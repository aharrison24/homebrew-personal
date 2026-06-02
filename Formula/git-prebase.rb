class GitPrebase < Formula
  homepage "https://github.com/koreno/prebase"
  url "https://github.com/koreno/prebase.git", :revision => "20fc8f331bf14427f964f6273274e36627583d52"
  version "0.0.1-20fc8f3"

  head "https://github.com/koreno/prebase.git"

  def install
    bin.install 'git-prebase'
  end
end
