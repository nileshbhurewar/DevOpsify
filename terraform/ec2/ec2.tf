variable "vpc_id" {}
variable "public_subnet_id" {}

resource "aws_key_pair" "main_key" {
  key_name   = "main-key"
  public_key = file("main-key.pub")
}

resource "aws_security_group" "master_sg" {
  name   = "master_sg"
  vpc_id = var.vpc_id

  #SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  #HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  #MYSQL
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  #backend
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  #DataDog-log
  ingress {
    from_port   = 10516
    to_port     = 10516
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  #HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
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

resource "aws_instance" "master_instance" {
  ami                    = "ami-02d26659fd82cf299" # Ubuntu 20.04
  instance_type          = "t3.large"
  subnet_id              = var.public_subnet_id
  key_name               = aws_key_pair.main_key.key_name
  vpc_security_group_ids = [aws_security_group.master_sg.id]

  tags = { Name = "master_instance" }
}

output "master_instance_ip" {
  value = aws_instance.master_instance.public_ip
}
