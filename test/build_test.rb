require "minitest/autorun"
require "tmpdir"
require_relative "../build"

class BuildTest < Minitest::Test
  def test_pages_match_the_build
    Dir.mktmpdir do |dir|
      build(dir)

      pages = Dir.glob("*.html", base: dir) + Dir.glob("misterios/*.html", base: dir)
      assert_equal 26, pages.size

      pages.each do |page|
        assert_equal File.read(File.join(dir, page)), File.read(File.join(ROOT, page)), page
      end
    end
  end
end
