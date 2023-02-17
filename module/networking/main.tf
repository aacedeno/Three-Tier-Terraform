#------networking/main.tf ------

data "aws_availability_zones" "available" {}

#This random integer will allow us to assign a new number to our vpc
resource "random_integer" "random" {
  min = 1
  max = 100
}

#This produces a list that is stored in the state
resource "random_shuffle" "az_list" {
  input        = data.aws_availability_zones.available.names
  result_count = var.max_subnets
}

#--- VPC-----
resource "aws_vpc" "prod_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true #Provide a dns hostname for any reosurce that is deployed in a public env
  enable_dns_support   = true

  tags = {
    Name = "prod_vpc-${random_integer.random.id}"
  }
  #Creates a new VPC before destroying the old one
  lifecycle {
    create_before_destroy = true
  }
}

#--- Internet Gateway ----------
resource "aws_internet_gateway" "prod_igw" {
  vpc_id = aws_vpc.prod_vpc.id

  tags = {
    Name = "prod_igw"
  }
}

#----Elastic IP and NAT Gateway -----

resource "aws_eip" "prod_nat_eip" {}

resource "aws_nat_gateway" "prod_ngw" {
  allocation_id = aws_eip.prod_nat_eip.id
  subnet_id     = aws_subnet.prod_public_subnet[0].id #Subnet that the NAT will be placed 

  tags = {
    Name = "prod_NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.prod_igw]
}


#----- Public Subnets and Public Route Table 
resource "aws_subnet" "prod_public_subnet" {
  count                   = var.public_sn_count #
  vpc_id                  = aws_vpc.prod_vpc.id
  cidr_block              = var.public_cidrs[count.index] #iterates through list  
  map_public_ip_on_launch = true
  availability_zone       = random_shuffle.az_list.result[count.index] #the random_shuffle resource runs through the list

  tags = {
    Name = "prod_public_${count.index + 1}"
  }
}

resource "aws_route_table" "prod_public_rt" {
  vpc_id = aws_vpc.prod_vpc.id

  tags = {
    Name = "prod_public_routet"
  }
}

#This connect our public route route to public subnets, specifying every public subnet found in the count and associate it to the public route table
resource "aws_route_table_association" "prod_public_assoc" {
  count          = var.public_sn_count                             #Need to assocatie every public subnet to this route table
  subnet_id      = aws_subnet.prod_public_subnet.*.id[count.index] #Access all public subnets and iterate through each one
  route_table_id = aws_route_table.prod_public_rt.id               #Defines what route table to associate
}

#Default route is where all traffic goes that isnt specifically destiend for something or somewhere else
#IGW will be the default route, anytime a resource request something, we will send it to the internet
resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.prod_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.prod_igw.id #can be anytype of gateway (peering connection or NAT gateway)
}

#-----Private Subnets and Route Table -------

resource "aws_subnet" "prod_private_subnet" {
  count                   = var.private_sn_count
  vpc_id                  = aws_vpc.prod_vpc.id
  cidr_block              = var.private_cidrs[count.index] #iterates through list  
  map_public_ip_on_launch = false
  availability_zone       = random_shuffle.az_list.result[count.index]

  tags = {
    Name = "prod_private_${count.index + 1}"
  }
}

resource "aws_route_table" "prod_private_rt" {
  vpc_id = aws_vpc.prod_vpc.id

  tags = {
    Name = "prod_private_routet"
  }
}

resource "aws_route" "default_private_route" {
  route_table_id         = aws_route_table.prod_private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.prod_ngw.id
}


resource "aws_route_table_association" "prod_private_assoc" {
  count          = var.private_sn_count                             #Need to assocatie every private subnet to this route table
  subnet_id      = aws_subnet.prod_private_subnet.*.id[count.index] #Access all private subnets and iterate through each one
  route_table_id = aws_route_table.prod_private_rt.id
}

#------ Database --------

resource "aws_db_subnet_group" "prod_rds_subnetgroup" {
  count      = var.db_subnet_group == true ? 1 : 0
  name       = "prod_rds_subnetgroup"
  subnet_ids = [aws_subnet.prod_private_subnet[2].id, aws_subnet.prod_private_subnet[3].id] #Assigning a specific subnet for databases 

  tags = {
    Name = "prod_rds_sng"
  }
}

#------ Security Groups -------

resource "aws_security_group" "ext_prod_lb_sg" {
  name        = "ext_prod_lb_sg"
  description = "Allow Inbound HTTP Traffic"
  vpc_id      = aws_vpc.prod_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
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


resource "aws_security_group" "web_servers_sg" {
  name        = "web_servers_sg"
  description = "Allow SSH inbound traffic from jumpbox and HTTP inbound traffic from external ALB"
  vpc_id      = aws_vpc.prod_vpc.id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.prod_bastion_sg.id]
  }
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.ext_prod_lb_sg.id]
  }
}

# #How to distriute traffic from web tier to internal alb -----------
# resource "aws_security_group" "int_prod_lb_sg" {
#   name        = "int_prod_lb_sg"
#   description = "Allow Inbound HTTP Traffic from the web tier"
#   vpc_id      = aws_vpc.prod_vpc.id

#   ingress {
#     from_port       = 80
#     to_port         = 80
#     protocol        = "tcp"
#     security_groups = [aws_security_group.web_servers_sg.id]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

resource "aws_security_group" "app_servers_sg" {
  name        = "app_server_sg"
  vpc_id      = aws_vpc.prod_vpc.id
  description = "Allow Inbound HTTP from the web servers and SSH inbound traffic from Bastion"

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.web_servers_sg.id]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.prod_bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "prod_rds_sg" {
  name        = "prod_rds_sg"
  description = "Allow MySQL port inbound traffic from backend app servers"
  vpc_id      = aws_vpc.prod_vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_servers_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "prod_bastion_sg" {
  name        = "prod_bastion_sg"
  description = "Allow SSH Inbound Traffic From Set IP"
  vpc_id      = aws_vpc.prod_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_access_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
