# Proyecto TechStore - Despliegue en Kubernetes

## Descripción del Proyecto

Este proyecto implementa una solución de alta disponibilidad para TechStore, una tienda virtual de comercio electrónico, utilizando Kubernetes (Minikube) para resolver problemas críticos de:

* Escalabilidad ante tráfico masivo
* Despliegues sin tiempo de inactividad (Zero-Downtime)
* Persistencia de datos garantizada
* Gobernanza de recursos de cómputo

## Arquitectura Implementada

La solución consta de una arquitectura multi-capa con los siguientes componentes:

### Frontend (3 réplicas)

* **Imagen:** `nginx:1.25-alpine`
* **Estrategia:** RollingUpdate con `maxUnavailable: 0`
* **Probes:** `readinessProbe` y `livenessProbe` configuradas
* **Recursos:** CPU y memoria limitados para evitar consumo excesivo
* **Servicio:** NodePort para acceso externo

### Base de Datos (1 réplica)

* **Imagen:** `postgres:15-alpine`
* **Persistencia:** PersistentVolumeClaim de 1Gi
* **Seguridad:** Credenciales almacenadas en Secret
* **Servicio:** ClusterIP para acceso interno únicamente

## Estructura del Proyecto

```text
tarea-techstore/
├── 01-namespace.yaml
├── 02-configmap.yaml
├── 03-secret.yaml
├── 04-db-pvc.yaml
├── 05-db-deployment.yaml
├── 06-db-service.yaml
├── 07-frontend-deployment.yaml
├── 08-frontend-service.yaml
└── README.md
```

## Instrucciones de Despliegue

### Prerrequisitos

* Minikube instalado y configurado
* kubectl instalado y configurado
* Docker instalado para Minikube

### Paso 1: Iniciar Minikube

```bash
minikube start --driver=docker
```

### Paso 2: Aplicar los Manifiestos

Aplicar los archivos en orden:

```bash
kubectl apply -f 01-namespace.yaml
kubectl apply -f 02-configmap.yaml
kubectl apply -f 03-secret.yaml
kubectl apply -f 04-db-pvc.yaml
kubectl apply -f 05-db-deployment.yaml
kubectl apply -f 06-db-service.yaml
kubectl apply -f 07-frontend-deployment.yaml
kubectl apply -f 08-frontend-service.yaml
```

También es posible aplicar todos los manifiestos de una vez:

```bash
kubectl apply -f .
```

### Paso 3: Verificar el Despliegue

```bash
kubectl get all -n techstore-app
kubectl get pods -n techstore-app
kubectl get svc -n techstore-app
kubectl get pvc -n techstore-app
```

### Paso 4: Acceder a la Aplicación

Obtener la URL del servicio:

```bash
minikube service frontend-service -n techstore-app --url
```

También se puede abrir directamente en el navegador:

```bash
minikube service frontend-service -n techstore-app
```

## Pruebas de Validación

### Prueba 1: Verificar la Topología

```bash
kubectl get all,pvc -n techstore-app
```

### Prueba 2: Autorreparación (Self-Healing)

Listar los pods:

```bash
kubectl get pods -n techstore-app
```

Eliminar un pod del frontend:

```bash
kubectl delete pod <nombre-del-pod-frontend> -n techstore-app
```

Verificar que Kubernetes cree automáticamente un nuevo pod:

```bash
kubectl get pods -n techstore-app -w
```

### Prueba 3: Escalabilidad

Escalar el frontend a 5 réplicas:

```bash
kubectl scale deployment frontend-deployment --replicas=5 -n techstore-app
```

Verificar el escalado:

```bash
kubectl get pods -n techstore-app
```

### Prueba 4: Actualización Sin Caída (Rolling Update)

Actualizar la imagen del frontend:

```bash
kubectl set image deployment/frontend-deployment nginx=nginx:1.26-alpine -n techstore-app
```

Monitorear el progreso:

```bash
kubectl rollout status deployment/frontend-deployment -n techstore-app
```

Consultar el historial:

```bash
kubectl rollout history deployment/frontend-deployment -n techstore-app
```

### Prueba 5: Persistencia de Datos

Conectarse a PostgreSQL:

```bash
kubectl exec -it <nombre-pod-postgres> -n techstore-app -- psql -U admintechstore -d techstoredb
```

Dentro de PostgreSQL:

```sql
CREATE TABLE productos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    precio DECIMAL
);

INSERT INTO productos (nombre, precio)
VALUES ('Laptop Dell', 999.99);

SELECT * FROM productos;
\q
```

Eliminar el pod de PostgreSQL:

```bash
kubectl delete pod <nombre-pod-postgres> -n techstore-app
```

Esperar a que se cree el nuevo pod y conectarse nuevamente:

```bash
kubectl exec -it <nuevo-nombre-pod-postgres> -n techstore-app -- psql -U admintechstore -d techstoredb
```

Verificar que los datos persistan:

```sql
SELECT * FROM productos;
```

## Credenciales de Base de Datos

* **Base de datos:** `techstoredb`
* **Usuario:** `admintechstore`
* **Contraseña:** `TechStore2024@!`

Las credenciales están almacenadas en un Secret de Kubernetes y codificadas en Base64.

## Comandos Útiles

Ver logs de un pod:

```bash
kubectl logs <nombre-pod> -n techstore-app
```

Consultar información detallada de un recurso:

```bash
kubectl describe pod <nombre-pod> -n techstore-app
```

Consultar los eventos del namespace:

```bash
kubectl get events -n techstore-app --sort-by='.lastTimestamp'
```

Eliminar todos los recursos del proyecto:

```bash
kubectl delete namespace techstore-app
```

## Características Técnicas Implementadas

### Alta Disponibilidad

* 3 réplicas del frontend
* Balanceo automático mediante Kubernetes
* Self-healing para recuperación automática de pods

### Zero-Downtime Deployments

* Estrategia `RollingUpdate`
* `maxUnavailable: 0`
* `maxSurge: 1`

### Health Probes

* **livenessProbe:** reinicia contenedores que no responden correctamente
* **readinessProbe:** evita enviar tráfico a pods que todavía no están listos

### Persistencia de Datos

* PersistentVolumeClaim de 1Gi
* Volumen montado en `/var/lib/postgresql/data`
* Los datos sobreviven a los reinicios de los pods

### Gobernanza de Recursos

**Frontend:**

* CPU request: `100m`
* CPU limit: `200m`
* Memoria request: `64Mi`
* Memoria limit: `128Mi`

**Database:**

* CPU request: `250m`
* CPU limit: `500m`
* Memoria request: `256Mi`
* Memoria limit: `512Mi`

### Seguridad

* Credenciales almacenadas en un Secret
* Base de datos expuesta mediante ClusterIP
* Acceso externo restringido al frontend
* Variables de entorno inyectadas desde Secret

## Autor

Proyecto desarrollado por Alexandra Quispe Chavez
