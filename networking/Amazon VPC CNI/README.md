# Amazon VPC CNI

EKS utiliza Amazon VPC para proporcionar red a los nodos y pods de Kubernetes. Un clúster de EKS consta de dos VPC: 
- una administrada por AWS que aloja el `control-plane` de Kubernetes 
- una segunda administrada por el cliente que aloja los nodos donde se ejecutan los contenedores, así como otra infraestructura de AWS (como load balancers). 
 
Todos los nodos deben poder conectarse al endpoint del servidor API administrado. Esta conexión permite que el nodo se registre en el `control-plane` y reciba solicitudes para ejecutar pods.

Los nodos se conectan al `control-plane` de EKS a través del endpoint público de EKS o de las interfaces de red elásticas (ENI) administradas por EKS. Las subredes que se definen al crear un clúster influyen dónde EKS ubica estas ENIs. Se debe proporcionar al menos dos subredes en al menos dos zonas de disponibilidad. La ruta que siguen los nodos para conectarse depende de si se ha habilitado o deshabilitado el endpoing privado del clúster. EKS utiliza la ENI administrada por EKS para comunicarse con los nodos.

Amazon EKS es oficialmente compatible con el plugin CNI de Amazon VPC para implementar la red de pods de Kubernetes. El CNI de VPC proporciona integración nativa con AWS VPC y funciona en modo subyacente. 

