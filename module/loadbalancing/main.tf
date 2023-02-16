# #-----loadbalancing/main.tf ------

# resource "aws_lb" "prod_alb" {
#   name               = "prod-alb"
#   internal           = false
#   load_balancer_type = "application"
#   security_groups    = var.extlb_prod_sg
#   subnets            = var.public_subnets 
#   #[for subnet in aws_subnet.public : subnet.id]
#}



# #----Internal ALB
# resource "aws_lb" "example" {
#   name               = "example"
#   load_balancer_type = "network"

#   subnet_mapping {
#     subnet_id            = aws_subnet.example1.id
#     private_ipv4_address = "10.0.1.15"
#   }

#   subnet_mapping {
#     subnet_id            = aws_subnet.example2.id
#     private_ipv4_address = "10.0.2.15"
#   }
# }