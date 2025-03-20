variable "region" {
  default = "ap-southeast-1"
}

variable "instance_type" {
  default = "t3.medium"
}

variable "key_name" {
  default = "your-key-pair"
}

variable "elb_name" {
  default = "elasticsearch-nlb"
}

variable "desired_capacity" {
  default = 3
}

variable "max_size" {
  default = 6
}

variable "min_size" {
  default = 2
}

variable "vpc_id" {}
variable "ami_id" {}

variable "subnet_ids" {
  type = list(string)
}
variable "data_node_instance_type" {
  default = "r5.xlarge"
}

variable "master_node_instance_type" {
  default = "m5.large"
}
variable "name" {
}
