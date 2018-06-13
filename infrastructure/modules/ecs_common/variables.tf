variable "name" {
  type        = "string"
  description = "Name of the service"
}

variable "aws_region" {
  type        = "string"
  description = "AWS region for ECS instances"
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

variable "ssm_decrypt_key" {
  description = "Alias for the ssm decrypt key to access secure ssm parameters"
  default     = "aws/ssm"
}

variable "account_id" {
  description = "The account id for specifying arns"
}

variable "task_role_name" {
  description = "The name of the role"
}

variable "parameter_store_resource" {
  type        = "string"
  default     = "*"
  description = "The parameter store services that can be acccessed. E.g. * for all or /datacube/* for all datacube"
}

########
# ecs_service
########

variable "custom_policy" {
  default     = ""
  description = "custom policy to add to the task"
}

########
# database_task
########
variable "database_task" {
  default     = false
  description = "Whether to provision database specific policies"
}

variable "new_database_name" {
  default     = ""
  description = "the name of the new database, to be used when creating task perms"
}

variable "state_bucket" {
  default     = ""
  description = "the s3 bucket that hosts the remote state"
}
