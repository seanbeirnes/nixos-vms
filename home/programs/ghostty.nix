{ ... }: {
  xdg.configFile."ghostty/config".text = ''
    font-size = 24
    font-feature = -liga

    keybind = super+t=new_tab
    keybind = super+w=close_tab
    keybind = super+digit_1=goto_tab:1
    keybind = super+1=goto_tab:1
    keybind = super+digit_2=goto_tab:2
    keybind = super+2=goto_tab:2
    keybind = super+digit_3=goto_tab:3
    keybind = super+3=goto_tab:3
    keybind = super+digit_4=goto_tab:4
    keybind = super+4=goto_tab:4
    keybind = super+digit_5=goto_tab:5
    keybind = super+5=goto_tab:5
    keybind = super+digit_6=goto_tab:6
    keybind = super+6=goto_tab:6
    keybind = super+digit_7=goto_tab:7
    keybind = super+7=goto_tab:7
    keybind = super+digit_8=goto_tab:8
    keybind = super+8=goto_tab:8
    keybind = super+digit_9=last_tab
    keybind = super+9=last_tab

    keybind = performable:ctrl+c=copy_to_clipboard
    keybind = ctrl+v=paste_from_clipboard
    keybind = ctrl+arrow_left=esc:b
    keybind = ctrl+arrow_right=esc:f
    keybind = ctrl+backspace=text:\x17
  '';
}
