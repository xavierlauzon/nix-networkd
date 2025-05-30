# Template for using nix-networkd module

This template provides a basic setup for using the nix-networkd module in your NixOS configuration.

## Usage

1. Copy this template to your project:

   ```bash
   nix flake init -t github:xavierlauzon/nix-networkd
   ```

2. Update the `flake.nix` with your specific configuration
3. Replace `"00:11:22:33:44:55"` with your actual interface MAC address
4. Adjust IP addresses and network settings as needed

## Example configurations

See the main README.md for examples of:

- Bond configurations
- Bridge setups
- VLAN configurations
- Advanced routing
