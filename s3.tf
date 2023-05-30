resource "aws_s3_bucket_notification" "alb_logs_to_elasticsearch" {
  bucket = var.s3_bucket_id

  lambda_function {
    lambda_function_arn = aws_lambda_function.alb_logs_to_elasticsearch.arn
    events              = ["s3:ObjectCreated:*"]
  }
}
