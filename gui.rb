#!/usr/bin/env ruby
require 'gtk2'

class NDSTrimWindow < Gtk::Window
  def initialize
    super("NDSTrim")
    signal_connect("destroy") {Gtk.main_quit}
    if File.exist?('icon.ico')
      set_icon(Gdk::Pixbuf.new('icon.ico'))
    end
    set_default_size(300, 40)
    set_resizable(true)
    
    @output_folder = Gtk::FileChooserButton.new("Output Folder",
                                                Gtk::FileChooser::ACTION_SELECT_FOLDER)
    @output_label = Gtk::Label.new("Output: ")
    
    @input_file = Gtk::FileChooserButton.new("Input File",
                                             Gtk::FileChooser::ACTION_OPEN)
    @input_label = Gtk::Label.new("Rom: ")
    filter_nds = Gtk::FileFilter.new.set_name("*.nds").add_pattern("*nds")
    @input_file.add_filter(filter_nds)
    
    @trim_button = Gtk::Button.new("Trim")
    @trim_button.signal_connect("clicked") {trim}
    
    hbox_input = Gtk::HBox.new
    hbox_input.pack_start(@input_label, false, false, 8).pack_start(@input_file, true, true, 5)
    
    hbox_out = Gtk::HBox.new
    hbox_out.pack_start(@output_label, false, false, 2).pack_start(@output_folder, true, true, 5)
    
    vbox_main = Gtk::VBox.new
    vbox_main.pack_start(hbox_input, false, false, 10).pack_start(hbox_out, false, false, 0)\
    .pack_start(Gtk::HSeparator.new , false, false, 12).pack_start(@trim_button, false, false, 0)
    
    add(vbox_main)
    show_all
  end

  def trim
    rom = @input_file.filename.split('/')
    name = rom[-1]
    @outplace = @output_folder.filename.to_s + '/' + name.to_s
    unless system("./ndstrim '#{@input_file.filename}' '#{@outplace}'")
      Dialog.new("Trimming Failed", "Unable to trim rom")
    else
      Dialog.new("File Trimmed", "Trimming successful")
    end
  end
end

class Dialog < Gtk::Dialog
  def initialize(title, message)
    super(title)
    set_default_size(250, 10)
    add_button(Gtk::Stock::OK, Gtk::Dialog::RESPONSE_REJECT)
    signal_connect("response") {destroy}
    vbox.add(Gtk::Label.new(message))
    show_all
  end
end

Gtk.init
NDSTrimWindow.new
Gtk.main
