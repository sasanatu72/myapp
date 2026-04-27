from sqlalchemy import Column, Integer, String, Boolean
from sqlalchemy.orm import relationship
from app.db import Base
from app.models.todo import Todo

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)

    todos = relationship("Todo", back_populates="user")
    preferences = relationship("UserPreference", back_populates="user", uselist=False)

    is_deleted = Column(Boolean, default=False)
