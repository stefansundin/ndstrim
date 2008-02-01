#!/usr/bin/env ruby
require 'gtk2'

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
    .pack_start(about_button, true, true, 5)

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

        File.open(rom_name, "r+b") do |file|
          rom = NDSRom.new(file)
          rom.trim(File.join(@out_folder.current_folder, base_name))
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
  attr_reader :file_name, :rom_size, :wifi_block

  def initialize(file)

    @file_name = file

    #First we check the file size, if that is correct we
    #read the rom size in the header. If the rom size in the header is not
    #zero we proceed to reading the wifi block and checking whether or not
    #it is present. The final check before trimming is to check if the rom
    #has already been trimmed.
    check_file_size
    read_rom_size

    #if the return from the read_wifi_block method is non zero
    #then the file has the 136 bytes after the rom_size in the
    #header, otherwise those 136 bytes dont exist and the rom
    #is most likely trimmed.
    if read_wifi_block
      check_wifi_block
    end

    #After appending the rom_size according to the rom type
    #the rom is finally checked for previous trims.
    check_trimmed
  end

  def check_file_size

    #If the rom size is less that 0x200 the file is the size
    #of the nds rom header, meaning there is no rom data.
    if File.size(@file_name) <= 0x200
      raise_error("File too small")
    end
  end

  def read_rom_size

    #seek to 0x80 and read four bytes, this
    #is the location of the rom size in the header
    #rewind back to file start.
    @file_name.seek(0x80)
    @rom_size = @file_name.read(4).unpack('I')[0]
    @file_name.rewind

    if @rom_size == 0
      raise_error("Rom Size in Header is zero")
    end
  end

  def read_wifi_block

    #seek to the rom size in the header, read the next 136
    #bytes after this, which is the wifi block.
    @file_name.seek(@rom_size)
    @wifi_block = @file_name.read(136)
    @file_name.rewind

    #return the wifi_block back to the caller.
    return @wifi_block
  end

  def check_wifi_block

    #The wifi block is 136 bytes long, if it doesn't exist it will be padded like all the
    #data after the rom size in the header. ROMs are usually padded with FF or 00,
    #we check for both these paddings. If the 136 bytes after the rom_size is neither then
    #it must contain a working wifi_block.
    unless @wifi_block == ("\000" * 136) || @wifi_block == ("\377" * 136)
      puts "Wifi block exists"

      #Append wifi block if it exists.
      @rom_size = @rom_size + 136
    else
      return false
    end
  end

  def check_trimmed
    #If the current ROM size is equal to the theoretical ROM
    #size(the rom size in header + wifi block) then the ROM
    #has been (correctly)trimmed before.

    if @rom_size == File.size(@file_name)
      raise_error("Rom has already been trimmed")
    end
  end

  def trim(out_file_name=nil)

    unless @file_name == out_file_name || out_file_name.nil?

      #While the rom's offset is less than the size it should be trimmed to
      #write the number of bytes defined in the buffer from the untrimmed
      #file to the trimmed file. Once the ROM's offset + the buffer is greater
      #than the size it should be the buffer is redefined to be the required rom_size
      #subtracted by the rom offset, which is essentially the bytes left to be written
      #to the new file so that it equals the required size.
      File.open(out_file_name, 'wb') do |rom|
        buffer = 1_000_000
        while rom.pos < @rom_size
          if rom.pos + buffer > @rom_size
            buffer = @rom_size - rom.pos
          end
          rom.write(@file_name.read(buffer))
        end
      end
    else

      #Truncates file in place.
      @file_name.truncate(@rom_size)
    end
  end

  def raise_error(error)

    #Some sort of error handling should go here.
    puts error
  end
end

Gtk.init
NDSTrimWindow.new
Gtk.main
