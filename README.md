# Votaciones Congresistas

Automatización basada en n8n para extraer, procesar y servir registros de votación del Congreso (actas en PDF). El proyecto contiene flujos de trabajo n8n que:

- Extraen imágenes de PDFs subidos y recortan las áreas relevantes (ImageMagick + poppler).
- Ejecutan OCR usando el servicio ocr.space para obtener el texto superpuesto.
- Procesan el texto OCR para detectar metadatos (fecha, hora, asunto) y estructurar los votos por congresista.
- Almacenan las votaciones procesadas y los detalles de los votos en una base de datos Postgres.
- Ofrecen una interfaz por Telegram y un agente AI (LangChain + Google Gemini) que responde consultas usando la base de datos y búsquedas web.

![Estado](https://img.shields.io/badge/status-development-yellow)

## Por qué es útil este proyecto

- Automatiza la extracción OCR y el parseo de actas para construir una base de datos estructurada y consultable de votaciones.
- Combina la extracción automática con un asistente interactivo en Telegram para usuarios finales.
- Está pensado para desplegarse de forma reproducible con Docker / docker-compose.

## Características principales

- Flujos n8n:
  - `VotacionesCongresalesFeedBD` — pipeline que convierte PDF -> imágenes -> OCR -> votos estructurados -> inserción en Postgres.
  - `VotacionesCongresistasChat` — agente AI activado por Telegram que consulta Postgres y, opcionalmente, realiza búsquedas web.
- Procesamiento de imágenes con ImageMagick y poppler (instalados en la imagen Docker).
- OCR usando el servicio ocr.space (requiere clave API).
- Almacenamiento en Postgres (imagen: `postgres:15-alpine`).
- Nodo de Telegram y nodos de LangChain/AI configurados en los flujos n8n.

## Inicio rápido (desarrollador)

### Requisitos previos

- Tener instalado Docker y docker-compose.
- Disponer de una clave de API de ocr.space (para las llamadas OCR).
- Un token de bot de Telegram y las credenciales configuradas en n8n.
- Cuentas de Google PaLM/Gemini y SerpAPI.

1. Clona el repositorio

```bash
git clone <repo-url> && cd VotacionesCongresistas
```

1. Configura el entorno y los volúmenes

- Coloca los PDFs de entrada en `documentos_entrada/` (el flujo espera archivos dentro de `/documentos` en el contenedor).
- Agrega tu clave de ocr.space en la configuración del nodo del flujo (busca `TU_API_KEY` en `workflow/VotacionesCongresalesFeedBD.json`) o configúrala como credencial en n8n.
- Configura las credenciales de Telegram y otras dentro de la UI de n8n o copia los archivos de credenciales en `n8n_storage` (en este repositorio hay nodos instalados en `n8n_storage/nodes/package.json`).

1. Levanta los servicios

```bash
docker compose up --build
```

1. Aplica los permisos necesarios a la carpeta generada por n8n para evitar errores de escritura en Linux y reinicia el servicio.

```bash
sudo chown -R 1000:1000 n8n_storage
docker compose restart n8n
```

### Restauración de datos

El proyecto incluye un archivo SQL demostrativo con el registro de algunas votaciones. Inyecta este respaldo para que el agente tenga un historial que consultar de inmediato sin necesidad de procesar PDFs desde cero. Asegúrate de estar en la carpeta raíz del proyecto.

```bash
cat backup_datos.sql | docker exec -i <nombre_del_contenedor_postgres> psql -U vcBot -d congreso_db
```

### Servicios principales iniciados

- `n8n` — servidor de automatizaciones (expuesto en el puerto 5678).
- `postgres` — Postgres 15 para almacenar los datos de votaciones (puerto 5432).

## Uso básico

- Abre la interfaz web de n8n en <http://localhost:5678> para inspeccionar y activar los flujos.
- Sube un PDF a `documentos_entrada/` y ejecuta el flujo `VotacionesCongresalesFeedBD` (revisa los nodos del flujo para los nombres/paths esperados).
- Para interacción por chat, configura las credenciales del Trigger de Telegram en n8n, activa `VotacionesCongresistasChat` y chatea con el bot.

## Notas de configuración

- `dockerfile`: instala `poppler-utils` e `imagemagick` y añade `n8n-nodes-telegram-polling` en el directorio personalizado de n8n.
- `docker-compose.yml`: contiene credenciales por defecto de ejemplo para Postgres (usuario: `vcBot`, password: `vcBotPass`, bd: `congreso_db`). Cámbialas en producción y actualiza las credenciales en n8n.
- `workflow/`: los archivos JSON son exportaciones de n8n y muestran la configuración exacta de los nodos (llamadas HTTP al OCR, comandos ImageMagick, lógica JS y mapeos SQL).

## Credenciales necesarias para los flujos

Para que ambos flujos funcionen correctamente, deberás configurar las siguientes credenciales en la interfaz de n8n y asignarlas a los nodos correspondientes:

- Credenciales de Postgres: necesarias en ambos flujos para conectar los nodos de base de datos (por defecto: usuario vcBot, contraseña vcBotPass, base de datos congreso_db).
- API key de OCR.space: necesaria en el flujo de extracción (VotacionesCongresalesFeedBD) para el nodo de petición HTTP que procesa las imágenes.
- Token de Telegram: necesario en el flujo de chat (VotacionesCongresistasChat) para que el bot pueda recibir y enviar mensajes.
- API key de Google Gemini: necesaria en el flujo de chat para el modelo de lenguaje que da vida al agente AI.
- API key de SerpAPI (opcional): necesaria en el flujo de chat si deseas que el agente pueda buscar contexto adicional en internet.

## Archivos importantes

- `docker-compose.yml` — definiciones de servicios para n8n y Postgres.
- `dockerfile` — Dockerfile para construir la imagen n8n (instala ImageMagick y poppler).
- `workflow/` — flujos exportados (`VotacionesCongresalesFeedBD.json`, `VotacionesCongresistasChat.json`).

