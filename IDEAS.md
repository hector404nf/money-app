# 🚀 Propuestas de Innovación para Money App (Ikatu)

Este documento detalla ideas para nuevas funcionalidades enfocadas en aumentar la retención de usuarios, aportar valor real y modernizar la aplicación.

## 🤖 1. Inteligencia Artificial y Automatización (GRATIS / On-Device)
*El futuro de las finanzas personales es que la app trabaje por ti, sin costos recurrentes.*

*   **Ingreso por Lenguaje Natural (NLP) con Google ML Kit (On-Device):** (✅ Prototipo Implementado)
    *   *Estrategia Gratuita:* Combinar **Reconocimiento de Voz Nativo** (Speech-to-Text del OS) + **Google ML Kit Entity Extraction**.
    *   *Funcionamiento (Audio):* El usuario dicta: "Gasté 50.000 en Superseis". El sistema nativo del celular (Android/iOS) convierte el audio a texto GRATIS. Luego, ese texto pasa a ML Kit para extraer `Money: 50000` y `PaymentMethod`.
    *   *Valor:* Carga por voz rápida y sin conexión, sin pagar APIs de transcripción como Whisper.
*   **Detector de Anomalías (Estadística Local):**
    *   *Estrategia Gratuita:* No se necesita una IA generativa. Se usa **Estadística Descriptiva** (Math local).
    *   *Funcionamiento:* La app calcula tu "promedio histórico" de gastos en comida. Si el gasto actual supera ese promedio + 20% (desviación estándar), lanza la alerta. Es pura matemática que corre en el teléfono.
    *   *Valor:* Alertas inteligentes a costo cero.
*   **Predicción de Saldos (Regresión Lineal):**
    *   *Estrategia Gratuita:* Algoritmo de **Regresión Lineal** simple.
    *   *Funcionamiento:* Si gastaste 10.000 el día 1, 20.000 el día 2... la app traza una línea recta matemática para predecir cuánto tendrás el día 30.
    *   *Valor:* Previsión financiera real sin servidores externos.

## 🎮 2. Gamificación (Hacerlo Divertido)
*Convertir el ahorro en un juego.*

*   **Logros e Insignias:**
    *   *Ejemplos:* "Racha de 7 días registrando gastos", "Presupuesto Maestro" (no pasarse en un mes), "Cero Deudas".
    *   *Valor:* Refuerzo positivo.
*   **Modo "Ahorro Forzado" (Retos):**
    *   *Idea:* Retos predefinidos como "Semana sin gastos hormiga" o "Reto de las 52 semanas".
    *   *Valor:* Educación financiera práctica.

## 📊 3. Salud Financiera y Herramientas
*Más allá de solo registrar gastos.*

*   **Gestor de Suscripciones:**
    *   *Idea:* Una vista dedicada a Netflix, Spotify, Gym, etc., con alertas 2 días antes del cobro.
    *   *Valor:* Evitar pagos olvidados de servicios que no se usan.
*   **Calculadora de "Bola de Nieve" (Deudas):**
    *   *Idea:* Si el usuario tiene deudas, sugerirle en qué orden pagarlas para salir más rápido de ellas.
    *   *Valor:* Asesoramiento financiero real.
*   **Simulador de Compras:**
    *   *Idea:* "¿Puedo comprarme el nuevo iPhone?" -> La app analiza tus ahorros y flujo de caja y te dice "Sí, pero te quedarás corto para el alquiler" o "Mejor espera 2 meses".

## 📱 4. Experiencia de Usuario (UX) Visual
*Que la app se sienta moderna y fluida.*

*   **Vista de Calendario:** (✅ Implementado)
    *   *Idea:* Ver los gastos en un calendario mensual. Los días con muchos gastos en rojo, días "limpios" en verde.
    *   *Valor:* Visualización rápida de patrones de gasto.
*   **Modo "Viaje" / Multimoneda:**
    *   *Idea:* Crear un "Evento" (ej. Vacaciones Brasil). La app permite registrar en Reales/Dólares y convierte a Guaraníes automáticamente al tipo de cambio del día.
    *   *Valor:* Indispensable para usuarios que viajan.
*   **Widgets de Pantalla de Inicio:**
    *   *Idea:* Botón rápido "+ Gasto" o visualización de "Presupuesto Restante" sin abrir la app.
    *   *Valor:* Accesibilidad inmediata.

## 🤝 5. Funciones Sociales / Compartidas
*   **Presupuesto en Pareja / Compartido:**
    *   *Idea:* Cuentas o categorías compartidas donde dos usuarios pueden agregar gastos (ej. "Gastos de la Casa").
    *   *Valor:* Muy solicitado por parejas y familias.

---
**Recomendación de Prioridad (MVP):**
1.  **Gestor de Suscripciones** (Fácil de implementar, alto valor).
2.  **Vista de Calendario** (Visualmente impactante).
3.  **Ingreso Rápido/NLP** (Mejora la usabilidad diaria).
