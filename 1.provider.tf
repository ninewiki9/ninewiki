
provider "aws" {
  region = var.region
}
data "aws_key_pair" "ninewiki_key" {
  key_name = "ninewiki_key"
}
