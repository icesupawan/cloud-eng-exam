variable "alb_name" {}
variable "alb_security_group" {}
variable "subnets" { type = list(string) }
variable "target_group_name" {}
variable "target_port" { default = 3000 }
variable "vpc_id" {}
