resource "aws_lambda_function" "visitorCounter" {
  filename         = data.archive_file.zip_the_mjs_code.output_path
  source_code_hash = data.archive_file.zip_the_mjs_code.output_base64sha256
  function_name    = "${var.lambda_function_name}"
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"

  environment {
    variables = {
      dynamodb_table = var.dynamodb_table_name  # Passing the variable from tfvars
    }
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

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

resource "aws_iam_policy" "iam_policy_for_resume_project" {

  name        = "aws_iam_policy_for_terraform_resume_project_policy"
  path        = "/"
  description = "AWS IAM Policy for managing the resume project role"
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Resource" : "arn:aws:logs:*:*:*",
          "Effect" : "Allow"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "dynamodb:UpdateItem",
            "dynamodb:GetItem"
          ],
          #"Resource" : "arn:aws:dynamodb:*:*:table/VisitorCounter1"
          "Resource" : "${aws_dynamodb_table.visitor_counter.arn}"
        },
      ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.iam_policy_for_resume_project.arn

}

data "archive_file" "zip_the_mjs_code" {
  type        = "zip"
  source_file = "${path.module}/lambda/index.mjs"
  output_path = "${path.module}/lambda/index.zip"
}

resource "aws_lambda_function_url" "url1" {
  function_name      = aws_lambda_function.visitorCounter.function_name
  authorization_type = "NONE"
  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["*"]
    allow_headers     = ["date", "keep-alive"]
    expose_headers    = ["keep-alive", "date"]
    max_age           = 86400
  }
}

resource "local_file" "config_js" {
  content  = "export const FUNCTION_URL = \"${aws_lambda_function_url.url1.function_url}\";"
  filename = "${path.module}/../CherryBlossom/Scripts/config.js"
}

#Upload the config.js file to the S3 bucket
resource "aws_s3_object" "config" {
  bucket = aws_s3_bucket.front-end-s3-bucket.bucket
  key    = "Scripts/config.js"
  source = "${local.source_directory}/${local_file.config_js.filename}"  # Local path to config.js
  #acl    = "public-read"
  content_type = "application/javascript"
  #etag = "${local_file.config_js.filename}" 
  ##depends_on = [aws_s3_object.files,local_file.config_js]
}


resource "aws_dynamodb_table" "visitor_counter" {
  name         = "${var.dynamodb_table_name}"
  billing_mode = "PAY_PER_REQUEST"  # On-demand pricing

  attribute {
    name = "counterID"
    type = "S"  # String type for counterID
  }

  hash_key = "counterID"

  tags = {
    Name        = "${var.dynamodb_table_name}"
    Environment = "Dev"
  }
}

resource "aws_dynamodb_table_item" "visitor_item" {
  table_name = aws_dynamodb_table.visitor_counter.name
  hash_key   = "counterID"

  item = <<ITEM
{
  "counterID": {"S": "1"},
  "visitCount": {"N": "0"}
}
ITEM

lifecycle {
    ignore_changes = [item]
  }
  
}