# codexAI

An experimental web application for extracting data from documents using OCR. It includes an Angular interface, a Node.js/Express REST API, and OCR processing scripts built with Tesseract, ImageMagick, and Python.

## Components

- **Frontend:** Angular 19, PrimeNG, PrimeFlex, and PrimeIcons.
- **Backend:** Node.js and Express 5, with a health check and document processing endpoint.
- **OCR:** Bash/Python scripts and parameterized layouts for Venezuelan ID cards and Puerto Rico driver licenses. Passport support is partial.
- **Docker:** Nginx serves the frontend over HTTPS and routes `/api/` requests to the backend.

## Project structure

```text
.
├── backend/                 API, configuration, and OCR scripts
│   ├── controller/
│   ├── route/
│   └── ocr/
├── docker/                  Dockerfiles, Compose, Nginx, and deployment files
├── frontend/                Angular application
├── shared/                  Models, images, license, and shared resources
└── setup-workspace.sh       Workspace initialization script
```

## Requirements

For local development:

- Node.js and npm versions compatible with Angular 19.
- Angular CLI 19.
- Bash to run the OCR engine.
- Tesseract OCR with the languages required by the layouts (the main Docker image includes `spa` and `eng`).
- ImageMagick, `jq`, `awk`, and the shell tools used by the OCR scripts.
- A TLS certificate and key for the local HTTPS server or Docker deployment.

The main Docker image installs Node.js, Python, Tesseract, ImageMagick, and the Python OCR dependencies.

## Backend configuration

The backend loads environment variables from `backend/.env`. Create it from the template:

```bash
cd backend
cp .env.sample .env
```

On Windows PowerShell:

```powershell
Copy-Item .env.sample .env
```

Variables in `.env.sample`:

| Variable | Purpose | Default |
|---|---|---|
| `DEBUG_MODE` | When `true`, retains temporary files and increases log detail. | `false` |
| `BACKEND_HTTP_PORT` | Backend HTTP port. | `8080` |
| `BACKEND_HTTPS_PORT` | Backend HTTPS port. | `8443` |
| `BACKEND_SSL_CERTIFICATE` | Certificate path; relative paths resolve from `backend/`. | `../shared/assets/ssl/mbonet.xyz.crt` |
| `BACKEND_SSL_CERTIFICATE_KEY` | TLS key path; relative paths resolve from `backend/`. | `../shared/assets/ssl/mbonet.xyz.key` |
| `OCR_DOCUMENT_PICTURE_UPLOAD_DIRECTORY` | Temporary directory for uploaded images. | `../shared/uploads` |
| `OCR_DOCUMENT_PICTURE_MAX_FILE_SIZE_IN_MB` | Maximum image size, in MB. | `5` |
| `OCR_SIMULATION_MODE` | Uses the simulation script instead of real OCR. | `false` |

The backend also reads `BACKEND_TIME_IN_SECONDS_FOR_GRACEFUL_SHUTDOWN` (10 seconds by default), though it is not listed in the template. `SUPPORTED_LOCALES`, `DEFAULT_LOCALE`, `DOMAIN`, `WEBMASTEREMAILADDRESS`, and `ERRORREPORTINGEMAILADDRESS` appear in the template but are not used by the current configuration.

**Important:** on startup, the backend deletes files already present directly in the configured upload directory. Use a dedicated directory for temporary files.

## Local development

Install dependencies:

```bash
cd backend
npm ci
cd ../frontend
npm ci
```

In one terminal, start the backend:

```bash
cd backend
npm run dev
```

In another terminal, start Angular:

```bash
cd frontend
npm start
```

Angular's development configuration uses HTTPS on port 443 and the host `codexai.mbonet.xyz`, and expects certificates under `shared/assets/ssl/`. Adjust the host, certificates, and backend URL in `frontend/src/environments/environment.ts` for your environment. The backend HTTPS server defaults to port 8443. To simulate OCR, set `OCR_SIMULATION_MODE=true` in `backend/.env`. The simulation returns dummy data and may produce a simulated error.

Available commands:

| Directory | Command | Action |
|---|---|---|
| `backend` | `npm start` | Runs the backend |
| `backend` | `npm run dev` | Runs the backend with nodemon |
| `frontend` | `npm start` | Starts the Angular development server |
| `frontend` | `npm run build` | Builds Angular for production |
| `frontend` | `npm test` | Runs Angular tests |

The backend test script is a placeholder and exits with an error because backend tests have not been configured.

## API

The API uses the `/api` prefix.

- `GET /api/ping`: checks whether the backend is running.
- `POST /api/ocr`: accepts an image and the `documentLayout` field, runs OCR with the requested layout, and returns the result as JSON.

See `backend/route/validator/` for validation rules and `backend/ocr/layouts/` for the available layouts. Middleware limits the uploaded file type and size.

## Docker Compose

`docker/docker-compose.yml` runs the published `marcb76/tec-codexai:1.0` image; it does not build the image locally. It publishes:

- `https://localhost/` on port 443 (Nginx and the frontend).
- Port 8443 for the backend HTTPS server.
- Local persistent volumes `docker/uploads/` and `docker/logs/`.

The container sets its hostname to `codexai.mbonet.xyz`. Run Compose with:

```bash
cd docker
docker compose up -d
docker compose logs -f tec-ocr
docker compose down
```

Docker Engine and the Docker Compose plugin are required. The TLS certificate and hostname must match your environment.

### Building the image

The Dockerfile expects its build context to contain `backend/`, `frontend/browser/`, `backend.env`, `nginx/`, and `ssl/ssl.crt` and `ssl/ssl.key` under `docker/`. The `docker/buildDockerImage.sh` script stages these files from the rest of the workspace and publishes the image.

Review that script before using it: it deletes and recopies directories under `docker/`, handles private certificates, and contains a Docker registry credential hard-coded in the file. Revoke that credential and replace it with a secure method, such as environment variables or interactive `docker login`, before running the script. Do not store private keys or credentials in the repository.

## License

`shared/assets/license.txt` describes the software as proprietary to Marc Bonet. Review it before using, modifying, or distributing the project.
