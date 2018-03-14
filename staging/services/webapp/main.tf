# Cloud provider(s)
provider "aws" {
    region = "us-east-1"
}

# The launch configuration that specifies the instances in the ASG
resource "aws_launch_configuration" "example" {
  image_id    = "ami-40d28157"
  instance_type = "t2.micro"
  security_groups = ["${aws_security_group.instance.id}"]

  user_data = <<-EOF
          #!/bin/bash
          echo "Hello, World" > index.html
          nohup busybox httpd -f -p "${var.server_port}" &
          EOF
    lifecycle {
    create_before_destroy = true
    }
}

# The ASG itself that launches between 2 and 10 EC2 instances
resource "aws_autoscaling_group" "example" {
  launch_configuration = "${aws_launch_configuration.example.id}"
  availability_zones = ["${data.aws_availability_zones.all.names}"]

  load_balancers    = ["${aws_elb.example.name}"]
  health_check_type = "ELB" # Use ELB's health check
  
  min_size = 2
  max_size = 10

  tag {
    key         = "Name"
    value         = "terraform-asg-example"
    propagate_at_launch = true
  }
}

# Elastic Load Balancer
resource "aws_elb" "example" {
  name                = "terraform-asg-example"
  availability_zones  = ["${data.aws_availability_zones.all.names}"]
  security_groups     = ["${aws_security_group.elb.id}"]

  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = "${var.server_port}"
    instance_protocol = "http"
  }

  # Sends an HTTP request to the "/" URL of each instance every 30 seconds
  health_check { 
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    target              = "HTTP:${var.server_port}/"
  }
}

# Security group that allows inbound traffic for instances
resource "aws_security_group" "instance" {
  name = "terraform-example-instance"

  ingress {
    from_port = "${var.server_port}"
    to_port   = "${var.server_port}"
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Security group for ELB
resource "aws_security_group" "elb" {
  name = "terraform-example-elb"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Data source for fetching AZs
data "aws_availability_zones" "all" {}