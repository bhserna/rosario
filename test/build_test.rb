require "minitest/autorun"
require "tmpdir"
require_relative "../lib/build"

class BuildTest < Minitest::Test
  def test_writes_the_site_into_the_given_directory
    Dir.mktmpdir do |dir|
      build(dir)

      pages = ["index.html", "today.html", "como-se-reza.html", "rosario.css"]
      GROUPS.each do |group|
        pages << "#{group[:id]}.html"
        group[:mysteries].each_index { |index| pages << "misterios/#{group[:id]}-#{index + 1}.html" }
      end
      pages.each { |page| assert File.exist?(File.join(dir, page)), page }

      index = File.read(File.join(dir, "index.html"))
      assert_includes index, 'href="today.html"'
      assert_includes index, "Lunes y sábado"

      today = File.read(File.join(dir, "today.html"))
      assert_includes today, "['gloriosos', 'gozosos', 'dolorosos', 'gloriosos', 'luminosos', 'dolorosos', 'gozosos']"

      mystery = File.read(File.join(dir, "misterios/gozosos-1.html"))
      assert_includes mystery, "La Encarnación del Hijo de Dios"
      assert_includes mystery, 'register("../sw.js")'

      assert_includes index, 'register("sw.js")'
      worker = File.read(File.join(dir, "sw.js"))
      assert_includes worker, '"./index.html"'
      assert_includes worker, '"./rosario.css"'
      assert_includes worker, '"./misterios/gozosos-1.html"'
      assert_match(/const CACHE = "rosario-[0-9a-f]{12}"/, worker)

      assert_equal File.read(File.join(STATIC, "rosario.css")), File.read(File.join(dir, "rosario.css"))
      assert_equal File.read(File.join(STATIC, "como-se-reza.html")), File.read(File.join(dir, "como-se-reza.html"))
    end
  end
end
