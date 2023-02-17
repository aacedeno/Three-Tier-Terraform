#--- root/main.tf ---

locals {
  vpc_cidr = "10.10.0.0/16"
}


module "networking" {
  source           = "./module/networking"
  vpc_cidr         = local.vpc_cidr
  access_ip        = var.access_ip
  ssh_access_ip    = var.ssh_access_ip
  public_sn_count  = 2 #Variable defines how many subnets need to be created
  private_sn_count = 4 #The numbers specfified here will pass through child module and the subnets will be created using the for loop defined in public/private_cidrs 
  max_subnets      = 20
  public_cidrs     = [for i in range(2, 255, 2) : cidrsubnet(local.vpc_cidr, 8, i)] #Defines the cidr blocks used in the VPC, 
  private_cidrs    = [for i in range(1, 255, 2) : cidrsubnet(local.vpc_cidr, 8, i)] #Subnets do not go higher than 255 so that is set to the max value
  db_subnet_group  = true

}

module "database" {
  source                 = "./module/database"
  db_storage             = 10
  db_engine_version      = "8.0.30"
  db_instance_class      = "db.t3.micro"
  db_name                = var.db_name
  dbuser                 = var.dbuser
  dbpassword             = var.dbpassword
  db_identifier          = "prod-db"
  skip_db_snapshot       = true                                          #In prod it should most liekly be set to false
  db_subnet_group_name   = module.networking.aws_db_subnet_group_name[0] #Use count index to specify 1 private subent for db instance
  vpc_security_group_ids = module.networking.db_security_group
}

module "public-alb" {
  source                     = "./module/loadbalancing"
  extlb_prod_sg              = module.networking.extlb_prod_sg
  public_subnets             = module.networking.public_subnets
  web_tg_port                = 80
  web_tg_protocol            = "HTTP"
  vpc_id                     = module.networking.vpc_id
  web_lb_healthy_threshold   = 2
  web_lb_unhealthy_threshold = 2
  web_lb_timeout             = 3
  web_lb_interval            = 30
  ext_listener_port          = 80
  ext_listener_protocol      = "HTTP"
}

module "compute" {
  source            = "./module/compute"
  instance_type_web = "t2.micro"
  instance_type_app = "t3.micro"
  public_subnets    = module.networking.public_subnets
  web_server_sg     = module.networking.web_server_sg
  web_min_size      = 2
  web_max_size      = 5
  web_desired       = 2
  private_subnets   = module.networking.private_subnets
  app_server_sg     = module.networking.app_server_sg
  app_min_size      = 2
  app_max_size      = 4
  app_desired       = 2
  bastion_sg        = module.networking.bastion_sg
  ext_alb_tg        = module.public-alb.ext_alb_tg
  key_name          = "prodkey"
  public_key_path   = var.public_key_path



}
# module "private-alb" {
#   source = "./module/loadbalancing"
#   intlb_prod_sg = module.networking.intlb_prod_sg
#   private_subnets = module.networking.private_subnets
#   app_tg_port                = 80
#   app_tg_protocol            = "HTTP"
#   vpc_id                     = module.networking.vpc_id
#   app_lb_healthy_threshold   = 2
#   app_lb_unhealthy_threshold = 2
#   app_lb_timeout             = 3
#   app_lb_interval            = 30
#   int_listener_port          = 80
#   int_listener_protocol      = "HTTP"
# }
