variable "cluster" {
  default = "datacube-wms"
}

variable "aws_region" {
  default = "ap-southeast-2"
}

variable "workspace" {
  default = "dev"
}

variable "owner" {
  default = "DEA"
}

variable "name" {
  type        = "string"
  description = "Name of the service"
}

variable "webservice" {
  default     = true
  description = "Whether the task should restart and be publically accessible"
}

variable "docker_image" {
  type        = "string"
  description = "docker image to run"
}

variable "docker_command" {
  default     = ""
  description = "Command to run on docker container"
}

variable "health_check_path" {
  default     = "/?version=1.3.0&request=GetCapabilities&service=WMS"
  description = "A path that returns 200OK if container is healthy"
}

variable "memory" {
  default     = 1024
  description = "memory for the container in MB"
}

variable "alb_name" {
  default     = "default"
  description = "The name of the loadbalancer"
}

# ==================
# Containers
variable "container_port" {
  default = 8000
}

variable "environment_vars" {
  default     = {}
  description = "Map containing environment variables to pass to docker container. Overrides defaults."
}

variable "custom_policy" {
  default     = ""
  description = "IAM Policy JSON"
}

# ==================
# Services and Tasks
variable "task_desired_count" {
  default = 1
}

variable "schedulable" {
  default = false
}

variable "schedule_expression" {
  default = ""
}

# ==================
# Database

variable "database" {
  default = "prod"
}

# ==================
# DNS

variable "dns_name" {
  default     = ""
  description = "DNS name of the service"
}

variable "dns_zone" {
  default     = ""
  description = "DNS zone of the service"
}
