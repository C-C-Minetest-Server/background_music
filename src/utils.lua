-- background_music/src/utils.lua
-- Utility functions
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: LGPL-3.0-or-later

if minetest.features.dynamic_add_media_startup and minetest.features.dynamic_add_media_filepath then
    ---Register a list of sounds to be randomly looped under `alias`
    ---@param alias name
    ---@param paths string[]
    function background_music.register_music_random_list(alias, paths)
        for i, path in ipairs(paths) do
            minetest.dynamic_add_media({
                filename = string.format("%s.%i.ogg", alias, i),
                filepath = path,
            })
        end
    end
end
