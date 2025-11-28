# AWS IAM Role Setup for GitHub Actions

This document outlines the configuration of an AWS IAM role that enables GitHub Actions workflows,

to securely manage AWS resources through OpenID Connect (OIDC) federation,

eliminating the need for long-lived access keys.

## 1. Create OIDC Identity Provider

First, check if the GitHub OIDC provider already exists:

```bash
aws iam list-open-id-connect-providers
```

If it doesn't exist, create it:

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

## 2. Create IAM Role with Trust and Permissions Policies

Create the trust policy file (`trust-policy.json`):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_USERNAME/terramate:*"
        }
      }
    }
  ]
}
```

Create the permissions policy file (`permissions-policy.json`):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*",
        "ecs:Describe*",
        "ecs:List*",
        "elasticloadbalancing:Describe*",
        "iam:List*",
        "iam:Get*",
        "logs:Describe*",
        "logs:ListTagsForResource",
        "s3:ListBucket",
        "s3:GetBucketLocation",
        "s3:GetObject",
        "s3:PutObject",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem",
        "dynamodb:DescribeTable"
      ],
      "Resource": "*"
    }
  ]
}
```

Create the IAM role:

```bash
# Create the role with the trust policy
aws iam create-role \
  --role-name GitHubActions-TerramateRole \
  --assume-role-policy-document file://trust-policy.json

# Attach the permissions policy
aws iam put-role-policy \
  --role-name GitHubActions-TerramateRole \
  --policy-name TerramatePermissions \
  --policy-document file://permissions-policy.json
```

**Note:** Replace `YOUR_ACCOUNT_ID` and `YOUR_GITHUB_USERNAME` with your actual AWS account ID and GitHub username.
