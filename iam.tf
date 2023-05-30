data "aws_iam_policy_document" "policy" {
  statement {
    sid       = "LambdaLogCreation"
    effect    = "Allow"
    resources = ["arn:aws:logs:*:*:*"]

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
  }

  statement {
    sid    = "ESPermissions"
    effect = "Allow"
    resources = [
      format("%s/*", var.es_domain_arn)
    ]

    actions = [
      "es:ESHttpPost",
      "es:ESHttpPut",
    ]
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = [var.s3_bucket_arn]
    actions   = ["s3:ListBucket"]
  }

  statement {
    sid    = ""
    effect = "Allow"
    resources = [
      format("%s/*", var.s3_bucket_arn)
    ]
    actions = ["s3:GetObject"]
  }
}

resource "aws_iam_policy" "policy" {
  name        = "${var.prefix}alb-logs-to-elasticsearch"
  path        = "/"
  description = "Policy for ${var.prefix}alb-logs-to-elasticsearch Lambda function"
  policy      = data.aws_iam_policy_document.policy.json
}

data "aws_iam_policy_document" "sts" {
  statement {
    sid     = ""
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "role" {
  name               = "${var.prefix}alb-logs-to-elasticsearch"
  assume_role_policy = data.aws_iam_policy_document.sts.json
}

resource "aws_iam_role_policy_attachment" "policy_attachment" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}

resource "aws_iam_role_policy_attachment" "policy_attachment_vpc" {
  count      = length(var.subnet_ids) > 0 ? 1 : 0
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
