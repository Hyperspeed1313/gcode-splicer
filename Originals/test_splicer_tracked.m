% Newline is char(10)

gcode{doc_num}.newlines = [0,find(raw_text == char(10)),numel(raw_text)+1];
gcode{doc_num}.n_lines = length(newlines)-1;

gcode{doc_num}.lined_text = cell(n_lines,1);
gcode{doc_num}.relative_mode_state = logical(n_lines,1);

for i = 1:n_lines
	current_line = rawtext((newlines(i)+1):(newlines(i+1)-1));
	gcode{doc_num}.lined_text{i} = current_line;
	e_lines_logic(i) = strcmp(current_line(1:3),'G1 ');
	layer_lines_logic(i) = 1==regexp(current_line,layer_marker,'once');
	relative_mode_call_logic = 1==regexp(current_line,relative_mode_call,'once');
	absolute_mode_call_logic = 1==regexp(current_line,absolute_mode_call,'once');
	if absolute_mode_call_logic
		gcode{doc_num}.relative_mode_state(i) = false;
	elseif relative_mode_call_logic
		gcode{doc_num}.relative_mode_state(i) = true;
	else
		if i ~= 1
			gcode{doc_num}.relative_mode_state(i) = relative_mode_state(i-1)
		else
			gcode{doc_num}.relative_mode_state(i) = false;
		end
	end
	set_position_call_logic(i) = 1==regexp(current_line,set_position_call,'once');
	% Set position call necessary for determining if extruder position has been reset.
end

%get_nonempty = @(x) find(~cellfun('isempty',x));
%e_lines = get_nonempty(regexp(lined_text,'^G1 ','once')); % Finds all lines with extrude commands
%layer_lines = get_nonempty(regexp(lined_text,layer_marker,'once')); % Gets lines that define layers
%n_layers = numel(layer_lines);

gcode{doc_num}.e_lines = find(e_lines_logic);
gcode{doc_num}.layer_lines = find(layer_lines_logic);
gcode{doc_num}.set_position_lines = find(set_position_lines_logic);



% Code will split line, extract E step and E step position, convert to relative, then dump rest.
% Will then re-split and re-join line at write-out

% Read out E steps, converting absolute E values to relative. Unless a G91 call
% is specified, all movement is in absolute mode.