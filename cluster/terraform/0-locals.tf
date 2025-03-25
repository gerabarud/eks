# Latest k8s versions https://docs.aws.amazon.com/es_es/eks/latest/userguide/kubernetes-versions.html

locals {
  env         = "desarrollo"
  region      = "us-east-1"
  zone1       = "us-east-1a"
  zone2       = "us-east-1b"
  eks_name    = "cluster-siu"
  eks_version = "1.32"
}