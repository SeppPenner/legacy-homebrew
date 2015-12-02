# Track Chrome stable.
# https://omahaproxy.appspot.com/
class V8 < Formula
  desc "Google's JavaScript engine"
  homepage "https://code.google.com/p/v8/"
  url "https://github.com/v8/v8-git-mirror/archive/4.7.80.23.tar.gz"
  sha256 "54d96c8f9522422da8903d11201b6aa7d55c38390364477fdc58d4cdc9dcf744"

  bottle do
    cellar :any
    sha256 "e664e94981fa50212ede32af4a1a8ba6dd6ad7aec7da49966b46f39382146865" => :el_capitan
    sha256 "604b8871c4916cc8343b3a359a172b2c0d2f39d88fed58ead55306e6bf4737b9" => :yosemite
    sha256 "ea3fe86e89f1289a405a4a28423b2cdd490262b0ba2d1e0f4922c09cdf84d186" => :mavericks
  end

  option "with-readline", "Use readline instead of libedit"

  # not building on Snow Leopard:
  # https://github.com/Homebrew/homebrew/issues/21426
  depends_on :macos => :lion

  depends_on :python => :build # gyp doesn't run under 2.6 or lower
  depends_on "readline" => :optional

  needs :cxx11

  # Update from "DEPS" file in tarball.
  resource "gyp" do
    url "https://chromium.googlesource.com/external/gyp.git",
        :revision => "01528c7244837168a1c80f06ff60fa5a9793c824"
  end

  resource "icu" do
    url "https://chromium.googlesource.com/chromium/deps/icu.git",
        :revision => "423fc7e1107fb08ccf007c4aeb76dcab8b2747c1"
  end

  resource "buildtools" do
    url "https://chromium.googlesource.com/chromium/buildtools.git",
        :revision => "e7111440c07a883b82ffbbe6d26c744dfc6c9673"
  end

  resource "swarming_client" do
    url "https://chromium.googlesource.com/external/swarming.client.git",
        :revision => "6e5d2b21f0ac98396cd736097a985346feed1328"
  end

  resource "clang" do
    url "https://chromium.googlesource.com/chromium/src/tools/clang.git",
        :revision => "0150e39a3112dbc7e4c7a3ab25276b8d7781f3b6"
  end

  resource "gmock" do
    url "https://chromium.googlesource.com/external/googlemock.git",
        :revision => "0421b6f358139f02e102c9c332ce19a33faf75be"
  end

  resource "gtest" do
    url "https://chromium.googlesource.com/external/googletest.git",
        :revision => "9855a87157778d39b95eccfb201a9dc90f6d61c6"
  end

  def install
    # Bully GYP into correctly linking with c++11
    ENV.cxx11
    ENV["GYP_DEFINES"] = "clang=1 mac_deployment_target=#{MacOS.version}"
    # https://code.google.com/p/v8/issues/detail?id=4511#c3
    ENV.append "GYP_DEFINES", "v8_use_external_startup_data=0"

    # fix up libv8.dylib install_name
    # https://github.com/Homebrew/homebrew/issues/36571
    # https://code.google.com/p/v8/issues/detail?id=3871
    inreplace "tools/gyp/v8.gyp",
              "'OTHER_LDFLAGS': ['-dynamiclib', '-all_load']",
              "\\0, 'DYLIB_INSTALL_NAME_BASE': '#{opt_lib}'"

    (buildpath/"buildtools").install resource("buildtools")
    (buildpath/"build/gyp").install resource("gyp")
    (buildpath/"third_party/icu").install resource("icu")
    (buildpath/"testing/gmock").install resource("gmock")
    (buildpath/"testing/gtest").install resource("gtest")
    (buildpath/"tools/clang").install resource("clang")
    (buildpath/"tools/swarming_client").install resource("swarming_client")

    system "make", "native", "library=shared", "snapshot=on",
                   "console=readline", "i18nsupport=off",
                   "strictaliasing=off"

    include.install Dir["include/*"]

    cd "out/native" do
      rm ["libgmock.a", "libgtest.a"]
      lib.install Dir["lib*"]
      bin.install "d8", "mksnapshot", "process", "shell" => "v8"
    end
  end

  test do
    assert_equal "Hello World!", pipe_output("#{bin}/v8 -e 'print(\"Hello World!\")'").chomp
  end
end
