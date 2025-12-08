# https://www.youtube.com/watch?v=rCVW8BGnYIc&ab_channel=TechSupportOnHold
{ pkgs, ... }:

{

  # Enable dconf (System Management Tool)
  programs.dconf.enable = true;

  # Add user to libvirtd group
  users.users.srghma.extraGroups = [ "libvirtd" ];

  # Install necessary packages
  environment.systemPackages = with pkgs; [
    virt-manager
    virt-viewer
    spice
    spice-gtk
    spice-protocol
    virtio-win
    win-spice
    adwaita-icon-theme
    virtiofsd
  ];

  # Manage the virtualisation services
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        swtpm.enable = true;
      };
    };
    spiceUSBRedirection.enable = true;
  };
  services.spice-vdagentd.enable = true;
  services.qemuGuest.enable = true; # clipboard?

  # sometimes
  # https://askubuntu.com/questions/1036297/cant-start-kvm-guest-network-default-is-not-active
  # sudo virsh net-start default && virt-manager
}
