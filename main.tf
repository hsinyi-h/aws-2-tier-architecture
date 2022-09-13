#--------------------------------------------------------------
# EC2 keypair
#--------------------------------------------------------------
resource "aws_key_pair" "ec2-key" {
  key_name   = "common-ssh"
  public_key = tls_private_key._.public_key_openssh
}

resource "tls_private_key" "_" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

#--------------------------------------------------------------
# EC2 Instance
#--------------------------------------------------------------
resource "aws_instance" "ec2" {
  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = element(aws_subnet.pub-subnet.*.id, 0)
  associate_public_ip_address = "true"
  key_name                    = aws_key_pair.ec2-key.key_name
  vpc_security_group_ids      = [aws_security_group.ec2-sg.id]
  user_data                   = file("./bootstrap.sh")
  root_block_device {
    volume_type = var.ebs_volume_type
    volume_size = var.ebs_volume_size
  }
}

resource "aws_eip" "ec2-eip" {
  vpc      = true
  instance = aws_instance.ec2.id
}

#--------------------------------------------------------------
# RDS
#--------------------------------------------------------------

resource "aws_db_subnet_group" "db-subnet-group" {
  name       = var.db-subnet-group_name
  subnet_ids = aws_subnet.pri-subnet.*.id
}

resource "aws_db_instance" "db" {
  db_subnet_group_name   = aws_db_subnet_group.db-subnet-group.name
  allocated_storage      = var.allocated_storage
  storage_type           = var.storage_type
  engine                 = var.engine
  engine_version         = var.engine_version
  multi_az               = true
  instance_class         = var.db_instance
  identifier             = var.db_identifier_name
  username               = var.db_username
  password               = data.aws_secretsmanager_secret_version.db-password.secret_string
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.rds-sg.id]

  depends_on = [
    aws_secretsmanager_secret_version.db-password
  ]

}

#--------------------------------------------------------------
# Security group
#--------------------------------------------------------------

resource "aws_security_group" "alb-sg" {
  name        = "vpc_alb_sg"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "ec2-sg" {
  name = "ec2-sg"

  vpc_id = aws_vpc.vpc.id

  dynamic "ingress" {
    for_each = { for i in var.ingress_config : i.port => i }

    content {
      from_port       = ingress.value.port
      to_port         = ingress.value.port
      protocol        = ingress.value.protocol
      cidr_blocks     = ingress.value.cidr_blocks
      security_groups = [aws_security_group.alb-sg.id]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds-sg" {
  name        = "rds-sg"
  description = "Allows ec2 to access the RDS instances"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    description     = "EC2 to MYSQL"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2-sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#--------------------------------------------------------------
# ALB
#--------------------------------------------------------------

resource "aws_lb" "alb" {
  name               = "main-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb-sg.id]
  subnets            = aws_subnet.pub-subnet.*.id

  depends_on = [aws_security_group.alb-sg]

}
resource "aws_lb_target_group" "alb-target-group" {
  name     = "alb-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id
}

resource "aws_lb_listener" "alb-listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-target-group.arn
  }
  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_lb_target_group_attachment" "attach" {

  target_group_arn = aws_lb_target_group.alb-target-group.arn
  target_id        = aws_instance.ec2.id
  port             = 80
}
