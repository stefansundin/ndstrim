#!/usr/bin/ruby -W0
#ndstrim daemon, automatically trims roms
#placed in its watch directory.
#Easy to extend.

require "lib/filesystemwatcher"

@path = "/mnt/sda4/watch/"    #path to watch
@target_path = "/mnt/sda4/roms/"    #path where trimmed roms are placed
@ndstrim = "/home/sazeinel/git-projects/ndstrim/ndstrim"    #path to ndstrim executable
@unrar = "/usr/bin/unrar"    #path to unrar command
@unzip = "/usr/bin/unzip"    #path to uzip command
@seven_z = "/usr/bin/7z"    #path to 7z command
#@tar = "/bin/tar"    #path to tar command

sleep = 1    #how long for the watcher to loop, 
             #affects speed at which files are detected
             #in the watch directory

#start message
print "ndstrim daemon 1.1\n
Watching: #@path
Target: #@target_path\n\n"

#-----Don't edit below this------
#check for path existance, create if none exists
unless File.exist?(@path); Dir.mkdir(@path); end
unless File.exist?(@target_path); Dir.mkdir(@target_path); end

#create new filesystemwatchers
ndswatch = FileSystemWatcher.new
rarwatch = FileSystemWatcher.new
zipwatch = FileSystemWatcher.new
seven_zwatch = FileSystemWatcher.new
#tarwatch = FileSystemWatcher.new

#specify watch directory and pattern to watch
ndswatch.addDirectory(@path, "*.nds")
rarwatch.addDirectory(@path, "*.rar")
zipwatch.addDirectory(@path, "*.zip")
seven_zwatch.addDirectory(@path, "*.7z")
#tarwatch.addDirectory(@path, "*.bz2")
#tarwatch.addDirectory(@path, "*.gz")

#set loop sleep time
ndswatch.sleepTime = sleep
rarwatch.sleepTime = sleep
zipwatch.sleepTime = sleep
seven_zwatch.sleepTime = sleep
#tarwatch.sleepTime = sleep

#nds file watcher
ndswatch.start do |status, file|
  if (status == FileSystemWatcher::CREATED)
    puts "#{file} added, trimming..."
    file_name_array = file.split('/')
    file_name = file_name_array[-1]
    if system("#@ndstrim #{file} #{@target_path + file_name}")
      puts "#{file} trimmed successfully"
      File.delete(file)
    end
  elsif (status == FileSystemWatcher::DELETED)
    puts "deleted: #{file}"
  end
end

#rar watcher
rarwatch.start do |status, file|
  if (status == FileSystemWatcher::CREATED)
    puts "#{file} added, unraring..."
    if system("#@unrar x -inul #{file} #@path")
      puts "#{file} unrared successfully"
      File.delete(file)
    else
      puts "unraring failed!"
    end
  elsif (status == FileSystemWatcher::DELETED)
    puts "deleted: #{file}"
  end
end

#zip watcher
zipwatch.start do |status, file|
  if (status == FileSystemWatcher::CREATED)
    puts "#{file} added, unzipping..."
    if system("#@unzip #{file} -d #@path")
      puts "#{file} unzipped successfully"
      File.delete(file)
    else
      puts "unzipping failed!"
    end
  elsif (status == FileSystemWatcher::DELETED)
    puts "deleted: #{file}"
  end
end

#7zwatcher
seven_zwatch.start do |status, file|
  if (status == FileSystemWatcher::CREATED)
    puts "#{file} added, extracting 7z..."
    if system("#@seven_z x -bd -o#@path #{file}")
      puts "#{file} extracted successfully"
      File.delete(file)
    else
      puts "extraction failed"
    end
  elsif (status == FileSystemWatcher::DELETED)
    puts "deleted: #{file}"
  end
end

#tarwatcher - testing
=begin
tarwatch.start do |status, file|
  if (status == FileSystemWatcher::CREATED)
    puts "#{file} added, untarring..."
    if system("#@tar -xf #{file} -C #@path")
      puts "#{file} untarred successfully"
    else
      puts "extraction failed"
    end
    File.delete(file)
  elsif (status == FileSystemWatcher::DELETED)
    puts "deleted: #{file}"
  end
end
=end

#loop
ndswatch.join
rarwatch.join
seven_zwatch.join
#tarwatch.join
