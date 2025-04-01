# Crear cluster con Terraform

Terraform va a crear lo siguiente: 
- Create a VPC across three availability zones
- Create an EKS cluster
- Create an IAM OIDC provider
- Add a managed node group named default
- Configure the VPC CNI to use prefix delegation

## Desplegar VPC y configuraciones de red

Vamos a crear:
- 1 VPC
- 2 Subredes públicas
- 2 Subredes privadas
- 1 Internet GW
- 1 Nat GW
- 1 Tabla de ruteo pública
- 1 Tabla de ruteo privada

![alt text](01-vpc.png)
![alt text](02-tableroutes.png)

```bash
terraform init
terraform apply
```

## Desplegar EKS y Nodos

Vamos a crear:
- eks cluster
- nodos

![alt text](03-nodos.png)

## IAMs permisos

![alt text](04-iam.png)

### Viewer

1. Creamos un rol con los siguientes permisos:
```yaml
    resources: ["deployments", "configmaps", "pods", "secrets", "services"]
    verbs: ["get", "list", "watch"]
```
Aplicamos
```bash
kubectl apply -f viewer-role/0-viewer-cluster-role.yaml
```

2. Bindeamos el rol con un grupo que luego crearemos con IAM

Aplicamos
```bash
kubectl apply -f viewer-role/1-viewer-cluster-role-binding.yaml
```

3. Aplicamos el TF `9-add-viewer-user.tf`

4. Crear credenciales para ese user: Por consola, en `IAM > Users > viewer > Security Credentials > Create access key` 

El usuarios se tiene que conectar haciendo:
```bash
aws sso configure --profile viewer
```
y configura las credenciales creadas. 

Luego, configura el cluster
```bash
aws eks update-kubeconfig --name cluster-siu --alias cluster-siu-ueprod --profile viewer
```

Probar
```bash
kubectl auth can-i get pods
```

### Admin

1. En este caso usamos un role ya disponile en el cluster y con permisos de administración

Por lo tanto, directamente, hacemos el binding:
```bash
kubectl apply -f admin-role/admin-cluster-role-binding.yaml
```

2. Aplicamos el tf `10-add-manager-role.tf` 

3. Crear credenciales para ese user: Por consola, en `IAM > Users > manager > Security Credentials > Create access key`

El usuarios se tiene que conectar haciendo:
```bash
aws sso configure --profile manager
```
y configura las credenciales creadas. 

Luego, configura el cluster
```bash
aws eks update-kubeconfig --name cluster-siu --alias cluster-siu-ueprod --profile manager
```

Probar
```bash
kubectl auth can-i "*" "*"
```

## Configurar HELM en el cluster

✔️ Permite a Terraform usar Helm para desplegar aplicaciones en EKS.
✔️ Se usa en módulos de Terraform donde se quiere instalar Prometheus, Nginx, Ingress, Cert-Manager, etc. con Helm.
✔️ No necesita archivos kubeconfig, ya que genera la autenticación en tiempo de ejecución.

Como vamos a usar un nuevo provider, primero hay que inicializar terraform:

```bash
terraform init
```

- Aplicar tf `11-helm-providers.tf`

Probar: 
```bash
k top nodes
k top pod -A
```

## HPA

Para, métricas personalizadas a parte de CPU y RAM utilization: https://www.youtube.com/watch?v=hsJ2qtwoWZw&list=PLiMWaCMwGJXnHmccp2xlBENZ1xr4FpjXF&index=8&pp=iAQB

Prerequisitos:
✔️ Metrics Server debe estar instalado en el cluster. Se usa para obtener el uso de CPU y memoria de los pods.
✔️ El cluster debe permitir el escalado automático, asegurando que haya suficientes nodos disponibles.
✔️ Los pods deben tener requests de CPU y memoria definidos en su Deployment:

```yaml
          resources:
            requests:
              memory: 256Mi
              cpu: 100m
            limits:
              memory: 256Mi
              cpu: 100m
```

Ejemplo de HPA:

```yaml
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: myapp
  namespace: hpa
spec:
  # Definición del escalado
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  # Definición de Réplicas
  minReplicas: 1
  maxReplicas: 5
  # Métricas de Autoescalado
  metrics:
    # Métrica 1: CPU - Si el uso promedio de CPU en los pods supera el 80%, se escala hacia arriba.
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 80
    # Métrica 2: Memoria - Si el uso promedio de memoria en los pods supera el 70%, Kubernetes escalará hacia arriba.
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 70
```

Aplicar ejemplo: 
```bash
k apply -f hpa
```

Chequear HPA:
```bash
k get hpa
```

Hacer escalar la app:
```bash
k port-forward svc/myapp 8080
# La app calcula número fibbonchi y aumenta su CPU
curl "localhost:8080/api/cpu?index=44"
```

## Cluster Autoscaler & EKS Pod Identities

### Cluster Autoscaler

Es un componente externo que se debe instalar para escalar automáticamente el cluster. 

Permisos para que pueda autoescalar con `EKS Pod Identities`:

1. Instalamos el agente de pod identity

¿Para qué sirve eks-pod-identity-agent?

📌 Permite que los pods en Kubernetes usen roles de IAM sin credenciales estáticas.
📌 Mejora la seguridad al eliminar la necesidad de almacenar claves de acceso en los pods.
📌 Facilita el uso de servicios de AWS (S3, DynamoDB, RDS, etc.) desde aplicaciones en EKS.
📍 Ejemplo de uso

    - Se configura un Service Account en Kubernetes.
    - Se asocia ese Service Account a un rol de IAM.
    - Los pods que usan ese Service Account pueden acceder a AWS con permisos específicos.

Aplicamos el tf `13-pod-Identity-addon.tf`

2. Creamos el autoscaler aplicando `14-cluster-autoscaler.tf`

¿Qué hace este código?

- Crea un rol de IAM (aws_iam_role.cluster_autoscaler) que los pods de Cluster Autoscaler pueden asumir.
- Crea una política de IAM (aws_iam_policy.cluster_autoscaler) con permisos para escalar nodos.
- Adjunta la política al rol de IAM (aws_iam_role_policy_attachment.cluster_autoscaler).
- Asocia el rol de IAM con el Service Account de Kubernetes (aws_eks_pod_identity_association.cluster_autoscaler).
- Despliega Cluster Autoscaler con Helm (helm_release.cluster_autoscaler).

```bash
k get pods -n kube-system
```

3. Probamos con un ejemplo: un deployment con 5 réplicas

```bash
k apply -f autoscaler
```

## ALB

Servicio de balanceo de carga de AWS que distribuye el tráfico entrante entre múltiples instancias de backend (EC2, contenedores en ECS, pods en EKS, etc.). Está diseñado para aplicaciones que operan a nivel de capa 7 (HTTP/HTTPS), permitiendo balanceo basado en contenido, reglas avanzadas de enrutamiento y soporte para microservicios.

![alt text](05-alb.png)

1. Crear ALB con tf `15-aws-lbc.tf`

## Ingress

![alt text](ingress.png)