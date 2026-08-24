# 🎥 GUION COMPLETO PARA VIDEO DE SUSTENTACIÓN

**Duración Total:** 5-8 minutos  
**Requisito:** Cámara encendida durante todo el video

---

## 🎬 MINUTO 0:00 - 1:00 | PRESENTACIÓN PERSONAL

### 📹 QUÉ MOSTRAR EN PANTALLA:
- Tu repositorio de GitHub abierto en el navegador

### 🗣️ QUÉ DECIR:

> "Buenas tardes, mi nombre es **[TU NOMBRE COMPLETO]**, estudiante del IESTP Valle Grande de la asignatura de Orquestadores y Automatización de Software.
>
> El día de hoy voy a sustentar mi proyecto de despliegue en Kubernetes para TechStore, una tienda virtual de comercio electrónico.
>
> Como pueden ver en pantalla, este es mi repositorio de GitHub que ya fue compartido con el profesor Jean Carlos Simon. El repositorio contiene los 8 manifiestos YAML necesarios para implementar la solución completa."

### 📋 MOSTRAR EN PANTALLA:
- Navega rápidamente por los archivos del repo mostrando:
  - 01-namespace.yaml
  - 02-configmap.yaml
  - ... (scroll rápido)
  - 08-frontend-service.yaml
  - README.md

---

## 🎬 MINUTO 1:00 - 2:30 | EXPLICACIÓN DE MANIFIESTOS CLAVE

### 📹 QUÉ MOSTRAR EN PANTALLA:
- Abre VS Code o tu editor con los archivos YAML

### 🗣️ QUÉ DECIR:

> "Voy a explicar brevemente las decisiones técnicas más importantes que tomé:
>
> **Primero, el ConfigMap** [ABRIR 02-configmap.yaml]:  
> Aquí almacené las variables de configuración pública como el nombre de la tienda, la moneda y el entorno. También incluí el archivo index.html completo que será servido por NGINX.
>
> **Segundo, el Secret** [ABRIR 03-secret.yaml]:  
> Aquí guardé las credenciales de PostgreSQL codificadas en base64 por seguridad: el nombre de la base de datos, el usuario administrador y la contraseña.
>
> **Tercero, el PersistentVolumeClaim** [ABRIR 04-db-pvc.yaml]:  
> Solicité 1 Gigabyte de almacenamiento persistente con modo ReadWriteOnce para garantizar que los datos de PostgreSQL sobrevivan a reinicios de pods.
>
> **Cuarto, el Deployment del Frontend** [ABRIR 07-frontend-deployment.yaml]:  
> Configuré 3 réplicas para alta disponibilidad. Lo más importante aquí es la estrategia RollingUpdate con maxUnavailable en cero, lo que garantiza que nunca haya caídas durante actualizaciones.
>
> También configuré readinessProbe y livenessProbe para que Kubernetes solo envíe tráfico a pods que estén realmente listos.
>
> Y por último, definí requests y limits de CPU y memoria para controlar el consumo de recursos."

---

## 🎬 MINUTO 2:30 - 5:30 | DEMOSTRACIÓN PRÁCTICA EN TERMINAL

### 📹 QUÉ MOSTRAR EN PANTALLA:
- Terminal abierta en pantalla completa
- **IMPORTANTE:** Ejecuta los comandos EN VIVO

### 🗣️ PARTE 1: VERIFICACIÓN DEL CLÚSTER

> "Ahora voy a demostrar que mi solución está funcionando correctamente. Primero voy a verificar el estado de todos los recursos:"

```bash
kubectl get all,pvc -n techstore-app
```

**🗣️ COMENTARIO:**
> "Como pueden ver, tengo 3 pods del frontend corriendo, 1 pod de PostgreSQL, los dos servicios activos y el PVC en estado Bound, lo que significa que el almacenamiento persistente está correctamente asignado."

---

### 🗣️ PARTE 2: ACCESO AL PORTAL WEB

```bash
minikube service frontend-service -n techstore-app --url
```

**🗣️ COMENTARIO:**
> "Este comando me devuelve la URL para acceder al servicio. Voy a copiar esta dirección y abrirla en el navegador..."

**📹 ACCIÓN:**
- Copia la URL
- Abre el navegador
- Pega la URL
- Muestra la página cargando con "TechStore - Catálogo Oficial v1.0.0"

**🗣️ COMENTARIO:**
> "Perfecto, aquí está el portal web funcionando correctamente con el HTML personalizado que incluí en el ConfigMap."

---

### 🗣️ PARTE 3: AUTORREPARACIÓN (SELF-HEALING)

> "Ahora voy a demostrar la capacidad de autorreparación de Kubernetes. Primero listo los pods del frontend:"

```bash
kubectl get pods -n techstore-app -l tier=frontend
```

**🗣️ COMENTARIO:**
> "Aquí tengo los 3 pods corriendo. Voy a eliminar uno manualmente para simular un fallo:"

```bash
kubectl delete pod [NOMBRE-DEL-PRIMER-POD] -n techstore-app
```

**⚡ INMEDIATAMENTE EJECUTA:**
```bash
kubectl get pods -n techstore-app -l tier=frontend -w
```

**🗣️ COMENTARIO:**
> "Como pueden ver en tiempo real, Kubernetes detectó inmediatamente que falta un pod y ya está creando uno nuevo. En pocos segundos tendremos nuevamente 3 réplicas corriendo. Esto es el self-healing automático."

**Espera 5-10 segundos y presiona Ctrl+C para detener el watch**

---

### 🗣️ PARTE 4: PERSISTENCIA DE DATOS

> "Ahora voy a demostrar la persistencia de datos. Primero me voy a conectar a PostgreSQL:"

```bash
kubectl get pods -n techstore-app -l tier=database
```

**🗣️ COMENTARIO:**
> "Aquí está el pod de PostgreSQL. Voy a conectarme:"

```bash
kubectl exec -it [NOMBRE-POD-POSTGRES] -n techstore-app -- psql -U admintechstore -d techstoredb
```

**DENTRO DE POSTGRESQL, EJECUTA:**
```sql
CREATE TABLE productos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    precio DECIMAL
);

INSERT INTO productos (nombre, precio) VALUES ('Laptop Dell', 999.99);
INSERT INTO productos (nombre, precio) VALUES ('Mouse Logitech', 29.99);

SELECT * FROM productos;
```

**🗣️ COMENTARIO:**
> "Perfecto, creé una tabla y dos registros. Ahora salgo de la base de datos y voy a eliminar el pod completo:"

```sql
\q
```

```bash
kubectl delete pod [NOMBRE-POD-POSTGRES] -n techstore-app
```

**🗣️ COMENTARIO:**
> "El pod se está eliminando. Voy a esperar a que Kubernetes cree el nuevo pod:"

```bash
kubectl get pods -n techstore-app -l tier=database -w
```

**Espera hasta que el nuevo pod esté en Running, presiona Ctrl+C**

**🗣️ COMENTARIO:**
> "Ahora voy a conectarme al NUEVO pod y verificar si los datos siguen ahí:"

```bash
kubectl exec -it [NUEVO-NOMBRE-POD-POSTGRES] -n techstore-app -- psql -U admintechstore -d techstoredb -c "SELECT * FROM productos;"
```

**🗣️ COMENTARIO:**
> "Como pueden ver, los datos persisten! Los productos que creé en el pod anterior siguen presentes en el nuevo pod. Esto es gracias al PersistentVolumeClaim que mantiene los datos independientes del ciclo de vida de los pods."

---

## 🎬 MINUTO 5:30 - 7:30 | RESPUESTAS A LAS 4 PREGUNTAS

### 📹 QUÉ MOSTRAR:
- Puedes volver a mostrar tu cara en pantalla completa o mantener el editor visible

### 🗣️ PREGUNTA 1: SELF-HEALING

> "**Primera pregunta:** ¿Qué ocurrió cuando eliminé el pod y por qué Kubernetes levantó uno nuevo inmediatamente?
>
> Cuando eliminé el pod, el **ReplicaSet** detectó que el número de réplicas actual era menor al deseado. El ReplicaSet es el responsable de mantener el número correcto de réplicas corriendo en todo momento.
>
> La diferencia clave es que el **Deployment** define el estado deseado de alto nivel (quiero 3 réplicas con esta imagen y configuración), mientras que el **ReplicaSet** es el controlador de bajo nivel que ejecuta y monitorea constantemente ese estado. Si detecta una desviación, actúa inmediatamente para corregirla creando o eliminando pods."

---

### 🗣️ PREGUNTA 2: ROLLING UPDATE Y PROBES

> "**Segunda pregunta:** ¿Cómo trabajan RollingUpdate y readinessProbe para evitar errores 502/503 durante actualizaciones?
>
> La estrategia **RollingUpdate** con maxUnavailable en cero garantiza que Kubernetes nunca destruya un pod viejo hasta que el nuevo esté listo.
>
> Aquí entra el **readinessProbe**: este probe hace peticiones HTTP al contenedor para verificar que realmente esté respondiendo correctamente. Solo cuando el readinessProbe confirma que el nuevo pod está healthy, Kubernetes lo añade al Service y recién entonces elimina un pod viejo.
>
> De esta manera, siempre hay pods disponibles recibiendo tráfico y los usuarios nunca ven errores 502 o 503."

---

### 🗣️ PREGUNTA 3: PERSISTENCIA Y PVC

> "**Tercera pregunta:** ¿Por qué los datos no se perdieron al destruir el pod?
>
> Esto es gracias a la arquitectura de almacenamiento de Kubernetes. El **PersistentVolumeClaim** solicita almacenamiento al clúster, y este almacenamiento tiene un ciclo de vida independiente de los pods.
>
> Cuando el pod de PostgreSQL se crea, monta el PVC en el directorio `/var/lib/postgresql/data`, que es donde PostgreSQL guarda físicamente las bases de datos.
>
> Cuando eliminé el pod, el volumen persistente no se destruyó. Cuando Kubernetes creó el nuevo pod, simplemente montó el mismo volumen, y PostgreSQL encontró todos sus archivos de datos intactos. Por eso los datos persisten."

---

### 🗣️ PREGUNTA 4: GOBERNANZA DE RECURSOS

> "**Cuarta pregunta:** ¿Por qué es mala práctica no definir requests y limits?
>
> Sin **requests**, Kubernetes no sabe cuántos recursos necesita un contenedor, lo que puede causar que programe múltiples pods en un nodo que no tiene capacidad suficiente.
>
> Sin **limits**, un contenedor con un memory leak puede consumir toda la RAM del nodo, causando que el sistema operativo empiece a matar procesos aleatoriamente, incluyendo otros pods críticos o incluso componentes del propio Kubernetes.
>
> Con requests y limits bien definidos, Kubernetes puede distribuir mejor la carga, y si un contenedor excede su limit de memoria, solo ese contenedor se reinicia sin afectar a los demás."

---

## 🎬 MINUTO 7:30 - 8:00 | CIERRE

### 🗣️ QUÉ DECIR:

> "Para finalizar, esta solución resolvió los 4 problemas críticos de TechStore:
>
> 1. El colapso por tráfico masivo se resolvió con 3 réplicas balanceadas
> 2. Los cortes en despliegues se eliminaron con RollingUpdate
> 3. La pérdida de datos se previno con PersistentVolumeClaim
> 4. Y la falta de control se solucionó con gobernanza de recursos
>
> Todos los manifiestos, el código y la documentación completa están en mi repositorio de GitHub que compartí con el profesor.
>
> Muchas gracias por su atención."

---

## ✅ CHECKLIST ANTES DE GRABAR

- [ ] Minikube está corriendo y todos los pods están en Running
- [ ] Tienes el repositorio de GitHub abierto en el navegador
- [ ] Tienes VS Code o editor con los YAMLs listos
- [ ] Tienes una terminal limpia abierta
- [ ] Tu cámara funciona correctamente
- [ ] Probaste el audio del micrófono
- [ ] Cerraste notificaciones y aplicaciones de fondo
- [ ] Tienes los comandos listos para copiar/pegar si es necesario

---

## 📝 COMANDOS RÁPIDOS DE REFERENCIA

```bash
# Ver todos los recursos
kubectl get all,pvc -n techstore-app

# URL del servicio
minikube service frontend-service -n techstore-app --url

# Ver pods del frontend
kubectl get pods -n techstore-app -l tier=frontend

# Eliminar un pod (reemplaza NOMBRE)
kubectl delete pod NOMBRE-DEL-POD -n techstore-app

# Watch pods en tiempo real
kubectl get pods -n techstore-app -w

# Ver pod de database
kubectl get pods -n techstore-app -l tier=database

# Conectarse a PostgreSQL (reemplaza NOMBRE)
kubectl exec -it NOMBRE-POD-POSTGRES -n techstore-app -- psql -U admintechstore -d techstoredb

# Consulta SQL directa desde terminal
kubectl exec -it NOMBRE-POD-POSTGRES -n techstore-app -- psql -U admintechstore -d techstoredb -c "SELECT * FROM productos;"
```

---

## 🎯 TIPS PARA UNA BUENA GRABACIÓN

1. **Habla claro y pausado** - No te apures
2. **Mira a la cámara** - Establece conexión visual
3. **Si te equivocas**, pausa y edita después (no reinicies todo)
4. **Ten agua cerca** - Para evitar carraspeos
5. **Practica antes** - Haz una grabación de prueba
6. **Revisa el tiempo** - Usa un cronómetro visible

---

**¡ÉXITO EN TU SUSTENTACIÓN! 🚀**
