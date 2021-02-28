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
%		code{i} = raw_text((newlines(i)+1):(newlines(i+1)-1));
		e_lines_logic(i) = ~isempty(regexp(current_line,flavor.(flavor.active).e_movement_call,'once'));
		layer_lines_logic(i) = ~isempty(regexp(current_line,compiler.(compiler.active).layer_marker,'once'));
		relative_mode_call_logic = ~isempty(regexp(current_line,flavor.(flavor.active).relative_mode_call,'once'));
		absolute_mode_call_logic = ~isempty(regexp(current_line,flavor.(flavor.active).absolute_mode_call,'once'));
		set_position_call_logic(i) = ~isempty(regexp(current_line,flavor.(flavor.active).set_position_call,'once'));
		% Logs any time the extruder position has been reset
		
		if absolute_mode_call_logic
			% do nothing. Value is already false
		elseif relative_mode_call_logic
			relative_mode_state(i) = true;
		elseif i ~= 1
			relative_mode_state(i) = relative_mode_state(i-1);
		else
			% do nothing. Value is already false
		end
	end
	toc
	disp('Struct done')
	
	tic
	files(n).code = code;
	toc
	disp('Copy done')
	
	tic
%	e_lines_logic = cellfun(@(x) ~isempty(regexp(x,l_flavor.(l_flavor.active).e_movement_call,'once')),files(n).code);
%	layer_lines_logic = cellfun(@(x) ~isempty(regexp(x,l_compiler.(l_compiler.active).layer_marker,'once')),files(n).code);
%	relative_mode_call_logic = cellfun(@(x) ~isempty(regexp(x,l_flavor.(l_flavor.active).relative_mode_call,'once')),files(n).code);
%	absolute_mode_call_logic = cellfun(@(x) ~isempty(regexp(x,l_flavor.(l_flavor.active).absolute_mode_call,'once')),files(n).code);
%	set_position_call_logic = cellfun(@(x) ~isempty(regexp(x,l_flavor.(l_flavor.active).set_position_call,'once')),files(n).code);
	
	files(n).e_lines = find(e_lines_logic);
	files(n).layer_lines = find(layer_lines_logic);
	files(n).set_positiofiles(n).n_lines = find(set_position_call_logic);
	
%	for i = 1:files(n).n_lines
%		if absolute_mode_call_logic
%			relative_mode_state(i) = false;
%		elseif relative_mode_call_logic
%			relative_mode_state(i) = true;
%		elseif i ~= 1
%			relative_mode_state(i) = relative_mode_state(i-1);
%		else
%			relative_mode_state(1) = false;
%		end
%	end	
	files(n).relative_mode_state = relative_mode_state;
	
catch
	files(n) = []; % Clears all data on current file
	disp(['Error encountered attempting to load ',fullfile(f_path,f_name),char(10),...
		'File was not loaded.'])
end