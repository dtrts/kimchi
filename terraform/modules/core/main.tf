resource "aws_s3_bucket" "bucket_1" {
  bucket_prefix = "kimchi-ingest"
  acl           = "private"
  tags = {
    Name        = "kimchi-ingest"
    Environment = "kimchi"
  }

  force_destroy = true
}

resource "aws_iam_role" "lambda_role" {
  name = "kimchi-lambda-execution"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda-logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda-s3" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_lambda_function" "lambda_1" {
  function_name = "kimchi-1-ingest-file"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  filename      = "../lambdas/kimchi-l1-ingest-file/code.zip"

  source_code_hash = filebase64sha256("../lambdas/kimchi-1-ingest-file/code.zip")

  runtime = "nodejs12.x"

  environment {
    variables = {
      localstack = var.localstack
    }
  }

}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_1.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.bucket_1.arn
}

resource "aws_s3_bucket_notification" "bucket_notification_1" {
  bucket = aws_s3_bucket.bucket_1.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda_1.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "upload/"
    filter_suffix       = ".json"
  }
}

resource "aws_dynamodb_table" "ddb_colours" {
  name           = "colours"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "Colour"
  attribute {
    name = "Colour"
    type = "S"
  }
}
