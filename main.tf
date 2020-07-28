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
    Name = "${var.name}TF.IGW"
  }
}

# Public Subnet
resource "aws_subnet" "Public-sub" {
  vpc_id = aws_vpc.patrick_vpc.id
  cidr_block = "16.0.1.0/24"
  availability_zone = "eu-west-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.name}TF.PublicSubnet"
  }
}

# Security group - Public
resource "aws_security_group" "SG-web" {
  name = "app-sg"
  description = "Allow http and https traffic"
  vpc_id = aws_vpc.patrick_vpc.id 

  ingress {
    description = "3000 from VPC"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "https from VPC"
    from_port   = 443
    to_port     = 443
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
    Name = "${var.name}SG.App"
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
      Name = "${var.name}NACL.public"
    }
}

# Route Table - Public
resource "aws_route_table" "route-public" {
  vpc_id = aws_vpc.patrick_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGW.id
  }

  tags = {
    Name = "${var.name}Route.Public"
  }
}  

# Route table associations
resource "aws_route_table_association" "route-app" {
  subnet_id = aws_subnet.Public-sub.id
  route_table_id = aws_route_table.route-public.id
}


# Create EC2 instance IMAGE with APP
resource "aws_instance" "Web" {
  ami                         = "ami-00b48f09c568b0014"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.Public-sub.id
  vpc_security_group_ids      = [aws_security_group.SG-web.id]
  associate_public_ip_address = true
  user_data = data.template_file.initapp.rendered
  tags = {
    Name = "${var.name}TF.App"
  }
  
}

# Private Subnet
resource "aws_subnet" "Private-sub" {
  vpc_id = aws_vpc.patrick_vpc.id
  cidr_block = "16.0.2.0/24"
  availability_zone = "eu-west-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.name}TF.PrivateSubnet"
  }
}


# Security Group - Private
resource "aws_security_group" "SG-db" {
  name = "SG-db"
  description = "Allow http and MongoDB traffic"
  vpc_id = aws_vpc.patrick_vpc.id 

  ingress {
    description = "Mongodb from VPC"
    from_port   = 27017
    to_port     = 27017
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
    Name = "${var.name}TF.SG.db"
  }
}

# NACL - Private
resource "aws_network_acl" "private-nacl" {
  vpc_id = aws_vpc.patrick_vpc.id

  # Port 27017

   ingress {
     protocol = "tcp"
     rule_no = 100
     action = "allow"
     cidr_block = "16.0.1.0/24"
     from_port = 27017
     to_port = 27017
   }

  # Ephemeral Ports

  egress {
    protocol = "tcp"
    rule_no = 100
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 1024
    to_port = 65535
  }

  ingress {
    protocol = "tcp"
    rule_no = 110
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 1024
    to_port = 65535
  }

  # Inbounds - 80, 443

  egress {
    protocol = "tcp"
    rule_no = 110
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 80
    to_port = 80
  }

  egress {
    protocol = "tcp"
    rule_no = 120
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 443
    to_port = 443
  }

  subnet_ids = [aws_subnet.Private-sub.id]

    tags = {
      Name = "${var.name}NACL.TF.private"
    }
}

# Create EC2 instance for DB
resource "aws_instance" "DB" {
  ami                         = "ami-0983c603572871a58"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.Private-sub.id
  vpc_security_group_ids      = [aws_security_group.SG-db.id]
  associate_public_ip_address = true
  # user_data = data.template_file.initdb.rendered
  tags = {
    Name = "${var.name}TF.DB"
  }
  
}

# Route Table - Private
resource "aws_route_table" "route-private" {
  vpc_id = aws_vpc.patrick_vpc.id

  # route {
  #   cidr_block = "16.0.0.0/16"
  #   instance_id = aws_instance.DB.id
  # }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGW.id
  }

  tags = {
    Name = "${var.name}Route.TF.Private"
  }
}  

# Route table associations
resource "aws_route_table_association" "route-db" {
  subnet_id = aws_subnet.Private-sub.id
  route_table_id = aws_route_table.route-private.id
}

# Load init script to be used
data "template_file" "initapp" {
  template = file("./scripts/app/init.sh.tpl")
  vars = {
      db_host = "mongodb://${aws_instance.DB.private_ip}:27017/posts"
    }  
}

# Load init script to be used
# data "template_file" "initdb" {
#   template = file("./scripts/db/init.sh.tpl")
# }