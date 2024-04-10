{
  description = "OpenVPN 3 Indicator for the Systray";

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
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
                  pkgs.makeWrapper
                ];
                installPhase = ''
                  install -d $out
                  install -d $out/bin
                  install -d $out/share/applications

                  cp -R src/ $out
                  NESTO_BIN_PATH=$out/bin/openvpn3applet

                  makeWrapper "$out/src/openvpn3applet.sh" "$NESTO_BIN_PATH" \
                    --inherit-argv0 \
                    --prefix PATH : ${pkgs.lib.makeBinPath [ 
                      pkgs.yad
                    ]}

                  sed "s#@execPath@#$NESTO_BIN_PATH#" xdg-config/autostart/openvpn3-applet.desktop.in > $out/share/applications/openvpn3-applet.desktop
                '';
              };
          }
        );

      defaultPackage = forAllSystems (system: self.packages.${system}.openvpn3-applet);
    };
}
