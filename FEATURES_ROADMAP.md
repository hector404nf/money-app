# Roadmap de Funcionalidades Avanzadas - Money App

Este documento detalla las próximas funcionalidades propuestas para Money App y cómo implementarlas de manera incremental, alineadas con el estilo **“Modern Financial”** descrito en [APP_DESCRIPTION_FOR_UI_GEN.md](file:///c:/projects/money_app/APP_DESCRIPTION_FOR_UI_GEN.md) y el [UX_UI_IMPROVEMENT_PLAN.md](file:///c:/projects/money_app/UX_UI_IMPROVEMENT_PLAN.md).

Cada sección incluye:
- Objetivo de producto.
- Cambios técnicos necesarios (modelos, providers, UI).
- Persistencia/configuración.
- Criterios de aceptación.

---

## 1. Modo Oscuro (Dark Mode Real)

### Objetivo
Permitir al usuario alternar entre tema claro y oscuro, con una experiencia visual coherente y moderna en ambas variantes, incluyendo soporte para “usar tema del sistema”.

### Cambios Técnicos

- Crear un provider de UI (por ejemplo `UiProvider`) para gestionar:
  - `ThemeMode themeMode` (system, light, dark).
  - Posibles flags de otras preferencias (idioma, notificaciones, etc.).
- Integrar este provider en `main.dart`:
  - Añadirlo al árbol de `MultiProvider`.
  - Cambiar `MaterialApp` para usar:
    - `theme: lightTheme`.
    - `darkTheme: darkTheme`.
    - `themeMode: uiProvider.themeMode`.
- Definir dos temas en un archivo central:
  - Basados en `AppColors` de [lib/utils/constants.dart](file:///c:/projects/money_app/lib/utils/constants.dart).
  - `lightTheme`: similar al actual (background claro, surface blanco).
  - `darkTheme`:
    - `brightness: Brightness.dark`.
    - `scaffoldBackgroundColor: Color(0xFF121212)`.
    - `colorScheme` con `surface: Color(0xFF1E1E1E)` y textos claros.
    - Ajustar `AppBarTheme`, `CardTheme`, `BottomNavigationBar`, `DialogTheme`.

### UI y Flujo

- Reutilizar el ítem existente “Modo oscuro” en [lib/screens/sync_screen.dart](file:///c:/projects/money_app/lib/screens/sync_screen.dart):
  - Cambiar el switch para que consuma `UiProvider`.
  - Opcional: convertirlo en un `ListTile` con menú:
    - “Claro”, “Oscuro”, “Seguir sistema”.
- Verificar pantallas críticas:
  - Dashboard, Transacciones, Cuentas, Reportes, Detalle de transacción, Add Transaction, Settings.
  - Ajustar colores “hard-coded” (ej. `Colors.white`, `Colors.black`) para utilizar `Theme.of(context)` o `AppColors` adaptados.

### Persistencia

- Guardar preferencia de `ThemeMode` en almacenamiento local:
  - Opción rápida: `shared_preferences`.
  - Opción homogénea con el resto: Hive (ej. caja `settings`).
- Al iniciar la app, `UiProvider` lee la preferencia y la aplica.

### Criterios de Aceptación

- Cambiar el switch de modo oscuro en Ajustes altera toda la app sin reinicio manual.
- Respetar “usar tema del sistema” si está configurado.
- Ningún texto pierde contraste (WCAG mínimo razonable).
- Todas las pantallas principales se ven bien en ambos temas.

---

## 2. Presupuestos por Categoría + Alertas

### Objetivo
Permitir que el usuario establezca un presupuesto mensual por categoría (ej. “Comida: ₲1.500.000”) y reciba feedback visual cuando se acerque o supere dicho presupuesto.

### Cambios en el Modelo

- Extender `Category` en [lib/models/category.dart](file:///c:/projects/money_app/lib/models/category.dart):
  - Añadir campo opcional:
    - `double? monthlyBudget;`
  - Actualizar:
    - `toMap()` y `fromMap()` para manejar `monthlyBudget`.
    - Cualquier migración de Hive o almacenamiento existente (si aplica).

### Lógica en DataProvider

- Añadir métodos auxiliares en [lib/providers/data_provider.dart](file:///c:/projects/money_app/lib/providers/data_provider.dart):
  - Obtener gasto total por categoría para un mes determinado.
  - Calcular porcentaje de uso de presupuesto: `gasto / monthlyBudget`.
  - Detectar:
    - Categorías en alerta (>= 80% del presupuesto).
    - Categorías que superan el 100%.

### UI

- En `ManageCategoryScreen`:
  - Añadir campo para presupuesto mensual:
    - Input de monto (reutilizar `formatCurrency` de `AppColors`).
    - Opción de dejarlo vacío (sin presupuesto).
- En `ReportsScreen` (tab de Categorías) [lib/screens/reports_screen.dart](file:///c:/projects/money_app/lib/screens/reports_screen.dart):
  - Para cada categoría:
    - Mostrar barra de progreso de presupuesto si existe:
      - Color adaptado:
        - Normal (<80%): verde/teal.
        - Alerta (80–99%): amarillo/ámbar.
        - Excedido (>=100%): rojo.
    - Texto: “₲x de ₲y (zz%)”.
- Opcional:
  - En el Dashboard, un pequeño resumen:
    - “3 categorías en alerta de presupuesto”.

### Criterios de Aceptación

- El usuario puede establecer/editar presupuestos por categoría.
- El reporte de categorías muestra progreso y estados de alerta.
- Los cálculos se filtran correctamente por mes seleccionado.

---

## 3. Notificaciones y Recordatorios

### Objetivo
Enviar recordatorios locales para pagos próximos, resúmenes periódicos y otras alertas relevantes sin necesidad de backend.

### Dependencias

- Integrar `flutter_local_notifications` (o similar):
  - Configuración básica para Android.
  - Manejo de permisos según versión de Android.

### Cambios Técnicos

- Crear un servicio de notificaciones (ej. `NotificationService`):
  - Inicialización del plugin.
  - Métodos:
    - `schedulePaymentReminder(Transaction tx)`.
    - `cancelReminderForTransaction(String transactionId)`.
    - `scheduleDailySummary()` / `scheduleWeeklySummary()`.
- Integrar con `DataProvider`:
  - Al crear o editar una transacción con `dueDate` y estado pendiente:
    - Programar notificación de recordatorio (ej. 1 día antes).
  - Al marcar como pagada o eliminar:
    - Cancelar notificación asociada.

### UI en Ajustes

- Reutilizar el switch “Notificaciones” en [lib/screens/sync_screen.dart](file:///c:/projects/money_app/lib/screens/sync_screen.dart):
  - Activar/desactivar notificaciones globalmente.
- Opcional:
  - Sub-opciones:
    - Recordatorios de pagos.
    - Resumen diario/semanal.

### Criterios de Aceptación

- Si las notificaciones están activadas, las transacciones con vencimiento generan recordatorios.
- Al desactivar el switch global, se cancelan/ignoran nuevas notificaciones.
- No se requiere conexión a Internet para notificaciones locales.

---

## 4. Transacciones Recurrentes

### Objetivo
Permitir configurar movimientos que se repiten automáticamente (ej. sueldo mensual, suscripciones, alquiler).

### Cambios en el Modelo

- Extender `Transaction` en [lib/models/transaction.dart](file:///c:/projects/money_app/lib/models/transaction.dart):
  - Campos sugeridos:
    - `bool isRecurring;`
    - `RecurringFrequency? frequency;` (enum: daily, weekly, monthly, yearly).
    - `DateTime? recursUntil;` (opcional).
    - `String? parentRecurringId;` para relacionar ocurrencias.

### Lógica en DataProvider

- Añadir lógica para “generar instancias”:
  - En un método como `ensureRecurringTransactionsGenerated(DateTime now)`:
    - Revisar transacciones recurrentes “plantilla”.
    - Crear nuevas ocurrencias para periodos que aún no existan (ej. siguiente mes).
  - Momento de ejecución:
    - Al iniciar la app.
    - Al cambiar de mes en el filtro global.

### UI

- En `AddTransactionScreen`:
  - Sección “Repetir”:
    - Radio/chips: “No repetir”, “Semanal”, “Mensual”, “Anual”.
  - Fecha inicial: igual que hoy o definida por el usuario.
- En el listado / detalle:
  - Indicar si una transacción es parte de una serie recurrente.
  - Opción de editar:
    - Solo esta ocurrencia.
    - Toda la serie futura (fase avanzada).

### Criterios de Aceptación

- El usuario puede marcar una transacción como recurrente.
- Nuevas ocurrencias aparecen automáticamente en los meses siguientes.
- No se generan duplicados si la app se abre muchas veces.

---

## 5. Backup y Sincronización de Datos

### Objetivo
Evitar pérdida de datos y facilitar migrar a un nuevo dispositivo, inicialmente mediante backups manuales y, a futuro, sincronización en la nube.

### Fase 1: Backup/Restore Local (Archivo)

- Crear funciones en `CloudSyncService` o `BackupService`:
  - Exportar:
    - Leer todas las cuentas, categorías, transacciones, metas desde `DataProvider` o desde la capa de persistencia.
    - Serializar a JSON estructurado.
    - Guardar archivo en almacenamiento local y permitir compartir (compartir como archivo).
  - Importar:
    - Permitir seleccionar un archivo JSON.
    - Validar formato y versión.
    - Sobrescribir o fusionar datos (definir estrategia).

- UI en Ajustes (sección DATOS en `SyncScreen`):
  - Botón “Exportar datos”:
    - Genera archivo y abre diálogo de compartir.
  - Botón “Importar datos”:
    - Abre selector de archivo y procesa importación.

### Fase 2: Sincronización en la Nube (Opcional/Futuro)

- Decidir backend (Firebase Firestore, Supabase, etc.).
- Añadir autenticación simple (Google, email).
- Sincronizar cambios:
  - Subir cambios locales.
  - Resolver conflictos básicos (última escritura gana o estrategia más sofisticada).

### Criterios de Aceptación

- El usuario puede exportar un backup completo de sus datos.
- Puede importar un backup en un dispositivo limpio y ver sus datos restaurados.

---

## 6. Exportar a CSV / Integración con Excel

### Objetivo
Permitir que el usuario exporte las transacciones a CSV para analizarlas en Excel o Google Sheets.

### Cambios Técnicos

- Crear un helper de exportación:
  - `CsvExportService` con método:
    - `Future<File> exportTransactionsToCsv(List<Transaction> txs);`
  - Columnas sugeridas:
    - Fecha, Cuenta origen, Cuenta destino, Categoría, Monto, Tipo (Ingreso/Egreso/Transferencia), Nota, Estado.

### UI

- En Ajustes (DATOS) o en la pestaña de Transacciones:
  - Botón “Exportar a CSV”.
  - Opciones de filtro:
    - Rango de fechas.
    - Solo una cuenta, o todas.

### Criterios de Aceptación

- El archivo CSV se abre correctamente en Excel/Sheets.
- Los campos numéricos se reconocen como números.

---

## 7. Multi-moneda y Configuración Regional

### Objetivo
Soportar diferentes monedas y formateo local, manteniendo a Guaraní como valor por defecto.

### Cambios Técnicos

- Extender configuración de usuario (p.ej. en `UiProvider` o `SettingsProvider`):
  - `String currencyCode;` (ej. PYG, USD, BRL).
  - Posible `Locale` o configuración regional.
- Refactor de `AppColors.formatCurrency` en [lib/utils/constants.dart](file:///c:/projects/money_app/lib/utils/constants.dart):
  - Pasar a un `CurrencyFormatter` que reciba:
    - Monto.
    - Configuración actual de moneda.
  - Ajustar símbolo (₲, $, R$, etc.) y separadores.

### UI

- En Ajustes:
  - Opción “Moneda”:
    - Lista de monedas soportadas.
  - Mostrar ejemplo de formato al seleccionar.

### Criterios de Aceptación

- Todos los lugares donde se muestra dinero usan el mismo formateador.
- Cambiar la moneda en ajustes actualiza el formato en todas las pantallas.

---

## 8. Seguridad: PIN / Biometría

### Objetivo
Proteger el acceso a la app mediante PIN o datos biométricos (huella, FaceID donde aplique).

### Dependencias

- Integrar `local_auth` para biometría (cuando esté disponible).

### Cambios Técnicos

- Crear `SecurityService` o integrarlo en un provider de ajustes:
  - Guardar un hash del PIN (no en texto plano).
  - Comprobar PIN al inicio.
- Flujo de inicio:
  - Antes de `HomeScreen`, mostrar:
    - Pantalla de bloqueo si el PIN está activo.
    - Intento de autenticación biométrica si disponible y activada.

### UI

- Ajustes:
  - Toggle “Bloquear con PIN”.
  - Opción “Cambiar PIN”.
  - Toggle “Usar huella/biometría” (si el dispositivo lo soporta).

### Criterios de Aceptación

- Si el usuario activa PIN, la app pide PIN al abrir.
- Si activa biometría, puede entrar sin escribir PIN (cuando la biometría tenga éxito).

---

## 9. Onboarding y Ayuda en la App

### Objetivo
Ayudar a usuarios nuevos a entender rápidamente el concepto de la app (cuentas, transacciones, metas, reportes) sin necesidad de leer documentación externa.

### Componentes

- Onboarding inicial (3–4 pantallas):
  - Explicación visual de:
    - Cuentas.
    - Movimientos (gasto real vs transferencias).
    - Metas/objetivos.
    - Reportes.
- Tooltips / Coach marks:
  - Al primer uso del Dashboard:
    - Resaltar botón “Nuevo”.
    - Resaltar acceso a Reportes.

### Cambios Técnicos

- Guardar flag de “onboarding completado” en almacenamiento local.
- En `main.dart`:
  - Decidir pantalla inicial:
    - `OnboardingScreen` si es la primera vez.
    - `HomeScreen` si ya fue completado.

### Criterios de Aceptación

- Usuarios nuevos ven onboarding solo la primera vez.
- Usuarios existentes no son molestados si ya lo completaron.

---

## 10. Prioridades de Implementación

Orden recomendado para desarrollar estas funcionalidades de manera incremental:

1. Modo oscuro (Dark Mode real).
2. Presupuestos por categoría + alertas.
3. Notificaciones y transacciones recurrentes.
4. Backup/restore de datos y exportación a CSV.
5. Multi-moneda y configuración regional.
6. Seguridad (PIN/biometría).
7. Onboarding y mejoras de ayuda contextual.

Cada bloque puede abordarse como una “feature branch” independiente, con sus propias pruebas unitarias y de integración donde aplique.

