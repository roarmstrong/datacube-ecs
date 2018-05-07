terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}

# --------------
# Variables

variable "aws_region" {
  default = "ap-southeast-2"
}

variable "db_port" {
  default = 5432
}

variable "cluster" {}

variable "database" {}

# --------------
# AWS
provider "aws" {
  region = "${var.aws_region}"
}

# Get the admin credentials from SSM
data "aws_ssm_parameter" "db_admin_username" {
  name = "${var.cluster}.db_username"
}

data "aws_ssm_parameter" "db_admin_password" {
  name = "${var.cluster}.db_password"
}

data "aws_ssm_parameter" "db_host" {
  name = "${var.cluster}.db_host"
}

# Set the user credentials in SSM
locals {
  db_user = "${var.cluster}_${var.database}_user"
}

resource "aws_ssm_parameter" "service_db_name" {
  name      = "${var.cluster}.${var.database}.db_name"
  value     = "${var.database}"
  type      = "String"
  overwrite = false
}

resource "aws_ssm_parameter" "service_db_username" {
  name      = "${var.cluster}.${var.database}.db_username"
  value     = "${local.db_user}"
  type      = "String"
  overwrite = false
}

resource "random_string" "password" {
  length  = 24
  special = false
}

resource "aws_ssm_parameter" "service_db_password" {
  name      = "${var.cluster}.${var.database}.db_password"
  value     = "${random_string.password.result}"
  type      = "SecureString"
  overwrite = false
}

# -------------
# Postgres

provider "postgresql" {
  host     = "${var.db_host}"
  port     = "${var.db_port}"
  username = "${var.db_admin_user}"
  password = "${var.db_admin_pass}"
}

resource "postgresql_role" "my_role" {
  name     = "${local.db_user}"
  login    = true
  password = "${random_string.password.result}"
}

resource "postgresql_database" "my_db" {
  name              = "${var.database}"
  owner             = "${local.db_user}"
  connection_limit  = -1
  allow_connections = true
}

# -------------
# Variables
resource "null_resource" "env_vars" {
  triggers {
    db_user = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "firsttime/setup.sh"

    # This will add environment vars to any already set
    environment = {
      DB_HOSTNAME = "${var.db_host}"
      DB_PORT     = "${var.db_port}"
      DB_USERNAME = "${local.db_user}"
      DB_PASSWORD = "${random_string.password.result}"
      DB_DATABASE = "${var.database}"
    }
  }
}
