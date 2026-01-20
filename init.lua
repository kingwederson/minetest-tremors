-- Init.lua para mod tremors

local path = minetest.get_modpath("tremors")

-- Carrega o arquivo do Shrieker
dofile(path .. "/shrieker.lua")

-- Opcional: Registra spawn automático (ajuste nodes/chance)
mobs:spawn({
    name = "tremors:shrieker",
    nodes = {"default:dirt_with_grass", "default:desert_sand"},  -- Spawna em grama ou deserto
    neighbors = {"air"},
    min_light = 0,
    max_light = 14,  -- Prefere escuro
    interval = 60,   -- Cada 60s checa spawn
    chance = 8000,   -- Raro (ajuste para mais comum)
    active_object_count = 1,  -- Max 1 por área
    min_height = -100,        -- Underground possível
    max_height = 200,
})