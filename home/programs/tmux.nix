{ pkgs, ... }: {
  programs.tmux = {
    enable = true;
    clock24 = true;
    keyMode = "vi";
    terminal = "screen-256color";
    extraConfig = ''
      # Vim style pane selection
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # Start windows and panes at 1, not 0
      set -g base-index 1
      set -g pane-base-index 1
      set-window-option -g pane-base-index 1
      set-option -g renumber-windows on

      # Make windows and panes open in current path
      bind '"' split-window -v -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"
      bind c new-window -c "#{pane_current_path}"

      # Use scroll wheel to scroll through terminal output
      set -g mouse on

      set -g history-limit 100000
      bind r source-file ~/.config/tmux/tmux.conf \; display-message "tmux config reloaded"
    '';

    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      {
        plugin = catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavour "mocha"
          set -g @catppuccin_status_background "none"
        '';
      }
    ];
  };
}
