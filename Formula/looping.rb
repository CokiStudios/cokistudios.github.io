class Looping < Formula
  desc "Dual hybrid high-performance engine and programming language for Loop OS"
  homepage "https://cokistudios.github.io"
  version "2.5.0"
  license "MIT"

  url "https://github.com/CokiStudios/cokistudios.github.io/releases/download/v2.5.0/looping-v2.5.0-darwin-universal.tar.gz"
  sha256 "db86f633e561800ae9c4de373018593fc9bcbd91e37aa4501fdcdbecb7ef3b60"

  def install
    bin.install "looping"
    bin.install_symlink "looping" => "ruuping"
  end

  test do
    system "#{bin}/looping", "test"
  end
end
