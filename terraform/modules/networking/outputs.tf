output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets (for ALB)"
  value       = [aws_subnet.pub_1a.id, aws_subnet.pub_1b.id]
}

output "private_subnet_ids" {
  description = "IDs of the private subnets (for ECS tasks)"
  value       = [aws_subnet.pri_1a.id, aws_subnet.pri_1b.id]
}
