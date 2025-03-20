## Crear cluster con Terraform

Terraform va a crear lo siguiente: 
- Create a VPC across three availability zones
- Create an EKS cluster
- Create an IAM OIDC provider
- Add a managed node group named default
- Configure the VPC CNI to use prefix delegation

Download Terraform files:
```bash
mkdir -p terraform; cd terraform
curl --remote-name-all https://raw.githubusercontent.com/aws-samples/eks-workshop-v2/stable/cluster/terraform/{main.tf,variables.tf,providers.tf,vpc.tf,eks.tf}
```

Desplegar ambiente
```bash
export EKS_CLUSTER_NAME=eks-workshop
terraform init
terraform apply -var="cluster_name=$EKS_CLUSTER_NAME" -auto-approve
```