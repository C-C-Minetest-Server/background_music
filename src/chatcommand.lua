-- background_music/src/chatcommand.lua
-- Commands
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: LGPL-3.0-or-later

local _int = background_music.internal
local S = _int.S
local logger = _int.logger:sublogger("decide")

minetest.register_chatcommand("toggle_bgm", {
    description = S("Enable or disable background musics"),
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then
            return false, S("You must be online to use this.")
        end

        local meta = player:get_meta()
        local value = meta:get_int("background_music_disable") == 0
        meta:set_int("background_music_disable", value and 1 or 0)

        return true, value
            and S("Successfully enabled background music")
            or S("Successfully disabled background music")
    end,
})

background_music.register_on_decide_music(function(player)
    local meta = player:get_meta()
    if meta:get_int("background_music_disable") == 1 then
        return "null", math.huge
    end
end)
