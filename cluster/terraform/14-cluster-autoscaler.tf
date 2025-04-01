# Crear el Rol de IAM:
# Crea un rol IAM llamado <nombre-del-cluster>-cluster-autoscaler.
# Permite que los pods en EKS asuman este rol (sts:AssumeRole).
# Está diseñado para funcionar con AWS Pod Identity (pods.eks.amazonaws.com).
resource "aws_iam_role" "cluster_autoscaler" {
  name = "${aws_eks_cluster.eks.name}-cluster-autoscaler"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
      }
    ]
  })
}

# Crear la Política de IAM para Autoscaler: Otorga permisos al Cluster Autoscaler para:
# Leer información sobre Auto Scaling Groups (autoscaling:DescribeAutoScalingGroups).
# Modificar la capacidad (autoscaling:SetDesiredCapacity).
# Terminar instancias (autoscaling:TerminateInstanceInAutoScalingGroup).
resource "aws_iam_policy" "cluster_autoscaler" {
  name = "${aws_eks_cluster.eks.name}-cluster-autoscaler"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DescribeTags",
          "ec2:DescribeImages",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:GetInstanceTypesFromInstanceRequirements",
          "eks:DescribeNodegroup"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup"
        ]
        Resource = "*"
      },
    ]
  })
}

# Vincular la Política al Rol: Asocia la política de permisos al rol IAM del Cluster Autoscaler.
resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  policy_arn = aws_iam_policy.cluster_autoscaler.arn
  role       = aws_iam_role.cluster_autoscaler.name
}

# Asociar el Rol de IAM con un Service Account en Kubernetes
# Asocia el rol IAM cluster_autoscaler al Service Account cluster-autoscaler en Kubernetes.
# Permite que los pods del Cluster Autoscaler usen los permisos IAM sin credenciales estáticas.
resource "aws_eks_pod_identity_association" "cluster_autoscaler" {
  cluster_name    = aws_eks_cluster.eks.name
  namespace       = "kube-system"
  service_account = "cluster-autoscaler"
  role_arn        = aws_iam_role.cluster_autoscaler.arn
}

# Instalar Cluster Autoscaler con Helm seteando variables en lugar de usar values
resource "helm_release" "cluster_autoscaler" {
  name = "autoscaler"

  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"
  version    = "9.37.0"

  set {
    name  = "rbac.serviceAccount.name"
    value = "cluster-autoscaler"
  }

  set {
    name  = "autoDiscovery.clusterName"
    value = aws_eks_cluster.eks.name
  }

  # MUST be updated to match your region 
  set {
    name  = "awsRegion"
    value = "us-east-1"
  }
  # Cluster Autoscaler se instalará después de metrics-server, ya que depende de él para tomar decisiones de escalado.
  depends_on = [helm_release.metrics_server]
}