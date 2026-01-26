########################################
# Archives (ZIP) pour chaque Lambda
########################################

data "archive_file" "employee_crud_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambdas/employee_crud"
  output_path = "${path.module}/../lambdas/employee_crud.zip"
}

data "archive_file" "token_crud_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambdas/token_crud"
  output_path = "${path.module}/../lambdas/token_crud.zip"
}

data "archive_file" "events_rud_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambdas/events_rud"
  output_path = "${path.module}/../lambdas/events_rud.zip"
}

data "archive_file" "iot_handler_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambdas/iot_handler"
  output_path = "${path.module}/../lambdas/iot_handler.zip"
}

data "archive_file" "custom_authorizer_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambdas/custom_authorizer"
  output_path = "${path.module}/../lambdas/custom_authorizer.zip"
}


data "archive_file" "db_migrate_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambdas/db_migrate"
  output_path = "${path.module}/../lambdas/db_migrate.zip"
}

########################################
# Lambda employee_crud (Aurora)
########################################

resource "aws_lambda_function" "employee_crud" {
  function_name = "stilltesting-employee-crud"

  handler = "app.handler"
  runtime = "python3.12"

  role = aws_iam_role.lambda_role.arn

  filename         = data.archive_file.employee_crud_zip.output_path
  source_code_hash = data.archive_file.employee_crud_zip.output_base64sha256

  timeout = 10

  vpc_config {
    subnet_ids = [
      aws_subnet.private_a.id,
      aws_subnet.private_b.id,
      aws_subnet.private_c.id,
    ]
    security_group_ids = [aws_security_group.app.id]
  }

  environment {
    variables = {
      AURORA_SECRET_ARN = aws_secretsmanager_secret.aurora_credentials.arn
      DB_NAME           = "stilltesting"
    }
  }
}

########################################
# Lambda token_crud (Aurora)
########################################

resource "aws_lambda_function" "token_crud" {
  function_name = "stilltesting-token-crud"

  handler = "app.handler"
  runtime = "python3.12"

  role = aws_iam_role.lambda_role.arn

  filename         = data.archive_file.token_crud_zip.output_path
  source_code_hash = data.archive_file.token_crud_zip.output_base64sha256

  timeout = 10

  vpc_config {
    subnet_ids = [
      aws_subnet.private_a.id,
      aws_subnet.private_b.id,
      aws_subnet.private_c.id,
    ]
    security_group_ids = [aws_security_group.app.id]
  }

  environment {
    variables = {
      AURORA_SECRET_ARN = aws_secretsmanager_secret.aurora_credentials.arn
      DB_NAME           = "stilltesting"
    }
  }
}

########################################
# Lambda events_rud (DynamoDB only)
########################################

resource "aws_lambda_function" "events_rud" {
  function_name = "stilltesting-events-rud"

  handler = "app.handler"
  runtime = "python3.12"

  role = aws_iam_role.lambda_role.arn

  filename         = data.archive_file.events_rud_zip.output_path
  source_code_hash = data.archive_file.events_rud_zip.output_base64sha256

  timeout = 10

  environment {
    variables = {
      ACCESS_EVENTS_TABLE = aws_dynamodb_table.access_events.name
    }
  }
}

########################################
# Lambda iot_handler (SQS -> DynamoDB)
########################################

resource "aws_lambda_function" "iot_handler" {
  function_name = "stilltesting-iot-handler"

  handler = "app.handler"
  runtime = "python3.12"

  role = aws_iam_role.lambda_role.arn

  filename         = data.archive_file.iot_handler_zip.output_path
  source_code_hash = data.archive_file.iot_handler_zip.output_base64sha256

  timeout = 10

  environment {
    variables = {
      ACCESS_EVENTS_TABLE = aws_dynamodb_table.access_events.name
    }
  }
}

resource "aws_lambda_event_source_mapping" "iot_sqs_mapping" {
  event_source_arn = aws_sqs_queue.iot_events.arn
  function_name    = aws_lambda_function.iot_handler.arn

  batch_size = 10
  enabled    = true
}

########################################
# Lambda custom_authorizer (stub)
########################################

resource "aws_lambda_function" "custom_authorizer" {
  function_name = "stilltesting-custom-authorizer"

  handler = "app.handler"
  runtime = "python3.12"

  role = aws_iam_role.lambda_role.arn

  filename         = data.archive_file.custom_authorizer_zip.output_path
  source_code_hash = data.archive_file.custom_authorizer_zip.output_base64sha256

  timeout = 5
}

########################################
# Permission : API GW -> employee_crud
########################################

resource "aws_lambda_permission" "apigw_invoke_employee" {
  statement_id  = "AllowAPIGatewayInvokeEmployee"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.employee_crud.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*/employee"
}

########################################
# DB-Migrate (Aurora schema apply)
########################################

# Permission to read Aurora credentials secret
resource "aws_iam_role_policy" "db_migrate_secret" {
  name = "stilltesting-db-migrate-secret"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["secretsmanager:GetSecretValue"],
      Resource = aws_secretsmanager_secret.aurora_credentials.arn
    }]
  })
}

resource "aws_lambda_function" "db_migrate" {
  function_name = "stilltesting-db-migrate"

  handler = "app.handler"
  runtime = "python3.12"

  role = aws_iam_role.lambda_role.arn

  filename         = data.archive_file.db_migrate_zip.output_path
  source_code_hash = data.archive_file.db_migrate_zip.output_base64sha256

  timeout = 60

  vpc_config {
    subnet_ids = [
      aws_subnet.private_a.id,
      aws_subnet.private_b.id,
      aws_subnet.private_c.id,
    ]
    security_group_ids = [aws_security_group.app.id]
  }

  environment {
    variables = {
      AURORA_SECRET_ARN = aws_secretsmanager_secret.aurora_credentials.arn
      DB_HOST           = aws_rds_cluster.aurora.endpoint
      DB_NAME           = "stilltesting"
    }
  }

  depends_on = [aws_iam_role_policy.db_migrate_secret]
}
