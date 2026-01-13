# Guía de Implementación de Diseño (Money Flow -> Flutter)

Esta guía define las especificaciones exactas para replicar el diseño de "Money Flow" (React) en la aplicación Flutter.

## 1. Design Tokens (Fundamentos)

### 1.1 Colores (Paleta Exacta)
| Token | Hex | Uso |
| :--- | :--- | :--- |
| **Primary** | `#004D40` | Color principal de marca, textos oscuros. |
| **Secondary** | `#00BFA5` | Acentos, gradientes. |
| **Background** | `#F5F7FA` | Fondo general de las pantallas (Scaffold). |
| **Surface (Card)** | `#FFFFFF` | Tarjetas, contenedores, BottomSheet. |
| **Text Primary** | `#293241` | Títulos, cifras principales. |
| **Text Secondary** | `#737B8C` | Subtítulos, etiquetas, iconos inactivos. |
| **Income** | `#4CAF50` | Ingresos (Verde). |
| **Expense** | `#E53935` | Gastos (Rojo). |
| **Transfer** | `#1976D2` | Transferencias (Azul). |

### 1.2 Tipografía
*   **Familia:** `Poppins` (Google Fonts).
*   **Escala:**
    *   **H1 (Balance):** 36-40px Bold, Tracking Tight.
    *   **H2 (Títulos):** 24px Bold.
    *   **H3 (Subtítulos):** 18px SemiBold.
    *   **Body:** 14px Regular.
    *   **Label:** 12px Medium.

### 1.3 Sombras y Bordes
*   **Border Radius Global:** `16.0` (Equivalente a `rounded-2xl` de Tailwind).
*   **Shadow Soft:** `BoxShadow(color: Color(0x26004D40), offset: Offset(0, 4), blurRadius: 20)` (Sombra suave y difusa).
*   **Shadow Card:** `BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 2))`.

---

## 2. Componentes UI (Especificaciones)

### 2.1 Hero Card (Tarjeta de Balance)
*   **Contenedor:**
    *   `BorderRadius`: 24.0.
    *   `Gradient`: LinearGradient (`AppColors.primary` → `AppColors.secondary`, TopLeft → BottomRight).
    *   `Padding`: 24.0.
*   **Decoración:**
    *   Icono `Wallet` (Phosphor/Material) gigante.
    *   Posición: `Positioned(right: -20, top: -20)`.
    *   Tamaño: 120-150px.
    *   Opacidad: 0.1 (Blanco).
    *   Rotación: -15 grados.
*   **Contenido:**
    *   "Te sobraría" (White, Opacity 0.9).
    *   Monto (White, Bold, 40px).
    *   Footer: Divider blanco (20% opacidad) + Indicador "Pulse" (Círculo blanco 8px con animación de escala/fade) + Texto "Balance estimado".

### 2.2 Quick Actions (Botones Circulares)
*   **Layout:** Row centrado con `MainAxisAlignment.spaceEvenly` o `gap: 24`.
*   **Botón:**
    *   Forma: `CircleAvatar` o Container circular.
    *   Tamaño: 56x56.
    *   Sombra: `Shadow Soft`.
    *   Colores de Fondo:
        *   Nuevo: `AppColors.primary` (#004D40).
        *   Sincronizar: `AppColors.secondary` (#00BFA5).
        *   Reportes: `AppColors.transfer` (#1976D2).
    *   Icono: Blanco, 24px.
*   **Etiqueta:** Texto debajo del botón, 12px, `TextSecondary`, Medium.

### 2.3 Summary Cards (Ingreso/Gasto)
*   **Layout:** Grid 2 columnas (`Expanded` en Row).
*   **Tarjeta:**
    *   Fondo: Blanco (`Surface`).
    *   Radio: 16.0.
    *   Sombra: `Shadow Card`.
    *   Padding: 16.0.
*   **Estructura Interna:**
    *   Row Superior: Icono en Círculo (32px, fondo color suave `withValues(alpha: 0.1)`, icono color sólido) + Texto "Ingresos" (Gris).
    *   Texto Inferior: Monto (20px, Bold, color correspondiente: Verde/Rojo).

### 2.4 Transaction Tile (Item de Lista)
*   **Contenedor:**
    *   Fondo: Blanco.
    *   Radio: 16.0.
    *   Margin-bottom: 12.0.
    *   Sombra: `Shadow Card` (Sutil).
*   **Contenido (Row):**
    *   **Leading:** Container cuadrado (rounded 12) o circular. Fondo color categoría (suave). Icono color categoría (fuerte).
    *   **Middle:** Título (Categoría) Bold + Subtítulo (Nota/Fecha) Gris pequeño.
    *   **Trailing:** Monto (Bold, color según tipo: Rojo/Verde).

### 2.5 Pantalla "Agregar Transacción" (AddTransaction)
*   **Header:** Botón Cerrar (X) izquierda. Título "Nueva transacción" centro.
*   **Selector de Tipo (Segmented Control Personalizado):**
    *   Contenedor Padre: Fondo Blanco, `BorderRadius: 12`, Padding: 4, `BoxShadow` suave.
    *   Botones Hijos: `Expanded`.
    *   Estado Activo: Fondo Color (Rojo/Verde/Azul), Texto Blanco, `BorderRadius: 8`.
    *   Estado Inactivo: Fondo Transparente, Texto Gris.
*   **Input de Monto:**
    *   Gigante (48-56px).
    *   Centrado.
    *   Color: Coincide con el tipo seleccionado (ej. Rojo si es Gasto).
    *   Sin bordes, fondo transparente.
*   **Formulario Inferior:**
    *   Container blanco con `BorderRadius` superior (32.0).
    *   Sombra superior fuerte para separar del fondo.

---

## 3. Estructura de Navegación y Layout
*   **Dashboard Header:**
    *   Row: Columna Saludo ("Hola,") + Título ("Resumen Financiero") vs Selector de Mes (Dropdown simple con borde).
    *   Spacing: `SizedBox(height: 24)` entre secciones.
*   **Animaciones:**
    *   Entrada: `FadeInUp` (Opacidad 0->1, Offset Y 20->0) escalonada para cada sección (Hero -> Actions -> Summary -> List).

## 4. Archivos Clave a Modificar
1.  `lib/utils/constants.dart`: Actualizar paleta y estilos de sombra.
2.  `lib/widgets/hero_card.dart`: Ajustar gradiente y añadir icono decorativo.
3.  `lib/widgets/quick_action_button.dart`: Asegurar estilo circular y colores correctos.
4.  `lib/screens/add_transaction_screen.dart`: Implementar el selector de tipo estilo "Card Segmented" y el input gigante coloreado.
5.  `lib/widgets/transaction_tile.dart`: Ajustar padding y sombras.
