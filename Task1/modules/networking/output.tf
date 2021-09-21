output "vpc_id" {
  value = "${aws_vpc.vpc.id}"
}

output "public_subnet_ids" {
  value = "${join(",", aws_subnet.public.*.id)}" 
}

output "private_subnet_ids" {
  value = "${join(",", aws_subnet.private.*.id)}" 
}

output "default_sg_id" {
  value = "${aws_security_group.default.id}"
}