# Lo usamos para traducir IPs privadas en IPs públicas para proveer acceso público a redes privadas
# [ Instancias en Subred Privada ] → [ NAT Gateway (en Subred Pública) ] → [ Internet Gateway ] → 🌍 Internet

# Primero creamos una Elastic IP (EIP) para asociarla al NAT Gateway.
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${local.env}-nat"
  }
}

resource "aws_nat_gateway" "nat" {
  # Asignamos la Elastic IP creada en el paso anterior.  
  allocation_id = aws_eip.nat.id
  # Lo atachamos a una de las subredes públicas para poder tener acceso a internet
  subnet_id     = aws_subnet.public_zone1.id

  tags = {
    Name = "${local.env}-nat"
  }

  # Nos aseguramos de que el Internet Gateway esté creado antes, ya que sin este, el NAT Gateway no podría funcionar. 
  depends_on = [aws_internet_gateway.igw]
}