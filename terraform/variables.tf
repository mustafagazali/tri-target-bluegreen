variable "region" {
  type = string
}
variable "project_name" {
  type    = string
  default = "tri-target-bluegreen"
}
variable "vpc_cidr" {
  type    = string
  default = "10.42.0.0/16"
}
variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.42.1.0/24", "10.42.2.0/24"]
}
variable "github_owner" {
  type = string
}
variable "github_repo" {
  type = string
}
variable "github_branch" {
  type    = string
  default = "main"
}
variable "codestar_connection_arn" {
  type = string
}
variable "ec2_key_pair_name" {
  type    = string
  default = null
}