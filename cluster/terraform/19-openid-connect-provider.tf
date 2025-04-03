# Obtener el certificado TLS del OIDC de EKS
# Obtiene el certificado TLS del Proveedor de Identidad OIDC del clúster EKS.
# Se usa para verificar la autenticidad de las solicitudes OIDC.
data "tls_certificate" "eks" {
  url = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}

# Crear el Proveedor OIDC en AWS IAM
# Registra el OIDC de EKS en AWS IAM, permitiendo que Kubernetes autentique pods con IAM Roles.
resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}