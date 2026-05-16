from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI

from mywebapp.config import Config
from mywebapp.db import Database
from mywebapp.routes import health, root, tasks


def create_app(config: Config) -> FastAPI:
    @asynccontextmanager
    async def lifespan(app: FastAPI) -> AsyncIterator[None]:
        app.state.db = Database(config.database.url)
        try:
            yield
        finally:
            await app.state.db.dispose()

    app = FastAPI(title="Task Tracker", lifespan=lifespan)
    app.state.config = config
    app.include_router(root.router)
    app.include_router(health.router)
    app.include_router(tasks.router)
    return app
