{ lib }:
with lib;
let
  # Network config builder
  makeNetworkConfig = cfg:
    let
      ipv4Enabled = cfg.ipv4.enable or true;
      ipv6Enabled = cfg.ipv6.enable or false;
      ipv4IsDynamic = ipv4Enabled && cfg.ipv4.type == "dynamic";
      ipv6IsDynamic = ipv6Enabled && cfg.ipv6.type == "dynamic";
      ipv4IsStatic = ipv4Enabled && cfg.ipv4.type == "static";
      ipv6IsStatic = ipv6Enabled && cfg.ipv6.type == "static";

      dhcpMode =
        if ipv4IsDynamic && ipv6IsDynamic then "yes"
        else if ipv4IsDynamic then "ipv4"
        else if ipv6IsDynamic then "ipv6"
        else "no";

      additionalRoutes =
        optionals ipv4IsStatic (map (r: r.routeConfig) cfg.ipv4.routes) ++
        optionals ipv6IsStatic (map (r: r.routeConfig) cfg.ipv6.routes);
    in {
      networkConfig =
        optionalAttrs (dhcpMode != "no") { DHCP = dhcpMode; } //
        optionalAttrs ipv6Enabled {
          IPv6AcceptRA = if cfg.ipv6.acceptRA then "yes" else "no";
        };
      address =
        optionals ipv4IsStatic cfg.ipv4.addresses ++
        optionals ipv6IsStatic cfg.ipv6.addresses;
      routes =
        optionals (ipv4IsStatic && cfg.ipv4.gateway != null) [({
          Gateway = cfg.ipv4.gateway;
        } // optionalAttrs cfg.ipv4.gatewayOnLink {
          GatewayOnLink = true;
        } // optionalAttrs (cfg.ipv4.priority != null) {
          Metric = cfg.ipv4.priority;
        })] ++
        optionals (ipv6IsStatic && cfg.ipv6.gateway != null) [({
          Gateway = cfg.ipv6.gateway;
        } // optionalAttrs cfg.ipv6.gatewayOnLink {
          GatewayOnLink = true;
        } // optionalAttrs (cfg.ipv6.priority != null) {
          Metric = cfg.ipv6.priority;
        })] ++
        additionalRoutes;
    };

  # Link config builder
  makeLinkConfig = desiredName: mac: {
    matchConfig = {
      MACAddress = mac;
      Kind = "!bridge !bond";
    };
    linkConfig = {
      Name = desiredName;
    };
  };

  makeNameMatchConfig = name: { matchConfig = { Name = name; }; };

in {
  inherit makeNetworkConfig makeNameMatchConfig makeLinkConfig;

  mkBondNetdev = name: bondCfg: nameValuePair "10-${name}" {
    netdevConfig = {
      Kind = "bond";
      Name = name;
    } // optionalAttrs (bondCfg.mac != null) {
      MACAddress = bondCfg.mac;
    };

    bondConfig = {
      Mode = bondCfg.mode;
      MIIMonitorSec = toString (bondCfg.miimonFreq / 1000);
      UpDelaySec = toString (bondCfg.upDelay / 1000);
      DownDelaySec = toString (bondCfg.downDelay / 1000);
    } // optionalAttrs (bondCfg.primaryInterface != null) {
      PrimaryReselectPolicy = "always";
      PrimarySlave = bondCfg.primaryInterface;
    } // optionalAttrs (bondCfg.mode == "802.3ad") {
      LACPTransmitRate = bondCfg.lacpRate;
      TransmitHashPolicy = bondCfg.xmitHashPolicy;
    } // optionalAttrs bondCfg.allSlavesActive {
      AllSlavesActive = "1";
    };
  };

  mkBridgeNetdev = name: bridgeCfg: nameValuePair "20-${name}" {
    netdevConfig = {
      Kind = "bridge";
      Name = name;
    } // optionalAttrs (bridgeCfg.mac or null != null) {
      MACAddress = bridgeCfg.mac;
    };
  };

  mkVlanNetdev = name: vlanCfg: nameValuePair "30-${name}" {
    netdevConfig = {
      Kind = "vlan";
      Name = name;
    };
    vlanConfig = {
      Id = vlanCfg.id;
    };
  };

  mkBondMemberNetworks = name: bondCfg:
    map (interfaceName:
      nameValuePair "10-bond-member-${interfaceName}" (
        recursiveUpdate (makeNameMatchConfig interfaceName) {
          networkConfig = { Bond = name; };
          linkConfig = {
            PrimarySlave = if interfaceName == bondCfg.primaryInterface then "yes" else "no";
          };
        }
      )
    ) bondCfg.interfaces;

  mkInterfaceNetwork = pair: nameValuePair "10-${pair.name}" (
    recursiveUpdate (makeNameMatchConfig pair.name) (makeNetworkConfig pair.value)
  );

  mkBondNetwork = allBridgedBonds: name: bondCfg:
    let isBridged = elem name allBridgedBonds; in
    nameValuePair "30-${name}" (
      recursiveUpdate (makeNameMatchConfig name) (
        if isBridged
        then { networkConfig.ConfigureWithoutCarrier = "yes"; }
        else makeNetworkConfig bondCfg
      )
    );

  mkBridgeMemberNetworks = name: bridgeCfg:
    map (interfaceName:
      nameValuePair "40-bridge-member-${interfaceName}" (
        recursiveUpdate (makeNameMatchConfig interfaceName) {
          networkConfig = { Bridge = name; };
        }
      )
    ) bridgeCfg.interfaces;

  mkBridgeNetwork = name: bridgeCfg:
    nameValuePair "50-${name}" (
      recursiveUpdate (makeNameMatchConfig name) (makeNetworkConfig bridgeCfg)
    );

  mkVlanNetwork = name: vlanCfg: nameValuePair "60-${name}" (
    recursiveUpdate (makeNameMatchConfig vlanCfg.interface) {
      vlan = [ name ];
    }
  );

  mkVlanInterfaceNetwork = name: vlanCfg: nameValuePair "61-${name}" (
    recursiveUpdate (makeNameMatchConfig name) (makeNetworkConfig vlanCfg)
  );
}