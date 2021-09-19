provider "aws"{
        region = "eu-west-1"

}

resource "aws_vpc" "sre_kieron_dbVPC" {
    cidr_block = "10.108.0.0/16"
    instance_tenancy = "default"

    tags = {
        Name = "sre_kieron_dbVPC"
    }
}

resource "aws_internet_gateway" "sre_kieron_internetg_db" {
    vpc_id = var.vpc_id_db

    tags = {
        Name = "sre_kieron_internetg_db"
    }
}

resource "aws_subnet" "sre_kieron_app_privsubnet"{
        availability_zone = "eu-west-1a"
        vpc_id = var.vpc_id_db
        cidr_block = "10.108.2.0/24"
        map_public_ip_on_launch = "false"

        tags = {
            Name = "sre_kieron_app_privsubnet"
        }
}

resource "aws_security_group" "sre_kieron_secgroup_db"{
    description = "The Security group for my db "
    vpc_id = var.vpc_id_db

    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 27017
        to_port = 27017
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    
    tags = {
      Name = "sre_kieron_secgroup_db"
    }
}

 resource "aws_route" "r"{
     route_table_id = var.aws_routet_priv
     destination_cidr_block = "0.0.0.0/0"
     gateway_id = var.internetg_id_db
 }
#resource "aws_route_table" "sre_kieron_pub_route" {
#    vpc_id = var.vpc_id
#    route {
#        cidr_block = "0.0.0.0/0"
#        gateway_id = var.internetg_id
#    }
#        tags = {
#            Name = "sre_kieron_pub_route"
#        }
#   }

#data "aws_internet_gateway" "default" {
#    filter {
#        name = "attachment.vpc-id"
#        values = [var.vpc_id]
#    }
#}
resource "aws_instance" "sre_kieron_terraform_db" {
    ami = "ami-090c2e11c335f901c"
    subnet_id = var.aws_subnet_priv
    vpc_security_group_ids = [var.aws_secgroup_db]
    instance_type = "t2.micro"
    associate_public_ip_address = false
    key_name = var.aws_key_name
    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = var.aws_key_path
      host = "${self.associate_public_ip_address}"
    }

    tags = {
        Name = "SRE_kieron_terraform_db"
    }
}
