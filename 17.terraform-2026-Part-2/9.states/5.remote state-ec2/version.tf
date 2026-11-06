terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.88.0"
    }
  }
  backend "s3" {
    bucket = "bhanu-terraform-remote-state2" // Bucket where to SAVE Terraform State
    key    = "prod/state/terraform.tfstate" // Object name in the bucket to SAVE Terraform State
    region = "us-east-1"                     // Region where bucket created
    profile = "dev-account"
    use_lockfile = "true"
  }
}
