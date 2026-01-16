# Integración de Scrapper de Emails para Movimientos Bancarios

Este documento analiza la viabilidad de conectar Ikatu con tu correo para capturar automáticamente movimientos de tus cuentas bancarias y sincronizarlos con la app.

---

## 1. Objetivo

- Leer correos de bancos (por ejemplo, notificaciones de movimientos).
- Detectar depósitos, débitos, cargos con tarjeta, comisiones, etc.
- Convertirlos en `Transaction` dentro del modelo actual de Ikatu.
- Mantener el control 100% del usuario (opt‑in explícito, posibilidad de desactivar).

---

## 2. Nivel de Dificultad y Viabilidad

- **Técnicamente posible**: sí, pero es una funcionalidad **compleja**.
- **Factores de complejidad**:
  - Autenticación segura contra Gmail/Outlook/otros (OAuth2).
  - Formatos de correo diferentes por banco, país e idioma.
  - Reglas legales y términos de uso de los bancos y proveedores de correo.
  - Procesos en segundo plano (sin drenar batería ni violar restricciones de Android).
- **Recomendación**: abordarlo en fases, empezando por un flujo **manual / semi‑automático** y solo para **un proveedor de correo y uno o dos bancos**.

---

## 3. Opciones de Arquitectura

### 3.1. Todo en el Cliente (Solo App Flutter)

**Idea**: la app se conecta directamente al correo del usuario (por ejemplo, Gmail) usando OAuth y consume su API o IMAP.

- Pros:
  - No requiere backend propio adicional (solo Firebase, como ahora).
  - Los datos viajan directamente dispositivo ↔ proveedor de correo.
- Contras:
  - Flutter debe manejar OAuth con scopes “sensibles” (`gmail.readonly`).
  - Manejo de tokens, refresco, errores de red, límites de cuota.
  - Lógica de parsing de correos corre en el dispositivo (consume CPU/batería).

**Implementación típica**:

- Usar `google_sign_in` o similar con scope adicional para Gmail.
- Usar el token de acceso para llamar a la API de Gmail (REST).
- Leer correos filtrando por:
  - Remitente del banco.
  - Asuntos típicos (ej: “Movimiento en su cuenta”, “Compra tarjeta de crédito”).

### 3.2. Backend Intermedio (Servidor o Cloud Functions)

**Idea**: Ikatu tiene un pequeño backend (por ejemplo, en Firebase Functions o un server ligero) que se conecta al correo del usuario, procesa los emails y solo envía a la app los movimientos “limpios”.

- Pros:
  - Parsing pesado y reglas complejas viven fuera del dispositivo.
  - Más fácil actualizar reglas de scraping sin actualizar la app.
  - Puedes integrar múltiples bancos/formatos en un solo lugar.
- Contras:
  - Requiere infraestructura backend y gestión de credenciales con muchísima seguridad.
  - Responsabilidad legal mayor (tu backend toca correos de usuario).

---

## 4. Seguridad, Privacidad y Legal

- **OAuth2 obligatorio**:
  - Nunca guardar usuario/contraseña de correo.
  - Usar siempre proveedores oficiales (Gmail API, Outlook Graph, etc.).
- **Scopes mínimos**:
  - Por ejemplo, `gmail.readonly` + filtros de búsqueda.
  - Explicar claramente qué se lee y con qué fin (pantalla de permisos en la app).
- **Almacenamiento**:
  - Idealmente, no guardar el texto completo del correo.
  - Solo guardar campos ya procesados: fecha, monto, descripción, banco, tipo.
- **Términos de uso de bancos**:
  - Algunos bancos prohíben explícitamente el scraping.
  - Lo más seguro es tratar esto como herramienta personal del usuario, sin revender datos ni integrarse “oficialmente” con el banco.

---

## 5. Flujo Funcional Propuesto (MVP)

### 5.1. Configuración Inicial

1. Usuario abre una nueva sección: **“Conectar correo”**.
2. Elige proveedor: por ahora, **Gmail**.
3. Se muestra explicación clara:
   - Qué correos se leerán.
   - Qué datos se derivan (movimientos).
   - Cómo desactivar la integración.
4. Usuario autoriza con Google (OAuth2, scope de solo lectura).

### 5.2. Importación Manual

1. Botón: **“Buscar movimientos en mi correo”**.
2. La app:
   - Llama a la API de Gmail con filtros (remitentes de bancos, fecha desde X).
   - Procesa cada correo con reglas por banco:
     - Extrae monto, fecha, tipo (crédito/débito), descripción, últimos 4 dígitos de la tarjeta o cuenta.
   - Mapea esos datos a un modelo intermedio `EmailTransactionCandidate`.
3. Pantalla de revisión:
   - Lista de movimientos propuestos.
   - El usuario confirma/edita:
     - Cuenta origen en Ikatu.
     - Categoría.
     - Notas.
4. Al confirmar, se crean `Transaction` normales dentro de la app y se sincronizan con el sistema existente (Hive + CloudSyncService).

### 5.3. Sincronización Semi‑Automática

Una vez establecida la importación manual:

- Opción 1 (simple): recordar la fecha del último correo procesado y, cuando el usuario pulse el botón, solo leer emails nuevos desde esa fecha.
- Opción 2 (más avanzada): usar tareas en segundo plano en Android (`workmanager`) para revisar cada cierto tiempo, pero esto se debe hacer con cuidado por batería y restricciones del sistema.

---

## 6. Integración con el Modelo Actual de Ikatu

Ikatu ya tiene:

- Modelos `Account`, `Category`, `Transaction`.
- `DataProvider` como cerebro de cálculos.
- `CloudSyncService` para sincronizar con Firestore usando Google Sign‑In.

### 6.1. Nuevas Entidades/Clases

- `EmailConnection`:
  - proveedor (GMAIL, OUTLOOK, etc.)
  - fechaÚltimaSincronización
  - filtrosAplicados (remitentes, etiquetas)
- `EmailTransactionCandidate`:
  - idCorreo
  - fecha
  - monto
  - moneda
  - tipoMovimiento (cargo, abono, comisión)
  - descripcionCruda
  - bancoDetectado

### 6.2. Flujo de Datos

1. App obtiene emails → los convierte en `EmailTransactionCandidate`.
2. Usuario revisa/confirmar → se convierten en `Transaction`.
3. `DataProvider` actualiza cuentas, dashboard, reportes.
4. Si el usuario tiene la nube activada, `CloudSyncService` sube los nuevos movimientos.

---

## 7. Plan por Fases

### Fase 1 – Diseño y preparación

- Definir bancos objetivo (ej: Banco X, Banco Y).
- Recolectar ejemplos reales de correos de esos bancos.
- Diseñar expresiones regulares/parsers para esos formatos.

### Fase 2 – MVP Manual con Gmail

- Integrar login Gmail con scope de lectura.
- Implementar búsqueda de emails filtrados por remitente/asunto.
- Implementar parser simple para 1 banco y 1 tipo de correo (por ejemplo, movimiento de tarjeta).
- Crear pantalla de revisión y mapeo a `Transaction`.

### Fase 3 – Soporte a más bancos y tipos de correo

- Añadir reglas de parsing por banco y tipo de notificación.
- Mejorar la detección de duplicados (mismo movimiento no se importa dos veces).

### Fase 4 – Automatización y mejoras

- Soporte opcional a sincronización periódica (Android background).
- Mejoras de UX: filtros, resumen de “importado desde correo”.

---

## 8. Conclusión

- **Es posible**, pero:
  - Es una funcionalidad de alta complejidad técnica y de mantenimiento.
  - Requiere especial cuidado en **seguridad**, **privacidad** y **legalidad**.
- Recomendación:
  - Empezar pequeño: **Gmail + 1 banco + importación manual**.
  - Validar si realmente ahorra tiempo y aporta valor al usuario.
  - Solo después considerar automatización y soporte a más bancos/proveedores.

