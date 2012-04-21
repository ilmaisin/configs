-- Standard awesome library
require("awful")
require("awful.autofocus")
require("awful.rules")
-- Theme handling library
require("beautiful")
-- Notification library
require("naughty")
require("vicious")

require("mpd-popup")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- {{{ Variable definitions
-- Home directory
home = os.getenv("HOME")
-- Themes define colours, icons, and wallpapers
theme_path = home .. "/.config/awesome/themes/blueyes"
-- Actually load theme
beautiful.init(theme_path)
-- Define if we want to see naughty notifications
use_naughty = true
naughty.config.presets.normal.border_color = beautiful.menu_border_color
naughty.config.border_width = 2
-- Define if we want to modify client.opacity
use_composite = false
-- the parentheses color
par_color = beautiful.fg_focus


-- This is used later as the default terminal and editor to run.
terminal = "urxvtc"
editor = os.getenv("EDITOR") or "gvim"
editor_cmd = terminal .. " -e " .. editor


-- Some variables
browser_nav = "firefox -P navigation"
browser_mad = "firefox -P maidens -no-remote"
music = terminal .. " -e ncmpcpp"
musicPlay = "ncmpcpp toggle"
musicStop = "ncmpcpp stop"
musicPrev = "ncmpcpp prev"
musicNext = "ncmpcpp next"
soundRaiseVolume = "amixer set Master 5%+ unmute"
soundLowerVolume = "amixer set Master 5%- unmute"
soundPerfectVolume = "amixer set Master 5% unmute"
soundMute = "amixer set Master mute"
filemanager = terminal .. " -e ranger"
mutt = terminal .. " -e mutt -y"
maildir = home .. "/Maildir"
lockScreen = "slock"

-- menu bindings
awful.menu.menu_keys.up = {"k"}
awful.menu.menu_keys.down = {"j"}
awful.menu.menu_keys.exec = {"i"}

-- Alt is Mod1
alt = "Mod1"

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
layouts =
{
    awful.layout.suit.tile,             -- [1]
    awful.layout.suit.tile.left,        -- [2]
    awful.layout.suit.tile.bottom,      -- [3]
    awful.layout.suit.tile.top,         -- [4]
    awful.layout.suit.fair,             -- [5]
    awful.layout.suit.fair.horizontal,  -- [6]
    awful.layout.suit.max,              -- [7]
    awful.layout.suit.max.fullscreen,   -- [8]
    awful.layout.suit.magnifier,        -- [9]
    awful.layout.suit.floating,         -- [10]
    awful.layout.suit.spiral,           -- [11]
    awful.layout.suit.spiral.dwindle    -- [12]
}

-- Define if we want to use titlebar on all applications.
use_titlebar = false
-- }}}

-- {{{ Functions

-- Mouse remove function
-- basically move the pointer to the bottom right of the screen with
-- Mod4+Ctrl+m, useful to remove it when it stands in the middle of the
-- screen but without using the touchpad
local safeCoords = {x=1680, y=1050}
function moveMouse(x_co, y_co)
    mouse.coords({ x=x_co, y=y_co })
end


-- Markup functions
function setBg(bgcolor, text)
    return '<bg color="'..bgcolor..'" />'..text
end

function setFg(fgcolor, text)
    return '<span color="'..fgcolor..'">'..text..'</span>'
end

function setBgFg(bgcolor, fgcolor, text)
    return '<bg color="'..bgcolor..'" /><span color="'..fgcolor'">'..text..'</span>'
end

function setFont(font, text)
    return '<span font_desc="'..font..'">'..text..'</span>'
end

-- Show clipboard contents
function show_clipboard()
    local paste = selection()
    paste = naughty.notify({
        text = paste,
        timeout = 3,
        hover_timeout = 3,
        width = 300,
    })
end

-- Xprop function
function xprop(c)
    f = function (prop, str)
        return
        prop and
        ( str
        .. ((type(prop)=="boolean") and "" or (" = " .. prop))
        .. "\n"
        )
        or ""
    end

    naughty.notify({
        title = "Client info",
        text = ""
        .. f(c.class, "class")
        .. f(c.instance, "instance")
        .. f(c.name, "name")
        .. f(c.type, "type")
        .. f(c.role, "role")
        .. f(c.pid, "pid")
        .. f(c.window, "window_id")
        .. f(c.machine, "machine")
        .. f(c.floating, "Is floating")
        .. f(c.minimized, "Is minimized")
        .. f(c.fullscreen, "Is fullscreen")
        .. f(c.maximized_horizontal, "Is maximized horizontal")
        .. f(c.maximized_vertical, "Is maximized vertical")
        .. f(c.urgent, "Is urgent")
        .. f(c.focused, "Has focus")
        .. f(c.sticky, "Is sticky")
        .. f(c.ontop, "Is ontop")
        .. f(c.above, "Is set above")
        .. f(c.below, "Is set below")
    })
end


-- Cover art showing function
local coverart_on
local base_id = 0
local m_connection
function coverart_show()
    local id
    local info
    local cover_path
    -- hide a previously showing notify
    coverart_hide()
    -- get song id, info and path to the cover from mpd-popup.lua
    -- if we have already established a connection with the mpd server
    -- before, reuse that
    if m_connection ~= nil then
        m_connection, id, info, cover_path = mpd_main(base_id, m_connection)
    else
        m_connection, id, info, cover_path = mpd_main(base_id)
    end
    -- if the got id is different from the last one, show the naughty
    -- notify
    if id == nil then
        return
    end
    if base_id ~= id then
        local img = image(cover_path)
        local ico = img
        local txt = info
        coverart_on = naughty.notify({
            icon = ico,
            icon_size = 80,
            text = txt,
            timeout = 3,
            position = "bottom_right"
        })
    -- new id becomes the old one
    base_id = id
    end
end


function coverart_hide()
    if coverart_on ~= nil then
        naughty.destroy(coverart_on)
    end
end

-- Temp functions

function getCpuTemp ()
    --local f = io.popen('cut -b 1-2 /sys/module/w83627ehf/drivers/platform\:w83627ehf/w83627ehf.656/temp1_input')
    local f = io.popen('cut -b 1-2 /sys/class/hwmon/hwmon0/device/temp3_input')
	local n = f:read()
	f:close()
    return  setFg(beautiful.fg_normal, ' '..n..'°C')
end

function getMoboTemp ()
  --local f = io.popen('cut -b 1-2 /sys/module/w83627ehf/drivers/platform\:w83627ehf/w83627ehf.656/temp2_input')
  local f = io.popen('cut -b 1-2 /sys/class/hwmon/hwmon0/device/temp1_input')
  local n = f:read()
  f:close()
  return setFg(beautiful.fg_normal, ' '..n..'°C ')
end

function getGpuTemp ()
    --local f = io.popen(home .. "/.conky/nvidiatemp")
	local f = io.popen('nvidia-settings -q gpucoretemp -t')
	local n = f:read()
	f:close()
    if (n == nil) then
        return ''
    end
    if tonumber(n) >= 70 then
        n = setFg("#aadc43", n .. '°C')
        return n
    else
	    return setFg(beautiful.fg_normal, n..'°C ')
    end
end

-- Calendar functions

local calendar = nil
local offset = 0

function removeCalendar()
    if calendar ~= nil then
        naughty.destroy(calendar)
        calendar = nil
        offset = 0
    end
end

function addCalendar(inc_offset)
    local save_offset = offset
    removeCalendar()
    offset = save_offset + inc_offset
    local datespec = os.date("*t")
    datespec = datespec.year * 12 + datespec.month - 1 + offset
    datespec = (datespec % 12 + 1) .. " " .. math.floor(datespec / 12)
    local cal = awful.util.pread("cal -m " .. datespec)
    cal = string.gsub(cal, "^%s*(.-)%s*$", "%1")
    calendar = naughty.notify({
        text = string.format('<span font_desc="%s">%s</span>', "monospace", os.date("%a, %d %B %Y") .. "\n" .. cal),
        timeout = 0,
        hover_timeout = 0.5,
        width = 150,
        position = "bottom_right",
    })
end


function psByCpu(n)
    if n == 1 then
        naughty.destroy(cpuPopup)
        cpuPopup = nil
    else
        local r = io.popen("ps -eo pid,user,comm,%cpu --sort=-%cpu | sed -n '1,15p'"):read("*a")
        cpuPopup = naughty.notify({
            title = "Cpu Usage",
            text = r,
            timeout = 0,
            hover_timeout = 3,
            width = 250
        })
    end
end

function psByMemory(n)
    if n == 1 then
        naughty.destroy(memoryPopup)
        memoryPopup = nil
    else
        -- memory sorting doesn't work
        local r = io.popen("ps -eo pid,pmem,user,comm,rss --sort -rss | sed -n '1,15p'"):read("*a")
        memoryPopup = naughty.notify({
            title = "Memory Usage",
            text = r,
            timeout = 0,
            hover_timeout = 3
        })
    end
end

function dailyActivities()
    local r = [[ ]] -- a stringified list of time and corresponding activity throughout the day
    roadmapPopup = naughty.notify({
        title = "Daily Activities",
        text = r,
        timeout = 3,
        hover_timeout = 3,
    })
end

function taskShow()
    local t = io.popen("task veryminimal"):read("*a")
    taskPopup = naughty.notify({
        title = "Tasks",
        text = t,
        timeout = 3,
        hover_timeout = 3,
        position = "bottom_right"
    })
end

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {}
tags.setup = {
    { name = "♒", layout = layouts[1] },
    { name = "♂", layout = layouts[1] },
    { name = "♀", layout = layouts[7] },
    { name = "⚒", layout = layouts[1] },
    { name = "☥", layout = layouts[1] },
    { name = "♔", layout = layouts[1] },
    { name = "☢", layout = layouts[1] },
}
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    tags[s] = {}
    -- Create enough tags per screen as lenght of tags.setup table
    for i,t in ipairs(tags.setup) do
        tags[s][i] = tag({ name = t.name })
        tags[s][i].screen = s
        awful.tag.setproperty(tags[s][i], "layout", t.layout)
        awful.tag.setproperty(tags[s][i], "mwfact", t.mwfact)
        awful.tag.setproperty(tags[s][i], "hide", t.hide)
    end
    tags[s][1].selected = true
end
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
myawesomemenu = {
   { "manual", terminal .. " -e man awesome" },
   { "lock screen", lockScreen },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", awesome.quit },
   { "reboot", "sudo reboot"}
}

-- Need more OSes? Greedy bitch...
vboxmenu = {
    { "WinXp", "VBoxManage startvm WinXp", image(beautiful.windows_image) },
    { "Ubuntu", "VBoxManage startvm Ubuntu", image(beautiful.ubuntu_image) }
}

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, image(beautiful.awesomewm_image) },
                                        { "open terminal", terminal, image(beautiful.terminal_image) },
                                        { "firefox (navigation)", browser_nav, image(beautiful.firefox_image) },
                                        { "firefox (maidens)", browser_mad, image(beautiful.firefox_image) },
                                        { "ranger", filemanager, image(beautiful.filemanager_image) },
                                        { "Music", music, image(beautiful.music_image) },
                                        { "Libreoffice", "soffice", image(beautiful.office_image) },
                                        { "Skype", "skype", image(beautiful.skype_image) },
                                        { "Avidemux", "avidemux2_gtk", image(beautiful.avidemux_image) },
                                        { "Gimp", "gimp", image(beautiful.gimp_image) },
                                        { "Other OS", vboxmenu, image(beautiful.vbox_image) }
                                      }
                            })


-- Top Statusbar widgets

-- Launchbox
mylauncher = awful.widget.launcher({ image = image(beautiful.archlinux_image),
                                     menu = mymainmenu })

-- Cpu widget
cpuicon = widget({ type = "imagebox"})
cpuicon.image = image(beautiful.amdcpu_image)
cpuwidget = widget({ type = "textbox" })
cpuwidget:add_signal("mouse::enter", function () psByCpu(0) end)
cpuwidget:add_signal("mouse::leave", function () psByCpu(1) end)
cputextformat = fun
vicious.register(cpuwidget, vicious.widgets.cpu,
    function (widget, args)
        if args[2] and args[3] > 50 then
            return setFg(par_color, '[') .. setFg(beautiful.fg_urgent, args[2] .. '%') .. setFg(par_color, '][') .. setFg(beautiful.fg_urgent, args[3] .. '%') .. setFg(par_color, ']'), 5
        elseif args[2] > 50 then
            return setFg(par_color, '[') .. setFg(beautiful.fg_urgent, args[2] .. '%') .. setFg(par_color, '][') .. args[3] .. '%' .. setFg(par_color, ']'), 5
        elseif args[3] > 50 then
            return setFg(par_color, '[') .. args[2] .. '%' .. setFg(par_color, '][') .. setFg(beautiful.fg_urgent, args[3] .. '%') .. setFg(par_color, ']'), 5
        else
            return setFg(par_color, '[') .. args[2] .. '%' .. setFg(par_color, '][') .. args[3] .. '%' .. setFg(par_color, ']'), 5
        end
    end
)


-- Motherboard icon
moboicon = widget({ type = "imagebox" })
moboicon.image = image(beautiful.mobo_image)

-- Gpu icon
gpuicon = widget({ type = "imagebox" })
gpuicon.image = image(beautiful.nvidia_image)

-- Memory widget
memicon = widget({ type = "imagebox"})
memicon.image = image(beautiful.ram_image)
memwidget = widget({ type = "textbox"})
memwidget:add_signal("mouse::enter", function () psByMemory(0) end)
memwidget:add_signal("mouse::leave", function () psByMemory(1) end)
vicious.register(memwidget, vicious.widgets.mem,
    function (widget, args)
        if args[1] > 70 then
            return setFg(beautiful.fg_urgent, ' ' .. args[1] .. '%') .. setFg(par_color, '|') .. setFg(beautiful.fg_urgent, args[2] .. 'MB'), 10
        else
            return ' ' .. args[1] .. '%' .. setFg(par_color, '|') .. args[2] .. 'MB', 10
        end
    end
)


-- Network widget
netupwidget = widget({type = "textbox"})
-- the last 3 options are interval-in-seconds, properties-name, padding
vicious.cache(vicious.widgets.net)
vicious.register(netupwidget, vicious.widgets.net,
    function (widget, args)
        if tonumber(args["{eth0 up_kb}"]) > 80 then
            return setFg(beautiful.fg_urgent, args["{eth0 up_kb}"]) .. setFg(par_color, ' [') .. args["{eth0 tx_mb}"] .. 'M' .. setFg(par_color, ']'), nil, nil, 3
        else
            return args["{eth0 up_kb}"] .. setFg(par_color, ' [') .. args["{eth0 tx_mb}"] .. 'M' .. setFg(par_color, ']'), nil, nil, 3
        end
    end
)
netdownwidget = widget({ type = "textbox"})
vicious.register(netdownwidget, vicious.widgets.net,
    function (widget, args)
        if tonumber(args["{eth0 down_kb}"]) > 200 then
            return setFg(beautiful.fg_urgent, args["{eth0 down_kb}"]) .. setFg(par_color, ' [') .. args["{eth0 rx_mb}"] .. 'M' .. setFg(par_color, ']'), nil, nil, 3
        else
            return args["{eth0 down_kb}"] .. setFg(par_color, ' [') .. args["{eth0 rx_mb}"] .. 'M' .. setFg(par_color, ']'), nil, nil, 3
        end
    end
)
netupicon = widget({ type = "imagebox"})
netupicon.image = image(beautiful.up_arrow_image)
netdownicon = widget({ type = "imagebox" })
netdownicon.image = image(beautiful.down_arrow_image)

-- Maildir widget
maildiricon = widget({ type = "imagebox" })
maildiricon.image = image(beautiful.mail_image)
maildirwidget = widget({ type = "textbox" })
vicious.register(maildirwidget, vicious.widgets.mdir, ' $1 ', 300, { maildir })


-- Temperatures
--
cputemp = widget({ type = 'textbox'})
vicious.register(cputemp, getCpuTemp, "$1", 30)
--vicious.register(cputemp, vicious.widgets.thermal, "$1°C", 30, "thermal_zone0")

--mobotemp = widget({ type = 'textbox'})
--vicious.register(mobotemp, vicious.widgets.thermal, "$1°C", 50, "thermal_zone1")
--vicious.register(mobotemp, getMoboTemp, "$1", 50)

--gputemp = widget({ type = 'textbox'})
--vicious.register(gputemp, getGpuTemp, "$1", 30)
 
-- Bottom Statusbar widgets

-- Task widget
taskicon = widget({ type = "imagebox" })
taskicon.image = image(beautiful.taskwarrior_image)
taskicon:buttons(awful.util.table.join(
    awful.button({ }, 1, function() taskShow() end)
    )
)

-- Mpd widget
mpdwidget = widget({ type = 'textbox' })
vicious.register(mpdwidget, vicious.widgets.mpd,
    function (widget, args)
    if args["{state}"] == "Stop" then
        return ""
    elseif args["{state}"] == "Play" then
        return ' ' .. setFg(par_color, '[') .. args["{Artist}"] .. ' - ' .. args["{Album}"] .. ' - ' .. args["{Title}"] .. setFg(par_color, '] ')
    elseif args["{state}"] == "Pause" then
        return ' ' .. setFg(par_color, '[') .. args["{Artist}"] .. ' - ' .. args["{Album}"] .. ' - ' .. args["{Title}"] .. setFg(par_color, ']') .. '{PAUSED} '
    end
end, 2 )
mpdwidget:buttons(
    awful.util.table.join(
        awful.button({}, 1, function () awful.util.spawn(musicPlay, false) end),
        awful.button({}, 3, function () awful.util.spawn(music) end),
        awful.button({}, 4, function () awful.util.spawn(musicNext, false) end),
        awful.button({}, 5, function () awful.util.spawn(musicPrev, false) end)
    )
)

-- Volume widget
volumewidget = widget({ type = "textbox"})
-- enable caching
vicious.cache(vicious.widgets.volume)
vicious.register(volumewidget, vicious.widgets.volume, "♫ $1% ", 1, "Master")
volumewidget:buttons(awful.util.table.join(
    awful.button({ }, 1, function() awful.util.spawn(soundPerfectVolume) end),
    awful.button({ }, 4, function() awful.util.spawn(soundRaiseVolume) end),
    awful.button({ }, 5, function() awful.util.spawn(soundLowerVolume) end),
    awful.button({ }, 3, function() awful.util.spawn(soundMute) end)
))

-- Date widget
datebox = widget({ type = "textbox"})
datebox:add_signal("mouse::enter", function () addCalendar(0) end)
datebox:add_signal("mouse::leave", function () removeCalendar() end)
datebox:buttons(awful.util.table.join(
    awful.button({ }, 4, function () addCalendar(-1) end),
    awful.button({ }, 5, function () addCalendar(1) end)
))
vicious.register(datebox, vicious.widgets.date, " %T %F ")


-- {{{ Wibox
-- Set the default text in textbox
mypromptbox = widget({ type = "textbox" })

-- Create a systray
mysystray = widget({ type = "systray" })

-- Create a wibox for each screen and add it
topwibox = {}
--topwibox.ontop = false
bottomwibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, awful.tag.viewnext),
                    awful.button({ }, 5, awful.tag.viewprev)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                            if c == client.focus then
                                                c.minimized = true
                                            else
                                                if not c:isvisible() then
                                                    awful.tag.viewonly(c:tags()[1])
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({ width=250 })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

for s = 1, screen.count() do
    -- Set a screen margin for borders
    awful.screen.padding(screen[s], { top = 0 })
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt({ layout = awful.widget.layout.horizontal.leftright })
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
			awful.button({ }, 1, function () awful.layout.inc(layouts, 1)
				naughty.notify({ text = awful.layout.getname(awful.layout.get(1))}) end),
			awful.button({ }, 3, function () awful.layout.inc(layouts, -1)
				naughty.notify({ text = awful.layout.getname(awful.layout.get(1))}) end),
			awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
			awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.label.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(function(c)
                                              return awful.widget.tasklist.label.currenttags(c, s)
                                          end, mytasklist.buttons)

    -- Create the top wibox
    topwibox[s] = awful.wibox({ 
        position = "top", 
        type = '_NET_WM_WINDOW_TYPE_DOCK',
        screen = s,
        fg = beautiful.fg_normal, 
        bg = beautiful.bg_normal, 
        height = 18 })
    -- Add widgets to the wibox - order matters
    topwibox[s].widgets = {
		{
            mytaglist[s],
            mylauncher,
            mypromptbox[s],
			layout = awful.widget.layout.horizontal.leftright
		},
            s == screen.count() and mysystray or nil,
            maildirwidget,
            maildiricon,
            netdownwidget,
            netdownicon,
            netupwidget,
            netupicon,
            memwidget,
            memicon,
            cpuwidget,
            cputemp,
            cpuicon,
            mytasklist[s],
            layout = awful.widget.layout.horizontal.rightleft
    }

    -- Create the bottom wibox
    bottomwibox[s] = awful.wibox({
        position = "bottom",
        type = '_NET_WM_WINDOW_TYPE_DOCK',
        screen = s,
        fg = beautiful.fg_normal,
        bg = beautiful.bg_normal,
        height = 15 })
    -- adding widgets to the wibox
    bottomwibox[s].widgets = {
        { 
            mylayoutbox[s],
            layout = awful.widget.layout.horizontal.leftright
        },
        datebox,
        volumewidget,
        mpdwidget,
        layout = awful.widget.layout.horizontal.rightleft
    }
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,             }, "Left",      awful.tag.viewprev       ),
    awful.key({ modkey,             }, "Right",     awful.tag.viewnext       ),
    awful.key({ modkey,             }, "Escape",    awful.tag.history.restore),

    awful.key({ modkey,             }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,             }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,             }, "w", function () mymainmenu:show({keygrabber=true}) end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"     }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"     }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control"   }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control"   }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,             }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,             }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ modkey,             }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control"   }, "r", awesome.restart),
    awful.key({ modkey, "Shift"     }, "q", awesome.quit),


    awful.key({ modkey,             }, "l", function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,             }, "h", function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"     }, "h", function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"     }, "l", function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control"   }, "h", function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control"   }, "l", function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,             }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"     }, "space", function () awful.layout.inc(layouts, -1) end),

    awful.key({ modkey, "Control"   }, "n", awful.client.restore),

    -- DailyActivties popup
    awful.key({ modkey,             }, "a", function () dailyActivities()             end),
    awful.key({ modkey, alt         }, "m", function () awful.util.spawn(music) end),
    awful.key({ modkey, alt         }, "f", function () awful.util.spawn(browser_nav) end),
    awful.key({ modkey, "Control"   }, "f", function () awful.util.spawn(browser_mad) end),
    awful.key({ modkey, alt         }, "r", function () awful.util.spawn(filemanager) end),
    awful.key({ modkey              }, "p", function () show_clipboard() end),
    awful.key({ none                }, "XF86AudioPlay", function () awful.util.spawn(musicPlay) end),
    awful.key({ none                }, "XF86AudioStop", function () awful.util.spawn(musicStop) end),
    awful.key({ none                }, "XF86AudioPrev", function () awful.util.spawn(musicPrev) end),
    awful.key({ none                }, "XF86AudioNext", function () awful.util.spawn(musicNext) end),
    awful.key({ none                }, "XF86AudioLowerVolume", function () awful.util.spawn(soundLowerVolume) end),
    awful.key({ none                }, "XF86AudioRaiseVolume", function () awful.util.spawn(soundRaiseVolume) end),
    awful.key({ none                }, "XF86AudioMute", function () awful.util.spawn(soundMute) end),
    awful.key({ none                }, "XF86Sleep", function () awful.util.spawn(lockScreen) end),
    awful.key({ none                }, "XF86Mail", function () awful.util.spawn(mutt) end),
    awful.key({ modkey, "Control"   }, "m", function() moveMouse(safeCoords.x, safeCoords.y) end),
    -- Win+z: stop any widget but battery and wifi, Win+Shift+z:
    -- reactivate all widgets
    awful.key({ modkey,             }, "z", function() io.popen(home .. "/Script/awesome_widgets.sh stop") end),
    awful.key({ modkey, "Shift"     }, "z", function() io.popen(home .. "/Script/awesome_widgets.sh start") end),

    -- Mod4+s set the window sticky; pressing it again leave the window
    -- only on the current tag
    awful.key({ modkey              }, "s", function ()
        for s = 1, screen.count( ) do
            tagtable = screen[s]:tags()
            for k,t in pairs(tagtable) do
                if t ~= awful.tag.selected() then
                    awful.client.toggletag ( t, c )
                end
            end
        end
    end),

    -- Prompt
    awful.key({ modkey              }, "r", function () mypromptbox[mouse.screen]:run() end),

    awful.key({ modkey              }, "x",
            function ()
                awful.prompt.run({ prompt = "Run Lua code: " },
                mypromptbox[mouse.screen].widget,
                awful.util.eval, nil,
                awful.util.getdir("cache") .. "/history_eval")
            end)
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,             }, "f", function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"     }, "c", function (c) c:kill()                         end),
    awful.key({ modkey, "Control"   }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control"   }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,             }, "o", awful.client.movetoscreen                        ),
    awful.key({ modkey, "Shift"     }, "r", function (c) c:redraw()                       end),
    awful.key({ modkey,             }, "t", function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey, "Shift"     }, "x", function (c) xprop(c) end),
    awful.key({ modkey,             }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
   keynumber = math.min(9, math.max(#tags[s], keynumber));
end

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, keynumber do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        if tags[screen][i] then
                            awful.tag.viewonly(tags[screen][i])
                        end
                  end),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      if tags[screen][i] then
                          awful.tag.viewtoggle(tags[screen][i])
                      end
                  end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.movetotag(tags[client.focus.screen][i])
                      end
                  end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.toggletag(tags[client.focus.screen][i])
                      end
                  end),
        awful.key({ modkey, "Shift" }, "F" .. i,
                  function ()
                      local screen = mouse.screen
                      if tags[screen][i] then
                          for k, c in pairs(awful.client.getmarked()) do
                              awful.client.movetotag(tags[screen][i], c)
                          end
                      end
                   end),
        -- unminimize windows
        awful.key({ modkey, "Shift"   }, "n",
            function ()
                local allclients = client.get(mouse.screen)
                for _,c in pairs(allclients) do
                    if c.minimized and c:tags()[mouse.screen] == awful.tag.selected(mouse.screen)
                        then
                            c.minimized = false
                            client.focus = c
                            c:raise()
                            return
                    end
                end
            end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = true,
                     keys = clientkeys,
                     buttons = clientbuttons } },
    { rule = { class = "MPlayer" },
      properties = { floating = true } },
    { rule = { class = "Gimp" },
      properties = { floating = true , tag = tags[1][5], switchtotag = true} },
    { rule = { role = "gimp-toolbox" },
      properties = { slave = true } },
    { rule = { role = "gimp-dock" },
      properties = { slave = true } },
    { rule = { class = "feh" },
      properties = { floating = true } },
    { rule = { class = "gcolor2" }, 
      properties = { floating = true } },
    { rule = { class = "Gmusicbrowser" },
      properties = { floating = true } },
    -- trying to start Firefox's download window minimized, not working
    { rule = { class = "Firefox", instance = "Download" },
      properties = { floating = true, minimized = true } },
    { rule = { name = "Firefox Preferences" },
      properties = { floating = true } },
    { rule = { class = "Firefox", instance = "Abp" }, -- AdblockPlus
      properties = { floating = true } },
    { rule = { class = "<unknown>" }, -- for fullscreen flash videos
      properties = { floating = true } },
    { rule = { class = "Plugin-container" }, -- for fullscreen flash videos
      properties = { floating = true } }, 
    { rule = { class = "Wine" },
      properties = { floating = true } },
    { rule = { class = "Skype" },
      properties = { floating = true } },
    { rule = { class = "Hp-toolbox" },
      properties = { floating = true } },
    { rule = { class = "Slimrat-gui" },
      properties = { floating = true } },
    { rule = { class = "evince" },
      properties = { floating = true } },
    { rule = { class = "Pidgin" },
      properties = { tag = tags[1][6] },
      callback = awful.client.setslave },
    { rule = { instance = "Chats" },
      properties = { tag = tags[1][6] } },
    { rule = { role = "conversation" },
      properties = { tag = tags[1][6] } },
    { rule = { class = "Choqok" },
      properties = { floating = true } },
    { rule = { name = "JDownloader" },
      properties = { tag = tags[1][7] } },
  }


-- {{{ Autorun apps
autorun = true
autorunApps =
{
--    "xscreensaver -no-splash",
    "xbindkeys",
--    "xcompmgr -c -C -r10 -o.70 -D5 &",
--    "cairo-compmgr &",
    "compton -cC -fF -I 0.065 -O 0.065 -D 10 -b",
    "xset m 0.7 2",
    "xset dpms 0 900 2750",
    "urxvtd -q -o -f",
}

--if autorun then
--    for app = 1, #autorunApps do
--        local p = os.execute("pgrep " .. autorunApps[app])
--        print(p)
--        if p ~= 0 then
--            awful.util.spawn(autorunApps[app]) 
--        else
--            return nil
--        end
--    end
--end

if autorun then
    for app = 1, #autorunApps do
        awful.util.spawn(autorunApps[app])
    end
end

-- }}}
		
-- {{{ Signals
-- Signal function to execute when a new client appears.
client.add_signal("manage", function (c, startup)
    -- add a titlebar to each floating client
--    if awful.client.floating.get(c)
--    or awful.layout.get(c.screen) == awful.layout.suit.floating then
--    --    if not c.titlebar and c.class ~= "Xmessage" then
--    --        awful.titlebar.add(c, { modkey = modkey })
--    --    end
--        -- floating clients are always on top
--        c.above = true
--    end

    -- Enable sloppy focus
    c:add_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end
    -- honor size hints
    c.size_hints_honor = false

    -- I want Mplayer sticky in all tags
    --if c.name:find("MPlayer") then
    --    for s = 1, screen.count() do
    --        tagtable = screen[s]:tags()
    --        for k,t in pairs(tagtable) do
    --            if t ~= awful.tag.selected() then
    --                awful.client.toggletag(t, c)
    --            end
    --        end
    --    end
    --end
end)

client.add_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.add_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
client.add_signal("marked", function (c) c.border_color = beautiful.border_marked end)

client.add_signal("manage", function (c, startup)
	-- if we are not managing this application at startup,
	-- move it to the screen where the mouse is.
	-- we only do it for filtered windows (i.e. no dock, etc).
	if not startup and awful.client.focus.filter(c) then
		c.screen = mouse.screen
	end
end)


-- call coverart_show every 2 seconds
mpdtimer = timer({ timeout = 2 })
mpdtimer:add_signal("timeout", function () coverart_show() end)
mpdtimer:start()

-- }}}

-- vim: set filetype=lua tabstop=4 shiftwidth=4: