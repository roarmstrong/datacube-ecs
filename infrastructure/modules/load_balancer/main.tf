# Default ALB implementation that can be used connect ECS instances to it

resource "aws_alb_target_group" "default" {
  # only create if webservice is true
  count                = "${length(keys(var.hosts))}"
  port                 = "${var.container_port}"
  protocol             = "HTTP"
  vpc_id               = "${var.vpc_id}"
  deregistration_delay = "${var.deregistration_delay}"

  health_check {
    path     = "${var.health_check_path}"
    protocol = "HTTP"
    matcher  = "200-299"
  }

  tags {
    workspace  = "${var.workspace}"
    Cluster    = "${var.cluster}"
    Service    = "${var.service_name}"
    Created_by = "terraform"
    Owner      = "${var.owner}"
  }

  depends_on = ["aws_alb.alb"]
}

resource "aws_alb" "alb" {
  # only create if webservice is true
  count           = "${length(keys(var.hosts)) > 0 ? 1 : 0}"
  name            = "${var.alb_name}"
  subnets         = ["${var.public_subnet_ids}"]
  security_groups = ["${var.security_group}"]

  tags {
    workspace  = "${var.workspace}"
    Cluster    = "${var.cluster}"
    Service    = "${var.service_name}"
    Created_by = "terraform"
    Owner      = "${var.owner}"
  }
}

resource "aws_alb_listener" "http" {
  # only create if webservice is true
  count             = "${length(keys(var.hosts)) > 0 ? 1 : 0}"
  load_balancer_arn = "${aws_alb.alb.0.id}"
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${element(aws_alb_target_group.default.*.arn, count.index)}"
    type             = "forward"
  }

  depends_on = ["aws_alb_target_group.default"]
}

resource "aws_alb_listener_rule" "http_rules" {
  count        = "${length(keys(var.hosts))}"
  listener_arn = "${element(aws_alb_listener.http.*.arn, count.index)}"

  action {
    type = "forward"
    target_group_arn = "${element(aws_alb_target_group.default.*.arn, count.index)}"
  }

  condition {
    field = "host-header"
    values = ["${element(values(var.hosts), count.index)}"]
  }
}

provider "aws" {
  alias  = "cert"
  region = "${var.ssl_cert_region}"
}

data "aws_acm_certificate" "default" {
  domain   = "${var.ssl_cert_domain_name}"
  statuses = [ "ISSUED" ]
  provider = "aws.cert"
  count    = "${var.enable_https}"
}

resource "aws_alb_listener" "https" {
  # only create if webservice and enable_https is true
  count = "${var.enable_https * 1}"

  load_balancer_arn = "${aws_alb.alb.0.id}"
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "${var.ssl_policy_name}"
  certificate_arn   = "${data.aws_acm_certificate.default.arn}"

  default_action {
    target_group_arn = "${element(aws_alb_target_group.default.*.arn, count.index)}"
    type             = "forward"
  }

  depends_on = ["aws_alb_target_group.default"]
}

resource "aws_alb_listener_rule" "https_rules" {
  count        = "${length(keys(var.hosts))}"
  listener_arn = "${element(aws_alb_listener.https.*.arn, count.index)}"

  action {
    type = "forward"
    target_group_arn = "${element(aws_alb_target_group.default.*.arn, count.index)}"
  }

  condition {
    field = "host-header"
    values = ["${element(values(var.hosts), count.index)}"]
  }
}

locals {
  http_listener_rules  = "${zipmap(keys(var.hosts), aws_alb_listener_rule.http_rules.*.arn)}"
  https_listener_rules = "${zipmap(keys(var.hosts), aws_alb_listener_rule.https_rules.*.arn)}"
  target_groups        = "${zipmap(keys(var.hosts), aws_alb_target_group.default.*.arn)}"
}

