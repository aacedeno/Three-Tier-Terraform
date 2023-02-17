#------ compute/variables.tf -----



variable "key_name" {}
variable "public_key_path" {}

variable "instance_type_web" {}
variable "web_server_sg" {}
variable "public_subnets" {}
variable "web_min_size" {}
variable "web_max_size" {}
variable "web_desired" {}

variable "instance_type_app" {}
variable "private_subnets" {}
variable "app_server_sg" {}
variable "app_min_size" {}
variable "app_max_size" {}
variable "app_desired" {}

variable "bastion_sg" {}
variable "ext_alb_tg" {}


