{
  mywebapp,
  config,
  lib,
  pkgs,
  ...
}:

{
  options.services.mywebapp.configFile = lib.mkOption {
    type = lib.types.path;
    description = "Path to mywebapp config file";
  };

  config = {
    environment.etc."mywebapp/config.toml".source = config.services.mywebapp.configFile;

    systemd.services.mywebapp = {
      description = "mywebapp backend server";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "postgresql.service"
      ];

      environment = {
        MYWEBAPP_CONFIG = "/etc/mywebapp/config.toml";
        UV_PROJECT_ENVIRONMENT = "/var/lib/mywebapp/.venv";
        UV_CACHE_DIR = "/var/cache/mywebapp";
        HOME = "/var/lib/mywebapp";
        UV_PYTHON = "${pkgs.python314}/bin/python3";
        LD_LIBRARY_PATH = lib.makeLibraryPath [
          pkgs.stdenv.cc.cc
        ];
      };

      serviceConfig = {
        ExecStartPre = [
          "${pkgs.uv}/bin/uv sync --frozen --no-dev --project ${mywebapp}/lib/mywebapp"
          "${pkgs.uv}/bin/uv run --project ${mywebapp}/lib/mywebapp alembic -c ${mywebapp}/lib/mywebapp/alembic.ini upgrade head"
        ];
        ExecStart = "/var/lib/mywebapp/.venv/bin/mywebapp /etc/mywebapp/config.toml";
        Restart = "always";
        User = "app";
        StateDirectory = "mywebapp";
        CacheDirectory = "mywebapp";
        WorkingDirectory = "/var/lib/mywebapp";
      };

      path = [ pkgs.python314 ];
    };
    users.users.app = {
      isSystemUser = true;
      group = "app";
    };
    users.groups.app = { };

  };

}
