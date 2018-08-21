class GitMultiRebase < Formula
  homepage "https://github.com/goncalopp/git-utilities"
  url "https://github.com/goncalopp/git-utilities.git", :revision => "02b1cf22192f2556dc537720e0c86626b6af0701"
  version "0.0.1-02b1cf2"

  head "https://github.com/goncalopp/git-utilities.git"

  def install
    bin.install 'git-multi-rebase'
    bin.install 'git_python.py'
  end
end
