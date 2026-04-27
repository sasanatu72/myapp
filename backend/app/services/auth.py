from sqlalchemy.orm import Session
from app.models.user import User
from app.core.security import hash_password, verify_password, create_access_token

def register_user(db: Session, email: str, password: str):
    user = User(
        email=email,
        hashed_password=hash_password(password)
    )

    existing_user = db.query(User).filter(User.email == email).first()
    if existing_user:
        return None

    db.add(user)
    db.commit()
    db.refresh(user)
    return user

def authenticate_user(db: Session, email: str, password: str):
    user = db.query(User).filter(
        User.email == email,
        User.is_deleted == False,    
    ).first()
    if not user:
        return None
    if not verify_password(password, user.hashed_password):
        return None
    return user

def login_user(user: User):
    token = create_access_token({"sub": str(user.id)})
    return {"access_token": token, "token_type": "bearer"}
