{ pkgs, ... }:

# sudo mkdir -p /etc/secrets
# mkpasswd -m yescrypt | sudo tee /etc/secrets/user-password
# sudo chmod 600 /etc/secrets/user-password

{
  mutableUsers = false;

  defaultUserShell = pkgs.nushell;

  extraUsers = {
    root = {
      hashedPasswordFile = "/etc/secrets/user-password";
    };

    testuser = {
      isNormalUser = true;
      description = "Interview Test Account";
      # Only provide audio/video if needed for desktop display
      extraGroups = [
        # "video"
        # "audio"
      ];

      # "!" disables password login completely (sudo -u needs no password)
      hashedPassword = "!";

      # packages = with pkgs; [
      #   # vscode
      #   # nodejs_22
      #   # Add fhs wrapper or steam-run so solc binaries work
      #   # steam-run
      # ];
    };

    srghma = {
      isNormalUser = true;
      description = "Serhii Khoma";

      extraGroups = [
        "audio"
        "video"
        "disk"
        "wheel"
        "networkmanager"
        "docker"
        "vboxusers"
        "libvirtd" # qemu
        # "user-with-access-to-virtualbox"
        "dialout"

        # https://nixos.wiki/wiki/Android
        "adbusers"
        "kvm"
        # "testuser"
      ];
      hashedPasswordFile = "/etc/secrets/user-password";
    };
  };
}
