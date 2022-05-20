_addon.name = 'MapTile'
_addon.author = 'Ghosty'
_addon.version = '0.2'
_addon.command = 'maptile'

config = require('config')
texts = require('texts')
res = require('resources')

local LOGIN_ZONE_PACKET = 0x0A
local STATUS_ID_CUTSCENES = 0x04
local wait_for_pos = true
local mouse_on = false

local defaults = {}
defaults.txt = {}
defaults.txt.text = {}
defaults.txt.text.font = 'Arial'
defaults.txt.text.size = 10
defaults.txt.text.red = 255
defaults.txt.text.green = 255
defaults.txt.text.blue = 255
defaults.txt.text.alpha = 255
defaults.txt.text.stroke = {}
defaults.txt.text.stroke.width = 1
defaults.txt.bg = {}
defaults.txt.bg.visible = false
defaults.txt.flags = {}
defaults.txt.flags.bold = true
defaults.txt.flags.italic = true
defaults.txt.flags.draggable = true

defaults.position = {}
defaults.position.x = 0
defaults.position.y = 0
defaults.replace_abbreviations = false
defaults.alignment = 'left'

local settings = config.load(defaults)
config.save(settings)

-- display a | when dragging to help line things up with other UI elements
local align_point = {}
align_point.text = {}
align_point.text.font = settings.txt.text.font
align_point.text.size = settings.txt.text.size
align_point.text.red = 255
align_point.text.green = 50
align_point.text.blue = 50
align_point.text.alpha = 255
align_point.text.stroke = {}
align_point.text.stroke.width = 1
align_point.bg = {}
align_point.bg.visible = false
align_point.flags = {}
align_point.flags.bold = true

local maptile = {}
maptile.initialized = false
maptile.ready = false
maptile.hide = false
maptile.txt = texts.new(settings.txt)

maptile.align_point = texts.new('|', align_point)
maptile.align_point:hide()

-- initialize addon
local function initialize()
    maptile.txt:text('${ZoneName|} ${MapTile|}')
    maptile.initialized = true
end

local function replace_zone_abbreviations(zone_name)
    if string.match(zone_name,'%[S]') then
        zone_name = string.gsub(zone_name,'%[S]','(Shadowreign)')
    elseif string.match(zone_name,'%[U]') then
        zone_name = string.gsub(zone_name,'%[U]','(Skirmish)')
    elseif string.match(zone_name,'%[D]') then
        zone_name = string.gsub(zone_name,'%[D]','(Divergence)')
    end
    return zone_name
end

local function update_maptile()
    local info = windower.ffxi.get_info()
    if not info.logged_in then
        return
    end

    local pos = windower.ffxi.get_position()
    maptile.MapTile = pos

    local zone_id = info.zone
    local zone_table = res.zones[zone_id]
    maptile.ZoneName = nil
    if (zone_table ~= nil) then
        maptile.ZoneName = zone_table.en

        if settings.replace_abbreviations then
            maptile.ZoneName = replace_zone_abbreviations(maptile.ZoneName)
        end
    end

    maptile.txt:update(maptile)

    local width, _ = maptile.txt:extents()

    if settings.alignment == 'left' then
        maptile.txt:pos_x(settings.position.x)
    elseif settings.alignment == 'center' then
        local offset_x = math.floor(width / 2)
        maptile.txt:pos_x(settings.position.x - offset_x)
    elseif settings.alignment == 'right' then
        maptile.txt:pos_x(settings.position.x - width)
    end
    maptile.txt:pos_y(settings.position.y)
end

local function update_position()
    local width, _ = maptile.txt:extents()

    if settings.alignment == 'left' then
        settings.position.x = maptile.txt:pos_x()
    elseif settings.alignment == 'center' then
        settings.position.x = maptile.txt:pos_x() + math.floor(width / 2)
    elseif settings.alignment == 'right' then
        settings.position.x = maptile.txt:pos_x() + width
    end
    settings.position.y = maptile.txt:pos_y()

    local ap_width, _ = maptile.align_point:extents()
    local ap_offset = ap_width / 2
    maptile.align_point:pos(settings.position.x - ap_offset, settings.position.y)
end

-- hide the addon
local function hide()
    maptile.txt:hide()
    maptile.ready = false
end

-- show the addon
local function show()
    if maptile.initialized == false then
        initialize()
    end

    maptile.txt:show()
    maptile.ready = true
end

-- Bind Events
-- ON LOAD
windower.register_event('load', function()
    if windower.ffxi.get_info().logged_in then
        initialize()
        show()
    end
end)

-- ON LOGIN
windower.register_event('login', function()
    show()
end)

-- ON LOGOUT
windower.register_event('logout', function()
    hide()
end)

-- ON ZONE CHANGE
windower.register_event('incoming chunk',function(id,org,_modi,_is_injected,_is_blocked)
    if (id == LOGIN_ZONE_PACKET) then
        if windower.ffxi.get_info().mog_house then
            hide()
        end
    end
end)

-- BEFORE EACH RENDER
windower.register_event('prerender', function()
    local pos = windower.ffxi.get_position()
    if pos == '(?-?)' then
        hide()
        wait_for_pos = true
    elseif wait_for_pos and not windower.ffxi.get_info().mog_house then
        show()
        wait_for_pos = false
    end

    if maptile.ready == false then
        return
    end

    update_maptile()
end)

-- ENTER/EXIT CUTSCENES
windower.register_event('status change', function(new_status_id)
    if maptile.hide == false and (new_status_id == STATUS_ID_CUTSCENES) then
        maptile.hide = true
        hide()
    elseif maptile.hide and new_status_id ~= STATUS_ID_CUTSCENES then
        maptile.hide = false
        show()
    end
end)

windower.register_event("mouse",function(type,x,y,delta,blocked)
    if not maptile.txt:hover(x, y) then return false end

	if type == 1 then
		mouse_on = true
        maptile.align_point:show()
	end
	if type == 2 then
		mouse_on = false
        maptile.align_point:hide()
		config.save(settings)
	end
	if mouse_on then
		update_position()
	end
end)

local function printFF11( text )
	windower.add_to_chat(207, windower.to_shift_jis(text))
end

windower.register_event("addon command", function(command, ...)
	local args = L{ ... }

    local h = {}
    h[#h+1] = "MapTile ".._addon.version
    h[#h+1] = " //maptile align <left/center/right> - set the text alignment"
    h[#h+1] = " //maptile expand <on/off/toggle> - expand abbreviations"
    h[#h+1] = " //maptile reset - resets position and alignment to top left corner of UI"

	if command == 'help' or command == nil then
		for _,tv in pairs(h) do
			windower.add_to_chat(207, windower.to_shift_jis(tv))
		end

	elseif command == 'align' then
        local a = {['left']=true, ['center']=true, ['right']=true}
		if not args:empty() and a[args[1]] ~= nil then
            printFF11("MapTile text alignment changed: "..settings.alignment.." -> "..args[1])
            settings.alignment = args[1]
            update_maptile()
        else
            printFF11(h[2])
        end

	elseif command == 'expand' then
        local a = {['on']=true, ['off']=true, ['toggle']=true}
		if not args:empty() then
            if a[args[1]] ~= nil then
                if args[1] == 'toggle' then
                    settings.replace_abbreviations = not settings.replace_abbreviations
                elseif args[1] == 'on' then
                    settings.replace_abbreviations = true
                else
                    settings.replace_abbreviations = false
                end
                printFF11("MapTile abbreviation expansion: " .. (settings.replace_abbreviations and "on" or "off"))
                update_maptile()
            else
                printFF11(h[3])
            end
        else
            -- no args also toggles
    		settings.replace_abbreviations = not settings.replace_abbreviations
            printFF11("MapTile abbreviation expansion: " .. (settings.replace_abbreviations and "on" or "off"))
            update_maptile()
        end

    elseif command == 'reset' then
        settings.alignment = 'left'
        settings.position.x = 0
        settings.position.y = 0
        update_maptile()

    end

	config.save(settings)
end)