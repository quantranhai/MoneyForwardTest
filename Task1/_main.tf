# RESOURCES

provider "aws" {
  shared_credentials_file  = "${var.cred-file}"
  region = "ap-southeast-1"
}

resource "aws_key_pair" "key" {
  key_name   = "${var.environment}"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAgNMP20LpG1Zop2d/kOoas3vaVtDCuBC4tx5xXgdp9T5LLyclh8ohBpw234/SruMLtbgVbJwTYw0hy3eU4uRQk4V1HPJRUR8Ub3/H8wy27bjzRr07YCb8wg3R76RzAhkzGCTqZ4qRJyUFTDiDuTm6BPHmqhqT1xtj13Wr73VtiWRcDIc1j+b6yTBZ+eJ3Bb6ZRZMxb5qNxTDCL+PHT7WwRVvcxEhlcvdc751hwESy84X/ADt1MthERXLbqFlZTqZzYb/0iQMG+0HzZjNZ6rXf2KRrAiNUWwetoPq434yL9Y4xsE8MC3rLXlmC7l6Lj9NPDF8Qzhqit26gMGqYhJvXQ=="
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
