{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # ── Kernel modules (AMD CPU + NVMe + USB) ────────────────────────────────
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];
  services.xserver.videoDrivers = [ "amdgpu" ];

  # ── Filesystems (LUKS-encrypted ext4 + EFI) ──────────────────────────────
  fileSystems."/" = {
    device = "/dev/mapper/luks-ad965f77-d580-43af-ab1f-ef7e5643ae27";
    fsType = "ext4";
  };

  boot.initrd.luks.devices."luks-ad965f77-d580-43af-ab1f-ef7e5643ae27".device =
    "/dev/disk/by-uuid/ad965f77-d580-43af-ab1f-ef7e5643ae27";

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/DE06-42CD";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = [
    { device = "/dev/mapper/luks-6fe41ff0-532d-437b-b962-8c861e98791a"; }
  ];

  # ── Graphics / Hardware Acceleration ─────────────────────────────────────
  # AMD GPU: use amdgpu with VAAPI/Vulkan support
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      vulkan-loader
      vulkan-validation-layers
      vulkan-extension-layer
      libvdpau-va-gl  
    ];
  };

  # ── CPU microcode ─────────────────────────────────────────────────────────
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
