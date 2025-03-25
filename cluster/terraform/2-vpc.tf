resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  # DNS es requerido por algunos addons como EFS  
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.env}-main"
  }
}