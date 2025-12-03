# Get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security Group for Scheduling API
resource "aws_security_group" "api" {
  name_prefix = "${var.project_name}-${var.environment}-scheduling-api-"
  description = "Security group for Scheduling API"
  vpc_id      = var.vpc_id

  ingress {
    description = "API port from ALB/App servers"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    security_groups = [var.app_security_group_id]
  }

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-scheduling-api-sg"
      Environment = var.environment
      Service     = "SchedulingAPI"
    },
    var.tags
  )

  lifecycle {
    create_before_destroy = true
  }
}

# CloudWatch Log Group for API
resource "aws_cloudwatch_log_group" "api" {
  name              = "/aws/ec2/${var.project_name}-${var.environment}-scheduling-api"
  retention_in_days = 7

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-scheduling-api-logs"
      Environment = var.environment
    },
    var.tags
  )
}

# Launch Template for Scheduling API
resource "aws_launch_template" "api" {
  name_prefix   = "${var.project_name}-${var.environment}-scheduling-api-"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type

  key_name = var.key_name != "" ? var.key_name : null

  vpc_security_group_ids = [aws_security_group.api.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.api.name
  }

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    project_name = var.project_name
    environment  = var.environment
    db_endpoint  = var.db_endpoint
    db_name      = var.db_name
    db_user      = var.db_user
    db_password  = var.db_password
    log_group    = aws_cloudwatch_log_group.api.name
  }))

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      {
        Name        = "${var.project_name}-${var.environment}-scheduling-api"
        Environment = var.environment
        Service     = "SchedulingAPI"
      },
      var.tags
    )
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group for API
resource "aws_autoscaling_group" "api" {
  name                = "${var.project_name}-${var.environment}-scheduling-api-asg"
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = var.alb_listener_arn != "" ? [aws_lb_target_group.api[0].arn] : []
  health_check_type   = var.alb_listener_arn != "" ? "ELB" : "EC2"
  health_check_grace_period = 300

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  launch_template {
    id      = aws_launch_template.api.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-scheduling-api"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "Service"
    value               = "SchedulingAPI"
    propagate_at_launch = true
  }
}

# Target Group for API (if ALB is provided)
resource "aws_lb_target_group" "api" {
  count    = var.alb_listener_arn != "" ? 1 : 0
  name     = "${var.project_name}-${var.environment}-sched-api-tg"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/api/scheduling/health"
    matcher             = "200"
  }

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-scheduling-api-tg"
      Environment = var.environment
      Service     = "SchedulingAPI"
    },
    var.tags
  )
}

# ALB Listener Rule for API (if ALB is provided)
resource "aws_lb_listener_rule" "api" {
  count        = var.alb_listener_arn != "" ? 1 : 0
  listener_arn = var.alb_listener_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api[0].arn
  }

  condition {
    path_pattern {
      values = ["/api/scheduling/*"]
    }
  }
}

# IAM Role for API instances
resource "aws_iam_role" "api" {
  name_prefix = "${var.project_name}-${var.environment}-api-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-scheduling-api-role"
      Environment = var.environment
    },
    var.tags
  )
}

# IAM Policy for CloudWatch Logs
resource "aws_iam_role_policy" "cloudwatch_logs" {
  name_prefix = "cloudwatch-logs-"
  role        = aws_iam_role.api.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "${aws_cloudwatch_log_group.api.arn}:*"
      }
    ]
  })
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "api" {
  name_prefix = "${var.project_name}-${var.environment}-api-"
  role        = aws_iam_role.api.name

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-scheduling-api-profile"
      Environment = var.environment
    },
    var.tags
  )
}

# Auto Scaling Policies
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.project_name}-${var.environment}-api-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.api.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.project_name}-${var.environment}-api-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.api.name
}

# CloudWatch Alarms for Auto Scaling
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-api-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "75"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.api.name
  }
}

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-api-low-cpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "25"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.api.name
  }
}
