{ ... }:
{
  services.nginx = {
    enable = true;
    virtualHosts."_" = {
      listen = [
        {
          addr = "0.0.0.0";
          port = 80;
        }
      ];
      locations."/" = {
        proxyPass = "http://127.0.0.1:8080";
      };
    };
  };
}
