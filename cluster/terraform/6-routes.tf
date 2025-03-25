# Las tablas de ruteo sirven para definir cómo se enruta el tráfico de una subred dentro de una VPC:

# [ Subred Privada ] --(NAT Gateway)--> [ Internet Gateway ] --> 🌍 Internet
# [ Subred Pública ] --(Internet Gateway)--> 🌍 Internet

# Las instancias en subredes privadas pueden salir a Internet (por ejemplo, para actualizaciones), pero NO son accesibles desde Internet.
# Las instancias en subredes públicas tienen acceso directo a Internet y pueden recibir tráfico entrante.

# Tabla de ruteo para las subredes privadas: 
resource "aws_route_table" "private" {
  # La asociamos a la VPC
  vpc_id = aws_vpc.main.id

  # Ruta default para todo el tráfico que no pertenezca a la VPC salta por el NAT a internet
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "${local.env}-private"
  }
}

# Tabla de ruteo para las subredes públicas: 
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  # Ruta default para todo el tráfico que no pertenezca a la VPC salta por el IGW a internet
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${local.env}-public"
  }
}

# Asociaciones: 

# Asocia subredes privadas (private_zone1 y private_zone2) con la tabla de ruteo privada.
resource "aws_route_table_association" "private_zone1" {
  subnet_id      = aws_subnet.private_zone1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_zone2" {
  subnet_id      = aws_subnet.private_zone2.id
  route_table_id = aws_route_table.private.id
}

#  Asocia subredes públicas (public_zone1 y public_zone2) con la tabla de ruteo pública.
resource "aws_route_table_association" "public_zone1" {
  subnet_id      = aws_subnet.public_zone1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_zone2" {
  subnet_id      = aws_subnet.public_zone2.id
  route_table_id = aws_route_table.public.id
}