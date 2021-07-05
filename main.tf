provider "aws" {
    region     = "us-east-1"
    access_key = "aws_access_key_here"
    secret_key = "aws_secret_key_here"
}

variable "myregion" {
    default = "us-east-1"
}

variable "accountId" {
    default = "aws_account_id"
}

resource "aws_dynamodb_table" "ddbtable" {
  name             = "terraform_table"
  hash_key         = "id"
  range_key        = "name" 
  billing_mode     = "PROVISIONED"
  read_capacity    = 5
  write_capacity   = 5
  
  attribute {
    name = "id"
    type = "S"
  }
  attribute {
    name = "name"
    type = "S"
  }
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_policy"
  role = aws_iam_role.role_for_LDC.id
  policy = file("policy.json")
}

resource "aws_iam_role_policy" "lambda_policy1" {
  name = "lambda_policy1"
  role = aws_iam_role.role_for_LDC.id
  policy = file("policy1.json")
}

resource "aws_iam_role" "role_for_LDC" {
  name = "myrole"
  assume_role_policy = file("assume_role_policy.json")
}

resource "aws_lambda_function" "lambda" {
  filename      = "index.zip"
  function_name = "terra_func"
  role          = aws_iam_role.role_for_LDC.arn
  handler       = "index.handler"
  runtime       = "python3.7"
  source_code_hash = filebase64sha256("index.zip")
}

resource "aws_lambda_function" "lambda1" {
  filename      = "index1.zip"
  function_name = "terra1_func"
  role          = aws_iam_role.role_for_LDC.arn
  handler       = "index1.handler"
  runtime       = "python3.7"
  source_code_hash = filebase64sha256("index1.zip")
}

resource "aws_lambda_function" "lambda2" {
  filename      = "index2.zip"
  function_name = "terra2_func"
  role          = aws_iam_role.role_for_LDC.arn
  handler       = "index2.handler"
  runtime       = "python3.7"
  source_code_hash = filebase64sha256("index2.zip")
}


resource "aws_api_gateway_rest_api" "api" {
  name = "terra_first_api"
}

resource "aws_api_gateway_resource" "resource" {
  path_part   = "resource"
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_resource" "resource1" {
  path_part   = "resource1"
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_resource" "resource2" {
  path_part   = "resource2"
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "method1" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource1.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "method2" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource2.id
  http_method   = "ANY"
  authorization = "NONE"
}


#index.py
resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
}


resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "arn:aws:execute-api:${var.myregion}:${var.accountId}:${aws_api_gateway_rest_api.api.id}/*/${aws_api_gateway_method.method.http_method}${aws_api_gateway_resource.resource.path}"
}

#index1.py
resource "aws_api_gateway_integration" "integration1" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resource1.id
  http_method             = aws_api_gateway_method.method1.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda1.invoke_arn
}


resource "aws_lambda_permission" "apigw_lambda1" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda1.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "arn:aws:execute-api:${var.myregion}:${var.accountId}:${aws_api_gateway_rest_api.api.id}/*/${aws_api_gateway_method.method1.http_method}${aws_api_gateway_resource.resource1.path}"
}

#index2.py
resource "aws_api_gateway_integration" "integration2" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resource2.id
  http_method             = aws_api_gateway_method.method2.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda2.invoke_arn
}


resource "aws_lambda_permission" "apigw_lambda2" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda2.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "arn:aws:execute-api:${var.myregion}:${var.accountId}:${aws_api_gateway_rest_api.api.id}/*/${aws_api_gateway_method.method2.http_method}${aws_api_gateway_resource.resource2.path}"
}



resource "aws_api_gateway_deployment" "apideploy" {
   depends_on = [
     aws_api_gateway_integration.integration,aws_api_gateway_integration.integration1,aws_api_gateway_integration.integration2
   ]

   rest_api_id = aws_api_gateway_rest_api.api.id
   stage_name  = "dev"
}

resource "aws_api_gateway_deployment" "apideploy1" {
   depends_on = [
     aws_api_gateway_integration.integration1
   ]

   rest_api_id = aws_api_gateway_rest_api.api.id
   stage_name  = "dev"
}
resource "aws_api_gateway_deployment" "apideploy2" {
   depends_on = [
     aws_api_gateway_integration.integration2
   ]

   rest_api_id = aws_api_gateway_rest_api.api.id
   stage_name  = "dev"
}

output "base_url" {
  value = aws_api_gateway_deployment.apideploy.invoke_url
}
