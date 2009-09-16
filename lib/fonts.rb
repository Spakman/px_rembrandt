module Rembrandt
  module Fonts
    Font = Struct.new :path, :size, :width, :height, :descender_height
    Small = Font.new "#{File.dirname(__FILE__)}/../fonts/profont.ttf", 7.0, 6, 8, 2
    BUTTON_FONT = Small
    LIST_FONT = Small
    TITLE_FONT = Small
    TEXT_FONT = Small
  end
end
