resource "aws_cloudwatch_log_group" "ami_refresher" {
  name              = "/aws/lambda/ami-refresher"
  retention_in_days = 7
  kms_key_id        = data.aws_kms_key.generic.arn
}

resource "aws_s3_object" "ami_refresher" {
  bucket      = data.terraform_remote_state.cloudsetup.outputs.s3_lambda
  key         = "ami_refresher/lambda.zip"
  source      = "lambda.zip"
  source_hash = filemd5("lambda.zip")
  kms_key_id  = data.aws_kms_key.generic.arn
}

resource "aws_lambda_function" "ami_refresher" {
  function_name = "ami-refresher"
  role          = aws_iam_role.ami_refresher.arn
  handler       = "lambda_function.lambda_handler"

  s3_bucket         = aws_s3_object.ami_refresher.bucket
  s3_key            = aws_s3_object.ami_refresher.id
  s3_object_version = aws_s3_object.ami_refresher.version_id

  layers = [
    "arn:aws:lambda:eu-west-1:901920570463:layer:aws-otel-python-amd64-ver-1-11-1:1",
  ]

  runtime       = "python3.9"
  architectures = ["x86_64"]
  memory_size   = 128
  timeout       = 8

  tracing_config {
    mode = "Active"
  }

  kms_key_arn = data.aws_kms_key.generic.arn

  environment {
    variables = {
      AMI_PARAM_PATH_X86      = "/aws/service/ami-amazon-linux-latest/al2022-ami-minimal-kernel-default-x86_64"
      AMI_PARAM_PATH_ARM64    = "/aws/service/ami-amazon-linux-latest/al2022-ami-minimal-kernel-default-arm64"
      TEMPLATE_ARN_X86        = data.aws_launch_template.lmgateway-x86.id
      TEMPLATE_ARN_ARM        = data.aws_launch_template.lmgateway-arm.id
      AWS_LAMBDA_EXEC_WRAPPER = "/opt/otel-instrument"
    }
  }

  depends_on = [
    aws_iam_role_policy.ami_refresher,
    aws_cloudwatch_log_group.ami_refresher,
  ]
}

resource "aws_lambda_event_source_mapping" "ami_refresher" {
  event_source_arn = aws_sqs_queue.ami_updates_queue.arn
  function_name    = aws_lambda_function.ami_refresher.arn

  depends_on = [
    aws_iam_role.ami_refresher,
  ]
}
