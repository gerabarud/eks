# CIDR Calculator: https://mxtoolbox.com/subnetcalculator.aspx
# Necesitamos si o si dos AZ distintas. En cada una creamos una subred privada y una subred pública

resource "aws_subnet" "private_zone1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.0.0/19"
  availability_zone = local.zone1

  tags = {
    # Etiquetas en subredes: https://docs.aws.amazon.com/es_es/eks/latest/userguide/network-load-balancing.html#_prerequisites
    "Name"                                                 = "${local.env}-private-${local.zone1}"
    # La siguiente es usada por EKS para decidir donde crear load balancers dependiendo privados
    "kubernetes.io/role/internal-elb"                      = "1"
    "kubernetes.io/cluster/${local.env}-${local.eks_name}" = "owned"
  }
}

resource "aws_subnet" "private_zone2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.32.0/19"
  availability_zone = local.zone2

  tags = {
    "Name"                                                 = "${local.env}-private-${local.zone2}"
    "kubernetes.io/role/internal-elb"                      = "1"
    "kubernetes.io/cluster/${local.env}-${local.eks_name}" = "owned"
  }
}

resource "aws_subnet" "public_zone1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.64.0/19"
  availability_zone       = local.zone1
  # Si necesitamos que un nodo tenga IP pública, lo alojamos en una subred pública y habilitamos la siguiente opción 
  map_public_ip_on_launch = true

  tags = {
    "Name"                                                 = "${local.env}-public-${local.zone1}"
    # La siguiente es usada por EKS para decidir donde crear load balancers dependiendo públicos
    "kubernetes.io/role/elb"                               = "1"
    "kubernetes.io/cluster/${local.env}-${local.eks_name}" = "owned"
  }
}

resource "aws_subnet" "public_zone2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.96.0/19"
  availability_zone       = local.zone2
  map_public_ip_on_launch = true

  tags = {
    "Name"                                                 = "${local.env}-public-${local.zone2}"
    "kubernetes.io/role/elb"                               = "1"
    "kubernetes.io/cluster/${local.env}-${local.eks_name}" = "owned"
  }
}