{ config, lib, pkgs, ... }:
with lib;
let
  interface = import ./interface.nix { inherit lib; };
  bond = import ./bond.nix { inherit lib; };
  bridge = import ./bridge.nix { inherit lib; };
  vlan = import ./vlan.nix { inherit lib; };
in
{
  options = {
    host.network = {
      # Generic network configuration options
      networkd = {
        enable = mkEnableOption "systemd-networkd based networking";
        dhcp = {
          enable = mkEnableOption "DHCP for all unconfigured ethernet interfaces";
          v4 = mkOption {
            type = types.bool;
            default = true;
            description = "Enable DHCPv4 for unconfigured interfaces";
          };
          v6 = mkOption {
            type = types.bool;
            default = false;
            description = "Enable DHCPv6 for unconfigured interfaces";
          };
        };
      };

      # Network interface configurations
      interfaces = mkOption {
        type = types.attrsOf (types.submodule { options = interface.mkInterfaceOptions; });
        default = {};
        description = "Network interface configurations";
        example = literalExpression ''
          {
            eth0 = {
              mac = "00:11:22:33:44:55";
              ipv4 = {
                type = "static";
                addresses = [ "192.168.1.10/24" ];
                gateway = "192.168.1.1";
              };
              ipv6 = {
                enable = true;
                type = "static";
                addresses = [ "2001:db8::10/64" ];
                gateway = "2001:db8::1";
              };
            };
          }
        '';
      };

      # Network bridge configurations
      bridges = mkOption {
        type = types.attrsOf (types.submodule { options = bridge.mkBridgeOptions; });
        default = {};
        description = ''
          Network bridge configurations. Bridges allow multiple interfaces
          to be connected together at the data link layer (Layer 2).
          Useful for VMs, containers, or creating network segments.
        '';
        example = literalExpression ''
          {
            br0 = {
              interfaces = [ "eth0" ];
              ipv4 = {
                type = "static";
                addresses = [ "192.168.1.10/24" ];
                gateway = "192.168.1.1";
              };
              ipv6 = {
                enable = true;
                type = "static";
                addresses = [ "2001:db8::10/64" ];
                gateway = "2001:db8::1";
              };
            };
          }
        '';
      };

      # Network bond configurations
      bonds = mkOption {
        type = types.attrsOf (types.submodule { options = bond.mkBondOptions; });
        default = {};
        description = ''
          Network bond configurations. Bonds combine multiple interfaces
          for redundancy (active-backup) or increased bandwidth (LACP).
          Essential for high-availability server setups.
        '';
        example = literalExpression ''
          {
            bond0 = {
              interfaces = [ "eth0" "eth1" ];
              mode = "active-backup";
              primaryInterface = "eth0";
              ipv4 = {
                type = "static";
                addresses = [ "192.168.1.10/24" ];
                gateway = "192.168.1.1";
              };
              ipv6 = {
                enable = true;
                type = "static";
                addresses = [ "2001:db8::10/64" ];
                gateway = "2001:db8::1";
              };
            };
          }
        '';
      };

      # Network VLAN configurations
      vlans = mkOption {
        type = types.attrsOf (types.submodule { options = vlan.mkVlanOptions; });
        default = {};
        description = ''
          VLAN configurations for network segmentation. VLANs allow
          multiple logical networks to share the same physical infrastructure.
          Commonly used to separate traffic types (management, storage, etc.).
        '';
        example = literalExpression ''
          {
            "vlan100" = {
              id = 100;
              interface = "eth0";
              ipv4 = {
                type = "static";
                addresses = [ "192.168.100.10/24" ];
                gateway = "192.168.100.1";
              };
              ipv6 = {
                enable = true;
                type = "static";
                addresses = [ "2001:db8:100::10/64" ];
                gateway = "2001:db8:100::1";
              };
            };
          }
        '';
      };
    };
  };
}