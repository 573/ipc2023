{
  description = "IPC 2023 document";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
    typst-dev.url = "github:typst/typst";
    typst-packages = {
      flake = false;
      url = "github:typst/packages";
    };
    bamboovir = {
      url = "github:bamboovir/typst-resume-template"; #?narHash=sha256-WxvEyIRu322YIwBpv9iVHR6YcA46h2kPz9dZB0aTMT0=";
      flake = false;
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
    };
  };

  outputs = inputs @ { self, flake-parts, typst-dev, ... }: flake-parts.lib.mkFlake { inherit inputs; } {
    systems = import inputs.systems;

    perSystem = { config, self', inputs', pkgs, system, lib, ... }:
      let
        typst = pkgs.typst;
        typst-packages = pkgs.callPackage ./nix/typst-packages.nix { src = inputs.typst-packages; };
        bamboovir = pkgs.callPackage ./nix/bamboovir.nix { src =
        inputs.bamboovir; formattoml = pkgs.formats.toml { }; };

        fontsConf = pkgs.symlinkJoin {
          name = "typst-fonts";
          paths = [
            pkgs.source-sans-pro
            pkgs.roboto
          ];
        };

        mkBuildDocumentDrv = documentName: pkgs.stdenvNoCC.mkDerivation {
          name = "build-" + documentName;

          src = pkgs.lib.cleanSource ./.;

          buildInputs = [
            typst
          ];

          XDG_CACHE_HOME = typst-packages;
          XDG_DATA_HOME = "${bamboovir.outPath}";

          buildPhase = ''
            runHook preBuild

            ${lib.getExe typst} \
              compile \
              --root ./. \
              --font-path ${fontsConf} \
              ./src/${documentName}/resume.typ \
              ${documentName}.pdf

            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall

            mkdir -p $out
            cp ${documentName}.* $out/

            runHook postInstall
          '';
        };

        mkBuildDocumentScript = documentName: pkgs.writeShellApplication {
          name = "build-${documentName}";
          runtimeInputs = [
            typst
          ];

          text = ''
            export XDG_CACHE_HOME=${typst-packages}
            export XDG_DATA_HOME=${bamboovir}

            ${lib.getExe typst} \
              compile \
              --root ./. \
              --font-path ${fontsConf} \
              ./src/${documentName}/resume.typ \
              ${documentName}.pdf
          '';
        };

        mkWatchDocumentScript = documentName: pkgs.writeShellApplication {
          name = "watch-${documentName}";
          runtimeInputs = [
            typst
          ];
          text = ''
            export XDG_CACHE_HOME=${typst-packages}
            export XDG_DATA_HOME=${bamboovir}

            ${lib.getExe typst} \
              watch \
              --root ./. \
              --font-path ${fontsConf} \
              ./src/${documentName}/resume.typ \
              ${documentName}.pdf

            ${pkgs.inotify-tools}/bin/inotifywait --exclude '\.pdf|\.git' -qre close_write .; \
          '';
        };

        documentNames = (lib.attrNames (lib.filterAttrs (k: v: (v == "directory")) (builtins.readDir ./src)));

        documentDrvs = lib.foldl'
          (a: i: a // {
            "${i}" = mkBuildDocumentDrv i;
          })
          { }
          documentNames;

        scriptDrvs = lib.foldl'
          (a: i: a // {
            "build-${i}" = mkBuildDocumentScript i;
            "watch-${i}" = mkWatchDocumentScript i;
          })
          { }
          documentNames;
      in
      {
        _module.args.pkgs = import self.inputs.nixpkgs {
          inherit system;
          overlays = [
            typst-dev.overlays.default
          ];
        };

        formatter = pkgs.nixpkgs-fmt;

        packages = documentDrvs;

        devShells.default = pkgs.mkShellNoCC {
          name = "typst-devshell";
          buildInputs = (lib.attrValues scriptDrvs) ++ [
            typst
            typst-packages
            bamboovir
            pkgs.typst-fmt
          ];
        };
      };
  };
}
