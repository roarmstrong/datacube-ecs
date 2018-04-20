variable "name" {
  type = "string"
  description = "Name of the service"
}

variable "docker_image" {
  type = "string"
  description = "docker image to run"
}

variable "zone_url" {
  type = "string"
  description = "Zone URL"
}

variable "public_url" {
  type = "string"
  description = "The URL at which this service will be accessed"
}

variable "database" {
  type = "string"
  description = "name of the database being used"
}

variable "db_username" {
  type = "string"
  description = "database admin username"
}

variable "db_zone" {
  type = "string"
  description = "database DNS zone"
}

variable "db_name" {
  type = "string"
  description = "database DNS name"
}

variable "container_port" {
  default = 80
}

variable "memory" {
  default = 1024
  description = "memory for the container in MB"
}

variable "aws_region" {
  type = "string"
  description = "AWS region for ECS instances"
}

variable "ec2_security_group" {
  type = "string"
  description = "EC2 security group ID"
}

variable "task_desired_count" {
  default = 1
  description = "Desired count of the ecs task"
}

## ALB required vars

variable "alb_name" {
  type = "string"
  description = "unique name for the alb"
}

variable "vpc_id" {
  type = "string"
  description = "ID of the VPC this ALB is contained in"
}

variable "public_subnet_ids" {
  type = "list"
  description = "IDs of the public subnets that this ALB will use"
}

#######
# Tags
#######

variable "cluster" {
  type = "string"
  description = "Name of the cluster"
}

variable "workspace" {
  type = "string"
  description = "workspace of this cluster"
}

variable "owner" {
  type = "string"
  description = "Owner of this cluster"
}