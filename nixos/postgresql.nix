{ lib, config, ... }:
{
  services.postgresql = {
    enable = true;
    settings = {
      port = 5432;
    };
    ensureDatabases = [ "tasks" ];
    ensureUsers = [
      {
        name = "taskuser";
      }
    ];
    authentication = ''
      local all all trust
      host all all 127.0.0.1/32 trust
    '';
  };

  systemd.services.postgresql.postStart = lib.mkAfter ''
    ${config.services.postgresql.package}/bin/psql -U postgres -d tasks -c "GRANT ALL PRIVILEGES ON DATABASE tasks TO taskuser;"
    ${config.services.postgresql.package}/bin/psql -U postgres -d tasks -c "GRANT ALL ON SCHEMA public TO taskuser;"
  '';
}
