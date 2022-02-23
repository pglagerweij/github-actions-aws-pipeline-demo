# Create DynamoDB for locking the state file when its used
resource "aws_dynamodb_table" "terraform_locks" {
  name         = var.dynamo_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 2.14"

  bucket = var.state_bucket_name
  acl    = "private"

  force_destroy = true

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  # S3 bucket-level Public Access Block configuration
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_openid_connect_provider" "default" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

data "aws_iam_policy_document" "github_readonly" {
  statement {
    sid = "StateBucket"
    actions = [
      "s3:GetBucketLocation",
      "s3:List*"
    ]
    resources = [module.s3_bucket.s3_bucket_arn]
  }
  statement {
    sid = "StateFileRead"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = ["${module.s3_bucket.s3_bucket_arn}/*"]
  }
  statement {
    sid = "AllowDynamoDBActions"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem",
      "dynamodb:DescribeTable",
      "dynamodb:DeleteItem"
    ]
    resources = [aws_dynamodb_table.terraform_locks.arn]
  }
}

resource "aws_iam_policy" "github_readonly" {
  name        = "github_terraform_readonly"
  description = "Permissions to access state bucket and dynamo table"
  policy      = data.aws_iam_policy_document.github_readonly.json
}
  
module "github_readonly" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 4.11"

  create_role = true

  role_name = "github_readonly"

  tags = {
    Role = "role-with-oidc"
  }

  provider_url = "token.actions.githubusercontent.com"

  role_policy_arns = [
    "arn:aws:iam::aws:policy/ReadOnlyAccess",
    aws_iam_policy.github_readonly.arn
  ]

  oidc_fully_qualified_subjects = ["repo:${var.github_org_name}/${var.github_repo_name}:pull_request"]
}

module "github_readwrite" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 4.11"

  create_role = true

  role_name = "github_readwrite"

  tags = {
    Role = "role-with-oidc"
  }

  provider_url = "token.actions.githubusercontent.com"

  role_policy_arns = [
    "arn:aws:iam::aws:policy/AdministratorAccess",
  ]

  oidc_fully_qualified_subjects = ["repo:${var.github_org_name}/${var.github_repo_name}:ref:refs/heads/main"]
}
