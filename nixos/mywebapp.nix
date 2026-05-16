{ mywebapp, ... }:
{
  systemd.services.mywebapp = {
    description = "mywebapp backend server";
    wantedBy = [ "multi-user.target" ];
    after = [
      "network.target"
      "postgresql.service"
    ];

    serviceConfig = {
      ExecStart = "${mywebapp}/bin/mywebapp";
      Restart = "always";
      User = "mywebapp";
      StateDirectory = "mywebapp";
      WorkingDirectory = "/var/lib/mywebapp";
    };
  };

  users.users.app = {
    isSystemUser = true;
    group = "app";
  };
  users.groups.app = { };
}
