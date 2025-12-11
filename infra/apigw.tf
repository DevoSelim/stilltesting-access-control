resource "aws_api_gateway_rest_api" "api" {
  name        = "stilltesting-api"
  description = "Access control backend API"
}

resource "aws_api_gateway_authorizer" "cognito" {
  name          = "stilltesting-cognito-authorizer"
  rest_api_id   = aws_api_gateway_rest_api.api.id
  type          = "COGNITO_USER_POOLS"
  identity_source = "method.request.header.Authorization"

  provider_arns = [
    aws_cognito_user_pool.admins.arn
  ]
}

resource "aws_api_gateway_resource" "employee" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "employee"
}

resource "aws_api_gateway_method" "employee_any" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.employee.id
  http_method   = "ANY"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id

  api_key_required = false
}
resource "aws_api_gateway_integration" "employee_any" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.employee.id
  http_method = aws_api_gateway_method.employee_any.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.employee_crud.invoke_arn
}

resource "aws_api_gateway_resource" "token" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "token"
}

resource "aws_api_gateway_method" "token_any" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.token.id
  http_method   = "ANY"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id

  api_key_required = false
}

resource "aws_api_gateway_integration" "token_any" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.token.id
  http_method = aws_api_gateway_method.token_any.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.token_crud.invoke_arn
}

resource "aws_api_gateway_resource" "events" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "events"
}

resource "aws_api_gateway_method" "events_any" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.events.id
  http_method   = "ANY"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id

  api_key_required = false
}

resource "aws_api_gateway_integration" "events_any" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.events.id
  http_method = aws_api_gateway_method.events_any.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.events_rud.invoke_arn
}


resource "aws_api_gateway_deployment" "api" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    redeploy = sha1(jsonencode([
      aws_api_gateway_method.employee_any.id,
      aws_api_gateway_integration.employee_any.id,
      aws_api_gateway_method.token_any.id,
      aws_api_gateway_integration.token_any.id,
      aws_api_gateway_method.events_any.id,
      aws_api_gateway_integration.events_any.id,
      aws_api_gateway_method.iot_event_post.id,
      aws_api_gateway_integration.iot_event_to_sqs.id,
    ]))
  }

  depends_on = [
    aws_api_gateway_integration.employee_any,
    aws_api_gateway_integration.token_any,
    aws_api_gateway_integration.events_any,
    aws_api_gateway_integration.iot_event_to_sqs,
  ]
  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_api_gateway_stage" "dev" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.api.id
  stage_name    = "dev"
}


# Authorizer Lambda for /iot/event
resource "aws_api_gateway_authorizer" "iot_custom" {
  name        = "stilltesting-iot-custom-authorizer"
  rest_api_id = aws_api_gateway_rest_api.api.id

  type = "REQUEST"
  identity_source = "method.request.header.Authorization"
  authorizer_uri = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.custom_authorizer.arn}/invocations"
}
resource "aws_lambda_permission" "apigw_invoke_custom_authorizer" {
  statement_id  = "AllowAPIGatewayInvokeCustomAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.custom_authorizer.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/authorizers/*"
}
resource "aws_lambda_permission" "apigw_invoke_events" {
  statement_id  = "AllowAPIGatewayInvokeEvents"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.events_rud.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*/events"
}


# /iot
resource "aws_api_gateway_resource" "iot" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "iot"
}

# /iot/event
resource "aws_api_gateway_resource" "iot_event" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.iot.id
  path_part   = "event"
}
resource "aws_api_gateway_method" "iot_event_post" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.iot_event.id
  http_method = "POST"

  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.iot_custom.id

  api_key_required = false
}

data "aws_caller_identity" "current" {}

resource "aws_api_gateway_integration" "iot_event_to_sqs" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.iot_event.id
  http_method = aws_api_gateway_method.iot_event_post.http_method

  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${var.region}:sqs:path/${data.aws_caller_identity.current.account_id}/${aws_sqs_queue.iot_events.name}"

  credentials = aws_iam_role.apigw_sqs_role.arn

  request_parameters = {
    "integration.request.header.Content-Type" = "'application/x-www-form-urlencoded'"
  }

  request_templates = {
    "application/json" = "Action=SendMessage&MessageBody=$input.body"
  }
}

