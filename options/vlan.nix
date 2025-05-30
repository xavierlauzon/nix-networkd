{ lib }:
with lib;
let
  common = import ./common.nix { inherit lib; };
in
{
  mkVlanOptions = {
    id = mkOption {
      type = types.ints.between 1 4094;
      description = "VLAN ID (1-4094)";
      example = 100;
    };
    interface = mkOption {
      type = types.str;
      description = "Parent interface name (bond/bridge name or interface name)";
      example = "bond0";
    };
    ipv4 = common.mkNetworkOptions "ipv4";
    ipv6 = common.mkNetworkOptions "ipv6";
  };
}