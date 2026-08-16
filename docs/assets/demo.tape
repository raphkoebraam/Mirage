# Regenerates docs/assets/demo.gif.
#
#   mise install                      # or: brew install vhs ttyd ffmpeg
#   mise run build                    # produces ./bin/mirage
#   vhs docs/assets/demo.tape
#
# Everything runs against a throwaway CoreSimulator device set created in the
# setup block below, so recording never touches real simulators.

Output docs/assets/demo.gif

Set Shell zsh
Set Theme "Catppuccin Mocha"
Set FontSize 18
Set Width 1320
Set Height 470
Set Padding 24
Set TypingSpeed 60ms

Hide
Type "export PATH=$PWD/bin:$PATH"
Enter
Type "export MIRAGE_DEVICE_SET=$(mktemp -d)/devices"
Enter
Type "mkdir -p $MIRAGE_DEVICE_SET"
Enter
Type `mirage create "iPhone 17 Pro" --type "iPhone 17 Pro" --yes`
Enter
Type `mirage create "iPhone 16" --type "iPhone 16" --yes`
Enter
Type `mirage create "CI Phone" --type "iPhone 17" --yes`
Enter
Type `mirage create "iPad Pro 13-inch" --type "iPad Pro 13-inch (M4)" --yes`
Enter
Type "cd $(mktemp -d)"
Enter
Type "export PROMPT='%F{6}❯%f '"
Enter
Type "clear"
Enter
Show

Sleep 1s

Type "mirage list"
Enter
Sleep 3.5s

Type `mirage boot "17 pro"`
Enter
Sleep 3.5s

Type "mirage screenshot"
Enter
Sleep 4s
