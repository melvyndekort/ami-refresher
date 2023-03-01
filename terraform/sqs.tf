resource "aws_sqs_queue" "ami_updates_queue" {
  name = "ami-updates-queue"
}

resource "aws_sns_topic_subscription" "ami_updates_sqs_target" {
  provider = aws.snsregion

  topic_arn = var.sns_topic_arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.ami_updates_queue.arn
}
