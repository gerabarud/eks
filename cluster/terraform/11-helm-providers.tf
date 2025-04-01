# Obtener datos del cluster EKS: Endpoint API (eks.endpoint) y Certificado CA (eks.certificate_authority[0].data)
data "aws_eks_cluster" "eks" {
  name = aws_eks_cluster.eks.name
}

# Obtener autenticación para EKS: token de autenticación (eks.token) para interactuar con Kubernetes a través de kubectl o Helm.
data "aws_eks_cluster_auth" "eks" {
  name = aws_eks_cluster.eks.name
}

# Proveedor Helm para conectarse al cluster: 
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}