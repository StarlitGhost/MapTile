_addon.name = 'MapTile'
_addon.author = 'Ghosty'
_addon.version = '0.1'
_addon.command = 'maptile'

config = require('config')
texts = require('texts')
res = require('resources')

local windower_settings = windower.get_windower_settings()
local ui_scale = { x = windower_settings.x_res / windower_settings.ui_x_res ,
                   y = windower_settings.y_res / windower_settings.ui_y_res }
local LOGIN_ZONE_PACKET = 0x0A
local STATUS_ID_CUTSCENES = 0x04
local wait_for_pos = true

local defaults = {}
defaults.text = {}
defaults.text.font = 'Arial'
defaults.text.size = 10
defaults.text.red = 255
defaults.text.green = 255
defaults.text.blue = 255
defaults.text.alpha = 200
defaults.bg = {}
defaults.bg.visible = false
defaults.flags = {}
defaults.flags.bold = true
defaults.flags.italic = true
defaults.flags.draggable = true

local settings = config.load(defaults)
config.save(settings)

local maptile = {}
maptile.initialized = false
maptile.ready = false
maptile.hide = false
maptile.txt = texts.new(settings)

-- initialize addon
local function initialize()
    maptile.txt:text('${ZoneName|} ${MapTile|}')
    maptile.initialized = true
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
    end

    maptile.txt:update(maptile)

    local width, _ = maptile.txt:extents()

    -- skip empty zone/pos strings
    if width == 0 then
        return
    end
    -- initialize maptile.PrevWidth
    if maptile.PrevWidth == nil or maptile.PrevWidth < 5 then
        maptile.PrevWidth = width
    end

    -- adjust the position to keep the text centered
    if width ~= maptile.PrevWidth then
        local offset = (maptile.PrevWidth - width) / 2
        -- skip offset changes smaller than 1 pixel
        if offset >= -0.5 and offset <= 0.5 then
            return
        end
        local new_pos_x = maptile.txt:pos_x() + offset
        --print('maptile prevWidth: '..maptile.PrevWidth..' width: '..width..' offset: '..offset..' new x: '..new_pos_x)
        maptile.txt:pos_x(new_pos_x)
        maptile.PrevWidth = width
    end
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