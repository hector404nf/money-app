# Guía de Migración de Diseño: Money Flow Design -> Money App (Flutter)

Este documento detalla el plan paso a paso para migrar el diseño de la referencia `money-flow-design` (React/Tailwind) a `Money App` (Flutter).

## 1. Fundamentos de Diseño (Design Tokens)

### 1.1. Paleta de Colores
Los colores originales están en HSL. Aquí se definen sus equivalentes Hexadecimales para Dart/Flutter.

| Token Tailwind | HSL (Ref) | Hex (Flutter) | Variable Dart (`AppColors`) |
| :--- | :--- | :--- | :--- |
| `primary` | `174 100% 15%` | **`#004D40`** | `primary` |
| `accent` | `168 100% 37%` | **`#00BFA5`** | `secondary` |
| `background` | `216 33% 97%` | **`#F5F7FA`** | `background` |
| `card` | `0 0% 100%` | **`#FFFFFF`** | `surface` |
| `foreground` | `220 20% 20%` | **`#293241`** | `textPrimary` |
| `muted-foreground` | `220 10% 50%` | **`#737B8C`** | `textSecondary` |
| `income` | `122 39% 49%` | **`#4CAF50`** | `income` |
| `expense` | `4 82% 56%` | **`#E53935`** | `expense` |
| `transfer` | `210 79% 46%` | **`#1976D2`** | `transfer` |

### 1.2. Tipografía
*   **Fuente:** `Poppins` (Google Fonts).
*   **Pesos:**
    *   `Regular (400)`: Texto general.
    *   `Medium (500)`: Subtítulos, etiquetas.
    *   `SemiBold (600)`: Botones, énfasis.
    *   `Bold (700)`: Montos grandes, encabezados.

### 1.3. Formas y Sombras
*   **Border Radius Base:** `16.0` (`rounded-2xl` en Tailwind es usualmente 1rem/16px).
*   **Sombra Suave (`shadow-soft`):**
    *   Color: `AppColors.primary.withValues(alpha: 0.15)`
    *   Offset: `Offset(0, 4)`
    *   Blur: `20`
*   **Gradiente Primario:**
    *   `LinearGradient(colors: [AppColors.primary, AppColors.secondary], begin: Alignment.topLeft, end: Alignment.bottomRight)`

---

## 2. Plan de Implementación de Componentes

### 2.1. Hero Card (Saldo Estimado)
Referencia: `src/components/money/HeroCard.tsx`

*   **Widget:** `Container` con `BoxDecoration`.
*   **Fondo:** Gradiente lineal primario.
*   **Decoración:** Icono de `Wallet` (usar `Icons.account_balance_wallet`) posicionado absolutamente (`Stack` + `Positioned`) en la esquina superior derecha, rotado, tamaño gigante y opacidad `0.1`.
*   **Contenido:**
    *   Label "Te sobraría" (Texto pequeño, opacidad 0.9).
    *   Monto (Texto gigante, Bold, tracking tight).
    *   Footer: Separador (`Divider` blanco/20) + Indicador de pulso (animación opcional o círculo estático) + Texto "Balance estimado".

### 2.2. Dashboard Header
Referencia: `src/pages/Dashboard.tsx`

*   **Layout:** `Row` con `MainAxisAlignment.spaceBetween`.
*   **Izquierda:** `Column` [ Text("Hola,", color: gris), Text("Resumen Financiero", bold, size: 24) ].
*   **Derecha:** `MonthSelector` (Container blanco, borde gris, dropdown limpio).

### 2.3. Quick Actions
Referencia: `src/components/money/QuickActions.tsx`

*   **Layout:** `Row` horizontal con scroll o `Row` con `MainAxisAlignment.spaceEvenly` (si son pocos items).
*   **Item Widget:** `Column` [ `Container` circular (color acento suave) con Icono, Text Label ].

### 2.4. Summary Cards
Referencia: `src/components/money/SummaryCards.tsx`

*   **Layout:** `Row` con dos `Expanded`.
*   **Card:** `Container` blanco, `borderRadius: 16`, `boxShadow`.
*   **Contenido:** Icono (Flecha arriba/abajo en círculo), Label ("Ingresos"), Monto (Color verde/rojo).

### 2.5. Transaction Tile
Referencia: `src/components/money/TransactionTile.tsx`

*   **Widget:** `Container` (no `Card` de Material por defecto para controlar mejor la sombra/borde) o `ListTile` personalizado.
*   **Estilo:** Fondo blanco, `borderRadius: 16`, margen vertical pequeño.
*   **Leading:** `Container` cuadrado redondeado (squircle) o círculo, color de fondo suave según categoría, icono centrado.

---

## 3. Pasos de Ejecución

1.  **Actualizar `constants.dart`:** Definir la nueva paleta de colores exacta y estilos de sombra/gradiente.
2.  **Refactorizar `HeroCard`:** Crear un widget dedicado `HeroCard` en `lib/widgets/hero_card.dart` que replique el diseño con el icono de fondo decorativo.
3.  **Actualizar `DashboardTab`:** Reorganizar el layout para coincidir con `src/pages/Dashboard.tsx` (Header -> Hero -> Actions -> Summary -> List).
4.  **Pulido Visual:** Ajustar `ThemeData` en `main.dart` para que `Scaffold` use el nuevo color de fondo y la fuente `Poppins` por defecto.

---

**Nota:** La animación de entrada (`animate-fade-in`) se puede lograr en Flutter con `flutter_animate` o `AnimationController`, pero para la primera fase nos centraremos en la estructura estática.
