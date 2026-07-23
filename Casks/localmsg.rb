cask "localmsg" do
  version "0.1.0"
  sha256 "875024aaecf628ad0ee34c97cb369641d36ea95ff49b44515541c5fbad5d4341"

  url "https://github.com/sindus/localmsg/releases/download/v#{version}/localmsg-macos.zip"
  name "LocalMsg"
  desc "Messagerie sur reseau local (LAN), a la LocalSend mais pour du texte"
  homepage "https://sindus.github.io/localmsg/"

  app "localmsg.app"

  caveats <<~EOS
    localmsg n'est pas signe/notarise par Apple. Au premier lancement, si
    macOS bloque l'ouverture, faites un clic droit sur l'app > Ouvrir,
    ou lancez : xattr -cr /Applications/localmsg.app
  EOS
end
