terraform {
  backend "s3" {
    bucket         = "tf-state-selim-123"    # Remote state bucket
    key            = "infra/terraform.tfstate"
    region         = "eu-west-3"               
    dynamodb_table = "terraform-locks"             
    encrypt        = true
  }
}
