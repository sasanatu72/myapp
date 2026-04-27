from sqlalchemy.orm import Session
from app.models.todo import Todo
from app.schemas.todo import TodoCreate, TodoUpdate

def create_todo(db: Session, todo: TodoCreate, user_id: int):
    db_todo = Todo(
        title=todo.title,
        due_date=todo.due_date,
        user_id=user_id,
    )
    db.add(db_todo)
    db.commit()
    db.refresh(db_todo)
    return db_todo


def get_todos(db: Session, user_id: int):
    return (
        db.query(Todo)
        .filter(
            Todo.user_id == user_id,
            Todo.is_deleted == False,
        )
        .order_by(Todo.is_done.asc(), Todo.due_date.asc())
        .all()
    )

def get_todo_by_id(db: Session, todo_id: int, user_id: int):
    return (
        db.query(Todo)
        .filter(
            Todo.id == todo_id,
            Todo.user_id == user_id,
            Todo.is_deleted == False,
        )
        .first()
    )



def update_todo(db: Session, todo_id: int, todo: TodoUpdate, user_id: int):
    db_todo = (
        db.query(Todo)
        .filter(
            Todo.id == todo_id,
            Todo.user_id == user_id,
            Todo.is_deleted == False,
        )
        .first()
    )
    if not db_todo:
        return None

    if todo.title is not None:
        db_todo.title = todo.title

    if todo.due_date is not None:
        db_todo.due_date = todo.due_date

    if todo.is_done is not None:
        db_todo.is_done = todo.is_done

    db.commit()
    db.refresh(db_todo)
    return db_todo

def delete_todo(db: Session, todo_id: int, user_id: int):
    db_todo = (
        db.query(Todo)
        .filter(
            Todo.id == todo_id,
            Todo.user_id == user_id,
            Todo.is_deleted == False
        )
        .first()
    )

    if not db_todo:
        return False

    db_todo.is_deleted = True
    db.commit()
    return True