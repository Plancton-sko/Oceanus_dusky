{ config, pkgs, ... }:

let
  sddm-astronaut-theme = pkgs.sddm-astronaut.override {
    embeddedTheme = "pixel_sakura";
  };
in
{
  imports = [
    ./hardware.nix
  ];

  # ── Bootloader (UEFI systemd-boot) ───────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 3;

  # ── Plymouth Boot Splash ──────────────────────────────────────────────────
  boot.plymouth = {
    enable = true;
    theme = "lone";
    themePackages = [
      (pkgs.adi1090x-plymouth-themes.override {
        selected_themes = [ "lone" ];
      })
    ];
  };

  # ── Networking ────────────────────────────────────────────────────────────
  networking.hostName = "dusky";
  networking.networkmanager.enable = true;

  # ── Timezone & Locale ─────────────────────────────────────────────────────
  time.timeZone = "America/Sao_Paulo";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_TIME = "pt_BR.UTF-8";  # datas/horas em formato brasileiro
  };

  # ── Nix Settings ──────────────────────────────────────────────────────────
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };
  nixpkgs.config.allowUnfree = true;

  # ── Hyprland WM with UWSM ─────────────────────────────────────────────────
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  # ── Display Manager — SDDM (Wayland) ─────────────────────────────────────
  services.xserver.enable = true;
  qt.enable = true;
  services.displayManager.sddm = {
    package = pkgs.kdePackages.sddm;
    enable = true;
    theme = "sddm-astronaut-theme";
    wayland.enable = true;
    extraPackages = with pkgs; [
      sddm-astronaut-theme
      kdePackages.qtmultimedia
      kdePackages.qtsvg
      kdePackages.qtvirtualkeyboard
    ];
  };
  services.displayManager.defaultSession = "hyprland-uwsm";

  # ── XDG Desktop Portal ────────────────────────────────────────────────────
  # Required for: screen sharing, file pickers, clipboard, notifications
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ];
    # Let Hyprland portal be the default for Wayland; GTK portal as fallback
    config.common.default = "*";
  };

  # ── Audio — PipeWire ──────────────────────────────────────────────────────
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    # wireplumber is the default session manager in NixOS 24.11+
    wireplumber.enable = true;
  };

  # ── Bluetooth ─────────────────────────────────────────────────────────────
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings.Policy.AutoEnable = "true";
  };
  services.blueman.enable = true;

  # ── Power & Hardware Services ─────────────────────────────────────────────
  services.tlp.enable = true;
  services.upower.enable = true;
  services.udisks2.enable = true;
  zramSwap.enable = true;

  # ── Security & Authentication ─────────────────────────────────────────────
  security.polkit.enable = true;
  security.pam.services.hyprlock = {};

  # Gnome Keyring: armazena senhas para VSCode, browsers, SSH agent, etc.
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;
  security.pam.services.sddm.enableGnomeKeyring = true;

  # ── File Manager — Thunar ─────────────────────────────────────────────────
  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-archive-plugin
      thunar-volman
    ];
  };
  # GVFS: monta SMB/MTP/FTP/etc no Thunar
  services.gvfs.enable = true;
  # Tumbler: gerador de thumbnails para Thunar
  services.tumbler.enable = true;

  # ── GTK / dconf ───────────────────────────────────────────────────────────
  # Necessário para temas GTK4 e configurações GNOME funcionarem no Hyprland
  programs.dconf.enable = true;

  # ── Nix-ld: Compatibilidade com binários dinâmicos ────────────────────────
  # Permite executar binários pré-compilados (scripts Python com extensões C,
  # binários AUR equivalentes, appimages, etc.) sem quebrar no NixOS
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib
      zlib
      fuse3
      curl
      openssl
    ];
  };

  # ── Shell ─────────────────────────────────────────────────────────────────
  programs.zsh.enable = true;

  # ── User Account ──────────────────────────────────────────────────────────
  users.users.plancton = {
    isNormalUser = true;
    description = "Dusky User";
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
      "input"
      "storage"
      "disk"
      "libvirtd"  # para dusky_vm scripts
    ];
    shell = pkgs.zsh;
  };

  # ── Typography & Fonts ────────────────────────────────────────────────────
  fonts = {
    packages = with pkgs; [
      jetbrains-mono
      nerd-fonts.jetbrains-mono
      nerd-fonts.noto
      font-awesome
      noto-fonts
      noto-fonts-color-emoji
      liberation_ttf
      atkinson-hyperlegible
    ];
    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [ "JetBrainsMono Nerd Font" "JetBrains Mono" ];
        sansSerif = [ "Atkinson Hyperlegible" "Noto Sans" ];
        serif = [ "Liberation Serif" "Noto Serif" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };

  # ── Essential System Packages ─────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    sddm-astronaut-theme
    git
    curl
    wget
    pciutils
    usbutils
    efibootmgr
    psmisc
    lm_sensors
    python3
    # Utilitários NixOS
    nix-output-monitor  # melhor output do nixos-rebuild
    nh                  # helper CLI para NixOS (nh os switch, nh home switch)
    nvd                 # diff de gerações do Nix
  ];

  # ── Virtualização (para dusky_vm scripts) ─────────────────────────────────
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  system.stateVersion = "24.11";
}
