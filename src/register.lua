-- background_music/src/register.lua
-- Register background musics
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: LGPL-3.0-or-later

local _int = background_music.internal
local logger = _int.logger:sublogger("register")

---Table of registered background musics
---@type { [string]: SimpleSoundSpec }
background_music.registered_background_musics = {}

---@enum (keys) background_music.ResevredNames
local reserved_names = {
    null = true, -- Stop playing any musics
    keep = true, -- Keep playing the current music
}

---Register a background music
---@param name string The technical name of the background music. Cannot be `"null"`.
---@param spec SimpleSoundSpec
function background_music.register_music(name, spec)
    logger:assert(type(name) == "string",
        "Bad background music name type (expected string, got %s)", type(name))
    logger:assert(not reserved_names[name],
        "Attempt to override reserved background music name \"%s\"", name)
    background_music.registered_background_musics[name] = spec
end
