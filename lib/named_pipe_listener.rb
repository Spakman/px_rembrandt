# Copyright (C) 2009-2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the General Public License (GPL) version 3.
# See COPYING

require "fileutils"
require_relative "renderer"

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

    # Returns the last request that is available on the pipe. If no requests
    # are available, this method blocks.
    #
    # Invalid lines are ignored. A request consists of a message header and the
    # markup to render. The message header is of the form (terminated by a
    # newline character):
    #
    # <render X>
    #
    # where X is the number of bytes in the request that follows.
    #
    # TODO: should this be using IO.sysread?
    #
    # http://www.slideshare.net/feyeleanor/the-ruby-guide-to-nix-plumbing-hax0r-r3dux
    def get_latest_request
      IO.select([ @pipe ], nil, nil, nil)
      begin
        header = @pipe.gets
        if header =~ /^<render (\d{1,4})>\n$/
          request = @pipe.read $1.to_i
        end
      end while IO.select([ @pipe ], nil, nil, 0)
      request
    end

    # Listens for requests on the named pipe and hands them over to the
    # renderer.
    def listen_and_process
      loop do
        request = get_latest_request
        @renderer.render(request) unless request.nil?
      end
    end
  end
end
