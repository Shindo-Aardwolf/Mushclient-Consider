# Mushclient-Consider
This plugin creates and displays a numbered list of the mobs in a room. Currently the output is to a mini-window but future versions may include only outputting to the main window when toggled to do so by the user.

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
  - conw auto|on|off - toggle auto update consider window on room entry and after combat.  
  - conw flags - toggle showing of flags on and off.  
  - conw ? - show this help.  
