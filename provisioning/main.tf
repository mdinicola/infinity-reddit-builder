provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
  assume_role {
    role_arn = var.aws_assume_role_arn
  }
  default_tags {
    tags = {
      Component = var.service_name
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
    account_id = data.aws_caller_identity.current.account_id
}

resource "aws_secretsmanager_secret" "app_secret" {
  name = "apps/${var.service_name}"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codebuild" {
  name = "CodeBuild_${var.service_name}"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "codebuild" {
  statement {
    effect = "Allow"

    actions = [
      "codestar-connections:GetConnectionToken",
      "codestar-connections:GetConnection",
      "codeconnections:GetConnectionToken",
      "codeconnections:GetConnection",
      "codeconnections:UseConnection"
    ]

    resources = [
      "${var.repository_connection_arn}",
      "${var.repository_codeconnection_arn}"
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "arn:aws:logs:ca-central-1:${local.account_id}:log-group:/aws/codebuild/${var.service_name}",
      "arn:aws:logs:ca-central-1:${local.account_id}:log-group:/aws/codebuild/${var.service_name}:*",
    ]
  }

  statement {
    effect    = "Allow"
    actions   = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation"
    ]
    resources = [
      "arn:aws:s3:::codepipeline-ca-central-1-*"
    ]
  }

  statement {
    effect    = "Allow"
    actions   = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation"
    ]
    resources = [
      "arn:aws:s3:::${var.artifacts_bucket_name}",
      "arn:aws:s3:::${var.artifacts_bucket_name}/*"
    ]
  }

  statement {
    effect    = "Allow"
    actions   = [
      "s3:GetObject"
    ]
    resources = [
      "${var.keystore_file_arn}",
    ]
  }

  statement {
    effect    = "Allow"
    actions   = [
      "codebuild:CreateReportGroup",
      "codebuild:CreateReport",
      "codebuild:UpdateReport",
      "codebuild:BatchPutTestCases",
      "codebuild:BatchPutCodeCoverages"
    ]
    resources = [
      "arn:aws:codebuild:ca-central-1:${local.account_id}:report-group/${var.service_name}-*",
    ]
  }

  statement {
    effect    = "Allow"
    actions   = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      "${aws_secretsmanager_secret.app_secret.arn}",
    ]
  }
}

resource "aws_iam_role_policy" "codebuild" {
  role = aws_iam_role.codebuild.name
  policy = data.aws_iam_policy_document.codebuild.json
}

resource "aws_codebuild_project" "codebuild" {
  name = var.service_name
  description = "Builds Infinity-For-Reddit APK with custom app id"
  build_timeout = 20
  service_role = aws_iam_role.codebuild.arn

  artifacts {
    type = "S3"
    name = var.service_name
    packaging = "NONE"
    location = var.artifacts_bucket_name
    namespace_type = "BUILD_ID"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image = "aws/codebuild/amazonlinux-x86_64-standard:5.0"
    type = "LINUX_CONTAINER"
  }

  source {
    type = "GITHUB"
    location = var.repository_url
    git_clone_depth = 1
  }

  source_version = var.repository_branch_name

  logs_config {
    cloudwatch_logs {
      status = "ENABLED"
    }
  }
}

resource "aws_codebuild_source_credential" "codebuild_credential" {
  auth_type = "CODECONNECTIONS"
  server_type = "GITHUB"
  token = "${var.repository_connection_arn}"
}