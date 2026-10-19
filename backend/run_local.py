"""Start the API with a dedicated local SQLite database, never the Render DB."""
import argparse
import os
from pathlib import Path
import secrets


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--port', type=int, default=8000)
    parser.add_argument('--demo', action='store_true', help='Create a local demo account')
    args = parser.parse_args()

    directory = Path(__file__).resolve().parent / '.local'
    directory.mkdir(exist_ok=True)
    os.environ['DATABASE_URL'] = f"sqlite:///{(directory / 'life_custom.db').as_posix()}"
    os.environ['SECRET_KEY'] = secrets.token_urlsafe(48)
    os.environ['CORS_ORIGINS'] = 'http://localhost:8080,http://127.0.0.1:8080'

    from app.db import Base, engine, SessionLocal
    from app.main import app
    from app.models.user import User
    from app.services.auth import register_user
    import uvicorn

    Base.metadata.create_all(bind=engine)
    if args.demo:
        with SessionLocal() as db:
            if db.query(User).filter(User.email == 'demo@example.com').first() is None:
                register_user(db, 'demo@example.com', 'example')
        print('Local demo: demo@example.com / example', flush=True)
    uvicorn.run(app, host='127.0.0.1', port=args.port)


if __name__ == '__main__':
    main()
