{ lib, ... }:
let
  disabledShortcut = lib.hm.gvariant.mkEmptyArray lib.hm.gvariant.type.string;
in
{
  dconf.settings."org/gnome/desktop/session" = {
    idle-delay = lib.hm.gvariant.mkUint32 0;
  };

  dconf.settings."org/gnome/mutter" = {
    overlay-key = "F4";
  };

  dconf.settings."org/gnome/shell/keybindings" = {
    switch-to-application-1 = disabledShortcut;
    switch-to-application-2 = disabledShortcut;
    switch-to-application-3 = disabledShortcut;
    switch-to-application-4 = disabledShortcut;
    switch-to-application-5 = disabledShortcut;
    switch-to-application-6 = disabledShortcut;
    switch-to-application-7 = disabledShortcut;
    switch-to-application-8 = disabledShortcut;
    switch-to-application-9 = disabledShortcut;
  };
}
