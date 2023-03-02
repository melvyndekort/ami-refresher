data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ami_refresher" {
  name = "ami_refresher"
  path = "/lambda/"

  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

data "aws_iam_policy_document" "ami_refresher" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      aws_cloudwatch_log_group.ami_refresher.arn,
      "${aws_cloudwatch_log_group.ami_refresher.arn}:*",
    ]
  }

  statement {
    actions = [
      "ssm:GetParameter",
    ]

    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "ec2:ModifyLaunchTemplate",
      "ec2:DeleteLaunchTemplateVersions",
      "ec2:CreateLaunchTemplateVersion",
    ]

    resources = [
      data.aws_launch_template.lmgateway-x86.arn,
      data.aws_launch_template.lmgateway-arm.arn,
    ]
  }

  statement {
    actions = [
      "ec2:DescribeInstances",
      "ec2:TerminateInstances",
      "ec2:DescribeLaunchTemplates",
    ]

    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
    ]

    resources = [ 
      aws_sqs_queue.ami_updates_queue.arn,
    ]
  }
}

data "aws_iam_policy" "xray" {
  name = "AWSXRayDaemonWriteAccess"
}

resource "aws_iam_role_policy_attachment" "ami_refresher_xray" {
  role       = aws_iam_role.ami_refresher.id
  policy_arn = data.aws_iam_policy.xray.arn
}

resource "aws_iam_role_policy" "ami_refresher" {
  name   = "ami_refresher"
  role   = aws_iam_role.ami_refresher.id
  policy = data.aws_iam_policy_document.ami_refresher.json
}
