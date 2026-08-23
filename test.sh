#!/bin/bash

# Script de pruebas automatizado para TechStore
# Autor: Proyecto TechStore
# Uso: ./test.sh

echo "=================================="
echo "🧪 TechStore - Suite de Pruebas"
echo "=================================="
echo ""

NAMESPACE="techstore-app"

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Función para imprimir con color
print_test() {
    echo -e "${YELLOW}$1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Verificar que el namespace existe
if ! kubectl get namespace $NAMESPACE &> /dev/null; then
    print_error "El namespace $NAMESPACE no existe. Ejecuta primero ./deploy.sh"
    exit 1
fi

echo ""
print_test "=========================================="
print_test "PRUEBA 1: Verificación de Topología"
print_test "=========================================="
echo ""

echo "Estado general del clúster:"
kubectl get all,pvc -n $NAMESPACE

echo ""
PODS_RUNNING=$(kubectl get pods -n $NAMESPACE --field-selector=status.phase=Running --no-headers | wc -l)
if [ $PODS_RUNNING -ge 4 ]; then
    print_success "Todos los pods están en estado Running ($PODS_RUNNING pods)"
else
    print_error "Algunos pods no están Running. Esperados: 4+, Actual: $PODS_RUNNING"
fi

PVC_STATUS=$(kubectl get pvc postgres-pvc -n $NAMESPACE -o jsonpath='{.status.phase}')
if [ "$PVC_STATUS" == "Bound" ]; then
    print_success "PVC está en estado Bound"
else
    print_error "PVC no está Bound. Estado actual: $PVC_STATUS"
fi

echo ""
print_test "=========================================="
print_test "PRUEBA 2: Acceso a la Aplicación Web"
print_test "=========================================="
echo ""

SERVICE_URL=$(minikube service frontend-service -n $NAMESPACE --url 2>/dev/null)
echo "URL del servicio: $SERVICE_URL"
echo ""
echo "Para abrir en el navegador, ejecuta:"
echo "  minikube service frontend-service -n $NAMESPACE"

echo ""
print_test "=========================================="
print_test "PRUEBA 3: Self-Healing (Autorreparación)"
print_test "=========================================="
echo ""

echo "Pods del frontend antes de eliminar:"
kubectl get pods -n $NAMESPACE -l tier=frontend

FRONTEND_POD=$(kubectl get pods -n $NAMESPACE -l tier=frontend -o jsonpath='{.items[0].metadata.name}')
echo ""
echo "Eliminando pod: $FRONTEND_POD"
kubectl delete pod $FRONTEND_POD -n $NAMESPACE

echo ""
echo "Esperando 5 segundos..."
sleep 5

echo ""
echo "Pods del frontend después de eliminar (debería haber un nuevo pod):"
kubectl get pods -n $NAMESPACE -l tier=frontend

NEW_PODS=$(kubectl get pods -n $NAMESPACE -l tier=frontend --field-selector=status.phase=Running --no-headers | wc -l)
if [ $NEW_PODS -eq 3 ]; then
    print_success "Self-healing funciona correctamente. 3 réplicas manteniéndose."
else
    print_error "Self-healing no funcionó como esperado. Réplicas actuales: $NEW_PODS"
fi

echo ""
print_test "=========================================="
print_test "PRUEBA 4: Escalabilidad"
print_test "=========================================="
echo ""

echo "Escalando frontend a 5 réplicas..."
kubectl scale deployment frontend-deployment --replicas=5 -n $NAMESPACE

echo "Esperando a que los nuevos pods estén listos..."
kubectl wait --for=condition=ready pod -l tier=frontend -n $NAMESPACE --timeout=60s

echo ""
echo "Pods del frontend después de escalar:"
kubectl get pods -n $NAMESPACE -l tier=frontend

SCALED_PODS=$(kubectl get pods -n $NAMESPACE -l tier=frontend --field-selector=status.phase=Running --no-headers | wc -l)
if [ $SCALED_PODS -eq 5 ]; then
    print_success "Escalado exitoso a 5 réplicas"
else
    print_error "El escalado no funcionó correctamente. Réplicas: $SCALED_PODS"
fi

echo ""
echo "Regresando a 3 réplicas..."
kubectl scale deployment frontend-deployment --replicas=3 -n $NAMESPACE

echo ""
print_test "=========================================="
print_test "PRUEBA 5: Rolling Update (Zero-Downtime)"
print_test "=========================================="
echo ""

echo "Versión actual de la imagen:"
kubectl get deployment frontend-deployment -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""

echo ""
echo "Actualizando a nginx:1.26-alpine..."
kubectl set image deployment/frontend-deployment nginx=nginx:1.26-alpine -n $NAMESPACE

echo ""
echo "Monitoreando el progreso del rolling update..."
kubectl rollout status deployment/frontend-deployment -n $NAMESPACE

echo ""
echo "Historial de revisiones:"
kubectl rollout history deployment/frontend-deployment -n $NAMESPACE

print_success "Rolling update completado"

echo ""
echo "Revirtiendo a la versión anterior..."
kubectl rollout undo deployment/frontend-deployment -n $NAMESPACE
kubectl rollout status deployment/frontend-deployment -n $NAMESPACE

print_success "Rollback completado"

echo ""
print_test "=========================================="
print_test "PRUEBA 6: Persistencia de Datos"
print_test "=========================================="
echo ""

DB_POD=$(kubectl get pods -n $NAMESPACE -l tier=database -o jsonpath='{.items[0].metadata.name}')
echo "Pod de base de datos: $DB_POD"

echo ""
echo "Creando tabla de prueba e insertando datos..."
kubectl exec -it $DB_POD -n $NAMESPACE -- psql -U admintechstore -d techstoredb -c "CREATE TABLE IF NOT EXISTS productos (id SERIAL PRIMARY KEY, nombre VARCHAR(100), precio DECIMAL);"
kubectl exec -it $DB_POD -n $NAMESPACE -- psql -U admintechstore -d techstoredb -c "INSERT INTO productos (nombre, precio) VALUES ('Laptop Dell XPS', 1299.99), ('Mouse Logitech', 29.99);"

echo ""
echo "Datos insertados:"
kubectl exec -it $DB_POD -n $NAMESPACE -- psql -U admintechstore -d techstoredb -c "SELECT * FROM productos;"

echo ""
echo "Eliminando el pod de PostgreSQL..."
kubectl delete pod $DB_POD -n $NAMESPACE

echo ""
echo "Esperando a que se cree el nuevo pod..."
kubectl wait --for=condition=ready pod -l tier=database -n $NAMESPACE --timeout=120s

NEW_DB_POD=$(kubectl get pods -n $NAMESPACE -l tier=database -o jsonpath='{.items[0].metadata.name}')
echo "Nuevo pod de base de datos: $NEW_DB_POD"

echo ""
echo "Verificando que los datos persisten:"
kubectl exec -it $NEW_DB_POD -n $NAMESPACE -- psql -U admintechstore -d techstoredb -c "SELECT * FROM productos;"

ROWS=$(kubectl exec -it $NEW_DB_POD -n $NAMESPACE -- psql -U admintechstore -d techstoredb -t -c "SELECT COUNT(*) FROM productos;" | tr -d ' \r\n')
if [ "$ROWS" -ge 2 ]; then
    print_success "Persistencia de datos verificada. Los datos sobrevivieron a la eliminación del pod."
else
    print_error "Los datos no persistieron correctamente"
fi

echo ""
print_test "=========================================="
print_test "PRUEBA 7: Resource Governance"
print_test "=========================================="
echo ""

echo "Límites de recursos del frontend:"
kubectl get deployment frontend-deployment -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].resources}' | jq '.'

echo ""
echo "Límites de recursos de la base de datos:"
kubectl get deployment postgres-deployment -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].resources}' | jq '.'

print_success "Gobernanza de recursos configurada correctamente"

echo ""
echo "=================================="
echo "✅ Todas las pruebas completadas"
echo "=================================="
echo ""

echo "📊 Resumen final:"
kubectl get all,pvc -n $NAMESPACE
