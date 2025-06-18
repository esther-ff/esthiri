crane: nixpkgs: src: version:
{ wayland, pkg-config, eudev, pipewire, libxkbcommon, libinput, libgbm
, installShellFiles, libglvnd, libdisplay-info, pango, systemdLibs, seatd
, rustPlatform, usesSystemd ? true, usesDbus ? true, usesDinit ? false
, wantsScreencast ? true }:
let
  inherit (nixpkgs.lib) optional optionalString;
  craneLib = crane.mkLib nixpkgs;

  args = {
    inherit version;
    inherit src;

    pname = "niri";

    strictDeps = true;

    nativeBuildInputs =
      [ pkg-config rustPlatform.bindgenHook installShellFiles ];

    buildNoDefaultFeatures = true;

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
  };
in craneLib.buildPackage (args // {
  # awkward buiding magic
  # taken from sodiboo's `niri-flake`
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
      substituteInPlace resources/niri.service --replace-fail /usr/bin $out/bin     
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
})
