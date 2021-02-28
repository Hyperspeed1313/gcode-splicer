%% Primary Command Interpreter
% Takes user inputs in the bash-style format and interprets them into commands
% and variables.
base_constants;
global commands; fetch_commands;
global command_names = fields(commands);

fprintf(['\nG-Code Splicer ',version_number])

while true
	raw_input = input('>> ','s');
	if isempty(raw_input)
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
end