function[] = show_file_list(args)
global files
global buffer

% Will implement later when buffer format is decided.
%if strcmp(args{1},'buffer')
%	disp(['Modified state of ',files(buffer.active).name])
%	disp(
%	return
%end

if length(args) > 0
	arg1 = is_loaded_file(args{1});
else
	arg1 = 0;
end
if arg1 > 0
	disp(fullfile(files(arg1).path,files(arg1).name))
	disp([num2str(length(files(arg1).layer_lines)),' layers'])
	disp([num2str(files(arg1).n_lines),' lines of gcode'])
else
	for i = 1:length(files)
		if buffer.active == i
			lead = "  * ";
		else
			lead = "    ";	
		end
		disp([lead,num2str(i)," ",fullfile(files(i).path,files(i).name)]);
	end
end