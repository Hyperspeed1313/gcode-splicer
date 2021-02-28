function[] = close_gcode_file(args)
global files;
global buffer;

if length(args) <= 0
	return
end
% For now, will not touch the buffer unless the file to be closed is the active.
arg1 = is_loaded_file(args{1});

if arg1
	if buffer.active == arg1
		buffer.active = 0;
		disp("Active file unset.")
	end
	files(arg1) = [];
end