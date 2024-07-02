-- background_music/src/decide.lua
-- Decide the background music of a player
-- depends: register
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: LGPL-3.0-or-later

local _int = background_music.internal
local logger = _int.logger:sublogger("decide")

---@alias background_music.DecideMusicFunc fun(player: ObjectRef): string, number?

---Functions to decide background musics
---@type background_music.DecideMusicFunc[]
background_music.registered_on_decide_music = {}

---Register function to decide background music.
---The function should either return `nil` or a background music name
-- and its priority (default: `0`, the larger the upper).
---@param func background_music.DecideMusicFunc
function background_music.register_on_decide_music(func)
    background_music.registered_on_decide_music[#background_music.registered_on_decide_music+1] = func
end

---Get the music for a player
---@param player ObjectRef
---@return string
---@nodiscard
function background_music.get_music_for(player)
    ---@type [string, number][]
    local results = {}
    for _, func in ipairs(background_music.registered_on_decide_music) do
        local music, priority = func(player)
        if music then
            logger:assert(type(music) == "string",
                "Bad returned background music name type (expected string, got %s)", type(music))
            logger:assert(
                background_music.registered_background_musics[music]
                or background_music.reserved_names[music],
                "Background music %s does not exist", music)

            if priority == nil then
                priority = 0
            end
            ---@cast priority number
            logger:assert(type(priority) == "number",
                "Bad returned priority type (expected string, got %s)", type(music))
            results[#results+1] = { music, priority }
        end
    end
    if #results == 0 then return "null" end

    table.sort(results, function(a, b)
        if a[2] == b[2] then
            -- Though undefined, prevent chaotic behavior
            return a[1] > b[1]
        end
        return a[2] > b[2]
    end)

    return results[1][1]
end
