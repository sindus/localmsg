cask "localmsg" do
  version "0.2.0"
  sha256 "f39401584f6f3ac2553d576e4804af9db7fefda06159ea7ca05a01bd51ce64cb"

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
