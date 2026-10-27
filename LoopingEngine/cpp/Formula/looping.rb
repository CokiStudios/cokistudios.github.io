class Looping < Formula
  desc "High-performance programming language and native UI engine (v2.8 Quantum Signature)"
  homepage "https://cokistudios.com/engine"
  url "https://github.com/cokistudios/looping/archive/refs/tags/v2.8.0.tar.gz"
  version "2.8.0"
  license "MIT"

  # Para instalaciones desde tap de Coki Studios o Homebrew Core
  depends_on :macos
  depends_on "python@3" => :optional

  def install
    # Compilación nativa universal (Apple Silicon arm64 + Intel x86_64)
    system "make", "looping"
    bin.install "looping"
  end

  test do
    # Verificación de versión y evaluación básica de Looping
    assert_match "v2.8.0", shell_output("#{bin}/looping --version")
    assert_match "42", shell_output("#{bin}/looping eval 'print 42'")
  end
end
