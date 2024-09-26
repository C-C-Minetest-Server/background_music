-- background_music/src/chatcommand.lua
-- Commands
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: LGPL-3.0-or-later

local _int = background_music.internal
local S = _int.S
local logger = _int.logger:sublogger("chatcommand")

minetest.register_chatcommand("toggle_bgm", {
    description = S("Enable or disable background musics"),
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then
            return false, S("You must be online to use this.")
        end

        local meta = player:get_meta()
        local value = meta:get_int("background_music_disable") == 1
        meta:set_int("background_music_disable", value and 0 or 1)

        logger:action("%s %s background music", name,
            value and "enabled" or "disabled")

        return true, value
            and S("Successfully enabled background music")
            or S("Successfully disabled background music")
    end,
})

local force2bgm = {}

minetest.register_chatcommand("force2bgm", {
    description = S("Force a player (or yourself) to a BGM"),
    privs = { server = true },
    func = function(name, param)
        local args = string.split(param, " ", false, 2)
        local target, bgm
        if args[2] then
            target, bgm = args[1], args[2]
        else
            target, bgm = name, args[1]
        end

        if not minetest.get_player_by_name(target) then
            return false, S("Player @1 is not online.", target)
        elseif bgm ~= "null" and not background_music.registered_background_musics[bgm] then
            return false, S("Background music @1 does not exist.", bgm)
        end

        if bgm == "null" then
            force2bgm[target] = nil
            return true, S("Successfully lifted force2bgm for @1.", target)
        end
        force2bgm[target] = bgm
        return true, S("Successfully set background music of @1 to @2.", target, bgm)
    end,
})

minetest.register_on_leaveplayer(function(player)
    local name = player:get_player_name()
    force2bgm[name] = nil
end)

background_music.register_on_decide_music(function(player)
    local meta = player:get_meta()
    if meta:get_int("background_music_disable") == 1 then
        return "null", math.huge
    end
    local name = player:get_player_name()
    if force2bgm[name] then
        return force2bgm[name], math.huge
    end
end)
