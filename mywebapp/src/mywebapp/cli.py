import argparse
from pathlib import Path

import uvicorn

from mywebapp.app import create_app
from mywebapp.config import load_config


def main() -> None:
    parser = argparse.ArgumentParser(prog="mywebapp", description="Task Tracker service")
    parser.add_argument("config", type=Path, help="Path to TOML config file")
    args = parser.parse_args()

    config = load_config(args.config)
    app = create_app(config)
    uvicorn.run(app, host=config.server.host, port=config.server.port)


if __name__ == "__main__":
    main()
