import tomllib
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True, slots=True)
class ServerConfig:
    host: str
    port: int


@dataclass(frozen=True, slots=True)
class DatabaseConfig:
    url: str


@dataclass(frozen=True, slots=True)
class Config:
    server: ServerConfig
    database: DatabaseConfig


def load_config(path: Path) -> Config:
    with path.open("rb") as f:
        raw = tomllib.load(f)
    server = raw["server"]
    database = raw["database"]
    return Config(
        server=ServerConfig(host=server["host"], port=int(server["port"])),
        database=DatabaseConfig(url=database["url"]),
    )
