resource "aws_ecs_task_definition" "service-task" {
  family                = "${var.family}"
  container_definitions = "${var.container_definitions}"
  task_role_arn         = "${aws_iam_role.task_role.arn}"

  volume {
    name      = "${var.volume_name}"
    host_path = "${var.container_path}"
  }
}

resource "aws_ecs_service" "service" {
  # only create if webservice is true
  count           = "${var.webservice}"
  name            = "${var.name}"
  cluster         = "${var.cluster}"
  task_definition = "${aws_ecs_task_definition.service-task.arn}"
  desired_count   = "${var.task_desired_count}"

  load_balancer {
    target_group_arn = "${element(var.target_group_arn,0)}"
    container_name   = "${var.container_name}"
    container_port   = "${var.container_port}"
  }
}

resource "null_resource" "aws_ecs_task" {
  count = "${var.webservice ? 0 : 1}"

  triggers {
    timestamp = "${timestamp()}"
  }

  # If it isn't a webservice start a once-off task
  # Terraform doesn't have a run-task capability as it's a short term thing
  provisioner "local-exec" {
    command = "aws ecs run-task --cluster ${var.cluster} --task-definition ${aws_ecs_task_definition.service-task.arn}"
  }

  depends_on = ["aws_iam_role.task_role"]
}

resource "aws_iam_policy" "scheduled_task" {
  name   = "${var.cluster}_${var.workspace}_${var.name}_s_policy"
  policy = "${data.aws_iam_policy_document.scheduled_task.json}"
}

resource "aws_iam_role_policy_attachment" "schedule_policy_role" {
  role       = "${aws_iam_role.task_role.name}"
  policy_arn = "${aws_iam_policy.scheduled_task.arn}"
}

resource "aws_cloudwatch_event_rule" "task" {
  name                = "${var.cluster}_${var.workspace}_${var.name}_task"
  count               = "${var.schedulable ? 1 : 0}"
  schedule_expression = "${var.schedule_expression}"
}

resource "aws_cloudwatch_event_target" "task" {
  count    = "${var.schedulable ? 1 : 0}"
  rule     = "${aws_cloudwatch_event_rule.task.name}"
  arn      = "${data.aws_ecs_cluster.cluster.arn}"
  role_arn = "${aws_iam_role.task_role.arn}"

  ecs_target {
    task_count          = "${var.task_desired_count}"
    task_definition_arn = "${aws_ecs_task_definition.service-task.arn}"
  }
}
