# Variables
variable "vpc_id" {}
variable "public_subnet_ids" {}
variable environment {}
variable availability_zone {}
variable "instance_type" {
  description = "Type of ec2 instances"
  default     = "t2.micro"
}
variable "bastion_sg" {}
variable certificate_arn {}

# Data
data "aws_ami" "ecs_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["*-amazon-ecs-optimized"]
  }
}

data "aws_iam_policy_document" "instance" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}


# Resources

resource "aws_iam_instance_profile" "instance" {
  name     = "${var.environment}-profile-instance"
  role     = "${aws_iam_role.ecs_role.name}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role" "ecs_role" {
  name                = "${var.environment}-project-role"
  path                = "/"
  assume_role_policy  = "${data.aws_iam_policy_document.instance.json}"
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"]
  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_ecs_cluster" "nginx" {
  name = "${var.environment}-nginx"
}

/* ECS Cluster Security group */
resource "aws_security_group" "ecs_cluster_sg" {
  vpc_id      = "${var.vpc_id}"
  name        = "${var.environment}-ecs_cluster_sg"
  description = "Allow access to Cluster EC2 instance host"

  ingress {
    from_port       = "22"
    to_port         = "22"
    protocol        = "tcp"
    security_groups = ["${var.bastion_sg}"]
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
  ingress {
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = "8080"
    to_port     = "8080"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = "8081"
    to_port     = "8081"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.environment}-ecs-cluster-sg" }
}

resource "aws_launch_configuration" "ecs_instance"{
  name_prefix     = "${var.environment}-ecs-instance-"
  instance_type   = "${var.instance_type}"
  image_id        = "${data.aws_ami.ecs_ami.id}"
  security_groups = ["${aws_security_group.ecs_cluster_sg.id}"]
}

resource "aws_autoscaling_group" "ecs_cluster"{
  availability_zones   = ["${var.availability_zone}"]
  name                 = "${var.environment}-ecs-cluster"
  min_size             = 1
  max_size             = 2
  launch_configuration = "${aws_launch_configuration.ecs_instance.name}"
}

resource "aws_ecs_task_definition" "app" {
  family = "nginxapp"
  container_definitions = <<EOF
  [
    {
      "name": "nginx",
      "image": "nginx",
      "essential": true,
      "portMappings": [{"containerPort":80, "hostPort":80}]
    },
    {
      "name": "registry",
      "image": "docker.bintray.io/reg2/jfrog/artifactory-registry:4.16.1",
      "cpu": 100,
      "memory": 512,
      "essential": true,
      "portMappings": [{"containerPort":8081, "hostPort":8081}, {"containerPort":8082, "hostPort":8082}]
    }
  ]
  EOF
}


resource "aws_ecs_service" "nginx" {
  name             = "${var.environment}-nginx"
  cluster          = "${aws_ecs_cluster.nginx.id}"
  task_definition  = "${aws_ecs_task_definition.app.arn}"
  desired_count    = 1
  iam_role         = "${aws_iam_role.ecs_role.arn}"
  load_balancer {
    elb_name       = "${aws_elb.nginx.id}"
    container_name = "nginx"
    container_port = 80
  }
}
resource "aws_elb" "nginx" {
  availability_zones    = ["${var.availability_zone}"]
  subnets               = ["${var.public_subnet_ids}"]
  name                  = "${var.environment}-nginx"
  listener {
    instance_port       = 80
    instance_protocol   = "http"
    lb_port             = 80
    lb_protocol         = "http"
  }

  dynamic "listener" {
    for_each = var.certificate_arn != "" ? [1]: []
    content {
      lb_port             = 443
      lb_protocol         = "https"
      instance_port       = 80
      instance_protocol   = "http"
      ssl_certificate_id  = "${var.certificate_arn}"
    }
  }
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }
}