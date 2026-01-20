-- Shrieker.lua: Registro do mob Shrieker usando mobs_redo API

mobs:register_mob("tremors:shrieker", {
    type = "monster",
    hp_min = 20,
    hp_max = 30,
    armor = 80,
    damage = 4,

    visual = "mesh",
    mesh = "shrieker.all.glb",
    textures = {{"shrieker.png"}},
    visual_size = {x = 8, y = 8},
    collisionbox = {-0.5, 0, -0.5, 0.5, 1.5, 0.5},
    selectionbox = {-1, 0, -1, 1, 0.5, 0.5},

    animation = {
        stand_start = 0.00, stand_end = 1.52, stand_speed = 1,
        walk_start  = 1.52, walk_end  = 2.60, walk_speed  = 1,
        run_start   = 2.60, run_end   = 3.08, run_speed   = 1,
        punch_start = 3.08, punch_end = 4.12, punch_speed = 1,
        die_start   = 4.12, die_end   = 4.64, die_speed   = 1, die_loop = false,
    },

    animation_speed = 0.8,

    on_activate = function(self, staticdata, dtime_s)
        -- Inicializa variáveis ANTES do on_spawn
        self.chase_sound_timer = 0
        self.detection_timer = 0
        self.was_chasing = false
        self.last_sound_time = 0
        self.sound_cooldown = 0
        self.alerted = false
        self.has_valid_ground = false
    end,

    on_spawn = function(self)
        local pos = self.object:get_pos()
        
        if pos then
            -- Verifica se a posição atual é válida
            local current_node = minetest.get_node(pos)
            local below_pos = {x = pos.x, y = pos.y - 1, z = pos.z}
            local below_node = minetest.get_node(below_pos)
            local walkable = minetest.registered_nodes[below_node.name]
            
            -- Se não tem chão válido abaixo, procura uma posição melhor
            if not walkable or not walkable.walkable or current_node.name ~= "air" then
                self.has_valid_ground = false
                
                -- Procura uma posição com chão sólido e ar acima
                local found_valid = false
                for search_radius = 1, 5 do
                    for dx = -search_radius, search_radius do
                        for dz = -search_radius, search_radius do
                            for dy = -2, 2 do
                                local test_pos = {
                                    x = pos.x + dx,
                                    y = pos.y + dy,
                                    z = pos.z + dz
                                }
                                
                                local test_node = minetest.get_node(test_pos)
                                local test_below = {x = test_pos.x, y = test_pos.y - 1, z = test_pos.z}
                                local test_below_node = minetest.get_node(test_below)
                                local test_walkable = minetest.registered_nodes[test_below_node.name]
                                
                                if test_node.name == "air" and test_walkable and test_walkable.walkable then
                                    self.object:set_pos(test_pos)
                                    pos = test_pos
                                    found_valid = true
                                    self.has_valid_ground = true
                                    break
                                end
                            end
                            if found_valid then break end
                        end
                        if found_valid then break end
                    end
                    if found_valid then break end
                end
                
                -- Se não encontrou posição válida, remove o mob
                if not found_valid then
                    minetest.log("warning", "[tremors] Shrieker em posição inválida, removendo...")
                    self.object:remove()
                    return
                end
            else
                self.has_valid_ground = true
            end
        end
        
        -- Configura animação
        self.object:set_animation({x = 0.00, y = 1.52}, 8, 0, true)
        self:set_animation("stand")
        
        -- Som de idle inicial (apenas uma vez, com chance)
        if math.random(1, 3) == 1 then  -- 33% de chance
            minetest.after(1.0, function()
                if self.object and self.object:get_pos() then
                    local idle_sound = "shrieker_idle" .. math.random(1, 7)
                    minetest.sound_play(idle_sound, {
                        object = self.object,
                        max_hear_distance = 20,
                        gain = 0.4,
                    })
                end
            end)
        end
    end,

    sounds = {
        random  = "shrieker_idle",
        war_cry = "shrieker_angry",
        attack  = "shrieker_attack",
        damage  = "shrieker_hurt",
        death   = "shrieker_die",
        distance = 25,
    },

    do_custom = function(self, dtime)
        -- Atualiza timers
        if not self.detection_timer then self.detection_timer = 0 end
        if not self.sound_cooldown then self.sound_cooldown = 0 end
        if not self.chase_sound_timer then self.chase_sound_timer = 0 end
        
        self.detection_timer = self.detection_timer + dtime
        self.sound_cooldown = math.max(0, self.sound_cooldown - dtime)
        self.chase_sound_timer = self.chase_sound_timer + dtime
        
        -- Verificação periódica de posição (previne fallback_nodes)
        if self.detection_timer >= 1.0 then
            local pos = self.object:get_pos()
            if pos then
                -- Verifica se ainda está em posição válida
                local current_node = minetest.get_node(pos)
                local below_pos = {x = pos.x, y = pos.y - 1, z = pos.z}
                local below_node = minetest.get_node(below_pos)
                local walkable = minetest.registered_nodes[below_node.name]
                
                -- Se perdeu o chão, tenta corrigir
                if not walkable or not walkable.walkable then
                    self.has_valid_ground = false
                    
                    -- Procura posição válida próxima
                    local found_ground = false
                    for i = 1, 10 do
                        local test_pos = {
                            x = pos.x + math.random(-2, 2),
                            y = pos.y + math.random(-1, 1),
                            z = pos.z + math.random(-2, 2)
                        }
                        
                        local test_below = {x = test_pos.x, y = test_pos.y - 1, z = test_pos.z}
                        local test_below_node = minetest.get_node(test_below)
                        local test_node = minetest.get_node(test_pos)
                        local test_walkable = minetest.registered_nodes[test_below_node.name]
                        
                        if test_node.name == "air" and test_walkable and test_walkable.walkable then
                            self.object:set_pos(test_pos)
                            self.has_valid_ground = true
                            found_ground = true
                            break
                        end
                    end
                    
                    -- Se não encontrou chão, para a perseguição
                    if not found_ground and self.attack then
                        self.attack = nil
                        self.state = "stand"
                        minetest.chat_send_all("[DEBUG] Shrieker perdeu chão, parando perseguição")
                    end
                else
                    self.has_valid_ground = true
                end
                
                -- Detecção de jogadores (só se tiver chão válido)
                if self.has_valid_ground then
                    local objects = minetest.get_objects_inside_radius(pos, self.view_range)
                    local can_see_player = false
                    
                    for _, obj in ipairs(objects) do
                        if obj:is_player() then
                            local player_pos = obj:get_pos()
                            local distance = vector.distance(pos, player_pos)
                            
                            if distance <= self.view_range then
                                -- Verificação simplificada de linha de visão
                                local ray = minetest.raycast(pos, player_pos, false, true)
                                local hit = ray:next()
                                local obstructed = false
                                
                                -- Verifica alguns pontos ao longo do caminho
                                local steps = math.floor(distance)
                                for i = 1, steps do
                                    local check_pos = {
                                        x = pos.x + (player_pos.x - pos.x) * (i / steps),
                                        y = pos.y + (player_pos.y - pos.y) * (i / steps),
                                        z = pos.z + (player_pos.z - pos.z) * (i / steps)
                                    }
                                    
                                    local node = minetest.get_node(check_pos)
                                    local node_def = minetest.registered_nodes[node.name]
                                    if node_def and node_def.walkable then
                                        obstructed = true
                                        break
                                    end
                                end
                                
                                if not obstructed then
                                    can_see_player = true
                                    if not self.attack or self.attack ~= obj then
                                        self.attack = obj
                                        self.state = "attack"
                                        self.alerted = true
                                        
                                        -- Som de alerta inicial (50% de chance)
                                        if math.random(1, 2) == 1 and self.sound_cooldown <= 0 then
                                            local angry_sound = "shrieker_angry" .. math.random(1, 5)
                                            minetest.sound_play(angry_sound, {
                                                object = self.object,
                                                max_hear_distance = 48,
                                                gain = 0.8,
                                            })
                                            self.sound_cooldown = 3.0  -- Cooldown inicial
                                            minetest.chat_send_all("[DEBUG] Shrieker detectou jogador!")
                                        end
                                    end
                                    break
                                end
                            end
                        end
                    end
                    
                    -- Se não vê jogador mas estava perseguindo
                    if not can_see_player and self.attack then
                        self.attack = nil
                        self.state = "stand"
                        self.alerted = false
                        minetest.chat_send_all("[DEBUG] Shrieker perdeu visão do jogador")
                    end
                end
                
                self.detection_timer = 0
            end
        end
        
        -- Sons durante perseguição (MUITO menos frequentes)
        if self.attack and self.alerted then
            self.chase_sound_timer = self.chase_sound_timer + dtime
            
            -- Som durante perseguição: apenas ocasionalmente
            if self.chase_sound_timer >= 30.0 then  -- A cada 8 segundos no mínimo
                -- Chance decrescente baseada no tempo de perseguição
                local sound_chance = 30  -- 30% de chance inicial
                
                -- Reduz chance se já está perseguindo há muito tempo
                if self.chase_sound_timer > 30.0 then
                    sound_chance = 15
                elseif self.chase_sound_timer > 60.0 then
                    sound_chance = 8
                end
                
                -- Som apenas se passar na chance E estiver em cooldown
                if math.random(1, 100) <= sound_chance and self.sound_cooldown <= 0 then
                    local angry_sound = "shrieker_angry" .. math.random(1, 5)
                    minetest.sound_play(angry_sound, {
                        object = self.object,
                        max_hear_distance = 30,
                        gain = 0.6,  -- Volume mais baixo
                    })
                    self.sound_cooldown = 5.0  -- Cooldown entre sons
                    self.chase_sound_timer = 0
                    minetest.chat_send_all("[DEBUG] Shrieker emite som de perseguição")
                end
            end
        else
            self.chase_sound_timer = 0
        end
        
        -- Sons aleatórios quando em repouso (muito raros)
        if not self.attack and self.sound_cooldown <= 0 and math.random(1, 1000) == 1 then
            local idle_sound = "shrieker_idle" .. math.random(1, 7)
            minetest.sound_play(idle_sound, {
                object = self.object,
                max_hear_distance = 15,
                gain = 0.3,
            })
            self.sound_cooldown = 10.0
        end
        
        return true
    end,

    on_damage = function(self, damage, damager)
        -- Som de hurt quando atacado (sempre)
        minetest.sound_play("shrieker_hurt", {
            object = self.object,
            max_hear_distance = 25,
            gain = 0.9,
        })
        
        -- Se atacado por jogador, torna-se agressivo
        if damager and damager:is_player() then
            if not self.attack or self.attack ~= damager then
                self.attack = damager
                self.state = "attack"
                self.alerted = true
                
                -- Som de angry ao ser atacado (50% de chance)
                if math.random(1, 2) == 1 then
                    local angry_sound = "shrieker_angry" .. math.random(1, 5)
                    minetest.sound_play(angry_sound, {
                        object = self.object,
                        max_hear_distance = 35,
                        gain = 1.0,
                    })
                    self.sound_cooldown = 4.0
                end
                
                minetest.chat_send_all("[DEBUG] Shrieker contra-ataca!")
            end
        end
        
        return damage
    end,

    -- Propriedades de movimento e combate
    walk_velocity = 1.2,
    run_velocity = 3.0,
    walk_chance = 25,
    jump = true,
    jump_height = 1.2,
    stepheight = 1.1,
    view_range = 18,  -- Reduzido para melhor desempenho
    attack_type = "dogfight",
    attack_chance = 90,
    reach = 2.5,
    fear_height = 3,
    pathfinding = 1,  -- Pathfinding mais simples
    group_attack = true,
    
    attack_animals = true,
    attack_players = true,
    attack_npcs = true,
    passive = false,

    water_damage = 2,
    lava_damage = 10,
    light_damage = 0,
    fall_damage = true,
    suffocation = false,
    floats = true,
    fall_speed = -2.5,

    drops = {
        {name = "default:meat_raw", chance = 1, min = 1, max = 3},
    },

    follow = {},
    runaway = false,
    makes_footstep_sound = true,
    knock_back = 1.2,
    
    on_step = function(self, dtime)
        -- Verificação extra de posição a cada passo
        if self.object then
            local pos = self.object:get_pos()
            if pos then
                -- Verifica se está caindo no vazio
                local below_pos = {x = pos.x, y = pos.y - 1, z = pos.z}
                local below_node = minetest.get_node(below_pos)
                local walkable = minetest.registered_nodes[below_node.name]
                
                if not walkable or not walkable.walkable then
                    -- Se está caindo, reduz velocidade e procura chão
                    self.run_velocity = math.max(1.0, self.run_velocity * 0.8)
                    
                    -- Procura chão abaixo
                    for i = 2, 10 do
                        local deeper_pos = {x = pos.x, y = pos.y - i, z = pos.z}
                        local deeper_node = minetest.get_node(deeper_pos)
                        local deeper_walkable = minetest.registered_nodes[deeper_node.name]
                        
                        if deeper_walkable and deeper_walkable.walkable then
                            -- Teleporta para cima do chão encontrado
                            self.object:set_pos({x = pos.x, y = deeper_pos.y + 1, z = pos.z})
                            self.run_velocity = 3.0  -- Restaura velocidade
                            break
                        end
                    end
                else
                    self.run_velocity = 3.0  -- Velocidade normal no chão
                end
            end
        end
        
        return true
    end,
    
    on_blast = function(self, damage)
        minetest.sound_play("shrieker_die", {
            object = self.object,
            max_hear_distance = 40,
            gain = 1.0,
        })
        return damage
    end
})

-- Registra o ovo de spawn
mobs:register_egg("tremors:shrieker", "Shrieker Spawn Egg", "default_grass.png", 1)

-- Comando para spawn seguro (para testes)
minetest.register_chatcommand("spawn_shrieker_safe", {
    params = "",
    description = "Spawna um Shrieker em posição segura",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Jogador não encontrado" end
        
        local pos = player:get_pos()
        local spawned = false
        
        -- Procura posição segura em círculos concêntricos
        for radius = 3, 10, 2 do
            for angle = 0, 360, 45 do
                local rad = math.rad(angle)
                local test_pos = {
                    x = pos.x + math.cos(rad) * radius,
                    y = pos.y + 2,
                    z = pos.z + math.sin(rad) * radius
                }
                
                -- Verifica se é posição válida
                local node_at = minetest.get_node(test_pos)
                local node_below = {x = test_pos.x, y = test_pos.y - 1, z = test_pos.z}
                local below_node = minetest.get_node(node_below)
                local walkable = minetest.registered_nodes[below_node.name]
                
                if node_at.name == "air" and walkable and walkable.walkable then
                    local mob = minetest.add_entity(test_pos, "tremors:shrieker")
                    if mob then
                        spawned = true
                        return true, "Shrieker spawnado em posição segura!"
                    end
                end
            end
            if spawned then break end
        end
        
        if not spawned then
            return false, "Não foi possível encontrar posição segura para spawn"
        end
    end
})

minetest.log("action", "[tremors] Shrieker carregado com melhorias de som e posicionamento")