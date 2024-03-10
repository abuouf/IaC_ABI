terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.40.0"
    }
  }
}

provider "aws" {
  # Configuration options
  region = "us-east-1"
}

#create Database Instant
resource "aws_db_instance" "mysql" {
  allocated_storage    = 10
  db_name              = "mydb"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  username             = "super"
  password             = "password1590"
  skip_final_snapshot  = true
  db_subnet_group_name = aws_db_subnet_group.db_subnet_g.name 
  vpc_security_group_ids =[aws_security_group.db_sg.id]
  publicly_accessible =  false
}

#Create frontend EC2
resource "aws_instance" "frontend" {
  ami                    = "ami-07d9b9ddc6cd8dd30" // Replace with the appropriate AMI ID for Ubuntu 22.04
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.web_public_subnet.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true
  key_name               = "Test_Key" // Replace with your key pair name

  tags = {
    Name = "frontend"
  }
  provisioner "remote-exec" {
    connection {
      type = "ssh"
      user = "ubuntu"                  // Assuming Ubuntu AMI, adjust if different
      private_key = file("C:/Users/User/.aws/Test_Key.pem")  // Path to your private key
      host     = self.public_ip
    }
    inline = [
      "sudo apt update",      
      "sudo apt-get install -y nodejs",
      "sudo apt-get install -y npm", 
      "sudo npm install pm2 -g",     
      "sudo mkdir /scripts",
      "sudo wget https://raw.githubusercontent.com/abuouf/IaC_ABI/main/deploy_frontend.sh -O /scripts/deploy_frontend.sh",
      "sudo chmod +x /scripts/deploy_frontend.sh", 
      "sudo . /scripts/deploy_frontend.sh",
      "sudo wget https://github.com/abuouf/IaC_ABI/raw/main/monitor-cpu.sh -O /scripts/monitor-cpu.sh",
      "sudo chmod +x /scripts/monitor-cpu.sh",
      "sudo . /scripts/monitor-cpu.sh",
      "echo '*/10 * * * * /scripts/monitor-cpu.sh' | crontab -"
    ]
  }
}

#create backend EC2
resource "aws_instance" "backend" {
  ami                    = "ami-07d9b9ddc6cd8dd30" // Replace with the appropriate AMI ID for Ubuntu 22.04
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.web_public_subnet.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true
  key_name               = "Test_Key" // Replace with your key pair name

  tags = {
    Name = "backend"
  }
  provisioner "remote-exec" {
    connection {
      type = "ssh"
      user = "ubuntu"                  // Assuming Ubuntu AMI, adjust if different
      private_key = file("C:/Users/User/.aws/Test_Key.pem")  // Path to your private key
      host     = self.public_ip
    }
    inline = [
      "sudo apt update",
      "sudo apt install -y apache2",
      "sudo mkdir /scripts",
      "sudo wget https://raw.githubusercontent.com/abuouf/IaC_ABI/main/deploy_backend.sh -O /scripts/deploy_backend.sh",
      "sudo chmod +x /scripts/deploy_backend.sh", 
      "sudo . /scripts/deploy_backend.sh",
      "sudo wget https://github.com/abuouf/IaC_ABI/raw/main/monitor-cpu.sh -O /scripts/monitor-cpu.sh",
      "sudo chmod +x /scripts/monitor-cpu.sh",
      "sudo . /scripts/monitor-cpu.sh",
      "echo '*/10 * * * * /scripts/monitor-cpu.sh' | crontab -"
      ]
  }
}

#create DB subnet group
resource "aws_db_subnet_group" "db_subnet_g" {
  name       = "main"
  subnet_ids = [aws_subnet.web_public_subnet.id,aws_subnet.web_private_subnet.id]

  tags = {
    Name = "My DB subnet group"
  }
}
#create VPC
resource "aws_vpc" "web_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Web VPC"
  }
}

#create public subnet
resource "aws_subnet" "web_public_subnet" {
  vpc_id            = aws_vpc.web_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "Web Public Subnet"
  }
}

#create private subnet
resource "aws_subnet" "web_private_subnet" {
  vpc_id            = aws_vpc.web_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone =  "us-east-1b"

  tags = {
    Name = "Web Private Subnet"
  }
}

#attach an internet gateway to the VPC
resource "aws_internet_gateway" "web_ig" {
  vpc_id = aws_vpc.web_vpc.id

  tags = {
    Name = "Web Internet Gateway"
  }
}

#create a route table for a public subnet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.web_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.web_ig.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.web_ig.id
  }

  tags = {
    Name = "Public Route Table"
  }
}

#associate routing table with public subnet
resource "aws_route_table_association" "public_1_rt_a" {
  subnet_id      = aws_subnet.web_public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

#create security groups to allow web traffic
resource "aws_security_group" "web_sg" {
  name   = "HTTP and SSH"
  vpc_id = aws_vpc.web_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3001
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#create security groups to allow Database traffic
resource "aws_security_group" "db_sg" {
  name   = "SQL"
  vpc_id = aws_vpc.web_vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["10.0.1.0/24"]
  }
}
