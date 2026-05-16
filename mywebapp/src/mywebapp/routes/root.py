from fastapi import APIRouter, HTTPException, Request
from fastapi.responses import HTMLResponse

from mywebapp.content_negotiation import HTML
from mywebapp.schemas import EndpointInfo

router = APIRouter()


ENDPOINTS: list[EndpointInfo] = [
    EndpointInfo(method="GET", path="/tasks", description="list all tasks"),
    EndpointInfo(method="POST", path="/tasks", description="create a new task"),
    EndpointInfo(method="POST", path="/tasks/{id}/done", description="mark task as done"),
]


@router.get("/", response_class=HTMLResponse)
async def root(request: Request) -> HTMLResponse:
    accept = request.headers.get("accept", "")
    if accept and HTML not in accept and "*/*" not in accept:
        raise HTTPException(status_code=406, detail="text/html only")
    rows = "".join(
        f"<tr><td>{e.method}</td><td>{e.path}</td><td>{e.description}</td></tr>" for e in ENDPOINTS
    )
    body = (
        "<!doctype html><html><head><title>Task Tracker</title></head><body>"
        "<h1>Task Tracker — endpoints</h1>"
        '<table border="1">'
        "<thead><tr><th>method</th><th>path</th><th>description</th></tr></thead>"
        f"<tbody>{rows}</tbody>"
        "</table>"
        "</body></html>"
    )
    return HTMLResponse(body)
