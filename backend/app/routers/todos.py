from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.db import get_db
from app.core.security import get_current_user
from app.schemas.todo import TodoCreate, TodoUpdate, TodoResponse
from app.services.todo import (
    create_todo,
    get_todos,
    get_todo_by_id,
    update_todo,
    delete_todo,
)

router = APIRouter(prefix="/todos", tags=["todos"])


@router.post("", response_model=TodoResponse)
def create(
    todo: TodoCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    return create_todo(db, todo, current_user.id)


@router.get("", response_model=list[TodoResponse])
def read_all(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    return get_todos(db, current_user.id)


@router.get("/{todo_id}", response_model=TodoResponse)
def read_one(
    todo_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    todo = get_todo_by_id(db, todo_id, current_user.id)
    if not todo:
        raise HTTPException(status_code=404, detail="Todo not found")
    return todo


@router.put("/{todo_id}", response_model=TodoResponse)
def update(
    todo_id: int,
    todo: TodoUpdate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
):
    updated_todo = update_todo(db, todo_id, todo, current_user.id)
    if not updated_todo:
        raise HTTPException(status_code=404, detail="Todo not found")
    return updated_todo



@router.delete("/{todo_id}")
def delete(
    todo_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
):
    success = delete_todo(db, todo_id, current_user.id)
    if not success:
        raise HTTPException(status_code=404, detail="Todo not found")
    return {"message": "Todo deleted"}