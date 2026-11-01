locals {
  tags = {
    Project = "EWB-VPC-Peering"
    Student = var.student_name
  }

  vpc_a_cidr      = "10.10.0.0/16"
  a_public_cidr   = "10.10.1.0/24"
  a_private_cidr  = "10.10.2.0/24"
  vpc_b_cidr      = "10.20.0.0/16"
  b_private_cidr  = "10.20.1.0/24"

  bastion_ip = "10.10.1.10"
  app_a_ip   = "10.10.2.10"
  app_b_ip   = "10.20.1.10"
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Amazon Linux 2023, x86_64 (latest, resolved from the public SSM parameter)
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

locals {
  az = data.aws_availability_zones.available.names[0] # same AZ for the whole lab
}

# ---------------------------------------------------------------------------
# VPC A  (public + private subnet, internet gateway)
# ---------------------------------------------------------------------------
resource "aws_vpc" "a" {
  cidr_block           = local.vpc_a_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(local.tags, { Name = "ewb-vpc-a" })
}

resource "aws_subnet" "a_public" {
  vpc_id                  = aws_vpc.a.id
  cidr_block              = local.a_public_cidr
  availability_zone       = local.az
  map_public_ip_on_launch = false # public IP is set per-instance (bastion only)
  tags                    = merge(local.tags, { Name = "ewb-a-public" })
}

resource "aws_subnet" "a_private" {
  vpc_id                  = aws_vpc.a.id
  cidr_block              = local.a_private_cidr
  availability_zone       = local.az
  map_public_ip_on_launch = false
  tags                    = merge(local.tags, { Name = "ewb-a-private" })
}

resource "aws_internet_gateway" "a" {
  vpc_id = aws_vpc.a.id
  tags   = merge(local.tags, { Name = "ewb-igw-a" })
}

resource "aws_route_table" "a_public" {
  vpc_id = aws_vpc.a.id
  tags   = merge(local.tags, { Name = "ewb-rt-a-public" })
}

resource "aws_route" "a_public_default" {
  route_table_id         = aws_route_table.a_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.a.id
}

resource "aws_route_table_association" "a_public" {
  subnet_id      = aws_subnet.a_public.id
  route_table_id = aws_route_table.a_public.id
}

resource "aws_route_table" "a_private" {
  vpc_id = aws_vpc.a.id
  tags   = merge(local.tags, { Name = "ewb-rt-a-private" })
}

resource "aws_route_table_association" "a_private" {
  subnet_id      = aws_subnet.a_private.id
  route_table_id = aws_route_table.a_private.id
}

# ---------------------------------------------------------------------------
# VPC B  (private subnet only, no internet gateway)
# ---------------------------------------------------------------------------
resource "aws_vpc" "b" {
  cidr_block           = local.vpc_b_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(local.tags, { Name = "ewb-vpc-b" })
}

resource "aws_subnet" "b_private" {
  vpc_id                  = aws_vpc.b.id
  cidr_block              = local.b_private_cidr
  availability_zone       = local.az
  map_public_ip_on_launch = false
  tags                    = merge(local.tags, { Name = "ewb-b-private" })
}

resource "aws_route_table" "b_private" {
  vpc_id = aws_vpc.b.id
  tags   = merge(local.tags, { Name = "ewb-rt-b-private" })
}

resource "aws_route_table_association" "b_private" {
  subnet_id      = aws_subnet.b_private.id
  route_table_id = aws_route_table.b_private.id
}

# ---------------------------------------------------------------------------
# Security groups  (inbound exactly as in workbook page 6; default allow-all egress)
# ---------------------------------------------------------------------------
resource "aws_security_group" "bastion" {
  name        = "ewb-sg-bastion"
  description = "Bastion SSH from the student's public IP only"
  vpc_id      = aws_vpc.a.id
  tags        = merge(local.tags, { Name = "ewb-sg-bastion" })
}

resource "aws_security_group" "app_a" {
  name        = "ewb-sg-app-a"
  description = "App-A: SSH from bastion, ICMP echo from App-B"
  vpc_id      = aws_vpc.a.id
  tags        = merge(local.tags, { Name = "ewb-sg-app-a" })
}

resource "aws_security_group" "app_b" {
  name        = "ewb-sg-app-b"
  description = "App-B: SSH from bastion, ICMP echo from App-A"
  vpc_id      = aws_vpc.b.id
  tags        = merge(local.tags, { Name = "ewb-sg-app-b" })
}

resource "aws_vpc_security_group_egress_rule" "bastion_all" {
  security_group_id = aws_security_group.bastion.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "app_a_all" {
  security_group_id = aws_security_group.app_a.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "app_b_all" {
  security_group_id = aws_security_group.app_b.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# ewb-sg-bastion: SSH / 22 from my public IP /32
resource "aws_vpc_security_group_ingress_rule" "bastion_ssh" {
  security_group_id = aws_security_group.bastion.id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = var.my_ip_cidr
  description       = "SSH from my public IP"
}

# ewb-sg-app-a: SSH from bastion private IP
resource "aws_vpc_security_group_ingress_rule" "app_a_ssh" {
  security_group_id = aws_security_group.app_a.id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = "${local.bastion_ip}/32"
  description       = "SSH from bastion private IP"
}

# ewb-sg-app-a: ICMP echo request from App-B
resource "aws_vpc_security_group_ingress_rule" "app_a_icmp" {
  security_group_id = aws_security_group.app_a.id
  ip_protocol       = "icmp"
  from_port         = 8 # ICMP type 8 (echo request)
  to_port           = 0 # ICMP code 0
  cidr_ipv4         = "${local.app_b_ip}/32"
  description       = "ICMP echo request from App-B"
}

# ewb-sg-app-b: SSH from bastion private IP (App-B sees the bastion's private IP via ProxyJump)
resource "aws_vpc_security_group_ingress_rule" "app_b_ssh" {
  security_group_id = aws_security_group.app_b.id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = "${local.bastion_ip}/32"
  description       = "SSH from bastion private IP"
}

# ewb-sg-app-b: ICMP echo request from App-A  (toggle off for the controlled failure)
resource "aws_vpc_security_group_ingress_rule" "app_b_icmp" {
  count             = var.enable_app_b_icmp_rule ? 1 : 0
  security_group_id = aws_security_group.app_b.id
  ip_protocol       = "icmp"
  from_port         = 8
  to_port           = 0
  cidr_ipv4         = "${local.app_a_ip}/32"
  description       = "ICMP echo request from App-A"
}

# ---------------------------------------------------------------------------
# EC2 instances
# ---------------------------------------------------------------------------
resource "aws_instance" "bastion" {
  ami                         = data.aws_ssm_parameter.al2023.value
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.a_public.id
  private_ip                  = local.bastion_ip
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.bastion.id]

  metadata_options {
    http_tokens = "required" # IMDSv2 only
  }

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = merge(local.tags, { Name = "ewb-bastion" })

  depends_on = [aws_route.a_public_default]
}

resource "aws_instance" "app_a" {
  ami                         = data.aws_ssm_parameter.al2023.value
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.a_private.id
  private_ip                  = local.app_a_ip
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.app_a.id]

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = merge(local.tags, { Name = "ewb-app-a" })
}

resource "aws_instance" "app_b" {
  ami                         = data.aws_ssm_parameter.al2023.value
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.b_private.id
  private_ip                  = local.app_b_ip
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.app_b.id]

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = merge(local.tags, { Name = "ewb-app-b" })
}

# ---------------------------------------------------------------------------
# VPC peering  (phase 2: set enable_peering = true)
# Same account + same Region, so Terraform requests and accepts in one step.
# ---------------------------------------------------------------------------
resource "aws_vpc_peering_connection" "a_b" {
  count       = var.enable_peering ? 1 : 0
  vpc_id      = aws_vpc.a.id # requester
  peer_vpc_id = aws_vpc.b.id # accepter
  auto_accept = true
  tags        = merge(local.tags, { Name = "ewb-a-b-peer" })
}

# ewb-rt-a-private: 10.20.0.0/16 -> pcx   (App-A to VPC B)
resource "aws_route" "a_private_to_b" {
  count                     = var.enable_peering ? 1 : 0
  route_table_id            = aws_route_table.a_private.id
  destination_cidr_block    = local.vpc_b_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.a_b[0].id
}

# ewb-rt-b-private: 10.10.0.0/16 -> pcx   (return path to VPC A)
resource "aws_route" "b_private_to_a" {
  count                     = var.enable_peering ? 1 : 0
  route_table_id            = aws_route_table.b_private.id
  destination_cidr_block    = local.vpc_a_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.a_b[0].id
}

# ewb-rt-a-public: 10.20.0.0/16 -> pcx    (bastion SSH to App-B via ProxyJump)
resource "aws_route" "a_public_to_b" {
  count                     = var.enable_peering ? 1 : 0
  route_table_id            = aws_route_table.a_public.id
  destination_cidr_block    = local.vpc_b_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.a_b[0].id
}
