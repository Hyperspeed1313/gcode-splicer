function[] = fetch_commands()
global commands
commands.help.func = @show_help;
commands.help.args = [0,1];
commands.help.helptext = "Displays this text."

% open
commands.open.func = @open_gcode_file;
commands.open.args = 0;
commands.open.helptext = "Open a gcode file."

% insert
commands.insert.func = @insert_line;
commands.insert.args = 4; % Source file, source layers, dest layers?
commands.insert.helptext = "Insert line from one open gcode file into another."