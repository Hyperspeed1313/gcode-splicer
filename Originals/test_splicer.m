starting_code = ["; Ender 3 v2 Custom Start G-code",char(10),...
"G92 E0 ; Reset Extruder",char(10),...
"G28 ; Home all axes",char(10),...
"G1 Z2.0 F3000 ; Move Z Axis up little to prevent scratching of Heat Bed",char(10),...
"G1 X0.1 Y20 Z0.3 F5000.0 ; Move to start position",char(10),...
"G1 X0.1 Y200.0 Z0.3 F1500.0 E15 ; Draw the first line",char(10),...
"G1 X0.4 Y200.0 Z0.3 F5000.0 ; Move to side a little",char(10),...
"G1 X0.4 Y20 Z0.3 F1500.0 E30 ; Draw the second line",char(10),...
"G92 E0 ; Reset Extruder",char(10),...
"G1 Z2.0 F3000 ; Move Z Axis up little to prevent scratching of Heat Bed",char(10),...
"G1 X5 Y20 Z0.3 F5000.0 ; Move over to prevent blob squish"];

ending_code = ["G91 ;Relative positioning",char(10),...
"G1 E-2 F2700 ;Retract a bit",char(10),...
"G1 E-2 Z0.2 F2400 ;Retract and raise Z",char(10),...
"G1 X5 Y5 F3000 ;Wipe out",char(10),...
"G1 Z10 ;Raise Z more",char(10),...
"G90 ;Absolute positionning"];

layer_marker = "^;LAYER:[0-9]+";
absolute_mode_call = '^G90';
relative_mode_call = '^G91';
set_position_call = '^G92';

% Newline is char(10)

% E is extrusion value
% M25 is command to pause print until further input
% G1 and G0 commands - G0 reserved for non-extrusion typically
% Need code to construct variable order G0/G1 sequence and extract values

doc_num = 1;
[filename,filepath] = uigetfile('*.gcode');
if filename == 0
	return
end

fid = fopen(fullfile(filepath,filename));
raw_text = char(fread(fid))';
fclose(fid);

newlines = [0,find(raw_text == char(10)),numel(raw_text)+1];
n_lines = length(newlines)-1;

lined_text = cell(n_lines,1);
relative_mode_state = false(n_lines,1);

for i = 1:n_lines
	current_line = rawtext((newlines(i)+1):(newlines(i+1)-1));
	lined_text{i} = current_line;
	e_lines_logic(i) = strcmp(current_line(1:3),'G1 ');
	layer_lines_logic(i) = 1==regexp(current_line,layer_marker,'once');
	relative_mode_call_logic = 1==regexp(current_line,relative_mode_call,'once');
	absolute_mode_call_logic = 1==regexp(current_line,absolute_mode_call,'once');
	if absolute_mode_call_logic
		relative_mode_state(i) = false;
	elseif relative_mode_call_logic
		relative_mode_state(i) = true;
	else
		if i ~= 1
			relative_mode_state(i) = relative_mode_state(i-1)
		else
			relative_mode_state(i) = false;
		end
	end
	set_position_call_logic(i) = 1==regexp(current_line,set_position_call,'once');
	% Set position call necessary for determining if extruder position has been reset.
end

%get_nonempty = @(x) find(~cellfun('isempty',x));
%e_lines = get_nonempty(regexp(lined_text,'^G1 ','once')); % Finds all lines with extrude commands
%layer_lines = get_nonempty(regexp(lined_text,layer_marker,'once')); % Gets lines that define layers
%n_layers = numel(layer_lines);

e_lines = find(e_lines_logic);
layer_lines = find(layer_lines_logic);
set_position_lines = find(set_position_lines_logic);



% Code will split line, extract E step and E step position, convert to relative, then dump rest.
% Will then re-split and re-join line at write-out

% Read out E steps, converting absolute E values to relative. Unless a G91 call
% is specified, all movement is in absolute mode.