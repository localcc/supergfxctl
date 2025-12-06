{
  description = "GPU switching utility, mostly for ASUS laptops";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages = {
          supergfxctl = pkgs.rustPlatform.buildRustPackage rec {
            pname = "supergfxctl";
            version = "5.2.7";

            src = ./.;

            cargoLock = {
              lockFile = ./Cargo.lock;
            };

            postPatch = ''
              substituteInPlace data/supergfxd.service --replace /usr/bin/supergfxd $out/bin/supergfxd
              substituteInPlace data/99-nvidia-ac.rules --replace /usr/bin/systemctl ${pkgs.systemd}/bin/systemctl
            '';

            nativeBuildInputs = with pkgs; [
              pkg-config
            ];

            buildInputs = with pkgs; [
              systemd
            ];

            # upstream doesn't have tests, don't build twice just to find that out
            doCheck = false;

            postInstall = ''
              install -Dm444 -t $out/lib/udev/rules.d/ data/*.rules
              install -Dm444 -t $out/share/dbus-1/system.d/ data/org.supergfxctl.Daemon.conf
              install -Dm444 -t $out/lib/systemd/system/ data/supergfxd.service
            '';

            meta = with pkgs.lib; {
              description = "GPU switching utility, mostly for ASUS laptops";
              homepage = "https://gitlab.com/asus-linux/supergfxctl";
              license = licenses.mpl20;
              platforms = [ "x86_64-linux" ];
              maintainers = [ maintainers.k900 ];
            };
          };

          default = self.packages.${system}.supergfxctl;
        };

        devShells.default = pkgs.mkShell {
          inputsFrom = [ self.packages.${system}.supergfxctl ];
          packages = with pkgs; [
            rust-analyzer
            rustfmt
            clippy
          ];
        };
      }
    );
}
