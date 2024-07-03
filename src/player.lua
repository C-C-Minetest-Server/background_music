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

local start_play_gap = {}

---Get current music of a player
---@param name steing
---@return string? music
function background_music.get_current_music(name)
    if not data[name] then return end
    return data[name].music
end

---Fade audio of a player
---@param name string
---@param instant? boolean
function background_music.fade_player_music(name, instant)
    if data[name] then
        if instant then
            minetest.sound_stop(data[name].handle)
        else
            minetest.sound_fade(data[name].handle, 0.5, 0)
        end
        data[name] = nil
    end
end

---Play music on a player, restart even if it is already playing
---@param name string
---@param music string
---@param instant? boolean
function background_music.play_for_player_force(name, music, instant)
    local old_idx = data[name] and data[name].spec_idx
    background_music.fade_player_music(name, instant)
    if music == "null" then return end

    local music_specs = logger:assert(background_music.registered_background_musics[music],
        "Background music %s not found", music)

    local avaliable_idx = {}
    for i, spec in ipairs(music_specs) do
        local avaliable = true
        if spec.avaliable_to then
            avaliable = spec.avaliable_to(name)
        end
        if avaliable then
            avaliable_idx[#avaliable_idx+1] = i
        end
    end
    local spec_idx = avaliable_idx[math.random(#avaliable_idx)]
    if #avaliable_idx ~= 1 then
        while spec_idx == old_idx do
            spec_idx = avaliable_idx[math.random(#avaliable_idx)]
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
---@param instant? boolean
---@return boolean changed
function background_music.play_for_player(name, music, instant)
    if music == "keep" then
        return false
    elseif data[name] then
        if data[name].music == music and data[name].expire_time > os.time() then
            return false
        end
    end
    return background_music.play_for_player_force(name, music, instant)
end

---Decide the music of a player then apply the change
---@param player ObjectRef
function background_music.decide_and_play(player, instant)
    local music = background_music.get_music_for(player)
    local name = player:get_player_name()
    if music == "null" and data[name] then
        logger:action("Stopping music on player %s", name)
        background_music.fade_player_music(name, instant)
        return
    end

    if start_play_gap[name] and start_play_gap[name] > os.time() then
        if data[name] and data[name].music ~= music then
            logger:action("Stopping music on player %s due to start play gap", name)
            background_music.fade_player_music(name, instant)
            return
        end
    else
        local spec = background_music.play_for_player(name, music, instant)
        if spec then
            logger:action("Playing %s -> %s on player %s", music, spec.name, name)
        end
        start_play_gap[name] = nil
    end
end

modlib.minetest.register_globalstep(1, function()
    for _, player in ipairs(minetest.get_connected_players()) do
        background_music.decide_and_play(player)
    end
end)

---Set playing gap
---@param name string
---@param sec number
function background_music.set_start_play_gap(name, sec)
    start_play_gap[name] = os.time() + sec
end

minetest.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    background_music.set_start_play_gap(name, 2)
end)

minetest.register_on_leaveplayer(function(player)
    local name = player:get_player_name()
    data[name] = nil
    start_play_gap[name] = nil
end)
