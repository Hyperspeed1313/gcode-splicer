function[arg_out] = is_loaded_file(arg_in)
% Returns positive integer if valid file number
% Returns 0 if not valid file number
global files
n_files = length(files);
tmp = is_whole_number(arg_in);
if tmp > 0 && max(tmp == 1:n_files)
	arg_out = tmp;
else
	arg_out = 0;
end