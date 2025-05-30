variable "access_key" {
  description = "Naver Cloud Access Key"
  type        = string
}

variable "secret_key" {
  description = "Naver Cloud Secret Key"
  type        = string
}

variable "region" {
  description = "Region to deploy resources"
  type        = string
  default     = "KR" # 한국 리전
}

variable "site" {
  description = "Naver Cloud API Site"
  type        = string
  default     = "public"
}

variable "support_vpc" {
  description = "Whether to use VPC environment"
  type        = bool
  default     = true
}

variable "login_key_name" {
  description = "Name of the SSH login key registered in NCP"
  type        = string
}
