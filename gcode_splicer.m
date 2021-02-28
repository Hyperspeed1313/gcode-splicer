%% Primary Command Interpreter
% Takes user inputs in the bash-style format and interprets them into commands
% and variables.
clear global
clearvars
base_constants; % Load other base variables into memory
global commands;
fetch_commands();
command_names = fieldnames(commands);
global files;
global buffer;
buffer.active = 0;
buffer.changes = [];

fprintf(['\nG-Code Splicer ',version_number,'\n'])

while true
	user_input = input('$> ','s');
	if isempty(user_input)
		continue
	end
	split_input = strsplit(user_input);
	% Remove empty segments
	split_input(cellfun('isempty',split_input)) = [];

	% Validate function call
	if strcmp(split_input{1},'exit')
		return
	elseif isempty(find(strcmp(split_input{1},command_names)))
		disp([split_input{1},' is not a recognized command.'])
		disp('For help, type ''help''');
		continue
	end
	n_args = min(commands.(split_input{1}).args,length(split_input)-1);
	args = cell(1,n_args);
	for i = 1:n_args
		args{i} = split_input{i+1};
	end
	commands.(split_input{1}).func(args);
end