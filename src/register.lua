-- background_music/src/register.lua
-- Register background musics
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: LGPL-3.0-or-later

local _int = background_music.internal
local logger = _int.logger:sublogger("register")

---Extended SimpleSoundSpec
---@class background_music.XSimpleSoundSpec: table
---@field name string The sound group name
---@field gain? number
---@field pitch? number
---@field gain? number
---@field resend_time number Approximate playback duration in seconds.
---@field avaliable_to? fun(name: string): boolean Whether a song is avaliable to a player. Checked on start.

---Table of registered background musics
---@type { [string]: background_music.XSimpleSoundSpec[] }
background_music.registered_background_musics = {}

background_music.reserved_names = {
    null = true, -- Stop playing any musics
    keep = true, -- Keep playing the current music
}

---Register a background music
---@param name string The technical name of the background music. Cannot be `"null"`.
---@param specs background_music.XSimpleSoundSpec[]
function background_music.register_music(name, specs)
    logger:assert(type(name) == "string",
        "Bad background music name type (expected string, got %s)", type(name))
    logger:assert(not background_music.reserved_names[name],
        "Attempt to override reserved background music name \"%s\"", name)
    background_music.registered_background_musics[name] = specs
end
