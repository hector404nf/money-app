# Plan de Mejora UX/UI - Money App

Este documento detalla una propuesta integral para modernizar la estética y mejorar la experiencia de usuario (UX) de la aplicación.

## 1. Identidad Visual y Tema (Aesthetics)

### Paleta de Colores (Modern Financial)
Actualmente se usan colores base muy saturados. Proponemos una paleta más sofisticada y amigable a la vista:

- **Primary (Brand):** `#004D40` (Teal profundo/Esmeralda) - Transmite seguridad y estabilidad.
- **Secondary (Accent):** `#00BFA5` (Teal vibrante) - Para acciones principales (FAB, botones activos).
- **Background:** `#F5F7FA` (Gris muy suave/Azulado) - Reduce la fatiga visual comparado con el blanco puro.
- **Surface (Cards):** `#FFFFFF` (Blanco puro) - Para contenedores y tarjetas.
- **Semantic Colors:**
  - **Ingreso:** `#2E7D32` -> `#4CAF50` (Verde más suave pero legible).
  - **Gasto:** `#C62828` -> `#E53935` (Rojo moderno).
  - **Transferencia:** `#1565C0` -> `#1976D2` (Azul material).

### Tipografía
- **Fuente Principal:** `Poppins` o `Inter` para títulos y textos (moderna, sans-serif).
- **Números:** `Roboto Mono` o `Lato` para montos, asegurando alineación tabular.
- **Jerarquía:**
  - *Headlines:* Bold, color oscuro (`#263238`).
  - *Subtitles:* Medium, color gris intermedio (`#546E7A`).
  - *Body:* Regular, legible.

### Formas y Bordes
- **Radio de Borde (Border Radius):** Estandarizar a `12.0` o `16.0` para tarjetas y botones.
- **Elevación:** Sombras suaves y difusas (`BoxShadow` con opacidad baja) en lugar de elevaciones duras de Material 2.

## 2. Mejoras de Experiencia (UX)

### Dashboard (Tablero Principal)
- **Problema:** Actualmente es funcional pero puede ser plano.
- **Solución:**
  - **Tarjeta de Resumen Total:** Un "Hero Card" con gradiente suave que muestre el saldo total.
  - **Gráficos:** Implementar un gráfico de pastel (PieChart) o barras simple para visualizar gastos por categoría.
  - **Accesos Rápidos:** Botones pequeños para acciones frecuentes (ej. "Transferir", "Nuevo Gasto").

### Flujo de "Agregar Transacción"
- **Problema:** Formulario largo y vertical.
- **Solución:**
  - **Teclado Numérico Grande:** Al estilo de apps bancarias (Nubank, Revolut). Primero el monto (grande), luego los detalles.
  - **Categorías con Iconos:** Grid de iconos en lugar de solo un dropdown de texto.
  - **Selección de Fecha:** Chips de "Hoy", "Ayer" + Selector de calendario.

### Listado de Movimientos
- **Agrupación:** Agrupar transacciones por día (Sticky Headers: "Hoy", "Ayer", "12 Ene").
- **Iconografía:** Usar iconos para categorías (ej. 🍔 Comida, 🚌 Transporte) con un fondo circular de color suave.

### Navegación
- **BottomNavigationBar:** Mantenerla, pero aumentar el tamaño de los iconos seleccionados y eliminar las etiquetas si se busca un look minimalista, o usar una `NavigationBar` con `indicatorColor` personalizado.

## 3. Componentes y Feedback

- **Empty States:** Ilustraciones amigables (SVG) cuando no hay cuentas o movimientos, invitando a crear el primero.
- **Micro-interacciones:**
  - Animación al completar una carga (Check animado).
  - Feedback háptico (vibración suave) al pulsar botones importantes.
- **Modo Oscuro (Dark Mode):** Definir un tema oscuro real (Fondos `#121212`, Surface `#1E1E1E`) para uso nocturno.

## 4. Plan de Implementación (Roadmap)

1.  **Fase 1: Refactor de Tema:** Actualizar `ThemeData` en `main.dart` y `AppColors`.
2.  **Fase 2: Componentes Reusables:** Crear widgets base (`MoneyCard`, `MoneyButton`, `TransactionTile`).
3.  **Fase 3: Rediseño de Pantallas:** Aplicar el nuevo estilo pantalla por pantalla (Home -> Add -> Settings).
4.  **Fase 4: Pulido:** Animaciones y gráficos.

---
**Nota:** Este archivo sirve como guía maestra. Podemos empezar aplicando la **Fase 1** inmediatamente si estás de acuerdo.
