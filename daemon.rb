#!/usr/bin/env ruby
#ndstrim daemon, automatically trims roms placed in its watch directory.
#Easy to extend.

require "lib/filesystemwatcher"

@path = "/path/to/watch/"    
@target_path = "/path/to/target/"
@ndstrim = "/path/to/ndstrim"
@unrar = "/usr/bin/unrar"
@unzip = "/usr/bin/unzip"
@seven_z = "/usr/bin/7z"

sleep = 1

#start message
print "\e[35mndstrim daemon 1.2\n
\e[32mWatching: \e[34m#@path
\e[32mTarget: \e[34m#@target_path\e[0m\n\n"

#-----Don't edit below this------
#check for path existance, create if none exists
unless File.exist?(@path); Dir.mkdir(@path); end
unless File.exist?(@target_path); Dir.mkdir(@target_path); end

#create new filesystemwatchers
ndswatch = FileSystemWatcher.new
rarwatch = FileSystemWatcher.new
zipwatch = FileSystemWatcher.new
seven_zwatch = FileSystemWatcher.new

#specify watch directory and pattern to watch
ndswatch.addDirectory(@path, "*.nds")
rarwatch.addDirectory(@path, "*.rar")
zipwatch.addDirectory(@path, "*.zip")
seven_zwatch.addDirectory(@path, "*.7z")

#set loop sleep time
ndswatch.sleepTime = sleep
rarwatch.sleepTime = sleep
zipwatch.sleepTime = sleep
seven_zwatch.sleepTime = sleep

ndswatch.start do |status, file|
  if (status == FileSystemWatcher::CREATED)
    puts "\e[34m#{file} added, trimming...\e[0m"
    file_name_array = file.split('/')
    file_name = file_name_array[-1]
    if system("#@ndstrim #{file} #{@target_path + file_name}")
      puts "\e[32m#{file} trimmed successfully\e[0m"
      File.delete(file)
    else
      File.open(@target_path + "error_ndstrim." + file_name, "w") {puts "\e[33mtrimming failed!\e[0m"}
    end
  elsif (status == FileSystemWatcher::DELETED)
    puts "\e[31mdeleted: #{file}\e[0m"
  end
end

rarwatch.start do |status, file|
  if (status == FileSystemWatcher::CREATED)
    puts "\e[34m#{file} added, unraring...\e[0m"
    if system("#@unrar x -inul #{file} #@path")
      puts "#{file} unrared successfully"
      File.delete(file)
    else
      puts "\e[33munraring failed!\e[0m"
    end
  elsif (status == FileSystemWatcher::DELETED)
    puts "\e[31mdeleted: #{file}\e[0m"
  end
end

zipwatch.start do |status, file|
  if (status == FileSystemWatcher::CREATED)
    puts "\e[34m#{file} added, unzipping...\e[0m"
    if system("#@unzip -qq #{file} -d #@path")
      puts "#{file} unzipped successfully"
      File.delete(file)
    else
      puts "\e[33munzipping failed!\e[0m"
    end
  elsif (status == FileSystemWatcher::DELETED)
    puts "\e[31mdeleted: #{file}\e[0m"
  end
end

seven_zwatch.start do |status, file|
  if (status == FileSystemWatcher::CREATED)
    puts "\e[34m#{file} added, extracting 7z...\e[0m"
    if system("#@seven_z x -bd -o#@path #{file}")
      puts "#{file} extracted successfully"
      File.delete(file)
    else
      puts "\e[33mextraction failed\e[0m"
    end
  elsif (status == FileSystemWatcher::DELETED)
    puts "\e[31mdeleted: #{file}\e[0m"
  end
end

#loop
ndswatch.join
rarwatch.join
seven_zwatch.join
