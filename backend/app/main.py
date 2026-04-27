from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.db import Base, engine
from app.routers import auth, users, events, todos, note, user_preferences 
from app.core.config import CORS_ORIGINS


app = FastAPI()

allow_origins = ["*"] if CORS_ORIGINS == "*" else [origin.strip() for origin in CORS_ORIGINS.split(",")]

app.add_middleware(
    CORSMiddleware,
    allow_origins=allow_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
def health():
    return {"status": "ok"}


app.include_router(auth.router)
app.include_router(users.router)
app.include_router(events.router)
app.include_router(todos.router)
app.include_router(note.router)
app.include_router(user_preferences.router)