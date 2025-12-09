#Zipping lambdas
data "archive_file" "employee_crud_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambdas/employee_crud"
  output_path = "${path.module}/../lambdas/employee_crud.zip"
}
data "archive_file" "custom_authorizer_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambdas/custom_authorizer"
  output_path = "${path.module}/../lambdas/custom_authorizer.zip"
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
data "archive_file" "token_crud_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambdas/token_crud"
  output_path = "${path.module}/../lambdas/token_crud.zip"
}

#Lambdas Config

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

        security_group_ids = [
          aws_security_group.app.id,
        ]
    }



  environment {
    variables = {
      AURORA_SECRET_ARN = aws_secretsmanager_secret.aurora_credentials.arn
      DB_NAME           = "stilltesting"
    }
  }
}

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
resource "aws_lambda_function" "events_rud" {
  function_name = "stilltesting-events-rud"

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
      ACCESS_EVENTS_TABLE = aws_dynamodb_table.access_events.name
    }
  }
}
resource "aws_lambda_function" "iot_handler" {
  function_name = "stilltesting-iot-handler"

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
      ACCESS_EVENTS_TABLE = aws_dynamodb_table.access_events.name
    }
  }
}
resource "aws_lambda_function" "custom_authorizer" {
  function_name = "stilltesting-custom-authorizer"

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

}

