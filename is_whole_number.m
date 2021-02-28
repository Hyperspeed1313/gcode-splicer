function[arg] = is_whole_number(user_input)
if strcmp(num2str(int8(str2double(user_input))),user_input)
	arg = int8(str2double(user_input));
	if arg <= 0
		arg = 0;
	end
else
	arg = 0;
end