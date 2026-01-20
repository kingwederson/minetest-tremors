-- Shrieker.lua: Registro do mob Shrieker usando mobs_redo API

mobs:register_mob("tremors:shrieker", {
    -- Tipo e stats básicas
    type = "monster",  -- Ataca jogadores à vista
    hp_min = 20,       -- Saúde mínima
    hp_max = 30,       -- Saúde máxima
    armor = 80,        -- Resistência (menor = mais fraco)
    damage = 4,        -- Dano por ataque

    -- Visual e modelo (usa seu shrieker.b3d e textura)
    visual = "mesh",
    mesh = "shrieker.all.glb",
    textures = {
        {"shrieker.png"},  -- Da pasta textures/entity
    },
    visual_size = {x = 8, y = 8},  -- Escala padrão (ajuste se preciso)
    collisionbox = {-0.5, 0, -0.5, 0.5, 1.5, 0.5},  -- Hitbox aproximada (ajuste com testes)
    selectionbox = {-1, 0, -1, 1, 0.5, 0.5},  -- Caixa de seleção

   -- Animações em SEGUNDOS (obrigatório para glTF!)
    animation = {
        stand_start = 0.00,  stand_end = 1.52,  stand_speed = 1,   -- Idle lento para ver oscilação
        walk_start  = 1.52,  walk_end  = 2.60,  walk_speed  = 1,  -- Reduzido para pernas normais
        run_start   = 2.60,  run_end   = 3.08,  run_speed   = 1,
        punch_start = 3.08,  punch_end = 4.12,  punch_speed = 1,  -- Gritando/angry
        die_start   = 4.12,  die_end   = 4.64,  die_speed   = 1,  die_loop = false,  -- Ataque
    },

    animation_speed = 0.8,  -- Leve slowdown global (ajuda a "desacelerar" o walk louco; teste 0.7-1.0)

    -- Força iniciar em idle lento e visível
    on_spawn = function(self)
        self.object:set_animation({x = 0.00, y = 1.52}, 8, 0, true)  -- Inicia idle loop
        self:set_animation("stand")  -- Garante que use stand
    end,

    -- Sons (usa seus arquivos OGG; random toca idle aleatório)
    sounds = {
        random  = "shrieker_idle",     -- mobs_redo vai procurar shrieker_idle1..7.ogg
        attack  = "shrieker_attack",
        damage  = "shrieker_hurt",
        death   = "shrieker_die",
        distance = 48,
    },

    -- AI e movimento básico
    walk_velocity = 1,    -- Velocidade de andar
    run_velocity = 3,     -- Velocidade de correr/ataque
    walk_chance = 50,     -- Chance de começar a andar (0-100)
    jump = true,          -- Pode pular
    jump_height = 2,      -- Altura de pulo
    stepheight = 1.1,     -- Passa blocos de 1 altura
    view_range = 10,      -- Visão para detectar jogadores
    attack_type = "dogfight",  -- Ataque melee (corpo a corpo)
    attack_chance = 30,   -- Chance de atacar (0-100)
    fear_height = 4,      -- Evita quedas de 4+ blocos
    pathfinding = 1,      -- Encontra caminho simples (sem quebrar blocos)
    group_attack = true,  -- Ataca em grupo se outros Shrieker próximos

    -- Danos ambientais
    water_damage = 1,     -- Dano em água
    lava_damage = 5,      -- Dano em lava
    light_damage = 0,     -- Dano em luz forte (prefere escuro)
    fall_damage = true,   -- Toma dano de queda

    -- Drops (itens ao morrer; adicione seus itens custom)
    drops = {
        {name = "default:meat_raw", chance = 1, min = 1, max = 3},
    },

    -- Outros (opcional: taming, breeding, etc., mas básico sem)
    follow = {"default:apple"},  -- Segue se jogador segura (para taming simples)
    runaway = false,             -- Não foge quando hit
    makes_footstep_sound = true, -- Sons de passos
})

-- Opcional: Registra ovo de spawn para testes (use /giveme mobs:egg_tremors_shrieker)
mobs:register_egg("tremors:shrieker", "Shrieker Spawn Egg", "default_grass.png", 1)