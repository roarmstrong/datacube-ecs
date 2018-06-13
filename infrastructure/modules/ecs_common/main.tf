resource "aws_iam_role" "task_role" {
  name = "${var.cluster}-${var.name}-task_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "ecs-tasks.amazonaws.com",
          "events.amazonaws.com"
        ]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "database_task" {
  count       = "${var.database_task ? 1 : 0}"
  name        = "${var.cluster}-${var.name}-database_task"
  path        = "/"
  description = "Allows database provisioner to export vars"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ssm:DescribeParameters",
                "kms:*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameterHistory",
                "ssm:GetParameters",
                "ssm:GetParameter",
                "ssm:DeleteParameters",
                "ssm:PutParameter",
                "ssm:DeleteParameter",
                "ssm:GetParametersByPath"
            ],
            "Resource": [
                "arn:aws:ssm:ap-southeast-2:${data.aws_caller_identity.current.account_id}:parameter/${var.cluster}*",
                "arn:aws:ssm:ap-southeast-2:${data.aws_caller_identity.current.account_id}:parameter/${var.cluster}.${var.new_database_name}*"
            ]
        },
        {
            "Sid": "TerraformState",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "dynamodb:PutItem",
                "dynamodb:DeleteItem",
                "dynamodb:GetItem",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::${var.state_bucket}",
                "arn:aws:s3:::${var.state_bucket}/*",
                "arn:aws:dynamodb:*:*:table/terraform"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "database_task" {
  count      = "${var.database_task ? 1 : 0}"
  name       = "${var.workspace}_${var.name}database_task"
  roles      = ["${aws_iam_role.task_role.name}"]
  policy_arn = "${aws_iam_policy.database_task.arn}"
}

resource "aws_iam_policy" "bucket_access" {
  name        = "${var.cluster}-${var.name}-bucket_access"
  path        = "/"
  description = "Allow access to dea data"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "GetFiles",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:ListObjects",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::dea-public-data",
                "arn:aws:s3:::dea-public-data/*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "bucket_access" {
  name       = "${var.workspace}_${var.name}_attach_bucket"
  roles      = ["${aws_iam_role.task_role.name}"]
  policy_arn = "${aws_iam_policy.bucket_access.arn}"
}

resource "aws_iam_policy" "secrets" {
  name        = "${var.cluster}-${var.name}-secrets"
  path        = "/"
  description = "My test policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ssm:DescribeParameters"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParametersByPath",
        "ssm:ListTagsForResource"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:ssm:${var.aws_region}:${var.account_id}:parameter/${var.cluster}*",
        "arn:aws:ssm:${var.aws_region}:${var.account_id}:parameter/${var.name}*"
      ]
    },
    {
      "Action": [
        "kms:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "secrets" {
  name       = "${var.workspace}_${var.name}_attach_secrets"
  roles      = ["${aws_iam_role.task_role.name}"]
  policy_arn = "${aws_iam_policy.secrets.arn}"
}

resource "aws_iam_policy_attachment" "cw_logs" {
  name       = "${var.workspace}_${var.name}_attach_cw_logs"
  roles      = ["${aws_iam_role.task_role.name}"]
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_cloudwatch_log_group" "cw_logs" {
  name = "${var.cluster}/apps/${terraform.workspace}"

  tags {
    Environment = "${var.workspace}"
    Application = "${var.name}"
  }
}

resource "aws_iam_policy" "custom_policy" {
  count  = "${length(var.custom_policy) > 0 ? 1 : 0}"
  name   = "${var.cluster}_${var.workspace}_${var.name}_policy"
  path   = "/"
  policy = "${var.custom_policy}"
}

resource "aws_iam_policy_attachment" "custom_policy_to_odc_role" {
  count      = "${length(var.custom_policy) > 0 ? 1 : 0}"
  name       = "${var.workspace}_${var.name}_attach_ssm_policy_to_odc_ecs"
  roles      = ["${aws_iam_role.task_role.name}"]
  policy_arn = "${aws_iam_policy.custom_policy.id}"
}

data "aws_iam_policy_document" "scheduled_task" {
  statement {
    effect    = "Allow"
    actions   = ["ecs:RunTask"]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = ["${aws_iam_role.task_role.arn}"]
  }
}

resource "aws_iam_policy" "scheduled_task" {
  name   = "${var.cluster}_${var.workspace}_${var.name}_s_policy"
  policy = "${data.aws_iam_policy_document.scheduled_task.json}"
}

resource "aws_iam_role_policy_attachment" "schedule_policy_role" {
  role       = "${aws_iam_role.task_role.name}"
  policy_arn = "${aws_iam_policy.scheduled_task.arn}"
}
