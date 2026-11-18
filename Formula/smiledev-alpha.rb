class SmiledevAlpha < Formula
  desc "Alpha! 1.1.2A (Super Experimental) package manager & Asm+ObjC+C micro-runtime for Looping (Arch 3.1A)"
  homepage "https://engine.cokistudios.com"
  version "1.1.2A"
  version_scheme 1
  license "MIT"

  url "https://engine.cokistudios.com/looping-v1.1A-darwin-universal.tar.gz"
  mirror "https://repo.cokistudios.com/engine/looping-v1.1A-darwin-universal.tar.gz"
  mirror "https://github.com/CokiStudios/engine/releases/download/v1.1/looping-v1.1A-darwin-universal.tar.gz"
  mirror "https://github.com/CokiStudios/cokistudios.github.io/releases/download/v1.1/looping-v1.1A-darwin-universal.tar.gz"
  sha256 "f311e4e3651438748c26cc10f43bba8f1055897727526a06b3d58edd64cd9973"

  def install
    libexec.install "smiledev"
    (bin/"smiledev-alpha").write_env_script libexec/"smiledev", LOOPING_CHANNEL: "alpha"
    bin.install "looping-exp" if File.exist?("looping-exp")
  end

  test do
    assert_match "1.1.2A", shell_output("#{bin}/smiledev-alpha version")
    assert_match "PASS", shell_output("#{bin}/looping-exp --test") if File.exist?(bin/"looping-exp")
  end
end

