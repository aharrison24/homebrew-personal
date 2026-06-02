class Diffmerge < Formula
  desc "SourceGear DiffMerge (Open Source Edition)"
  homepage "https://github.com/sourcegear/diffmerge"
  url "https://github.com/sourcegear/diffmerge/archive/refs/tags/v5.0.0.1.tar.gz"
  version "5.0.0.1"
  sha256 "bdd29879585a119a7962e68b4f5b3f746b92d5c84b37d5ce5f8503ec419745c4"
  license "GPL-3.0-or-later"

  depends_on :xcode => :build

  def install
    # The Makefiles have missing dependency chains that cause parallel builds to fail.
    # We fix these so we can use all CPU cores.
    
    # Fix top-level dependency: build_diffmerge must wait for thirdparty
    inreplace "sgdm3/Makefile.Apple" do |s|
      s.gsub! "all:\tmaybe_build_thirdparty build_diffmerge report_outputs",
              "all: report_outputs\nreport_outputs: build_diffmerge\nbuild_diffmerge: maybe_build_thirdparty"
    end
    
    # Fix thirdparty dependency: _compile -> _config -> _unpack
    inreplace "sgdm3/thirdparty/Makefile.Apple" do |s|
      s.gsub! "_all:\t_unpack _config _compile",
              "_all: _compile\n_compile: _config\n_config: _unpack"
      # Enable parallel make for the nested wxWidgets build
      s.gsub! "(cd $(OBJ_PATHNAME); make)",
              "(cd $(OBJ_PATHNAME); make -j#{ENV.make_jobs})"
    end

    # Enable parallel make for the main source build
    inreplace "sgdm3/src/Makefile.Unix" do |s|
      s.gsub! "$(MAKE) -C $$subdir", "$(MAKE) -j#{ENV.make_jobs} -C $$subdir"
    end

    # Skip DMG creation as it fails in sandbox
    inreplace "sgdm3/src/Config/ConfigExecutable.Apple.inc", "default:\t$(DMG)", "default:\t$(TARGET)"

    # The build system expects 'ARCH' and an absolute 'BUILD' path.
    arch = Hardware::CPU.arm? ? "arm64" : "x86_64"
    build_root = buildpath/"build_output"
    
    cd "sgdm3" do
      # We pass BUILDNUM=1 to match the 5.0.0.1 versioning from the tag.
      # We target 'build_diffmerge' which we've now patched to depend on 
      # 'maybe_build_thirdparty', ensuring a correct and fast parallel build.
      system "make", "-f", "Makefile.Apple", 
             "ARCH=#{arch}", 
             "BUILD=#{build_root}",
             "BUILDNUM=1",
             "build_diffmerge"
    end

    # Locating the built .app bundle (path depends on version/label)
    app_path = Dir.glob("build_output/Apple/#{arch}/Release/tmp/*/DiffMerge.app").first
    odie "Could not find built DiffMerge.app" if app_path.nil?
    
    # Install the app bundle into the prefix
    prefix.install app_path
    
    # Process and install the man page
    man_page = "sgdm3/src/Installers/Apple.man1"
    inreplace man_page do |s|
      s.gsub! "@MAJOR@", "5"
      s.gsub! "@MINOR@", "0"
      s.gsub! "@REVISION@", "0"
      s.gsub! "@BUILDNUM@", "1"
      s.gsub! "@COPYRIGHTDATE@", Time.now.year.to_s
      s.gsub! "@BUILDLABEL@", "dev"
      s.gsub! "@PACKAGE@", "DiffMerge"
      s.gsub! "@EXE@", "diffmerge"
    end
    man1.install man_page => "diffmerge.1"
    
    # Create the command-line wrapper shim
    (bin/"diffmerge").write <<~EOS
      #!/bin/sh
      exec "#{prefix}/DiffMerge.app/Contents/MacOS/DiffMerge" --nosplash "$@"
    EOS
    
    # Ad-hoc sign the app bundle. This is mandatory for ARM binaries to run.
    if Hardware::CPU.arm?
      system "xattr", "-cr", "#{prefix}/DiffMerge.app"
      system "codesign", "-s", "-", "--deep", "--force", "#{prefix}/DiffMerge.app"
    end
  end

  def caveats
    <<~EOS
      To use the GUI application, you can link it to your Applications folder:
        ln -s #{opt_prefix}/DiffMerge.app /Applications/DiffMerge.app
    EOS
  end

  test do
    assert_predicate bin/"diffmerge", :executable?
    assert_predicate prefix/"DiffMerge.app/Contents/MacOS/DiffMerge", :executable?
  end
end
