# Diagramas de Arquitectura y Flujo de RehApp

Estos diagramas detallan la arquitectura técnica y los flujos de datos principales de la aplicación para facilitar su comprensión y mantenimiento.

## 1. Arquitectura Técnica (MVVM + SwiftData)
La aplicación utiliza una arquitectura MVVM moderna. El flujo de datos es reactivo y persistente.

```mermaid
graph TD
    subgraph View ["Capa de Vista (SwiftUI)"]
        DASH[DashboardView]
        REP[RecoveryReportView]
        PLAY[ExercisePlayerView]
    end

    subgraph ViewModel ["Capa de Lógica (ViewModels)"]
        DVM[DashboardViewModel]
        PVM[ExercisePlayerViewModel]
    end

    subgraph Services ["Servicios (Capacidad del Sistema)"]
        INF[LocalInferenceService]
        HK[HealthKitService]
        AUDIO[AudioFeedbackService]
        GAM[GamificationEngine]
    end

    subgraph Data ["Persistencia (SwiftData)"]
        SD[(Database / InjuryProfile)]
    end

    DASH <--> DVM
    PLAY <--> PVM
    DVM <--> SD
    DVM --> INF
    PVM --> HK
    PVM --> AUDIO
    PVM --> GAM
    GAM --> SD
```

---

## 2. Flujo de Generación del Plan (IA Local)
Proceso de inferencia local para transformar datos médicos en un plan de acción.

```mermaid
flowchart LR
    A[Perfil de Lesión] --> B{Motor NLP}
    B -- Análisis de Texto --> C[Detección de Gravedad]
    C --> D[Estimar Semanas]
    D --> E[Generar 4 Fases]
    E --> F[Seleccionar Ejercicios]
    F --> G[Hoja de Ruta Final]

    subgraph NLP ["Natural Language Framework"]
        B
    end
```

---

## 3. Estado de la Sesión de Ejercicio
Máquina de estados que gestiona la experiencia del usuario durante el entrenamiento.

```mermaid
stateDiagram-v2
    [*] --> Calentamiento
    Calentamiento --> Ejercicio: Inicio Bloque
    Ejercicio --> Descanso: Serie Completada
    Descanso --> Ejercicio: Serie Siguiente
    Ejercicio --> SiguienteBloque: Series Finalizadas
    SiguienteBloque --> Ejercicio: Si hay más
    SiguienteBloque --> Enfriamiento: Si es el último
    Enfriamiento --> Completado
    Completado --> Summary: Guardar Salud + Puntos
```

---

## 4. Integración de Servicios en el Entrenamiento
Interacción secuencial entre componentes durante la ejecución de ejercicios.

```mermaid
sequenceDiagram
    participant P as PlayerViewModel
    participant A as AudioService
    participant G as Gamification
    participant H as HealthKit

    P->>A: playFeedback(.exerciseStarted)
    A-->>P: "Voz: Siguiente ejercicio..."
    P->>P: Cronómetro inicia
    Note over P: Usuario hace el ejercicio
    P->>A: playFeedback(.exerciseCompleted)
    P->>G: processExerciseCompletion
    G->>G: Sumar puntos + racha
    P->>H: saveWorkout (al finalizar todo)
    H-->>P: Éxito en Apple Health
```
