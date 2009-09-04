require 'test/unit'
require 'fileutils'
require "#{File.dirname(__FILE__)}/../lib/renderer"

class Renderer
  def render_string_testing(*args)
    setup_image
    render_string args.first, args[1] || {}
    create_png
    finalise
  end
end

class RendererTest < Test::Unit::TestCase

  def images_are_identical?(target, value_filepath)
    target_filepath = "#{File.dirname(__FILE__)}/images_for_assertions/#{target}.png"
    target = GD::Image.newFromPng(File.open(target_filepath, "r"))
    value = GD::Image.newFromPng(File.open(value_filepath, "r"))
    return_value = target.pngStr == value.pngStr
    target.destroy
    value.destroy
    return_value
  end

  def setup
    @image_filepath = "/tmp/renderer_test_image.png"
    FileUtils.rm_f @image_filepath
    @renderer = Renderer.new @image_filepath
  end

  def test_render_top_left_button_label
    @renderer.render '<button position="top_left">top left</button>'
    assert images_are_identical?(:render_top_left_button_label, @image_filepath)
  end

  def test_render_top_right_button_label
    @renderer.render '<button position="top_right">top right</button>'
    assert images_are_identical?(:render_top_right_button_label, @image_filepath)
  end

  def test_render_bottom_left_button_label
    @renderer.render '<button position="bottom_left">bottom left</button>'
    assert images_are_identical?(:render_bottom_left_button_label, @image_filepath)
  end

  def test_render_bottom_right_button_label
    @renderer.render '<button position="bottom_right">bottom right</button>'
    assert images_are_identical?(:render_bottom_right_button_label, @image_filepath)
  end

  def test_render_list_with_four_items_first_selected
    @renderer.render '<list><item selected="true">Item 1</item>
                            <item>Item 2</item>
                            <item>Item 3</item>
                            <item>Item 4</item></list>'
    assert images_are_identical?(:render_list_with_four_items_first_selected, @image_filepath)
  end
   
  def test_render_list_with_four_items_second_selected
    @renderer.render '<list><item>Item 1</item>
                            <item selected="true">Item 2</item>
                            <item>Item 3</item>
                            <item>Item 4</item></list>'
    assert images_are_identical?(:render_list_with_four_items_second_selected, @image_filepath)
  end
   
  def test_render_list_with_four_items_third_selected
    @renderer.render '<list><item>Item 1</item>
                            <item>Item 2</item>
                            <item selected="true">Item 3</item>
                            <item>Item 4</item></list>'
    assert images_are_identical?(:render_list_with_four_items_third_selected, @image_filepath)
  end

  def test_render_list_with_four_items_fourth_selected
    @renderer.render '<list><item>Item 1</item>
                            <item>Item 2</item>
                            <item>Item 3</item>
                            <item selected="true">Item 4</item></list>'
    assert images_are_identical?(:render_list_with_four_items_fourth_selected, @image_filepath)
  end
  
  def test_render_list_with_three_items_first_selected
    @renderer.render '<list><item selected="true">Item 1</item>
                            <item>Item 2</item>
                            <item>Item 3</item></list>'
    assert images_are_identical?(:render_list_with_three_items_first_selected, @image_filepath)
  end

  def test_render_list_with_three_items_second_selected
    @renderer.render '<list><item>Item 1</item>
                            <item selected="true">Item 2</item>
                            <item>Item 3</item></list>'
    assert images_are_identical?(:render_list_with_three_items_second_selected, @image_filepath)
  end
   
  def test_render_list_with_three_items_third_selected
    @renderer.render '<list><item>Item 1</item>
                            <item>Item 2</item>
                            <item selected="true">Item 3</item></list>'
    assert images_are_identical?(:render_list_with_three_items_third_selected, @image_filepath)
  end

  def test_render_list_with_five_items_first_selected
    @renderer.render '<list><item selected="true">Item 1</item>
                            <item>Item 2</item>
                            <item>Item 3</item>
                            <item>Item 4</item>
                            <item>Item 5</item></list>'
    assert images_are_identical?(:render_list_with_five_items_first_selected, @image_filepath)
  end
  
  def test_render_list_with_five_items_second_selected
    @renderer.render '<list><item>Item 1</item>
                            <item selected="true">Item 2</item>
                            <item>Item 3</item>
                            <item>Item 4</item>
                            <item>Item 5</item></list>'
    assert images_are_identical?(:render_list_with_five_items_second_selected, @image_filepath)
  end

  def test_render_list_with_five_items_third_selected
    @renderer.render '<list><item>Item 1</item>
                            <item>Item 2</item>
                            <item selected="true">Item 3</item>
                            <item>Item 4</item>
                            <item>Item 5</item></list>'
    assert images_are_identical?(:render_list_with_five_items_third_selected, @image_filepath)
  end
   
  def test_render_list_with_five_items_fifth_selected
    @renderer.render '<list><item>Item 1</item>
                            <item>Item 2</item>
                            <item>Item 3</item>
                            <item>Item 4</item>
                            <item selected="true">Item 5</item></list>'
    assert images_are_identical?(:render_list_with_five_items_fifth_selected, @image_filepath)
  end

  def test_render_string_left_align
    @renderer.render_string_testing 'Left aligned string'
    assert images_are_identical?(:render_string_left_top_0_0, @image_filepath)
    @renderer.render_string_testing 'Left aligned string', :x => 20, :y => 20, :valign => :top, :halign => :left
    assert images_are_identical?(:render_string_left_top_20_20, @image_filepath)
  end

  def test_render_string_right_align
    @renderer.render_string_testing 'Right aligned string', :halign => :right
    assert images_are_identical?(:render_string_right_top_0_0, @image_filepath)
    @renderer.render_string_testing 'Right aligned string', :y => 20, :halign => :right
    assert images_are_identical?(:render_string_right_top_20_20, @image_filepath)
    @renderer.render_string_testing 'Right aligned string', :x => 20, :y => 20, :halign => :right
    assert images_are_identical?(:render_string_right_top_20_20, @image_filepath)
  end

  def test_render_string_bottom_align
    @renderer.render_string_testing 'Bottom aligned string', :valign => :bottom
    assert images_are_identical?(:render_string_left_bottom_0_0, @image_filepath)
    @renderer.render_string_testing 'Bottom aligned string', :valign => :bottom, :x => 20, :y => 20
    assert images_are_identical?(:render_string_right_bottom_20_20, @image_filepath)
  end

  def test_render_string_horizontal_centre
    @renderer.render_string_testing 'Centre aligned string', :halign => :centre
    assert images_are_identical?(:render_string_horizontal_centre_0_0, @image_filepath)
  end

  def test_render_string_vertical_centre
    @renderer.render_string_testing 'Centre aligned string', :valign => :centre
    assert images_are_identical?(:render_string_vertical_centre_0_0, @image_filepath)
  end

  def test_render_title
    @renderer.render '<title>This is a page title</title>'
    assert images_are_identical?(:render_title, @image_filepath)
  end
end
