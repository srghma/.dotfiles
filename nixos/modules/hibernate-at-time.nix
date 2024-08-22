{ pkgs
, lib
, config
, ...
}:

{
  systemd.services.myhibernate = {
    description = "Hibernate the system";
    serviceConfig.ExecStart = [ "/run/current-system/sw/bin/systemctl hibernate" ];
  };

  systemd.timers.hibernate-timer = {
    description = "Timer to hibernate the system at TIME";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "19:30";
      Persistent = true;
    };
    unitConfig = {
      # Link this timer to the hibernate service
      Unit = "myhibernate.service";
    };
  };
}
