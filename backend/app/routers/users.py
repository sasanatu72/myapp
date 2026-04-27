from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from app.db import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.models.event import Event
from app.models.todo import Todo

router = APIRouter(prefix="/users", tags=["users"])

@router.get("/me")
def read_me(current_user: User = Depends(get_current_user)):
    return {
        "id": current_user.id,
        "email": current_user.email
    }


@router.delete("/{user_id}")
def delete_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.id != user_id:
        raise HTTPException(status_code=403, detail="Not allowed")

    user = db.query(User).filter(User.id == user_id).first()

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    user.is_deleted = True

    db.query(Event).filter(Event.user_id == user_id).update({"is_deleted": True})
    db.query(Todo).filter(Todo.user_id == user_id).update({"is_deleted": True})

    db.commit()

    return {"message": "User deleted"}