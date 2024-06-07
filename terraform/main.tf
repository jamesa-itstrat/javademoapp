# Configure the AWS provider
provider "aws" {
  region = "us-east-1"
}

# Define the variables
variable "environment" {
  type        = string
  default     = "dev"
}

# Create the VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name        = "main-vpc-${var.environment}"
    Environment = var.environment
  }
}

# Create the subnet
resource "aws_subnet" "main" {
  cidr_block = "10.0.1.0/24"
  vpc_id     = aws_vpc.main.id
  availability_zone = "us-east-1a"
  tags = {
    Name        = "main-subnet-${var.environment}"
    Environment = var.environment
  }
}

# Create the security group for the load balancer
resource "aws_security_group" "lb" {
  name        = "lb-sg-${var.environment}"
  description = "Security group for load balancer"
  vpc_id      = aws_vpc.main.id

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
}

# Create the security group for the EC2 instances
resource "aws_security_group" "ec2" {
  name        = "ec2-sg-${var.environment}"
  description = "Security group for EC2 instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.lb.id]
  }
}

# Create a self-signed certificate
resource "tls_private_key" "example" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "example" {
  private_key_pem = tls_private_key.example.private_key_pem

  subject {
    common_name  = "it-strat.com"
    organization = "IT-Strat Inc"
    country      = "US"
  }

  validity_period_hours = 8760

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

# Create the load balancer
resource "aws_elb" "main" {
  name            = "main-elb-${var.environment}"
  subnets         = [aws_subnet.main.id]
  security_groups = [aws_security_group.lb.id]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 443
    lb_protocol       = "https"
    ssl_certificate_id = aws_iam_server_certificate.main.arn
  }
}

# Create an Elastic IP address for the load balancer
resource "aws_eip" "main" {
  domain = "vpc"
  depends_on = [aws_elb.main]
}

# Associate the Elastic IP address with the load balancer
resource "aws_elb_attachment" "main" {
  elb      = aws_elb.main.id
  instance = aws_eip.main.id
}

# Create an SSL certificate
resource "aws_iam_server_certificate" "main" {
  name             = "main-cert-${var.environment}"
  certificate_body = tls_self_signed_cert.example.cert_pem
  private_key      = tls_private_key.example.private_key_pem
}

# Create the EC2 instances
resource "aws_instance" "main" {
  count         = 3
  ami           = "ami-0c94855ba95c71c99"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.ec2.id]
  subnet_id = aws_subnet.main.id
  key_name               = "my_key"

  tags = {
    Name        = "main-ec2-${var.environment}-${count.index}"
    Environment = var.environment
  }
}

# Create the target group
resource "aws_lb_target_group" "main" {
  name     = "main-tg-${var.environment}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

# Create the target group attachment
resource "aws_lb_target_group_attachment" "main" {
  count            = 3
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = aws_instance.main[count.index].id
  port             = 80
}
