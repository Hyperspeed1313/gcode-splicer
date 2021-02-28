function [] = show_help(args)
	global commands;
	if isempty(args)
		command_names = fieldnames(commands);
		disp('exit - Quit this program.')
		for i = 1:length(command_names)
			disp([command_names{i},' - ',commands.(command_names{i}).helptext])
		end
	elseif ~isempty(find(strcmp(args{1},command_names)))
		disp(commands.(args{1}).helptext_long);
	end
end