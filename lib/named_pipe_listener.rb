require "#{File.dirname(__FILE__)}/renderer"
require 'fileutils'

module Rembrandt
  class NamedPipeListener
    def initialize(pipe_filepath, renderer_image_filepath)
      system "mkfifo #{pipe_filepath}"
      @pipe = File.open(pipe_filepath, "r")
      @pipe_for_writing = File.open(pipe_filepath, "w")
      @renderer = Renderer.new renderer_image_filepath
    end

    # Listens for requests on the named pipe and hands them over to the
    # renderer. Invalid lines are ignored. A request consists of a message
    # header and the markup to render. The message header is of the form
    # (terminated by a newline character):
    #
    # <request X>
    #
    # where X is the number of bytes in the request that follows.
    def listen_and_process
      loop do
        header = @pipe.gets
        if header =~ /^<request (\d{1,4})>\n$/
          request = @pipe.read $1.to_i
          @renderer.render(request)
        end
      end
    end
  end
end
