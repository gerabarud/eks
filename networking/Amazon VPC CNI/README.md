# Amazon VPC CNI

EKS utiliza Amazon VPC para proporcionar red a los nodos y pods de Kubernetes. Un clúster de EKS consta de dos VPC: 
- una administrada por AWS que aloja el `control-plane` de Kubernetes 
- una segunda administrada por el cliente que aloja los nodos donde se ejecutan los contenedores, así como otra infraestructura de AWS (como load balancers). 
 
Todos los nodos deben poder conectarse al endpoint del servidor API administrado. Esta conexión permite que el nodo se registre en el `control-plane` y reciba solicitudes para ejecutar pods.

Los nodos se conectan al `control-plane` de EKS a través del endpoint público de EKS o de las interfaces de red elásticas (ENI) administradas por EKS. Las subredes que se definen al crear un clúster influyen dónde EKS ubica estas ENIs. Se debe proporcionar al menos dos subredes en al menos dos zonas de disponibilidad. La ruta que siguen los nodos para conectarse depende de si se ha habilitado o deshabilitado el endpoing privado del clúster. EKS utiliza la ENI administrada por EKS para comunicarse con los nodos.

Amazon EKS es oficialmente compatible con el plugin CNI de Amazon VPC para implementar la red de pods de Kubernetes. El CNI de VPC proporciona integración nativa con AWS VPC y funciona en modo subyacente. 

## Network Policies

## Security Groups

Los grupos de seguridad, que actúan como firewalls de red a nivel de instancia, se encuentran entre los componentes más importantes y utilizados. Las aplicaciones en contenedores suelen requerir acceso a otros servicios que se ejecutan dentro del clúster, así como a servicios externos de AWS, como Amazon Relational Database Service (Amazon RDS) o Amazon ElastiCache. En AWS, el control del acceso a nivel de red entre servicios suele realizarse mediante grupos de seguridad de EC2.

De forma predeterminada, la CNI de Amazon VPC utilizará grupos de seguridad asociados con la ENI principal del nodo. Más específicamente, cada ENI asociada a la instancia tendrá los mismos grupos de seguridad de EC2. **Por lo tanto, cada pod de un nodo comparte los mismos grupos de seguridad que el nodo en el que se ejecuta.** 

Puede habilitar grupos de seguridad para pods configurando `ENABLE_POD_ENI=true` la CNI de VPC. Al habilitar la ENI de pod, el controlador de recursos de VPC que se ejecuta en el `control-plane` (administrado por EKS) crea y conecta una interfaz troncal llamada "aws-k8s-trunk-eni" al nodo. Esta interfaz troncal actúa como una interfaz de red estándar conectada a la instancia.

El controlador también crea interfaces branch llamadas `aws-k8s-branch-eni` y las asocia con la interfaz troncal. A los pods se les asigna un grupo de seguridad mediante el recurso personalizado `SecurityGroupPolicy` y se asocian con una interfaz branch. Dado que los grupos de seguridad se especifican con las interfaces de red, ahora podemos programar pods que requieran grupos de seguridad específicos en estas interfaces de red adicionales. 


