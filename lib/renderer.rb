require 'rubygems'
require 'GD'
require 'nokogiri'

class Renderer
  SCREEN_WIDTH = 256
  SCREEN_HEIGHT = 64
  CONTENT_HEIGHT = 32

  Font = Struct.new :path, :size, :width, :height, :descender_height
  Small = Font.new "#{File.dirname(__FILE__)}/../fonts/profont.ttf", 7.0, 6, 8, 2
  BUTTON_FONT = Small
  LIST_FONT = Small

  def initialize(filepath)
    @filepath = filepath
    @temporary_filepath = "#{filepath}.tmp"
  end

  def setup_image
    @temporary_file = File.open(@temporary_filepath, "w")
    @image = GD::Image.new(256, 64)
    @white = @image.colorAllocate(255, 255, 255)
    @black = @image.colorAllocate(0, 0, 0)
  end

  def parse_and_render(text)
    view = Nokogiri::HTML.parse text
    view.css('button').each do |button|
      render_button_label button
    end
    view.css('list').each do |list|
      render_list list
    end
  end

  def create_png
    @image.png @temporary_file
  end

  def finalise
    @temporary_file.close
    FileUtils.mv @temporary_filepath, @filepath
  end

  def render(text)
    setup_image
    parse_and_render text
    create_png
    finalise
  end

  def render_list(list)
    num_children = list.children.length
    if num_children <= (CONTENT_HEIGHT / LIST_FONT.height)
      build_and_render_short_list list
    else
      build_and_render_long_list list
    end
  end

  def build_and_render_short_list(list)
    selected_item = list.xpath('//item[@selected="true"]').first
    selected_index = list.children.index selected_item
    
    render_list_items list.children, selected_index
  end

  def build_and_render_long_list(list)
    selected_item = list.xpath('//item[@selected="true"]').first
    selected_index = list.children.index selected_item

    items_to_display = []
    (CONTENT_HEIGHT / LIST_FONT.height).times do |count|
      index = selected_index + count - 1
      if index >= list.children.length
        index -= list.children.length
      end
      items_to_display << list.children[index]
    end
    render_list_items items_to_display, selected_index
  end

  def render_list_items(items, selected_index)
    x, y = LIST_FONT.width * 2, BUTTON_FONT.height * 3

    items.each do |item|
      if item['selected']
        @image.filledRectangle(x, y - LIST_FONT.height, SCREEN_WIDTH - (LIST_FONT.width * 2), y, @black)
        render_string item.content, x, y, LIST_FONT, @white
      else
        render_string item.content, x, y, LIST_FONT
      end
      y += LIST_FONT.height
    end
  end

  def render_button_label(button)
    x, y = case button['name'].to_sym
    when :top_left
      [ 1, BUTTON_FONT.height ]
    when :bottom_left
      [ 1, SCREEN_HEIGHT - BUTTON_FONT.descender_height ]
    when :top_right
      [ SCREEN_WIDTH - (button.content.length * BUTTON_FONT.width), BUTTON_FONT.height ]
    when :bottom_right
      [ SCREEN_WIDTH - (button.content.length * BUTTON_FONT.width), SCREEN_HEIGHT - BUTTON_FONT.descender_height ]
    end
    render_string button.content, x, y, BUTTON_FONT
  end

  def render_string(text, x, y, font, colour = @black)
    @image.stringTTF(colour, font.path, font.size, 0, x, y, text)
  end
end
