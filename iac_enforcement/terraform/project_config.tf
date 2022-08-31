provider "aws" {
  region = "eu-west-1"
  default_tags {
    tags = {
      managed-by = "terraform"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  alias  = "us_east_1"
}


terraform {
  # Add your terraform config here
}
