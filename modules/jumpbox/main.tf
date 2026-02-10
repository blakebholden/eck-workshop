# Windows Jump Box Module
# Provides RDP access to private resources within the VPC

# Get the latest Windows Server 2022 AMI
data "aws_ami" "windows" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security group for jump box
resource "aws_security_group" "jumpbox" {
  name        = "${var.cluster_name}-jumpbox-sg"
  description = "Security group for Windows jump box"
  vpc_id      = var.vpc_id

  # RDP access
  ingress {
    description = "RDP from allowed CIDRs"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = var.allowed_rdp_cidrs
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.cluster_name}-jumpbox-sg"
    Environment = var.environment
  }
}

# Key pair for Windows password decryption
resource "tls_private_key" "jumpbox" {
  count     = var.create_key_pair ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "jumpbox" {
  count      = var.create_key_pair ? 1 : 0
  key_name   = "${var.cluster_name}-jumpbox-key"
  public_key = tls_private_key.jumpbox[0].public_key_openssh

  tags = {
    Name        = "${var.cluster_name}-jumpbox-key"
    Environment = var.environment
  }
}

# Windows jump box instance
resource "aws_instance" "jumpbox" {
  ami                         = data.aws_ami.windows.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.jumpbox.id]
  key_name                    = var.create_key_pair ? aws_key_pair.jumpbox[0].key_name : var.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true

    tags = {
      Name = "${var.cluster_name}-jumpbox-volume"
    }
  }

  # User data to configure the instance
  user_data = <<-EOF
    <powershell>
    # Enable RDP
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

    # Install Chocolatey
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

    # Install useful tools
    choco install -y googlechrome firefox git awscli kubectl helm

    # Add hosts file entries for elastic.internal domain
    Add-Content -Path "C:\Windows\System32\drivers\etc\hosts" -Value ""
    Add-Content -Path "C:\Windows\System32\drivers\etc\hosts" -Value "# Elastic internal DNS - will be updated with actual LB IP"
    </powershell>
  EOF

  tags = {
    Name        = "${var.cluster_name}-jumpbox"
    Environment = var.environment
    Purpose     = "RDP access to private ECK resources"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}

# Get the encrypted Windows password
data "aws_instance" "jumpbox_password" {
  instance_id = aws_instance.jumpbox.id

  depends_on = [aws_instance.jumpbox]
}
