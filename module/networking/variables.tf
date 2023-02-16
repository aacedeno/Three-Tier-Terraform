#------ networking/variables.tf -----
variable "vpc_cidr" {
  type = string
}

variable "public_cidrs" {
  type = list(any)
}

variable "private_cidrs" {
  type = list(any)
}
variable "private_sn_count" {
  type = number
}
variable "public_sn_count" {
  type = number
}

variable "max_subnets" {
  type = number
}
variable "access_ip" {
  type = string
}

variable "ssh_access_ip" {
  type = string
}

variable "db_subnet_group" {
  type = bool
}