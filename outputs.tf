output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "subnet_private_id" {
  value = [
    for instance in aws_subnet.private :
    {
      id         = instance.id
      cidr_block = instance.cidr_block
    }
  ]
}

output "subnet_public_id" {
  value = [
    for instance in aws_subnet.public :
    {
      id         = instance.id
      cidr_block = instance.cidr_block
    }
  ]
}