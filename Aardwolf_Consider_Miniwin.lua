dofile (GetPluginInfo(GetPluginID(), 20).. "aardwolf_colors.lua")
dofile (GetPluginInfo (GetPluginID(), 20)..  "Name_Cleanup.lua")

-- Options -----------------------------------------------
local BACKGROUND_COLOUR		= ColourNameToRGB "black"
local BORDER_COLOUR		= ColourNameToRGB "dimgray"
local DEFAULT_TEXT_COLOUR	= ColourNameToRGB "white"
local TEXT_OFFSET		= "4"
local BORDER_WIDTH		= "1"
local LINE_SPACING		= "1"
local FONT_NAME			= "Dina"
local FONT_SIZE			= 8
local WIN_STACK			= "conw"  -- Windows are stacked alphabetically, so a win named "aa" will sit on top of a win named "zz".
-- Adjust this setting to get the window to sit in front or behind other windows.
local SHOW_WELCOME		= true
local TITLE			= "consider all"
local ECHO_CONSIDER		= false -- show consider in command window
local SHOW_NO_MOB		= false -- show warning when considering an empty room
local SHOW_FLAGS		= true

local colour_to_ansi = {
	["chartreuse"] = "@x154",
	["darkviolet"] = "@x052",
	["springgreen"] = "@x010",
	["darkgoldenrod"] = "@x003",
	["darkgreen"] = "@x002",
	["lightpink"] = "@x182",
	["darkmagenta"] = "@x005",
	["tomato"] = "@x167",
	["crimson"] = "@x125",
	["forestgreen"] = "@x078",
	["magenta"] = "@x013",
	["gray"] = "@x008",
	["gold"] = "@x011",
	["white"] = "@x015",
	["silver"] = "@x007",
}

require "aard_register_z_on_create"
require "mw_theme_base"
require "movewindow"
mob_color = "gray" -- Color set by the triggers - Kobus
mob_range = "0 to 0" -- Range set by the triggers - Kobus

targT = {}

function keyword_change (name, line, wildcards)

	if keyword_position == "endw" then
		SetVariable ("keyword_position", "beginning")
	else
		SetVariable ("keyword_position", "endw")
	end
	keyword_position = GetVariable ("keyword_position")

	ColourTell ("white", "blue", "Keywords will now be taken from the ".. keyword_position.. " of Mobile names. ")
	ColourNote ("", "black", " ")

end -- keyword_position

function toggle_flags ()
	if SHOW_FLAGS == true then
		SHOW_FLAGS = false
		Note("You will no longer see the flags in the mini-window output")
	else
		SHOW_FLAGS = true
		Note("You will now see the flags in the mini-window output")
	end
end -- toggle_flags

function conw (name, line, wildcards)

	--show help <conw ?>
	if wildcards[1] == "?" then
		a = {
			"conw - update window with consider all command.",
			"<num> <word> - Execute <word> with keyword from line <num> on consider window.",
			"<num> - Execute with default word.",
			"conw <word> - set default command.",
			"conw chng - swop keyword from beginning of name to end of name or vice-versa.",
			"conw auto|on|off - toggle auto update consider window on room entry and after combat.",
			"conw flags - toggle showing of flags on and off.",
			"conw ? - show this help."
		}
		for i,v in ipairs (a) do
			sSpa = string.rep (" ", 20 - v:sub(1,v:find("-") - 1):len() )
			ColourTell ("yellow", GetInfo(271), v:sub(1,v:find("-") - 1).. sSpa )
			ColourNote ("white", GetInfo(271), v:sub(v:find("-"), v:len() ))
		end
		return
	end

	if wildcards[1] == "auto" then
		if tonumber (GetVariable ("auto_conw")) == 1 then
			SetVariable ("auto_conw", 0)
			EnableTriggerGroup ("auto_consider", 0)
			ColourTell ("white", "blue", "Auto consider off.")
			ColourNote ("", "black", " ")
		else
			SetVariable ("auto_conw", 1)
			EnableTriggerGroup ("auto_consider", 1)
			ColourTell ("white", "blue", "Auto consider on.")
			ColourNote ("", "black", " ")
		end
		Show_Window()
		return
	end

	if wildcards[1] == "off" then
		SetVariable ("auto_conw", 0)
		EnableTriggerGroup ("auto_consider", 0)
		ColourTell ("white", "blue", "Auto consider off.")
		ColourNote ("", "black", " ")
		Show_Window()
		return
	end

	if wildcards[1] == "on" then
		SetVariable ("auto_conw", 1)
		EnableTriggerGroup ("auto_consider", 1)
		ColourTell ("white", "blue", "Auto consider on.")
		ColourNote ("", "black", " ")
		Show_Window()
		return
	end

	if wildcards[1] == "chng" then
		keyword_change ()
		return
	end

	if wildcards[1] == "flags" then
		toggle_flags()
		return
	end

	if wildcards[1] and wildcards[1]:match ("^%w+$") then
		SetVariable ("default_command", wildcards[1])
		default_command = GetVariable ("default_command")
		ColourTell ("white", "blue", "Default command: ".. wildcards[1])
		ColourNote ("", "black", " ")
	end


end -- send_consider

function send_consider ()

	if GetVariable ("doing_consider") == "true" then
		return
	else
		SetVariable ("doing_consider", "true")
		EnableTriggerGroup ("consider", true)
		SendNoEcho ("consider all")
		SendNoEcho ("echo nhm")
		targT = {}
	end

end -- send_consider

function execute_command (id, s)

	if not s then
		return
	end

	s = s:match ("^([%d.%w' ]+)%:%d+$")
	Execute (default_command.. " ".. s)
	ColourTell ("white", "blue", default_command.. " ".. s)
	ColourNote ("", "black", " ")

end -- execute_command

function command_line (name, line, wildcards)

	iNum = tonumber (wildcards[1])
	if iNum > #targT then
		return
	end

	if wildcards[2] == "" then
		sKey = default_command
	else
		sKey = tostring (wildcards[2])
	end

	if targT[iNum] then
		Execute (sKey.. " ".. targT[iNum].keyword)
		ColourTell ("white", "blue", sKey.. " ".. targT[iNum].keyword.. " ")
		ColourNote ("", "black", " ")
	else
		ColourTell ("white", "blue", "no target in targT ")
		ColourNote ("", "black", " ")
	end

end -- command_line

function getKeyword(mob)
	local nameCount = 1
	for i, mobInfo in pairs(targT) do
		if mobInfo.name == mob then
			nameCount = nameCount + 1
		end
	end

	mob = stripname(mob)
	if nameCount > 1 then
		mob = string.format("%s.%s", tostring(nameCount), mob)
	end

	return mob
end

function process_flags (flags)
	newflags = ''
	if string.find(flags,"%(W%)") then
		newflags = newflags.. "@x015(W)"
	elseif string.find(flags,"%(R%)") then
		newflags = newflags.. "@x001(R)"
	else
		newflags = newflags.. "   "
	end
	if string.find(flags,"%(G%)") then
		newflags = newflags.. "@x003(G)"
	else
		newflags = newflags.. "   "
	end

	return newflags
end

function adapt_consider (name, line, wildcards)
	flags = nil
	if SHOW_FLAGS then-- we want to be able to show the flags to the user - Shindo
		flags = process_flags(wildcards[1]) 
	else
		flags = ""
	end
	mob = nil
	mob = wildcards[2] -- New version because of regex triggers - Kobus

	-- Removed for loop here, no longer necessary with color, range set by triggers - Kobus
	if mob then
		t = {
			keyword = getKeyword(mob),
			name    = mob,
			mflags  = flags,
			line    = line,
			colour  = mob_color,
			range   = "(".. mob_range.. ")",
			message = line
		} -- Changed to use color, range set by triggers - Kobus
		if ECHO_CONSIDER then
			--ColourTell   --build the string in parts

			ColourNote (mob_color, "", line.. " (".. mob_range.. ")" )
			-- Changed to use color, range set by triggers - Kobus
		end
		table.insert (targT, t)
	end -- if


	if not mob and SHOW_NO_MOB then
		ColourTell ("white", "blue", "Could not find anything: ".. line)
		ColourNote ("", "black", " ")
	end -- not  found in table

end -- adapt_consider

function Draw_Title ()

	--draw the title and add drag hotspot
	top     = BORDER_WIDTH + LINE_SPACING
	bottom  = top + font_height
	left    = BORDER_WIDTH + TEXT_OFFSET
	right   = WindowInfo (win, 3)
	movewindow.add_drag_handler (win, 0, top, right, bottom, 1)
	if (tonumber(GetVariable("auto_conw"))==1) then
		consider_status = "@GON@W" 
	else 
		consider_status = "@ROFF@W" 
	end
	title_text = ColoursToStyles(string.format("@W%s (%s) - %s", TITLE, default_command, consider_status))
	Theme.WindowTextFromStyles(win, font_id, title_text, left, top, right, bottom, utf8)

	-- draw drag bar rectangle
	WindowRectOp (win, 1, 0, 0, WindowInfo (win, 3) , WindowInfo (win, 4), BORDER_COLOUR)

	banner_height = bottom + LINE_SPACING + BORDER_WIDTH

end -- MakeTitle

function Show_Window ()

	-- get width and height and draw the window
	if #targT > 0 then
		for i,v in ipairs (targT) do
			window_width = math.max ((WindowTextWidth (win, font_id, tostring(i).. ". ".. strip_colours(v.mflags).. " ".. v.name.. " ".. v.range) + TEXT_OFFSET * 2 + BORDER_WIDTH * 2), banner_width, window_width)
		end
	else
		window_width = banner_width
	end
	window_height = banner_height * 1.2 + #targT * (font_height + LINE_SPACING)

	WindowCreate (win,
	windowinfo.window_left,
	windowinfo.window_top,
	window_width,     -- width
	window_height,  -- height
	windowinfo.window_mode,
	windowinfo.window_flags,
	BACKGROUND_COLOUR)

	-- draw each line
	top     = banner_height + LINE_SPACING
	left    = TEXT_OFFSET + BORDER_WIDTH
	bottom  = top + font_height

	for i,v in ipairs (targT) do
		sLine = tostring(i).. ". ".. v.mflags.. " @W".. v.name.. " ".. colour_to_ansi[v.colour].. v.range
		right   = WindowTextWidth (win, font_id, strip_colours(sLine)) + left
		Theme.WindowTextFromStyles(win, font_id, ColoursToStyles(sLine), left, top, right, bottom, utf8) 
		sBalloon = v.line.. " ".. v.range.. "\n\n".. "Click to Execute: '".. default_command.. " "..  v.keyword.. "'"
		WindowAddHotspot (win, v.keyword.. ":".. tostring (i), left, top, right, bottom,
		"", -- MouseOver
		"", -- CancelMouseOver
		"", -- MouseDown
		"", -- CancelMouseDown
		"execute_command", -- MouseUp
		sBalloon,
		1, -- Cursor
		0) --  Flag
		top     = bottom + LINE_SPACING
		bottom  = top + font_height  --]]
	end

	--draw the title
	Draw_Title()

	WindowShow (win, true)
	SetVariable ("doing_consider", "false")
	EnableTriggerGroup ("consider", false)

end -- Show_Consider

function Show_Banner ()

	window_width = title_width + BORDER_WIDTH * 2 + TEXT_OFFSET * 2
	window_height = font_height + LINE_SPACING * 2 + descent

	WindowCreate (win,
	windowinfo.window_left,
	windowinfo.window_top,
	window_width,     -- width
	window_height,  -- height
	windowinfo.window_mode,
	windowinfo.window_flags,
	BACKGROUND_COLOUR)

	Draw_Title ()

	WindowShow (win, true)

end -- ShowBanner

function MouseUp(flags, hotspot_id, win)
	if bit.band (flags, miniwin.hotspot_got_rh_mouse) ~= 0 then
		right_click_menu()
	end
	return true
end

function right_click_menu ()
	menustring = "!Bring to Front|Send to Back"
	result = WindowMenu(win,
	WindowInfo(win, 14),
	WindowInfo(win, 15),
	menustring)
	if result ~= "" then
		numResult = tonumber(result)
		if numResult == 1 then
			-- bring to front
			CallPlugin("462b665ecb569efbf261422f","boostMe", win)
			--Note("Front")
		elseif numResult == 2 then
			-- send to back
			CallPlugin("462b665ecb569efbf261422f","dropMe", win)
			--Note("Back")
		end
	end
end

function OnPluginInstall ()

	if SHOW_WELCOME then
		Note("Consider_Window.xml installed")
		-- Suggest help command - Kobus
		Note("For a list of commands type 'conw ?'")
	end

	win = WIN_STACK.. GetPluginID ()

	local fonts = utils.getfontfamilies ()
	if fonts[FONT_NAME] then
		font_size = FONT_SIZE
		font_name = FONT_NAME
	elseif fonts.Dina then
		font_size = 8
		font_name = "Dina"    -- the actual font
	else
		font_size = 10
		font_name = "Courier"
	end -- if

	font_id = "consider_font"

	windowinfo = movewindow.install (win, 6, miniwin.create_absolute_location)

	check (WindowCreate (win,
	windowinfo.window_left,
	windowinfo.window_top,
	1, 1,
	windowinfo.window_mode,
	windowinfo.window_flags,
	BACKGROUND_COLOUR) )

	WindowFont (win, font_id, font_name, font_size, false, false, false, false, 0, 0)  -- normal
	font_height = WindowFontInfo (win, font_id, 1)  -- height
	ascent = WindowFontInfo (win, font_id, 2)
	descent = WindowFontInfo (win, font_id, 3)

	default_command = GetVariable ("default_command") or "kill"
	keyword_position = GetVariable ("keyword_position") or "endw"

	SetVariable ("doing_consider", "false")

	auto_conw = GetVariable ("auto_conw") or 1

	EnableTriggerGroup ("auto_consider", auto_conw)

	if GetVariable ("enabled") == "false" then
		ColourNote ("yellow", "", "Warning: Plugin ".. GetPluginName ().. " is currently disabled.")
		check (EnablePlugin(GetPluginID (), false))
		return
	end -- they didn't enable us last time

	OnPluginEnable ()

end -- OnPluginInstall

function OnPluginEnable ()

	title_width = WindowTextWidth (win, font_id, TITLE.. " (".. default_command.. ")".. " - OFF")
	banner_width = title_width + BORDER_WIDTH * 2 + TEXT_OFFSET * 2
	Show_Banner ()

end -- OnPluginEnable

function OnPluginDisable ()

	WindowShow (win, false)

end -- OnPluginDisable

function OnPluginSaveState ()

	SetVariable ("enabled", tostring (GetPluginInfo (GetPluginID (), 17)))
	SetVariable ("doing_consider", "false")
	movewindow.save_state (win)

end -- OnPluginSaveState


