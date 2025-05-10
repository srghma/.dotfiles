{
  config,
  pkgs,
  ...
}:
let
  # mypkgs = pkgs.nixpkgsMaster.pkgs;
  mypkgs = pkgs;

  obs = mypkgs.wrapOBS {
    plugins = with mypkgs.obs-studio-plugins; [
      advanced-scene-switcher
      obs-pipewire-audio-capture
      # droidcam-obs
      obs-shaderfilter
      obs-composite-blur
      obs-vintage-filter
      # input-overlay
      # obs-source-clone
      # looking-glass-obs
      obs-source-record
      # obs-3d-effect
      # obs-teleport
      obs-backgroundremoval
      # obs-vaapi
      # obs-command-source
      # obs-gstreamer
      # obs-vkcapture
      # obs-hyperion
      # obs-websocket
      # obs-livesplit-one
      # obs-move-transition
      obs-multi-rtmp
      # obs-ndi
      # wlrobs
      # obs-nvfbc
    ];
  };

  obs2 = obs.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./obs-change-v4l2-label.patch ];
  });

  # customV4l2loopback = config.boot.kernelPackages.v4l2loopback.overrideAttrs (old: {
  #   patches = (old.patches or [ ]) ++ [ ./v4l2loopback-change-v4l2-label.patch ];
  # });
in
{
  # sudo v4l2loopback-ctl query 44
  # v4l2loopback-ctl set-caps 44 "YUYV:1280x720@30/1"
  # sudo modprobe -r v4l2loopback && sudo modprobe v4l2loopback video_nr=4 width=640,1920 max_width=1920 height=480,1080 max_height=1080 format=YU12,YU12 exclusive_caps=1,1 card_label="HDcam C2900",Laptop debug=1
  # sudo v4l2-ctl -d /dev/video44 -l && echo "/dev/video44"
  # sudo modprobe -r v4l2loopback
  # sudo modprobe v4l2loopback devices=1 video_nr=44 card_label="HDcam C2900" exclusive_caps=1 debug=1
  # ls -al /dev/ | grep video
  # insmod v4l2loopback video_nr=4 exclusive_caps=1

  # sudo firejail --blacklist=/dev/video0 --blacklist=/dev/video1 --blacklist=/dev/video2 --blacklist=/dev/video3 chromium-browser

  boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
  # boot.extraModulePackages = [ customV4l2loopback ];
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 video_nr=44 card_label="HDcam C2900"  exclusive_caps=1 debug=1
  '';
  # ffmpeg -i /dev/video0 -f v4l2 -vcodec rawvideo -pix_fmt rgb24 /dev/video44
  # max_width=1280 max_height=720
  # options v4l2loopback video_nr=2,3 width=640,1920 max_width=1920 height=480,1080 max_height=1080 format=YU12,YU12 exclusive_caps=1,1 card_label="HDcam C2900",Laptop debug=1

  security.polkit.enable = true;

  # subject.isInGroup("users")
  # subject.user == "srghma"
  # action.lookup("program") == "/run/current-system/sw/bin/modprobe" &&
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.policykit.exec" &&
            subject.isInGroup("users")) {
            return polkit.Result.YES;
        }
    });
  '';

  # boot.extraModulePackages = [
  #   config.boot.kernelPackages.v4l2loopback # Webcam loopback
  # ];

  # boot.kernelModules = [
  #   "v4l2loopback" # Webcam loopback
  #   # "snd-aloop"
  # ];
  # services.usbmuxd.enable = true; # Webcam loopback

  environment.systemPackages = [
    obs2
    config.boot.kernelPackages.v4l2loopback.bin
    mypkgs.v4l-utils
    mypkgs.android-tools
    mypkgs.adb-sync
    # mypkgs.usbmuxd
  ];
}
