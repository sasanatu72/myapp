from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

from app.core.config import DATABASE_URL

connect_args = {}
if DATABASE_URL.startswith("sqlite"):
    connect_args = {"check_same_thread": False}

engine = create_engine(
    DATABASE_URL,
    connect_args=connect_args
)



SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)
Base = declarative_base() 
print(engine.dialect.name)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()