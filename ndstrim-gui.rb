#!/usr/bin/env ruby
require 'gtk2'
require 'base64'

$license = "
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
  along with NDSTrim.  If not, see <http://www.gnu.org/licenses/>"

$version = "1.27.5"

$BUFFER = 1_000_000 #1MB


class NDSTrimWindow < Gtk::Window
  def initialize
    super("NDSTrim")
    border_width = 10
    signal_connect("destroy") {Gtk.main_quit}

    #Detect OS
    if RUBY_PLATFORM =~ /linux/
      @home = ENV['HOME']
      @icon_filename = '/usr/share/pixmaps/ndstrim.png'
    elsif RUBY_PLATFORM =~ /win32/
      @home = ENV['USERPROFILE']
      @icon_filename = File.join(File.dirname(__FILE__), "ndstrim.png")
    end

    #Load icon
    if File.exist?(@icon_filename)
      @icon = Gdk::Pixbuf.new(@icon_filename)
    end

    set_icon(@icon)
    set_resizable(true)
    set_default_size(500, 450)

    #create a list store
    @liststore = Gtk::ListStore.new(String, String)

    #create tree view
    @treeview = Gtk::TreeView.new(@liststore)
    @treeview.selection.mode = Gtk::SELECTION_SINGLE
    @treeview.rules_hint = true

    #create text renderer, pack it into 'name' column, it grabs file names from rom[0]
    name_rend = Gtk::CellRendererText.new
    name_column = Gtk::TreeViewColumn.new("Name", name_rend, :text => 0)
    name_column.max_width=(250)
    name_column.set_resizable(true)

    #append 'name' column to treeview
    @treeview.append_column(name_column)

    path_rend = Gtk::CellRendererText.new
    path_column = Gtk::TreeViewColumn.new("Path", path_rend, :text => 1)
    path_column.resizable=(true)
    @treeview.append_column(path_column)

    #create scrolled window and pack treeview
    scrolled_roms = Gtk::ScrolledWindow.new
    scrolled_roms.shadow_type = Gtk::SHADOW_ETCHED_IN
    scrolled_roms.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
    scrolled_roms.add(@treeview)

    #create text view for log
    @log_buffer = Gtk::TextBuffer.new
    log_text = Gtk::TextView.new(@log_buffer)
    log_text.cursor_visible=(false)
    log_text.set_editable(false)
    log_text.set_size_request(200, 200)

    #create notebook to store different pages
    notebook = Gtk::Notebook.new
    notebook.homogeneous=(true)
    notebook.append_page(scrolled_roms).append_page(log_text)
    notebook.set_tab_label(scrolled_roms, Gtk::Label.new("Roms"))
    notebook.set_tab_label(log_text, Gtk::Label.new("Log"))

    @in_folder = Gtk::FileChooserButton.new("Input Folder", Gtk::FileChooser::ACTION_SELECT_FOLDER)
    @in_folder.current_folder = @home
    @in_folder.signal_connect("current-folder-changed") {load_roms}

    hbox_in_folder = Gtk::HBox.new
    hbox_in_folder.pack_start(Gtk::Label.new("Input Folder:"), false, true, 15)\
      .pack_start(@in_folder, true, true, 10)

    @out_folder = Gtk::FileChooserButton.new("Folder", Gtk::FileChooser::ACTION_SELECT_FOLDER)
    @out_folder.current_folder = @home

    #create hbox to pack output folder and its label
    hbox_out_folder = Gtk::HBox.new
    hbox_out_folder.pack_start(Gtk::Label.new("Output Folder:"), false, true, 10 )\
      .pack_start(@out_folder, true, true, 10)

    #create bottom buttons and connect them to coressponding methods
    trim_button = Gtk::Button.new("Trim")
    trim_button.signal_connect("clicked") {trim}

    add_button = Gtk::Button.new("Add")
    add_button.signal_connect("clicked") {add_roms}

    delete_button = Gtk::Button.new("Delete")
    delete_button.signal_connect("clicked") {delete_roms}

    clear_button = Gtk::Button.new("Clear")
    clear_button.signal_connect("clicked") {clear_roms}

    about_button = Gtk::Button.new("About")
    about_button.signal_connect("clicked") {about}

    #create hbox to pack buttons horizontally
    hbox_buttons = Gtk::HBox.new
    hbox_buttons.pack_start(add_button, true, true, 5)\
      .pack_start(delete_button, true, true, 5)\
      .pack_start(clear_button, true, true, 5)\
      .pack_start(trim_button, true, true, 5)\
      .pack_start(about_button, true, true, 5) #comment line to diable the about button

    #create vbox and pack notebook
    vbox_main = Gtk::VBox.new
    vbox_main.pack_start(notebook, true, true, 5)\
      .pack_start(Gtk::HSeparator.new, false, false, 10)\
      .pack_start(hbox_in_folder, false, true, 5)\
      .pack_start(hbox_out_folder, false, true, 5)\
      .pack_start(Gtk::HSeparator.new, false, false, 10)\
      .pack_start(hbox_buttons, false, true, 5)

    #add vbox main to window and show all widgets
    add(vbox_main)
    show_all
  end

  def update_log(text)
    @log_buffer.insert_at_cursor(text)
  end

  #load roms upon folder change, picks up Dir.entries and check extension for '.nds'
  def load_roms
    Dir.entries(@in_folder.current_folder).each do |filename|
      if File.extname(filename) == ".nds"
        iter = @liststore.append
        iter[0] = filename.to_s
        iter[1] = File.join(@in_folder.current_folder, filename)
        update_log("Added #{filename}\n")
        rom = NDSRom.new(File.join(@in_folder.current_folder, filename))
      end
    end
  end

  #add roms via 'add' button
  def add_roms
    dialog = Gtk::FileChooserDialog.new("Rom File", nil, Gtk::FileChooser::ACTION_OPEN,
      nil, [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
      [Gtk::Stock::OPEN, Gtk::Dialog::RESPONSE_ACCEPT])
    dialog.current_folder = @in_folder.current_folder
    dialog.add_filter(Gtk::FileFilter.new.set_name("*.nds").add_pattern("*.nds"))
    dialog.add_filter(Gtk::FileFilter.new.set_name("All Files").add_pattern("*"))
    if dialog.run == Gtk::Dialog::RESPONSE_ACCEPT
      iter = @liststore.append
      iter[0] = File.basename(dialog.filename)
      iter[1] = dialog.filename
      rom = NDSRom.new(dialog.filename)
      update_log("Added #{dialog.filename}\n")
    end
    dialog.destroy
  end

  #delete roms via 'delete' button
  def delete_roms
    selection = @treeview.selection
    file = selection.selected
    @liststore.remove(file) unless file == nil
  end

  #clear list of roms
  def clear_roms
    @liststore.clear
  end

  #loop over each element of liststore, trimming them until the first element of the row is nil
  def trim
    while @liststore.iter_first
      @liststore.each do |model, path, iter|
        rom_name = model.get_value(model.get_iter(path), 1)
        base_name = model.get_value(model.get_iter(path), 0)
        rom = NDSRom.new(rom_name)
        if rom.error?
          update_log("#{rom.error?}\n")
        else
          rom.trim(File.join(@out_folder.current_folder, base_name))
          update_log("Trimmed #{base_name}.\n")
        end
        model.remove(model.get_iter(path))
      end
    end
  end

  #about dialog
  def about
    Gtk::AboutDialog.show(nil,
      "authors" => ["recover <recover89@gmail.com>", "Azimuth <4zimuth@gmail.com>"],
      "comments" => "NDSTrim open source NDS rom trimmer",
      "copyright" => "Copyright (C) 2007 NDSTrim Project",
      "logo" => @icon,
      "license" => $license,
      "name" => "NDSTrim",
      "version" => $version,
      "website" => "http://www.code.google.com/p/ndstrim",
      "website_label" => "NDSTrim Project Website")
  end
end

class NDSRom
  attr_reader :filename, :input, :romsize, :romsize_with_wifi, :wifi_block, :wifi_data, :errorcode

  def initialize(fname)
    @filename = fname
    @error = false

    #Get filesize
    @filesize = File.size(@filename)
    if @filesize <= 0x200
      @error = "Error: '#{@filename}' is too small to contain a NDS cartridge header (corrupt rom?)"
      puts @error
      return 1
    end

    #Get romsize
    @input = File.new(@filename, 'rb')
    @input.seek(0x80)
    @romsize = @input.read(4).unpack('I')[0]
    @input.rewind
    if @filesize < @romsize
      @error = "Error: '#{@filename}' is too small to contain the whole rom (corrupt rom?)"
      puts @error
      return 1
    end

    #There is size for a possible WiFi block, check if it's there
    if @filesize >= @romsize + 136
      @input.seek(@romsize)
      @wifi_data = @input.read(136)
      @input.rewind

      if "\377" * 136 == wifi_data || "\000" * 136 == wifi_data
        #WiFi data consists of 0xFF or WiFi data consists of 0x00
        @wifi_block = false
      else
        #WiFi data consists of things that are not 0xFF.. or 0x00..
        @wifi_block = true
      end
    else
      #We might also get here if the rom have been trimmed to romsize by mistake before (nothing we can do about it)
      @wifi_block = false
    end

    if @wifi_block
      @romsize_with_wifi = @romsize + 136
    else
      @romsize_with_wifi = @romsize
    end
  end

  def error?
    return @error
  end

  def trim(out_fname)
    if @romsize == @filesize
      puts "Warning: #{@filename} is the same size as the trimmed rom will be (already trimmed?)"
    end

    if !out_fname.nil? && @filename != out_fname
      #Copy @input to @output in chunks
      @output = File.new(out_fname, 'wb')

      @tocopy = $BUFFER
      while @output.tell < @romsize_with_wifi
        if @output.tell+$BUFFER > @romsize_with_wifi
          @tocopy = @romsize_with_wifi-@output.tell
        end
        @output.write(@input.read(@tocopy))
      end
    else
      #Truncate file in place
      @input.close
      File.truncate(@filename, @romsize_with_wifi)
    end
  end
end

if __FILE__ == $0
  Gtk.init
  NDSTrimWindow.new
  Gtk.main
end
