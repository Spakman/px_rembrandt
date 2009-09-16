task :default => :test

desc "Run all the tests"
task :test do
  Dir.glob "#{File.dirname(__FILE__)}/test/*.rb" do |file|
    require file
  end
end
