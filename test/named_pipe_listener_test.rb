require 'test/unit'
require 'fileutils'

require_relative "../lib/named_pipe_listener"

Thread.abort_on_exception = true

class TestRenderer
  attr_reader :rendered, :last_rendered
  def initialize
    @rendered = 0
  end

  def render(markup)
    @rendered += 1
    @last_rendered = markup
  end
end

class NamedPipeListenerTest < Test::Unit::TestCase

  def setup
    @pipe_filepath = "/tmp/named_pipe_test.fifo"
    FileUtils.rm_f @pipe_filepath
    @renderer = TestRenderer.new
  end

  def teardown
    @pipe.close if @pipe
  end

  def open_pipe
    while not File.pipe? @pipe_filepath
      sleep 0.1
    end
    @pipe = File.open @pipe_filepath, "a+"
  end

  def write_request_to_pipe(string)
    @pipe << "<render #{string.length}>\n"
    @pipe << string
    @pipe.flush
    sleep 1
  end

  def test_initialize_no_pipe
    FileUtils.rm_f @pipe_filepath
    Thread.new do
      Rembrandt::NamedPipeListener.new @pipe_filepath, @renderer
    end
    sleep 0.5
    assert File.pipe? @pipe_filepath
  end

  def test_initialize_existing_pipe
    system "mkfifo #{@pipe_filepath}"
    Thread.new do
      Rembrandt::NamedPipeListener.new @pipe_filepath, @renderer
    end
    sleep 0.5
    assert File.pipe? @pipe_filepath
  end

  def test_initialize_existing_non_pipe_file
    File.open @pipe_filepath, "w" do |file|
      file << "Not a pipe"
    end
    assert_raise RuntimeError do
      Rembrandt::NamedPipeListener.new @pipe_filepath, @renderer
    end
  end

  def test_read_single_request
    Thread.new do
      @listener = Rembrandt::NamedPipeListener.new @pipe_filepath, @renderer
      @listener.listen_and_process
    end
    open_pipe
    write_request_to_pipe "Hello"
    assert_equal 1, @renderer.rendered
    assert_equal "Hello", @renderer.last_rendered
  end

  def test_read_multiple_requests_ignoring_junk
    Thread.new do
      @listener = Rembrandt::NamedPipeListener.new @pipe_filepath, @renderer
      @listener.listen_and_process
    end
    open_pipe
    @pipe << "<render 5>\nHellojunk\n<render 6>\nmiddle\njunk\njunk\n<render 7>\nGoodbye"
    @pipe.flush
    sleep 2
    assert_equal 1, @renderer.rendered
    assert_equal "Goodbye", @renderer.last_rendered
  end

  def test_only_display_last_frame_available
    Thread.new do
      @listener = Rembrandt::NamedPipeListener.new @pipe_filepath, @renderer
      @listener.listen_and_process
    end
    open_pipe
    @pipe << "<render 5>\nHello<render 6>\nmiddle<render 7>\nGoodbye"
    @pipe.flush
    sleep 0.2
    assert_equal 1, @renderer.rendered
    assert_equal "Goodbye", @renderer.last_rendered
  end
end
