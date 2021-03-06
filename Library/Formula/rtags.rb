class Rtags < Formula
  desc "ctags-like source code cross-referencer with a clang frontend"
  homepage "https://github.com/Andersbakken/rtags"
  url "https://github.com/Andersbakken/rtags.git",
      :tag => "v2.0",
      :revision => "ba85598841648490e64246be802fc2dcdd45bc3c"

  head "https://github.com/Andersbakken/rtags.git"

  bottle do
    sha256 "76809519b7d18df4289c88943607fe457c19f30d35fa283b5db0a387b3d83e63" => :yosemite
    sha256 "cc6dd88798074827fc3e27900ac7cc82763ae06d06a4e5f15afde28e9210376b" => :mavericks
    sha256 "6324718564081d380bc5eac717e4388315203d05ec52d2154ce0466191b16e8a" => :mountain_lion
  end

  depends_on "cmake" => :build
  depends_on "llvm" => "with-clang"
  depends_on "openssl"

  def install
    # Homebrew llvm libc++.dylib doesn't correctly reexport libc++abi
    ENV.append("LDFLAGS", "-lc++abi")

    mkdir "build" do
      system "cmake", "..", *std_cmake_args
      system "make"
      system "make", "install"
    end
  end

  test do
    mkpath testpath/"src"
    (testpath/"src/foo.c").write(<<-END.undent)
        void zaphod() {
        }

        void beeblebrox() {
          zaphod();
        }
        END
    (testpath/"src/README").write(<<-END.undent)
        42
      END
    rdm = fork do
      $stdout.reopen("/dev/null")
      $stderr.reopen("/dev/null")
      exec "#{bin}/rdm", "-L", "log"
    end
    def pause
      slept = 0
      while slept < 5
        Kernel.system "#{bin}/rc --is-indexing >/dev/null 2>&1"
        if $? == 0
          break
        end
        dt = 0.01
        sleep dt
        slept += dt
      end
    end
    pause
    system "sh", "-c", "echo clang -c src/foo.c | #{bin}/rc -c"
    assert_equal $?, 0
    pause
    assert_match /foo\.c:1:6/, shell_output("#{bin}/rc -f src/foo.c:5:3")
    system "#{bin}/rc", "-q"
    assert_equal $?, 0
    Process.wait(rdm)
  end
end
