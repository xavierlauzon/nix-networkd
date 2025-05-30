{ config, lib, ... }:
with lib;
let
  cfg = config.host.network;
  networkdCfg = cfg.networkd;
  interfaceCfgs = cfg.interfaces or { };
  bridgeCfgs = cfg.bridges or { };
  bondCfgs = cfg.bonds or { };
  vlanCfgs = cfg.vlans or { };

  # Import supporting modules
  generators = import ./generation.nix { inherit lib; };    # Generate systemd-networkd configs
  validators = import ./validation.nix { inherit lib; };   # Validate configurations
  data = import ./processing.nix {                         # Process and analyze data
    inherit cfg networkdCfg interfaceCfgs bridgeCfgs bondCfgs vlanCfgs lib;
  };

in {
  config = mkIf networkdCfg.enable (
    let
      # Generate all netdev configurations (bonds, bridges, VLANs)
      allNetdevs = listToAttrs (
        mapAttrsToList generators.mkBondNetdev bondCfgs ++
        mapAttrsToList generators.mkBridgeNetdev bridgeCfgs ++
        mapAttrsToList generators.mkVlanNetdev vlanCfgs
      );

      # Generate link configurations for interface renaming
      allLinks = listToAttrs (
        map (pair: nameValuePair "10-${pair.name}"
          (generators.makeLinkConfig pair.name pair.value.mac)
        ) data.interfacesWithNames
      );

      # Generate all network configurations (interface assignments, IP configs)
      allNetworks = listToAttrs (
        concatMap (pair: generators.mkBondMemberNetworks pair.name pair.value) (mapAttrsToList nameValuePair bondCfgs) ++
        map generators.mkInterfaceNetwork data.unbridgedInterfaces ++
        mapAttrsToList (generators.mkBondNetwork data.allBridgedBonds) bondCfgs ++
        concatMap (pair: generators.mkBridgeMemberNetworks pair.name pair.value) (mapAttrsToList nameValuePair bridgeCfgs) ++
        mapAttrsToList generators.mkBridgeNetwork bridgeCfgs ++
        mapAttrsToList generators.mkVlanNetwork vlanCfgs ++
        mapAttrsToList generators.mkVlanInterfaceNetwork vlanCfgs
      ) // optionalAttrs data.defaultDhcpEnabled {
        # Default DHCP configuration for unconfigured interfaces
        "99-ethernet-default-dhcp" = {
          matchConfig = {
            Type = "ether";
            Kind = "!*";
            Name = "!veth* !docker* !podman*";  # Exclude virtual interfaces
          };
          networkConfig = {
            DHCP = data.globalDhcpMode;
            IPv6AcceptRA = if data.dhcpV6Enabled || data.globalDhcpMode == "yes" then "yes" else "no";
            DHCPPrefixDelegation = data.dhcpV6Enabled || data.globalDhcpMode == "yes";
          };
        };
      };
    in {
      # Configure networking subsystem to use systemd-networkd
      networking = {
        useNetworkd = mkDefault true;
        useDHCP = mkDefault false;           # Disable legacy DHCP
        dhcpcd.enable = mkDefault false;     # Disable dhcpcd service
      };

      # Disable wait-online service (can cause boot delays)
      systemd.services.systemd-networkd-wait-online.enable = mkDefault false;

      # Apply generated configurations
      systemd.network = {
        enable = true;
        netdevs = allNetdevs;
        networks = allNetworks;
        links = allLinks;
      };

      # Apply validation assertions to prevent invalid configurations
      assertions = validators.buildAssertions {
        inherit networkdCfg interfaceCfgs bridgeCfgs bondCfgs vlanCfgs data;
      };
    }
  );
}