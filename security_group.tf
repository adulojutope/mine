resource "aws_security_group" "webtier" {
  name        = "webtier"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.demo.id

  tags = {
    Name = "webtier"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_https_ipv4" {
  security_group_id = aws_security_group.webtier.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4" {
  security_group_id = aws_security_group.webtier.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
  security_group_id = aws_security_group.webtier.id
  referenced_security_group_id = aws_security_group.ssh.id
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}



resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.webtier.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# ************************


resource "aws_security_group" "apptier" {
  name        = "apptier"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.demo.id

  tags = {
    Name = "apptier"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_https_ipv4_2" {
  security_group_id = aws_security_group.apptier.id
  referenced_security_group_id = aws_security_group.webtier.id
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4_1" {
  security_group_id = aws_security_group.apptier.id
  referenced_security_group_id = aws_security_group.webtier.id
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh11_ipv4" {
  security_group_id = aws_security_group.apptier.id
  referenced_security_group_id = aws_security_group.ssh.id
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}



resource "aws_vpc_security_group_egress_rule" "allow_all_traffic1_ipv4" {
  security_group_id = aws_security_group.apptier.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


# ************************ ssh 

resource "aws_security_group" "ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.demo.id

  tags = {
    Name = "allow_ssh"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh0_ipv4" {
  security_group_id = aws_security_group.ssh.id
  cidr_ipv4         = "104.6.252.222/32"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

# resource "aws_vpc_security_group_ingress_rule" "allow_ssh2_ipv4" {
#   security_group_id = aws_security_group.ssh.id
#   referenced_security_group_id = aws_vpc_security_group_ingress_rule.allow_ssh0_ipv4.id
#   from_port         = 22
#   ip_protocol       = "tcp"
#   to_port           = 22
#   depends_on = [aws_vpc_security_group_ingress_rule.allow_ssh0_ipv4]
# }

resource "aws_vpc_security_group_egress_rule" "ssh_all_out" {
  security_group_id = aws_security_group.ssh.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# *************************
resource "aws_security_group" "databasetier" {
  name        = "databasetier"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.demo.id

  tags = {
    Name = "allow_databasetier"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_https_ipv4_5" {
  security_group_id = aws_security_group.databasetier.id
  referenced_security_group_id = aws_security_group.apptier.id
  from_port         = 3306
  ip_protocol       = "tcp"
  to_port           = 3306
}

# ************************* EFS

resource "aws_security_group" "efs" {
  name        = "efs"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.demo.id

  tags = {
    Name = "allow_efs"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_https_ipv4_4" {
  security_group_id = aws_security_group.efs.id
  referenced_security_group_id = aws_security_group.apptier.id
  from_port         = 2049
  ip_protocol       = "tcp"
  to_port           = 2049
}

# resource "aws_vpc_security_group_ingress_rule" "allow_https_ipv4_6" {
#   security_group_id = aws_security_group.efs.id
#   referenced_security_group_id = aws_vpc_security_group_ingress_rule.allow_https_ipv4_4.id
#   from_port         = 2049
#   ip_protocol       = "tcp"
#   to_port           = 2049
#   depends_on = [aws_vpc_security_group_ingress_rule.allow_https_ipv4_4]
# }
