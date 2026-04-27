from pydantic import BaseModel
from datetime import datetime
from typing import Union, Optional


class EventCreate(BaseModel):
    title: str
    start_time: datetime
    end_time: datetime


class EventUpdate(BaseModel):
    title: Optional[str] = None
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None
    

class EventResponse(BaseModel):
    id: int
    title: str
    start_time: datetime
    end_time: datetime

    class Config:
        from_attributes = True
        