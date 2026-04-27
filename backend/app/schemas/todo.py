from pydantic import BaseModel
from datetime import date, datetime
from typing import Optional

class TodoCreate(BaseModel):
    title: str
    due_date: Optional[date] = None

class TodoUpdate(BaseModel):
    title: Optional[str] = None
    due_date: Optional[date] = None
    is_done: Optional[bool] = None

class TodoResponse(BaseModel):
    id: int
    title: str
    is_done: bool
    due_date: Optional[date] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True 