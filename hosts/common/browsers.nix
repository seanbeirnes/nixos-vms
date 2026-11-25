# Browser automation for coding agents: agent-browser, Playwright MCP and CLI, and the libraries a project's own Playwright browsers need.
{ lib, pkgs, ... }:
let
  # The Chromium that's already installed for people. The agent tools use it instead of downloading
  # their own browser, which is built for Ubuntu.
  chromiumExecutable = lib.getExe pkgs.chromium;

  # Baked into the binary rather than set in the environment, so agents started from a login shell, the
  # T3 Code service, or anywhere else get the same browser. --set-default keeps an explicit value working.
  agentBrowser = pkgs.symlinkJoin {
    name = "agent-browser-${pkgs.unstable.agent-browser.version}";
    paths = [ pkgs.unstable.agent-browser ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/agent-browser \
        --set-default AGENT_BROWSER_EXECUTABLE_PATH ${chromiumExecutable}
    '';
  };

  # @playwright/cli is only on npm. Pinned so every VM runs the same version; bump it here.
  playwrightCliVersion = "0.1.25";

  # A `playwright-cli` command for the Playwright skill to call, since `npm install -g` (what the skill
  # suggests) can't write to the Nix store. The executable path is set here, not globally, because
  # PLAYWRIGHT_MCP_EXECUTABLE_PATH would also make playwright-mcp launch Chromium for --browser firefox.
  # The update notice is off because it tells agents to run that same failing `npm install -g`.
  playwrightCli = pkgs.writeShellApplication {
    name = "playwright-cli";
    runtimeInputs = [ pkgs.nodejs ];
    text = ''
      export PLAYWRIGHT_MCP_EXECUTABLE_PATH="''${PLAYWRIGHT_MCP_EXECUTABLE_PATH:-${chromiumExecutable}}"
      export NO_UPDATE_NOTIFIER=1
      exec npx --yes --package=@playwright/cli@${playwrightCliVersion} -- playwright-cli "$@"
    '';
  };

  # Set for login shells and for the T3 Code service, the two places agents start from. Playwright checks
  # a browser's libraries with `ldd`, which can't see nix-ld's libraries, so its check fails even though the
  # browser runs.
  browserSessionVariables = {
    PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "1";
  };
in
{
  environment.systemPackages = [
    agentBrowser
    playwrightCli
    # Wrapped by nixpkgs to use its own Playwright browsers (Chromium, Firefox, WebKit) from the Nix store.
    pkgs.unstable.playwright-mcp
  ];

  environment.sessionVariables = browserSessionVariables;
  systemd.user.services.t3code.environment = browserSessionVariables;

  # Lets the browsers a project downloads with `npx playwright install` run, so any Playwright version works.
  # Chromium and Firefox only: the libraries are Playwright's own Ubuntu 24.04 lists (nativeDeps.ts), minus
  # those nix-ld already provides. WebKit is left out: it needs old libraries (libvpx 1.12, libjxl 0.8) that
  # nixpkgs builds only inside its own Playwright WebKit, and playwright-mcp already has that WebKit.
  programs.nix-ld.libraries = with pkgs; [
    # Chromium and Firefox
    alsa-lib
    at-spi2-core # libatk, libatk-bridge, libatspi
    cairo # also libcairo-gobject (Firefox)
    dbus
    glib
    libx11 # also libX11-xcb (Firefox)
    libxcb # also libxcb-shm (Firefox)
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    pango # also libpangocairo (Firefox)

    # Chromium
    cups
    expat # in Ubuntu's base system, so not in Playwright's list; nixpkgs' Playwright Chromium links it
    libdrm
    libgbm
    libxkbcommon
    nspr
    nss

    # Firefox. Playwright's list also has libavcodec, left out because Firefox loads it only to play
    # H.264 and AAC media.
    fontconfig
    freetype
    gdk-pixbuf
    gtk3
    libxcursor
    libxi
    libxrender
  ];
}
