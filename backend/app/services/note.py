from sqlalchemy.orm import Session
from app.models.note import Note
from app.schemas.note import NoteCreate, NoteUpdate
from datetime import datetime

def create_note(db: Session, note: NoteCreate, user_id: int):
    db_note = Note(
        title=note.title,
        content=note.content,
        user_id=user_id,
    )
    db.add(db_note)
    db.commit()
    db.refresh(db_note)
    return db_note


def get_notes(db: Session, user_id: int):
    return (
        db.query(Note)
        .filter(
            Note.user_id == user_id
        )
        .all()
    )


def get_note_by_id(db: Session, note_id: int, user_id: int):
    return (
        db.query(Note)
        .filter(
            Note.id == note_id,
            Note.user_id == user_id,
        )
        .first()
    )


def update_note(db: Session, note_id: int, note: NoteUpdate, user_id: int):
    db_note = (
        db.query(Note)
        .filter(
            Note.id == note_id,
            Note.user_id == user_id,
        )
        .first()
    )
    if not db_note:
        return None

    if note.title is not None:
        db_note.title = note.title
    
    if note.content is not None:
        db_note.content = note.content

    db_note.updated_at = datetime.utcnow()
    db.commit()
    return db_note


def delete_note(db: Session, note_id: int, user_id: int):
    db_note = (
        db.query(Note)
        .filter(
            Note.id == note_id,
            Note.user_id == user_id,
        )
        .first()
    )
    
    if not db_note:
        return False

    db.delete(db_note)
    db.commit()
    return True