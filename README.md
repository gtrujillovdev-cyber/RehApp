# RehApp 

![Swift](https://img.shields.io/badge/Swift-5.10-orange.svg)
![SwiftUI](https://img.shields.io/badge/SwiftUI-Framework-blue.svg)
![Platform](https://img.shields.io/badge/Platform-iOS%2017%2B-black.svg)
![Privacy](https://img.shields.io/badge/Privacy-Local--First-green.svg)

**RehApp** es una plataforma nativa de iOS diseñada para la rehabilitación física profesional, impulsada por IA local y centrada en la privacidad del usuario. La aplicación permite generar hojas de ruta de recuperación personalizadas de 12 semanas basadas en el perfil clínico del deportista.

## 🌟 Características Principales

- **IA Local (Privacy-First)**: Procesamiento de informes médicos y síntomas directamente en el dispositivo mediante `NaturalLanguage` y modelos de inferencia locales.
- **Hoja de Ruta de 12 Semanas**: Planificación dinámica dividida en 4 fases clínicas (Control, Activación, Carga y Rendimiento).
- **Motor de Ejercicios Inteligente**: Generación de hasta 5 ejercicios técnicos por sesión con variabilidad y progresión mecánica.
- **Dashboard de Rendimiento**: Seguimiento de "Recovery Score", rachas diarias y gráficos de actividad semanal.
- **Integración con Apple Health**: Sincronización de entrenamientos y quema calórica mediante `HealthKit`.
- **Diseño Premium**: Interfaz moderna con soporte completo para Modo Claro/Oscuro y estética "Glassmorphism".

## 🛠 Arquitectura Técnica

La app sigue una arquitectura **MVVM (Model-View-ViewModel)** robusta y escalable:

- **UI**: SwiftUI con sistema de diseño adaptativo (`AppTheme`).
- **Persistencia**: SwiftData para una gestión de datos reactiva y moderna.
- **Lógica de IA**: `MedicalAnalysis` para procesamiento de texto y `LocalInferenceService` para generación de planes.
- **Servicios**: Capa de servicios desacoplada para Gamificación, Salud y Feedback de Audio.

## 📂 Estructura del Proyecto

```bash
RehApp/
├── Models/           # Modelos de SwiftData (InjuryProfile, Roadmap, Exercise...)
├── ViewModels/       # Lógica de estado y comportamiento de las vistas
├── Views/            # Componentes de UI y navegación principal
├── Services/         # Servicios de infraestructura (Health, AI, Repository)
└── Resources/        # Assets y archivos de localización
```

## 🚀 Instalación y Requisitos

1. **Xcode 15.0+**
2. **iOS 17.0+** (Requerido para SwiftData nativo)
3. Clonar el repositorio:
   ```bash
   git clone https://github.com/gtrujillovdev-cyber/RehApp.git
   ```
4. Abrir `RehApp.xcodeproj` y ejecutar en un simulador o dispositivo físico.

## 🛡 Seguridad y Privacidad

RehApp no envía datos de salud a servidores externos. Todo el análisis de informes médicos se realiza de forma local utilizando los frameworks de Apple, garantizando la máxima confidencialidad para el atleta.

---
*Desarrollado con ❤️ para fisioterapeutas y atletas en proceso de recuperación.*
