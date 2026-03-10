"""Initial schema: users, fields, sampling, diseases, observations, modeling

Revision ID: 0001
Revises:
Create Date: 2025-01-01 00:00:00.000000
"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
import geoalchemy2

revision: str = "0001"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Enable PostGIS extension
    op.execute("CREATE EXTENSION IF NOT EXISTS postgis")

    # ── users ──────────────────────────────────────────────────────────────────
    op.create_table(
        "users",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("email", sa.String(), nullable=False),
        sa.Column("full_name", sa.String(), nullable=False),
        sa.Column("hashed_password", sa.String(), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default="true"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.text("now()")),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("email"),
    )
    op.create_index("ix_users_email", "users", ["email"])

    # ── fields ─────────────────────────────────────────────────────────────────
    op.create_table(
        "fields",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("crop", sa.String(100), nullable=False, server_default="maize"),
        sa.Column("owner_id", sa.String(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column(
            "geometry",
            geoalchemy2.types.Geometry(geometry_type="POLYGON", srid=4326),
            nullable=False,
        ),
        sa.Column("area_ha", sa.Numeric(10, 4), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.text("now()")),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.text("now()")),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_fields_owner", "fields", ["owner_id"])

    # ── diseases ───────────────────────────────────────────────────────────────
    op.create_table(
        "diseases",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("name", sa.String(200), nullable=False),
        sa.Column("common_name", sa.String(200), nullable=True),
        sa.Column("pathogen", sa.String(300), nullable=True),
        sa.Column("pathogen_type", sa.String(50), nullable=True),
        sa.Column("crop", sa.String(100), nullable=False, server_default="maize"),
        sa.Column("description", sa.Text(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("name"),
    )

    # Seed maize diseases catalog
    op.bulk_insert(
        sa.table(
            "diseases",
            sa.column("name", sa.String),
            sa.column("common_name", sa.String),
            sa.column("pathogen", sa.String),
            sa.column("pathogen_type", sa.String),
            sa.column("crop", sa.String),
        ),
        [
            {"name": "Northern Corn Leaf Blight", "common_name": "Tizón foliar norte", "pathogen": "Exserohilum turcicum", "pathogen_type": "fungal", "crop": "maize"},
            {"name": "Gray Leaf Spot", "common_name": "Mancha gris", "pathogen": "Cercospora zeae-maydis", "pathogen_type": "fungal", "crop": "maize"},
            {"name": "Common Rust", "common_name": "Roya común", "pathogen": "Puccinia sorghi", "pathogen_type": "fungal", "crop": "maize"},
            {"name": "Southern Corn Leaf Blight", "common_name": "Tizón foliar sur", "pathogen": "Cochliobolus heterostrophus", "pathogen_type": "fungal", "crop": "maize"},
            {"name": "Tar Spot", "common_name": "Mancha de alquitrán", "pathogen": "Phyllachora maydis", "pathogen_type": "fungal", "crop": "maize"},
            {"name": "Goss's Wilt", "common_name": "Marchitez de Goss", "pathogen": "Clavibacter michiganensis", "pathogen_type": "bacterial", "crop": "maize"},
            {"name": "Corn Lethal Necrosis", "common_name": "Necrosis letal", "pathogen": "MCMV + SCMV", "pathogen_type": "viral", "crop": "maize"},
        ],
    )

    # ── sampling_sessions ──────────────────────────────────────────────────────
    op.create_table(
        "sampling_sessions",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("field_id", sa.String(), sa.ForeignKey("fields.id"), nullable=False),
        sa.Column("created_by", sa.String(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("sampling_type", sa.String(50), nullable=False),
        sa.Column("session_date", sa.Date(), nullable=False),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.text("now()")),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_sessions_field", "sampling_sessions", ["field_id"])

    # ── sampling_points ────────────────────────────────────────────────────────
    op.create_table(
        "sampling_points",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("session_id", sa.String(), sa.ForeignKey("sampling_sessions.id", ondelete="CASCADE"), nullable=False),
        sa.Column("point_code", sa.String(50), nullable=True),
        sa.Column(
            "location",
            geoalchemy2.types.Geometry(geometry_type="POINT", srid=4326),
            nullable=False,
        ),
        sa.Column("altitude_m", sa.Numeric(8, 2), nullable=True),
        sa.Column("sync_status", sa.String(20), nullable=False, server_default="synced"),
        sa.Column("recorded_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.text("now()")),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_points_session", "sampling_points", ["session_id"])

    # ── observations ───────────────────────────────────────────────────────────
    op.create_table(
        "observations",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("sampling_point_id", sa.String(), sa.ForeignKey("sampling_points.id", ondelete="CASCADE"), nullable=False),
        sa.Column("disease_id", sa.Integer(), sa.ForeignKey("diseases.id"), nullable=False),
        sa.Column("incidence_pct", sa.Numeric(5, 2), nullable=True),
        sa.Column("severity_value", sa.Numeric(5, 2), nullable=True),
        sa.Column("severity_scale", sa.String(20), nullable=True),
        sa.Column("cultivar", sa.String(200), nullable=True),
        sa.Column("phenological_stage", sa.String(100), nullable=True),
        sa.Column("planting_date", sa.String(50), nullable=True),
        sa.Column("irrigation", sa.Boolean(), nullable=True),
        sa.Column("fungicide_applied", sa.Boolean(), nullable=True),
        sa.Column("fertilization_notes", sa.Text(), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("observed_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("sync_status", sa.String(20), nullable=False, server_default="synced"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.text("now()")),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_obs_point", "observations", ["sampling_point_id"])
    op.create_index("ix_obs_disease", "observations", ["disease_id"])

    # ── media_files ────────────────────────────────────────────────────────────
    op.create_table(
        "media_files",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("observation_id", sa.String(), sa.ForeignKey("observations.id", ondelete="CASCADE"), nullable=False),
        sa.Column("media_type", sa.String(10), nullable=False),
        sa.Column("original_filename", sa.String(500), nullable=True),
        sa.Column("file_path", sa.String(1000), nullable=False),
        sa.Column("file_size_bytes", sa.Integer(), nullable=True),
        sa.Column("duration_seconds", sa.Numeric(8, 2), nullable=True),
        sa.Column("mime_type", sa.String(100), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.text("now()")),
        sa.PrimaryKeyConstraint("id"),
    )

    # ── model_runs ─────────────────────────────────────────────────────────────
    op.create_table(
        "model_runs",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("field_id", sa.String(), sa.ForeignKey("fields.id"), nullable=False),
        sa.Column("disease_id", sa.Integer(), sa.ForeignKey("diseases.id"), nullable=False),
        sa.Column("created_by", sa.String(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("model_type", sa.String(100), nullable=False),
        sa.Column("prediction_horizon_days", sa.Integer(), nullable=False, server_default="14"),
        sa.Column("parameters", sa.JSON(), nullable=True),
        sa.Column("status", sa.String(20), nullable=False, server_default="pending"),
        sa.Column("error_message", sa.Text(), nullable=True),
        sa.Column("metrics", sa.JSON(), nullable=True),
        sa.Column("started_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.text("now()")),
        sa.PrimaryKeyConstraint("id"),
    )

    # ── model_results ──────────────────────────────────────────────────────────
    op.create_table(
        "model_results",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("run_id", sa.String(), sa.ForeignKey("model_runs.id", ondelete="CASCADE"), nullable=False),
        sa.Column("result_date", sa.Date(), nullable=False),
        sa.Column(
            "location",
            geoalchemy2.types.Geometry(geometry_type="POINT", srid=4326),
            nullable=True,
        ),
        sa.Column("risk_level", sa.String(20), nullable=True),
        sa.Column("predicted_incidence_pct", sa.Numeric(5, 2), nullable=True),
        sa.Column("predicted_severity_value", sa.Numeric(5, 2), nullable=True),
        sa.Column("confidence", sa.Numeric(5, 4), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_results_run_date", "model_results", ["run_id", "result_date"])


def downgrade() -> None:
    op.drop_table("model_results")
    op.drop_table("model_runs")
    op.drop_table("media_files")
    op.drop_table("observations")
    op.drop_table("sampling_points")
    op.drop_table("sampling_sessions")
    op.drop_table("diseases")
    op.drop_table("fields")
    op.drop_table("users")
    op.execute("DROP EXTENSION IF EXISTS postgis")
