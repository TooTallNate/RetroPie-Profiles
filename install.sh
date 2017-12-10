#!/usr/bin/env bash
# install script that does the following:
# - put `login.sh` in `$HOME/RetroPie/retropiemenu/` directory
# - put `icon.png` in `$HOME/RetroPie/retropiemenu/icons` directory
# - create a gamelist.xml entry for `login.sh`
user=$(stat -c "%U" "$HOME")
group=$(stat -c "%G" "$HOME")
echo "User: $user, Group: $group"

echo -n "Putting \"login.sh\" in \"$HOME/RetroPie/retropiemenu/\"..."
cp login.sh "$HOME/RetroPie/retropiemenu/login.sh" || {
  echo -e "\nUnable to put \"login.sh\" in \"$HOME/RetroPie/retropiemenu/\". Aborting."
  exit 1
}
echo " OK!"


echo -n "Putting \"icon.png\" in \"$HOME/RetroPie/retropiemenu/icons\"..."
cp icon.png "$HOME/RetroPie/retropiemenu/icons/save-profiles.png" || {
  echo -e "\nUnable to put \"icon.png\" in \"$HOME/RetroPie/retropiemenu/icons\". Aborting."
  exit 1
}
echo " OK!"


gamelistxml="$HOME/RetroPie/retropiemenu/gamelist.xml"
[[ -f "$gamelistxml" ]] || {
  cp "/opt/retropie/configs/all/emulationstation/gamelists/retropie/gamelist.xml" \
    "$gamelistxml"
}

grep -q "<path>./login.sh</path>" "$gamelistxml" && {
  echo "gamelist.xml file already has RetroPie-Profiles entry"
  exit 0
}

gamelist_info='\
  <game>\
    <path>.\/login.sh<\/path>\
    <name>Save Profiles<\/name>\
    <desc>Select which profile to use for save files and save states.<\/desc>\
    <image>.\/icons\/save-profiles.png<\/image>\
  <\/game>'

echo -n "Creating a gamelist.xml entry for login.sh..."
sudo sed -i.bak "/<\/gameList>/ s/.*/${gamelist_info}\n&/" "$gamelistxml" || {
  echo "Warning: Unable to edit \"$gamelistxml\"."
  exit 1
}
echo " OK!"

# ensuring that the /opt/retropie/configs/all dir is owned by the user
sudo chown $user:$group /opt/retropie/configs/all
