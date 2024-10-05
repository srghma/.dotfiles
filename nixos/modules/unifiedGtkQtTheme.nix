# stolen from https://github.com/rychly/nur-packages/blob/79fa016d59006fb02fbd3590cbc756f46977cc4b/modules/unified-gtk-qt-theme.nix#L67
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.unifiedGtkQtTheme;

  ## modules

  mainModuleOptions = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Sets Adwaita as the unified GTK/Qt4/Qt5 theme.";
    };

    iconTheme = {
      name = mkOption {
        type = types.str;
        default = "breeze";
        description = "Name of an icon theme to use with the unified GTK/Qt4/Qt5 theme.";
      };

      package = mkOption {
        type = types.package;
        default = pkgs.breeze-icons;
        description = "Package/derivation of the icon theme to use with the unified GTK/Qt4/Qt5 theme.";
      };
    };

    font = mkOption {
      type = types.str;
      default = "DejaVu Sans 11";
      description = "Font to use with the unified GTK/Qt4/Qt5 theme.";
    };
  };

  ## shortcuts

  gtkini = ''
    gtk-cursor-theme-name="Adwaita"
    gtk-icon-theme-name="${cfg.iconTheme.name}"
    gtk-theme-name="Adwaita"
    gtk-font-name="${cfg.font}"
    gtk-application-prefer-dark-theme=1
  '';
in {
  options.unifiedGtkQtTheme = mainModuleOptions;

  # see also https://wiki.archlinux.org/index.php/GTK%2B and https://wiki.archlinux.org/index.php/Qt

  config = mkIf (cfg.enable) {
    # QT4/5 global theme
    environment.etc."xdg/Trolltech.conf".text = ''
      [Qt]
      style=GTK+
    '';

    # GTK2/GTK3 global theme (widget and icon theme)
    environment.etc."gtk-2.0/gtkrc".text = gtkini;
    environment.etc."gtk-3.0/settings.ini".text = ''
      [Settings]
      ${gtkini}
    '';
    environment.etc."gtk-4.0/settings.ini".text = ''
      [Settings]
      ${gtkini}
    '';

    environment.systemPackages = with pkgs; [
      # No Qt theme (from Qt 4.5, QGtkStyle style is included in Qt)
      # No Gtk2/Gtk3 theme (the default theme is already included in pkgs.gnome-themes-standard)
      # Icons for both GNOME/KDE applications including a fallback
      cfg.iconTheme.package # KDE/GNOME
      adwaita-icon-theme # GNOME fallback
      # hicolor_icon_theme	# general fallback
      # SVG loader for pixbuf (needed for GTK svg icon themes)
      librsvg
    ];

    # # GTK2/GTK3: libs/theme definitions in lib/share directories of their packages
    # export GTK_PATH="${pkgs.gnome-themes-standard}/lib/gtk-2.0:$GTK_PATH"
    # export GTK2_RC_FILES="${pkgs.gnome-themes-standard}/share/themes/Adwaita/gtk-2.0/gtkrc:$GTK2_RC_FILES"
    # export XDG_DATA_DIRS="${pkgs.gnome-themes-standard}/share:$XDG_DATA_DIRS"
    # # QT/GTK: remove local user overrides (for determinism, causes hard to find bugs)
    # rm -f ~/.config/Trolltech.conf ~/.gtkrc-2.0 ~/.config/gtk-3.0/settings.ini ~/.config/gtk-4.0/settings.ini
    # # SVG loader for pixbuf (needed for GTK svg icon themes); cannot be in environment.variables as there is a shell pattern expansion
    # export GDK_PIXBUF_MODULE_FILE=$(echo ${pkgs.librsvg}/lib/gdk-pixbuf-2.0/*/loaders.cache)

    environment.extraInit = lib.mkAfter ''
      export GTK_THEME="Adwaita:dark"

      # Qt4/Qt5: convince it to use our preferred style
      export QT_QPA_PLATFORMTHEME="gtk2"
      export QT_STYLE_OVERRIDE="GTK+"
    '';

    # Enable access to /share where the themes are.
    environment.pathsToLink = ["/share"];
  };
}
