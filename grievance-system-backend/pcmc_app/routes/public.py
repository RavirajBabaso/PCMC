from datetime import datetime, timezone

from flask import Blueprint, jsonify, current_app
from .. import db
from ..models import Advertisement, MasterSubjects, MasterAreas
from ..schemas import MasterSubjectsSchema, MasterAreasSchema

public_bp = Blueprint('public', __name__)

subjects_schema = MasterSubjectsSchema(many=True)
areas_schema = MasterAreasSchema(many=True)


@public_bp.route('/')
def index():
    return jsonify({"service": "PCMC Grievance System API", "status": "running"}), 200


@public_bp.route('/health')
def health():
    """Lightweight health check — used by Docker, load-balancers, and uptime monitors."""
    try:
        db.session.execute(db.text('SELECT 1'))
        db_ok = True
    except Exception:
        db_ok = False

    status = "ok" if db_ok else "degraded"
    code = 200 if db_ok else 503
    return jsonify({
        "status": status,
        "db": "ok" if db_ok else "error",
        "service": "pcmc-grievance-backend",
    }), code


@public_bp.route('/subjects', methods=['GET'])
def get_subjects():
    """Get all available grievance subjects."""
    try:
        subjects = MasterSubjects.query.all()
        return jsonify(subjects_schema.dump(subjects)), 200
    except Exception as e:
        current_app.logger.exception('Failed to fetch subjects')
        return jsonify([]), 200


@public_bp.route('/areas', methods=['GET'])
def get_areas():
    """Get all available grievance areas."""
    try:
        areas = MasterAreas.query.all()
        return jsonify(areas_schema.dump(areas)), 200
    except Exception as e:
        current_app.logger.exception('Failed to fetch areas')
        return jsonify([]), 200


@public_bp.route('/areas/<int:area_id>', methods=['GET'])
def get_area_by_id(area_id):
    """Get a single area by ID — used by frontend getMasterArea()."""
    area = db.session.get(MasterAreas, area_id)
    if not area:
        return jsonify({"error": "Area not found"}), 404
    return jsonify(MasterAreasSchema().dump(area)), 200


@public_bp.route('/advertisements', methods=['GET'])
def get_public_advertisements():
    """
    Public endpoint — returns active, non-expired advertisements.
    Used by the citizen home screen (ApiService.fetchAds).
    No authentication required.
    """
    try:
        now = datetime.now(timezone.utc)
        ads = Advertisement.query.filter(
            Advertisement.is_active == True,
            db.or_(
                Advertisement.expires_at == None,
                Advertisement.expires_at > now,
            ),
        ).order_by(Advertisement.created_at.desc()).all()
        return jsonify([ad.to_dict() for ad in ads]), 200
    except Exception as e:
        current_app.logger.exception('Failed to fetch public advertisements')
        return jsonify([]), 200
