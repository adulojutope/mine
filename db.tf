resource "aws_db_subnet_group" "demo" {
  name       = "demo-db-subnet-group"
  subnet_ids = [aws_subnet.private_subnet_databasetier1.id, aws_subnet.private_subnet_databasetier2.id]

  tags = {
    Name = "My DB subnet group"
  }
}

# *********************** mysql database instance
resource "aws_db_instance" "demo" {
  allocated_storage    = 10
  db_name              = "demo_db"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = "foo"
  password             = "foobarbaz"
#   parameter_group_name = "demo.mysql8.0"
  skip_final_snapshot  = true
  db_subnet_group_name = aws_db_subnet_group.demo.name
  vpc_security_group_ids = [aws_security_group.databasetier.id]
  publicly_accessible   = false
  port                 = 3306

}

