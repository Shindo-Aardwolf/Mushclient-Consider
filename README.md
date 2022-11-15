# Mushclient-Consider
This plugin creates and displays a numbered list of the mobs in a room.
Allows killing specific mob in the room with mouse or by just sending mob number like "1", "2" etc.
Allows killing all mobs in the room filtered by level range, alignment, sanctuary by sending "conwall" command.
Even while you're stacked window is updated with killed mobs and currently aimed mob.

![Screenshot](https://user-images.githubusercontent.com/118027636/201795092-4040d6d7-4aff-401e-9f92-d13db66ddeae.jpg)
![Screenshot](https://user-images.githubusercontent.com/118027636/201498973-cc41e779-2336-4a27-a8e3-03e8b50606ae.jpg)

Note: This plugin picks up custom mob keywords from S&D (either Crowley's or Winkle's versions)
# Commands
  - conw - update window with consider all command.  
  - \<num\> \<word\> - Execute \<word\> with keyword from line \<num\> on consider window.  
  - \<num\> - Execute with default word.  
  - conw \<word\> - set default command to word.  
  - conwall - Execute all targets matching selected options with default word.  
  - conwall options - See current conwall options.  
  -   conwall options SkipEvil - toggle skip Evil mobs.  
  -   conwall options SkipGood - toggle skip Good mobs.  
  -   conwall options SkipSanctuary - toggle skip mobs with Sanctuary.  
  -   conwall options MinLevel \<number\> - skip mobs with level range lower than this number.  
        For example: conwall options MinLevel -2 - will skips mobs with level range below -2.  
  -   conwall options MaxLevel \<number\> - skip mobs with level range higher than this number.  
        For example: conwall options MaxLevel 21 - will skips mobs with level range above +21.  
  - conw_notify_attack <target> - use this alias if you're attacking mob via other commands but
			want consider window to draw attack mark on that mob.
			For example when using S&D's kk to attack do the following "xset qk my_uber_attack_alias"
			and have the above alias expand to "conw_notify_attack %1;kill %1"
  - conw auto|on|off - toggle auto update consider window on room entry and after combat.  
  - conw flags - toggle showing of flags on and off.  
  - conw ? - show this help.  
