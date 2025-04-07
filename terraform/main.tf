# Key Pair
resource "tls_private_key" "test_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "test_key" {
  key_name   = "test_key"
  public_key = tls_private_key.test_key.public_key_openssh
}

resource "local_file" "test_key_pem" {
  content         = tls_private_key.test_key.private_key_pem
  filename        = "${path.module}/test_key.pem"
  file_permission = "0400"
}

# Add this new resource to save the key locally
resource "local_file" "test_key_pem" {
  content         = tls_private_key.test_key.private_key_pem
  filename        = "${path.module}/test_key.pem"
  file_permission = "0400"  # Secure permissions for the key file
}

# Security Groups
resource "aws_security_group" "sg_healthcare" {
  name        = "sg_healthcare"
  description = "Security group for healthcare server"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sg_monitoring" {
  name        = "sg_monitoring"
  description = "Security group for monitoring server"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instances
resource "aws_instance" "healthcare_server" {
  ami                    = var.ami_id
  instance_type         = var.instance_type
  key_name              = aws_key_pair.test_key.key_name
  security_groups       = [aws_security_group.sg_healthcare.name]
  user_data             = <<-EOF
                          #!/bin/bash
                          sudo apt update -y
                          # Execute all installation scripts
                          bash /tmp/docker.sh
                          bash /tmp/jenkins.sh
                          bash /tmp/trivy.sh
                          bash /tmp/awscli.sh
                          bash /tmp/kubectl.sh
                          bash /tmp/eksctl.sh
                          EOF

  provisioner "file" {
    source      = "scripts/healthcare/docker.sh"
    destination = "/tmp/docker.sh"
  }

  provisioner "file" {
    source      = "scripts/healthcare/jenkins.sh"
    destination = "/tmp/jenkins.sh"
  }

  provisioner "file" {
    source      = "scripts/healthcare/trivy.sh"
    destination = "/tmp/trivy.sh"
  }

  provisioner "file" {
    source      = "scripts/healthcare/awscli.sh"
    destination = "/tmp/awscli.sh"
  }

  provisioner "file" {
    source      = "scripts/healthcare/kubectl.sh"
    destination = "/tmp/kubectl.sh"
  }

  provisioner "file" {
    source      = "scripts/healthcare/eksctl.sh"
    destination = "/tmp/eksctl.sh"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.test_key.private_key_pem
    host        = self.public_ip
  }

  tags = {
    Name = "healthcare-server"
  }
}

resource "aws_instance" "monitoring_server" {
  ami                    = var.ami_id
  instance_type         = var.instance_type
  key_name              = aws_key_pair.test_key.key_name
  security_groups       = [aws_security_group.sg_monitoring.name]
  user_data             = <<-EOF
                          #!/bin/bash
                          sudo apt update -y
                          bash /tmp/docker.sh
                          EOF

  provisioner "file" {
    source      = "scripts/monitoring/docker.sh"
    destination = "/tmp/docker.sh"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.test_key.private_key_pem
    host        = self.public_ip
  }

  tags = {
    Name = "monitoring-server"
  }
}

# Elastic IPs
resource "aws_eip" "eip_healthcare" {
  instance = aws_instance.healthcare_server.id
  vpc      = true
}

resource "aws_eip" "eip_monitoring" {
  instance = aws_instance.monitoring_server.id
  vpc      = true
}