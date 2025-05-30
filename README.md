# nix-networkd

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Nix](https://img.shields.io/badge/Made%20with-Nix-blue.svg)](https://nixos.org/)
[![NixOS](https://img.shields.io/badge/NixOS-Module-blue.svg)](https://nixos.org/)

A NixOS module for configuring networks using systemd-networkd. Supports bonds, bridges, VLANs, and other complex networking setups.

## What it does

- **Interface renaming**: Rename interfaces from udev names (e.g., `ens3`) to predictable names (e.g., `eth0`)
- Interface bonding (active-backup, LACP, etc.)
- Bridge configuration for VMs and containers
- VLAN tagging
- Custom routing and multiple interfaces
- Validates your config so you don't lock yourself out

## Architecture

```
├── default.nix              # Main entry point
├── options/                 # Option definitions
│   ├── default.nix          #   Main options definition
│   ├── common.nix           #   Shared utilities & option generators
│   ├── interface.nix        #   Interface-specific options
│   ├── bond.nix             #   Bond-specific options
│   ├── bridge.nix           #   Bridge-specific options
│   └── vlan.nix             #   VLAN-specific options
└── config/                  # Configuration implementations
    ├── default.nix          #   Config index
    ├── implementation.nix   #   Main configuration logic
    ├── processing.nix       #   Data processing & collection
    ├── validation.nix       #   Validation logic
    └── generation.nix       #   systemd-networkd generators
```

## Configuration Reference

### Overview

nix-networkd provides a unified configuration system where all network types (interfaces, bonds, bridges, VLANs) can be configured with IP addresses using the same options. This section explains both the common IP configuration options and the type-specific options for each network type.

### Common IP Configuration

**These options work on all network types**: interfaces, bonds, bridges, and VLANs.

```nix
# Example: This same structure works for any network type
host.network.interfaces.eth0 = {
  # ... type-specific options ...
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
```

#### IPv4 Configuration Options

- `ipv4.enable` - Enable IPv4 (default: `true`)
- `ipv4.type` - Configuration method:
  - `"static"` - Manual IP configuration
  - `"dynamic"` - DHCP
- `ipv4.addresses` - List of IP addresses with prefix length
  - Example: `[ "192.168.1.10/24" "10.0.0.5/8" ]`
- `ipv4.gateway` - Default gateway address
- `ipv4.gatewayOnLink` - Gateway is directly reachable (default: `true`)
- `ipv4.routes` - Additional static routes (list of `{ routeConfig = {...}; }`)
- `ipv4.priority` - Route metric/priority (lower = higher priority)

#### IPv6 Configuration Options

- `ipv6.enable` - Enable IPv6 (default: `false`)
- `ipv6.type` - Configuration method:
  - `"static"` - Manual IP configuration
  - `"dynamic"` - DHCPv6
  - `"slaac"` - StateLess Address AutoConfiguration (default)
- `ipv6.addresses` - List of IP addresses with prefix length
  - Example: `[ "2001:db8::10/64" ]`
- `ipv6.gateway` - Default gateway address
- `ipv6.gatewayOnLink` - Gateway is directly reachable (default: `true`)
- `ipv6.routes` - Additional static routes (list of `{ routeConfig = {...}; }`)
- `ipv6.priority` - Route metric/priority (lower = higher priority)
- `ipv6.acceptRA` - Accept Router Advertisements for SLAAC (default: `true`)

### Network Type Specific Options

Each network type has its own specific configuration options in addition to the common IP configuration above.

#### Interface Options (`host.network.interfaces.<name>`)

**Required:**

- `mac` - MAC address to match for this interface

**Example:**
```nix
host.network.interfaces.eth0 = {
  mac = "00:11:22:33:44:55";
  ipv4 = {
    type = "static";
    addresses = [ "192.168.1.10/24" ];
    gateway = "192.168.1.1";
  };
};
```

**Note**: Interfaces are automatically renamed from udev names (like `ens3`, `enp0s3`) to your specified names (like `eth0`, `eth1`). This provides predictable interface naming regardless of hardware detection order.

#### Bond Options (`host.network.bonds.<name>`)

**Required:**

- `interfaces` - List of interface names to bond

**Optional:**

- `mode` - Bonding mode (default: `"active-backup"`)
  - `"active-backup"` - One active, others standby
  - `"802.3ad"` - LACP aggregation
  - `"balance-rr"`, `"balance-xor"`, `"balance-tlb"`, `"balance-alb"` - Load balancing modes
  - `"broadcast"` - Broadcast on all interfaces
- `primaryInterface` - Primary interface name for active-backup mode
- `mac` - Optional MAC address for the bond
- `miimonFreq` - Link monitoring frequency in ms (default: 100)
- `lacpRate` - LACP rate for 802.3ad: `"slow"` (30s) or `"fast"` (1s)
- `xmitHashPolicy` - Load balancing hash policy: `"layer2"`, `"layer2+3"`, `"layer3+4"`, etc.

**Example:**

```nix
host.network.bonds.bond0 = {
  interfaces = [ "eth0" "eth1" ];
  mode = "active-backup";
  primaryInterface = "eth0";
  ipv4 = {
    type = "static";
    addresses = [ "192.168.1.10/24" ];
    gateway = "192.168.1.1";
  };
};
```

#### Bridge Options (`host.network.bridges.<name>`)

**Required:**

- `interfaces` - List of interface names to bridge (can include physical interfaces, bonds)

**Optional:**

- `mac` - Optional MAC address for the bridge (useful for OVH failover IPs)

**Example:**

```nix
host.network.bridges.br0 = {
  interfaces = [ "eth0" "bond0" ];
  ipv4 = {
    type = "static";
    addresses = [ "192.168.1.10/24" ];
    gateway = "192.168.1.1";
  };
};
```

#### VLAN Options (`host.network.vlans.<name>`)

**Required:**

- `id` - VLAN ID (1-4094)
- `interface` - Parent interface name (physical interface, bond, or bridge)

**Example:**

```nix
host.network.vlans.vlan100 = {
  id = 100;
  interface = "eth0";
  ipv4 = {
    type = "static";
    addresses = [ "192.168.100.10/24" ];
    gateway = "192.168.100.1";
  };
};
```

## License

MIT License - see LICENSE file for details.
