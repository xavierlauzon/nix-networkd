{
  description = "A NixOS module for configuring networking using systemd-networkd and Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs }: {
    nixosModules.default = import ./default.nix;

    templates = {
      default = {
        path = ./template;
        description = "Basic template for using nix-networkd module";
      };
    };
  };
}