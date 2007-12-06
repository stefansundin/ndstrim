#!/usr/bin/env ruby

#ndstrim daemon, automatically trims roms placed in its watch directory.

require 'lib/filesystemwatcher'
require 'lib/trim-module'
require 'yaml'

class NDSWatcher

  include Trimmer

  def initialize
    @config = YAML.load_file("daemon.conf")
    @path = @config["path"]
    @target_path = @config["target_path"]
    @ndstrim = @config["ndstrim"]
    sleep = @config["sleep"]

    #start message
    print "\e[35mndstrim daemon 1.27\n
\e[32mWatching: \e[34m#@path
\e[32mTarget: \e[34m#@target_path\e[0m\n\n"

    #check for path existance, create if none exists
    unless File.exist?(@path); Dir.mkdir(@path); end
    unless File.exist?(@target_path); Dir.mkdir(@target_path); end

    #create new filesystemwatchers
    ndswatch = FileSystemWatcher.new
    rarwatch = FileSystemWatcher.new
    zipwatch = FileSystemWatcher.new
    seven_zwatch = FileSystemWatcher.new
    tarwatch = FileSystemWatcher.new

    #specify watch directory and pattern to watch
    ndswatch.addDirectory(@path, "*.nds")
    rarwatch.addDirectory(@path, "*.rar")
    zipwatch.addDirectory(@path, "*.zip")
    seven_zwatch.addDirectory(@path, "*.7z")
    tarwatch.addDirectory(@path, "*.tar.gz")
    tarwatch.addDirectory(@path, "*.tar.bz2")

    #set loop sleep time
    ndswatch.sleepTime = rarwatch.sleepTime = tarwatch.sleepTime =\
    zipwatch.sleepTime = seven_zwatch.sleepTime = sleep

    ndswatch.start do |status, file|
      if status == FileSystemWatcher::CREATED
        puts "\n\e[34m#{file} added, trimming...\e[0m"
        trim_nds(file)
      elsif status == FileSystemWatcher::DELETED
        puts "\e[31mdeleted: #{file}\e[0m"
      end
    end

    rarwatch.start do |status, file|
      if status == FileSystemWatcher::CREATED
        puts "\e[34m#{file} added, unraring...\e[0m"
        unrar(file)
      elsif status == FileSystemWatcher::DELETED
        puts "\e[31mdeleted: #{file}\e[0m"
      end
    end

    zipwatch.start do |status, file|
      if status == FileSystemWatcher::CREATED
        puts "\e[34m#{file} added, unzipping...\e[0m"
        unzip(file)
      elsif status == FileSystemWatcher::DELETED
        puts "\e[31mdeleted: #{file}\e[0m"
      end
    end

    seven_zwatch.start do |status, file|
      if status == FileSystemWatcher::CREATED
        puts "\e[34m#{file} added, extracting 7z...\e[0m"
        sevenz(file)
      elsif status == FileSystemWatcher::DELETED
        puts "\e[31mdeleted: #{file}\e[0m"
      end
    end

    tarwatch.start do |status, file|
      if status == FileSystemWatcher::CREATED
        puts "\e[34m#{file} added, untarring...\e[0m"
        untar(file)
      elsif status == FileSystemWatcher::DELETED
        puts "\e[31mdeleted: #{file}\e[0m"
      end
    end

    ndswatch.join
    rarwatch.join
    zipwatch.join
    seven_zwatch.join
    tarwatch.join
  end
end

NDSWatcher.new
