#!/usr/bin/env ruby
require 'gtk2'

$version = "1.27.5"

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
    along with NDSTrim.  If not, see <http://www.gnu.org/licenses/>
"

class NDSTrimWindow < Gtk::Window
  def initialize
    super("NDSTrim")
    border_width = 10
    signal_connect("destroy") {Gtk.main_quit}

    if File.exist?("/usr/share/pixmaps/ndstrim.png")
      set_icon(Gdk::Pixbuf.new("/usr/share/pixmaps/ndstrim.png"))
    end

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
    name_column = Gtk::TreeViewColumn.new('Name', name_rend, :text => 0)
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
    @in_folder.current_folder = ENV['HOME']
    @in_folder.signal_connect("current-folder-changed") {load_roms}

    hbox_in_folder = Gtk::HBox.new
    hbox_in_folder.pack_start(Gtk::Label.new("Input Folder:"), false, true, 15)\
    .pack_start(@in_folder, true, true, 10)

    @out_folder = Gtk::FileChooserButton.new("Folder", Gtk::FileChooser::ACTION_SELECT_FOLDER)
    @out_folder.current_folder = ENV['HOME']

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
    Dir.entries(@in_folder.current_folder).each do |rom|
      if File.extname(rom) == ".nds"
        iter = @liststore.append
        iter[0] = rom.to_s
        iter[1] = File.join(@in_folder.current_folder, rom)
        update_log("Added #{rom}\n")
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
        rom = UntrimmedRom.new(rom_name)
        if rom.trim_rom(File.join(@out_folder.current_folder, base_name))
          model.remove(model.get_iter(path))
        end
      end
    end
  end

  #about dialog
  def about
    Gtk::AboutDialog.show(nil,
                          "authors" => ["recover <recover89@gmail.com>", "Azimuth <4zimuth@gmail.com>"],
                          "comments" => "NDSTrim open source NDS rom trimmer",
                          "copyright" => "Copyright (C) 2007 NDSTrim Project",
                          "logo" => Gdk::Pixbuf.new("/usr/share/pixmaps/ndstrim.png"),
                          "license" => $license,
                          "name" => "NDSTrim",
                          "version" => $version,
                          "website" => "http://www.code.google.com/p/ndstrim",
                          "website_label" => "NDSTrim Project Website")
  end
end

#A big thanks to recover for help helping a noob understand
#nds trimmers :)
class UntrimmedRom
  attr_reader :file_name, :rom_size, :wifi_block
  def initialize(file_name)
    @file_name = file_name
    @rom_size = (IO.read(file_name, 4, 128)).unpack("I")[0]

    unless File.size(file_name) == @rom_size
      @wifi_block = (IO.read(file_name, 136, @rom_size)).unpack("I")[0]
    end
  end


  def check_wifi_block
    #Checks for wifi_block
    #90977 is the value if the wifi block exists
    if @wifi_block == 90977
      return true
    else
      return false
    end
  end

  def trim_rom(out_file_name)
    if check_wifi_block
      #Append wifi block if it exists
      adjusted_rom_size = @rom_size + 136
      else
      adjusted_rom_size = @rom_size
    end

    unless @rom_size == File.size(@file_name)
      unless @file_name == out_file_name || out_file_name.nil?
        #Appends bytes till adjusted_rom_size to new file
        File.open(out_file_name, 'w') {|rom|
          rom.syswrite(IO.read(@file_name, adjusted_rom_size))}
      else
        #truncates file in place
        File.open(@file_name, "w") {|rom|
          rom.truncate(adjusted_rom_size)}
      end
    else
      puts "Rom already trimmed"
      return 0
    end
  end
end

if __FILE__ == $0
  Gtk.init
  NDSTrimWindow.new
  Gtk.main
end
