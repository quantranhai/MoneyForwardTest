# Variables
variable "vpc_id" {}
variable "vpc_zone_identifier" {}
variable "environment" {}
#variable "ami" {}
variable "instance_type" {
  description = "Type of bastion ec2 instances"
  default     = "t2.micro"
}
variable "bastion_key_name" {}

# Data
data "aws_ami" "bastion_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}


# Resources
/* Bastion Security group */
resource "aws_security_group" "bastion_sg" {


  vpc_id      = "${var.vpc_id}"
  name        = "${var.environment}-bastion-host"
  description = "Allow SSH to bastion host"

  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "8"
    to_port     = "0"
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.environment}-bastion-sg"}
}

/* Bastion Launch Configuration */
resource "aws_launch_configuration" "bastion_launch_configuration" {
  name_prefix                 = "${var.environment}_bastion_lc-"
  image_id                    = "${data.aws_ami.bastion_ami.id}"
  instance_type               = "${var.instance_type}"
  key_name                    = "${var.bastion_key_name}"
  security_groups             = ["${aws_security_group.bastion_sg.id}"]
  ebs_optimized               = "true"
  associate_public_ip_address = "true"
  root_block_device {
    volume_type               = "gp2"
    volume_size               = "10"
  }
  lifecycle {
    create_before_destroy     = "true"
  }
}


/* Bastion Auto-Scaling Group */
resource "aws_autoscaling_group" "bastion_asg" {
  name                 = "${var.environment}_bastion_asg"
  max_size             = "2"
  min_size             = "2"
  desired_capacity     = "2"
  launch_configuration = "${aws_launch_configuration.bastion_launch_configuration.name}"
  vpc_zone_identifier  = ["${var.vpc_zone_identifier}"]
}
