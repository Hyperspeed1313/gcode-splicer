function(out) = yesno(query)

while true
	tmp = input(query);
	if strcmp(lower(tmp),'yes')
		return 1
	elseif strcmp(lower(tmp),'no') || strcmp(lower(tmp),'n');
		return 0
	end
end