function[] = open_gcode_file()
global files;
global flavor;
l_flavor = flavor;
global compiler;
l_compiler = compiler;
n = length(files)+1;

[f_name,f_path] = uigetfile('*.gcode');
if f_name == 0
	return
end

try % If at any point there is an error, dump all contents associated with target file
	disp(['Loading ',fullfile(f_path,f_name)])
	files(n).path = f_path;
	files(n).name = f_name;

	fid = fopen(fullfile(f_path,f_name));
	raw_text = char(fread(fid))';
	fclose(fid);

	newlines = [0,find(raw_text==char(10)),numel(raw_text)+1];
	files(n).n_lines = length(newlines)-1;

	% Preallocation
	code = cell(files(n).n_lines,1);
	relative_mode_state = false(files(n).n_lines,1);
	e_lines_logic = false(files(n).n_lines,1);
	layer_lines_logic = false(files(n).n_lines,1);
	set_position_call_logic = false(files(n).n_lines,1);
	
	tic
	for i = 1:files(n).n_lines
		current_line = raw_text((newlines(i)+1):(newlines(i+1)-1));
		code{i} = current_line;
		layer_lines_logic(i) = ~isempty(regexp(current_line,compiler.(compiler.active).layer_marker,'once'));
	end
	files(n).code = code;
	files(n).layer_lines = find(layer_lines_logic);
	
catch
	files(n) = []; % Clears all data on current file
	disp(['Error encountered attempting to load ',fullfile(f_path,f_name),char(10),...
		'File was not loaded.'])
end