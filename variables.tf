variable "region" {
  description = "Default region of this terraform project"
}

variable "dynamo_table" {
  description = "Dynamo table name"
}

variable "state_bucket_name" {
  description = "Terraform state file bucket name"
}

variable "github_repo_name" {
  description = "Github repository name"
}

variable "github_org_name" {
  description = "Github organisation name"
}