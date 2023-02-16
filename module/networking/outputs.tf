#------ networking/outputs.tf --------

output "vpc_id" {
  value = aws_vpc.prod_vpc.id
}

output "aws_db_subnet_group_name" {
  value = aws_db_subnet_group.prod_rds_subnetgroup.*.name #Outputs every private subnet
}

output "db_security_group" {
  value = [aws_security_group.prod_rds_sg.id]
}

#-----ALB ------

output "ext_lb_security_group" {
  value = [aws_security_group.ext_prod_lb_sg.id]
}

output "int_lb_security_group" {
  value = [aws_security_group.int_prod_lb_sg.id]
}

output "public_subnets" {
  value = [aws_subnet.prod_public_subnet.*.id]
}