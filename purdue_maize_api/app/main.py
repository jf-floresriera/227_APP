from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse
from contextlib import asynccontextmanager

from app.core.config import get_settings
from app.core.database import create_tables
from app.api.v1.router import api_router

settings = get_settings()

# ── OpenAPI tag metadata ───────────────────────────────────────────────────────
tags_metadata = [
    {
        "name": "Auth",
        "description": "Registration, login (JWT), and user profile management.",
    },
    {
        "name": "Fields",
        "description": (
            "Manage agricultural fields as **GeoJSON polygons** (SRID 4326). "
            "Area in hectares is computed automatically from the geometry."
        ),
    },
    {
        "name": "Diseases",
        "description": "Read-only catalog of maize diseases (fungal, bacterial, viral).",
    },
    {
        "name": "Sampling",
        "description": (
            "Create sampling sessions (systematic / random / transect / directed) "
            "and register GPS sampling points within a field."
        ),
    },
    {
        "name": "Data Capture",
        "description": (
            "Record disease observations (incidence %, severity scale) at each "
            "sampling point, and attach image / audio evidence."
        ),
    },
    {
        "name": "Modeling",
        "description": (
            "Submit predictive-model runs (regression, random forest, LSTM) and "
            "retrieve spatially-interpolated risk maps as GeoJSON."
        ),
    },
]

APP_DESCRIPTION = """
## Purdue Maize Disease Monitor — REST API

Backend for the **Purdue Maize Disease Monitor** mobile application developed as
a Master's thesis at [Purdue University](https://www.purdue.edu) (Agronomy Dept.).

### Workflow

1. **Register / Login** → obtain a JWT Bearer token
2. **Create a Field** → upload a GeoJSON polygon of your farm parcel
3. **Start a Sampling Session** → choose a sampling scheme and date
4. **Record Observations** → add disease incidence/severity at each GPS point,
   optionally attach images or audio notes
5. **Run a Predictive Model** → get a risk-level map interpolated across the field

### Authentication

All endpoints except `POST /auth/register` and `POST /auth/token` require an
`Authorization: Bearer <token>` header.

Use the **Authorize 🔒** button (top right) to authenticate in this UI.

### Demo credentials

| Field    | Value               |
|----------|---------------------|
| Email    | `demo@purdue.edu`   |
| Password | `purdue2025`        |
"""


@asynccontextmanager
async def lifespan(app: FastAPI):
    await create_tables()
    yield


app = FastAPI(
    title="Purdue Maize Disease Monitor",
    version="0.1.0",
    description=APP_DESCRIPTION,
    contact={
        "name": "Purdue Agronomy — Maize Pathology Lab",
        "url": "https://www.purdue.edu/hla/sites/agronomy/",
        "email": "demo@purdue.edu",
    },
    license_info={
        "name": "MIT",
        "url": "https://opensource.org/licenses/MIT",
    },
    openapi_tags=tags_metadata,
    lifespan=lifespan,
    docs_url=None,    # disable default Swagger — we serve our own below
    redoc_url=None,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix=settings.API_V1_PREFIX)


# ── Health ─────────────────────────────────────────────────────────────────────

@app.get("/health", tags=["Health"], summary="Service liveness check")
async def health():
    return {"status": "ok", "service": settings.PROJECT_NAME}


# ── Scalar API Reference UI ────────────────────────────────────────────────────

_SCALAR_HTML = """<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width,initial-scale=1"/>
  <title>Purdue Maize Disease Monitor — API Docs</title>
  <style>
    :root {
      --scalar-color-1: #CFB991;
      --scalar-color-2: #DAAA00;
      --scalar-color-accent: #CFB991;
      --scalar-background-1: #1A1A1A;
      --scalar-background-2: #242424;
      --scalar-background-3: #2e2e2e;
      --scalar-border-color: #3a3a3a;
      --scalar-sidebar-background-1: #141414;
      --scalar-sidebar-color-1: #CFB991;
      --scalar-sidebar-color-active: #DAAA00;
      --scalar-button-1: #CFB991;
      --scalar-button-1-color: #1A1A1A;
    }
    body { margin: 0; }
  </style>
</head>
<body>
  <script
    id="api-reference"
    data-url="/openapi.json"
    data-configuration='{
      "theme": "kepler",
      "darkMode": true,
      "defaultHttpClient": { "targetKey": "python", "clientKey": "requests" },
      "hiddenClients": [],
      "metaData": {
        "title": "Purdue Maize Disease Monitor",
        "description": "API for maize disease monitoring — Purdue University"
      },
      "favicon": "https://www.purdue.edu/favicon.ico",
      "hideDownloadButton": false
    }'
  ></script>
  <script src="https://cdn.jsdelivr.net/npm/@scalar/api-reference"></script>
</body>
</html>"""


@app.get("/docs", include_in_schema=False)
async def scalar_docs():
    return HTMLResponse(content=_SCALAR_HTML)


# Keep classic Swagger at /swagger for fallback
@app.get("/swagger", include_in_schema=False)
async def swagger_fallback():
    from fastapi.openapi.docs import get_swagger_ui_html
    return get_swagger_ui_html(
        openapi_url="/openapi.json",
        title="Purdue Maize — Swagger UI",
    )
