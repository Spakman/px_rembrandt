# Copyright (C) 2009 Mark Somerville <mark@scottishclimbs.com>
# Released under the General Public License (GPL) version 3.
# See COPYING

require_relative "renderer"
require 'fileutils'

module Rembrandt
  class NamedPipeListener
    def initialize(pipe_filepath, renderer)
      if File.exists? pipe_filepath and not File.pipe? pipe_filepath
        raise "#{pipe_filepath} exists and is not a pipe!"
      elsif not File.pipe? pipe_filepath
        system "mkfifo #{pipe_filepath}"
      end
      @pipe = File.open(pipe_filepath, "r")
      @pipe_for_writing = File.open(pipe_filepath, "w")
      @renderer = renderer
    end

    # Listens for requests on the named pipe and hands them over to the
    # renderer. Invalid lines are ignored. A request consists of a message
    # header and the markup to render. The message header is of the form
    # (terminated by a newline character):
    #
    # <render X>
    #
    # where X is the number of bytes in the request that follows.
    #
    # TODO: should this be using IO.sysread?
    #
    # http://www.slideshare.net/feyeleanor/the-ruby-guide-to-nix-plumbing-hax0r-r3dux
    def listen_and_process
      loop do
        header = @pipe.gets
        if header =~ /^<render (\d{1,4})>\n$/
          request = @pipe.read $1.to_i
          @renderer.render(request)
        end
      end
    end
  end
end
