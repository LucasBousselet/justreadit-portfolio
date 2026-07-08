resource "aws_db_instance" "justreadit_postgres_db" {
  allocated_storage           = 20
  max_allocated_storage       = 100 # Enables autoscaling because > allocated_storage 
  db_name                     = "justreadit_db"
  engine                      = "postgres"
  engine_version              = "16"
  instance_class              = "db.t4g.micro"
  storage_type                = "gp2"
  identifier                  = "${local.name}-instance-demo"
  username                    = "postgres_admin"
  manage_master_user_password = true # Automatically creates an entry in Secrets Manager
  skip_final_snapshot         = true # For demo app only
  db_subnet_group_name        = aws_db_subnet_group.postgres_subnet_group.name
  publicly_accessible         = false
  storage_encrypted           = true
  deletion_protection         = false
  backup_retention_period     = 7 # Enables automated backups

  vpc_security_group_ids = [
    aws_security_group.sg_rds.id
  ]
}

resource "aws_db_subnet_group" "postgres_subnet_group" {
  name = "${local.name}-postgres-subnet-group"

  subnet_ids = [
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id
  ]

  tags = local.tags
}