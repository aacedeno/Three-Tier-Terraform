#----- database/main.tf -------

resource "aws_db_instance" "prod_db" {
  allocated_storage      = var.db_storage #10 GiB 
  engine                 = "mysql"        #hardcoded because we don't want it to change 
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  db_name                = var.db_name
  username               = var.dbuser
  password               = var.dbpassword
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = var.vpc_security_group_ids
  identifier             = var.db_identifier
  skip_final_snapshot    = var.skip_db_snapshot
  tags = {
    Name = "prod-db"
  }
}