# Crear un usuario IAM llamado viewer
resource "aws_iam_user" "viewer" {
  name = "viewer"
}

# Crear una policy personalizada llamada AmazonEKSDeveloperPolicy
# eks:DescribeCluster: Ver la descripción de cualquier cluster EKS.
# eks:ListClusters: Listar todos los clusters EKS.
# "Resource": "*": Todos los cluster. Podríamos restringir a un cluster en particular
resource "aws_iam_policy" "viewer_eks" {
  name = "AmazonEKSDeveloperPolicy"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "eks:DescribeCluster",
                "eks:ListClusters"
            ],
            "Resource": "*"
        }
    ]
}
POLICY
}

# Asociar la policy al usuario
resource "aws_iam_user_policy_attachment" "viewer_eks" {
  user       = aws_iam_user.viewer.name
  policy_arn = aws_iam_policy.viewer_eks.arn
}

# Crear el aws_eks_access_entry- Este recurso sirve para registrar al usuario IAM (principal_arn) dentro del cluster EKS.
resource "aws_eks_access_entry" "viewer" {
  cluster_name      = aws_eks_cluster.eks.name
  principal_arn     = aws_iam_user.viewer.arn
  # Lo registramos como un grupo que despues lo mapeamos con RBAC a un ClusterRole
  kubernetes_groups = ["my-viewer"]
}