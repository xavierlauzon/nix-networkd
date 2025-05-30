{ lib }:
with lib;
{
  # Checks IP configuration to prevent common mistakes
  # Makes sure static configs have addresses and gateways set properly
  validateIPConfig = ipVersion: name: cfg:
    let
      ipCfg = cfg.${ipVersion};
      ipEnabled = ipCfg.enable or (if ipVersion == "ipv4" then true else false);
      isStatic = ipEnabled && ipCfg.type == "static";
      hasAddresses = ipCfg.addresses != [];
      hasGateway = ipCfg.gateway != null;
    in optionals isStatic [
      {
        assertion = hasAddresses;
        message = "${name}: ${ipVersion} addresses required for static configuration";
      }
      {
        assertion = hasGateway;
        message = "${name}: ${ipVersion} gateway required for static configuration";
      }
    ];

  # Validates both IPv4 and IPv6 settings for any network interface
  # Just a wrapper that calls the IP validation for both protocols
  validateNetworkConfig = name: cfg:
    let
      self = import ./validation.nix { inherit lib; };
    in
    self.validateIPConfig "ipv4" name cfg ++ self.validateIPConfig "ipv6" name cfg;
  # Builds all the validation checks that prevent broken network configs
  # This catches most common mistakes before they can lock you out of your system
  buildAssertions = { networkdCfg, interfaceCfgs, bridgeCfgs, bondCfgs, vlanCfgs, data }:
    let
      self = import ./validation.nix { inherit lib; };
      interfacesWithNames = mapAttrsToList nameValuePair interfaceCfgs;
    in
    [
      # Make sure no two interfaces have the same MAC address
      {
        assertion = !data.hasDuplicateMacs;
        message = "Error: Found duplicate MAC addresses in network configuration";
      }
    ]
    # Validate individual interfaces
    ++ concatMap (pair: let name = pair.name; cfg = pair.value; in
      [{
        assertion = cfg.mac != null;
        message = "Interface ${name}: MAC address is required";
      }] ++ self.validateNetworkConfig "Interface ${name}" cfg
    ) interfacesWithNames

    # Validate bridges
    ++ concatMap (pair: let name = pair.name; bridgeCfg = pair.value; in
      let
        emptyInterfaces = bridgeCfg.interfaces == [];
        invalidInterfaces = filter (ifName:
          !hasAttr ifName interfaceCfgs && !hasAttr ifName bondCfgs
        ) bridgeCfg.interfaces;
      in
      [{
        assertion = !emptyInterfaces;
        message = "Bridge ${name}: Must have at least one interface";
      }
      {
        assertion = invalidInterfaces == [];
        message = "Bridge ${name}: References non-existent interface(s) or bond(s): ${toString invalidInterfaces}";
      }] ++ self.validateNetworkConfig "Bridge ${name}" bridgeCfg
    ) (mapAttrsToList nameValuePair bridgeCfgs)

    # Validate bonds
    ++ concatMap (pair: let name = pair.name; bondCfg = pair.value; in
      let
        isBridged = elem name data.allBridgedBonds;
        emptyInterfaces = bondCfg.interfaces == [];
        isPrimaryInterfaceValid = bondCfg.primaryInterface == null ||
                                  elem bondCfg.primaryInterface bondCfg.interfaces;
      in
      [{
        assertion = !emptyInterfaces;
        message = "Bond ${name}: Must have at least one interface";
      }
      {
        assertion = isPrimaryInterfaceValid;
        message = "Bond ${name}: Primary interface must be one of the interfaces in the bond";
      }] ++ (if isBridged then [] else self.validateNetworkConfig "Bond ${name}" bondCfg)
    ) (mapAttrsToList nameValuePair bondCfgs)

    # Validate VLANs
    ++ concatMap (pair: let name = pair.name; vlanCfg = pair.value; in
      let
        parentExists = hasAttr vlanCfg.interface bondCfgs ||
                      hasAttr vlanCfg.interface bridgeCfgs ||
                      any (iface: iface.name == vlanCfg.interface) interfacesWithNames;
      in
      [{
        assertion = parentExists;
        message = "VLAN ${name}: Parent interface '${vlanCfg.interface}' does not exist";
      }] ++ self.validateNetworkConfig "VLAN ${name}" vlanCfg
    ) (mapAttrsToList nameValuePair vlanCfgs);
}