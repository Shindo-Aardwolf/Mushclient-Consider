dofile (GetPluginInfo(GetPluginID(), 20).. "aardwolf_colors.lua")
dofile (GetPluginInfo (GetPluginID(), 20).. "Name_Cleanup.lua")

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
	["chartreuse"] = "@x118",
	["darkviolet"] = "@x128",
	["springgreen"] = "@x048",
	["darkgoldenrod"] = "@x136",
	["darkgreen"] = "@x022",
	["lightpink"] = "@x217",
	["darkmagenta"] = "@x090",
	["tomato"] = "@x203",
	["crimson"] = "@x125",
	["forestgreen"] = "@x078",
	["magenta"] = "@x201",
	["gray"] = "@x008",
	["gold"] = "@x220",
	["white"] = "@x015",
	["silver"] = "@x007",
}

require "aard_register_z_on_create"
require "mw_theme_base"
require "movewindow"
require "gmcphelper"
require "var"

--consider flags
local conw_on = tonumber(GetVariable("conw_on")) or 1
local conw_entry = tonumber(GetVariable("conw_entry")) or 1
local conw_kill = tonumber(GetVariable("conw_kill")) or 1
local conw_misc = tonumber(GetVariable("conw_misc")) or 1

local conwall_options = {}

local search_destroy_id = "e50b1d08a0cfc0ee9c442001"
local search_destroy_crowley_id = "30000000537461726c696e67"

local banner_height = 0
local currentState = -1
local keyword_position = GetVariable("keyword_position") or "endw"
local default_command

local targT = {}

--1         At login screen, no player yet
--2         Player at MOTD or other login sequence
--3         Player fully active and able to receive MUD commands
--4         Player AFK
--5         Player in note
--6         Player in Building/Edit mode
--7         Player at paged output prompt
--8         Player in combat
--9         Player sleeping
--11        Player resting or sitting
--12        Player running

function OnPluginBroadcast (msg, id, name, text)
	local gmcparg = ""
	local luastmt = ""

	if (currentState == -1) then
		currentState = 0 -- sent request
		Send_GMCP_Packet("request char")
	end

	-- Look for GMCP handler.
	if (id == '3e7dedbe37e44942dd46d264') then
		if (text == "char.status") then
			_, gmcparg = CallPlugin("3e7dedbe37e44942dd46d264","gmcpval","char")
			luastmt = "gmcpdata = " .. gmcparg
			assert (loadstring (luastmt or "")) ()
			currentState = tonumber(gmcpval("status.state"))
--			DebugNote("char.status.state : " ..currentState)

		end
	end
end

function Keyword_change (name, line, wildcards)

	if keyword_position == "endw" then
		SetVariable ("keyword_position", "beginning")
	else
		SetVariable ("keyword_position", "endw")
	end
	keyword_position = GetVariable ("keyword_position")

	ColourTell ("white", "blue", "Keywords will now be taken from the ".. keyword_position.. " of Mobile names. ")
	ColourNote ("", "black", " ")

end -- keyword_position

local function toggle_flags ()
	if SHOW_FLAGS == true then
		SHOW_FLAGS = false
		Note("You will no longer see the flags in the mini-window output")
	else
		SHOW_FLAGS = true
		Note("You will now see the flags in the mini-window output")
	end
end -- toggle_flags

function Conw (name, line, wildcards)

	--show help <conw ?>
	if wildcards[1] == "?" or wildcards[1] == "help" then
		local comlist = {
			"conw - update window with consider all command.",
			"<num> <word> - Execute <word> with keyword from line <num> on consider window.",
			"<num> - Execute with default word.",
			"conw <word> - set default command.",
			"conwall - Execute all targets matching selected options with default word.",
			"conwall options - See current conwall options",
			"  conwall options SkipEvil - toggle skip Evil mobs",
			"  conwall options SkipGood - toggle skip Good mobs",
			"  conwall options SkipSanctuary - toggle skip mobs with Sanctuary",
			"  conwall options MinLevel <number> - skip mobs with level range lower than this number",
			"    For example: conwall options MinLevel -2 - will skips mobs with level range below -2",
			"  conwall options MaxLevel <number> - skip mobs with level range higher than this number",
			"    For example: conwall options MaxLevel 21 - will skips mobs with level range above +21",
			"conw auto|on|off - toggle auto update consider window on room entry and after combat.",
			"conw misc|entry|kill - toggle consider on room entry, mob kill or miscellanous stuff",
			"conw flags - toggle showing of flags on and off.",
			"conw ?|help - show this help."
		}
		for i,v in ipairs (comlist) do
			local sSpa = string.rep (" ", 20 - v:sub(1,v:find("-") - 1):len() )
			ColourTell ("yellow", GetInfo(271), v:sub(1,v:find("-") - 1).. sSpa )
			ColourNote ("white", GetInfo(271), v:sub(v:find("-"), v:len() ))
		end
		return
	end

	if wildcards[1] == "auto" then
		if conw_on == 1 then
			conw_on = 0
			EnableTriggerGroup ("auto_consider_on_entry", 0)
			EnableTriggerGroup ("auto_consider_on_kill", 0)
			EnableTriggerGroup ("auto_consider_misc", 0)
			ColourTell ("white", "blue", "Auto consider off.")
			ColourNote ("", "black", " ")
		else
			conw_on = 1
			EnableTriggerGroup ("auto_consider_on_entry", conw_entry)
			EnableTriggerGroup ("auto_consider_on_kill", conw_kill)
			EnableTriggerGroup ("auto_consider_misc", conw_misc)
			ColourTell ("white", "blue", "Auto consider on.")
			ColourNote ("", "black", " ")
		end
		Show_Window()
		return
	end

	if wildcards[1] == "off" then
		conw_on = 0
		EnableTriggerGroup ("auto_consider_on_kill", 0)
		EnableTriggerGroup ("auto_consider_on_entry", 0)
		EnableTriggerGroup ("auto_consider_misc", 0)
		ColourTell ("white", "blue", "Auto consider off.")
		ColourNote ("", "black", " ")
		Show_Window()
		return
	end

	if wildcards[1] == "on" then
		conw_on = 1
		EnableTriggerGroup ("auto_consider_on_entry", conw_entry)
		EnableTriggerGroup ("auto_consider_on_kill", conw_kill)
		EnableTriggerGroup ("auto_consider_misc", conw_misc)
		ColourTell ("white", "blue", "Auto consider on.")
		ColourNote ("", "black", " ")
		Show_Window()
		return
	end

	if wildcards[1] == "kill" then
		if conw_kill == 1 then
			conw_kill = 0
			ColourTell ("white", "blue", "Consider on kill - OFF.")
			ColourNote ("", "black", " ")
		else
			conw_kill = 1
			ColourTell ("white", "blue", "Consider on kill - ON.")
			ColourNote ("", "black", " ")
		end
		if conw_on == 1 then
			EnableTriggerGroup("auto_consider_on_kill", conw_kill)
		end
		return
	end

	if wildcards[1] == "entry" then
		if conw_entry == 1 then
			conw_entry = 0
			ColourTell ("white", "blue", "Consider on entry - OFF.")
			ColourNote ("", "black", " ")
		else
			conw_entry = 1
			ColourTell ("white", "blue", "Consider on entry - ON.")
			ColourNote ("", "black", " ")
		end
		if conw_on == 1 then
			EnableTriggerGroup("auto_consider_on_entry", conw_entry)
		end
		return
	end

	if wildcards[1] == "misc" then
		if conw_misc == 1 then
			conw_misc = 0
			ColourTell ("white", "blue", "Consider on misc - OFF.")
			ColourNote ("", "black", " ")
		else
			conw_misc = 1
			ColourTell ("white", "blue", "Consider on misc - ON.")
			ColourNote ("", "black", " ")
		end
		if conw_on == 1 then
			EnableTriggerGroup("auto_consider_misc", conw_misc)
		end
		return
	end

	if wildcards[1] == "chng" then
		Keyword_change ()
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

end -- Send_consider

function Send_consider ()

	if GetVariable ("doing_consider") == "true" then
		return
	else
		SetVariable ("doing_consider", "true")
		EnableTriggerGroup ("consider", true)
		SendNoEcho ("consider all")
		SendNoEcho ("echo nhm")
		targT = {}
	end

end -- Send_consider

function Execute_command (id, s)

	if not s then
		return
	end

	s = s:match ("^([%d.%w' ]+)%:%d+$")
	Execute (default_command.. " ".. s)
	ColourTell ("white", "blue", default_command.. " ".. s)
	ColourNote ("", "black", " ")

end -- Execute_command

function Command_line (name, line, wildcards)
	local iNum = tonumber (wildcards[1])
	local sKey = ""

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

end -- Command_line

function Conw_all(name, line, wildcards)
	if #targT == 0 then
		ColourTell ("white", "blue", "no targets to conwall")
		ColourNote ("", "black", " ")
	end

	for i = #targT, 1, -1 do
		local minlevel, maxlevel = string.match(targT[i].range, "([+-]?%d+) to ([+-]?%d+)")
		if not minlevel or not maxlevel then
			if string.match(targT[i].range, "%-20 or below") then
				minlevel = -300
				maxlevel = -20
			elseif string.match(targT[i].range, "%+50 or above") then
				minlevel = 50
				maxlevel = 300
			else
				Note("Something went off the rails...")
				minlevel = -300
				maxlevel = 300
			end
		end
		minlevel = tonumber(minlevel)
		maxlevel = tonumber(maxlevel)

		if conwall_options.skip_evil and (targT[i].mflags:match("%(R%)") or targT[i].mflags:match("%(red aura%)")) then
			ColourTell ("white", "blue", "Skipping EVIL ".. targT[i].keyword.. " ")
			ColourNote ("", "black", " ")
		elseif conwall_options.skip_good and (targT[i].mflags:match("%(G%)") or targT[i].mflags:match("%(golden aura%)")) then
			ColourTell ("white", "blue", "Skipping GOOD ".. targT[i].keyword.. " ")
			ColourNote ("", "black", " ")
		elseif conwall_options.skip_sanctuary and (targT[i].mflags:match("%(W%)") or targT[i].mflags:match("%(white aura%)")) then
			ColourTell ("white", "blue", "Skipping SANCTUARY ".. targT[i].keyword.. " ")
			ColourNote ("", "black", " ")
		elseif minlevel < conwall_options.min_level or maxlevel > conwall_options.max_level then
			ColourTell ("white", "blue", "Skipping out of level range ".. targT[i].keyword.. " ")
			ColourNote ("", "black", " ")
		else
			ColourTell ("white", "blue", default_command.. " ".. targT[i].keyword.. " ")
			ColourNote ("", "black", " ")
			Execute (default_command.. " ".. targT[i].keyword)
		end
	end
end -- Conw_all

function Default_conwall_options()
	local default_options = {
		skip_evil = false,
		skip_good = false,
		skip_sanctuary = false,
		min_level = -2,
		max_level = 20,
	}
	return serialize.save_simple(default_options)
end

function Load_conwall_options()
	conwall_options = loadstring(string.format("return %s", var.config or Default_conwall_options()))()
	Save_conwall_options()
end

function Save_conwall_options()
	var.config = serialize.save_simple(conwall_options)
end

function ShowNote(str)
	AnsiNote(stylesToANSI(ColoursToStyles(string.format("@w%s@w", str))))
end

function Conw_all_options(name, line, wildcards)
	if wildcards[1] == "" then
		Note("Current conwall options:")
		ShowNote(string.format("  @Y%-13.13s @w(%-3.5s@w)", "SkipEvil", conwall_options.skip_evil and "@GYes" or "@RNo"))
		ShowNote(string.format("  @Y%-13.13s @w(%-3.5s@w)", "SkipGood", conwall_options.skip_good and "@GYes" or "@RNo"))
		ShowNote(string.format("  @Y%-13.13s @w(%-3.5s@w)", "SkipSanctuary", conwall_options.skip_sanctuary and "@GYes" or "@RNo"))
		ShowNote(string.format("  @Y%-13.13s @w(%-3.5s@w)", "MinLevel", tostring(conwall_options.min_level)))
		ShowNote(string.format("  @Y%-13.13s @w(%-3.5s@w)", "MaxLevel", tostring(conwall_options.max_level)))
	elseif wildcards[1] == " SkipEvil" then
		Note("Changed conwall option:")
		conwall_options.skip_evil = not conwall_options.skip_evil
		ShowNote(string.format("  @Y%-13.13s @w(%-3.5s@w)", "SkipEvil", conwall_options.skip_evil and "@GYes" or "@RNo"))
		Save_conwall_options()
	elseif wildcards[1] == " SkipGood" then
		Note("Changed conwall option:")
		conwall_options.skip_good = not conwall_options.skip_good
		ShowNote(string.format("  @Y%-13.13s @w(%-3.5s@w)", "SkipGood", conwall_options.skip_good and "@GYes" or "@RNo"))
		Save_conwall_options()
	elseif wildcards[1] == " SkipSanctuary" then
		Note("Changed conwall option:")
		conwall_options.skip_sanctuary = not conwall_options.skip_sanctuary
		ShowNote(string.format("  @Y%-13.13s @w(%-3.5s@w)", "SkipSanctuary", conwall_options.skip_sanctuary and "@GYes" or "@RNo"))
		Save_conwall_options()
	elseif string.match(wildcards[1], " MinLevel %-?%d+") then
		Note("Changed conwall option:")
		conwall_options.min_level = tonumber(string.match(wildcards[1], " MinLevel (%-?%d+)"))
		ShowNote(string.format("  @Y%-13.13s @w(%-3.5s@w)", "MinLevel", tostring(conwall_options.min_level)))
		Save_conwall_options()
	elseif string.match(wildcards[1], " MaxLevel %-?%d+") then
		Note("Changed conwall option:")
		conwall_options.max_level = tonumber(string.match(wildcards[1], " MaxLevel (%-?%d+)"))
		ShowNote(string.format("  @Y%-13.13s @w(%-3.5s@w)", "MaxLevel", tostring(conwall_options.max_level)))
		Save_conwall_options()
	else
		Note("Unknown conwall command!")
	end
end

function GetKeyword(mob)
	local nameCount = 1
	for i, mobInfo in pairs(targT) do
		if mobInfo.name == mob then
			nameCount = nameCount + 1
		end
	end

	if (GetPluginInfo(search_destroy_id, 17)) then
		local gmcproomdata = gmcp("room")
		_, mob, _ = CallPlugin( search_destroy_id, "IGuessMobNameBroadcast", mob, gmcproomdata.info.zone) 
        elseif (GetPluginInfo(search_destroy_crowley_id, 17)) then
                local gmcproomdata = gmcp("room")
                _, mob = CallPlugin(search_destroy_crowley_id, "gmkw", mob, gmcproomdata.info.zone)
	else
		mob = Stripname(mob)
	end

	if nameCount > 1 then
		mob = string.format("%s.%s", tostring(nameCount), mob)
	end

	return mob
end

function Process_flags (flags)
	local newflags = ''
	if string.find(flags,"%(W%)")  or
		string.find(flags,"%(White Aura%)") then
		newflags = newflags.. "@x015(W)"
	else
		newflags = newflags.. "   "
	end
	if string.find(flags,"%(R%)") or
		string.find(flags,"%(Red Aura%)") then
		newflags = newflags.. "@x001(R)"
	elseif string.find(flags,"%(G%)") or
		string.find(flags,"%(Golden Aura%)") then
		newflags = newflags.. "@x003(G)"
	else
		newflags = newflags.. "   "
	end

	return newflags
end

function Adapt_consider (name, line, wildcards)
	local flags = nil
	if SHOW_FLAGS then-- we want to be able to show the flags to the user - Shindo
		flags = Process_flags(wildcards[1]) 
	else
		flags = ""
	end
	local mob = nil
	mob = wildcards[2] -- New version because of regex triggers - Kobus

	-- Removed for loop here, no longer necessary with color, range set by triggers - Kobus
	if mob then
		local t = {
			keyword = GetKeyword(mob),
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

end -- Adapt_consider

function Draw_Title ()
	local consider_status = ""
	local title_text = ""
	local entrycheck = {"@RE", "@GE"}
	local killcheck = {"@RK", "@GK"}
	local misccheck = {"@RM@W", "@GM@W"}
	local skipevil = {"@GR@W", "@RR@W"}
	local skipgood = {"@GG@W", "@RG@W"}
	local skipsanc = {"@GW@W", "@RW@W"}

	--draw the title and add drag hotspot
	local top     = BORDER_WIDTH + LINE_SPACING
	local bottom  = top + Font_height
	local left    = BORDER_WIDTH + TEXT_OFFSET
	local right   = WindowInfo (Win, 3)

	movewindow.add_drag_handler (Win, 0, top, right, bottom, 1)
	if (conw_on==1) then
		consider_status = "@GON@W "..entrycheck[conw_entry+1]..killcheck[conw_kill+1]..misccheck[conw_misc+1].." "
				  ..skipevil[(conwall_options.skip_evil and 1 or 0)+1]
				  ..skipgood[(conwall_options.skip_good and 1 or 0)+1]
				  ..skipsanc[(conwall_options.skip_sanctuary and 1 or 0)+1]
				  .." "..string.format("%+d", conwall_options.min_level)..".."..string.format("%+d", conwall_options.max_level)
	else 
		consider_status = "@ROFF@W"
	end
	title_text = ColoursToStyles(string.format("@W%s (%s) - %s", TITLE, default_command, consider_status))
	Theme.WindowTextFromStyles(Win, Font_id, title_text, left, top, right, bottom, utf8)

	-- draw drag bar rectangle
	WindowRectOp (Win, 1, 0, 0, WindowInfo (Win, 3) , WindowInfo (Win, 4), BORDER_COLOUR)

	banner_height = bottom + LINE_SPACING + BORDER_WIDTH

end -- MakeTitle

function Show_Window ()

	-- get width and height and draw the window
	if #targT > 0 then
		for i,v in ipairs (targT) do
			Window_width = math.max((WindowTextWidth (Win, Font_id, tostring(i).. ". ".. Strip_colours(v.mflags).. " ".. v.name.. " ".. v.range) + TEXT_OFFSET * 2 + BORDER_WIDTH * 2), Banner_width, Window_width)
		end
	else
		Window_width = Banner_width
	end
	Window_height = banner_height * 1.2 + #targT * (Font_height + LINE_SPACING)

	WindowCreate (Win,
	Windowinfo.window_left,
	Windowinfo.window_top,
	Window_width,     -- width
	Window_height,  -- height
	Windowinfo.window_mode,
	Windowinfo.window_flags,
	BACKGROUND_COLOUR)

	-- draw each line
	local top     = banner_height + LINE_SPACING
	local left    = TEXT_OFFSET + BORDER_WIDTH
	local right   = 0
	local bottom  = top + Font_height

	for i,v in ipairs (targT) do
		local sLine = tostring(i).. ". ".. v.mflags.. " @W".. v.name.. " ".. colour_to_ansi[v.colour].. v.range
		right   = WindowTextWidth (Win, Font_id, Strip_colours(sLine)) + left
		Theme.WindowTextFromStyles(Win, Font_id, ColoursToStyles(sLine), left, top, right, bottom, utf8) 
		local sBalloon = v.line.. " ".. v.range.. "\n\n".. "Click to Execute: '".. default_command.. " ".. v.keyword.. "'"
		WindowAddHotspot (Win, v.keyword.. ":".. tostring (i), left, top, right, bottom,
		"", -- MouseOver
		"", -- CancelMouseOver
		"", -- MouseDown
		"", -- CancelMouseDown
		"Execute_command", -- MouseUp
		sBalloon,
		1, -- Cursor
		0) --  Flag
		top     = bottom + LINE_SPACING
		bottom  = top + Font_height  --]]
	end

	--draw the title
	Draw_Title()

	WindowShow (Win, true)
	SetVariable ("doing_consider", "false")
	EnableTriggerGroup ("consider", false)

end -- Show_Consider

function Show_Banner ()

	Window_width = Title_width + BORDER_WIDTH * 2 + TEXT_OFFSET * 2
	Window_height = Font_height + LINE_SPACING * 2 + Descent

	WindowCreate (Win,
	Windowinfo.window_left,
	Windowinfo.window_top,
	Window_width,     -- width
	Window_height,  -- height
	Windowinfo.window_mode,
	Windowinfo.window_flags,
	BACKGROUND_COLOUR)

	Draw_Title ()

	WindowShow (Win, true)

end -- ShowBanner

function MouseUp(flags, hotspot_id, win)
	if bit.band (flags, miniwin.hotspot_got_rh_mouse) ~= 0 then
		Right_click_menu()
	end
	return true
end

function Right_click_menu ()
	Menustring = "!Bring to Front|Send to Back"
	Result = WindowMenu(Win,
	WindowInfo(Win, 14),
	WindowInfo(Win, 15),
	Menustring)
	if Result ~= "" then
		local numResult = tonumber(Result)
		if numResult == 1 then
			-- bring to front
			CallPlugin("462b665ecb569efbf261422f","boostMe", Win)
			--Note("Front")
		elseif numResult == 2 then
			-- send to back
			CallPlugin("462b665ecb569efbf261422f","dropMe", Win)
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

	Win = WIN_STACK.. GetPluginID ()

	local fonts = utils.getfontfamilies ()
	if fonts[FONT_NAME] then
		Font_size = FONT_SIZE
		Font_name = FONT_NAME
	elseif fonts.Dina then
		Font_size = 8
		Font_name = "Dina"    -- the actual font
	else
		Font_size = 10
		Font_name = "Courier"
	end -- if

	Font_id = "consider_font"

	Windowinfo = movewindow.install (Win, 6, miniwin.create_absolute_location)

	check (WindowCreate (Win,
	Windowinfo.window_left,
	Windowinfo.window_top,
	1, 1,
	Windowinfo.window_mode,
	Windowinfo.window_flags,
	BACKGROUND_COLOUR) )

	WindowFont (Win, Font_id, Font_name, Font_size, false, false, false, false, 0, 0)  -- normal
	Font_height = WindowFontInfo (Win, Font_id, 1)  -- height
	Ascent = WindowFontInfo (Win, Font_id, 2)
	Descent = WindowFontInfo (Win, Font_id, 3)

	default_command = GetVariable ("default_command") or "kill"
	keyword_position = GetVariable ("keyword_position") or "endw"

	SetVariable ("doing_consider", "false")

	conw_on = tonumber(GetVariable("conw_on")) or 1
	conw_entry = tonumber(GetVariable("conw_entry")) or 1
	conw_kill = tonumber(GetVariable("conw_kill")) or 1
	conw_misc = tonumber(GetVariable("conw_misc")) or 1

	EnableTriggerGroup ("auto_consider", conw_on)
	if tonumber(conw_on) == 1 then
		EnableTriggerGroup ("auto_consider_on_entry", conw_entry)
		EnableTriggerGroup ("auto_consider_on_kill", conw_kill)
		EnableTriggerGroup ("auto_consider_misc", conw_misc)
	else
		EnableTriggerGroup ("auto_consider_on_entry", 0)
		EnableTriggerGroup ("auto_consider_on_kill", 0)
		EnableTriggerGroup ("auto_consider_misc", 0)
	end

	if GetVariable ("enabled") == "false" then
		ColourNote ("yellow", "", "Warning: Plugin ".. GetPluginName ().. " is currently disabled.")
		check (EnablePlugin(GetPluginID (), false))
		return
	end -- they didn't enable us last time

	Load_conwall_options()

	OnPluginEnable ()

end -- OnPluginInstall

function OnPluginEnable ()
	Title_width = WindowTextWidth (Win, Font_id, TITLE.. " (".. default_command.. ")".. " - ON EKM RGW -100..+100")
	Banner_width = Title_width + BORDER_WIDTH * 2 + TEXT_OFFSET * 2
	Show_Banner ()

end -- OnPluginEnable

function OnPluginDisable ()

	WindowShow (Win, false)

end -- OnPluginDisable

function OnPluginSaveState ()

	SetVariable ("enabled", tostring (GetPluginInfo (GetPluginID (), 17)))
	SetVariable ("doing_consider", "false")
	SetVariable("conw_misc", conw_misc)
	SetVariable("conw_kill", conw_kill)
	SetVariable("conw_entry", conw_entry)
	SetVariable("conw_on", conw_on)
	movewindow.save_state (Win)
	Save_conwall_options()

end -- OnPluginSaveState

