variable "aws_region" {
  description = "AWS region to launch servers"
  default     = "us-east-1"
  type        = string
}

variable "instance_type" {
  description = "Type of EC2 instance"
  default     = "t3.medium"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for instances"
  default     = "ami-0f9de6e2d2f067fca" 
  type        = string
}