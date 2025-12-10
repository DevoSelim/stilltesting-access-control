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

resource "aws_api_gateway_deployment" "api" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    redeploy = sha1(jsonencode([
      aws_api_gateway_method.employee_any.id,
      aws_api_gateway_integration.employee_any.id,
    ]))
  }

  depends_on = [
    aws_api_gateway_integration.employee_any
  ]
}

resource "aws_api_gateway_stage" "dev" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.api.id
  stage_name    = "dev"
}

