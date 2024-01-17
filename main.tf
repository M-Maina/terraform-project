provider "aws" {
  region = "us-east-1"
}


variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable avail_zone {}
variable env_prefix {}
variable my_ip {}
variable instance_type {}


resource "aws_vpc" "development-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name: "${var.env_prefix}-vpc"
  }

}

resource "aws_subnet" "dev-subnet-1" {
  vpc_id = aws_vpc.development-vpc.id
  cidr_block = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags = {
    Name: "${var.env_prefix}-subnet-1"
  }

}


# resource "aws_route_table" "mydev-route-table" {
#   vpc_id = aws_vpc.development-vpc.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.dev-igw.id
#   }

#   tags = {
#     Name = "${var.env_prefix}-rtb"
#   }
# }

# resource "aws_route_table_association" "dev-rtb-ass" {
#   subnet_id = aws_subnet.dev-subnet-1.id
#   route_table_id = aws_default_route_table.main-rtb
# }


resource "aws_internet_gateway" "dev-igw" {
  vpc_id = aws_vpc.development-vpc.id

  tags = {
    Name = "${var.env_prefix}-igw"
  }
}

resource "aws_default_route_table" "main-rtb" {
  default_route_table_id = aws_vpc.development-vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dev-igw.id
  }

  tags = {
    Name = "${var.env_prefix}-main-rtb"
  }
}

resource "aws_default_security_group" "dev-default-sg" {
  vpc_id = aws_vpc.development-vpc.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags = {
    Name = "${var.env_prefix}-default-sg"
  }
}

# data "aws_ami" "latest-amazon-linux-image" {
#   most_recent = true
#   owners = ["amazon"]
#   filter {
#     name ="name"
#     values = ["Amazon Linux 2023 AMI"]
#   }
# }
# output "aws_ami_id" {
#   value = data.aws_ami.latest-amazon-linux-image.id
# }

# resource "aws_key_pair" "ssh-key" { come back
#   key_name = "server-key"
#   public_key = file(var.public_key_location) must be set
# }


resource "aws_instance" "dev-sever" {
  ami =  "ami-0005e0cfe09cc9050"
  instance_type = var.instance_type

  subnet_id = aws_subnet.dev-subnet-1.id
  vpc_security_group_ids = [aws_default_security_group.dev-default-sg.id]
  availability_zone = var.avail_zone

  associate_public_ip_address = true
  
  key_name = "server-pair"

  connection {
    type = "ssh"
    host = self.public_ip
    user = "ec2-user"
    private_key = "server-pair"
  }

 provisioner "file" {
    source = "entry-sript.sh"
    destination = "home/ec2-user/entry-sript.sh"
  }

  provisioner "remote-exec" {  #Not working
    inline = [ 
      "export ENV=dev",
      "mkdir newdir"
     ]
  }

  tags = {
    Name = "${var.env_prefix}-dev-server"
  }
}