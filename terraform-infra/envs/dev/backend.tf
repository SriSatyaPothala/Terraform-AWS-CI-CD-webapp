terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket-devopsar25"
    key            = "dev/terraform.tfstate"   #path for dev 
    region         = "ap-south-1"
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:ap-south-1:345594588323:key/ad6ce9d5-b2d4-48eb-bf88-f40e2e50cf2b"
  }
}
