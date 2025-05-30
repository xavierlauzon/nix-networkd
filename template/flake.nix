{
  description = "My NixOS configuration with nix-networkd";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-networkd.url = "github:xavierlauzon/nix-networkd";
  };

  outputs = { self, nixpkgs, nix-networkd }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        nix-networkd.nixosModules.default
        {
          # Basic networking configuration
          host.network.networkd = {
            enable = true;
            # Global DHCP
            dhcp.enable = true;
          };

          # Configure specific interfaces
          host.network.interfaces.eth0 = {
            mac = "00:11:22:33:44:55";
            ipv4 = {
              addresses = [ "192.168.1.10/24" ];
              gateway = "192.168.1.1";
            };
          };
        }
      ];
    };
  };
}