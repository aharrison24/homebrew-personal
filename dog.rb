class Dog < Formula
  desc "dog - better than cat"
  homepage "https://github.com/aharrison24/dog"
  url "https://github.com/aharrison24/dog.git", :revision => "edf5d6338b331a0ebbc7f81b65280266ba9a42bf"
  version "1.7-8"

  def install
    system "make"
    bin.install "dog"
    man1.install "dog.1"
  end

  test do
    # `test do` will create, run in and delete a temporary directory.
    #
    # The installed folder is not in the path, so use the entire path to any
    # executables being tested: `system "#{bin}/program", "do", "something"`.
    system "echo", "'Some text'", ">>", "myfile"
    system "#{bin}/dog", "myfile"
  end
end
