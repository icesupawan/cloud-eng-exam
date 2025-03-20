locals {
  db_creds = jsondecode(
    data.aws_secretsmanager_secret_version.database_secret.secret_string
  )
}

data "aws_secretsmanager_secret_version" "database_secret" {
  secret_id = "arn:aws:secretsmanager:ap-southeast-1:${var.account_id}:secret:cloud-eng-exam"
}

resource "aws_rds_cluster" "db_cluster" {
  cluster_identifier                  = var.cluster_identifier
  engine                              = var.engine
  engine_mode                         = var.engine_mode
  engine_version                      = var.engine_version
  master_username                     = local.db_creds.master_username
  master_password                     = local.db_creds.master_password
  backup_retention_period             = var.backup_retention_period
  final_snapshot_identifier           = "${var.cluster_identifier}-db-aurora-final-snapshot"
  copy_tags_to_snapshot               = true
  preferred_backup_window             = "18:00-18:30"
  preferred_maintenance_window        = "Mon:18:30-Mon:19:00"
  port                                = 5432
  db_subnet_group_name                = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids              = [var.security_group_id]
  db_cluster_parameter_group_name     = aws_rds_cluster_parameter_group.rds_cluster_parameter_group.name
  db_instance_parameter_group_name    = aws_db_parameter_group.db_aurora_parameter_group.name
  allow_major_version_upgrade         = false
  storage_encrypted                   = true
  iam_database_authentication_enabled = true
  kms_key_id                          = aws_kms_key.db_key.arn
  apply_immediately                   = true
  deletion_protection                 = true
  enabled_cloudwatch_logs_exports     = ["postgresql", "instance", "iam-db-auth-error"]
  performance_insights_enabled          = true
  performance_insights_retention_period = 7
}

resource "aws_rds_cluster_instance" "db_cluster_instances" {
  identifier                            = var.cluster_identifier
  cluster_identifier                    = aws_rds_cluster.db_cluster.id
  engine                                = aws_rds_cluster.db_cluster.engine
  engine_version                        = aws_rds_cluster.db_cluster.engine_version
  instance_class                        = var.instance_class
  publicly_accessible                   = false
  db_subnet_group_name                  = aws_db_subnet_group.db_subnet_group.name
  db_parameter_group_name               = aws_db_parameter_group.db_aurora_parameter_group.name
  apply_immediately                     = true
  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  preferred_maintenance_window          = "Mon:18:30-Mon:19:00"
  auto_minor_version_upgrade            = false
  monitoring_role_arn                   = aws_iam_role.rds_monitoring_role.arn
  monitoring_interval                   = 60
  copy_tags_to_snapshot                 = true
}


resource "aws_rds_cluster_parameter_group" "rds_cluster_parameter_group" {
  name   = "${var.cluster_identifier}-cluter-parameter-group"
  family = "aurora-postgresql14"

  parameter {
    apply_method = "pending-reboot"
    name         = "shared_preload_libraries"
    value        = "pgaudit,pg_stat_statements"
  }
  parameter {
    name  = "pgaudit.log"
    value = "read,write"
  }
  parameter {
    name  = "pgaudit.role"
    value = "rds_pgaudit"
  }
}

resource "aws_db_parameter_group" "db_aurora_parameter_group" {
  name   = "${var.cluster_identifier}-db-aurora-parameter-group"
  family = "aurora-postgresql14"

  parameter {
    apply_method = "pending-reboot"
    name         = "shared_preload_libraries"
    value        = "pgaudit,pg_stat_statements"
  }
  parameter {
    name  = "pgaudit.log"
    value = "read,write"
  }
  parameter {
    name  = "pgaudit.role"
    value = "rds_pgaudit"
  }
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.cluster_identifier}-db-subnet-group"
  subnet_ids = var.subnet_ids
}

resource "aws_kms_key" "db_key" {}

resource "aws_iam_role" "db_role" {
  name = "${var.cluster_identifier}-db-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "rds.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_kms_grant" "db_key" {
  name              = "${var.cluster_identifier}-db-key"
  key_id            = aws_kms_key.db_key.key_id
  grantee_principal = aws_iam_role.db_role.arn
  operations        = ["Encrypt", "Decrypt", "GenerateDataKey", "ReEncryptFrom", "ReEncryptTo", "CreateGrant", "DescribeKey"]
}

resource "aws_iam_role" "rds_monitoring_role" {
  name = "${var.cluster_identifier}-rds-monitoring-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      },
    ]
  })

  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"]
}

# resource "aws_iam_role" "argos_service_update_db_task_role" {
#   name               = "argos-service-update-db-task-role-${var.env}"
#   assume_role_policy = <<EOF
# {
#  "Version": "2012-10-17",
#  "Statement": [
#     {
#      "Action": "sts:AssumeRole",
#      "Principal": {
#        "Service": "ecs-tasks.amazonaws.com"
#      },
#      "Effect": "Allow",
#      "Sid": ""
#     }
#  ]
# }
# EOF
#   tags               = local.tags_argos_service_update_db
# }

# resource "aws_iam_policy" "argos_service_update_db_task_role_policy" {
#   name   = "argos-service-update-db-TaskRole-policy-${var.env}"
#   policy = <<EOF
# {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Action": [
#                 "secretsmanager:GetSecretValue"
#             ],
#             "Resource": [
#                 "arn:aws:secretsmanager:ap-southeast-1:${var.account_id}:secret:/${var.env}/*"
#             ],
#             "Effect": "Allow"
#         }
#     ]
# }
# EOF
#   tags   = local.tags_argos_service_update_db
# }

# resource "aws_iam_role_policy_attachment" "argos_service_update_db_policy_attachment" {
#   role       = aws_iam_role.argos_service_update_db_task_role.name
#   policy_arn = aws_iam_policy.argos_service_update_db_task_role_policy.arn
# }
