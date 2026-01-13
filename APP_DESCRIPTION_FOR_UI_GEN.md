# Descripción Detallada de la Aplicación: Money App

Este documento describe la arquitectura visual, el sistema de diseño y los flujos de usuario de "Money App", una aplicación de gestión financiera personal moderna desarrollada en Flutter. Esta descripción está optimizada para ser utilizada como contexto para herramientas de generación de UI/UX o para diseñadores.

## 1. Visión General y Estilo (Aesthetics)

La aplicación sigue un estilo **"Modern Financial"**, priorizando la claridad, la limpieza visual y la facilidad de uso. Se aleja de las interfaces aburridas tradicionales mediante el uso de espacios en blanco, bordes redondeados y una tipografía moderna.

### Sistema de Diseño

*   **Tipografía:** `Poppins` (Google Fonts). Se usa para toda la interfaz, aportando un toque geométrico y amigable pero profesional.
*   **Formas:** Bordes redondeados consistentes (`BorderRadius.circular(16)` o `24`).
*   **Elevación:** Sombras suaves y difusas (`BoxShadow` con baja opacidad) en lugar de elevaciones duras, creando una sensación de profundidad sutil.
*   **Tema:** Material 3 habilitado.

### Paleta de Colores

*   **Primario (Brand):** `#004D40` (Teal Profundo). Transmite seguridad y estabilidad. Usado en encabezados, gradientes y elementos principales.
*   **Secundario (Accent):** `#00BFA5` (Teal Vibrante). Usado para llamadas a la acción (FAB) y detalles que requieren atención.
*   **Fondo (Background):** `#F5F7FA` (Gris azulado muy suave). Reduce la fatiga visual.
*   **Superficie (Surface):** `#FFFFFF` (Blanco puro). Usado en tarjetas y contenedores.
*   **Semánticos:**
    *   **Ingreso:** `#4CAF50` (Verde suave).
    *   **Gasto:** `#E53935` (Rojo moderno).
    *   **Transferencia:** `#1976D2` (Azul Material).

## 2. Pantallas Principales y Componentes

### A. Dashboard (Pantalla Principal)

El centro de control del usuario. Diseño limpio enfocado en el "Saldo Estimado".

*   **Header:**
    *   Saludo personalizado ("Hola,").
    *   Título "Resumen Financiero".
    *   **Selector de Mes:** Un dropdown estilizado (borde redondeado, fondo blanco) para filtrar la vista (ej. "Todo el historial", "2023-10").
*   **Hero Card (Saldo):**
    *   Contenedor grande con **gradiente lineal** (de `#004D40` a `#00BFA5`).
    *   Sombra difusa de color primario.
    *   Icono de billetera translúcido.
    *   Etiqueta "Te sobraría" y el monto principal en gran tamaño (blanco).
*   **Accesos Rápidos:**
    *   Fila de botones circulares o rectangulares suaves con iconos para acciones frecuentes: "Nuevo" (Agregar), "Sincronizar", "Reportes".
*   **Resumen Comparativo:**
    *   Dos tarjetas lado a lado: "Ingresos" (Icono flecha arriba, verde) vs "Gasto Real" (Icono flecha abajo, rojo).

### B. Listado de Movimientos (Transactions Tab)

Una lista detallada pero fácil de escanear de todas las transacciones.

*   **Agrupación:** Las transacciones están agrupadas por fecha.
    *   *Headers:* "HOY", "AYER", "12 ENE" (Texto gris, pequeño, espaciado).
*   **Transaction Tile (Tarjeta de Movimiento):**
    *   Fondo blanco con sombra muy sutil.
    *   **Leading:** Círculo con fondo de color suave (según categoría) e icono representativo (ej. 🍔 para Comida, 🚌 para Transporte).
    *   **Title:** Nombre de la Categoría (ej. "Comida", "Sueldo").
    *   **Subtitle:** Nota o detalle opcional (truncado si es largo).
    *   **Trailing:** Monto con color semántico (Rojo para gastos, Verde para ingresos).

### C. Agregar Transacción (Add Transaction Screen)

Una pantalla modal o completa diseñada para la entrada rápida de datos.

*   **Selector de Flujo:** `SegmentedButton` superior para cambiar entre "Gasto", "Ingreso" y "Transferencia". El color de acento cambia según la selección.
*   **Input de Monto:**
    *   Texto masivo y centrado (ej. 48pt).
    *   Enfoque automático al abrir.
    *   Prefijo de moneda ("₲").
*   **Contenedor de Detalles (Bottom Sheet style):**
    *   Fondo gris suave con bordes superiores redondeados.
    *   **Selector de Fecha:** Chips de selección rápida: "Hoy", "Ayer", "Otro" (con calendario).
    *   **Selector de Cuenta:** Dropdown limpio para elegir cuenta origen (y destino si es transferencia).
    *   **Grid de Categorías:**
        *   Iconos circulares dentro de una cuadrícula.
        *   El seleccionado se rellena con el color del flujo.
        *   Botón "+ Crear" para nuevas categorías.
    *   **Notas:** Campo de texto opcional con icono de lápiz.
    *   **Botón Guardar:** Botón ancho, coloreado según el tipo de transacción.

### D. Gestión de Cuentas (Accounts Tab)

*   Lista de tarjetas que muestran las cuentas del usuario (Efectivo, Banco, Ahorro).
*   Muestra saldo actual y saldo inicial.
*   Botón para "Agregar Nueva Cuenta".

## 3. Lógica de UI Específica

*   **Iconografía Inteligente:** La app asigna iconos automáticamente basados en palabras clave (ej. "Uber" -> Auto, "Cine" -> Película).
*   **Feedback Visual:**
    *   Validaciones de formulario en rojo.
    *   Snackbars de éxito (verde) o error (rojo) al guardar.

## 4. Tecnologías (Contexto Técnico)

*   **Framework:** Flutter.
*   **State Management:** Provider.
*   **Persistencia:** Hive (NoSQL local).
*   **Backend (Opcional):** Firebase (Auth/Sync).
*   **Paquetes Clave:** `google_fonts`, `fl_chart` (planeado), `intl`.
