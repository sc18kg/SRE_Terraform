provider "aws"{
        region = "eu-west-1"

}

resource "aws_vpc" "sre_kieron_appVPC" {
    cidr_block = "10.108.0.0/16"
    instance_tenancy = "default"

    tags = {
        Name = "sre_kieron_appVPC"
    }
}

resource "aws_internet_gateway" "sre_kieron_internetg" {
    vpc_id = var.vpc_id

    tags = {
        Name = "sre_kieron_internetg"
    }
}

resource "aws_subnet" "sre_kieron_app_subnet"{
        availability_zone = "eu-west-1a"
        vpc_id = var.vpc_id
        cidr_block = "10.108.1.0/24"
        map_public_ip_on_launch = "true"

        tags = {
            Name = "sre_kieron_app_subnet"
        }
}

resource "aws_security_group" "sre_kieron_secgroup_app"{
    description = "The Security group for my app "
    vpc_id = var.vpc_id

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
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    
    ingress {
        from_port = 3000
        to_port = 3000
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
      Name = "sre_kieron_secgroup_app"
    }
}

 resource "aws_route" "r"{
     route_table_id = var.aws_routet_pub
     destination_cidr_block = "0.0.0.0/0"
     gateway_id = var.internetg_id
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
resource "aws_instance" "sre_kieron_terraform_app" {
    ami = "ami-00e8ddf087865b27f"
    subnet_id = var.aws_subnet_pub
    vpc_security_group_ids = [var.aws_secgroup_app]
    instance_type = "t2.micro"
    associate_public_ip_address = true
    key_name = var.aws_key_name
    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = var.aws_key_path
      host = "${self.associate_public_ip_address}"
    }
    provisioner "remote-exec" {
        inline = [
            "cd app",
            "npm start"
        ]
      
    }
    tags = {
        Name = "SRE_kieron_terraform_app"
    }
}
