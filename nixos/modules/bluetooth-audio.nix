{ config, lib, pkgs, modulesPath, inputs, settings, localpkgs, ... }:

{
  # Enable Bluetooth
  hardware.bluetooth.enable = lib.mkForce true;
  # Enable sound.
  sound.enable = true;

  # environment.etc = {
  #   "wireplumber/bluetooth.lua.d/51-bluez-config.lua".text = ''
  #     bluez_monitor.properties = {
  #       ["bluez5.enable-sbc-xq"] = true,
  #       ["bluez5.enable-msbc"] = true,
  #       ["bluez5.enable-hw-volume"] = true,
  #       ["bluez5.headset-roles"] = "[ hsp_hs hsp_ag hfp_hf hfp_ag ]"
  #     }
  #   '';
  # };

  services.pipewire.wireplumber.extraConfig = {
    "monitor.bluez.properties" = {
      "bluez5.enable-sbc-xq" = true;
      "bluez5.enable-msbc" = true;
      "bluez5.enable-hw-volume" = true;
      "bluez5.roles" = [ "hsp_hs" "hsp_ag" "hfp_hf" "hfp_ag" ];
    };
  };

  # - Using PipeWire as the sound server conflicts with PulseAudio. This option requires `hardware.pulseaudio.enable` to be set to false
  # hardware.pulseaudio.enable = lib.mkForce true;
  # hardware.pulseaudio.extraConfig = "
  #   load-module module-switch-on-connect
  # ";

  services.blueman.enable = true;
}
