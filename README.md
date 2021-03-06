# Terraform

## What is Terraform?
Open-source Infrastructure as Code software tool which provides a consistent CLI (command line interface) workflow to manage cloud services. Terraform codifies cloud APIs (application programming interface) which is a software intermediary that allows two applications to talk to each other.
### Write
Write infrastructure as code using declarative configuration files. HashiCorp Configuration Language (HCL) allows for concise descriptions of resources using blocks, arguments and expressions

### Plan
Run terraform plan to check whether the execution plan for a configuration matches your expectations before provisioning or changing infrastructure.

### Apply
Apply changes to hundreds of cloud providers with terraform apply to reach the desired state of the configuration.

## Purpose of Terraform
![terraform](img/terraf.png)

## Benefits
- Lightweight meaning it doesnt slow down your machine
- Cloud Independant so it will connect to any cloud using modules
- Open-source so no costs for use
- Simple language close to JSON which means no indentation issues

## Usage
Running `Terraform` in the command line brings up all the usage for Terraform
```
Main commands:
  init          Prepare your working directory for other commands
  validate      Check whether the configuration is valid
  plan          Show changes required by the current configuration
  apply         Create or update infrastructure
  destroy       Destroy previously-created infrastructure

All other commands:
  console       Try Terraform expressions at an interactive command prompt
  fmt           Reformat your configuration in the standard style
  force-unlock  Release a stuck lock on the current workspace
  get           Install or upgrade remote Terraform modules
  graph         Generate a Graphviz graph of the steps in an operation
  import        Associate existing infrastructure with a Terraform resource
  login         Obtain and save credentials for a remote host
  logout        Remove locally-stored credentials for a remote host
  output        Show output values from your root module
  providers     Show the providers required for this configuration
  refresh       Update the state to match remote systems
  show          Show the current state or a saved plan
  state         Advanced state management
  taint         Mark a resource instance as not fully functional
  test          Experimental support for module integration testing
  untaint       Remove the 'tainted' state from a resource instance
  version       Show the current Terraform version
  workspace     Workspace management

Global options (use these before the subcommand, if any):
  -chdir=DIR    Switch to a different working directory before executing the
                given subcommand.
  -help         Show this help output, or the help for a specified subcommand.
  -version      An alias for the "version" subcommand.
```
## Setting up Terraform
To begin using Terraform we need to create some environmental variables on your system.
`Windows > Edit the system environmental variables > Environmental Variables > Add `
You will need to add two variables:
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY

To start using Terraform we need to create a file names `main.tf`
- Add the code to initialise terraform with provider AWS
```
provider "aws"{
	region = "eu-west-1"

}
```
- Run this code with `terraform init`
- If successful:
```
Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.
```
- You will also notice the creation of two fles `.terraform` and `.terraform.lock.hcl` which should be added to a git ignore.

## Setting up VPC
```
resource "aws_vpc" "sre_kieron_appVPC" {
    cidr_block = "IP.HERE"
    instance_tenancy = "default"

    tags = {
        Name = "sre_kieron_appVPC"
    }
}
```
## Creating an Internet Gateway
```
resource "aws_internet_gateway" "sre_kieron_internetg" {
    vpc_id = var.vpc_id

    tags = {
        Name = "sre_kieron_internetg"
    }
}
```
## Creating a Public Subnet
```
resource "aws_subnet" "sre_kieron_app_subnet"{
        availability_zone = "eu-west-1a"
        vpc_id = var.vpc_id
        cidr_block = "IP.HERE"
        map_public_ip_on_launch = "true"

        tags = {
            Name = "sre_kieron_app_subnet"
        }
}
```
## Creating a Security Group
Here we create the security group for the app, we allow all aceept out with the `egress` and then `port 22`, `port 80` and `port 3000` for the `ingress` rules
```
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
```
## Adding the IG to the Route Table
```
 resource "aws_route" "r"{
     route_table_id = var.aws_routet_pub
     destination_cidr_block = "0.0.0.0/0"
     gateway_id = var.internetg_id
 }
```
## Launching the EC2 instance
After all the previous steps have been completed we are able to launch an EC2 instance using our app AMI with our VPC
```
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
```
To run this new code `terraform plan` if successful run `terraform apply`
This will prompt the user to enter `yes` to build the EC2 instance
- You should see the following:
```
aws_instance.app_instance: Creating...
aws_instance.app_instance: Still creating... [10s elapsed]
aws_instance.app_instance: Still creating... [20s elapsed]
aws_instance.app_instance: Still creating... [30s elapsed]
aws_instance.app_instance: Creation complete after 33s [id=i-0ed97ab41a2475e91]

Apply complete! Resources: 5 added, 0 changed, 0 destroyed.
```
Once completed you can head over to the cloud provider, here is AWS and check out the new instance.

## Creating a Database EC2 instance

## Loadbalancer
![awsload](img/awsload.jpg)
### Launch Configuration
```
resource "aws_launch_configuration" "app_launch_configuration" {
    name = "sre_kieron_launch_conf_app"
    image_id = var.webapp_ami_id
    instance_type = "t2.micro"
```
### Application load balancer
```
resource "aws_lb" "sre_kieron_loadbalancer" {
    name = "sre_kieron_loadbalancer"
    internal = false
    load_balancer_type = "application"
    subnets = [
        var.aws_subnet_priv,
        var.aws_subnet_pub
    ]


    tags = {
        Name = "sre_kieron_load_balancer"
    }
}

```
### Target Group
```
resource "aws_lb_target_group" "sre_kieron_app_targgroup" {
    name = "sre_kieron_app_targgroup"
    port = 80
    protocol = "HTTP"
    vpc_id = var.vpc_id

    tags = {
        Name = "sre_kieron_targgroup"
    }
}

```
### Listener
```
resource "aws_lb_listener" "sre_kieron_listener" {
    load_balancer_arn = aws_lb.sre_kieron_loadbalancer.arn
    port = 80
    protocol = "HTTP"

    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.sre_kieron_app_targgroup.arn
    }
}
```
### Target Group Attachment
```
resource "aws_lb_target_group_attachment" "sre_kieron_targgroup_att" {
    target_group_arn = aws_lb_target_group.sre_kieron_app_targgroup.arn
    target_id = aws_instance.app_instance.id
    port = 80
}
```
## Autoscaling Group and Policies
```

resource "aws_autoscaling_group" "sre_kieron_autoscalegroup" {
    name = "sre_kieron_autoscalegroup"

    min_size = 1
    desired_capacity = 1
    max_size = 3

    vpc_zone_identifier = [
        var.aws_subnet_pub,
        var.aws_subnet_priv
    ]

    launch_configuration = aws_launch_configuration.app_launch_configuration.name
}

resource "aws_autoscaling_policy" "app_ASG_policy" {
    name = "sre_kieron_ASG_policy"
    policy_type = "TargetTrackingScaling"
    estimated_instance_warmup = 100
    # Use "cooldown" or "estimated_instance_warmup"
    # Error: cooldown is only used by "SimpleScaling"
    autoscaling_group_name = aws_autoscaling_group.sre_kieron_autoscalegroup.name

    target_tracking_configuration {
        predefined_metric_specification {
            predefined_metric_type = "ASGAverageCPUUtilization"
        }
        target_value = 50.0
    }
}
```
