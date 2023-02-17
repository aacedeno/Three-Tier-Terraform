# ----- compute /main.tf ------

#---- AMI ------
data "aws_ami" "server_ami" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"] #Gets latest version
  }
}


# #Creates a random id to tell our instances apart
# resource "random_id" "prod_node_id" {
#     byte_length = 2 
# }

resource "aws_key_pair" "server_auth" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

#----- Launch template and auto scaling group for web servers

resource "aws_launch_template" "web_server_template" {
  name_prefix            = "web_server_template"
  instance_type          = var.instance_type_web
  image_id               = data.aws_ami.server_ami.id
  vpc_security_group_ids = [var.web_server_sg]
  # user_data              = filebase64("install_nginx.sh")
  key_name = aws_key_pair.server_auth.id

  tags = {
    Name = "web_server-${substr(uuid(), 0, 3)}"
  }
}

#Retrieving data from target group 
data "aws_lb_target_group" "web_servers_tg" {
  name = var.ext_alb_tg.name
}

resource "aws_autoscaling_group" "web_server_asg" {
  name                = "web_server_asg"
  vpc_zone_identifier = var.public_subnets
  min_size            = var.web_min_size #2
  max_size            = var.web_max_size #5
  desired_capacity    = var.web_desired  #2

  target_group_arns = [data.aws_lb_target_group.web_servers_tg.arn]

  launch_template {
    id      = aws_launch_template.web_server_template.id
    version = "$Latest"
  }
}

#----- Launch template and auto scaling group for app tier

resource "aws_launch_template" "app_server_template" {
  name_prefix            = "app_server_template"
  instance_type          = var.instance_type_app
  image_id               = data.aws_ami.server_ami.id
  vpc_security_group_ids = [var.app_server_sg]
  # user_data              = filebase64("install_nginx.sh")
  key_name = aws_key_pair.server_auth.id

  tags = {
    Name = "app_server-${substr(uuid(), 0, 3)}"
  }
}

resource "aws_autoscaling_group" "app_server_asg" {
  name                = "app_server_asg"
  vpc_zone_identifier = var.private_subnets
  min_size            = var.app_min_size #2
  max_size            = var.app_max_size #4
  desired_capacity    = var.app_desired  #2

  launch_template {
    id      = aws_launch_template.app_server_template.id
    version = "$Latest"
  }
}

#------- Launch template and auto scaling group for app tier
resource "aws_launch_template" "bastion_template" {
  name_prefix            = "bastion_template"
  instance_type          = var.instance_type_web
  image_id               = data.aws_ami.server_ami.id
  vpc_security_group_ids = [var.bastion_sg]
  key_name               = aws_key_pair.server_auth.id

  tags = {
    Name = "bastion_template"
  }
}

resource "aws_autoscaling_group" "bastion_asg" {
  name                = "three_tier_bastion"
  vpc_zone_identifier = var.public_subnets
  min_size            = 1
  max_size            = 1
  desired_capacity    = 1

  launch_template {
    id      = aws_launch_template.bastion_template.id
    version = "$Latest"
  }
}




# #--- Web Servers 
# resource "aws_instance" "web_server" {
#     count = var.instance_count
#     instance_type = var.instance_type
#     ami = data.aws_ami.server_ami
#     tags = {
#         Name = "web_server-${random_id.prod_node_id[count.index].dec}"
#     }
# }

# #key_name = 
# vpc_security_group_ids = 
# subnet_id
# #user_data
# rooot_block_device {
#     volume_size = var.vol_size
# }