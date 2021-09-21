# Variables

variable "vpc_cidr" {}
variable "private_cidrs" {}
variable "public_cidrs" {}
variable "environment" {}
variable "availability_zone" {
  description = "The az that the resources will be launched"
}

# Resources
resource "aws_vpc" "vpc" {
  cidr_block  = "${var.vpc_cidr}"
  tags = { Name = "${var.environment}-vpc"}
}

/* Internet gateway for the PUBLIC subnet */
resource "aws_internet_gateway" "public" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags = { Name = "${var.environment}-igw" }
}

/* Elastic IP for NAT */
resource "aws_eip" "nat_eip" {
  vpc        = true
  count      = "${length(split(",", var.public_cidrs))}"
}

/* NAT */
resource "aws_nat_gateway" "nat" {
  #allocation_id = "${aws_eip.nat_eip.id}"
  #subnet_id     = "${aws_subnet.public_subnet.id}"
  count          = "${length(split(",", var.public_cidrs))}"
  allocation_id  = "${element(aws_eip.nat_eip.*.id,count.index)}"
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
}

/* Public subnets */

resource "aws_subnet" "public" {
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "${element(split(",", var.public_cidrs), count.index)}"
  availability_zone = "${element(split(",", var.availability_zone), count.index)}"
  count             = "${length(split(",", var.public_cidrs))}"

  lifecycle { create_before_destroy = true }
  tags = { Name = "${var.environment}-public-${element(split(",", var.availability_zone), count.index)}" }

  map_public_ip_on_launch = true
}

/* Routing table for public subnet */
resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = "${aws_internet_gateway.public.id}"
  }
}

resource "aws_route" "public_internet_gateway" {
  count                  = "${length(split(",", var.public_cidrs))}"
  route_table_id         = "${aws_route_table.public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.public.id}"
}

resource "aws_route_table_association" "public" {
  count          = "${length(split(",", var.public_cidrs))}"
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}

/* Private subnets */
resource "aws_subnet" "private" {
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "${element(split(",", var.private_cidrs), count.index)}"
  availability_zone = "${element(split(",", var.availability_zone), count.index)}"
  count             = "${length(split(",", var.private_cidrs))}"

  tags = { Name = "${var.environment}.${element(split(",", var.availability_zone), count.index)}" }
}

/* Routing table for private subnet */

resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.vpc.id}"
  /*count  = "${length(split(",", var.private_cidrs))}"

  #route {
  #  cidr_block  = "0.0.0.0/0"
  #  instance_id = "${element(aws_nat_gateway.nat.*.id, count.index)}"

  }*/
}

resource "aws_route_table_association" "private" {
  count          = "${length(split(",", var.private_cidrs))}"
  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  #route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}


/* Routing table for internet and NAT subnet */


resource "aws_route" "private_nat_gateway" {
  count                  = "${length(split(",", var.private_cidrs))}"
  route_table_id         = "${aws_route_table.private.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${element(aws_nat_gateway.nat.*.id, count.index)}"

}

/* Default security group */
resource "aws_security_group" "default" {
  name        = "${var.environment}-default-sg"
  description = "Default security group to allow inbound/outbound from the VPC"
  vpc_id      = "${aws_vpc.vpc.id}"

  ingress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = true
  }
  egress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = "true"
  }
  tags = { Environment = "${var.environment}"}
}