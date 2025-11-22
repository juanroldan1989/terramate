locals {
  aws_provider_version = "5.82.2"
  aws_account_id       = get_env("AWS_ACCOUNT_ID", "123456789012")
  environment          = "dev"

  # Cross-account roles for disaster recovery
  dr_accounts = {
    qa   = "234567890123"
    prod = "345678901234"
  }

  # Backup configuration
  backup_retention_days = 30

  # Monitoring
  central_monitoring_account = "456789012345"
}
