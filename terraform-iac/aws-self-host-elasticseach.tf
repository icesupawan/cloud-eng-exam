module "elasticsearch" {
  source         = "./modules/elasticsearch"
  vpc_id        = module.vpc.vpc_id
  subnet_ids     = module.vpc.public_subnet_ids
  data_node_instance_type = "r5.xlarge"
  master_node_instance_type = "m5.large"
  ami_id        = "ami-00ae2c3d8c3a99b5"
  instance_type = "t3.medium"
  key_name      = "es-keypair"
  desired_capacity = "2"
  name = var.name
}
