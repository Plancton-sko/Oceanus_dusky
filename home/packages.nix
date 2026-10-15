{ pkgs, inputs, ... }:

let
  # ── Python com módulos necessários para os TUIs e centro de controle Dusky ──
  duskyPython = pkgs.python3.withPackages (ps: with ps; [
    rich
    textual
    pygobject3
    pycairo
    evdev
    pyudev
    pillow
    regex
    pyquery
    requests
    psutil
  ]);

  # ── Spicetify: temas e extensões para o Spotify ───────────────────────────
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.system};
in
{
  # ── Importar módulo spicetify ──────────────────────────────────────────────
  imports = [ inputs.spicetify-nix.homeManagerModules.default ];

  programs.spicetify = {
    enable = true;
    # Tema padrão: pode trocar para qualquer um em spicePkgs.themes
    theme = spicePkgs.themes.catppuccin;
    colorScheme = "mocha";
    enabledExtensions = with spicePkgs.extensions; [
      adblock
      hidePodcasts
      shuffle          # shuffle melhorado
      beautifulLyrics
    ];
  };

  home.packages = with pkgs; [
    # ── Dusky Python Environment ───────────────────────────────────────────
    duskyPython

    # ── Wayland Core & WM Utilities ───────────────────────────────────────
    waybar
    rofi-wayland
    swaync
    mako
    matugen
    hyprlock
    hypridle
    hyprpicker
    hyprpaper
    hyprsunset
    brightnessctl
    playerctl
    nwg-look
    qt5ct
    qt6ct
    papirus-icon-theme
    bibata-cursors

    # ── Screenshots & Media Captures ──────────────────────────────────────
    grim
    slurp
    satty         # anotador de screenshots (substitui swappy para marcações)
    swappy        # alternativa de screenshot editor
    swayimg       # visualizador de imagens Wayland
    wl-clipboard
    cliphist

    # ── Audio & Bluetooth TUIs/GUIs ───────────────────────────────────────
    pavucontrol
    bluetuith     # TUI de bluetooth disponível no nixpkgs
    blueman
    sox
    rnnoise
    easyeffects   # equalizer e efeitos de áudio avançados

    # ── Terminals ─────────────────────────────────────────────────────────
    kitty
    foot
    alacritty

    # ── Shell & CLI Utilities ─────────────────────────────────────────────
    starship
    fastfetch
    bat
    eza
    fd
    ripgrep
    yazi
    gum
    tree
    fzf
    zoxide
    less
    jq
    du-dust
    btop
    htop
    nvtopPackages.full
    inxi
    chafa
    bc            # calculadora de precisão arbitrária (usada em scripts)
    file          # detecta tipo de arquivos

    # ── File Managers & Archiving ─────────────────────────────────────────
    # Nota: thunar é habilitado via programs.thunar no host (com plugins e DBus)
    file-roller
    unzip
    zip
    p7zip
    rsync
    rclone        # sincronização com cloud (Google Drive, etc.)

    # ── Editors & Dev Tools ───────────────────────────────────────────────
    neovim
    git
    git-delta
    lazygit
    shellcheck
    shfmt
    stylua
    nixfmt-rfc-style  # formatador de arquivos .nix (padrão oficial)

    # ── Multimedia & Apps ─────────────────────────────────────────────────
    mpv
    imagemagick
    ffmpeg
    vesktop       # cliente Discord não-oficial com melhor suporte Wayland

    # ── NixOS-specific Helpers ────────────────────────────────────────────
    nix-tree      # visualiza dependências do nix graficamente
    comma         # executa qualquer pacote nix sem instalar: , cowsay
    manix         # busca na documentação do NixOS/nixpkgs no terminal

    # ── Substituições NixOS para ferramentas Arch ─────────────────────────
    # pacman/paru → use: nix search, nh, nix-env, etc.
    # expac       → use: nix-tree, nix path-info
    # pacseek     → use: nix search nixpkgs#<nome>
  ];
}
