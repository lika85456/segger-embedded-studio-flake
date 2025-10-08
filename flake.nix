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

        seggerEmbeddedStudio = pkgs.stdenv.mkDerivation rec {
          pname = "segger-embedded-studio";
          version = "8.16b";

          src = ./install_segger_embedded_studio;

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

          dontUnpack = true;

          buildPhase = ''
            runHook preBuild

            echo "Running SEGGER Embedded Studio installer"

            # Copy installer and make it executable
            cp $src ./installer
            chmod +x ./installer

            # Create installation directory
            mkdir -p ./segger-install

            # Run the installer to copy files (avoids root requirement)
            echo "Running installer with steam-run..."
            ${pkgs.steam-run}/bin/steam-run ./installer --accept-license --copy-files-to $PWD/segger-install --full-install --silent

            runHook postBuild
          '';

          installPhase = ''
            mkdir -p $out/segger-install
            cp -r ./segger-install/* $out/segger-install/

            mkdir -p $out/bin
            cat > $out/bin/ses <<EOF
            #!${pkgs.bash}/bin/bash
            exec ${pkgs.steam-run}/bin/steam-run "$out/segger-install/bin/emStudio" "$@"
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

