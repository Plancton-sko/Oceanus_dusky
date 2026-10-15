{ config, pkgs, inputs, ... }:

{
  imports = [
    ./packages.nix
    ./hyprland.nix
  ];

  home.username = "plancton";
  home.homeDirectory = "/home/plancton";
  home.stateVersion = "24.11";

  # Permite pacotes unfree (Spotify, Discord, etc.) tanto no NixOS quanto no standalone Home Manager
  # nixpkgs.config.allowUnfree = true;

  # ── Home Manager instala e gerencia a si mesmo ────────────────────────────
  programs.home-manager.enable = true;

  # ── ZSH: integração com os dotfiles do Dusky ──────────────────────────────
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    # Carrega o .zshrc customizado do Dusky (em .config/zshrc/.zshrc)
    initContent = ''
      if [ -f "$HOME/.config/zshrc/.zshrc" ]; then
        source "$HOME/.config/zshrc/.zshrc"
      fi
    '';
  };

  # ── Git ───────────────────────────────────────────────────────────────────
  programs.git.enable = true;

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };

  # ── Systemd User Services (declarativo, idiomático no Nix) ───────────────
  # O hyprland-session.target já existe como arquivo symlinked via xdg.configFile
  # abaixo. Deixamos o arquivo bruto funcionar normalmente — é mais flexível
  # para os scripts Lua do Hyprland que fazem `systemctl --user start`.

  # Serviço de clipboard (wl-clipboard + cliphist)
  systemd.user.services.dusky-clipboard = {
    Unit = {
      Description = "Dusky Clipboard Manager (wl-paste → cliphist)";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.cliphist}/bin/cliphist store";
      Restart = "on-failure";
      RestartSec = "3s";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  # ── XDG: Configurações de aplicações padrão ─────────────────────────────
  xdg = {
    enable = true;

    userDirs = {
      enable = true;
      createDirectories = true;
      setSessionVariables = true;

      desktop = "${config.home.homeDirectory}/Desktop";
      documents = "${config.home.homeDirectory}/Documents";
      download = "${config.home.homeDirectory}/Downloads";
      music = "${config.home.homeDirectory}/Music";
      pictures = "${config.home.homeDirectory}/Pictures";
      videos = "${config.home.homeDirectory}/Videos";
      templates = "${config.home.homeDirectory}/Templates";
      publicShare = "${config.home.homeDirectory}/Public";
    };

    # Symlinks dos dotfiles para ~/.config/
    configFile = {
      "hypr".source = ../.config/hypr;
      "waybar".source = ../.config/waybar;
      "rofi".source = ../.config/rofi;
      "mako".source = ../.config/mako;
      "wlogout".source = ../.config/wlogout;
      "swappy".source = ../.config/swappy;
      "xdg-desktop-portal".source = ../.config/xdg-desktop-portal;

      "matugen".source = ../.config/matugen;
      "gtk-3.0".source = ../.config/gtk-3.0;
      "gtk-4.0".source = ../.config/gtk-4.0;
      "qt5ct".source = ../.config/qt5ct;
      "qt6ct".source = ../.config/qt6ct;
      "Kvantum".source = ../.config/Kvantum;
      "xsettingsd".source = ../.config/xsettingsd;

      "kitty".source = ../.config/kitty;
      "foot".source = ../.config/foot;
      "alacritty".source = ../.config/alacritty;

      "starship.toml".source = ../.config/starship.toml;
      "zshrc".source = ../.config/zshrc;

      "btop".source = ../.config/btop;
      "cava".source = ../.config/cava;
      "mpv".source = ../.config/mpv;
      "yazi".source = ../.config/yazi;
      "zathura".source = ../.config/zathura;
      "zellij".source = ../.config/zellij;
      "obs-studio".source = ../.config/obs-studio;

      "dusky".source = ../.config/dusky;
      "dusky_nvim".source = ../.config/dusky_nvim;
      "dusky_sites".source = ../.config/dusky_sites;

      "systemd/user/hyprland-session.target".source =
        ../.config/systemd/user/hyprland-session.target;
      "systemd/user/swaync.service.d".source =
        ../.config/systemd/user/swaync.service.d;

      "mimeapps.list".source = ../.config/mimeapps.list;
      "autostart".source = ../.config/autostart;
      "desktop_entries".source = ../.config/desktop_entries;
    };

    # Mantém o mimeapps.list personalizado, sem gerar outro arquivo
    mimeApps.enable = false;
  };

  # ── Arquivos no home directory ───────────────────────────────────────────
  home.file = {
    "user_scripts" = {
      source = ../user_scripts;
      recursive = true;
    };
  };
}

