{ ... }:
{
  services.nginx = {
    enable = true;
    virtualHosts."localhost" = {
      locations."/" = {
        return = "200 'hello from nginx'";
        extraConfig = "add_header Content-Type text/plain;";
      };
    };
  };
}
