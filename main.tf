provider "aws"{
        region = "eu-west-1"

}

resource "aws_instance" "app_instance" {
    ami = "ami-00e8ddf087865b27f"
    instance_type = "t2.micro"
    associate_public_ip_address = true
    tags = {
        Name = "SRE_kieron_terraform_app"
    }
}