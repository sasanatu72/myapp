from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.db import get_db
from app.core.security import get_current_user 
from app.schemas.note import NoteCreate, NoteUpdate, NoteResponse
from app.services.note import (
    create_note,
    get_notes,
    get_note_by_id,
    update_note,
    delete_note,
)

router = APIRouter(prefix="/notes", tags=["notes"])


@router.post("", response_model=NoteResponse)
def create(
    note: NoteCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    return create_note(db, note, current_user.id)

@router.get("", response_model=list[NoteResponse])
def read_all(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    return get_notes(db, current_user.id)


@router.get("/{note_id}", response_model=NoteResponse)
def read_one(
    note_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    note = get_note_by_id(db, note_id, current_user.id)
    if not note:
        raise HTTPException(status_code=404, detail="Note not found")
    return note


@router.put("/{note_id}", response_model=NoteResponse)
def update(
    note_id: int,
    note: NoteUpdate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
):
    updated_note = update_note(db, note_id, note, current_user.id)
    if not updated_note:
        raise HTTPException(status_code=404, detail="Todo not found")
    return updated_note


@router.delete("/{note_id}")
def delete(
    note_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
):
    success = delete_note(db, note_id, current_user.id)
    if not success:
        raise HTTPException(status_code=404, detail="Todo not found")
    return {"message": "Note deleted"}