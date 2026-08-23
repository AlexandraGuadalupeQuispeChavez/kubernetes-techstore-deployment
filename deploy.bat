@echo off
REM Script de despliegue automatizado para TechStore en Kubernetes (Windows)
REM Autor: Proyecto TechStore
REM Uso: deploy.bat

echo ==================================
echo 🚀 TechStore - Despliegue Automatizado
echo ==================================
echo.

REM Verificar que kubectl esté instalado
kubectl version --client >nul 2>&1
if errorlevel 1 (
    echo ❌ Error: kubectl no está instalado
    echo Por favor, instala kubectl antes de continuar
    pause
    exit /b 1
)

echo ✅ kubectl encontrado
echo.

echo 📦 Aplicando manifiestos...
echo.

echo 1/8 Creando namespace...
kubectl apply -f 01-namespace.yaml

echo 2/8 Creando ConfigMap...
kubectl apply -f 02-configmap.yaml

echo 3/8 Creando Secret...
kubectl apply -f 03-secret.yaml

echo 4/8 Creando PersistentVolumeClaim...
kubectl apply -f 04-db-pvc.yaml

echo 5/8 Desplegando base de datos PostgreSQL...
kubectl apply -f 05-db-deployment.yaml

echo 6/8 Creando servicio de base de datos...
kubectl apply -f 06-db-service.yaml

echo 7/8 Desplegando frontend NGINX...
kubectl apply -f 07-frontend-deployment.yaml

echo 8/8 Creando servicio frontend...
kubectl apply -f 08-frontend-service.yaml

echo.
echo ✅ Todos los manifiestos aplicados correctamente
echo.

echo ⏳ Esperando a que los pods estén listos...
timeout /t 15 /nobreak >nul

echo.
echo ==================================
echo ✅ Despliegue completado
echo ==================================
echo.

echo 📊 Estado actual del clúster:
echo.
kubectl get all,pvc -n techstore-app

echo.
echo 🌐 Para acceder a la aplicación web, ejecuta:
echo    minikube service frontend-service -n techstore-app
echo.
echo 📝 Comandos útiles:
echo    Ver logs:        kubectl logs -f deployment/frontend-deployment -n techstore-app
echo    Ver eventos:     kubectl get events -n techstore-app --sort-by=.lastTimestamp
echo    Escalar:         kubectl scale deployment frontend-deployment --replicas=5 -n techstore-app
echo.

pause
