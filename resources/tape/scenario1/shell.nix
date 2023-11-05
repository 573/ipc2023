{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/4ab8a3de296914f3b631121e9ce3884f1d34e1e5.tar.gz") {} }:

pkgs.mkShellNoCC {
  packages = [
    pkgs.vhs
    pkgs.php.packages.composer
    pkgs.tmux
    pkgs.asciinema
  ];
}
