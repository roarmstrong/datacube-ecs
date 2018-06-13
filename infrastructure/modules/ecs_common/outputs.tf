
output "task_role_arn" {
  value = "${aws_iam_role.task_role.arn}"
}

output "instance_role_arn" {
  value = "${aws_iam_role.instance_role.arn}"
}