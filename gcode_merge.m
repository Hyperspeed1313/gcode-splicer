clear all;

layer_start_string = '\n;LAYER:\d';
layer_end_string = '\n;TIME_ELAPSED';
command_chars = 'GFXYZE';

[f_name,f_path] = uigetfile('*.gcode','Select files for merge','Multiselect','on');
n_files = length(f_name);
if n_files == 1
	return
end

[f_name_out,f_path_out] = uiputfile('*.gcode','Save merged code as');
if f_name_out == 0
	return
end

bar = waitbar(0);
set(findall(bar,'type','text'),'Interpreter','none');

for i = 1:n_files
	tic
	waitbar(0,bar,['Parsing ',f_name{i},' (',num2str(i),' of ',num2str(n_files),')']);

	fid = fopen(fullfile(f_path,f_name{i}));
	raw = char(fread(fid))';
	fclose(fid);
	layers = regexp(raw,layer_start_string);
	n_layers = length(layers);
	code_end = regexp(raw,layer_end_string);
	code_end = code_end(end);

	newline = find(raw == char(10));
	code_end = find(code_end == newline) + 1;
	g1_call = regexp(raw,'\nG1 [\w \.]*E\d');
%	g0_call = sort([regexp(raw,'\nG1 '),regexp(raw,'\nG0 ')]);
%	g0_call(ismember(g1_call,g0_call)) = []; % Remove E calls

	k = 1;
	layer_start = zeros(1,n_layers);
	for j = 1:n_layers
		while layers(j) > newline(k)
			k = k + 1;
		end
		layer_start(j) = k;
	end
	layer_start = [layer_start,code_end];
	waitbar(.025,bar);

	l_e = length(g1_call);
	g1_line = zeros(1,l_e);
	k = 1;
	for j = 1:l_e
		while g1_call(j) > newline(k)
			k = k + 1;
		end
		g1_line(j) = k;
	end
	waitbar(.05,bar);
	
%	l_0 = length(g0_call);
%	g0_line = zeros(1,l_0);
%	k = 1;
%	for j = 1:l_0
%		while g0_call(j) > newline(k)
%			k = k + 1;
%		end
%		g0_line(j) = k;
%	end
%	waitbar(.075,bar);

	g1_code = cell(l_e,3);
	e_prev = 0;
	for j = 1:l_e
		holding = strsplit(raw((newline(g1_line(j))+1):(newline(g1_line(j)+1)-1)));
		holding{end} = char(10);
		for k = 2:length(holding) % 1 will always be G1
			if holding{k}(1) == 'E'
				e_hold =  str2double(holding{k}(2:end));
				if k == length(holding)
					g1_code{j,3} = strjoin(holding(k+1:end));
				else
					g1_code{j,3} = char(10);
				end
				e_prev = e_hold + e_prev;
				g1_code{j,1} = strjoin(holding(1:k-1));
				g1_code{j,2} = e_prev;
				break
			end
		end
		if rem(j,200) == 0
			waitbar(.05+.95*j/l_e,bar);
		end
	end
	
	% Backtrack from previous layer to get X Y Z and F
	layer_last = zeros(n_layers,4);
	for j = 2:n_layers
		have = [false,false,false,false]; % F X Y Z
		k = 1;
		while sum(have) < 4
			hold = strsplit(raw((newline(layer_start(j)-k)+1):newline(layer_start(j)-k+1)));
			if strcmp(hold{1},'G0') || strcmp(hold{1},'G1')
				for l = 2:(length(hold)-1) % Ignore last entry for newline
					tmp_ll = find(hold{l}(1) == 'FXYZ');
					if ~isempty(tmp_ll)
						have(tmp_ll) = true;
						layer_last(j,tmp_ll) = str2double(hold{l}(2:end));
					end
				end
			end
			k = k + 1;
		end
	end

	% Write contents from single-use variables into longer-term storage
	file(i).g1_code = g1_code; % 
	file(i).g1_line = g1_line; % Line number of each
	file(i).newline = newline;
	file(i).raw = raw;
	file(i).layer_start = layer_start;
	file(i).n_layers = n_layers;
	file(i).layer_last = layer_last;
	toc
end

waitbar(0,bar,['Writing gcode to ',f_name_out]);

tic
e_prev = 0;
buffer = char(zeros(1,length([file.raw])+40*sum([file.n_layers]))); % Will be a bit too long but that's okay
buffer_pos = 1;
layers_out = max([file.n_layers]);

for n = 1:layers_out
	for i = 1:n_files
		% Don't execute if file doesn't have this many layers.
		if file(i).n_layers >= n
			% Append previous layer's last known coordinates and flow rate
			line_tmp = ['G0 F',num2str(file(i).layer_last(n,1),'%d'),...
			' X',num2str(file(i).layer_last(n,2),'%.3f'),...
			' Y',num2str(file(i).layer_last(n,3),'%.3f'),...
			' Z',num2str(file(i).layer_last(n,4),'%.3f'),char(10)];
			buffer(buffer_pos:buffer_pos+length(line_tmp)-1) = line_tmp;
			buffer_pos = buffer_pos + length(line_tmp);
			
			for j = file(i).layer_start(n):(file(i).layer_start(n+1)-1)
				g_tmp = find(j == file(i).g1_line);
				if ~isempty(g_tmp)
					% Need to aboslutize E-steps
					e_prev = file(i).g1_code{g_tmp,2} + e_prev;
					line_tmp = strjoin({file(i).g1_code{g_tmp,1},['E',num2str(e_prev,'%.5f')],file(i).g1_code{g_tmp,3}});
				else
					line_tmp = file(i).raw((file(i).newline(j)+1):file(i).newline(j+1));
				end
				buffer(buffer_pos:buffer_pos+length(line_tmp)-1) = line_tmp;
				buffer_pos = buffer_pos + length(line_tmp);
			end
		end
	end
	waitbar(n/layers_out,bar);
end
buffer(buffer_pos:end) = [];
fid = fopen(fullfile(f_path_out,f_name_out),'w');
fwrite(fid,file(1).raw(1:file(1).newline(file(1).layer_start(1))));
fwrite(fid,buffer);
fwrite(fid,file(1).raw(file(1).newline(file(1).layer_start(end)):end));
fclose(fid);
close(bar);
toc