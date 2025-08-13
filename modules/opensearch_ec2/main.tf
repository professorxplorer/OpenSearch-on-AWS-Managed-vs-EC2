############################
# modules/opensearch_ec2/main.tf
############################

# --- IAM for discovery (DescribeInstances) ---
data "aws_iam_policy_document" "assume_ec2" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "node" {
  name               = "${var.ec2_name_prefix}-node-role"
  assume_role_policy = data.aws_iam_policy_document.assume_ec2.json
}

data "aws_iam_policy_document" "describe_ec2" {
  statement {
    actions   = ["ec2:DescribeInstances"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "describe_ec2" {
  name   = "${var.ec2_name_prefix}-describe-ec2"
  policy = data.aws_iam_policy_document.describe_ec2.json
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.node.name
  policy_arn = aws_iam_policy.describe_ec2.arn
}

resource "aws_iam_instance_profile" "node" {
  name = "${var.ec2_name_prefix}-instance-profile"
  role = aws_iam_role.node.name
}

# --- Networking helpers ---
# Use first subnet to detect VPC for the SG
data "aws_subnet" "selected" {
  id = var.ec2_subnet_ids[0]
}

# Cluster SG (added in addition to your provided SGs)
resource "aws_security_group" "os" {
  name        = "${var.ec2_name_prefix}-os-sg"
  description = "OpenSearch EC2 cluster SG"
  vpc_id      = data.aws_subnet.selected.vpc_id

  # Transport port (cluster comms)
  ingress {
    description = "Transport (9300) from self"
    from_port   = var.os_transport_port
    to_port     = var.os_transport_port
    protocol    = "tcp"
    self        = true
  }

  # HTTP API (9200) — from allowed CIDRs, if any
  dynamic "ingress" {
    for_each = length(var.os_allow_cidr_http) > 0 ? var.os_allow_cidr_http : []
    content {
      description = "HTTP (9200) from allowed CIDR"
      from_port   = var.os_http_port
      to_port     = var.os_http_port
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  # Always allow HTTP from self (intra-SG)
  ingress {
    description = "HTTP (9200) from self"
    from_port   = var.os_http_port
    to_port     = var.os_http_port
    protocol    = "tcp"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.ec2_tags, { Name = "${var.ec2_name_prefix}-os-sg" })
}

# --- User data / discovery ---
locals {
  cluster_tag_key   = "OpenSearchCluster"
  cluster_tag_value = var.os_cluster_name

  user_data = <<-EOT
    #!/bin/bash
    set -euo pipefail

    # Ensure tools (Amazon Linux/RHEL or Debian/Ubuntu)
    yum -y install curl tar jq awscli 2>/dev/null || (apt-get update && apt-get -y install curl jq awscli)

    # Kernel / vm settings
    sysctl -w vm.max_map_count=262144
    echo "vm.max_map_count=262144" >> /etc/sysctl.conf

    # Attach & format data volume if present
    if lsblk | grep -q "$(basename ${var.ec2_ebs_device_name})"; then
      mkfs.xfs ${var.ec2_ebs_device_name} || true
      mkdir -p /var/lib/opensearch
      echo "${var.ec2_ebs_device_name} /var/lib/opensearch xfs defaults,nofail 0 2" >> /etc/fstab
      mount -a || true
    else
      mkdir -p /var/lib/opensearch
    fi

    # Install OpenSearch ${var.os_version}
    if [ -f /etc/os-release ]; then . /etc/os-release; fi
    if [[ "$ID" == "amzn" || "$ID_LIKE" == *"rhel"* ]]; then
      rpm --import https://artifacts.opensearch.org/publickeys/opensearch.pgp
      cat >/etc/yum.repos.d/opensearch.repo <<'REPO'
[opensearch]
name=OpenSearch repo
baseurl=https://artifacts.opensearch.org/releases/bundle/opensearch/${var.os_version}/rpm/
gpgcheck=1
gpgkey=https://artifacts.opensearch.org/publickeys/opensearch.pgp
enabled=1
autorefresh=1
type=rpm-md
REPO
      sed -i "s|\${var.os_version}|${var.os_version}|g" /etc/yum.repos.d/opensearch.repo
      yum -y install opensearch
    else
      curl -L -o /tmp/opensearch.tar.gz "https://artifacts.opensearch.org/releases/bundle/opensearch/${var.os_version}/opensearch-${var.os_version}-linux-x64.tar.gz"
      mkdir -p /usr/share/opensearch
      tar -xzf /tmp/opensearch.tar.gz --strip-components=1 -C /usr/share/opensearch
      ln -sf /usr/share/opensearch/bin/opensearch /usr/bin/opensearch
      id opensearch >/dev/null 2>&1 || useradd -r -M -d /usr/share/opensearch opensearch
      chown -R opensearch:opensearch /usr/share/opensearch /var/lib/opensearch
      cat >/etc/systemd/system/opensearch.service <<'SVC'
[Unit]
Description=OpenSearch
After=network.target

[Service]
Type=simple
User=opensearch
Group=opensearch
LimitMEMLOCK=infinity
Environment=OPENSEARCH_PATH_CONF=/usr/share/opensearch/config
ExecStart=/usr/share/opensearch/bin/opensearch
Restart=always

[Install]
WantedBy=multi-user.target
SVC
      systemctl daemon-reload
    fi

    # Instance metadata (IMDSv2)
    TOKEN=$(curl -sS -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    REGION=$(curl -sS -H "X-aws-ec2-metadata-token: $${TOKEN}" http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)
    INSTANCE_ID=$(curl -sS -H "X-aws-ec2-metadata-token: $${TOKEN}" http://169.254.169.254/latest/meta-data/instance-id)
    LOCAL_IP=$(curl -sS -H "X-aws-ec2-metadata-token: $${TOKEN}" http://169.254.169.254/latest/meta-data/local-ipv4)

    # Discover peers by tag within same cluster
    FILTER_1="Name=tag:${local.cluster_tag_key},Values=${local.cluster_tag_value}"
    FILTER_2="Name=instance-state-name,Values=running"
    SEEDS=$(aws ec2 describe-instances --region "$${REGION}" --filters "$${FILTER_1}" "$${FILTER_2}" \
      | jq -r '.Reservations[].Instances[].PrivateIpAddress' \
      | grep -v "^$" | sort -u | tr '\\n' ',' | sed 's/,$//')

    mkdir -p /etc/opensearch
    cat >/etc/opensearch/opensearch.yml <<YML
cluster.name: ${var.os_cluster_name}
node.name: $${HOSTNAME}
path.data: /var/lib/opensearch
network.host: 0.0.0.0
http.port: ${var.os_http_port}
transport.port: ${var.os_transport_port}
discovery.seed_hosts: [$${SEEDS}]
cluster.initial_master_nodes: [$${SEEDS}]
bootstrap.memory_lock: true
plugins.security.disabled: ${var.os_enable_security ? "false" : "true"}
YML

    # JVM heap
    sed -i "s/^-Xms.*/-Xms${var.os_heap}/" /etc/opensearch/jvm.options || true
    sed -i "s/^-Xmx.*/-Xmx${var.os_heap}/" /etc/opensearch/jvm.options || true

    # Ensure memlock
    if [ -f /etc/systemd/system/opensearch.service ]; then
      grep -q '^LimitMEMLOCK=infinity' /etc/systemd/system/opensearch.service || echo 'LimitMEMLOCK=infinity' >> /etc/systemd/system/opensearch.service
      systemctl daemon-reload
    fi

    systemctl enable opensearch
    systemctl restart opensearch
  EOT
}

# Tag map for discovery
locals {
  discovery_tags = {
    (local.cluster_tag_key) = local.cluster_tag_value
  }
}

# --- EC2 Instances ---
resource "aws_instance" "node" {
  count         = var.ec2_instance_count
  ami           = var.ec2_ami_id
  instance_type = var.ec2_instance_type
  subnet_id     = var.ec2_subnet_ids[(count.index) % length(var.ec2_subnet_ids)]
  key_name      = var.ec2_key_name

  vpc_security_group_ids = concat(
    var.ec2_security_group_ids,
    [aws_security_group.os.id]
  )

  iam_instance_profile = aws_iam_instance_profile.node.name
  user_data            = local.user_data

  ebs_block_device {
    device_name           = var.ec2_ebs_device_name
    volume_size           = var.ec2_ebs_volume_size
    volume_type           = var.ec2_ebs_volume_type
    delete_on_termination = var.ec2_ebs_delete_on_termination
    encrypted             = var.ec2_ebs_encrypted
  }

  tags = merge(
    var.ec2_tags,
    local.discovery_tags,
    { Name = "${var.ec2_name_prefix}-${count.index}" }
  )
}
