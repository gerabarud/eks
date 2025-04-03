# Crear una política IAM para el EBS CSI Driver
# Permite que los pods en EKS asuman un rol IAM usando Pod Identity (pods.eks.amazonaws.com).
# Esto es necesario para que el EBS CSI Driver pueda acceder a los volúmenes EBS.
data "aws_iam_policy_document" "ebs_csi_driver" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

# Crear un rol IAM para el EBS CSI Driver
# Crea un rol IAM llamado eks-cluster-name-ebs-csi-driver.
# Asigna la política de confianza definida en data.aws_iam_policy_document.ebs_csi_driver.json.
# Este rol permitirá que los pods del EBS CSI Driver tengan permisos para gestionar volúmenes EBS.
resource "aws_iam_role" "ebs_csi_driver" {
  name               = "${aws_eks_cluster.eks.name}-ebs-csi-driver"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_driver.json
}

# Asociar la política de permisos de AWS EBS CSI Driver
# Asocia la política oficial de AWS (AmazonEBSCSIDriverPolicy) al rol IAM del EBS CSI Driver.
# Permite que los pods manejen volúmenes EBS (crear, adjuntar, desmontar, eliminar).
resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver.name
}

# Optional: only if you want to encrypt the EBS drives
# (Opcional) Permitir cifrado de volúmenes EBS
# Crea una política IAM personalizada para manejar claves KMS.
# Permite al driver usar claves KMS para cifrar y descifrar volúmenes EBS.
resource "aws_iam_policy" "ebs_csi_driver_encryption" {
  name = "${aws_eks_cluster.eks.name}-ebs-csi-driver-encryption"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKeyWithoutPlaintext",
          "kms:CreateGrant"
        ]
        Resource = "*"
      }
    ]
  })
}

# Optional: only if you want to encrypt the EBS drives
# Asocia la política de cifrado al rol IAM, permitiendo usar KMS para encriptar volúmenes EBS. 
resource "aws_iam_role_policy_attachment" "ebs_csi_driver_encryption" {
  policy_arn = aws_iam_policy.ebs_csi_driver_encryption.arn
  role       = aws_iam_role.ebs_csi_driver.name
}

# Configurar la identidad del pod en AWS EKS
# Usa Pod Identity para vincular el rol IAM (ebs_csi_driver) al ServiceAccount de Kubernetes (ebs-csi-controller-sa).
# Esto permite que el EBS CSI Driver use los permisos del rol IAM sin credenciales estáticas.
resource "aws_eks_pod_identity_association" "ebs_csi_driver" {
  cluster_name    = aws_eks_cluster.eks.name
  namespace       = "kube-system"
  service_account = "ebs-csi-controller-sa"
  role_arn        = aws_iam_role.ebs_csi_driver.arn
}

# Instalar el AWS EBS CSI Driver en EKS
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = aws_eks_cluster.eks.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.31.0-eksbuild.1"
  service_account_role_arn = aws_iam_role.ebs_csi_driver.arn

  depends_on = [aws_eks_node_group.general]
}