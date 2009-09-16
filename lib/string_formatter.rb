module Rembrandt
  module StringFormatter
    def wrap_string(string, width, font)
      chars = width.to_i / font.width
      lines = []

      while not string.empty?
        space_index = nil
        current_line = string[0, chars]
        string = string[chars, string.length] || ""

        if string.start_with?(" ")
          string = string.lstrip
        elsif not current_line.end_with?(" ") and current_line.length == chars
          space_index = current_line.rindex " "
          if space_index
            lines << current_line[0, space_index]
            string = current_line[space_index+1, chars-space_index] + string
          end
        end
        lines << current_line unless space_index
      end
      lines.join("\n")
    end

    def truncate_string(string, width, font)
      chars = width.to_i / font.width
      if string.length > chars
        string[0, chars]
      else
        string
      end
    end

    def cut_lines(string, height, font)
      lines = height.to_i / font.height
      string.split("\n")[0..lines-1].join("\n")
    end
  end
end
