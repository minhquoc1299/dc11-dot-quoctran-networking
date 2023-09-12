resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  assign_generated_ipv6_cidr_block = true

  tags = {
    name = "devops-vpc"
  }

}

locals {
  private    = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_v6 = ["2406:da18:03bc:6e01::/64", "2406:da18:03bc:6e02::/64", "2406:da18:03bc:6e03::/64"]
  public     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  zone       = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
}

resource "aws_subnet" "private" {
  count                           = length(local.private)
  vpc_id                          = aws_vpc.vpc.id
  cidr_block                      = local.private[count.index]
  availability_zone               = local.zone[count.index % length(local.zone)]
  ipv6_cidr_block                 = local.private_v6[count.index]
  assign_ipv6_address_on_creation = true

  tags = {
    name = "vpc-private-subnet-${local.private[count.index]}"
  }
}

resource "aws_subnet" "public" {
  count             = length(local.public)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = local.public[count.index]
  availability_zone = local.zone[count.index % length(local.zone)]

  tags = {
    name = "vpc-public-subnet-${local.private[count.index]}"
  }
}

resource "aws_internet_gateway" "igw" {

  vpc_id = aws_vpc.vpc.id
  tags = {
    name = "VPC Internet Gateway"
  }

}

resource "aws_route_table" "route_public_table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    name = "VPC Route Public Table"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.route_public_table.id
}

resource "aws_eip" "eip" {
  domain = "vpc"
}


# IP V6
resource "aws_egress_only_internet_gateway" "egress_gateway" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  route {
    ipv6_cidr_block        = "::/0"
    egress_only_gateway_id = aws_egress_only_internet_gateway.egress_gateway.id
  }

  tags = {
    "Name" = "VPC Route Private Table"
  }
}

resource "aws_route_table_association" "private" {
  for_each       = { for k, v in aws_subnet.private : k => v }
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

# NAT Billing
# IP-V4
# resource "aws_nat_gateway" "nat" {
#   allocation_id = aws_eip.eip.id
#   subnet_id     = aws_subnet.public[0].id

#   tags = {
#     Name = "VPC NAT All private sub -> Public Subnet [${aws_subnet.public[0].cidr_block}] "
#   }

#   depends_on = [aws_internet_gateway.igw]
# }

# resource "aws_route_table" "private" {
#   vpc_id = aws_vpc.vpc.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_nat_gateway.nat.id
#   }

#   tags = {
#     "Name" = "VPC Route Private Table"
#   }
# }

# resource "aws_route_table_association" "private" {
#   for_each       = { for k, v in aws_subnet.private : k => v }
#   subnet_id      = each.value.id
#   route_table_id = aws_route_table.private.id
# }