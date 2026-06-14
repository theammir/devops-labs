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

  systemd.services.mywebapp-db-grants = {
    description = "Grant taskuser privileges on the tasks database";
    wantedBy = [ "multi-user.target" ];
    after = [ "postgresql-setup.service" ];
    requires = [ "postgresql-setup.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "postgres";
    };
    script = ''
      ${config.services.postgresql.package}/bin/psql -d tasks -c "GRANT ALL PRIVILEGES ON DATABASE tasks TO taskuser;"
      ${config.services.postgresql.package}/bin/psql -d tasks -c "GRANT ALL ON SCHEMA public TO taskuser;"
    '';
  };
}
