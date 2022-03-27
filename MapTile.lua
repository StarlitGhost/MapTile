--[[
Copyright 2022, Ghosty
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

 * Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
 * Neither the name of MapTile nor the
   names of its contributors may be used to endorse or promote products
   derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL Ghosty BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

_addon.name = 'MapTile'
_addon.author = 'Ghosty'
_addon.version = '0.1'
_addon.command = 'maptile'

config = require('config')
texts = require('texts')
res = require('resources')

windower_settings = windower.get_windower_settings()
ui_scale = { x = windower_settings.x_res / windower_settings.ui_x_res , 
             y = windower_settings.y_res / windower_settings.ui_y_res }
local LOGIN_ZONE_PACKET = 0x0A
local STATUS_ID_CUTSCENES = 0x04
local wait_for_pos = true

defaults = {}
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
function initialize()
    maptile.txt:text('${ZoneName|} ${MapTile|}')
    maptile.initialized = true
end

function update_maptile()
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
        offset = (maptile.PrevWidth - width) / 2
        -- skip offset changes smaller than 1 pixel
        if offset >= -0.5 and offset <= 0.5 then
            return
        end
        new_pos_x = maptile.txt:pos_x() + offset
        --print('maptile prevWidth: '..maptile.PrevWidth..' width: '..width..' offset: '..offset..' new x: '..new_pos_x)
        maptile.txt:pos_x(new_pos_x)
        maptile.PrevWidth = width
    end
end

-- hide the addon
function hide()
    maptile.txt:hide()
    maptile.ready = false

    windower.send_command('unload ffxidb')
    windower.send_command('wm icon off')
end

-- show the addon
function show()
    if maptile.initialized == false then
        initialize()
    end

    maptile.txt:show()
    maptile.ready = true

    windower.send_command('load ffxidb')
    windower.send_command('wm icon on')
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
        info = windower.ffxi.get_info()
        if info.mog_house then
            hide()
        end
    end
end)

-- BEFORE EACH RENDER
windower.register_event('prerender', function()
    local pos = windower.ffxi.get_position()
    info = windower.ffxi.get_info()
    if pos == '(?-?)' then
        hide()
        wait_for_pos = true
    elseif wait_for_pos and not info.mog_house then
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