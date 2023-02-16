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
  db_identifier          = "aac-db"
  skip_db_snapshot       = true                                          #In prod it should most liekly be set to false
  db_subnet_group_name   = module.networking.aws_db_subnet_group_name[0] #Use count index to specify 1 private subent for db instance
  vpc_security_group_ids = module.networking.db_security_group
}

module "loadbalancing" {
  source = "./module/loadbalancing"
  #   extlb_prod_sg = ""
  #   public_subnets = ""

}