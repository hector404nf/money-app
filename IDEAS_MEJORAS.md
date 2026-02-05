# Roadmap de Mejoras e Ideas - Money App

Este documento recopila las funcionalidades implementadas, en progreso y futuras para transformar Money App en la herramienta definitiva de control financiero personal.

## 🚀 Próximo Lanzamiento (v1.0.23)
**Estado:** ✅ Listo para pruebas

### 1. Seguridad y Privacidad
- [x] **Modo Privacidad**: Ocultar montos sensibles en el Dashboard y listas de transacciones con un solo toque (icono de ojo).
- [x] **Bloqueo Biométrico**: Protección de acceso mediante FaceID / Huella dactilar (iOS y Android).
- [x] **Persistencia**: Recordar preferencias de privacidad entre sesiones.

### 2. Gestión de Tarjetas de Crédito
- [x] **Configuración Completa**:
  - Límite de crédito.
  - Fecha de Cierre (Corte).
  - Fecha de Vencimiento (Pago).
- [x] **Visualización**:
  - Barra de progreso de uso del límite.
  - Cálculo de "Disponible" en tiempo real.
- [x] **Notificaciones Inteligentes**:
  - Alerta 2 días antes del Cierre (para controlar gastos).
  - Alerta 2 días antes del Vencimiento (para evitar intereses).

### 3. Sistema de Presupuestos (Budgeting)
- [x] **Presupuestos por Categoría**: Asignar topes de gasto mensual a cada categoría (ej. Supermercado, Ocio).
- [x] **Visualización**: Indicadores de progreso (gastado vs presupuestado) en pantalla dedicada.
- [x] **Alertas**: Notificar cuando se supera el 80% o 100% del presupuesto.

---

## 💡 Ideas a Futuro (Backlog)

### 1. Gestión de Deudas y Préstamos
- [x] **Préstamos a Terceros**: Registrar dinero prestado a amigos/familia y llevar control de pagos/amortizaciones.
- [x] **Deudas Personales**: Registrar obligaciones financieras (no bancarias) y planificar su devolución.
- [ ] **Recordatorios de Cobro/Pago**: Alertas automáticas para no olvidar cobrar o pagar deudas pendientes.

### 2. Gestión de Suscripciones
- [x] **Vista de Recurrentes**: Panel centralizado para todos los gastos fijos (Netflix, Gym, Internet, Seguros).
- [x] **Calendario de Vencimientos**: Visualización mensual de días de débito automático.
- [ ] **Alerta de Variación**: Detectar y notificar si una suscripción aumentó de precio inesperadamente.

### 3. Mejoras en Tarjetas de Crédito
- [x] **Pago de Tarjeta Simplificado**: Botón directo para registrar el pago (transferencia de Banco -> Tarjeta) con un solo clic.
- [x] **Gestión de Cuotas**: Lógica para compras en cuotas sin interés (dividir gasto automáticamente en meses futuros).
- [x] **Proyección de Cierre**: Estimar el monto final del estado de cuenta basado en gastos actuales + cuotas.

### 4. Reportes y Análisis Avanzados
- [x] **Exportación Profesional**: Generar PDFs detallados o Excel (CSV) para contabilidad personal.
- [x] **Gráficos Interactivos**: Drill-down en gráficos circulares para ver detalles de categorías.
- [x] **Comparativa Temporal**: "Gastaste un 15% menos en Comida que el mes pasado" (Tendencias).
- [x] **Análisis de Flujo de Caja**: Gráfico de Ingresos vs Gastos diarios acumulados.

### 5. Automatización e IA
- [x] **Escaneo de Facturas (OCR)**: Usar la cámara para digitalizar tickets y extraer fecha, monto e ítems.
- [x] **Reglas de Categorización Automática**: "Si la descripción contiene 'Uber', asignar a 'Transporte'".
- **Asistente Financiero Conversacional**: Mejorar la IA de voz para responder preguntas complejas ("¿Cuánto puedo gastar hoy para no salirme del presupuesto?").

### 6. Modo Viaje y Multi-moneda
- **Conversión Automática**: Actualización diaria de cotizaciones (Dólar, Real, Peso, Euro).
- **Reporte de Viaje**: Agrupación de gastos por "Evento" (ej. "Vacaciones Brasil 2026") con totales en moneda original y local.
- **Modo Offline**: Asegurar funcionalidad completa sin internet para viajeros.

### 7. Metas y Ahorro Gamificado
- **Metas Vinculadas**: Conectar una meta visual en la app con una cuenta bancaria real.
- **Retos de Ahorro**: Desafíos preconfigurados (ej. "Reto de las 52 semanas", "Ayuno de gastos hormiga").
- **Logros y Medallas**: Expandir el sistema de gamificación actual con más niveles y recompensas visuales.

### 8. Sincronización y Ecosistema
- **Backup en la Nube**: Sincronización con Google Drive / iCloud para no perder datos.
- **Soporte Multi-dispositivo**: (Largo plazo) Sincronización en tiempo real entre teléfono y tablet/web.
- **Importación Bancaria**: Lectura de notificaciones push de bancos para registrar gastos automáticamente (Android).

### 9. UX/UI y Personalización
- [x] **Temas y Apariencia**: Modo oscuro/claro automático y elección de color de acento.
- **Iconos Personalizados**: Permitir subir iconos propios o ampliar la librería.
- **Widgets de Escritorio**: Ver saldo y añadir gastos rápidos desde la pantalla de inicio del celular.

---

## 🛠 Deuda Técnica y Mantenimiento
- **Cobertura de Tests**: Alcanzar >80% de cobertura en lógica de negocio (Providers) y widgets críticos.
- **Arquitectura**: Evaluar separación de `DataProvider` en repositorios más pequeños si la app crece.
- **Internacionalización (i18n)**: Completar soporte para Inglés y Portugués (cadenas actualmente hardcoded en español).
- **Optimización**: Mejorar tiempos de carga inicial (Cold Start) y uso de memoria en listas largas.
