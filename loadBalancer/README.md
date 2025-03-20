# AWS Load Balancer Controller

AWS Load Balancer Controller es un controlador que ayuda a administrar Elastic Load Balancers para un clúster de Kubernetes.

El controlador puede aprovisionar los siguientes recursos:

- Un Aplication Load Balancer (ALB) de AWS cuando crea un Ingress en Kubernetes.
- Un Network Load Balancer (NLB) de AWS cuando crea un Kubernetes Service de tipo LoadBalancer.

Los ALB funcionan según `L7` del modelo OSI, lo que permite exponer el servicio Kubernetes mediante reglas de entrada y admite el tráfico externo. Los NLB funcionan según `L4` del modelo OSI, lo que permite aprovechar Kubernetes Services para exponer un conjunto de pods como un servicio de red de aplicaciones.

El controlador permite simplificar las operaciones al compartir un ALB entre múltiples aplicaciones en su clúster de Kubernetes.

## Exponer aplicaciones con AWS Load Balancer Controller

### Instalación del controlador

```bash
helm repo add eks-charts https://aws.github.io/eks-charts

helm upgrade --install aws-load-balancer-controller eks-charts/aws-load-balancer-controller \
  --version "${LBC_CHART_VERSION}" \
  --namespace "kube-system" \
  --set "clusterName=${EKS_CLUSTER_NAME}" \
  --set "serviceAccount.name=aws-load-balancer-controller-sa" \
  --set "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"="$LBC_ROLE_ARN" \
  --wait
```

### Crear un Load Balancer

El siguiente servicio va a crear un Network Load Balancer (NLB)

```bash
apiVersion: v1
kind: Service
metadata:
  name: ui-nlb
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: external
    service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: instance
  namespace: ui
spec:
  type: LoadBalancer
  ports:
    - port: 80
      targetPort: 8080
      name: http
  selector:
    app.kubernetes.io/name: ui
    app.kubernetes.io/instance: ui
    app.kubernetes.io/component: service
```

Analisis:

```yaml
service.beta.kubernetes.io/aws-load-balancer-type: external
```
📌 **¿Qué hace?**  
- Define que el servicio **usará un Load Balancer en AWS**.  
- Puede ser un **Application Load Balancer (ALB)** o un **Network Load Balancer (NLB)**.  
- Como más abajo se usa `aws-load-balancer-nlb-target-type: instance`, se creará un **NLB**.  

✔ **Opciones posibles:**  
| Valor  | Tipo de Load Balancer creado |
|--------|------------------------------|
| `external` | Un **NLB o ALB** accesible desde Internet o redes privadas. |
| `nlb` | Un **NLB** específico. |
| `alb` | Un **ALB** específico. |

---

```yaml
service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
```
📌 **¿Qué hace?**  
- Define si el Load Balancer **será accesible desde Internet o solo dentro de la VPC**.  
- **`internet-facing`** → Se expone a Internet (tendrá una **IP pública** y será accesible desde cualquier red).  

✔ **Opciones posibles:**  
| Valor | Descripción |
|--------|-------------|
| `internet-facing` | Hace que el NLB tenga IPs públicas y sea accesible desde Internet. |
| `internal` | Crea un NLB solo accesible dentro de la VPC (para tráfico privado). |

---

```yaml
service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: instance
```
📌 **¿Qué hace?**  
- Define **cómo el NLB enruta el tráfico a los pods** en Kubernetes.  
- **`instance`** → El NLB **redirige el tráfico a los nodos EC2** en lugar de a los pods directamente.  

✔ **Opciones posibles:**  
| Valor | Descripción |
|--------|-------------|
| `instance` | Enruta tráfico a los nodos del clúster EKS (requiere que los nodos acepten tráfico en el puerto destino). |
| `ip` | Enruta tráfico directamente a los pods de Kubernetes (requiere que los pods tengan IPs accesibles en la VPC). |

📌 **Diferencia entre `instance` y `ip`:**  
- **`instance` (usado en este ejemplo)** → Se necesita que cada nodo EC2 acepte tráfico en el puerto `8080`.  
- **`ip`** → Cada pod recibe tráfico directamente, sin pasar por los nodos.  

📌 **¿Cuándo usar `instance` vs `ip`?**  
✔ Usa `instance` si los pods pueden moverse entre nodos y no quieres exponer muchas IPs.  
✔ Usa `ip` si necesitas que cada pod maneje tráfico individualmente (mejor para redes privadas).  


Aplicar:
```bash
kubectl apply -f nlb.yaml
kubectl get service -n ui
```

Decribirlo en aws:
```bash
aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-ui-uinlb`) == `true`]'
```
¿Qué nos dice esto?

- La NLB es accesible a través de Internet público.
- Utiliza las subredes públicas en nuestra VPC

We can also inspect the targets in the target group that was created by the controller:

También podemos inspeccionar los `target group` que fue creado por el controlador:

```bash
ALB_ARN=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-ui-uinlb`) == `true`].LoadBalancerArn' | jq -r '.[0]')

TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups --load-balancer-arn $ALB_ARN | jq -r '.TargetGroups[0].TargetGroupArn')

aws elbv2 describe-target-health --target-group-arn $TARGET_GROUP_ARN
```