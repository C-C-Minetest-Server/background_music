-- background_music/src/player.lua
-- Handle player switching background musics
-- depends: register, decide
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: LGPL-3.0-or-later

local _int = background_music.internal
local logger = _int.logger:sublogger("player")

---Handles returned by `minetest.sound_play`
---@type { [string]: { handle: integer, music: string, expire_time: integer } }
local data = {}

local newjoin_no_bgm = {}

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
    local old_idx = data[name] and data[name].spec_idx
    background_music.fade_player_music(name)
    if music == "null" then return end

    local music_specs = logger:assert(background_music.registered_background_musics[music],
        "Background music %s not found", music)
    local spec_idx = math.random(#music_specs)
    if #music_specs > 1 then
        while spec_idx == old_idx do
            spec_idx = math.random(#music_specs)
        end
    end
    local music_spec = music_specs[spec_idx]
    data[name] = {
        handle = minetest.sound_play(music_spec, {
            to_player = name,
        }),
        music = music,
        spec_idx = spec_idx,
        expire_time = os.time() + music_spec.resend_time + 2,
    }
    return music_spec
end

---Play music on a player
---@param name string
---@param music string
---@return boolean changed
function background_music.play_for_player(name, music)
    if music == "keep" then
        return false
    elseif data[name] then
        if data[name].music == music and data[name].expire_time > os.time() then
            return false
        end
    end
    return background_music.play_for_player_force(name, music)
end

---Decide the music of a player then apply the change
---@param player ObjectRef
function background_music.decide_and_play(player)
    local music = background_music.get_music_for(player)
    local name = player:get_player_name()
    local spec = background_music.play_for_player(name, music)
    if spec then
        logger:action("Playing %s -> %s on player %s", music, spec.name, name)
    end
end

modlib.minetest.register_globalstep(1, function()
    for _, player in ipairs(minetest.get_connected_players()) do
        background_music.decide_and_play(player)
    end
end)

background_music.register_on_decide_music(function(player)
    local name = player:get_player_name()
    local now = os.time()

    if newjoin_no_bgm[name] and newjoin_no_bgm[name] > now then
        return "null", 10000
    else
        newjoin_no_bgm[name] = nil
    end
end)

minetest.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    newjoin_no_bgm[name] = os.time() + 2
end)

minetest.register_on_leaveplayer(function(player)
    local name = player:get_player_name()
    data[name] = nil
    newjoin_no_bgm[name] = nil
end)
