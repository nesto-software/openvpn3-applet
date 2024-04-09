# openvpn3-applet (for Linux)

This tool exists because NetworkManager does not support OpenVPN 3 yet, see [issue #69 in the official OpenVPN repository](https://gitlab.gnome.org/GNOME/NetworkManager-openvpn/-/issues/69).
We wrote this applet as we want to connect to the OpenVPN CloudConnexa offering which prompts the user to follow an authentication flow in the browser.

**This applet currently supports SAML authentication only. PR to support more auth methods welcome.**
**You need to set a default browser, e.g. using the BROWSER env variable.**

**Update: There is a new official project by OpenVPN: [openvpn3-indicator](https://github.com/OpenVPN/openvpn3-indicator) which has better dbus and gnome integration and is hopefully better maintained overall.**

## Prerequisites:
* openvpn3-linux (https://github.com/OpenVPN/openvpn3-linux)
  * Debian/Ubuntu: https://openvpn.net/cloud-docs/openvpn-3-client-for-linux/#installation-for-debian-and-ubuntu
  * Arch: https://aur.archlinux.org/packages/openvpn3
  * Red Hat/Centos: https://openvpn.net/cloud-docs/openvpn-3-client-for-linux/#installation-for-fedora-red-hat-enterprise-linux-centos-or-scientific-linux
* yad (https://github.com/v1cont/yad)
  * Debian/Ubuntu: https://wiki.ubuntuusers.de/yad/
  * Arch: https://archlinux.org/packages/community/x86_64/yad/

## Install (NixOS)

`nix profile install 'git+https://github.com/nesto-software/openvpn3-applet'`

You can then add the `openvpn3-applet.desktop` to your desktop manager's autostart config, e.g. for a working GNOME config using home-manager:

```
let
  openvpn3-applet-pkg = openvpn3-applet.defaultPackage.${system};
in
 home-manager.users.your-user = { lib, pkgs, ... }: {
    home = {
      file = {
        ".config/autostart/openvpn3-applet.desktop" = {
          source = (openvpn3-applet-pkg + "/share/applications/openvpn3-applet.desktop");
          target = ".config/autostart/openvpn3-applet.desktop";
        };
      };
      packages = [
        openvpn3-applet-pkg
      ];
    };
};
```

Note: You need to pass the applet's flake as `openvpn3-applet` and the `system`.

## Install (others)

- Download the script: `git clone https://github.com/nesto-software/openvpn3-applet.git /tmp/openvpn3-applet`
- Install the script: `cp -R /tmp/openvpn3-applet/src/. ~/.openvpn3-applet`
- Add to autostart: `cp /tmp/openvpn3-applet/xdg-config/autostart/openvpn3-applet.desktop ~/.config/autostart/`

Note: Your desktop environment must support [XDG Autostart](https://wiki.archlinux.org/title/XDG_Autostart) for this to work.

Alternatively, to start the applet manually, launch the script: `~/.openvpn3-applet/openvpn3applet.sh`.

To run the script on XWayland, set the environment variable: `GDK_BACKEND=x11`.

## Limitations

We currently support one concurrent connection. Only click "connect" once and wait for the browser to open.
Otherwise, the applet attempts to open a second session which is unintended and will be fixed in the future.


## Preview

### Icon shows connection status
- red -> disconnected   
- green -> connected   
- blue -> connecting   

![OpenVPN3-Applet](assets/icon-red.png)

### Popup Menu to manage the connection when clicking on the icon
![OpenVPN3-Applet](assets/menu1.png)
![OpenVPN3-Applet](assets/menu2.png)

### Applet controls the openvpn3 binary which opens the browser for sso
![OpenVPN3-Applet](assets/sso.png)

## Author

`Caro <caroline.hemberger@nesto-software.de>`

License: MIT

## Contributors

- `Martin <martin.loeper@nesto-software.de>`
- Feel free to open an issue or PR if you have any proposal...
