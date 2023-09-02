# Creating s3 bucket to store json files
# Region used us-east-1
# Bucket Name kubeshot-data-pipeline
# Access control list set to private for security reasons

provider "aws" {
  region = "us-east-1"  # Change to your desired region
}

resource "aws_s3_bucket" "data_bucket" {
  bucket = "kubeshot-data-pipeline"
}

resource "aws_s3_bucket_ownership_controls" "data_bucket_ownership" {
  bucket = aws_s3_bucket.data_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "data_bucket_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.data_bucket_ownership]

  bucket = aws_s3_bucket.data_bucket.id
  acl    = "private"
}


# Creating an aws lambda function that processes the data in JSON File uploaded
# Name: KubeshotDataProcess
# Setting environment variable for s3 data bucket name where JSON file is uploaded, this will be used in Python Code while processing data 

resource "aws_lambda_function" "process_data_lambda" {
  filename         = "lambda_function.zip"  # Zip contains Python code that processes data
  function_name    = "KubeshotDataProcess"  # Function Name
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_handler"
  source_code_hash = filebase64sha256("lambda_function.zip")

  runtime = "python3.8"  # Choose an appropriate Python version

  environment {
    variables = {
      S3_BUCKET = aws_s3_bucket.data_bucket.id
    }
  }
}

# Creating IAM Role for lambda function to have necessary permissions
# Name: lambda-role

resource "aws_iam_role" "lambda_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Creating IAM for Lambda function to have access of S3 buckets
# Name: Lambda s3 policy
# Allows get put and list object.

resource "aws_iam_policy" "lambda_s3_policy" {
  name        = "LambdaS3Policy" 
  description = "Allows Lambda to access S3 buckets"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
        ],
        Effect   = "Allow",
        Resource = [
          aws_s3_bucket.data_bucket.arn,
          "${aws_s3_bucket.data_bucket.arn}/*",
        ],
      },
    ],
  })
}

# Attaching IAM POlicy to IAM Role created Above

resource "aws_iam_role_policy_attachment" "lambda_s3_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_s3_policy.arn
  role       = aws_iam_role.lambda_role.name
}

# Configuring s3 event notification to trigger lambda function whenever a new object is created

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.data_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.process_data_lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = ""
  }
}

# The csv file is sent to quicksight for visualization by our lambda function itself only.

# Create SNS Topic
# Name: kubeshot-notification-topic
resource "aws_sns_topic" "kubeshot_notification" {
  name = "kubeshot-notification-topic"  
}

# Creating Event source mapping to trigger our lambda function

resource "aws_lambda_event_source_mapping" "sns_trigger" {
  event_source_arn = aws_sns_topic.kubeshot_notification.arn
  function_name    = aws_lambda_function.kubeshot_notification_lambda.arn
  batch_size       = 1
  starting_position = "LATEST"
}

resource "aws_sns_topic" "notification-topic" {
  name = "notification-topic"
}

# Creating another lambda function for Notifications

resource "aws_lambda_function" "kubeshot_notification_lambda" {
  filename      = "notification_lambda_function.zip" 
  function_name = "kubeshot-notification-lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "notification_lambda_function.handler"
  runtime       = "python3.8"
}

# Attaching SNS Full Access Policy to our lambda role so that notification lambda function can trigger SNS notifications

resource "aws_iam_policy_attachment" "sns_policy_attachment" {
  name = "sns-policy-attachment"
  policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
  roles      = [aws_iam_role.lambda_role.arn]
}