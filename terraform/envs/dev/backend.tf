terraform {
  backend "s3" {
    bucket         = "infra-pipeline-terraform-state-rohit-213"
    key            = "dev/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "infra-pipeline-terraform-locks"
    encrypt        = true
  }
}
# terraform {
#   backend "s3" {
#     bucket         = "infra-pipeline-terraform-state-rohit-213"
#     key            = "dev/terraform.tfstate"
#     region         = "ap-south-1"
#     encrypt        = true
#     use_lockfile   = true
#   }
# }