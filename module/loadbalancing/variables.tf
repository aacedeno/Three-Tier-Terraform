#-----loadbalancing/variables.tf ------

#---External ALB -----
variable "extlb_prod_sg" {}
variable "public_subnets" {}
variable "web_tg_port" {}
variable "web_tg_protocol" {}
variable "vpc_id" {}
variable "web_lb_healthy_threshold" {}
variable "web_lb_unhealthy_threshold" {}
variable "web_lb_timeout" {}
variable "web_lb_interval" {}
variable "ext_listener_port" {}
variable "ext_listener_protocol" {}


# #-----Internal ALB ------
# variable "intlb_prod_sg" {}
# variable "private_subnets" {}
# variable "app_tg_port" {}
# variable "app_tg_protocol" {}
# variable "app_lb_healthy_threshold" {}
# variable "app_lb_unhealthy_threshold" {}
# variable "app_lb_timeout" {}
# variable "app_lb_interval" {}
# variable "int_listener_port" {}
# variable "int_listener_protocol" {}