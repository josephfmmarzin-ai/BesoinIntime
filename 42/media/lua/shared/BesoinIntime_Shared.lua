-- ===========================================================================
-- Besoin Intime - logique partagee (client + serveur) - Build 42
-- ===========================================================================
BesoinIntime = BesoinIntime or {}
local BI = BesoinIntime

BI.VERSION   = "3.0.1"
BI.MODULE    = "BesoinIntime"
BI.KEY       = "BesoinIntime_Need"        -- jauge 0..100
BI.KEY_CALM  = "BesoinIntime_CalmUntil"   -- heures-monde jusqu'a la fin de la serenite
BI.PANEL_KEY = "BesoinIntime_PanelVisible"
BI.KEY_LAST  = "BesoinIntime_LastRelief"   -- heures-monde du dernier moment
BI.MOODLE_POS_KEY = "BesoinIntime_MoodlePos"

local function clamp(v, lo, hi)
    if v < lo then return lo elseif v > hi then return hi end
    return v
end
BI.clamp = clamp

-- Option Sandbox avec valeur de secours
function BI.opt(name, default)
    local sv = SandboxVars and SandboxVars.BesoinIntime
    if sv and sv[name] ~= nil then return sv[name] end
    return default
end


-- ---------------------------------------------------------------------------
-- Textes de secours FR / EN (utilises si les fichiers Translate ne sont pas charges)
-- ---------------------------------------------------------------------------
BI.TEXTS = {
    EN = {
        ContextMenu_BesoinIntime_Title = "Intimate need",
        ContextMenu_BesoinIntime_State = "State: %1 (%2 %%)",
        ContextMenu_BesoinIntime_TitleState = "Intimate need - %1 (%2 %%)",
        ContextMenu_BesoinIntime_Relax = "Take some time for yourself",
        ContextMenu_BesoinIntime_Propose = "Propose an intimate moment to %1",
        ContextMenu_BesoinIntime_TogglePanel = "Show / hide gauge",
        IGUI_BesoinIntime_Title = "Intimate need",
        IGUI_BesoinIntime_Stage0 = "Satisfied",
        IGUI_BesoinIntime_Stage1 = "Calm",
        IGUI_BesoinIntime_Stage2 = "In the mood",
        IGUI_BesoinIntime_Stage3 = "Frustrated",
        IGUI_BesoinIntime_Stage4 = "Very frustrated",
        IGUI_BesoinIntime_Calm = "Serene",
        IGUI_BesoinIntime_Started = "Relaxing...",
        IGUI_BesoinIntime_Relieved = "Relieved",
        IGUI_BesoinIntime_Interrupted = "Zombies nearby!",
        IGUI_BesoinIntime_NoDesire = "Not right now, too soon since last time.",
        IGUI_BesoinIntime_InVehicle = "Not in a vehicle.",
        IGUI_BesoinIntime_VehicleMoving = "Stop the vehicle first.",
        IGUI_BesoinIntime_NoBedOrSeat = "Needs a bed, a couch, a chair or a parked vehicle.",
        IGUI_BesoinIntime_NotIndoors = "Needs to be indoors.",
        IGUI_BesoinIntime_NoBed = "Needs a bed, a couch or a chair nearby.",
        IGUI_BesoinIntime_TooTired = "Too exhausted.",
        IGUI_BesoinIntime_TooHungry = "Too hungry or thirsty.",
        IGUI_BesoinIntime_ZombiesNear = "Zombies are too close.",
        IGUI_BesoinIntime_NoPrivacy = "Someone else is nearby.",
        IGUI_BesoinIntime_ProposalSent = "Proposal sent...",
        IGUI_BesoinIntime_ProposalReceived = "%1 proposes an intimate moment. Accept?",
        IGUI_BesoinIntime_Declined = "Proposal declined.",
        IGUI_BesoinIntime_MoodleCalm = "Serene. The need does not rise for a while, and sleep is more restful.",
        IGUI_BesoinIntime_MoodleDesc2 = "In the mood. A bed or a couch, indoors, would do some good.",
        IGUI_BesoinIntime_MoodleDesc3 = "Frustrated. Stress is building up. Find some privacy.",
        IGUI_BesoinIntime_MoodleDesc4 = "Very frustrated. Stress and unhappiness keep rising.",
    },
    FR = {
        ContextMenu_BesoinIntime_Title = "Besoin intime",
        ContextMenu_BesoinIntime_State = "\201tat : %1 (%2 %%)",
        ContextMenu_BesoinIntime_TitleState = "Besoin intime - %1 (%2 %%)",
        ContextMenu_BesoinIntime_Relax = "Prendre un moment pour soi",
        ContextMenu_BesoinIntime_Propose = "Proposer un moment intime \224 %1",
        ContextMenu_BesoinIntime_TogglePanel = "Afficher / masquer la jauge",
        IGUI_BesoinIntime_Title = "Besoin intime",
        IGUI_BesoinIntime_Stage0 = "Combl\233(e)",
        IGUI_BesoinIntime_Stage1 = "Serein(e)",
        IGUI_BesoinIntime_Stage2 = "En manque",
        IGUI_BesoinIntime_Stage3 = "Frustr\233(e)",
        IGUI_BesoinIntime_Stage4 = "Tr\232s frustr\233(e)",
        IGUI_BesoinIntime_Calm = "Apais\233(e)",
        IGUI_BesoinIntime_Started = "Se d\233tend...",
        IGUI_BesoinIntime_Relieved = "Soulag\233(e)",
        IGUI_BesoinIntime_Interrupted = "Zombies \224 proximit\233 !",
        IGUI_BesoinIntime_NoDesire = "Pas maintenant, c'est trop t\244t depuis la derni\232re fois.",
        IGUI_BesoinIntime_InVehicle = "Pas dans un v\233hicule.",
        IGUI_BesoinIntime_VehicleMoving = "Arr\234tez d'abord le v\233hicule.",
        IGUI_BesoinIntime_NoBedOrSeat = "Il faut un lit, un canap\233, un fauteuil ou un v\233hicule \224 l'arr\234t.",
        IGUI_BesoinIntime_NotIndoors = "Il faut \234tre \224 l'int\233rieur.",
        IGUI_BesoinIntime_NoBed = "Il faut un lit, un canap\233 ou un fauteuil \224 proximit\233.",
        IGUI_BesoinIntime_TooTired = "Trop \233puis\233(e).",
        IGUI_BesoinIntime_TooHungry = "Trop affam\233(e) ou assoiff\233(e).",
        IGUI_BesoinIntime_ZombiesNear = "Des zombies sont trop proches.",
        IGUI_BesoinIntime_NoPrivacy = "Quelqu'un d'autre est \224 proximit\233.",
        IGUI_BesoinIntime_ProposalSent = "Proposition envoy\233e...",
        IGUI_BesoinIntime_ProposalReceived = "%1 vous propose un moment intime. Accepter ?",
        IGUI_BesoinIntime_Declined = "Proposition refus\233e.",
        IGUI_BesoinIntime_MoodleCalm = "Apais\233(e). Le besoin ne remonte pas pendant un moment, et le sommeil est plus r\233parateur.",
        IGUI_BesoinIntime_MoodleDesc2 = "En manque. Un lit ou un canap\233, \224 l'int\233rieur, ferait du bien.",
        IGUI_BesoinIntime_MoodleDesc3 = "Frustr\233(e). Le stress s'accumule. Trouvez un peu d'intimit\233.",
        IGUI_BesoinIntime_MoodleDesc4 = "Tr\232s frustr\233(e). Le stress et la tristesse continuent de monter.",
    },
}

local function currentLang()
    local ok, name = pcall(function()
        if Translator and Translator.getLanguage then
            local l = Translator.getLanguage()
            if l and l.name then return tostring(l:name()) end
        end
        return nil
    end)
    if ok and name and name:upper():sub(1, 2) == "FR" then return "FR" end
    return "EN"
end

-- Texte traduit, avec secours integre si le fichier Translate est absent.
function BI.T(key, ...)
    local args = { ... }
    local ok, txt = pcall(function() return getText(key, unpack(args)) end)
    if ok and txt and txt ~= key and txt ~= "" then return txt end
    local tbl = BI.TEXTS[currentLang()] or BI.TEXTS.EN
    local s = tbl[key] or BI.TEXTS.EN[key] or key
    s = s:gsub("%%%%", "%%")
    for i, v in ipairs(args) do
        s = s:gsub("%%" .. i, tostring(v))
    end
    return s
end

-- ---------------------------------------------------------------------------
-- Jauge
-- ---------------------------------------------------------------------------
function BI.getNeed(player)
    return player:getModData()[BI.KEY] or 0
end

function BI.setNeed(player, value)
    player:getModData()[BI.KEY] = clamp(value, 0, 100)
end

-- Paliers : 0 comble, 1 serein, 2 en manque, 3 frustre, 4 tres frustre
function BI.getStage(need)
    if need < 15 then return 0 end
    if need < 40 then return 1 end
    if need < 65 then return 2 end
    if need < 85 then return 3 end
    return 4
end

function BI.getStageName(player)
    return BI.T("IGUI_BesoinIntime_Stage" .. BI.getStage(BI.getNeed(player)))
end

local function worldHours()
    local gt = GameTime.getInstance()
    return gt and gt:getWorldAgeHours() or 0
end

function BI.isCalm(player)
    local until_ = player:getModData()[BI.KEY_CALM]
    return until_ ~= nil and worldHours() < until_
end

-- ---------------------------------------------------------------------------
-- Tick toutes les 10 minutes de jeu : montee + effets negatifs
-- ---------------------------------------------------------------------------
function BI.tickPlayer(player)
    if not player or player:isDead() then return end
    if BI.isCalm(player) then
        -- Bonus de sommeil : si l'on dort pendant la periode de serenite, la fatigue tombe plus vite
        local ok = pcall(function()
            if player:isAsleep() then
                local st = player:getStats()
                st:setFatigue(clamp(st:getFatigue() - BI.opt("SleepBonus", 0.01), 0, 1))
            end
        end)
        return
    end

    local hours = BI.opt("HoursToFull", 72)
    local need = BI.getNeed(player) + 100 / (hours * 6)
    BI.setNeed(player, need)

    if need > 50 then
        local ratio = (need - 50) / 50
        local stats = player:getStats()
        stats:setStress(clamp(stats:getStress() + BI.opt("StressPerTick", 0.005) * ratio, 0, 1))
        if need > 75 then
            local bd = player:getBodyDamage()
            bd:setUnhappynessLevel(clamp(bd:getUnhappynessLevel() + 0.25 * ratio, 0, 100))
        end
    end
end

-- ---------------------------------------------------------------------------
-- Lit / canape
-- ---------------------------------------------------------------------------
local function hasMethod(o, name)
    return o ~= nil and o[name] ~= nil
end

local function propsAreBed(props)
    if not props then return false end
    if hasMethod(props, "Is") then
        local ok, r = pcall(function() return props:Is("bed") end)
        if ok and r == true then return true end
        if IsoFlagType and IsoFlagType.bed then
            ok, r = pcall(function() return props:Is(IsoFlagType.bed) end)
            if ok and r == true then return true end
        end
    end
    return false
end

local function objectIsBed(obj)
    if not obj then return false end
    -- 1) API directe si elle existe
    if hasMethod(obj, "isBed") then
        local ok, r = pcall(function() return obj:isBed() end)
        if ok and r == true then return true end
    end
    -- 2) nom de la tuile (fiable en Build 42)
    if hasMethod(obj, "getSprite") then
        local sprite = obj:getSprite()
        if sprite and hasMethod(sprite, "getName") then
            local n = string.lower(tostring(sprite:getName() or ""))
            if n:find("bedding") or n:find("_bed") or n:find("bunk") or n:find("couch") or n:find("sofa")
                or n:find("seating") or n:find("chair") or n:find("armchair") or n:find("stool") or n:find("bench") then
                return true
            end
        end
        -- 3) proprietes du sprite, seulement si la methode existe
        if sprite and hasMethod(sprite, "getProperties") then
            if propsAreBed(sprite:getProperties()) then return true end
        end
    end
    if hasMethod(obj, "getProperties") then
        if propsAreBed(obj:getProperties()) then return true end
    end
    return false
end
BI.objectIsBed = objectIsBed

-- Qualite du lit : "goodBed", "averageBed", "badBed" (defaut averageBed)
function BI.bedQuality(bed)
    local ok, q = pcall(function()
        local sprite = bed:getSprite()
        if sprite and sprite:getProperties() and sprite:getProperties():Is("BedType") then
            return sprite:getProperties():Val("BedType")
        end
        return nil
    end)
    if ok and q then return q end
    return "averageBed"
end

-- Cherche un lit parmi les objets cliques, sinon dans le 3x3 autour du joueur
function BI.findBed(player, worldobjects)
    if worldobjects then
        for _, obj in ipairs(worldobjects) do
            if objectIsBed(obj) then return obj end
        end
    end
    local sq = player:getSquare()
    if not sq then return nil end
    local cell = player:getCell()
    for dx = -1, 1 do
        for dy = -1, 1 do
            local s = cell:getGridSquare(sq:getX() + dx, sq:getY() + dy, sq:getZ())
            if s then
                local objs = s:getObjects()
                for i = 0, objs:size() - 1 do
                    local o = objs:get(i)
                    if objectIsBed(o) then return o end
                end
            end
        end
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- Verifications
-- ---------------------------------------------------------------------------
function BI.zombieNear(player)
    local radius = BI.opt("ZombieRadius", 10)
    local cell = player:getCell()
    if not cell then return false end
    local list = cell:getZombieList()
    for i = 0, list:size() - 1 do
        local z = list:get(i)
        if z and not z:isDead() and z:DistTo(player) < radius then return true end
    end
    return false
end

function BI.playerNear(player, radius, exclude)
    if isClient() then
        local players = getOnlinePlayers()
        for i = 0, players:size() - 1 do
            local p = players:get(i)
            if p ~= player and p ~= exclude and p:DistTo(player) < radius then return true end
        end
    else
        for i = 0, getNumActivePlayers() - 1 do
            local p = getSpecificPlayer(i)
            if p and p ~= player and p ~= exclude and p:DistTo(player) < radius then return true end
        end
    end
    return false
end

-- Retourne ok, cleMessage, lit
function BI.canRelax(player, partner, worldobjects)
    -- Toujours possible, meme a 0 % (plaisir / anti-ennui), mais pas a repetition
    local last = player:getModData()[BI.KEY_LAST]
    if last and worldHours() < last + BI.opt("CooldownHours", 2) then
        return false, "IGUI_BesoinIntime_NoDesire"
    end
    local bed = nil
    local vehicle = player:getVehicle()
    if vehicle then
        -- En voiture : possible a l'arret (moteur allume ou non)
        local speed = 0
        if hasMethod(vehicle, "getCurrentSpeedKmHour") then speed = math.abs(vehicle:getCurrentSpeedKmHour() or 0) end
        if speed > 1 then
            return false, "IGUI_BesoinIntime_VehicleMoving"
        end
    else
        local sq = player:getSquare()
        if not sq or sq:isOutside() or not sq:getRoom() then
            return false, "IGUI_BesoinIntime_NotIndoors"
        end
        bed = BI.findBed(player, worldobjects)
        if not bed then
            return false, "IGUI_BesoinIntime_NoBed"
        end
    end
    local stats = player:getStats()
    if hasMethod(stats, "getFatigue") and stats:getFatigue() > 0.85 then
        return false, "IGUI_BesoinIntime_TooTired"
    end
    -- Faim / soif : les accesseurs varient selon la version, on ne teste que ceux qui existent
    local hunger, thirst = 0, 0
    if hasMethod(stats, "getHunger") then hunger = stats:getHunger() or 0 end
    if hasMethod(stats, "getThirst") then
        thirst = stats:getThirst() or 0
    else
        local bd = player:getBodyDamage()
        if hasMethod(bd, "getThirst") then thirst = bd:getThirst() or 0 end
    end
    if hunger > 0.7 or thirst > 0.7 then
        return false, "IGUI_BesoinIntime_TooHungry"
    end
    if BI.opt("ZombieCheck", true) and BI.zombieNear(player) then
        return false, "IGUI_BesoinIntime_ZombiesNear"
    end
    if BI.opt("RequirePrivacy", true) and BI.playerNear(player, 8, partner) then
        return false, "IGUI_BesoinIntime_NoPrivacy"
    end
    return true, nil, bed
end

-- ---------------------------------------------------------------------------
-- Soulagement
-- ---------------------------------------------------------------------------
function BI.applyRelief(player, withPartner, bedQuality)
    if not player or player:isDead() then return end
    local mult = withPartner and BI.opt("PartnerBonus", 1.5) or 1.0
    if bedQuality == "goodBed" then mult = mult * 1.2
    elseif bedQuality == "badBed" then mult = mult * 0.8 end
    -- Effet reduit quand la jauge est basse (plaisir sans besoin) : de 40 % a 100 %
    local need = BI.getNeed(player)
    local pleasure = BI.opt("LowNeedEffect", 0.4)
    mult = mult * (pleasure + (1 - pleasure) * (need / 100))

    local stats = player:getStats()
    local bd = player:getBodyDamage()
    stats:setStress(clamp(stats:getStress() - BI.opt("StressRelief", 0.35) * mult, 0, 1))
    stats:setPanic(clamp(stats:getPanic() - 10 * mult, 0, 100))
    bd:setUnhappynessLevel(clamp(bd:getUnhappynessLevel() - BI.opt("UnhappyRelief", 12) * mult, 0, 100))
    bd:setBoredomLevel(clamp(bd:getBoredomLevel() - BI.opt("BoredomRelief", 20) * mult, 0, 100))
    stats:setFatigue(clamp(stats:getFatigue() + 0.05, 0, 1))
    BI.setNeed(player, 0)
    player:getModData()[BI.KEY_CALM] = worldHours() + BI.opt("CalmHours", 3)
    player:getModData()[BI.KEY_LAST] = worldHours()

    if player.setHaloNote then
        player:setHaloNote(BI.T("IGUI_BesoinIntime_Relieved"), 150, 255, 150, 400)
    end
end

-- Sons (client) : boucle pendant l'action, son final au soulagement
function BI.playSound(player, name)
    if not BI.opt("SoundEnabled", true) then return nil end
    local id = nil
    pcall(function()
        local em = player:getEmitter()
        if em then id = em:playSound(name) end
    end)
    return id
end

function BI.stopSound(player, id)
    if not id then return end
    pcall(function()
        local em = player:getEmitter()
        if em then em:stopSound(id) end
    end)
end
