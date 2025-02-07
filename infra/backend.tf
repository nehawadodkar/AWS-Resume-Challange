terraform {
  backend "s3" {
    bucket         = "nehaw-terraform-backend"
    key            = "aws-resume-challange/terraform.tfstate"   # Path within the bucket
    region         = "us-east-1"                   # Replace with your region
    #dynamodb_table = "terraform-lock"              # For state locking (optional)
    encrypt        = true                          # Encrypt the state at rest
  }
}
