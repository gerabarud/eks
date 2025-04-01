# 1. Obtener el account_id: Esto es un data source de Terraform que te trae información de la cuenta actual (ID, usuario, etc.)
data "aws_caller_identity" "current" {}

# 2. Crear el rol eks_admin: Esto crea un rol IAM llamado eks_admin que podrá ser asumido por cualquier usuario de tu propia cuenta (por eso :root).
resource "aws_iam_role" "eks_admin" {
  name = "${local.env}-${local.eks_name}-eks-admin"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      }
    }
  ]
}
POLICY
}

# 3. Crear una política para eks_admin:  da permiso completo sobre EKS (eks:*) y también le permite usar iam:PassRole para que pueda asociar roles a recursos EKS (necesario para service accounts y addons).
resource "aws_iam_policy" "eks_admin" {
  name = "AmazonEKSAdminPolicy"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "eks:*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "iam:PassedToService": "eks.amazonaws.com"
                }
            }
        }
    ]
}
POLICY
}

# Asociar la policy al rol eks_admin
resource "aws_iam_role_policy_attachment" "eks_admin" {
  role       = aws_iam_role.eks_admin.name
  policy_arn = aws_iam_policy.eks_admin.arn
}

# Crear un usuario llamado manager
resource "aws_iam_user" "manager" {
  name = "manager"
}

# Crear una policy para que manager pueda asumir eks_admin: Esta policy permite a manager hacer sts:AssumeRole sobre el rol eks_admin.
resource "aws_iam_policy" "eks_assume_admin" {
  name = "AmazonEKSAssumeAdminPolicy"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sts:AssumeRole"
            ],
            "Resource": "${aws_iam_role.eks_admin.arn}"
        }
    ]
}
POLICY
}

# Asociar esa policy al usuario manager
resource "aws_iam_user_policy_attachment" "manager" {
  user       = aws_iam_user.manager.name
  policy_arn = aws_iam_policy.eks_assume_admin.arn
}

# Best practice: use IAM roles due to temporary credentials
# Registrar el rol eks_admin como acceso en el cluster
# Ahora este rol (eks_admin) va a tener acceso al cluster EKS y estará asignado al grupo my-admin dentro de Kubernetes.
# Este grupo es el que bindiamos al cluster role cluster-admin
resource "aws_eks_access_entry" "manager" {
  cluster_name      = aws_eks_cluster.eks.name
  principal_arn     = aws_iam_role.eks_admin.arn
  kubernetes_groups = ["my-admin"]
}