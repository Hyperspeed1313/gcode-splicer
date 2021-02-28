function [] = set_active_file(args)
global files;
global buffer;
n_files = length(files);

if length(args) > 0
	int_arg = is_loaded_file(args{1});
	if int_arg == 0
		return
	end
	if ~isempty(buffer.changes)
		tmp = yesno('This will clear all previous changes. Continue? $>');
		if ~tmp
			return
		end
	end
	buffer.active = int_arg;
	buffer.changes = [];
	disp(['Active: ',fullfile(files(buffer.active).path,files(buffer.active).name)])
else
	if buffer.active == 0
		disp('No active file set.');
	else
		disp(fullfile(files(buffer.active).path,files(buffer.active).name))
		disp([num2str(length(buffer.changes)),' pending changes.'])
	end
	return
end