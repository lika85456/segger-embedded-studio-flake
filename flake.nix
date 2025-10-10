{
  description = "Segger Embedded Studio development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        # Upstream downloads (see: https://www.segger.com/downloads/embedded-studio/)
        # Upstream direct tarball; site may require a Referer/User-Agent
        # See overview page: https://www.segger.com/downloads/embedded-studio/
        seggerTarball = pkgs.fetchurl {
          url =
            "https://www.segger.com/fd/embedded-studio/Setup_EmbeddedStudio_v816b_linux_x64.tar.gz";
          sha256 = "sha256-+uIVnfRQg4WqDLNSdKwDUPQMKJLm2uf8wEJMac5Y430=";
        };

        seggerEmbeddedStudio = pkgs.stdenv.mkDerivation rec {
          pname = "segger-embedded-studio";
          version = "8.16b";

          src = seggerTarball;

          nativeBuildInputs = with pkgs; [ autoPatchelfHook steam-run ];

          buildInputs = with pkgs; [
            glibc
            libGL
            libGLU
            xorg.libX11
            xorg.libXext
            xorg.libXi
            xorg.libXrender
            xorg.libXrandr
            xorg.libXfixes
            xorg.libXcursor
            xorg.libXinerama
            xorg.libXdamage
            xorg.libXcomposite
            fontconfig
            freetype
            zlib
            libusb1
            stdenv.cc.cc.lib
          ];

          dontUnpack = false;

          unpackCmd = "tar -xzf $src";

          buildPhase = ''
            runHook preBuild

            echo "Unpacked SEGGER tarball; running installer"

            # Find the installer inside the extracted contents
            installerPath=$(find . -maxdepth 2 -type f -name 'install_segger_embedded_studio' | head -n1)
            if [ -z "$installerPath" ]; then
              echo "Installer not found in tarball contents" >&2
              exit 1
            fi
            chmod +x "$installerPath"

            mkdir -p segger-install

            echo "Running installer with steam-run..."
            ${pkgs.steam-run}/bin/steam-run "$installerPath" --accept-license --copy-files-to "$PWD/segger-install" --full-install --silent

            runHook postBuild
          '';

          installPhase = ''
            mkdir -p $out/segger-install
            cp -r ./segger-install/* $out/segger-install/

            mkdir -p $out/bin
            cat > $out/bin/ses <<EOF
            #!${pkgs.bash}/bin/bash
            exec ${pkgs.steam-run}/bin/steam-run "$out/segger-install/bin/emStudio" "\$@"
            EOF
            chmod +x $out/bin/ses
          '';

          meta = with pkgs.lib; {
            description = "Segger Embedded Studio IDE";
            platforms = platforms.linux;
            license = licenses.unfree;
          };
        };
      in {
        packages.default = seggerEmbeddedStudio;
        packages.ses = seggerEmbeddedStudio;

        apps.ses = flake-utils.lib.mkApp {
          drv = seggerEmbeddedStudio;
          exePath = "/bin/ses";
        };
        apps.default = flake-utils.lib.mkApp {
          drv = seggerEmbeddedStudio;
          exePath = "/bin/ses";
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [ steam-run xorg.xhost fakeroot ];
        };
      });
}

