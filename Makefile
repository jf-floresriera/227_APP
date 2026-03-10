# ─────────────────────────────────────────────────────────────────────────────
# Purdue Maize Disease Monitor — Makefile
# Uso: make <comando>
# Requiere: Docker, Docker Compose, Flutter SDK
# ─────────────────────────────────────────────────────────────────────────────

.PHONY: help up down migrate seed logs api-shell flutter-web flutter-android \
        build-runner clean reset status

# ── Ayuda ─────────────────────────────────────────────────────────────────────
help:
	@echo ""
	@echo "  Purdue Maize Disease Monitor — comandos disponibles"
	@echo ""
	@echo "  Backend (Docker):"
	@echo "    make up          Levantar DB + API (detached)"
	@echo "    make down        Detener contenedores"
	@echo "    make migrate     Ejecutar migraciones Alembic"
	@echo "    make seed        Cargar datos demo en la DB"
	@echo "    make logs        Ver logs del API en tiempo real"
	@echo "    make api-shell   Abrir shell dentro del contenedor API"
	@echo "    make status      Ver estado de los contenedores"
	@echo ""
	@echo "  Flutter:"
	@echo "    make flutter-web     Correr la app en Chrome"
	@echo "    make flutter-android Correr la app en emulador/dispositivo Android"
	@echo "    make build-runner    Generar archivos .g.dart (Drift + Riverpod)"
	@echo ""
	@echo "  Utilidades:"
	@echo "    make reset       Eliminar volúmenes y volver a empezar"
	@echo "    make clean       Limpiar artefactos de build Flutter"
	@echo ""

# ── Backend ────────────────────────────────────────────────────────────────────
up:
	@echo "▶ Levantando stack..."
	docker compose up -d db
	@echo "  Esperando que PostgreSQL esté listo..."
	@sleep 4
	docker compose up -d api adminer
	@echo "✅ Stack levantado:"
	@echo "   API   →  http://localhost:8000"
	@echo "   Docs  →  http://localhost:8000/docs"
	@echo "   DB UI →  http://localhost:8080"

down:
	docker compose down

status:
	docker compose ps

logs:
	docker compose logs -f api

api-shell:
	docker compose exec api bash

migrate:
	@echo "▶ Ejecutando migraciones Alembic..."
	docker compose exec api alembic upgrade head
	@echo "✅ Migraciones aplicadas."

seed:
	@echo "▶ Cargando datos demo..."
	docker compose exec api python scripts/seed_demo.py
	@echo "✅ Datos demo cargados."

reset:
	@echo "⚠️  Eliminando volúmenes (se perderán todos los datos)..."
	docker compose down -v
	@echo "✅ Reset completo."

# ── Flutter ────────────────────────────────────────────────────────────────────
build-runner:
	@echo "▶ Generando archivos .g.dart..."
	cd purdue_maize_app && flutter pub get && \
	flutter pub run build_runner build --delete-conflicting-outputs
	@echo "✅ Generación completada."

flutter-web:
	@echo "▶ Iniciando app en Chrome..."
	@echo "   (La app apuntará a http://localhost:8000/api/v1)"
	cd purdue_maize_app && flutter run -d chrome \
	  --dart-define=API_BASE_URL=http://localhost:8000/api/v1

flutter-android:
	@echo "▶ Iniciando app en Android..."
	@echo "   (La app apuntará a http://10.0.2.2:8000/api/v1 — emulador)"
	cd purdue_maize_app && flutter run \
	  --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1

clean:
	cd purdue_maize_app && flutter clean
