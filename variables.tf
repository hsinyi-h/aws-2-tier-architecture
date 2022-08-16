variable "vpc_cidr" { type = string }

variable "pub_cidr" { type = list(string) }

variable "pri_cidr" { type = list(string) }

variable "ami" { default = "ami-0dd1e66116f7975b8" }

variable "instance_type" { default = "t2.micro" }

variable "db-subnet-group_name" { type = string }

variable "az" { type = list(string) }

variable "ingress_config" {
  type = list(object({
    port        = string
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      port        = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      port        = 3306
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    }
  ]
  description = "list of ingress config"
}

variable "allocated_storage" { default = 10 }

variable "storage_type" { default = "gp2" }

variable "db_username" { default = "admin"  }

variable "engine" { default = "mysql" }

variable "engine_version" { default = "8.0.20" }

variable "db_instance" { default = "db.t2.micro" }

variable "db_identifier_name" { 
	type = string 
	description = " Name to identify the database"
}

variable "ebs_volume_type" { default = "gp2" }

variable "ebs_volume_size" { default = "10" }

variable "db_password_name" { type = string }
