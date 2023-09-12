{
  description = "OpenVPN 3 Indicator for the Systray";

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs, nur }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {

      # Provide some binary packages for selected system types.
      packages = forAllSystems
        (system:
          let
            pkgs = import nixpkgs {
              inherit system;
            };
          in
          {
            openvpn3-applet = pkgs.stdenv.mkDerivation
              {
                name = "openvpn3-applet";
                src = ./.;
                nativeBuildInputs = [
                  pkgs.yad
                ];
                installPhase = ''
                  install -d $out
                  install -d $out/bin
                  install -d $out/share/applications

                  cp -R src/ $out
                  ln -s $out/src/openvpn3applet.sh $out/bin/openvpn3applet

                  NESTO_BIN_PATH=$out/bin/openvpn3applet
                  sed "s#@execPath@#$NESTO_BIN_PATH#" xdg-config/autostart/openvpn3-applet.desktop.in > $out/share/applications/openvpn3-applet.desktop
                '';
              };
          }
        );

      defaultPackage = forAllSystems (system: self.packages.${system}.openvpn3-applet);
    };
}
