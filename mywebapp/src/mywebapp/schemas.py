from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from mywebapp.models import TaskStatus


class TaskCreate(BaseModel):
    title: str = Field(min_length=1, max_length=255)


class TaskOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    title: str
    status: TaskStatus
    created_at: datetime


class EndpointInfo(BaseModel):
    method: str
    path: str
    description: str
