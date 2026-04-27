from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship
from app.db import Base

class UserPreference(Base):
    __tablename__ = "user_preferences"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)

    enabled_tabs = Column(String, nullable=False, default='["calendar","todo","note"]')
    tab_order = Column(String, nullable=False, default='["calendar","todo","note"]')
    initial_tab = Column(String, nullable=False, default='["calendar"]')
    theme_mode = Column(String, nullable=False, default="system")

    user = relationship("User", back_populates="preferences")