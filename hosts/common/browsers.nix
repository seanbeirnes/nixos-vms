# Browser automation for coding agents: agent-browser, Playwright MCP and CLI.
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
in
{
  environment.systemPackages = [
    agentBrowser
    playwrightCli
    # Wrapped by nixpkgs to use its own Playwright browsers (Chromium, Firefox, WebKit) from the Nix store.
    pkgs.unstable.playwright-mcp
  ];
}
