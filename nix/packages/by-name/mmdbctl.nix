{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
}:

buildGoModule rec {
  pname = "mmdbctl";
  version = "1.5.1";

  src = fetchFromGitHub {
    owner = "ipinfo";
    repo = "mmdbctl";
    rev = "mmdbctl-${version}";
    hash = "sha256-5b7iHeR93afErMZLKbHVgDGVNHjK/QoUDhsX4v1vl8A=";
  };

  vendorHash = "sha256-vWb0K79p6F2r/qUgVDh9BBaKix2VM6hv4sK9oHIrHT4=";

  doCheck = true;

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--flake"
      "--version-regex"
      "mmdbctl-(.*)"
    ];
  };

  meta = {
    description = "MMDB file management CLI";
    homepage = "https://github.com/ipinfo/mmdbctl";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ midchildan ];
  };
}
