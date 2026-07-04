# A data source is a read-only block that queries information from AWS or other external sources.
# Unlike Terraform resources, which have a full lifecycle of create, update, and delete, data sources only retrieve data at runtime to make configurations dynamic

data "aws_availability_zones" "available" {
  state = "available"
}