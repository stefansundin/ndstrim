require 'gtk2'

treestore = Gtk::TreeStore.new(String, String, Integer)

# Append a toplevel row and fill in some data
parent = treestore.append(nil)
parent[0] = "Maria"
parent[1] = "Incognito"

# Append a second toplevel row and fill in some data
parent = treestore.append(nil)
parent[0] = "Jane"
parent[1] = "Average"
parent[2] = 1962

# Append a child to the second toplevel row and fill in some data
child = treestore.append(parent)
child[0] = "Janinita"
child[1] = "Average"
child[2] = 1985

view = Gtk::TreeView.new(treestore)
view.selection.mode = Gtk::SELECTION_NONE

# Create a renderer
renderer = Gtk::CellRendererText.new

# Add column using our renderer
col = Gtk::TreeViewColumn.new("First Name", renderer, :text => 0)
view.append_column(col)

# Create another renderer and set the weight property
renderer = Gtk::CellRendererText.new
renderer.weight = Pango::FontDescription::WEIGHT_BOLD

# Add column using the second renderer
col = Gtk::TreeViewColumn.new("Last Name", renderer, :text => 1)
view.append_column(col)

# Create one last renderer and set the foreground color to red
renderer = Gtk::CellRendererText.new
renderer.foreground = "red"

# Add column using the third renderer
col = Gtk::TreeViewColumn.new("Age", renderer)
view.append_column(col)

# Create a cell data function to calculate age
col.set_cell_data_func(renderer) do |col, renderer, model, iter|
  year_now = 2003 # To save code not relevent to the example
  year_born = iter[2]

  if (year_born <= year_now) && (year_born > 0)
    renderer.text = sprintf("%i years old", year_now - year_born)
    # render in default foreground color if we know the age
    renderer.foreground_set = false
  else
    renderer.text = "age unknown"
    # render with foreground color we set earlier if we don't know the age
    renderer.foreground_set = true
  end
end

window = Gtk::Window.new(Gtk::Window::TOPLEVEL)
window.signal_connect("delete_event") { Gtk.main_quit; exit! }
window.add(view)
window.show_all

Gtk.main
