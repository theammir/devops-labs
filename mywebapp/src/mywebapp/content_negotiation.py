from fastapi import Request

JSON = "application/json"
HTML = "text/html"


def wants_html(request: Request) -> bool:
    """First explicit text/html or application/json in Accept wins.

    Empty or */* defaults to JSON.
    """
    accept = request.headers.get("accept", "")
    if not accept:
        return False
    for raw in accept.split(","):
        media = raw.split(";", 1)[0].strip().lower()
        if media == HTML:
            return True
        if media == JSON:
            return False
    return False
