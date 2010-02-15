# Copyright (C) 2009 Mark Somerville <mark@scottishclimbs.com>
# Released under the General Public License (GPL) version 3.
# See COPYING

require 'rubygems'
require 'GD'
require 'nokogiri'
require_relative "fonts"
require_relative "string_formatter"

module Rembrandt
  class Renderer
    attr_accessor :queue

    include Rembrandt::Fonts
    include Rembrandt::StringFormatter

    SCREEN_WIDTH = 256
    SCREEN_HEIGHT = 64
    NUMBER_OF_LIST_ITEMS_TO_DISPLAY = 5

    def initialize(filepath)
      @filepath = filepath
      @temporary_filepath = "#{filepath}.tmp"
    end

    def setup_image
      @temporary_file = File.open(@temporary_filepath, "w")
      @image = GD::Image.new(256, 64)
      @white = @image.colorAllocate(255, 255, 255)
      @black = @image.colorAllocate(0, 0, 0)
      @trans = @image.colorAllocate(1, 1, 1)
      @plcd = @image.colorAllocate(120, 190, 250)
      @image = @image.fill(0, 0, @white)
    end

    def parse_and_render(text)
      view = Nokogiri::HTML.parse text
      view.css('image').each do |image|
        render_image image
      end
      view.css('button').each do |button|
        render_button_label button
      end
      view.css('title').each do |title|
        render_title title
      end
      view.css('list').each do |list|
        render_list list
      end
      view.css('text').each do |text|
        render_text text
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


    # Draws a PNG.
    #
    # Parameters:
    #   x (integer)         : starting x coordinate of the image in pixels. Default: 0.
    #   y (integer)         : starting y coordinate of the image in pixels. Default: 0.
    #
    # TODO: refactor the halign and valign string rendering stuff to use
    # here too.
    def render_image(image)
      if File.readable? image['path']
        x = image['x'].to_i || 0
        y = image['y'].to_i || 0
        image_to_render = GD::Image.new_from_png(image['path'])
        image_to_render.copy(@image, x, y, 0, 0, image_to_render.width, image_to_render.height)
      end
    end

    def render_list(list)
      selected_item = list.xpath('//item[@selected="yes"]').first
      selected_index = list.children.index selected_item

      render_list_items list.children, selected_index
    end

    def render_list_items(items, selected_index)
      # Subtract 2 from the calculated Y since our font is slightly too tall to
      # fit eight lines on the screen.
      x, y = LIST_FONT.width * 2, (BUTTON_FONT.height * 2) - 2

      items.each do |item|
        if item['selected']
          @image.filledRectangle(x, y, SCREEN_WIDTH - (LIST_FONT.width * 2), y + LIST_FONT.height, @black)
          render_string item.content, :x => x, :y => y, :font => LIST_FONT, :colour => @white
        else
          render_string item.content, :x => x, :y => y, :font => LIST_FONT
        end
        y += LIST_FONT.height
      end
    end

    def render_button_label(button)
      case button['position'].to_sym
      when :top_left
        render_string button.content, :y => -1
      when :bottom_left
        render_string button.content, :valign => :bottom
      when :top_right
        render_string button.content, :halign => :right, :y => -1
      when :bottom_right
        render_string button.content, :valign => :bottom, :halign => :right
      end
    end

    def render_title(title)
      # Subtract 2 from the calculated Y since our font is slightly too tall to
      # fit eight lines on the screen. This does mean that long top labels will
      # overlap the title by two pixels, but this is a rarer case than long
      # bottom labels overlapping the bottom of lists and the like.
      render_string title.content, :font => TITLE_FONT, :halign => :centre, :y => BUTTON_FONT.height - 2
    end

    # Renders a <text> element. The origin is top-left.
    #
    # Parameters:
    #   x (integer)         : starting x coordinate of the text container in pixels. Default: 0.
    #   y (integer)         : starting y coordinate of the text container in pixels. Default: 0.
    #   width (integer)     : width of the container in pixels. Default: SCREEN_WIDTH
    #   height (integer)    : height of the container in pixels. Default: SCREEN_HEIGHT
    #   wrap ("yes"|"no")   : wrap lines that are too long for the screen. Default: "no".
    #   halign              : horizontal alignment within the defined container. Default "left".
    #     ("left"|"centre"|
    #     "right")
    #   valign              : vertical alignment within the defined container. Default "top".
    #     ("top"|"centre"|
    #     "bottom")
    #   size                : the text size. Sizes are defined in fonts.rb.
    #     ("small"|"huge")
    def render_text(text)
      if text['size']
        font = eval(text['size'].capitalize)
      else
        font = TEXT_FONT
      end
      if text['width']
        width = text['width'].to_i
      end
      if text['height']
        height = text['height'].to_i
      end
      if text['halign']
        halign = text['halign'].to_sym
      end
      if text['valign']
        valign = text['valign'].to_sym
      end
      x = text['x'].to_i || font.width
      y = text['y'].to_i || font.height
      wrap = text['wrap'] || 'no'
      render_string text.content, :font => font, :y => y, :x => x, :wrap => wrap, :width => width, :height => height, :halign => halign, :valign => valign
    end

    # TODO: Move the alignment stuff to StringFormatter and fix it for multi-line stuff.
    def render_string(text, options = {})
      options.delete_if { |key, value| value.nil? }
      default_options = { :x => 0, :y => 0, :colour => @black, :font => Small, :valign => :left, :halign => :top, :wrap => 'no', :width => SCREEN_WIDTH, :height => SCREEN_HEIGHT }
      options = default_options.merge options

      if options[:wrap] == 'yes'
        text = wrap_string text, options[:width], options[:font]
      else
        text = truncate_string text, options[:width], options[:font]
      end

      text = cut_lines text, options[:height], options[:font]

      if options[:valign] == :centre
        pixels_high = text.lines.count * options[:font].height
        options[:y] = (options[:height] - pixels_high) / 2
      elsif options [:valign] == :bottom
        options[:y] = options[:height] - (text.lines.count * options[:font].height) - options[:font].descender_height
      end
      options[:y] += options[:font].height

      if options[:halign] == :centre
        pixels_wide = options[:font].width * text.length
        options[:x] = (options[:width] - pixels_wide) / 2
      elsif options [:halign] == :right
        options[:x] = options[:width] - (text.length * options[:font].width)
      end
      @image.stringTTF(options[:colour], options[:font].path, options[:font].size, 0, options[:x], options[:y], text)
    end
  end
end
