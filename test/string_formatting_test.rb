require 'test/unit'
require 'fileutils'
require_relative "../lib/string_formatter"
require_relative "../lib/fonts"

class Formatter
  include Rembrandt::StringFormatter
end

class StringFormattingTest < Test::Unit::TestCase

  def setup
    @formatter = Formatter.new
  end

  def test_wrapped_string
    assert_equal "This string is\ntoo long,\ntruncate it!", @formatter.wrap_string('This string is too long, truncate it!', 100, Rembrandt::Fonts::Small)
    assert_equal "Another string \nthat is pesky!", @formatter.wrap_string('Another string that is pesky!', 90, Rembrandt::Fonts::Small)
    assert_equal "Another \nstring\nthat is \npesky!", @formatter.wrap_string('Another string that is pesky!', 50, Rembrandt::Fonts::Small)
    assert_equal " Another\nstring\nthat is \npesky!", @formatter.wrap_string(' Another string that is pesky!', 50, Rembrandt::Fonts::Small)
  end

  def test_wrapped_string_with_word_longer_than_line
    assert_equal "Thisisaverylongw\nord, isn't it?", @formatter.wrap_string('Thisisaverylongword, isn\'t it?', 100, Rembrandt::Fonts::Small)
    assert_equal "Butnotnearlyaslo\nngasthiswordrigh\nthereitistrulyal\nongword, isn't\nit?", @formatter.wrap_string('Butnotnearlyaslongasthiswordrighthereitistrulyalongword, isn\'t it?', 100, Rembrandt::Fonts::Small)
  end

  def test_truncate_string
    assert_equal "This sentence is", @formatter.truncate_string('This sentence is too long.', 100, Rembrandt::Fonts::Small)
  end

  def test_cut_lines
    assert_equal "This\nhas\ntoo\nmany", @formatter.cut_lines("This\nhas\ntoo\nmany\nlines!", 32, Rembrandt::Fonts::Small)
  end
end
