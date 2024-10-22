{ stdenvNoCC
, src
, formattoml
}:

stdenvNoCC.mkDerivation rec {
  inherit src;

  name = "bamboovir";
  version = "0.0.1";

  dontBuild = true;

  # https://github.com/typst/packages#local-packages
  toml = formattoml.generate "tomlfile" {
    package = {
      name = "bamboovir";
      version = "0.0.1";
      entrypoint = "templates/awesome/template.typ";
      authors = ["Huiming Sun"];
      license = "MIT";
      description = "A simple resume template for typst.app.";
      repository = "https://github.com/bamboovir/typst-resume-template";
      exclude = ["assets/image" "resume.typ" "resume.pdf" "huiming-sun-sde-resume.pdf"];
    };

    template = {
      path = "templates/awesome";
      entrypoint = "templates/awesome/resume.typ";
    };
  };

  installPhase = let name = "bamboovir"; version = "0.0.1"; in ''
    runHook preInstall

    mkdir -p $out/typst/packages/local/${name}/${version}
    cp -r * $out/typst/packages/local/${name}/${version}
    cp ${toml} $out/typst/packages/local/${name}/${version}/typst.toml

    runHook postInstall
  '';
}
