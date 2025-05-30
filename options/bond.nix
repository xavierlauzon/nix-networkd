{ lib }:
with lib;
let
  common = import ./common.nix { inherit lib; };
in
{
  mkBondOptions = {
    interfaces = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Interface names to include in the bond";
      example = [ "eth0" "eth1" ];
    };
    mode = mkOption {
      type = types.enum [
        "balance-rr" "active-backup" "balance-xor" "broadcast"
        "802.3ad" "balance-tlb" "balance-alb"
      ];
      default = "active-backup";
      description = "Bonding mode";
    };
    primaryInterface = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Name of primary interface for active-backup mode";
      example = "eth0";
    };
    mac = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Optional MAC address for the bond";
      example = "00:11:22:33:44:55";
    };
    miimonFreq = mkOption {
      type = types.int;
      default = 100;
      description = "Link monitoring frequency (ms)";
    };
    downDelay = mkOption {
      type = types.int;
      default = 200;
      description = "Delay before disabling a failing link (ms)";
    };
    upDelay = mkOption {
      type = types.int;
      default = 200;
      description = "Delay before enabling a recovered link (ms)";
    };
    lacpRate = mkOption {
      type = types.enum [ "slow" "fast" ];
      default = "slow";
      description = "LACP rate for 802.3ad mode (fast = 1 sec, slow = 30 sec)";
    };
    xmitHashPolicy = mkOption {
      type = types.enum [ "layer2" "layer2+3" "layer3+4" "encap2+3" "encap3+4" ];
      default = "layer2";
      description = "Transmit hash policy for load balancing modes";
    };
    allSlavesActive = mkOption {
      type = types.bool;
      default = false;
      description = "Keep all slaves active (useful for broadcast/balance-tlb modes)";
    };
    ipv4 = common.mkNetworkOptions "ipv4";
    ipv6 = common.mkNetworkOptions "ipv6";
  };
}