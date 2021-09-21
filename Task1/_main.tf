# RESOURCES

provider "aws" {
  shared_credentials_file  = "${var.cred-file}"
  region = "ap-southeast-1"
}

resource "aws_key_pair" "key" {
  key_name   = "${var.environment}"
  public_key = "${file("./.ssh/ssh_key.pub")}"
}

module "networking" {
  source              = "./modules/networking"
  environment         = "${var.environment}"
  availability_zone   = "${var.availability_zone}"
  vpc_cidr            = "${var.vpc_cidr}"
  public_cidrs        = "${var.public_cidrs}"
  private_cidrs       = "${var.private_cidrs}"
}

module "bastion" {
  source              = "./modules/bastion"
  vpc_id              = "${module.networking.vpc_id}"
  environment         = "${var.environment}"
  instance_type       = "t2.micro"
  bastion_key_name    = "${aws_key_pair.key.key_name}"
  vpc_zone_identifier = "${module.networking.public_subnet_ids}"
}

module "cluster" {
  source              = "./modules/ecs-cluster"
  vpc_id              = "${module.networking.vpc_id}"
  public_subnet_ids   = "${module.networking.public_subnet_ids}"
  bastion_sg          = "${module.bastion.bastion_sg}"
  environment         = "${var.environment}"
  instance_type       = "t2.micro"
  availability_zone   = "${var.availability_zone}"
  certificate_arn     = "${var.certificate_arn}"
}


module "rds" {
  source              = "./modules/database"
  environment         = "${var.environment}"
  db_instance_class   = "db.t2.micro"
  availability_zone   = "${var.availability_zone}"
}

resource "aws_s3_bucket" "app_bucket" {
  bucket_prefix       = "${var.environment}-nginx-app-"
  acl                 = "private"
  tags                = {Name  = "${var.environment}-nginx-app"}
}
