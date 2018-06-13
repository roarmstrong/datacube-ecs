variable "name" {
  type        = "string"
  description = "Name of the service"
}

variable "container_name" {
  type        = "string"
  default     = "datacube-wms"
  description = "Name of the container targetted by the load balancer"
}

variable "container_port" {
  default = 80
}

variable "aws_region" {
  type        = "string"
  description = "AWS region for ECS instances"
}

variable "task_desired_count" {
  default     = 1
  description = "Desired count of the ecs task"
}

#######
# Tags
#######

variable "cluster" {
  type        = "string"
  description = "Name of the cluster"
}

variable "workspace" {
  type        = "string"
  description = "workspace of this cluster"
}

variable "owner" {
  type        = "string"
  description = "Owner of this cluster"
}

########
# ecs_policy
########
variable "task_role_arn" {
  description = "ARN of the task role"
}

########
# ecs_service
########

variable "target_group_arn" {
  type        = "string"
  description = "ARN of the ELB's target group"
}

# Task variables
variable "family" {
  type        = "string"
  description = "The family of the task"
}

variable "container_path" {
  type        = "string"
  default     = "/opt/data"
  description = "file system path to mounted volume on container. e.g. /opt/data"
}

variable "volume_name" {
  type        = "string"
  default     = "volume-0"
  description = "name of the volume to be mounted"
}

variable "container_definitions" {
  type        = "string"
  description = "JSON container definition"
}

variable "webservice" {
  default     = true
  description = "Whether the task should restart and be publically accessible"
}

variable "schedulable" {
  default     = false
  description = "Whether the task will run periodically on a schedule"
}

variable "schedule_expression" {
  default     = ""
  description = "Determines the schedule of a schedulable task. e.g. cron(0 20 * * ? *) or rate(5 minutes)"
}