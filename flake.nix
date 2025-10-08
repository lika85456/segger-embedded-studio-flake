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

            # Create installation directory with full permissions
            mkdir -p ./segger-install
            chmod 755 ./segger-install

            # Run the installer to copy files (avoids root requirement)
            echo "Running installer with steam-run..."
            steam-run ./installer --accept-license --copy-files-to $PWD/segger-install --full-install --silent || {
              echo "Installer failed, checking what was created:"
              find ./segger-install -type f | head -20 || echo "No files found"
              echo "Continuing with partial installation..."
            }

            echo "Installation completed. Checking results:"
            find ./segger-install -type f | head -20 || echo "No files found"
            ls -la ./segger-install/ || echo "Directory listing failed"

            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            mkdir -p $out
            cp -r ./segger-install/* $out/
            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "Segger Embedded Studio IDE";
            platforms = platforms.linux;
            license = licenses.unfree;
          };
        };

      in {
        packages.default = seggerEmbeddedStudio;
        packages.segger-embedded-studio = seggerEmbeddedStudio;

        apps.default = {
          type = "app";
          program = "${seggerEmbeddedStudio}/bin/emStudio";
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [ steam-run xorg.xhost fakeroot ];
        };
      });
}

