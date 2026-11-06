terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.67.0"
    }
  }
}

provider "aws" {
  # Configuration options
  region = "us-east-1"
}

resource "aws_vpc" "vpc" {
  cidr_block       = "192.168.0.0/19"
  instance_tenancy = "default"
  enable_dns_hostnames= true

  tags = {
    Name = "newvpc"
  }
}

resource "aws_subnet" "dmzsub1" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "192.168.0.0/23" 
  availability_zone="us-east-1a"
  tags = {
    Name = "dmzsub1"
  }
}

resource "aws_subnet" "dmzsub2" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "192.168.2.0/23" 
  availability_zone="us-east-1b"
  tags = {
    Name = "dmzsub2"
  }
}

resource "aws_subnet" "pubsub1" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "192.168.4.0/23" 
  availability_zone="us-east-1a"
  map_public_ip_on_launch= true
  tags = {
    Name = "pubsub1"
  }
}

resource "aws_subnet" "pubsub2" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "192.168.6.0/23" 
  availability_zone="us-east-1b"
  map_public_ip_on_launch= true
  tags = {
    Name = "pubsub2"
  }
}

resource "aws_subnet" "privsub1" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "192.168.8.0/23" 
  availability_zone="us-east-1a"
  tags = {
    Name = "privsub1"
  }
}

resource "aws_subnet" "privsub2" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "192.168.10.0/23" 
  availability_zone="us-east-1b"
  tags = {
    Name = "privsub2"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "igw"
  }
}


resource "aws_route_table" "dmzrt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "dmzrt"
  }
}

resource "aws_route_table" "pubrt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "pubrt"
  }
}

resource "aws_route_table" "privrt" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "privrt"
  }
}


resource "aws_route_table_association" "dmz1" {
  subnet_id      = aws_subnet.dmzsub1.id
  route_table_id = aws_route_table.dmzrt.id
}

resource "aws_route_table_association" "dmz2" {
  subnet_id      = aws_subnet.dmzsub2.id
  route_table_id = aws_route_table.dmzrt.id
}

resource "aws_route_table_association" "pub1" {
  subnet_id      = aws_subnet.pubsub1.id
  route_table_id = aws_route_table.pubrt.id
}

resource "aws_route_table_association" "pub2" {
  subnet_id      = aws_subnet.pubsub2.id
  route_table_id = aws_route_table.pubrt.id
}

resource "aws_route_table_association" "priv1" {
  subnet_id      = aws_subnet.privsub1.id
  route_table_id = aws_route_table.privrt.id
}

resource "aws_route_table_association" "priv2" {
  subnet_id      = aws_subnet.privsub2.id
  route_table_id = aws_route_table.privrt.id
}

resource "aws_security_group" "loadsg" {
  name        = "loadsg"
  description = "loadbalancer sg"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.vpc.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "loadsg"
  }
}

resource "aws_security_group" "appsg" {
  name        = "appsg"
  description = "Application sg"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.vpc.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "appsg"
  }
}


resource "aws_launch_template" "lc" {
  name = "redhattemplate2"

  block_device_mappings {
    device_name = "/dev/sdf"

    ebs {
      volume_size = 10
    }
  }

  image_id = "ami-00adafae70b8029d8"

  instance_initiated_shutdown_behavior = "terminate"

  instance_type = "t3.micro"

  key_name = "demokey8am"
/*
  network_interfaces {
    associate_public_ip_address = true
  }

*/
  

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "redhattemplate2"
    }
  }

  user_data = filebase64("${path.module}/httpd.sh")
}

resource "aws_lb" "alb" {
  name               = "alb-10"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.loadsg.id]
  subnets            = ["${aws_subnet.dmzsub1.id}","${aws_subnet.dmzsub2.id}"]

 
  tags = {
    Environment = "production"
  }
}

resource "aws_lb_target_group" "tg10" {
  name     = "tf-10"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id
}

resource "aws_lb_listener" "alblistener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg10.arn
  }
}



resource "aws_autoscaling_group" "asg" {
  //availability_zones = ["us-east-1a","us-east-1b"]
  desired_capacity   = 4
  max_size           = 6
  min_size           = 2
  target_group_arns = ["${aws_lb_target_group.tg10.arn}"]
  vpc_zone_identifier =["${aws_subnet.pubsub1.id}","${aws_subnet.pubsub2.id}"]

  launch_template {
    id      = aws_launch_template.lc.id
    version = "$Latest"
  }
   tag {
    key                 = "Name"
    value               = "asg-11am"
    propagate_at_launch = true
  }
  
}

resource "aws_autoscaling_notification" "asg_activity_notification" {
  group_names = [
    "${aws_autoscaling_group.asg.name}"
  ]

  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR"
  ]

  topic_arn = "arn:aws:sns:us-east-1:212150477621:automaticnotification"
}

resource "aws_cloudwatch_metric_alarm" "High_Cpu_Alarm" {
  alarm_name                = "App_High_CPU_Alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "5"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "60"
  statistic                 = "Average"
  threshold                 = "70"
  alarm_description         = "This metric monitors ec2 cpu utilization"

    dimensions= {
        AutoScalingGroupName = "${aws_autoscaling_group.asg.name}"
  }

  alarm_actions     = ["${aws_autoscaling_policy.app_scaleup_policy.arn}"]
}

resource "aws_autoscaling_policy" "app_scaleup_policy" {
  name                   = "app_scaleup_policy"
  scaling_adjustment     = 2
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.asg.name}"
}

resource "aws_cloudwatch_metric_alarm" "Low_Cpu_Alarm" {
  alarm_name                = "App_Low_CPU_Alarm"
  comparison_operator       = "LessThanOrEqualToThreshold"
  evaluation_periods        = "5"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "60"
  statistic                 = "Average"
  threshold                 = "20"
  alarm_description         = "This metric monitors ec2 cpu utilization"

    dimensions = {
        AutoScalingGroupName = "${aws_autoscaling_group.asg.name}"
  }

    alarm_actions     = ["${aws_autoscaling_policy.app_scaledown_policy.arn}"]
}

resource "aws_autoscaling_policy" "app_scaledown_policy" {
  name                   = "app_scaledown_policy"
  scaling_adjustment     = -2
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.asg.name}"
}





