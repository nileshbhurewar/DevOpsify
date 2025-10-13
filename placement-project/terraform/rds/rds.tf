variable "vpc_id" {
  description = "VPC ID"
}

variable "subnet_ids" {
  description = "List of subnet IDs for RDS"
  type        = list(string)
}

variable "db_subnet_group_name" {
  description = "DB subnet group name"
}

# RDS Security Group
resource "aws_security_group" "rds_sg" {
  name_prefix = "rds-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # Allow from within VPC
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg"
  }
}

# RDS MySQL Instance
resource "aws_db_instance" "mysql" {
  identifier             = "mysql-db"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_type           = "gp2"
  db_name                = "springbackend"
  username               = "root"
  password               = "Redhat123"  # Change this in production!
  parameter_group_name   = "default.mysql8.0"
  skip_final_snapshot    = true
  publicly_accessible    = false
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = var.db_subnet_group_name

  tags = {
    Name = "mysql-db"
  }
}

output "rds_endpoint" {
  value = aws_db_instance.mysql.endpoint
}

output "rds_address" {
  value = aws_db_instance.mysql.address
}

