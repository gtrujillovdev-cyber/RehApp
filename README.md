# RehApp 

![Swift](https://img.shields.io/badge/Swift-5.10-orange.svg)
![SwiftUI](https://img.shields.io/badge/SwiftUI-Framework-blue.svg)
![Platform](https://img.shields.io/badge/Platform-iOS%2017%2B-black.svg)
![Privacy](https://img.shields.io/badge/Privacy-Local--First-green.svg)
![Tests](https://img.shields.io/badge/Tests-Unit%20%26%20Mocks-brightgreen.svg)

**RehApp** es una plataforma nativa de iOS diseñada para la rehabilitación física profesional, impulsada por IA local y centrada en la privacidad del usuario. La aplicación genera hojas de ruta de recuperación personalizadas adaptadas a la gravedad y el perfil clínico del deportista, sin enviar datos a la nube.

## 🌟 Características Principales

- **IA Local (Privacy-First)**: Procesamiento de informes médicos y síntomas directamente en el dispositivo mediante `NaturalLanguage` y modelos `CoreML`. El motor NLP ha sido ampliado para detectar +8 patologías (Codo, Espalda, Cuello, Fascia Plantar, Túnel Carpiano, etc.) y mapear sinónimos coloquiales a categorías clínicas.
- **Protocolos Clínicos Gold-Standard**: Integración de protocolos médicos estandarizados basados en la evidencia (cargados dinámicamente desde JSON), que definen fases de recuperación estacionales, objetivos clínicos y ejercicios específicos para cada patología detectada.
- **Reproductor de Ejercicios Multimedia**: Nuevo reproductor de ejecución que incluye:
  - **Contador Automático**: Repeticiones estimadas por tiempo con sistema de "ritmo de carrera".
  - **Visual Container**: Imágenes 3D centradas en alta definición para cada ejercicio.
  - **Contexto Clínico**: Visualización de descripciones técnicas e instrucciones detalladas durante la ejecución.
- **UI/UX Profesional (Apple Human Interface Guidelines)**:
  - **Densidad de Información**: Rediseño de `Dashboard` y `SessionOverview` para optimizar el espacio vertical.
  - **Safe Area Aware**: Gestión inteligente de paddings para Dynamic Island y dispositivos con notch.
  - **Glassmorphism Dinámico**: Estética premium con materiales translúcidos y bordes ultra-finos.
- **Check-in Diario de Dolor**: Ajuste dinámico de la intensidad del plan diario según el reporte de dolor del usuario.
- **Sincronización de Tema**: Cambio instantáneo de sistema Claro/Oscuro con persistencia en preferencias de usuario.

## 🛠 Arquitectura Técnica

La app sigue una arquitectura **MVVM (Model-View-ViewModel)** robusta y escalable:

- **UI**: SwiftUI con sistema de diseño adaptativo (`AppTheme`).
- **Persistencia**: SwiftData para una gestión de datos reactiva y moderna.
- **Lógica de IA**: `MedicalAnalysis` para procesamiento NLP de texto clínico y `LocalInferenceService` para generación asíncrona de planes de recuperación.
- **Servicios**: Capa de servicios desacoplada con protocolos (`LocalInferenceServiceProtocol`, `RecoveryRepositoryProtocol`, `ExerciseLibraryServiceProtocol`) que permiten inyección de dependencias y testing con mocks.
- **Concurrencia**: Uso de `Task.detached` y cancelación de tareas para evitar race conditions al cambiar de perfil.

## 📂 Estructura del Proyecto

```bash
RehApp/
├── Models/           # Modelos SwiftData (InjuryProfile, RecoveryRoadmap, Exercise, ActivityLog, Milestone...)
├── ViewModels/       # Lógica de estado (DashboardViewModel, ExercisePlayerViewModel)
├── Views/            # Componentes de UI y navegación principal
├── Services/         # Servicios desacoplados (LocalInference, ExerciseLibrary, Gamification, Health, Repository)
├── Resources/        # Assets, exercises.json y archivos de localización
└── Tests/
    └── RehAppTests/  # Tests unitarios con mocks (MockInferenceService, MockRecoveryRepository)
```

## 🧪 Testing

El proyecto incluye tests unitarios con mocks para las capas de servicio:

- `GamificationEngineServiceTests` — Validación del motor de puntos, rachas y logros.
- `SessionTimerServiceTests` — Tests del temporizador de sesiones de ejercicio.
- `DashboardViewModelTests` — Tests del ViewModel principal con mocks inyectados.
- **Mocks**: `MockInferenceService` y `MockRecoveryRepository` para testing aislado sin dependencias reales.

## 🚀 Instalación y Requisitos

1. **Xcode 15.0+**
2. **iOS 17.0+** (Requerido para SwiftData nativo)
3. Clonar el repositorio:
   ```bash
   git clone https://github.com/gtrujillovdev-cyber/RehApp.git
   ```
4. Abrir `RehApp.xcodeproj` y ejecutar en un simulador o dispositivo físico.

## 🛡 Seguridad y Privacidad

RehApp no envía datos de salud a servidores externos. Todo el análisis de informes médicos se realiza de forma local utilizando los frameworks de Apple (`NaturalLanguage`, `CoreML`), garantizando la máxima confidencialidad para el atleta.

## 🤝 Contribución

1. Crear una branch descriptiva: `feature/nombre-del-cambio` o `fix/descripcion-del-bug`
2. Usar [Conventional Commits](https://www.conventionalcommits.org/) en español
3. Asegurar que los tests pasan antes de abrir un PR

---
*Desarrollado con ❤️ para fisioterapeutas y atletas en proceso de recuperación.*
