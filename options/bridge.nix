{ lib }:
with lib;
let
  common = import ./common.nix { inherit lib; };
in
{
  mkBridgeOptions = {
    interfaces = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Interface names to include in the bridge (physical interfaces, bonds, etc.)";
      example = [ "eth0" "eth1" "bond0" ];
    };
    mac = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "MAC address to assign to the bridge (useful for OVH failover IPs)";
      example = "00:11:22:33:44:55";
    };
    ipv4 = common.mkNetworkOptions "ipv4";
    ipv6 = common.mkNetworkOptions "ipv6";
  };
}