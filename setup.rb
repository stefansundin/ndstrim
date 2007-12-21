#!/usr/bin/env ruby

=begin
This file is part of NDSTrim.

NDSTrim is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

NDSTrim is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with NDSTrim.  If not, see <http://www.gnu.org/licenses/>
=end

require 'fileutils'

include FileUtils::Verbose
#include FileUtils::DryRun

#check if files exist
def check_install
  print "Checking if files exist..\n\n"
  ["/usr/bin/ndstrim", "/usr/bin/ndstrim-gui.rb"].each do |file|
    raise "#{file} doesn't exist" unless File.exist?(file)
  end
  print "Files are teh finez!\n" #damn you lolcode :(
end

#check if files don't exist
def check_uninstall
  print "Checking if files exist..\n\n"
  ["/usr/bin/ndstrim", "/usr/bin/ndstrim-gui.rb"].each do |file|
    raise "Please install ruby-gnome2" unless File.exist?(File.join($LOAD_PATH[0], "gtk2.rb"))
    raise "#{file} exists in filesystem" if File.exist?(file)
  end
  print "No files found\n\n"
end

#copy over files
def install
  print "Copying files..\n"
  cp("bin/ndstrim", "/usr/bin/ndstrim")
  cp("extended-gui.rb", "/usr/bin/ndstrim-gui.rb")
  chmod(0755, %w{/usr/bin/ndstrim /usr/bin/ndstrim-gui.rb})
  cp("src/ndstrim.desktop", "/usr/share/applications/ndstrim.desktop")
  cp("src/ndstrim.png", "/usr/share/pixmaps/ndstrim.png")
  chmod(0644, %w{/usr/share/pixmaps/ndstrim.png /usr/share/applications/ndstrim.desktop})
  print "Done\n\n"
end

#delete files
def uninstall
  print "Removing files..\n"
  rm("/usr/share/pixmaps/ndstrim.png")
  rm("/usr/share/applications/ndstrim.desktop")
  rm("/usr/bin/ndstrim")
  rm("/usr/bin/ndstrim-gui.rb")
end

#install: check if files don't exist, copy, check if files exist
if ARGV[0] == "install"
  check_uninstall unless ARGV[1] == "force"
  install
  check_install
#uninstall: check if files exist, delete, check if files don't exist
elsif ARGV[0] == "uninstall"
  check_install unless ARGV[1] == "force"
  uninstall
  check_uninstall
elsif ARGV[0] == "--help" || ARGV.length < 1
  puts "Install: ruby #$0 install"
  puts "Uninstall: ruby #$0 uninstall"
  puts "Overwrite: ruby #$0 install force"
  puts "Force Removal: ruby #$0 uninstall force"
end
