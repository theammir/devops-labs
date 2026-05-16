from html import escape

from fastapi import APIRouter, HTTPException, Request
from fastapi.responses import HTMLResponse, JSONResponse, Response
from sqlalchemy import select

from mywebapp.content_negotiation import wants_html
from mywebapp.models import Task, TaskStatus
from mywebapp.schemas import TaskCreate, TaskOut

router = APIRouter(prefix="/tasks", tags=["tasks"])


def _render_tasks_html(tasks: list[TaskOut]) -> str:
    rows = "".join(
        "<tr>"
        f"<td>{t.id}</td>"
        f"<td>{escape(t.title)}</td>"
        f"<td>{escape(t.status.value)}</td>"
        f"<td>{escape(t.created_at.isoformat())}</td>"
        "</tr>"
        for t in tasks
    )
    return (
        "<!doctype html><html><head><title>Tasks</title></head><body>"
        "<h1>Tasks</h1>"
        '<table border="1">'
        "<thead><tr><th>id</th><th>title</th><th>status</th><th>created_at</th></tr></thead>"
        f"<tbody>{rows}</tbody>"
        "</table>"
        "</body></html>"
    )


def _render_task_html(t: TaskOut) -> str:
    return (
        "<!doctype html><html><head><title>Task</title></head><body>"
        f"<h1>Task {t.id}</h1>"
        '<table border="1">'
        f"<tr><th>id</th><td>{t.id}</td></tr>"
        f"<tr><th>title</th><td>{escape(t.title)}</td></tr>"
        f"<tr><th>status</th><td>{escape(t.status.value)}</td></tr>"
        f"<tr><th>created_at</th><td>{escape(t.created_at.isoformat())}</td></tr>"
        "</table>"
        "</body></html>"
    )


def _respond_one(request: Request, dto: TaskOut, status_code: int = 200) -> Response:
    if wants_html(request):
        return HTMLResponse(_render_task_html(dto), status_code=status_code)
    return JSONResponse(dto.model_dump(mode="json"), status_code=status_code)


def _respond_many(request: Request, dtos: list[TaskOut], status_code: int = 200) -> Response:
    if wants_html(request):
        return HTMLResponse(_render_tasks_html(dtos), status_code=status_code)
    return JSONResponse([d.model_dump(mode="json") for d in dtos], status_code=status_code)


@router.get("")
async def list_tasks(request: Request) -> Response:
    db = request.app.state.db
    async with db.sessionmaker() as session:
        result = await session.execute(select(Task).order_by(Task.id))
        dtos = [TaskOut.model_validate(t) for t in result.scalars().all()]
    return _respond_many(request, dtos)


@router.post("", status_code=201)
async def create_task(payload: TaskCreate, request: Request) -> Response:
    db = request.app.state.db
    async with db.sessionmaker() as session:
        task = Task(title=payload.title, status=TaskStatus.pending)
        session.add(task)
        await session.commit()
        await session.refresh(task)
        dto = TaskOut.model_validate(task)
    return _respond_one(request, dto, status_code=201)


@router.post("/{task_id}/done")
async def mark_done(task_id: int, request: Request) -> Response:
    db = request.app.state.db
    async with db.sessionmaker() as session:
        task = await session.get(Task, task_id)
        if task is None:
            raise HTTPException(status_code=404, detail="task not found")
        task.status = TaskStatus.done
        await session.commit()
        await session.refresh(task)
        dto = TaskOut.model_validate(task)
    return _respond_one(request, dto)
