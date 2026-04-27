from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session

from app.db import get_db
from app.core.security import get_current_user
from app.schemas.event import EventCreate, EventUpdate, EventResponse
from app.services.event import (
    create_event,
    get_events,
    update_event,
    delete_event,
)

router = APIRouter(
    prefix="/events",
    tags=["events"],
)


@router.post("/", response_model=EventResponse)
def create(
    event: EventCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
):
    return create_event(db, event, current_user.id)


@router.get("/", response_model=list[EventResponse])
def read_events(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
):
    return get_events(db, current_user.id)


@router.put("/{event_id}", response_model=EventResponse)
def update(
    event_id: int,
    event: EventUpdate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
):
    updated_event = update_event(db, event_id, event, current_user.id)
    if not updated_event:
        raise HTTPException(status_code=404, detail="Event not found")
    return updated_event


@router.delete("/{event_id}")
def delete(
    event_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
):
    success = delete_event(db, event_id, current_user.id)
    if not success:
        raise HTTPException(status_code=404, detail="Todo not found")
    return {"message": "Event deleted"}



