"""
notifications_routes.py

Provides GET /notifications/unread used by Flutter NotificationService.syncFromBackend().

Since there is no dedicated Notification model, this endpoint surfaces recent
active Announcements that target the caller's role (or all roles) as notification
objects.  The response shape matches what the Flutter service expects:
    [{"id": int, "title": str, "body": str}]

When a real push-notification table is added later, swap the query below.
"""
from datetime import datetime, timezone

from flask import Blueprint, jsonify
from flask_jwt_extended import get_jwt_identity

from ..models import Announcement, Role, User
from .. import db

notifications_bp = Blueprint('notifications', __name__)


@notifications_bp.route('/unread', methods=['GET'])
def get_unread_notifications():
    """
    Return unread notifications for the authenticated user.

    Auth: Bearer JWT required (attached automatically by Flutter Dio interceptor).
    The endpoint is lenient — if the token is missing or invalid it returns an
    empty list so the app degrades gracefully rather than crashing.
    """
    # Attempt to resolve the caller; fall back to empty list on any error.
    try:
        from flask_jwt_extended import verify_jwt_in_request
        verify_jwt_in_request()
        user_id = int(get_jwt_identity())
        user = db.session.get(User, user_id)
    except Exception:
        return jsonify([]), 200

    if not user:
        return jsonify([]), 200

    now = datetime.now(timezone.utc)

    try:
        # Build query: active, non-expired announcements for this user's role
        query = Announcement.query.filter(
            Announcement.is_active == True,
            db.or_(
                Announcement.expires_at == None,
                Announcement.expires_at > now,
            ),
        )

        # Admins see all; other roles see announcements targeting them or everyone
        if user.role != Role.ADMIN:
            query = query.filter(
                db.or_(
                    Announcement.target_role == None,
                    Announcement.target_role == user.role,
                )
            )

        announcements = query.order_by(Announcement.created_at.desc()).limit(20).all()

        notifications = [
            {
                "id": a.id,
                "title": a.title,
                "body": a.message,
            }
            for a in announcements
        ]
        return jsonify(notifications), 200

    except Exception:
        # Non-critical — always return a safe empty response
        return jsonify([]), 200
