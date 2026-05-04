# terraform {
#   backend "s3" {
#     bucket       = "infra-pipeline-tf-state"
#     key          = "staging/terraform.tfstate"
#     region       = "ap-south-1"
#     use_lockfile = true
#   }
# }

terraform {
  backend "s3" {
    bucket         = "infra-pipeline-terraform-state-rohit-213"
    key            = "staging/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "infra-pipeline-terraform-locks"
    encrypt        = true
  }
}
