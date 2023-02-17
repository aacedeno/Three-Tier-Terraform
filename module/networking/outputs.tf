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

#------Compute -------
output "web_server_sg" {
  value = aws_security_group.web_servers_sg.id
}

output "app_server_sg" {
  value = aws_security_group.app_servers_sg.id
}

output "bastion_sg" {
  value = aws_security_group.prod_bastion_sg.id
}


#-----ALB ------

output "extlb_prod_sg" {
  value = [aws_security_group.ext_prod_lb_sg.id]
}

output "public_subnets" {
  value = aws_subnet.prod_public_subnet.*.id
}

output "private_subnets" {
  value = aws_subnet.prod_private_subnet.*.id
}

# output "intlb_prod_sg" {
#   value = [aws_security_group.int_prod_lb_sg.id]
# }


#I may need to use the first 2 subnets since the last 2 are assign to rds subnet 
#[aws_subnet.prod_private_subnet[0].id, aws_subnet.prod_private_subnet[1].id] 