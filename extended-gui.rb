#!/usr/bin/env ruby
require 'gtk2'

class NDSTrimWindow < Gtk::Window
  def initialize
    super("NDSTrim")
    border_width = 10
    signal_connect("destroy") {Gtk.main_quit}

    #check if ndstrim's icon is available
    if File.exist?("src/ndstrim.png")
      set_icon(Gdk::Pixbuf.new("src/ndstrim.png"))
    end

    set_resizable(true)
    set_default_size(400, 350)

    #create a list store
    model = Gtk::TreeStore.new(String, TrueClass, String)

    #create tree view
    treeview = Gtk::TreeView.new(model)
    treeview.rules_hint = false


    #create icon rendererd, pack it into 'icon' column, it grabs icons if they exist with the same name as the rom.
    toggle_rend = Gtk::CellRendererToggle.new
    toggle_column = Gtk::TreeViewColumn.new('Trim?', toggle_rend, :active => 1)
    toggle_column.resizable=(true)

    treeview.append_column(toggle_column)


    #create text renderer, pack it into 'name' column, it grabs file names from rom[0]
    name_rend = Gtk::CellRendererText.new
    name_column = Gtk::TreeViewColumn.new('Name', name_rend, :text => 0)
    name_column.resizable=(true)

    #append 'name' column to treeview
    treeview.append_column(name_column)

    path_rend = Gtk::CellRendererText.new
    path_column = Gtk::TreeViewColumn.new("Path", path_rend, :text => 2)
    path_column.resizable=(true)

    treeview.append_column(path_column)

    #create scrolled window and pack treeview
    scrolled_roms = Gtk::ScrolledWindow.new
    scrolled_roms.shadow_type = Gtk::SHADOW_ETCHED_IN
    scrolled_roms.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
    scrolled_roms.add(treeview)

    #create text view for log
    log_text = Gtk::TextView.new
    log_text.editable=(false)

    #create notebook to store different pages
    notebook = Gtk::Notebook.new
    notebook.homogeneous=(true)
    notebook.append_page(scrolled_roms).append_page(log_text)
    notebook.set_tab_label(scrolled_roms, Gtk::Label.new("Roms"))
    notebook.set_tab_label(log_text, Gtk::Label.new("Log"))

    in_folder = Gtk::FileChooserButton.new("Input Folder", Gtk::FileChooser::ACTION_SELECT_FOLDER)
    #in_folder.current_folder = ENV['HOME']
    in_folder.signal_connect("current-folder-changed") {load_roms(treeview, model, in_folder.filename)}

    hbox_in_folder = Gtk::HBox.new
    hbox_in_folder.pack_start(Gtk::Label.new("Input Folder:"), false, true, 15)\
    .pack_start(in_folder, true, true, 10)

    #output folder
    out_folder = Gtk::FileChooserButton.new("Folder", Gtk::FileChooser::ACTION_SELECT_FOLDER)
    out_folder.current_folder = ENV['HOME']
    out_folder.signal_connect("current-folder-changed") {puts "Out: ", out_folder.filename}

    #create hbox to pack output folder and its label
    hbox_out_folder = Gtk::HBox.new
    hbox_out_folder.pack_start(Gtk::Label.new("Output Folder:"), false, true, 10 )\
    .pack_start(out_folder, true, true, 10)

     #create bottom buttons
    trim_button = Gtk::Button.new("Trim")
    trim_button.signal_connect("clicked") { puts "trimming..."}

    add_button = Gtk::Button.new("Add")
    add_button.signal_connect("clicked") {puts "add"}

    delete_button = Gtk::Button.new("Delete")
    delete_button.signal_connect("clicked") { puts "delete"}

    clear_button = Gtk::Button.new("Clear")
    clear_button.signal_connect("clicked") { puts "clear"}

    #create hbox to pack buttons horizontally
    hbox_buttons = Gtk::HBox.new
    hbox_buttons.pack_start(add_button, true, true, 5)\
    .pack_start(delete_button, true, true, 5)\
    .pack_start(clear_button, true, true, 5)\
    .pack_start(trim_button, true, true, 5)

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


  def load_roms(treeview, model, dir = ENV['HOME'])
    Dir.entries(dir).each do |rom|
      if File.extname(rom) == ".nds"
        root = model.append(nil)
        root[0] = rom.to_s
        root[1] = TRUE
        root[2] = dir + "/" + rom
      end
    end
  end

  def trim

  end

end


if __FILE__ == $0
  Gtk.init
  NDSTrimWindow.new
  Gtk.main
end
