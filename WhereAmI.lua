_addon.name = 'WhereAmI'
_addon.author = 'Ghosty'
_addon.version = '0.2'
_addon.commands = {'whereami', 'wai'}

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

local whereami = {}
whereami.initialized = false
whereami.ready = false
whereami.hide = false
whereami.txt = texts.new(settings.txt)

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
whereami.align_point = texts.new('|', align_point)
whereami.align_point:hide()

-- initialize addon
local function initialize()
    whereami.txt:text('${ZoneName|} ${MapTile|}')
    whereami.initialized = true
end

-- un-abbreviate zone name suffixes
local function replace_zone_abbreviations(zone_name)
    if string.match(zone_name,'%[S]') then
        zone_name = string.gsub(zone_name,'%[S]','[Shadowreign]')
    elseif string.match(zone_name,'%[U]') then
        zone_name = string.gsub(zone_name,'%[U]','[Skirmish]')
    elseif string.match(zone_name,'%[D]') then
        zone_name = string.gsub(zone_name,'%[D]','[Divergence]')
    end
    return zone_name
end

-- update the text string
local function update_location()
    local info = windower.ffxi.get_info()
    if not info.logged_in then
        return
    end

    local pos = windower.ffxi.get_position()
    whereami.MapTile = pos

    local zone_id = info.zone
    local zone_table = res.zones[zone_id]
    whereami.ZoneName = nil
    if (zone_table ~= nil) then
        whereami.ZoneName = zone_table.en

        if settings.replace_abbreviations then
            whereami.ZoneName = replace_zone_abbreviations(whereami.ZoneName)
        end
    end

    whereami.txt:update(whereami)

    -- update the text position relative to the alignment
    local width, _ = whereami.txt:extents()
    if settings.alignment == 'left' then
        whereami.txt:pos_x(settings.position.x)
    elseif settings.alignment == 'center' then
        local offset_x = math.floor(width / 2)
        whereami.txt:pos_x(settings.position.x - offset_x)
    elseif settings.alignment == 'right' then
        whereami.txt:pos_x(settings.position.x - width)
    end
    whereami.txt:pos_y(settings.position.y)
end

-- hide the addon
local function hide()
    whereami.txt:hide()
    whereami.ready = false
end

-- show the addon
local function show()
    if whereami.initialized == false then
        initialize()
    end

    whereami.txt:show()
    whereami.ready = true
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

    if whereami.ready == false then
        return
    end

    update_location()
end)

-- ENTER/EXIT CUTSCENES
windower.register_event('status change', function(new_status_id)
    if whereami.hide == false and (new_status_id == STATUS_ID_CUTSCENES) then
        whereami.hide = true
        hide()
    elseif whereami.hide and new_status_id ~= STATUS_ID_CUTSCENES then
        whereami.hide = false
        show()
    end
end)

-- update the saved position relative to the alignment
local function update_position()
    local width, _ = whereami.txt:extents()

    if settings.alignment == 'left' then
        settings.position.x = whereami.txt:pos_x()
    elseif settings.alignment == 'center' then
        settings.position.x = whereami.txt:pos_x() + math.floor(width / 2)
    elseif settings.alignment == 'right' then
        settings.position.x = whereami.txt:pos_x() + width
    end
    settings.position.y = whereami.txt:pos_y()

    local ap_width, _ = whereami.align_point:extents()
    local ap_offset = ap_width / 2
    whereami.align_point:pos(settings.position.x - ap_offset, settings.position.y)
end

-- MOUSE DRAGGING
windower.register_event("mouse",function(type,x,y,delta,blocked)
    if not whereami.txt:hover(x, y) then return false end

	if type == 1 then
		mouse_on = true
        whereami.align_point:show()
	end
	if type == 2 then
		mouse_on = false
        whereami.align_point:hide()
		config.save(settings)
	end
	if mouse_on then
		update_position()
	end
end)

-- print to chat window
local function print_wai( text )
	windower.add_to_chat(207, windower.to_shift_jis(text))
end

-- ADDON CHAT COMMANDS
windower.register_event("addon command", function(command, ...)
	local args = L{ ... }

    local h = {}
    h[#h+1] = "WhereAmI ".._addon.version
    h[#h+1] = " //wai align <left/center/right> - set the text alignment"
    h[#h+1] = " //wai expand <on/off/toggle> - expand abbreviations"
    h[#h+1] = " //wai reset - resets position and alignment to top left corner of UI"

	if command == 'help' or command == nil then
		for _,tv in pairs(h) do
			windower.add_to_chat(207, windower.to_shift_jis(tv))
		end

	elseif command == 'align' then
        local a = {['left']=true, ['center']=true, ['right']=true}
		if not args:empty() and a[args[1]] ~= nil then
            print_wai("WhereAmI text alignment changed: "..settings.alignment.." -> "..args[1])
            settings.alignment = args[1]
            update_location()
        else
            print_wai(h[2])
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
                print_wai("WhereAmI abbreviation expansion: " .. (settings.replace_abbreviations and "on" or "off"))
                update_location()
            else
                print_wai(h[3])
            end
        else
            -- no args also toggles
    		settings.replace_abbreviations = not settings.replace_abbreviations
            print_wai("WhereAmI abbreviation expansion: " .. (settings.replace_abbreviations and "on" or "off"))
            update_location()
        end

    elseif command == 'reset' then
        settings.alignment = 'left'
        settings.position.x = 0
        settings.position.y = 0
        update_location()

    end

	config.save(settings)
end)