provider "aws" {
	region = "eu-west-1"
}

# Creating EC2 instance

# resource "aws_instance" "Web" {
# 	ami 	      = "ami-089cc16f7f08c4457"
# 	instance_type = "t2.micro"
# 	associate_public_ip_address = true
# 	tags = {
# 		Name = "Eng57.Patrick.C.TF.App"
# 	}
# }


# Creating VPC and components
resource "aws_vpc" "patrick_vpc" {
  cidr_block = "16.0.0.0/16"
  tags = {
    Name = "${var.name}TF.VPC"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.patrick_vpc.id
  tags = {
    Name = "Eng57.Patrick.TF.IGW"
  }
}

# Public Subnet
resource "aws_subnet" "Public-sub" {
  vpc_id = aws_vpc.patrick_vpc.id
  cidr_block = "16.0.1.0/24"
  availability_zone = "eu-west-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "Eng57.Patrick.C.TF.PublicSubnet"
  }
}

# Security group - Public
resource "aws_security_group" "SG-web" {
  name = "app-sg"
  description = "Allow http and https traffic"
  vpc_id = aws_vpc.patrick_vpc.id 

  ingress {
    description = "https from VPC"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "http from VPC"
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

  tags = {
    Name = "Eng57.Patrick.C.SG.App"
  }
}

# NACL - Public

resource "aws_network_acl" "public-nacl" {
  vpc_id = aws_vpc.patrick_vpc.id

  # Port 80

  egress {
    protocol = "tcp"
    rule_no = 100
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 80
    to_port = 80
  }

  ingress {
    protocol = "tcp"
    rule_no = 100
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 80
    to_port = 80
  }

  # Ephemeral Ports

  egress {
    protocol = "tcp"
    rule_no = 120
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 1024
    to_port = 65535
  }

  ingress {
    protocol = "tcp"
    rule_no = 120
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 1024
    to_port = 65535
  }

  subnet_ids = [aws_subnet.Public-sub.id]

    tags = {
      Name = "Eng57.Patrick.C.NACL.public"
    }
}

# Route Table
resource "aws_route_table" "route-public" {
  vpc_id = aws_vpc.patrick_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGW.id
  }
  tags = {
    Name = "Eng57.Patrick.C.Route.Public"
  }
}  

# Route table associations
resource "aws_route_table_association" "route-app" {
  subnet_id = aws_subnet.Public-sub.id
  route_table_id = aws_route_table.route-public.id
}

# Load init script to be used
data "template_file" "initapp" {
  template = file("./scripts/app/init.sh.tpl")
}

# Create EC2 instance IMAGE with app
resource "aws_instance" "Web" {
  ami                         = "ami-00b48f09c568b0014"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.Public-sub.id
  vpc_security_group_ids      = [aws_security_group.SG-web.id]
  associate_public_ip_address = true
  user_data = data.template_file.initapp.rendered
  tags = {
    Name = "Eng57.Patrick.C.TF.App"
  }
  
}

