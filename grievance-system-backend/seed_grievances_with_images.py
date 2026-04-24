from pathlib import Path
import shutil
from datetime import datetime, timezone

from pcmc_app import create_app, db
from pcmc_app.models import (
    User, Role,
    MasterAreas, MasterCategories, MasterSubjects,
    Grievance, GrievanceAttachment,
    AuditLog, GrievanceStatus, Priority
)

IMAGE_SOURCE_DIR = Path(r"C:\Users\ravir\Downloads\images")
CITIZEN_EMAIL = "citizen@example.com"
CITIZEN_PASSWORD = "Test@1234"

DATA = [
    {
        "title": "Garbage not collected regularly",
        "description": "Garbage has not been collected in our area for the past 3 days, causing bad smell and hygiene issues.",
        "category": "Sanitation",
        "subject": "Area Cleaning / Garbage lifting",
        "area": "Wakad",
        "image": "garbasge.jpg",
    },
    {
        "title": "Street light not working",
        "description": "The street light near my house is not functioning, making the area unsafe at night.",
        "category": "Electricity",
        "subject": "Street lights",
        "area": "Pimple-Saudagar",
        "image": "sritlight not working.jpg",
    },
    {
        "title": "Drainage blockage issue",
        "description": "The drainage system is blocked and dirty water is overflowing onto the road.",
        "category": "Sanitation",
        "subject": "Drainage blockage",
        "area": "Nigdi-Prdhikaran",
        "image": "dranage blockage issue.jpg",
    },
    {
        "title": "Low water pressure problem",
        "description": "Water supply pressure is very low, making it difficult to store sufficient water.",
        "category": "Water Supply",
        "subject": "Low Water Pressure",
        "area": "Ravet",
        "image": "low water pressure problem.jpg",
    },
    {
        "title": "Road damaged with cracks",
        "description": "The road has developed multiple cracks and is becoming difficult for vehicles to pass.",
        "category": "Infrastructure",
        "subject": "Road repairing",
        "area": "Bhosari",
        "image": "rode damaged with carekcs.jpg",
    },
    {
        "title": "Irregular garbage vehicle service",
        "description": "Garbage collection vehicle does not come regularly in our area.",
        "category": "Sanitation",
        "subject": "Garbage vehicle not arrived",
        "area": "Moshi",
        "image": "irregulaer garbage vehical service.jpg",
    },
    {
        "title": "Tree branches blocking road",
        "description": "Overgrown tree branches are blocking the road and causing inconvenience to vehicles.",
        "category": "Infrastructure",
        "subject": "Tree Cutting",
        "area": "Thergaon",
        "image": "Tree branches blocking road.jpg",
    },
    {
        "title": "Water leakage from pipeline",
        "description": "There is continuous water leakage from the pipeline, wasting water and damaging the road.",
        "category": "Water Supply",
        "subject": "Pipeline Leakage",
        "area": "Chikhali",
        "image": "Water leakage from pipeline.jpg",
    },
    {
        "title": "Stray dogs creating disturbance",
        "description": "There are many stray dogs in the area creating noise and safety concerns.",
        "category": "Health",
        "subject": "Birth Control for Stray Dogs",
        "area": "Kalewadi-Rahatani",
        "image": "Stray dogs creating disturbance.jpg",
    },
    {
        "title": "Public toilet not clean",
        "description": "The public toilet is not maintained properly and needs immediate cleaning.",
        "category": "Sanitation",
        "subject": "Cleaning of Public Toilets",
        "area": "Pimpri-Camp",
        "image": "Public toilet not clean.jpg",
    },
]


def get_or_create_citizen():
    user = User.query.filter_by(email=CITIZEN_EMAIL).first()
    if user:
        user.role = Role.CITIZEN
        user.is_active = True
        user.set_password(CITIZEN_PASSWORD)
        return user

    user = User(
        name="Test Citizen",
        email=CITIZEN_EMAIL,
        role=Role.CITIZEN,
        is_active=True,
    )
    user.set_password(CITIZEN_PASSWORD)
    db.session.add(user)
    db.session.flush()
    return user


def get_or_create_category(name):
    category = MasterCategories.query.filter_by(name=name).first()
    if not category:
        category = MasterCategories(name=name, description=f"{name} related complaints")
        db.session.add(category)
        db.session.flush()
    return category


def get_or_create_area(name):
    area = MasterAreas.query.filter_by(name=name).first()
    if not area:
        area = MasterAreas(name=name, description=name)
        db.session.add(area)
        db.session.flush()
    return area


def get_or_create_subject(description, category_id):
    subject = MasterSubjects.query.filter_by(description=description).first()
    if not subject:
        subject = MasterSubjects(
            name=description,
            description=description,
            category_id=category_id,
            is_active=True,
        )
        db.session.add(subject)
        db.session.flush()
    else:
        subject.category_id = category_id
    return subject


def copy_attachment(image_name, grievance_id, upload_root):
    source = IMAGE_SOURCE_DIR / image_name
    if not source.exists():
        print(f"⚠️ Missing image skipped: {source}")
        return None

    target_dir = upload_root / str(grievance_id)
    target_dir.mkdir(parents=True, exist_ok=True)

    safe_name = source.name.replace("\\", "_").replace("/", "_")
    target = target_dir / safe_name
    shutil.copy2(source, target)

    return GrievanceAttachment(
        grievance_id=grievance_id,
        file_path=f"{grievance_id}/{safe_name}",
        file_type=source.suffix.lower().replace(".", "") or "jpg",
        file_size=target.stat().st_size,
        uploaded_at=datetime.now(timezone.utc),
    )


def seed():
    app = create_app()

    with app.app_context():
        upload_root = Path(app.config.get("UPLOAD_FOLDER", "uploads"))
        upload_root.mkdir(parents=True, exist_ok=True)

        citizen = get_or_create_citizen()

        created = 0
        updated = 0

        for item in DATA:
            category = get_or_create_category(item["category"])
            area = get_or_create_area(item["area"])
            subject = get_or_create_subject(item["subject"], category.id)

            grievance = Grievance.query.filter_by(
                citizen_id=citizen.id,
                title=item["title"],
            ).first()

            if grievance:
                grievance.description = item["description"]
                grievance.category_id = category.id
                grievance.subject_id = subject.id
                grievance.area_id = area.id
                grievance.address = item["area"]
                grievance.status = GrievanceStatus.NEW
                grievance.priority = Priority.MEDIUM
                grievance.updated_at = datetime.now(timezone.utc)

                GrievanceAttachment.query.filter_by(grievance_id=grievance.id).delete()
                updated += 1
            else:
                grievance = Grievance(
                    citizen_id=citizen.id,
                    subject_id=subject.id,
                    area_id=area.id,
                    category_id=category.id,
                    title=item["title"],
                    description=item["description"],
                    address=item["area"],
                    status=GrievanceStatus.NEW,
                    priority=Priority.MEDIUM,
                    escalation_level=0,
                )
                db.session.add(grievance)
                db.session.flush()
                created += 1

            attachment = copy_attachment(item["image"], grievance.id, upload_root)
            if attachment:
                db.session.add(attachment)

            db.session.add(AuditLog(
                action=f"Seed grievance created/updated: {grievance.title}",
                action_type="SEED",
                performed_by=citizen.id,
                grievance_id=grievance.id,
                details=f"Seeded with image: {item['image']}",
            ))

        db.session.commit()

        print("✅ Done")
        print(f"Created: {created}")
        print(f"Updated: {updated}")
        print(f"Citizen login: {CITIZEN_EMAIL} / {CITIZEN_PASSWORD}")


if __name__ == "__main__":
    seed()