# roboshop-dev
resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  instance_tenancy     = "default"
  enable_dns_hostnames = "true"

  tags = merge(
    local.common_tags,
    {
      Name : "${var.project}-${var.environment}"
    }
  )

}

# IGW roboshop-dev
resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.IGW_tags,
    local.common_tags,
    {
      Name = "${var.project}-${var.environment}"
    }
  )
}


# Public subnets - us-east-1

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidr)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr[count.index]
  availability_zone       = local.az_names[count.index]
  map_public_ip_on_launch = true


  tags = merge(
    var.public_subnet_cidr_tags,
    local.common_tags,
    {
      Name = "${var.project}-${var.environment}-public-${local.az_names[count.index]}"
    }
  )


}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidr)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr[count.index]
  availability_zone = local.az_names[count.index]



  tags = merge(
    var.private_subnet_cidr_tags,
    local.common_tags,
    {
      Name = "${var.project}-${var.environment}-private-${local.az_names[count.index]}"
    }
  )


}


resource "aws_subnet" "database" {
  count             = length(var.database_subnet_cidr)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.database_subnet_cidr[count.index]
  availability_zone = local.az_names[count.index]



  tags = merge(
    var.database_subnet_cidr_tags,
    local.common_tags,
    {
      Name = "${var.project}-${var.environment}-database-${local.az_names[count.index]}"
    }
  )


}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(
    var.eip_tags,
    local.common_tags,
    {
      Name = "${var.project}-${var.environment}"
    }
  )
}
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id # Use first public subnet(since there are 2 public subnets )

  tags = merge(
    var.nat_gateway_tags,
    local.common_tags,
    {
      Name = "${var.project}-${var.environment}"
    }

  )

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.IGW]
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = merge(
    var.public_route_tags,
    local.common_tags,

    {
      Name = "${var.project}-${var.environment}-public"
    }

  )
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = merge(
    var.public_route_tags,
    local.common_tags,

    {
      Name = "${var.project}-${var.environment}-private"
    }

  )
}

resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id
  tags = merge(
    var.public_route_tags,
    local.common_tags,

    {
      Name = "${var.project}-${var.environment}-database"
    }

  )
}


resource "aws_route" "public" {                           # Creating a route inside a route table
  route_table_id         = aws_route_table.public.id      # Which route table to update
  destination_cidr_block = "0.0.0.0/0"                    # Destination: all internet traffic
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id # Send traffic through NAT Gateway
}

resource "aws_route" "private" {                          # Creating a route inside a route table
  route_table_id         = aws_route_table.private.id     # Which route table to update
  destination_cidr_block = "0.0.0.0/0"                    # Destination: all internet traffic
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id # Send traffic through NAT Gateway
}


resource "aws_route" "database" {                         # Creating a route inside a route table
  route_table_id         = aws_route_table.database.id    # Which route table to update
  destination_cidr_block = "0.0.0.0/0"                    # Destination: all internet traffic
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id # Send traffic through NAT Gateway
}


resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidr)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidr)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "database" {
  count          = length(var.database_subnet_cidr)
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}
