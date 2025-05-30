{ cfg, networkdCfg, interfaceCfgs, bridgeCfgs, bondCfgs, vlanCfgs, lib }:
with lib;
let
  # Figure out which interface names are being used by bridges and bonds
  allBridgedInterfaces = concatMap (b: b.interfaces) (attrValues bridgeCfgs);
  allBondedInterfaces = concatMap (b: b.interfaces) (attrValues bondCfgs);

  # Figure out which bonds are bridged (intersection of bond names and bridged interfaces)
  allBridgedBonds = filter (bondName: elem bondName allBridgedInterfaces) (attrNames bondCfgs);

  # Turn the interface config into something easier to work with
  interfacesWithNames = mapAttrsToList nameValuePair interfaceCfgs;

  # Find interfaces that aren't part of bonds or bridges (these need direct IP config)
  unbridgedInterfaces = filter (ifData:
    !(elem ifData.name allBridgedInterfaces) &&
    !(elem ifData.name allBondedInterfaces)
  ) interfacesWithNames;

  # Check for duplicate MAC addresses
  allInterfaceMacs = map (ifData: ifData.value.mac) interfacesWithNames;
  hasDuplicateMacs = length allInterfaceMacs != length (unique allInterfaceMacs);

  # Figure out what kind of DHCP setup we need
  defaultDhcpEnabled = networkdCfg.dhcp.enable;
  dhcpV4Enabled = defaultDhcpEnabled && networkdCfg.dhcp.v4;
  dhcpV6Enabled = defaultDhcpEnabled && networkdCfg.dhcp.v6;
  globalDhcpMode =
    if dhcpV4Enabled && dhcpV6Enabled then "yes"
    else if dhcpV4Enabled then "ipv4"
    else if dhcpV6Enabled then "ipv6"
    else "no";

in {
  inherit
    allBridgedInterfaces allBondedInterfaces allBridgedBonds
    interfacesWithNames unbridgedInterfaces allInterfaceMacs hasDuplicateMacs
    defaultDhcpEnabled dhcpV4Enabled dhcpV6Enabled globalDhcpMode;
}