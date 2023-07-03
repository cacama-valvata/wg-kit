terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.6.2"
    }
  }

  required_version = "~> 1.3"
}

provider "aws" {
	shared_credentials_files = [".secret/credentials"]
	shared_config_files = [".secret/config"]
}


##################
# VPC and Subnets
##################

resource "aws_vpc" "wg-kit_vpc" {
    cidr_block = "10.0.0.0/16"

    tags = {
        Name = "wg-kit_vpc"
    }
}

resource "aws_subnet" "wg-kit_pubn" {
    vpc_id = aws_vpc.wg-kit_vpc.id
    cidr_block = "10.0.0.0/24"

    tags = {
        Name = "wg-kit_pubn"
    }
}

resource "aws_subnet" "wg-kit_privn" {
    vpc_id = aws_vpc.wg-kit_vpc.id
    cidr_block = "10.0.10.0/24"

    tags = {
        Name = "wg-kit_privn"
    }
}

##################
# Gateways
##################

resource "aws_internet_gateway" "wg-kit_igw" {
    vpc_id = aws_vpc.wg-kit_vpc.id
    
    tags = {
        Name = "wg-kit_igw"
    }
}

resource "aws_eip" "wg-kit_ngw_eip" {
    domain = "vpc"
    depends_on = [aws_internet_gateway.wg-kit_igw]
}

resource "aws_nat_gateway" "wg-kit_ngw" {
    allocation_id = aws_eip.wg-kit_ngw_eip.id
    subnet_id = aws_subnet.wg-kit_privn.id

    tags = {
        Name = "wg-kit_ngw"
    }

    depends_on = [aws_internet_gateway.wg-kit_igw]
}

##################
# Route tables
##################

resource "aws_route_table" "wg-kit_pubrt" {
    vpc_id = aws_vpc.wg-kit_vpc.id

    tags = {
        Name = "wg-kit_rt"
    }
}

resource "aws_route" "wg-kit_pub_internet" {
    route_table_id = aws_route_table.wg-kit_pubrt.id

    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.wg-kit_igw.id

}

resource "aws_route_table_association" "wg-kit_pubrt_assoc" {
    subnet_id = aws_subnet.wg-kit_pubn.id
    route_table_id = aws_route_table.wg-kit_pubrt.id
}

resource "aws_route_table" "wg-kit_privrt" {
    vpc_id = aws_vpc.wg-kit_vpc.id

    tags = {
        Name = "wg-kit_rt"
    }
}

resource "aws_route" "wg-kit_priv_internet" {
    route_table_id = aws_route_table.wg-kit_privrt.id

    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.wg-kit_ngw.id
}

resource "aws_route_table_association" "wg-kit_privrt_assoc" {
    subnet_id = aws_subnet.wg-kit_privn.id
    route_table_id = aws_route_table.wg-kit_privrt.id
}

##################
# Security Groups
##################

resource "aws_security_group" "sg_any-all" {
    vpc_id = aws_vpc.wg-kit_vpc.id
    name = "any-all"
    description = "let inside of WG network be trusted, all traffic allowed"

    lifecycle {
        create_before_destroy = true
    }

    tags = {
        Name = "any-all"
    }
}

resource "aws_vpc_security_group_egress_rule" "any-all_egress" {
    security_group_id = aws_security_group.sg_any-all.id

    cidr_ipv4 = "0.0.0.0/0"
    ip_protocol = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "any-all_ingress" {
    security_group_id = aws_security_group.sg_any-all.id

    cidr_ipv4 = "0.0.0.0/0"
    ip_protocol = "-1"
}

resource "aws_security_group" "sg_wg-public" {
    vpc_id = aws_vpc.wg-kit_vpc.id
    name = "wg-public"
    description = "open ports for wireguard instance"

    lifecycle {
        create_before_destroy = true
    }

    tags = {
        Name = "wg-public"
    }
}

resource "aws_vpc_security_group_ingress_rule" "wg-public_tunnel_ingress" {
    security_group_id = aws_security_group.sg_wg-public.id

    cidr_ipv4 = "0.0.0.0/0"
    ip_protocol = "udp"
    from_port = 51820
    to_port = 51820
}

resource "aws_vpc_security_group_ingress_rule" "wg-public_ssh_ingress" {
    security_group_id = aws_security_group.sg_wg-public.id

    cidr_ipv4 = "0.0.0.0/0"
    ip_protocol = "tcp"
    from_port = 22
    to_port = 22
}

resource "aws_vpc_security_group_egress_rule" "wg-public_egress" {
    security_group_id = aws_security_group.sg_wg-public.id

    cidr_ipv4 = "0.0.0.0/0"
    ip_protocol = "-1"
}

##################
# The WG Instance
##################

resource "aws_instance" "wg-kit_node" {
    ami = "ami-0fcf52bcf5db7b003"
    instance_type = "t2.micro"
    key_name = "wg-kit_key"
    subnet_id = aws_subnet.wg-kit_pubn.id
    vpc_security_group_ids = [aws_security_group.sg_wg-public.id]

    tags = {
        Name = "wg-kit_node"
    }

    depends_on = [aws_internet_gateway.wg-kit_igw]
}

resource "aws_eip" "wg-kit_eip" {
    domain = "vpc"
    instance = aws_instance.wg-kit_node.id

    depends_on = [aws_internet_gateway.wg-kit_igw]
}
