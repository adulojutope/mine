resource "aws_vpc" "demo" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "demo-vpc"
  }
}


resource "aws_subnet" "public_subnet_1" {
  vpc_id     = aws_vpc.demo.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id     = aws_vpc.demo.id
  cidr_block = "10.0.11.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public2"
  }
}

resource "aws_subnet" "private_subnet_apptier1" {
  vpc_id     = aws_vpc.demo.id
  cidr_block = "10.0.21.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "private_apptier1"
  }
}

resource "aws_subnet" "private_subnet_apptier2" {
  vpc_id     = aws_vpc.demo.id
  cidr_block = "10.0.31.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "private_apptier2"
  }
}

resource "aws_subnet" "private_subnet_databasetier1" {
  vpc_id     = aws_vpc.demo.id
  cidr_block = "10.0.41.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "private_databasetier1"
  }
}


resource "aws_subnet" "private_subnet_databasetier2" {
  vpc_id     = aws_vpc.demo.id
  cidr_block = "10.0.51.0/24"
  availability_zone = "us-east-1b"


  tags = {
    Name = "private_databasetier2"
  }
}

 

 resource "aws_internet_gateway" "demo-gateway" {
  vpc_id = aws_vpc.demo.id

  tags = {
    Name = "demo-gateway"
  }
}

resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "demo-nat-gateway1" {
 subnet_id      = aws_subnet.public_subnet_2.id
  allocation_id = aws_eip.nat.id
  depends_on = [aws_internet_gateway.demo-gateway]
}


resource "aws_route_table" "demo-route-table_public" {
  vpc_id = aws_vpc.demo.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo-gateway.id
  }


  tags = {
    Name = "demo-route-table_public"
  }
}

resource "aws_route_table" "demo-route-table_private1" {
  vpc_id = aws_vpc.demo.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.demo-nat-gateway1.id
  }


  tags = {
    Name = "demo-route-table_private1"
  }
}



resource "aws_route_table_association" "association_public_subnet" {
    for_each = {
        web1 = aws_subnet.public_subnet_1.id
        web2 = aws_subnet.public_subnet_2.id}

  subnet_id      = each.value   
  route_table_id = aws_route_table.demo-route-table_public.id
}

resource "aws_route_table_association" "association_private_subnet_apptier" {
    for_each = {apptier1 = aws_subnet.private_subnet_apptier1.id, apptier2 = aws_subnet.private_subnet_apptier2.id}
  subnet_id      = each.value
  route_table_id = aws_route_table.demo-route-table_private1.id
}


