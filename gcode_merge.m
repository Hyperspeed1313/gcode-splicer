clear all;clc

layer_marker = ';LAYER:\d'; % Appearance of this line is start of a layer
ending_code = ';TIME_ELAPSED:'; % Last instance of this line denotes end of final layer
command_chars = 'GFXYZE';

[f_name,f_path] = uigetfile('*.gcode','Select all files for merge','Multiselect','on');
n_files = length(f_name);
if n_files <= 1
	return
end

[f_name_out,f_path_out] = uiputfile('*.gcode','Save merged gcode as');

bar = waitbar(0,['Parsing ',f_name{1},' (1 of ',num2str(n_files),')']);
set(findall(bar,'type','text'),'Interpreter','none');
g1.line = struct('G',[],'F',[],'X',[],'Y',[],'Z',[],'E',[],'comment',[]);

% Layers will be merged in the order they are selected.
for i = 1:n_files
	tic
	waitbar(0,bar,['Parsing ',f_name{i},' (',num2str(i),' of ',num2str(n_files),')']);
	
	e_prev = 0; % reset for each file	
	
	fid = fopen(fullfile(f_path,f_name{i}));
	raw{i} = char(fread(fid))';
	fclose(fid);
	layers{i} = regexp(raw{i},layer_marker) - 1; % Gets newline character of comment identifying layer start
	tmp_i = regexp(raw{i},ending_code)-1;
	tmp_i = tmp_i(end);
	
	
	
	newline{i} = find(raw{i} == char(10));
	code_end = find(tmp_i == newline{i}) + 1;
	e_moves{i} = regexp(raw{i},'\nG1 '); % find all extrusion movements
	
	l_linestart{i} = zeros(1,length(layers{i}));
	k = 1;
	for j = 1:length(layers{i})
		while layers{i}(j) > newline{i}(k)
			k = k + 1;
		end
		l_linestart{i}(j) = k;
	end
%	l_linestart{i} = [find(sum(layers{i}' == newline{i},1)),code_end];
	n_layers(i) = length(l_linestart{i});
	l_linestart{i} = [l_linestart{i},code_end];
	
	
	
	% Cache G1 lines, convert E steps to relative
	e_linestart = zeros(1,length(e_moves{i}));
	k = 1;
	for j = 1:length(e_moves{i})
		while e_moves{i}(j) > newline{i}(k)
			k = k + 1;
		end
		e_linestart(j) = k;
	end
	e_linestart(e_linestart < l_linestart{i}(1)) = [];
	l_e = length(e_linestart);
	
	g1(i).line(l_e).G = [];
	
	for j = 1:l_e
		tmp_j = strsplit(raw{i}(newline{i}(e_linestart(j))+1:newline{i}(e_linestart(j)+1)-1));
		for k = 1:length(tmp_j)-1 % ignore newline item
			g1(i).line(j).start = e_linestart(j); % line number in newline
			if tmp_j{k}(1) == ';'
				g1(i).line(j).comment = strjoin(tmp_j(k:end));
				break % line done, go to next
			else
				tmp_k = find(tmp_j{k}(1) == command_chars);
				if isempty(tmp_k)
					warning(['ERROR: Bad file read in ',f_name{i},' at line ',num2str(e_linestart(j)),' element ',num2str(k)]);
				else
					tmp_k2 = str2double(tmp_j{k}(2:end));
					if tmp_k == 6 % Extrusion command- convert E to relative
						e_prev_hold = tmp_k2;
						tmp_k2 = tmp_k2 - e_prev;
						e_prev = e_prev_hold;
					end
					g1(i).line(j).(command_chars(tmp_k)) = tmp_k2;
				end
			end
		end
		if rem(j,200) == 0
			waitbar(j/(l_e),bar);
		end
	end
	toc
end

waitbar(0,bar,'Writing gcode');

for i = 1:n_files
	glines{i} = [g1(i).line.start];
end

%% File parsing complete - begin merge
% Use code prior to first layer of first file as init code
tic
fid = fopen(fullfile(f_path_out,f_name_out),'w');
e_prev = 0; % Cumulative for entire file
g_fnames = {'G','F','X','Y','Z','E','comment'};
g_precision = {'%d','%d','%.3f','%.3f','%.3f','%.5f'};

fwrite(fid,';gcode merge of multiple files');
fwrite(fid,raw{1}(1:newline{1}(l_linestart{1}(1))));

buffer = char(zeros(1,100000));
pos_buffer = 1;

for n = 1:max(n_layers)
	for i = 1:n_files
		if n_layers(i) < n % layer not present in current file
			continue
		end
		for j = l_linestart{i}(n):(l_linestart{i}(n+1)-1)
			tmp = find(j == glines{i}); % Returns index in g1
			if ~isempty(tmp)
				% Has altered E steps. Needs to be reassembled.
				% command_chars = 'GFXYZE'; (reference, do not uncomment)
				g_line = g1(i).line(tmp);
				tmp_line = '';
				for k = 1:length(g_fnames)
					if ~isempty(g_line.(g_fnames{k}))
						switch g_fnames{k}
						case 'G'
							tmp_line = ['G',num2str(g_line.G,'%d')];
						case 'F'
							tmp_line = strjoin({tmp_line,['F',num2str(g_line.F,'%d')]});
						case 'X'
							tmp_line = strjoin({tmp_line,['X',num2str(g_line.X,'%.3f')]});
						case 'Y'
							tmp_line = strjoin({tmp_line,['Y',num2str(g_line.Y,'%.3f')]});
						case 'Z'
							tmp_line = strjoin({tmp_line,['Z',num2str(g_line.Z,'%.3f')]});
						case 'E'
							e_prev = e_prev + g_line.E;
							tmp_line = strjoin({tmp_line,['E',num2str(e_prev,'%.5f')]});
						case 'comment'
							tmp_line = strjoin({tmp_line,g_line.comment});
						end
					end
				end
				buffer(pos_buffer:(pos_buffer+length(tmp_line))) = [tmp_line,char(10)];
				pos_buffer = pos_buffer + length(tmp_line) + 1;
			else
				buffer(pos_buffer:(pos_buffer+newline{i}(j+1)-(newline{i}(j)+1))) = raw{i}((newline{i}(j)+1):newline{i}(j+1));
			end
			if pos_buffer > 99000
				fwrite(fid,buffer(1:(pos_buffer-1)));
				buffer = char(zeros(1,100000));
				pos_buffer = 1;
			end
		end
	end
	waitbar(n/max(n_layers),bar);
end
fwrite(fid,buffer);

% write closing contents/end of print commands
fwrite(fid,raw{1}(( newline{1}(l_linestart{1}(end)) +1 ):end ));

fclose(fid);
close(bar);
toc