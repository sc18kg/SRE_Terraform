# First creating a launch template

resource "aws_launch_template" "app_template" {
    name = "sre_kieron_launchapp_template"
    image_id = var.app_ami_id
    instance_type ="t2.micro"

    key_name = var.aws_key_name
}

# Launch config

resource "aws_launch_configuration" "app_launch_configuration" {
    name = "sre_kieron_launch_conf_app"
    image_id = var.webapp_ami_id
    instance_type = "t2.micro"

# Load balancer

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

# Target group 

resource "aws_lb_target_group" "sre_kieron_app_targgroup" {
    name = "sre_kieron_app_targgroup"
    port = 80
    protocol = "HTTP"
    vpc_id = var.vpc_id

    tags = {
        Name = "sre_kieron_targgroup"
    }
}

# Listener

resource "aws_lb_listener" "sre_kieron_listener" {
    load_balancer_arn = aws_lb.sre_kieron_loadbalancer.arn
    port = 80
    protocol = "HTTP"

    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.sre_kieron_app_targgroup.arn
    }
}

resource "aws_lb_target_group_attachment" "sre_kieron_targgroup_att" {
    target_group_arn = aws_lb_target_group.sre_kieron_app_targgroup.arn
    target_id = aws_instance.app_instance.id
    port = 80
}

# Autoscaling Group

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
