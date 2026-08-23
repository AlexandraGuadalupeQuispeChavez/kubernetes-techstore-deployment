# 🚀 Proyecto TechStore - Despliegue en Kubernetes

## 📋 Descripción del Proyecto

Este proyecto implementa una solución de alta disponibilidad para TechStore, una tienda virtual de comercio electrónico, utilizando Kubernetes (Minikube) para resolver problemas críticos de:

- ✅ Escalabilidad ante tráfico masivo
- ✅ Despliegues sin tiempo de inactividad (Zero-Downtime)
- ✅ Persistencia de datos garantizada
- ✅ Gobernanza de recursos de cómputo

## 🏗️ Arquitectura Implementada

La solución consta de una arquitectura multi-capa con los siguientes componentes:

### Frontend (3 réplicas)
- **Imagen:** nginx:1.25-alpine
- **Estrategia:** RollingUpdate con maxUnavailable: 0
- **Probes:** readinessProbe y livenessProbe configuradas
- **Recursos:** CPU y memoria limitados para evitar consumo excesivo
- **Servicio:** NodePort para acceso externo

### Base de Datos (1 réplica)
- **Imagen:** postgres:15-alpine
- **Persistencia:** PersistentVolumeClaim de 1Gi
- **Seguridad:** Credenciales almacenadas en Secret
- **Servicio:** ClusterIP para acceso interno únicamente

## 📦 Estructura del Proyecto

```
tarea-techstore/
├── 01-namespace.yaml              # Namespace techstore-app
├── 02-configmap.yaml             # Variables de configuración y HTML
├── 03-secret.yaml                # Credenciales de base de datos
├── 04-db-pvc.yaml                # Solicitud de volumen persistente
├── 05-db-deployment.yaml         # Despliegue de PostgreSQL
├── 06-db-service.yaml            # Servicio interno para DB
├── 07-frontend-deployment.yaml   # Despliegue de NGINX
├── 08-frontend-service.yaml      # Servicio NodePort para frontend
└── README.md                     # Este archivo
```

## 🚀 Instrucciones de Despliegue

### Prerrequisitos

- Minikube instalado y configurado
- kubectl instalado y configurado
- Docker instalado (para Minikube)

### Paso 1: Iniciar Minikube

```bash
minikube start --driver=docker
```

### Paso 2: Aplicar los Manifiestos en Orden

```bash
# 1. Crear el namespace
kubectl apply -f 01-namespace.yaml

# 2. Crear la configuración
kubectl apply -f 02-configmap.yaml

# 3. Crear las credenciales
kubectl apply -f 03-secret.yaml

# 4. Crear el almacenamiento persistente
kubectl apply -f 04-db-pvc.yaml

# 5. Desplegar la base de datos
kubectl apply -f 05-db-deployment.yaml

# 6. Crear el servicio de base de datos
kubectl apply -f 06-db-service.yaml

# 7. Desplegar el frontend
kubectl apply -f 07-frontend-deployment.yaml

# 8. Exponer el frontend
kubectl apply -f 08-frontend-service.yaml
```

**O aplicar todos de una vez:**

```bash
kubectl apply -f .
```

### Paso 3: Verificar el Despliegue

```bash
# Ver todos los recursos
kubectl get all -n techstore-app

# Ver los pods
kubectl get pods -n techstore-app

# Ver los servicios
kubectl get svc -n techstore-app

# Ver el PVC
kubectl get pvc -n techstore-app
```

### Paso 4: Acceder a la Aplicación

```bash
# Obtener la URL del servicio
minikube service frontend-service -n techstore-app --url

# O abrir directamente en el navegador
minikube service frontend-service -n techstore-app
```

## 🧪 Pruebas de Validación

### Prueba 1: Verificar la Topología

```bash
kubectl get all,pvc -n techstore-app
```

### Prueba 2: Autorreparación (Self-Healing)

```bash
# Listar los pods
kubectl get pods -n techstore-app

# Eliminar un pod del frontend
kubectl delete pod <nombre-del-pod-frontend> -n techstore-app

# Verificar que se crea uno nuevo automáticamente
kubectl get pods -n techstore-app -w
```

### Prueba 3: Escalabilidad

```bash
# Escalar a 5 réplicas
kubectl scale deployment frontend-deployment --replicas=5 -n techstore-app

# Verificar el escalado
kubectl get pods -n techstore-app
```

### Prueba 4: Actualización Sin Caída (Rolling Update)

```bash
# Actualizar la imagen
kubectl set image deployment/frontend-deployment nginx=nginx:1.26-alpine -n techstore-app

# Monitorear el progreso
kubectl rollout status deployment/frontend-deployment -n techstore-app

# Ver el historial
kubectl rollout history deployment/frontend-deployment -n techstore-app
```

### Prueba 5: Persistencia de Datos

```bash
# Conectarse a PostgreSQL
kubectl exec -it <nombre-pod-postgres> -n techstore-app -- psql -U admintechstore -d techstoredb

# Dentro de PostgreSQL, crear una tabla y datos
CREATE TABLE productos (id SERIAL PRIMARY KEY, nombre VARCHAR(100), precio DECIMAL);
INSERT INTO productos (nombre, precio) VALUES ('Laptop Dell', 999.99);
SELECT * FROM productos;
\q

# Eliminar el pod de PostgreSQL
kubectl delete pod <nombre-pod-postgres> -n techstore-app

# Esperar a que se cree el nuevo pod y conectarse nuevamente
kubectl exec -it <nuevo-nombre-pod-postgres> -n techstore-app -- psql -U admintechstore -d techstoredb

# Verificar que los datos persisten
SELECT * FROM productos;
```

## 🔒 Credenciales de Base de Datos

- **Base de datos:** techstoredb
- **Usuario:** admintechstore
- **Contraseña:** TechStore2024@!

*Nota: Las credenciales están codificadas en base64 dentro del Secret.*

## 🛠️ Comandos Útiles

```bash
# Ver logs de un pod
kubectl logs <nombre-pod> -n techstore-app

# Descripción detallada de un recurso
kubectl describe pod <nombre-pod> -n techstore-app

# Obtener los eventos del namespace
kubectl get events -n techstore-app --sort-by='.lastTimestamp'

# Eliminar todos los recursos
kubectl delete namespace techstore-app
```

## 📊 Características Técnicas Implementadas

### ✅ Alta Disponibilidad
- 3 réplicas del frontend con balanceo automático
- Self-healing: Kubernetes recrea automáticamente pods fallidos

### ✅ Zero-Downtime Deployments
- Estrategia RollingUpdate configurada
- maxUnavailable: 0 (siempre hay pods disponibles)
- maxSurge: 1 (solo 1 pod extra durante actualización)

### ✅ Health Probes
- **livenessProbe:** Reinicia contenedores que no responden
- **readinessProbe:** Evita enviar tráfico a pods no listos

### ✅ Persistencia de Datos
- PersistentVolumeClaim de 1Gi
- Montado en /var/lib/postgresql/data
- Los datos sobreviven a reinicios de pods

### ✅ Gobernanza de Recursos
- **Frontend:** 100m CPU (request), 200m CPU (limit)
- **Frontend:** 64Mi RAM (request), 128Mi RAM (limit)
- **Database:** 250m CPU (request), 500m CPU (limit)
- **Database:** 256Mi RAM (request), 512Mi RAM (limit)

### ✅ Seguridad
- Credenciales en Secret (codificadas en base64)
- Base de datos con acceso ClusterIP (solo interno)
- Variables de entorno inyectadas desde Secret

## 👨‍🎓 Autor

Proyecto desarrollado para la asignatura **Orquestadores y Automatización de Software** del IESTP Valle Grande.

## 📝 Licencia

Este proyecto es de uso académico.
