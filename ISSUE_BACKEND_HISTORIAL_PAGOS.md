# Issue: Historial de Pagos - Nombre de Cliente no se muestra

## Problema
En el historial de pagos de la aplicación móvil, algunos registros muestran **"Cliente"** como nombre en lugar del nombre real del cliente.

## Análisis Técnico

### Comportamiento Actual
- La aplicación móvil intenta obtener el nombre del cliente desde: `pago.factura.cliente.nombre`
- Cuando este valor es `null` o no existe, la app muestra "Cliente" como valor por defecto
- El número de factura sí se muestra correctamente (ej: "Factura #171", "Factura #158")
- Otros pagos SÍ muestran correctamente el nombre del cliente

### Estructura Esperada de la Respuesta
```json
{
  "id": 123,
  "monto": 920.0,
  "tipoPago": "Fisico",
  "factura": {
    "id": 171,
    "numero": "Factura #171",
    "monto": 920.0,
    "cliente": {
      "id": 45,
      "codigo": "0260-JeffersonF-122025",
      "nombre": "Jefferson Francisco Torrez Hernández",
      "telefono": "12345678"
    }
  }
}
```

### Problema Identificado
Algunos pagos en el endpoint de historial están devolviendo:
- ✅ `factura` existe
- ✅ `factura.numero` existe
- ❌ `factura.cliente` es `null` o `factura.cliente.nombre` es `null/vacío`

## Endpoint Afectado
- **Endpoint**: `GET /api/pagos` (con paginación)
- **Método**: `getPagos()` en `PagosService`

## Solución Requerida
Revisar que el endpoint de historial de pagos siempre incluya la relación `factura.cliente` con todos sus campos, especialmente:
- `cliente.id`
- `cliente.codigo`
- `cliente.nombre` (este es el campo crítico que falta)
- `cliente.telefono` (opcional)

## Casos a Verificar
1. Pagos asociados a facturas que no tienen cliente asignado (¿casos válidos o error de datos?)
2. Pagos que fueron creados sin asociar correctamente la relación factura-cliente
3. Serialización del modelo en el backend que podría estar omitiendo la relación `cliente`

## Impacto
- **Usuario**: Dificulta identificar a qué cliente pertenece cada pago
- **Funcionalidad**: La app funciona correctamente, pero muestra información incompleta
- **Prioridad**: Media (la app tiene un fallback, pero la experiencia de usuario se ve afectada)

## Notas Adicionales
- La aplicación móvil maneja correctamente el caso con un fallback a "Cliente"
- El problema está en la **consistencia de los datos** que devuelve el backend
- Se recomienda revisar también la integridad referencial en la base de datos

