{
  # config,
  pkgs,
  # lib,
  ...
}:

let
  sshKeyDir = "/tmp/testuservm-keys";
  sshKey = "${sshKeyDir}/id_ed25519";
  vmPort = 2222;
  spicePort = 5930;
  stateDir = "/home/srghma/.local/share/testuservm";
  targetHome = "${stateDir}/testuser";
  pidFile = "${stateDir}/qemu.pid";

  # ---------------------------------------------------------
  # Guest NixOS System Configuration
  # ---------------------------------------------------------
  guestSystem = import "${pkgs.path}/nixos" {
    system = pkgs.stdenv.hostPlatform.system;
    configuration = { ... }: {
      imports = [
        "${pkgs.path}/nixos/modules/virtualisation/qemu-vm.nix"
        (import ./shared-packages.nix { inherit pkgs; })
        ./shared-default.nix
        ./nushell/default.nix
      ];

      system.stateVersion = "26.11";
      boot.loader.grub.enable = false;

      fileSystems."/home/testuser" = {
        device = "home-testuser";
        fsType = "9p";
        options = [
          "rw"
          "trans=virtio"
          "version=9p2000.L"
        ];
      };

      virtualisation = {
        memorySize = 6144;
        cores = 4;
        # NATIVE NIXOS PORT FORWARD: Attaches to the primary eth0 interface
        forwardPorts = [
          {
            from = "host";
            host.port = vmPort;
            guest.port = 22;
          }
        ];
        qemu.options = [
          "-vga"
          "qxl"
          "-spice"
          "port=${toString spicePort},disable-ticketing=on"
          "-device"
          "virtio-serial-pci"
          "-device"
          "virtserialport,chardev=spicechannel0,name=com.redhat.spice.0"
          "-chardev"
          "spicevmc,id=spicechannel0,name=vdagent"
        ];
      };

      services.xserver = {
        enable = true;
        desktopManager.xfce.enable = true;
        displayManager.lightdm.enable = true;
        displayManager.sessionCommands = ''
          ${pkgs.xkbcomp}/bin/xkbcomp ${../../layouts/en_ua_swapped} $DISPLAY
        '';
      };

      services.displayManager.autoLogin = {
        enable = true;
        user = "testuser";
      };

      services.spice-vdagentd.enable = true;
      services.qemuGuest.enable = true;

      services.openssh = {
        enable = true;
        settings = {
          PermitRootLogin = "no";
          PasswordAuthentication = false;
          X11Forwarding = true;
          StrictModes = false;
        };
      };

      users.defaultUserShell = pkgs.nushell;
      users.users.testuser = {
        isNormalUser = true;
        uid = 1001;
        extraGroups = [
          "wheel"
          "video"
          "audio"
        ];
      };

      security.sudo.wheelNeedsPassword = false;
    };
  };

  vmRunner = guestSystem.config.system.build.vm;

  # ---------------------------------------------------------
  # Host CLI Helper Scripts
  # ---------------------------------------------------------
  testuservm-status = pkgs.writeShellScriptBin "testuservm-status" ''
    if ${pkgs.openssh}/bin/ssh -q -i "${sshKey}" -o ConnectTimeout=1 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p ${toString vmPort} testuser@127.0.0.1 true 2>/dev/null; then
      echo "🟢 TestUser VM is RUNNING & SSH READY (SSH: ${toString vmPort}, SPICE GUI: ${toString spicePort})"
    elif ${pkgs.procps}/bin/pgrep -f "qemu-system-x86_64.*${toString vmPort}" > /dev/null; then
      echo "🟡 TestUser VM is BOOTING..."
    else
      echo "🔴 TestUser VM is STOPPED"
    fi
  '';

  testuservm-start = pkgs.writeShellScriptBin "testuservm-start" ''
    set -e
    mkdir -p ${sshKeyDir}
    if [ ! -f "${sshKey}" ]; then
      ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -N "" -f "${sshKey}"
    fi

    # Check if VM is already up and SSH ready
    if ${pkgs.openssh}/bin/ssh -q -i "${sshKey}" -o ConnectTimeout=1 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p ${toString vmPort} testuser@127.0.0.1 true 2>/dev/null; then
      exit 0
    fi

    # If QEMU is not running at all, start it
    if ! ${pkgs.procps}/bin/pgrep -f "qemu-system-x86_64.*${toString vmPort}" > /dev/null; then
      echo "Preparing ${targetHome} and syncing 🤝 safe dotfiles..."
      mkdir -p "${targetHome}/projects"
      mkdir -p "${targetHome}/.ssh"
      mkdir -p "${stateDir}"

      cat "${sshKey}.pub" > "${targetHome}/.ssh/authorized_keys"
      chmod 700 "${targetHome}/.ssh"
      chmod 600 "${targetHome}/.ssh/authorized_keys"

      ${pkgs.python3}/bin/python3 /home/srghma/.dotfiles/INSTALL/link_files__copy_safe_files_to_testuser.py "${targetHome}"

      chmod 770 "${targetHome}"

      echo "Starting TestUser VM..."
      cd "${stateDir}"

      # Use nohup so Ctrl+C in your terminal won't kill QEMU
      QEMU_OPTS="-virtfs local,path=${targetHome},mount_tag=home-testuser,security_model=none" \
        nohup ${vmRunner}/bin/run-*-vm > "${stateDir}/vm.log" 2>&1 &

      echo $! > "${pidFile}"
    fi

    echo "Waiting for VM to finish booting and SSH to become ready..."
    while ! ${pkgs.openssh}/bin/ssh -q -i "${sshKey}" -o ConnectTimeout=1 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p ${toString vmPort} testuser@127.0.0.1 true 2>/dev/null; do
      sleep 1
    done
    echo "TestUser VM is ready!"
  '';

  testuservm-connect = pkgs.writeShellScriptBin "testuservm-connect" ''
    ${testuservm-start}/bin/testuservm-start
    ${pkgs.virt-viewer}/bin/remote-viewer spice://127.0.0.1:${toString spicePort} &
  '';

  testuservm-enter = pkgs.writeShellScriptBin "testuservm-enter" ''
    ${testuservm-start}/bin/testuservm-start
    ${pkgs.openssh}/bin/ssh \
      -t \
      -i "${sshKey}" \
      -o StrictHostKeyChecking=no \
      -o UserKnownHostsFile=/dev/null \
      -p ${toString vmPort} \
      -Y \
      testuser@127.0.0.1
  '';

  testuservm-enter-wezterm = pkgs.writeShellScriptBin "testuservm-enter-wezterm" ''
    ${testuservm-start}/bin/testuservm-start
    ${pkgs.wezterm}/bin/wezterm start --always-new-process -- ${pkgs.openssh}/bin/ssh \
      -t \
      -i "${sshKey}" \
      -o StrictHostKeyChecking=no \
      -o UserKnownHostsFile=/dev/null \
      -p ${toString vmPort} \
      -Y \
      testuser@127.0.0.1
  '';

  testuservm-stop = pkgs.writeShellScriptBin "testuservm-stop" ''
    echo "Shutting down TestUser VM..."
    if [ -f "${pidFile}" ]; then
      kill -9 $(cat "${pidFile}") 2>/dev/null || true
      rm -f "${pidFile}"
    fi
    ${pkgs.procps}/bin/pkill -9 -f "qemu-system-x86_64.*${toString vmPort}" || true
    ${pkgs.procps}/bin/pkill -9 -f "run-.*-vm" || true
    echo "VM stopped."
  '';

in
{
  environment.systemPackages = [
    testuservm-status
    testuservm-start
    testuservm-connect
    testuservm-enter
    testuservm-enter-wezterm
    testuservm-stop
    pkgs.virt-viewer
  ];
}
