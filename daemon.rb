#!/usr/bin/ruby -W0

require "lib/filesystemwatcher"
require "lib/servicestate"

@path = "/home/sazeinel/Desktop/my/"
@target_path = "/home/sazeinel/Desktop/spleen/"

print "Welcome to the ndstrim daemon(Ctrl-C to exit).\n
To start patching files please edit the script and
change the @path and @target_path values. Then drop
a .nds file into the path folder you specified.
Enjoy!\n\n"

unless File.exist?(@path) and File.exist?(@target_path)
  Dir.mkdir(@path)
  Dir.mkdir(@target_path)
end

watcher = FileSystemWatcher.new
watcher.addDirectory(@path, "*.nds")
watcher.sleepTime = 3
watcher.start { |status,file|
  if(status == FileSystemWatcher::CREATED)
    puts "#{file} added, trimming..."
    file_name_array = file.split('/')
    file_name = file_name_array[-1]
    if system("./ndstrim #{file} #{@target_path + file_name}")
      puts "#{file} trimmed successfully"
      File.delete(file.to_s)
    end
  elsif(status == FileSystemWatcher::MODIFIED)
    puts "modified: #{file}"
  elsif(status == FileSystemWatcher::DELETED)
    puts "deleted: #{file}"
  end
}

watcher.join()
