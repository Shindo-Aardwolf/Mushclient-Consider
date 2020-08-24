function stripname(nametostrip, CurrentZone)
	--dirty_string = dirty_string:gsub("", "")

	local dirty_string = nametostrip
	if CurrentZone == "The Flying Citadel" then
		dirty_string = dirty_string:gsub(" prince of .*", "")
		dirty_string = dirty_string:gsub(" princess of .*", "")
		dirty_string = dirty_string:gsub(" archangel of .*", "")
	end
	dirty_string = dirty_string:gsub("^[aA] ", "")
	dirty_string = dirty_string:gsub("^[Aa]n ", "")
	dirty_string = dirty_string:gsub("^[Tt]he ", "")
	dirty_string = dirty_string:gsub("[Ff]rom ", "")
	dirty_string = dirty_string:gsub(" on ", " ")
	dirty_string = dirty_string:gsub(" in ", " ")
	dirty_string = dirty_string:gsub(" a ", " ")
	dirty_string = dirty_string:gsub(" an ", " ")
	dirty_string = dirty_string:gsub(" with ", " ")
	dirty_string = dirty_string:gsub(" and ", " ")
	dirty_string = dirty_string:gsub(" of ", " ")
	dirty_string = dirty_string:gsub(" [Tt]he ", " ")
	dirty_string = dirty_string:gsub("'s ", " ")
	dirty_string = dirty_string:gsub(", ", " ")
	dirty_string = dirty_string:gsub("%-", " ")
	while string.match(dirty_string,[=[[?!",]]=]) do -- Pull out ? and ! - Kobus
		dirty_string = string.gsub(dirty_string,"%?","")
		dirty_string = string.gsub(dirty_string,"!","")
		dirty_string = string.gsub(dirty_string,",","")
		dirty_string = string.gsub(dirty_string,[=["]=],"")
		dirty_string = string.gsub(dirty_string,[=["]=],"")
	end -- Stripping ? ! " and , from mob names -- Kobus

	dirty_string = dirty_string:gsub("%?%?%?%!%!%!", "")
	dirty_string = dirty_string:gsub("%?%?%!%!", "")
	dirty_string = dirty_string:gsub("%. ", " ")
	local CleanTarget = dirty_string
	return CleanTarget
end
