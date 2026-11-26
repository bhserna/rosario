# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require_relative '../lib/build'

class BuildTest < Minitest::Test
  def test_writes_the_site_into_the_given_directory
    Dir.mktmpdir do |dir|
      build(dir)

      assert_expected_files(dir)
      assert_index(dir)
      assert_today(dir)
      assert_first_mystery(dir)
      assert_service_worker(dir)
      assert_static_files(dir)
    end
  end

  private

  def assert_expected_files(dir)
    pages = ['index.html', 'today.html', 'como-se-reza.html', 'rosario.css']
    GROUPS.each do |group|
      pages << "#{group[:id]}.html"
      group[:mysteries].each_index { |index| pages << "misterios/#{group[:id]}-#{index + 1}.html" }
    end
    pages.each { |page| assert File.exist?(File.join(dir, page)), page }
  end

  def assert_index(dir)
    index = read_page(dir, 'index.html')
    assert_includes index, 'href="today.html"'
    assert_includes index, 'Lunes y sábado'
    assert_includes index, 'register("sw.js")'
  end

  def assert_today(dir)
    today = read_page(dir, 'today.html')
    assert_includes today, "['gloriosos', 'gozosos', 'dolorosos', 'gloriosos', 'luminosos', 'dolorosos', 'gozosos']"
  end

  def assert_first_mystery(dir)
    mystery = read_page(dir, 'misterios/gozosos-1.html')
    assert_includes mystery, 'La Encarnación del Hijo de Dios'
    assert_includes mystery, 'register("../sw.js")'
  end

  def assert_service_worker(dir)
    worker = read_page(dir, 'sw.js')
    assert_includes worker, '"./index.html"'
    assert_includes worker, '"./rosario.css"'
    assert_includes worker, '"./misterios/gozosos-1.html"'
    assert_match(/const CACHE = "rosario-[0-9a-f]{12}"/, worker)
  end

  def assert_static_files(dir)
    assert_equal read_source('rosario.css'), read_page(dir, 'rosario.css')
    assert_equal read_source('como-se-reza.html'), read_page(dir, 'como-se-reza.html')
  end

  def read_page(dir, page)
    File.read(File.join(dir, page))
  end

  def read_source(name)
    File.read(File.join(STATIC, name))
  end
end
