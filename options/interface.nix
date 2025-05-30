{ lib }:
with lib;
let
  common = import ./common.nix { inherit lib; };
in
{
  mkInterfaceOptions = {
    mac = mkOption {
      type = types.str;
      description = "MAC address to match for this interface";
      example = "00:11:22:33:44:55";
    };
    ipv4 = common.mkNetworkOptions "ipv4";
    ipv6 = common.mkNetworkOptions "ipv6";
  };
}