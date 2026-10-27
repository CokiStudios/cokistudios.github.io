class Looping < Formula
  desc "Dual hybrid high-performance engine and programming language (Commercial Production Release)"
  homepage "https://cokistudios.github.io"
  version "1.0.0-commercial"
  version_scheme 1
  license "MIT"

  url "https://repo.cokistudios.com/engine/looping-v1.0.0-commercial-darwin-universal.tar.gz"
  mirror "https://github.com/CokiStudios/engine/releases/download/v1.0.0-commercial/looping-v1.0.0-commercial-darwin-universal.tar.gz"
  mirror "https://github.com/CokiStudios/cokistudios.github.io/releases/download/v1.0.0-commercial/looping-v1.0.0-commercial-darwin-universal.tar.gz"
  sha256 "f624ea73e11d919a5bc30187afabe7a0d1c6b03bdee888feace9650e4f990dbc"

  def install
    bin.install "looping"
    bin.install_symlink "looping" => "ruuping"
    bin.install "smiledev"
  end

  test do
    system "#{bin}/looping", "test"
    system "#{bin}/smiledev", "version"
  end
end
