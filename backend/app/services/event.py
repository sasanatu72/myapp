from sqlalchemy.orm import Session
from app.models.event import Event
from app.schemas.event import EventCreate, EventUpdate
from datetime import datetime


def create_event(db: Session, event: EventCreate, user_id: int):
    db_event = Event(
        title=event.title,
        start_time=event.start_time,
        end_time=event.end_time,
        user_id=user_id,
    )

    db.add(db_event)
    db.commit()
    db.refresh(db_event)
    
    return db_event


def get_events(db: Session, user_id: int):
    return (
        db.query(Event)
        .filter(
            Event.user_id == user_id,
            Event.is_deleted == False,
        ).order_by(Event.start_time)
        .all()
    )


# def get_note_by_id(db: Session, note_id: int, user_id: int):
#     return (
#         db.query(Note)
#         .filter(
#             Note.id == note_id,
#             Note.user_id == user_id,
#         )
#         .first()
#     )


def update_event(db: Session, event_id: int, event: EventUpdate, user_id: int):
    db_event = (
        db.query(Event)
        .filter(
            Event.id == event_id,
            Event.user_id == user_id,
        )
        .first()
    )
    if not db_event:
        return None

    if event.title is not None:
        db_event.title = event.title
    
    if event.start_time is not None:
        db_event.start_time = event.start_time

    if event.end_time is not None:
        db_event.end_time = event.end_time

    db_event.updated_at = datetime.utcnow()
    db.commit()
    return db_event


def delete_event(db: Session, event_id: int, user_id: int):
    db_event = (
        db.query(Event)
        .filter(
            Event.id == event_id,
            Event.user_id == user_id,
            Event.is_deleted == False,
        )
        .first()
    )
    
    if not db_event:
        return False

    db_event.is_deleted = True
    db.commit()
    return True