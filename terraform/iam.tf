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
