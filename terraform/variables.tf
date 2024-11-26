variable "yc_iam_token" {
  description = "IAM Token for Yandex Cloud"
  type        = string
}

variable "yc_cloud_id" {
  description = "Cloud ID for Yandex Cloud"
  type        = string
}

variable "yc_folder_id" {
  description = "Folder ID for Yandex Cloud"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_user" {
  description = "Database user"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
}

variable "yc_postgresql_version" {
  description = "PostgreSQL version for Yandex Cloud"
  type        = string
  default     = "13"
}

#variable "ssh_key" {
#  type      = string
#  sensitive = true
#}

variable "service_account_id" {
  type      = string
  sensitive = true
}


variable "cert_id" {
  type = string
}


variable "zone_id" {
  type = string
}
