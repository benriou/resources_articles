resource "aws_iam_instance_profile" "bastion" {
  name = "bastion"
  role = aws_iam_role.bastion.name
}

resource "aws_iam_role" "bastion" {
  name = "bastion"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

#this allows to connect to the EC2 instance
resource "aws_iam_role_policy_attachment" "bastion_ssm" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


resource "aws_iam_role_policy_attachment" "ec2_instance_connect" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceConnect"
}

##########################################
### Security Group Bastion
resource "aws_security_group" "bastion_in_out" {
  name        = "bastion"
  description = "Bastion SSH access"
  vpc_id      = var.vpc_id
}


# Everyone from that security group can contact
resource "aws_security_group_rule" "bastion_in_self" {
  type      = "ingress"
  from_port = 1
  to_port   = 65535
  protocol  = -1
  self      = true

  security_group_id = aws_security_group.bastion_in_out.id
}

## OUTBOUND rules

# Everyone from that security group can contact
resource "aws_security_group_rule" "bastion_out_everywhere" {
  type        = "egress"
  from_port   = 0
  to_port     = 65365
  protocol    = -1
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.bastion_in_out.id
}

##############################################################
# LAUNCH TEMPLATE
##############################################################
resource "aws_launch_template" "bastion" {
  name        = "bastion"
  description = "Bastion (Amazon Linux 2 AMI ARM)"

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 20
    }
  }

  capacity_reservation_specification {
    capacity_reservation_preference = "open"
  }


  credit_specification {
    cpu_credits = "unlimited"
  }

  disable_api_termination = false

  ebs_optimized = true

  iam_instance_profile {
    name = aws_iam_instance_profile.bastion.name
  }

  image_id = "ami-0c669fe429b4cf93d"

  instance_initiated_shutdown_behavior = "terminate"

  instance_type = var.instance_type

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.bastion_in_out.id]
  }
  monitoring {
    enabled = true
  }

  placement {
    group_name = aws_placement_group.bastion.name
  }

  # These tags are set to the created resource
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "bastion"
    }
  }

}

##########################################
### AutoScalling Group
##########################################

resource "aws_placement_group" "bastion" {
  name     = "bastion"
  strategy = "spread"
}

resource "aws_autoscaling_group" "bastion" {
  name                = "bastion"
  desired_capacity    = 1
  max_size            = 1
  min_size            = 1
  vpc_zone_identifier = var.vpc_private_subnets_identifier

  launch_template {
    id      = aws_launch_template.bastion.id
    version = aws_launch_template.bastion.latest_version

  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }
}
