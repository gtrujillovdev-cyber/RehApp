# CLAUDE.md Global — Configuración de desarrollo

## Sobre mí

Soy estudiante de desarrollo. Estoy aprendiendo, así que necesito entender lo que haces.

## Comportamiento

- SIEMPRE explica el porqué de cada decisión técnica, no solo el qué
- Cuando escribas o modifiques código, añade un breve comentario con el razonamiento detrás de patrones, estructuras de datos o decisiones de diseño no obvias
- Si hay varias formas de resolver algo, menciona las alternativas brevemente y por qué eliges una
- Cuando uses un concepto avanzado (genéricos, protocolos, decoradores, patrones de diseño...), explica qué es y por qué se aplica aquí
- Si detectas un error conceptual en lo que te pido, corrígeme antes de implementar
- No simplifiques el código por encima de lo que sería profesional — enséñame buenas prácticas reales

## Lenguajes y stack

Trabajo principalmente con:

- **Swift** — Apps iOS/macOS (SwiftUI, UIKit). Prioridad principal
- **Java** — Backend y proyectos académicos (Spring Boot cuando aplique)
- **Python** — Scripts, automatización, prototipado rápido

Convenciones por lenguaje:

- Swift: Swift API Design Guidelines, naming descriptivo en inglés, structs sobre classes cuando sea posible
- Java: Convenciones estándar de Oracle, POJOs claros, inyección de dependencias cuando sea apropiado
- Python: PEP 8, type hints siempre, docstrings en funciones públicas

## Git

- Crear una branch por feature: `feature/nombre-descriptivo`
- Bugfixes: `fix/descripcion-del-bug`
- Commits en español siguiendo Conventional Commits:
  - `feat: añadir pantalla de login`
  - `fix: corregir crash al rotar dispositivo`
  - `refactor: extraer lógica de red a servicio`
  - `docs: actualizar README con instrucciones de instalación`
  - `test: añadir tests unitarios para UserService`
- Commits atómicos: un commit por cambio lógico, no commits gigantes
- IMPORTANTE: nunca hagas commit directamente a `main`

## Estilo de código

- Comentarios en español para explicaciones, nombres de variables y funciones en inglés
- Preferir código legible sobre código clever/inteligente
- Funciones cortas con responsabilidad única
- Nombrar las cosas de forma descriptiva — evitar abreviaciones crípticas
- Manejar errores explícitamente, nunca silenciar excepciones

## Testing

- Escribe tests cuando crees funcionalidad nueva no trivial
- Explícame la estrategia de testing: qué testeas y por qué
- Nombrar tests descriptivamente: `test_usuario_sin_email_lanza_error()`

## Cuando no sepas algo

Si una pregunta está fuera de tu conocimiento o no estás seguro, dilo claramente. Prefiero un "no estoy seguro" honesto a una respuesta incorrecta que me haga aprender algo mal.
