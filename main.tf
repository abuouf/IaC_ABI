provider "aws" {
  region = "your_region"
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "example" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "your_availability_zone"
  map_public_ip_on_launch = true
}

resource "aws_instance" "backend" {
  ami                    = "ami-xxxxxxxxxxxxxxxxx" // Replace with the appropriate AMI ID for Ubuntu 22.04
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.example.id
  associate_public_ip_address = true
  key_name               = "your_key_name" // Replace with your key pair name

  tags = {
    Name = "backend"
  }
}

resource "aws_instance" "frontend" {
  ami                    = "ami-xxxxxxxxxxxxxxxxx" // Replace with the appropriate AMI ID for Ubuntu 22.04
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.example.id
  associate_public_ip_address = true
  key_name               = "your_key_name" // Replace with your key pair name

  tags = {
    Name = "frontend"
  }
}

resource "aws_db_instance" "mysql" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = "admin"
  password             = "password"
  port                 = 3306
  subnet_group_name    = aws_db_subnet_group.example.name
}

resource "aws_db_subnet_group" "example" {
  name       = "example"
  subnet_ids = [aws_subnet.example.id]
}
