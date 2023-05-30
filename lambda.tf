resource "aws_lambda_function" "alb_logs_to_elasticsearch" {
  filename         = local.lambda_function_filename
  function_name    = "${var.prefix}alb-logs-to-elasticsearch"
  description      = "${var.prefix}alb-logs-to-elasticsearch"
  timeout          = 300
  runtime          = "nodejs${var.nodejs_version}"
  role             = aws_iam_role.role.arn
  handler          = "index.handler"
  source_code_hash = filebase64sha256(local.lambda_function_filename)

  environment {
    variables = {
      es_endpoint = var.es_endpoint
      index       = var.index
      region      = var.region
    }
  }

  tags = merge(
    var.tags,
    tomap({ "Scope" = "${var.prefix}lambda_function_to_elasticsearch" }),
  )

  dynamic "vpc_config" {
    for_each = length(var.subnet_ids) > 0 ? ["1"] : []
    content {
      subnet_ids         = var.subnet_ids
      security_group_ids = [aws_security_group.lambda[0].id]
    }
  }

  lifecycle {
    ignore_changes = [filename]
  }
}

resource "aws_lambda_permission" "allow_terraform_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.alb_logs_to_elasticsearch.arn
  principal     = "s3.amazonaws.com"
  source_arn    = var.s3_bucket_arn
}
