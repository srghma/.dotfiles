{ config, lib, pkgs, modulesPath, inputs, settings, localpkgs, ... }:
{
  ## this config also hosts gnome-network-displays and its variables
  #environment.sessionVariables = {
  #  NETWORK_DISPLAYS_H264_ENC = "openh264enc";
  #};
  #services.dbus.packages = [
  #  pkgs.miraclecast
  #  #localpkgs.miraclecast
  #];
  #environment.systemPackages = with pkgs; [
  #  iw
  #  gst_all_1.gstreamer
  #  gst_all_1.gst-plugins-base
  #  gst_all_1.gst-plugins-good
  #  gst_all_1.gst-plugins-bad
  #  gst_all_1.gst-plugins-ugly
  #  gst_all_1.gst-libav
  #  gst_all_1.gst-vaapi
  #  gst_all_1.gst-rtsp-server
  #  avahi.dev
  #] ++ [
  #  pkgs.miraclecast
  #  pkgs.gnome-network-displays
  #  #localpkgs.miraclecast
  #];

  #services.avahi.enable = true;

  ##########
  # services.teamviewer.enable = true;
  # environment.systemPackages = with pkgs; [
  #   teamviewer
  # ];

  #######
  # nix-shell -p scrcpy adb
  # adb devices
  # scrcpy
}
