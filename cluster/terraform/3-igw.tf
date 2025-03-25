# Este recurso provee acceso a internet a las subredes públicas

resource "aws_internet_gateway" "igw" {
  # Atachamos la vpc creada en 2
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.env}-igw"
  }
}