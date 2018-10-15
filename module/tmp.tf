data "aws_sns_topic" "my_topic" {
  name = "${var.TF_SNS_Topic_Name}"
}

data "archive_file" "codecommit_sns_lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/codecommit_sns.py"
  output_path = "${path.module}/lambda/codecommit_sns.zip"
}

resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role" "SNS_lambda_role" {
  name             = "SNS_lambda_role"
  depends_on       = ["aws_iam_role.lambda_execution_role"]


  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": "arn:aws:iam::${var.PL_ACCOUNT_ID}:role/lambda_execution_role"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "SNS_lambda_role" {
  name = "SNS_lambda_role_policy"
  role = "${aws_iam_role.SNS_lambda_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Ec2DescribeInstances",
      "Effect": "Allow",
      "Action": ["SNS:Publish"],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_execution_role" {
  role       = "${aws_iam_role.lambda_execution_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_execution_role" {
  name = "SNS_lambda_role_policy"
  role = "${aws_iam_role.lambda_execution_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Sid": "LambdaExecutionRole",
        "Effect": "Allow",
        "Action": "sts:AssumeRole",
        "Resource": "arn:aws:iam::${var.PL_ACCOUNT_ID}:role/SNS_lambda_role"
    },
    {
          "Sid": "CreateLogGroup",
          "Effect": "Allow",
          "Action": "logs:CreateLogGroup",
          "Resource": "arn:aws:logs:eu-west-1:${var.PL_ACCOUNT_ID}:*"
      },
      {
          "Sid": "LogStreamEvents",
          "Effect": "Allow",
          "Action": [
              "logs:CreateLogStream",
              "logs:PutLogEvents"
          ],
          "Resource": [
              "arn:aws:logs:eu-west-1:${var.PL_ACCOUNT_ID}:log-group:/aws/lambda/SNS_lambda_logs:*"
          ]
      }
  ]
}
EOF
}

resource "aws_lambda_function" "codecommit_sns" {
  depends_on       = ["aws_iam_role.lambda_execution_role", "aws_iam_role_policy.lambda_execution_role"]
  description      = "SNS once a PR has been done"
  filename         = "${path.module}/lambda/codecommit_sns.zip"
  function_name    = "codecommit_sns"
  role             = "${aws_iam_role.lambda_execution_role.arn}"
  handler          = "codecommit_sns.lambda_handler"
  source_code_hash = "${data.archive_file.codecommit_sns_lambda.output_base64sha256}"
  runtime          = "python3.6"
  timeout          = 300

  environment {
    variables = {
      PL_REGION         = "${var.PL_REGION}"
      TF_ACCOUNT_ID     = "${var.PL_ACCOUNT_ID}"
      TF_SNS_Topic_Name = "${data.aws_sns_topic.my_topic.arn}"
    }
  }

  tags {
    Environment     = "${var.PL_ENV}"
    Project         = "SNS per PR"
    Owner           = "Iban Marco - ibanmarco@gmail.com"
  }
}

resource "aws_cloudwatch_event_rule" "sns_lambda" {
  name                = "invoke_codecommit_sns_lambda"

  event_pattern = <<PATTERN
  {
    "source": [
      "aws.codecommit"
    ]
  }
PATTERN
}

resource "aws_cloudwatch_event_target" "sns_lambda" {
  target_id = "sns_lambda"
  rule      = "${aws_cloudwatch_event_rule.sns_lambda.name}"
  arn       = "${aws_lambda_function.codecommit_sns.arn}"
}
