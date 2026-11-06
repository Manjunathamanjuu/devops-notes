# Terraform Block
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.42.0"
    }
  }
  
  # Adding Backend as S3 for Remote State Storage
  backend "s3" {
    bucket = "bhanu-terraformtest-remote-state2"
    key    = "dev/terraform.tfstate"
    region = "us-east-1" 
    # For State Locking - LockID
    dynamodb_table = "terraform-state-lock-table"      
  }
}

# Provider Block
provider "aws" {
  region  = var.aws_region
  }
/*
Note-1:  AWS Credentials Profile (profile = "default") configured on your local desktop terminal  
$HOME/.aws/credentials
*/
