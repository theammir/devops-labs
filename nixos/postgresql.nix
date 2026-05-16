{ ... }:
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
}
