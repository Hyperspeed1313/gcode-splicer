function [] = show_help(varargin)
	global command_names;
	global commands;
	disp('exit - Quit this program.')
	for i = 1:length(command_names)
		disp([command_names{i},' - ',commands.(command_names{i}).helptext])
	end
end