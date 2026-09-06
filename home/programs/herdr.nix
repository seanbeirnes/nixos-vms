{ pkgs, herdrPackage, ... }: {
  home.packages = [ herdrPackage ];

  xdg.configFile."herdr/config.toml".source = (pkgs.formats.toml { }).generate "herdr-config.toml" {
    onboarding = false;
    update.version_check = false;
    terminal.new_cwd = "follow";
    theme = {
      name = "catppuccin";
      custom.panel_bg = "reset";
    };
    keys = {
      prefix = "ctrl+b";
      focus_pane_left = "prefix+h";
      focus_pane_down = "prefix+j";
      focus_pane_up = "prefix+k";
      focus_pane_right = "prefix+l";
      split_horizontal = "prefix+\"";
      split_vertical = "prefix+%";
      new_tab = "prefix+c";
      next_tab = "prefix+n";
      previous_tab = "prefix+p";
      switch_tab = "prefix+1..9";
      rename_tab = "prefix+comma";
      detach = "prefix+d";
      reload_config = "prefix+r";
      resize_mode = "prefix+shift+r";
    };
    ui = {
      mouse_capture = true;
      copy_on_select = true;
      prompt_new_tab_name = false;
      tab_bar_position = "bottom";
      tab_bar_right = [
        { type = "hostname"; }
        { type = "datetime"; format = "%H:%M"; }
      ];
    };
    # Herdr limits scrollback in bytes, rather than lines.
    advanced.scrollback_limit_bytes = 10000000;
  };
}
