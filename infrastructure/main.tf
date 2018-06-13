terraform {
  required_version = ">= 0.10.0"

  backend "s3" {
    # Force encryption
    encrypt = true
  }
}

# ===============
# containers
# ===============
# docker containers used in the WMS
# given in the format name:tag
# code will extract the SHA256 hash to allow Terraform
# to update a task definition to an exact version
# This means that running Terraform after a docker image
# changes, the task will be updated.
module "docker" {
  source = "modules/docker"

  images = {
    green  = "opendatacube/wms:0.2.1"
    blue = "opendatacube/wms:0.2.1"
  }
}

# ===============
# public address
# ===============
# set the public URL information here

locals {
  public_subnet_ids = ["${data.aws_subnet.a.id}", "${data.aws_subnet.b.id}", "${data.aws_subnet.c.id}"]

  default_environment_vars = {
    "DATACUBE_CONFIG_PATH" = "/opt/odc/datacube.conf"
    "DB_HOSTNAME"          = "${data.aws_ssm_parameter.db_host.value}"
    "DB_USERNAME"          = "${data.aws_ssm_parameter.db_username.value}"
    "DB_PASSWORD"          = "${data.aws_ssm_parameter.db_password.value}"
    "DB_PORT"              = "5432"
    "VIRTUAL_HOST"         = "localhost,127.0.0."
    "DB_DATABASE"          = "${coalesce(var.new_database_name, data.aws_ssm_parameter.db_name.value)}"
    TF_VAR_database        = "${coalesce(var.new_database_name, data.aws_ssm_parameter.db_name.value)}"
    TF_VAR_cluster         = "${var.cluster}"
    TF_VAR_state_bucket    = "${data.aws_ssm_parameter.state_bucket.value}"
  }

  # Checks if we need to overwrite cluster defaults
  dns_zone             = "${coalesce(var.dns_zone, data.aws_ssm_parameter.dns_zone.value)}"
  ssl_cert_domain_name = "${coalesce(var.ssl_cert_domain_name, data.aws_ssm_parameter.dns_zone.value)}"
  ssl_cert_region      = "${coalesce(var.ssl_cert_region, data.aws_ssm_parameter.ssl_cert_region.value)}"
  aliases              = ["${var.dns_name}.${local.dns_zone}"]
  db_ref               = "${join(".", compact(list(var.cluster, var.database)))}"

  env_vars = "${merge(local.default_environment_vars, var.environment_vars)}"
}

module "container_def" {
  source = "github.com/eiara/terraform_container_definitions"

  name      = "${var.name}"
  image     = "${module.docker.name_and_digest["green"]}"
  essential = true
  memory    = "${var.memory}"

  logging_driver = "awslogs"

  logging_options = {
    "awslogs-region" = "${var.aws_region}"
    "awslogs-group"  = "${var.cluster}/apps/${terraform.workspace}"
  }

  port_mappings = [{
    "container_port" = "${var.container_port}"
  }]

  environment = "${local.env_vars}"
  command     = ["${compact(split(" ",var.docker_command))}"]
}

module "container_def_blue" {
  source = "github.com/eiara/terraform_container_definitions"

  name      = "${var.name}"
  image     = "${module.docker.name_and_digest["blue"]}"
  essential = true
  memory    = "${var.memory}"

  logging_driver = "awslogs"

  logging_options = {
    "awslogs-region" = "${var.aws_region}"
    "awslogs-group"  = "${var.cluster}/apps/${terraform.workspace}"
  }

  port_mappings = [{
    "container_port" = "${var.container_port}"
  }]

  environment = "${local.env_vars}"
  command     = ["${compact(split(" ",var.docker_command))}"]
}

module "ecs_green" {
  source = "modules/ecs"

  name         = "${var.name}"

  container_port     = "${var.container_port}"
  container_name     = "${var.name}"
  task_desired_count = "${var.task_desired_count}"

  aws_region = "${var.aws_region}"

  family = "${var.name}-service-task"

  task_role_arn    = "${module.ecs_main.task_role_arn}"
  target_group_arn = "${lookup(module.alb.target_groups, "green")}"
  webservice       = "${var.webservice}"

  # // container def
  container_definitions = "[${module.container_def.json}]"

  # Scheduling definitions
  schedulable         = "${var.schedulable}"
  schedule_expression = "${var.schedule_expression}"

  # Tags
  owner     = "${var.owner}"
  cluster   = "${var.cluster}"
  workspace = "${var.workspace}"
}


module "ecs_blue" {
  source = "modules/ecs"

  name         = "${var.name}_test"

  container_port     = "${var.container_port}"
  container_name     = "${var.name}"
  task_desired_count = "1"

  aws_region = "${var.aws_region}"

  family = "${var.name}-service-task"

  task_role_arn    = "${module.ecs_main.task_role_arn}"
  target_group_arn = "${lookup(module.alb.target_groups, "blue")}"
  webservice       = "${var.webservice}"

  # // container def
  container_definitions = "[${module.container_def_blue.json}]"

  # Scheduling definitions
  schedulable         = "${var.schedulable}"
  schedule_expression = "${var.schedule_expression}"

  # Tags
  owner     = "${var.owner}"
  cluster   = "${var.cluster}"
  workspace = "${var.workspace}"
}

module "alb" {
  source = "modules/load_balancer"

  workspace            = "${var.workspace}"
  cluster              = "${var.cluster}"
  owner                = "${var.owner}"
  service_name         = "${var.name}"
  vpc_id               = "${data.aws_vpc.cluster.id}"
  public_subnet_ids    = "${local.public_subnet_ids}"
  alb_name             = "${var.alb_name}"
  container_port       = "${var.container_port}"
  security_group       = "${data.aws_security_group.alb_sg.id}"
  health_check_path    = "${var.health_check_path}"
  enable_https         = "${var.enable_https}"
  ssl_cert_domain_name = "*.${local.ssl_cert_domain_name}"
  ssl_cert_region      = "${local.ssl_cert_region}"
  hosts                = { 
                           "green" = "${var.dns_name}.${local.dns_zone}"
                           "blue"    = "blue.${var.dns_name}.${local.dns_zone}"
                         }
}

module "ecs_main" {
  source = "modules/ecs_common"

  name         = "${var.name}"

  aws_region = "${var.aws_region}"

  account_id       = "${data.aws_caller_identity.current.account_id}"
  task_role_name   = "${var.name}-role"

  # DB Task
  database_task     = "${var.database_task}"
  new_database_name = "${var.new_database_name}"
  state_bucket      = "${data.aws_ssm_parameter.state_bucket.value}"

  # Tags
  owner     = "${var.owner}"
  cluster   = "${var.cluster}"
  workspace = "${var.workspace}"
}

# Terraform doesn't lazily evaluate conditional expressions
# we have to ensure there is something in the list for
# terraform to not complain about an empty list, even if webservice is false
locals {
  cloudfront      = "${var.webservice && var.use_cloudfront}"
  target_dns_name = "${local.cloudfront ? element(concat(module.cloudfront.dns_name   , list("")), 0)
                                        : element(concat(module.alb.dns_name          , list("")), 0)}"
  target_dns_zone = "${local.cloudfront ? element(concat(module.cloudfront.dns_zone_id, list("")), 0)
                                        : element(concat(module.alb.dns_zone_id       , list("")), 0)}"
}

# Lack of a module count means we need to use flags
# and counts inside the route53 module to conditionally
# create the resources.
module "route53" {
  source = "modules/route53"

  domain_name        = "${var.dns_name}.${local.dns_zone}"
  zone_domain_name   = "${local.dns_zone}"
  target_dns_name    = "${var.webservice ? local.target_dns_name : ""}"
  target_dns_zone_id = "${var.webservice ? local.target_dns_zone : ""}"
  enable             = "${var.webservice}"
  all_subdomains     = true
}

# Lack of a module count means we need to use flags
# and counts inside the cloudfront module to conditionally
# create the resources.
# Terraform doesn't lazily evaluate conditional expressions
# we have to ensure there is something in the list for
# terraform to not complain about an empty list, even if webservice is false
module "cloudfront" {
  source = "modules/cloudfront"

  origin_domain        = "${local.cloudfront ? element(concat(module.alb.dns_name, list("")), 0) : ""}"
  origin_id            = "${var.cluster}_${var.workspace}_${var.name}_origin"
  aliases              = ["${local.aliases}"]
  ssl_cert_domain_name = "*.${local.ssl_cert_domain_name}"
  enable_distribution  = true
  enable               = "${local.cloudfront}"
}

# ==============
# Ancilliary

provider "aws" {
  region = "ap-southeast-2"
}
