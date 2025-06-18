{
  description = "Esthiri";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    stable-niri.url = "github:YaLTeR/niri/v25.05.1";
    unstable-niri.url = "github:YaLTeR/niri";
  };

  outputs = inputs@{ self, nixpkgs, stable-niri, ... }:
    let
      inherit (nixpkgs) lib;
      inherit (lib) optional optionalString genAttrs;

      buildNiri = src: version:
        { wayland, pkg-config, eudev, pipewire, libxkbcommon, libinput, libgbm
        , installShellFiles, libglvnd, libdisplay-info, pango, systemdLibs
        , seatd, rustPlatform, usesSystemd ? true, usesDbus ? true
        , usesDinit ? false, wantsScreencast ? true }:
        rustPlatform.buildRustPackage {
          inherit src;
          version = if version == null then "v25.05.1" else version;

          pname = "niri";

          cargoLock = {
            lockFile = "${src}/Cargo.lock";
            allowBuiltinFetchGit = true;
          };

          # passthru.providedSession = [ "niri" ];

          nativeBuildInputs =
            [ pkg-config rustPlatform.bindgenHook installShellFiles ];

          buildInputs = [
            wayland
            libglvnd
            libgbm
            libinput
            seatd
            libdisplay-info
            libxkbcommon
            pango
          ] ++ optional usesSystemd systemdLibs ++ optional (!usesSystemd) eudev
            ++ optional wantsScreencast pipewire;

          buildFeatures = optional usesDinit "dinit" ++ optional usesDbus "dbus"
            ++ optional wantsScreencast "xdp-gnome-screencast"
            ++ optional usesSystemd "systemd";

          buildNoDefaultFeatures = true;

          # awkward buiding magic
          RUSTFLAGS = [
            "-C link-arg=-Wl,--push-state,--no-as-needed"
            "-C link-arg=-lEGL"
            "-C link-arg=-lwayland-client"
            "-C link-arg=-Wl,--pop-state"
            "-C debuginfo=line-tables-only"
          ];

          postInstall = optionalString (usesSystemd || usesDinit)
          # enabled by systemd or dinit
          # as the niri-session binary requires those
            ''
              install -Dm0755 resources/niri-session -t $out/bin
              install -Dm0644 resources/niri.desktop -t $out/share/wayland-sessions
            '' + optionalString (usesDbus || wantsScreencast || usesSystemd)
            # enabled by any of those
            ''
              install -Dm0644 resources/niri-portals.conf -t $out/share/xdg-desktop-portal
            '' + optionalString usesSystemd

            # enabled by systemd
            ''
              install -Dm0644 resources/niri{-shutdown.target,.service} -t $out/lib/systemd/user

            '' + optionalString usesDinit
            # enabled by dinit
            ''
              install -Dm0644 resources/dinit/niri{,-shutdown} -t $out/lib/dinit.d/user
            '' +
            # shell completions 
            ''
              installShellCompletion --cmd niri \
                --bash <($out/bin/niri completions bash) \
                --zsh <($out/bin/niri completions zsh) \
                --fish <($out/bin/niri completions fish)
            '';

          postFixup = ''
            substituteInPlace $out/lib/systemd/user/niri.service --replace-fail /usr/bin $out/bin
          '';
        };

      genPackage = pkgs: let
        package = pkgs.callPackage (buildNiri inputs.stable-niri "25.05.1") { };
      in {
        default = package;
        niri = package;
      };

    in let
      systems = [ "x86_64-linux" ];
      forAllSystems = genAttrs systems;
    in {
      packages = forAllSystems
        (system: genPackage inputs.nixpkgs.legacyPackages.${system});
    };
}
