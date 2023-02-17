#-----loadbalancing/main.tf ------

resource "aws_lb" "ext_alb" {
  name               = "ext-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.extlb_prod_sg
  subnets            = var.public_subnets
  idle_timeout       = 60
}

resource "aws_lb_listener" "ext_lb_listener" {
  load_balancer_arn = aws_lb.ext_alb.arn
  port              = var.ext_listener_port
  protocol          = var.ext_listener_protocol
  default_action { #An action that will happen for any traffic that hits the listener port on ext ALB 
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_servers_tg.arn
  }
}

#-----Target Group for Web Tier
resource "aws_lb_target_group" "web_servers_tg" {
  name     = "web-lb-tg-${substr(uuid(), 0, 3)}"
  port     = var.web_tg_port
  protocol = var.web_tg_protocol
  vpc_id   = var.vpc_id #Output value from networking module
  lifecycle {
    ignore_changes        = [name] #Anytime the target group name changes it will be ignored
    create_before_destroy = true   #Target group has to be created so listener knows where to go 
  }
  health_check {
    healthy_threshold   = var.web_lb_healthy_threshold   #2
    unhealthy_threshold = var.web_lb_unhealthy_threshold #2
    timeout             = var.web_lb_timeout             #3
    interval            = var.web_lb_interval            #30
  }
}


# # #----Internal ALB -------
# resource "aws_lb" "int_alb" {
#   name               = "int-alb"
#   internal           = true
#   load_balancer_type = "application"
#   security_groups    = var.intlb_prod_sg
#   subnets            = var.private_subnets
#   idle_timeout       = 60
# }

# resource "aws_lb_listener" "int_lb_listener" {
#   load_balancer_arn = aws_lb.int_alb.arn
#   port              = var.app_listener_port
#   protocol          = var.app_listener_protocol
#   default_action { 
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.app_servers_tg.arn
#   }
# }

# #-----Target Group for App Tier
# resource "aws_lb_target_group" "app_servers_tg" {
#   name     = "app-lb-tg-${substr(uuid(), 0, 3)}"
#   port     = var.app_tg_port
#   protocol = var.app_tg_protocol
#   vpc_id   = var.vpc_id
#   lifecycle {
#     ignore_changes = [name]   
#     create_before_destroy = true    
#   }
#   health_check {
#     healthy_threshold   = var.app_lb_healthy_threshold   #2
#     unhealthy_threshold = var.app_lb_unhealthy_threshold #2
#     timeout             = var.app_lb_timeout             #3
#     interval            = var.app_lb_interval            #30
#   }
# }