terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    "Name" : "VPC"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    "Name" : "Public Subnet"
  }
}

resource "aws_internet_gateway" "igv" {
  vpc_id = aws_vpc.main.id
  tags = {
    "Name" = "Internet Gateway"
  }
}

resource "aws_route_table" "public_art" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igv.id
  }

  tags = {
    "Name" = "Public Route Table"
  }
}

resource "aws_route_table_association" "public_assoc" {
  route_table_id = aws_route_table.public_art.id
  subnet_id      = aws_subnet.public.id
}

// Private Subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-north-1c"
  tags = {
    "Name" : "Private Subnet"
  }
}

// Second Subnet Group => subnets to cover at least 2 AZs (current eu-north-1 (stoc)).
resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-north-1a"
  tags = {
    "Name" = "Private Subnet B"
  }
}

// Subnet Group => RDS needs it
resource "aws_db_subnet_group" "db_group" {
  name       = "subnet-group"
  subnet_ids = [aws_subnet.private.id, aws_subnet.private_2.id]

  tags = {
    "Name" = "Subnet Group"
  }
}



// Password Generator
resource "random_password" "db_password" {
  length  = 16
  special = false
}

resource "aws_db_instance" "default" {
  allocated_storage = 10 // 10 GB

  instance_class = "db.t3.micro"
  engine         = "mysql"
  engine_version = "8.0"

  skip_final_snapshot = true

  db_name = "db"

  username = "admin"
  password = random_password.db_password.result

  db_subnet_group_name   = aws_db_subnet_group.db_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
}


resource "aws_security_group" "web-sg" {
  name   = "web-server-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = "Web Server Security Group"
  }
}


// SG DB
resource "aws_security_group" "db_sg" {
  name   = "db-server-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    description     = "Allow MySQL only for Web Server"
    from_port       = 3306 // MySQL port
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web-sg.id]
  }

  tags = {
    "Name" = "DB SERVER SECURITY GROUP"
  }
}

resource "aws_instance" "web-server" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  key_name      = "my-aws-key"

  user_data = file("install_web_tools.sh")

  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web-sg.id]

  tags = {
    "Name" = "Web Server"
  }
}
