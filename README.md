# Dusky NixOS ❄️

An exhaustive, high-performance, dark/light dynamic **Hyprland** dotfiles suite and system configuration powered declaratively by **NixOS** and **Home Manager**.

![New Nerdy Horizontal Waybar](Pictures/readme_assets/waybar_horizontal.webp)

---

## 🎨 Features & Architecture

- **Window Manager**: Hyprland (configured modularly via `.lua` files in `.config/hypr/source/`).
- **Session Manager**: UWSM (Universal Wayland Session Manager) with native NixOS systemd integration.
- **Top Bar & Notifications**: Waybar (Horizontal & Vertical options) & SwayNC / Mako.
- **Dynamic Material Colors**: Matugen auto-generates accent colors from your current wallpaper across GTK, Qt, Rofi, Waybar, Vesktop, Spicetify, and Foot/Kitty.
- **Declarative System Management**: Built on Nix Flakes and Home Manager for 100% reproducible builds across machines.

---

## 💿 Installation on NixOS

### 1. Enable Nix Flakes
Ensure Flakes are enabled in your `/etc/nixos/configuration.nix` (or run using experimental flags):
```nix
nix.settings.experimental-features = [ "nix-command" "flakes" ];
```

### 2. Clone the Repository
```bash
git clone https://github.com/dusklinux/dusky.git ~/dusky
cd ~/dusky
```

### 3. Deploy NixOS System Configuration
To build and switch to the Dusky system configuration (Hyprland, SDDM, Pipewire, Bluetooth, graphics, fonts, user packages):

```bash
sudo nixos-rebuild switch --flake .#dusky
```

### 4. Deploy Home Manager Only (Optional)
If you already have a running NixOS system and only want to apply the dotfiles, user packages, and environment settings:

```bash
home-manager switch --flake .#plancton
```

---

## 📂 Repository Structure

```
dusky/
├── flake.nix                  # Nix Flake Entrypoint
├── hosts/
│   └── dusky/                 # System Configuration Module
│       ├── default.nix        # System Services, SDDM, Fonts, Audio, Users
│       └── hardware.nix       # Hardware drivers, GPU, Btrfs, Zram
├── home/                      # Home Manager Module
│   ├── default.nix            # User environment & Dotfile symlinking
│   ├── hyprland.nix           # Hyprland session variables
│   └── packages.nix           # User package definitions (Nixpkgs)
├── .config/                   # Dotfiles (Hyprland, Waybar, Rofi, Matugen, etc.)
└── user_scripts/              # Custom Dusky TUIs, Audio, and Utility scripts
```

---

## 🔄 Updating Your System & Dotfiles

To update all Nix packages to their latest versions:

```bash
cd ~/dusky
nix flake update
sudo nixos-rebuild switch --flake .#dusky
```

Press `CTRL + SHIFT + SPACE` inside Hyprland to launch the **Keybinds Cheatsheet**.
