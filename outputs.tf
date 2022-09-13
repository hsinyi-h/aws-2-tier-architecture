output "vpc_id" { value = aws_vpc.vpc.id }

output "vpc_cidr" { value = aws_vpc.vpc.cidr_block }

output "pub_subnet_ids" { value = aws_subnet.pub-subnet.*.id }

output "pri_subnet_ids" { value = aws_subnet.pri-subnet.*.id }

output "ec2_instance_id" { value = aws_instance.ec2.id }

output "ec2_eip" { value = aws_eip.ec2-eip.public_ip }

output "db_endpoint" { value = aws_db_instance.db.endpoint }

output "db_password" {
  value     = data.aws_secretsmanager_secret_version.db-password.secret_string
  sensitive = true
}

output "ec2_private_key" {
  value     = tls_private_key._.private_key_pem
  sensitive = true
}
