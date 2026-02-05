# Análisis y Propuesta: Módulo de Gestión de Deudas y Préstamos

## 1. Objetivo
Permitir al usuario llevar un control detallado de sus deudas (dinero que debe) y préstamos (dinero que le deben). Esto incluye el seguimiento de cuotas, fechas de vencimiento, intereses y el historial de pagos, integrándolo con el flujo de caja existente.

## 2. Modelo de Datos

### 2.1. Nueva Entidad: `Debt` (Deuda/Préstamo)
Necesitamos un nuevo modelo para representar la obligación financiera.

```dart
enum DebtType {
  lending,   // Préstamo dado (Activo / Me deben)
  borrowing, // Préstamo recibido (Pasivo / Debo)
}

class Debt {
  final String id;
  final String name;             // Ej: "Préstamo Auto", "Le presté a Juan"
  final DebtType type;           // Prestar o Pedir prestado
  final double totalAmount;      // Monto original
  final double remainingAmount;  // Saldo pendiente
  final double? interestRate;    // Tasa de interés (opcional)
  final DateTime startDate;      // Fecha de inicio
  final DateTime? endDate;       // Fecha estimada de fin
  final int? totalInstallments;  // Número total de cuotas (si aplica)
  final int paidInstallments;    // Cuotas pagadas
  final String? accountId;       // Cuenta donde se depositó/salió el dinero inicial (opcional)
  final bool isArchived;         // Para ocultar deudas saldadas
  
  // Lista de amortización o pagos programados (opcional para MVP, o calculado)
  // final List<Installment> installments; 
}
```

### 2.2. Cambios en `Transaction`
Para vincular los pagos a una deuda específica, debemos agregar un campo a la transacción.

- **Campo nuevo:** `String? debtId;`
- **Lógica:** Cuando se crea una transacción con `debtId`:
  - Si es `borrowing` (Debo dinero) y es un Gasto -> Reduce la deuda.
  - Si es `lending` (Me deben) y es un Ingreso -> Reduce la deuda.

### 2.3. Cambios en `Category`
Aprovechar el `CategoryKind.debt` existente.
- Al seleccionar una categoría de tipo `debt`, la UI debería mostrar un selector de "Deuda Vinculada" (opcional).

## 3. Flujos de Usuario (User Stories)

### 3.1. Crear un Préstamo (Ej: Pido 10.000.000 Gs al Banco)
1. Usuario va a la sección "Deudas".
2. Toca "+".
3. Rellena: "Préstamo Personal", Monto: 10.000.000, Cuotas: 12, Fecha inicio: Hoy.
4. **Opción:** "¿Crear transacción inicial?"
   - Si Sí: Se crea un INGRESO de 10.000.000 en la cuenta seleccionada (ej: Banco).
   - Esto ajusta el saldo real de la cuenta.

### 3.2. Pagar una Cuota
1. **Desde la pantalla de Deudas:**
   - Usuario ve la deuda "Préstamo Personal".
   - Toca "Registrar Pago".
   - La app pre-llena una transacción de GASTO.
   - Usuario confirma monto y cuenta de origen.
   - Al guardar, la transacción se registra y el saldo de la deuda baja.

2. **Desde la pantalla de Transacciones (AddTransactionScreen):**
   - Usuario crea un Gasto.
   - Selecciona categoría "Préstamos" (tipo `debt`).
   - Aparece campo "Vincular a Deuda" (Dropdown).
   - Selecciona "Préstamo Personal".
   - Guarda.

### 3.3. Prestar Dinero (Ej: Presto 100.000 a un amigo)
1. Crear Deuda tipo `lending`.
2. Crear transacción de GASTO (sale dinero de mi bolsillo).
3. Cuando el amigo paga, registro un INGRESO vinculado a esa deuda.

## 4. Interfaz de Usuario (UI)

### 4.1. Nueva Pantalla: `DebtsScreen`
- Pestañas: "Debo" (Pasivos) y "Me Deben" (Activos).
- Lista de tarjetas con: Nombre, Barra de progreso (Pagado vs Total), Próximo vencimiento.
- FAB para crear nueva deuda.

### 4.2. Pantalla de Detalle: `DebtDetailScreen`
- Resumen grande: Saldo Restante.
- Gráfico de progreso.
- Historial de pagos (lista de transacciones vinculadas).
- Botón "Amortizar" o "Pagar Cuota".

### 4.3. Modificación en `AddTransactionScreen`
- Si la categoría seleccionada es `debt`, mostrar selector de deudas activas.

## 5. Plan de Implementación (Pasos)

1.  **Backend (Modelos y Hive):**
    - Crear `Debt` model y su Adapter de Hive.
    - Actualizar `Transaction` model y Adapter (agregar `debtId`).
    - Regenerar TypeAdapters.
    - Migrar datos existentes (si es necesario, aunque `debtId` será null por defecto).

2.  **Lógica (DataProvider):**
    - Agregar CRUD para Debts (`addDebt`, `updateDebt`, `deleteDebt`).
    - Método `getTransactionsForDebt(String debtId)`.
    - Lógica reactiva: Cuando se agrega una transacción con `debtId`, recalcular `remainingAmount` de la deuda.
      - Opcional: Recalcular al vuelo sumando transacciones vinculadas (más seguro para evitar desincronización).

3.  **UI - Pantallas:**
    - Crear `DebtsScreen`.
    - Crear `AddDebtScreen`.
    - Crear `DebtDetailScreen`.

4.  **Integración:**
    - Modificar `AddTransactionScreen` para soportar la vinculación.

5.  **Extras (Futuro):**
    - Recordatorios de vencimiento (Notificaciones).
    - Cálculo automático de intereses (Sistema Francés/Alemán).
