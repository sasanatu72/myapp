from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.db import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.schemas.user_preference import UserPreferenceResponse, UserPreferenceUpdate
from app.services.user_preference import get_or_create_preferences, update_preferences

router = APIRouter(prefix="/preferences", tags=["preferences"])


@router.get("/me", response_model=UserPreferenceResponse)
def read_my_preferences(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return get_or_create_preferences(db, current_user.id)


@router.put("/me", response_model=UserPreferenceResponse)
def update_my_preferences(
    payload: UserPreferenceUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return update_preferences(db, current_user.id, payload)