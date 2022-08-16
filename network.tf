#--------------------------------------------------------------
# VPC
#--------------------------------------------------------------

resource "aws_vpc" "vpc" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
}
#--------------------------------------------------------------
# Internet Gateway
#--------------------------------------------------------------

resource "aws_internet_gateway" "igw"{
  vpc_id                        = aws_vpc.vpc.id
}
#--------------------------------------------------------------
# Public subnet
#--------------------------------------------------------------

resource "aws_subnet" "pub-subnet"{
  count = length(var.pub_cidr)

  vpc_id			= aws_vpc.vpc.id
  cidr_block   			= element(var.pub_cidr, count.index)
  availability_zone		= element(var.az, count.index)
  map_public_ip_on_launch	= true
}

resource "aws_route_table" "pub-rtb" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "pub-rtb-as" {
  count = length(var.pub_cidr)

  subnet_id      = element(aws_subnet.pub-subnet.*.id, count.index)
  route_table_id = aws_route_table.pub-rtb.id
}

resource "aws_main_route_table_association" "main-rtb-as" {
  vpc_id         = aws_vpc.vpc.id
  route_table_id = aws_route_table.pub-rtb.id
}

#--------------------------------------------------------------
# Private subnet
#--------------------------------------------------------------
resource "aws_subnet" "pri-subnet"{
  count = length(var.pri_cidr)

  vpc_id			= aws_vpc.vpc.id
  cidr_block			= element(var.pri_cidr, count.index)
  availability_zone		= element(var.az, count.index)
  map_public_ip_on_launch	= false
}

