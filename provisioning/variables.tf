variable "aws_profile" {
  description = "The name of the credentials profile for authentication with AWS"
  type = string
}

variable "aws_assume_role_arn" {
  description = "The ARN of the IAM role to assume with AWS"
  type = string
}

variable "aws_region" {
  description = "The AWS region to use for provisioning resources"
  default = "ca-central-1"
  type = string
}

variable "service_name" {
  description = "The name of the project"
  type = string
}

variable "repository_name" {
  description = "The full repository name e.g. some-user/my-repo"
  type = string
}

variable "repository_branch_name" {
  description = "The repository branch to watch for changes"
  default = "main"
  type = string
}

variable "repository_url" {
  description = "The repository url to watch for changes"
  default = "https://github.com/mdinicola/infinity-reddit-builder"
  type = string
}

variable "repository_connection_arn" {
  description = "The ARN of the CodeStar connection to the external repository"
  type = string
}

variable "repository_codeconnection_arn" {
  description = "The ARN of the CodeStar connection to the external repository"
  type = string
}

variable "artifacts_bucket_name" {
  description = "The name of the artifacts bucket"
  type = string
}

variable "keystore_file_arn" {
  description = "The ARN of the keystore file used for signing the apk"
  type = string
}