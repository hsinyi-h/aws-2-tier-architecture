vpc_cidr	= "10.0.0.0/16"

pub_cidr	= ["10.0.1.0/24", "10.0.2.0/24"]

pri_cidr	= ["10.0.10.0/24", "10.0.20.0/24"]

az		= ["ap-southeast-1a", "ap-southeast-1c"]

db-subnet-group_name	= "wordpress-db-subnet-grp"

db_identifier_name	= "wordpress-db"	

user_data		= file("./bootstrap.sh")

db_password_name	= "snd--password"
