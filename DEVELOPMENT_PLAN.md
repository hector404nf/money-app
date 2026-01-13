# Plan de Desarrollo Técnico - Money App

Este documento traduce los requisitos funcionales de `idea-app.md` a un plan de ejecución técnica para Flutter.

---

## 1. Arquitectura y Stack Tecnológico

*   **Framework**: Flutter (Dart).
*   **Plataforma Objetivo**: Android (Inicialmente), adaptable a iOS.
*   **Gestión de Estado**: `Provider` (Recomendado para MVP por su simplicidad) o `Riverpod`.
    *   *Decisión MVP*: Usaremos **Provider** (`ChangeNotifier`) para gestionar listas de Cuentas y Transacciones.
*   **Persistencia de Datos**:
    *   *Fase 1 (Prototipo)*: Datos en memoria (RAM) con datos de prueba (Mock Data).
    *   *Fase 2 (Persistencia)*: `Hive` (Base de datos NoSQL ligera y rápida) o `shared_preferences` para configuraciones simples.
*   **Navegación**: `MaterialPageRoute` estándar o `go_router` si la complejidad crece.

---

## 2. Estructura del Proyecto (`lib/`)

Organización propuesta para mantener el código limpio y escalable:

```
lib/
├── main.dart           # Punto de entrada (Configuración de temas, Providers)
├── models/             # Definición de datos (Entidades puras)
│   ├── account.dart
│   ├── category.dart
│   └── transaction.dart
├── providers/          # Lógica de negocio y Estado (State Management)
│   ├── data_provider.dart  # Gestiona la lista central de datos y cálculos
│   └── ui_provider.dart    # (Opcional) Estado de la interfaz (filtros activos, tabs)
├── screens/            # Pantallas (Vistas)
│   ├── home_screen.dart        # Contenedor principal (BottomNavigationBar)
│   ├── dashboard_tab.dart      # Vista Resumen
│   ├── accounts_tab.dart       # Vista Lista de Cuentas
│   ├── transactions_tab.dart   # Vista Historial de Movimientos
│   └── add_transaction_screen.dart # Formulario de creación/edición
├── widgets/            # Componentes reutilizables
│   ├── transaction_item.dart   # Fila de movimiento individual
│   ├── account_card.dart       # Tarjeta de resumen de cuenta
│   └── summary_card.dart       # Tarjetas del dashboard
└── utils/              # Ayudas generales
    ├── constants.dart      # Colores, estilos, textos fijos
    └── formatters.dart     # Formato de moneda (₲), fechas
```

---

## 3. Lógica de Negocio Core (El "Cerebro" del Excel)

La lógica se centralizará en `DataProvider` (o similar) para asegurar consistencia.

### A. Cálculo de Saldos por Cuenta
*   **Fórmula**: `Saldo Actual = Saldo Inicial + Suma(Movimientos de la cuenta)`
*   **Nota**: Aquí se suman TODOS los movimientos (Ingresos, Egresos y Transferencias), ya que afectan al dinero disponible.

### B. Dashboard "Gasto Real" (La clave del sistema)
*   **Ingresos**: `Suma(amount > 0)`
*   **Egresos Reales**:
    *   Filtrar movimientos donde `amount < 0`.
    *   **EXCLUIR** si `Category.isTransferLike == true`.
    *   **EXCLUIR** si `Category.isMoneyLike == true` (opcional, según regla "Mula").
*   **Resultado**: Esto evita que mover plata de "Banco" a "Billetera" parezca un gasto.

### C. Transferencias
*   No es un simple movimiento. Es una **Acción** que genera **Dos Movimientos**:
    1.  **Origen**: Egreso (Negativo) | Categoría: TRANSFER
    2.  **Destino**: Ingreso (Positivo) | Categoría: TRANSFER
*   Esto mantiene los saldos de cuentas cuadrados automáticamente.

---

## 4. Roadmap de Desarrollo por Fases

### Fase 1: Esqueleto y Modelos (Hecho / En Curso)
- [x] Crear proyecto Flutter.
- [x] Definir modelos de datos (`Account`, `Category`, `Transaction`).
- [ ] Configurar estructura de carpetas básica.

### Fase 2: UI Básica y Datos Dummy (MVP Visual)
- [ ] Implementar `DataProvider` con listas en memoria y datos de prueba.
- [ ] **Pantalla Dashboard**: Mostrar totales calculados (Ingresos vs Egresos Reales).
- [ ] **Pantalla Cuentas**: Listar cuentas con sus saldos.
- [ ] **Pantalla Movimientos**: Listado simple.

### Fase 3: Interacción y CRUD (MVP Funcional)
- [ ] **Agregar Movimiento**: Formulario para crear Ingresos/Egresos.
- [ ] **Lógica de Signos**: Auto-convertir egresos a negativo.
- [ ] **Flujo de Transferencia**: Formulario especial "De Cuenta A -> A Cuenta B".
- [ ] Actualización en tiempo real de saldos y dashboard al agregar datos.

### Fase 4: Reportes y Refinamiento
- [ ] **Reporte "Painful Truth"**: Agrupar gastos por categoría y mostrar gráfico o lista ordenada.
- [ ] **Filtros**: Filtrar movimientos por mes/año.
- [ ] **Persistencia**: Conectar `Hive` para guardar datos permanentemente.

---

## 5. Próximos Pasos Inmediatos
1.  Crear la estructura de carpetas (`providers`, `screens`, `widgets`).
2.  Implementar el `DataProvider` con datos falsos para poder diseñar la UI viendo información.
3.  Construir la UI del Dashboard para validar la lógica de cálculo "Gasto Real".
