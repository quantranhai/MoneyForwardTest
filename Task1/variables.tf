# REQUIRED PARAMETERS

variable "cred-file" {
  description = "AWS credentials location. Ex. ~/.aws/credentials"
  default     = "~/.aws/credentials"
}
variable "certificate_arn" {
 description = "SSL Certificate arn for the Load Balancer connection on port 443. Leave blank to run on port 80 only"
 default     = ""
 #default = "arn:aws:acm:eu-west-1:<account-id>:certificate/<certificate-arn-val>"
}
variable "aws_region" {
  description = "AWS region of the VPC and related resources"
  #default     = "ap-southeast-1"
}
variable "vpc_cidr" {
  description = "The CIDR block of the VPC"
  #default     = "10.0.0.0/16"
}
variable "public_cidrs" {
  description = "The CIDR block of the public subnets"
  #default     = "10.0.128.0/22,10.0.144.0/22"
}
variable "private_cidrs" {
  description = "The CIDR block of the private subnets"
  #default     = "10.0.0.0/19,10.0.32.0/19"
}
variable "environment" {
  description = "deployment environment"
  #default     = "production"
}
variable "availability_zone" {
  description = "The AZ that the resources will be launched"
  #default     = "ap-southeast-1a,ap-southeast-1b"
}