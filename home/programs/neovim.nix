{ pkgs, ... }: {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withNodeJs = false;
    withPython3 = false;
    withRuby = false;
    sideloadInitLua = true;
    extraPackages = with pkgs; [
      tree-sitter
    ];
  };
}
