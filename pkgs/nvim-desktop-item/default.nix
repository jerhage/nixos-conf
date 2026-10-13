# Desktop entry for opening text files in neovim. The nvim.desktop that neovim
# ships is Terminal=true, which needs a terminal resolver this system does not
# have, so this one names ghostty.
{
  lib,
  makeDesktopItem,
  ghostty,
  neovim,
}:
makeDesktopItem {
  name = "nvim-ghostty";
  desktopName = "Neovim";
  icon = "nvim";
  exec = "${lib.getExe ghostty} -e ${lib.getExe neovim} %F";
  terminal = false;

  categories = [
    "Utility"
    "TextEditor"
  ];

  mimeTypes = [
    "text/plain"
    "text/markdown"
    "text/csv"
    "application/json"
    "application/x-shellscript"
  ];
}
