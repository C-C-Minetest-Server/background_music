-- background_music/src/player.lua
-- Handle player switching background musics
-- depends: register, decide
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: LGPL-3.0-or-later

local _int = background_music.internal
local logger = _int.logger:sublogger("player")

---Handles returned by `minetest.sound_play`
---@type { [string]: integer }
local data = {}

---Fade audio of a player
---@param name string
function background_music.fade_player_music(name)
    if data[name] then
        minetest.sound_fade(data[name].handle, 0.5, 0)
        data[name] = nil
    end
end

---Play music on a player, restart even if it is already playing
---@param name string
---@param music string
function background_music.play_for_player_force(name, music)
    background_music.fade_player_music(name)
    local music_spec = logger:assert(background_music.registered_background_musics[music],
        "Background music %s not found", music)
    data[name] = {
        handle = minetest.sound_play(music_spec, {
            to_player = name,
            loop = true,
        }),
        music = music
    }
end

---Play music on a player
---@param name string
---@param music string
---@return boolean changed
function background_music.play_for_player(name, music)
    if music == "keep" or (data[name] and data[name].music == music) then
        return false
    end
    background_music.play_for_player_force(name, music)
    return true
end

---Decide the music of a player then apply the change
---@param player ObjectRef
function background_music.decide_and_play(player)
    local music = background_music.get_music_for(player)
    local name = player:get_player_name()
    if background_music.play_for_player(name, music) then
        logger:action("Playing %s on player %s", music, name)
    end
end

modlib.minetest.register_globalstep(1, function()
    for _, player in ipairs(minetest.get_connected_players()) do
        background_music.decide_and_play(player)
    end
end)

minetest.register_on_leaveplayer(function(player)
    data[player:get_player_name()] = nil
end)
