require "#{File.dirname(__FILE__)}/renderer"
require 'fileutils'
require 'socket'

module Rembrandt
  class UnixSocketListener
    def initialize(socket_filepath, renderer_image_filepath)
      @socket_path = socket_filepath
      try_to_connect_to_socket
      @renderer = Renderer.new renderer_image_filepath
    end

    def listen_and_process
      loop do
        client = @socket.accept
        request = ""
        while byte = client.read(1)
          request += byte
        end
        client.close
        @renderer.render(request) unless request.empty?
      end
    end

    protected

    # Checks if a process is already listening on the socket. If not, removes the 
    # socket file (if it's there) and starts a server. Throws an Errno::EADDRINUSE
    # exception if an existing server is detected.
    def try_to_connect_to_socket
      unless File.exists? @socket_path
        connect_to_socket
      else
        begin
          # test for a server on the socket
          test_socket = UNIXSocket.open(@socket_path)
          test_socket.close # got this far - seems like there is a server already
          raise Errno::EADDRINUSE.new("it seems like there is already a process listening on #{@socket_path}")
        rescue Errno::ECONNREFUSED
          # probably not a server on that socket - start one
          FileUtils.rm(@socket_path, :force => true)
          connect_to_socket
        end
      end
    end

    def connect_to_socket
      @socket = UNIXServer.open(@socket_path)
      FileUtils.chmod 0770, @socket_path
      @socket.listen 10
    end
  end
end
