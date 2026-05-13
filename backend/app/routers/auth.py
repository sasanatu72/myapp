from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from app.db import get_db
from app.schemas.user import UserCreate, UserLogin
from app.services.auth import register_user, authenticate_user, login_user

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register")
def register(user: UserCreate, db: Session = Depends(get_db)):
    registered_user = register_user(db, user.email, user.password)

    if not registered_user:
        raise HTTPException(status_code=400, detail="This email already exists")
    return registered_user

@router.post("/login")
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    auth_user = authenticate_user(db, form_data.username, form_data.password)
    if not auth_user:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    return login_user(auth_user)
