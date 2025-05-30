{ lib }:
with lib;
{
  mkNetworkOptions = type:
    let
      isIPv6 = type == "ipv6";
      baseOptions = {
        enable = mkEnableOption "${type} support";
        type = mkOption {
          type = types.enum ([ "static" "dynamic" ] ++ optional isIPv6 "slaac");
          default = if isIPv6 then "slaac" else "static";
          description = "${type} configuration method";
        };
        addresses = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "List of ${type} addresses with prefix length";
          example = if isIPv6 then [ "2001:db8::1/64" ] else [ "192.168.1.10/24" ];
        };
        gateway = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "${type} default gateway";
          example = if isIPv6 then "2001:db8::1" else "192.168.1.1";
        };
        gatewayOnLink = mkOption {
          type = types.bool;
          default = true;
          description = "Whether the gateway is on-link (directly reachable)";
        };
        routes = mkOption {
          type = types.listOf (types.submodule {
            options = {
              routeConfig = mkOption {
                type = types.attrsOf types.str;
                default = {};
                description = "Route configuration";
                example = { Destination = "10.0.0.0/24"; Gateway = "192.168.1.1"; };
              };
            };
          });
          default = [];
          description = "Additional ${type} routes";
        };
        priority = mkOption {
          type = types.nullOr types.int;
          default = null;
          description = "Route priority/metric";
        };
      };
      ipv6Options = {
        acceptRA = mkOption {
          type = types.bool;
          default = true;
          description = "Accept Router Advertisements (needed for SLAAC)";
        };
      };
    in baseOptions // optionalAttrs isIPv6 ipv6Options;
}