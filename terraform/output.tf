output "resources" {
  value = {
    # VPC
    vpc_id = aws_vpc.main.id
    vpc_cidr_block = aws_vpc.main.cidr_block

    # Subnet
    subnet_id = aws_subnet.main.id
    subnet_cidr_block = aws_subnet.main.cidr_block

    # Security Groups
    lb_sg_id = aws_security_group.lb.id
    ec2_sg_id = aws_security_group.ec2.id

    # Load Balancer
    lb_id = aws_elb.main.id
    lb_dns_name = aws_elb.main.dns_name
    lb_eip = aws_eip.main.public_ip

    # EC2 Instances
    ec2_ids = aws_instance.main.*.id
    ec2_private_ips = aws_instance.main.*.private_ip
    ec2_public_ips = aws_instance.main.*.public_ip

    # Target Group
    tg_id = aws_lb_target_group.main.id
    tg_arn = aws_lb_target_group.main.arn

    # Certificate
    cert_id = aws_iam_server_certificate.main.id
    cert_arn = aws_iam_server_certificate.main.arn
  }
}