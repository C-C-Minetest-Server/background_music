-- background_music/init.lua
-- Handle background music by callbacks
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: LGPL-3.0-or-later

background_music = {}
background_music.internal = {}
background_music.internal.logger = logging.logger("background_music")

local MP = minetest.get_modpath("background_music")
for _, name in ipairs({
    "register",
    "decide", -- depends: register
    "player", -- depends: register, decide
    "utils",
}) do
    dofile(table.concat({ MP, "src", name .. ".lua" }, DIR_DELIM))
end
