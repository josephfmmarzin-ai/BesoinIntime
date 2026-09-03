-- ===========================================================================
-- Besoin Intime — logique partagée (client + serveur) — Build 42
-- ===========================================================================
BesoinIntime = BesoinIntime or {}
local BI = BesoinIntime

BI.VERSION   = "2.1.0"
BI.MODULE    = "BesoinIntime"
BI.KEY       = "BesoinIntime_Need"        -- jauge 0..100
BI.KEY_CALM  = "BesoinIntime_CalmUntil"   -- heures-monde jusqu'à la fin de la sérénité
BI.PANEL_KEY = "BesoinIntime_PanelVisible"
BI.KEY_LAST  = "BesoinIntime_LastRelief"   -- heures-monde du dernier moment

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
-- Textes de secours FR / EN (utilisés si les fichiers Translate ne sont pas chargés)
-- ---------------------------------------------------------------------------
BI.TEXTS = {
    EN = {
        ContextMenu_BesoinIntime_Title = "Intimate need",
        ContextMenu_BesoinIntime_State = "State: %1 (%2 %%)",
        ContextMenu_BesoinIntime_TitleState = "Intimate need — %1 (%2 %%)",
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
        IGUI_BesoinIntime_NotIndoors = "Needs to be indoors.",
        IGUI_BesoinIntime_NoBed = "Needs a bed or a couch nearby.",
        IGUI_BesoinIntime_TooTired = "Too exhausted.",
        IGUI_BesoinIntime_TooHungry = "Too hungry or thirsty.",
        IGUI_BesoinIntime_ZombiesNear = "Zombies are too close.",
        IGUI_BesoinIntime_NoPrivacy = "Someone else is nearby.",
        IGUI_BesoinIntime_ProposalSent = "Proposal sent...",
        IGUI_BesoinIntime_ProposalReceived = "%1 proposes an intimate moment. Accept?",
        IGUI_BesoinIntime_Declined = "Proposal declined.",
    },
    FR = {
        ContextMenu_BesoinIntime_Title = "Besoin intime",
        ContextMenu_BesoinIntime_State = "État : %1 (%2 %%)",
        ContextMenu_BesoinIntime_TitleState = "Besoin intime — %1 (%2 %%)",
        ContextMenu_BesoinIntime_Relax = "Prendre un moment pour soi",
        ContextMenu_BesoinIntime_Propose = "Proposer un moment intime à %1",
        ContextMenu_BesoinIntime_TogglePanel = "Afficher / masquer la jauge",
        IGUI_BesoinIntime_Title = "Besoin intime",
        IGUI_BesoinIntime_Stage0 = "Comblé(e)",
        IGUI_BesoinIntime_Stage1 = "Serein(e)",
        IGUI_BesoinIntime_Stage2 = "En manque",
        IGUI_BesoinIntime_Stage3 = "Frustré(e)",
        IGUI_BesoinIntime_Stage4 = "Très frustré(e)",
        IGUI_BesoinIntime_Calm = "Apaisé(e)",
        IGUI_BesoinIntime_Started = "Se détend...",
        IGUI_BesoinIntime_Relieved = "Soulagé(e)",
        IGUI_BesoinIntime_Interrupted = "Zombies à proximité !",
        IGUI_BesoinIntime_NoDesire = "Pas maintenant, c'est trop tôt depuis la dernière fois.",
        IGUI_BesoinIntime_InVehicle = "Pas dans un véhicule.",
        IGUI_BesoinIntime_NotIndoors = "Il faut être à l'intérieur.",
        IGUI_BesoinIntime_NoBed = "Il faut un lit ou un canapé à proximité.",
        IGUI_BesoinIntime_TooTired = "Trop épuisé(e).",
        IGUI_BesoinIntime_TooHungry = "Trop affamé(e) ou assoiffé(e).",
        IGUI_BesoinIntime_ZombiesNear = "Des zombies sont trop proches.",
        IGUI_BesoinIntime_NoPrivacy = "Quelqu'un d'autre est à proximité.",
        IGUI_BesoinIntime_ProposalSent = "Proposition envoyée...",
        IGUI_BesoinIntime_ProposalReceived = "%1 vous propose un moment intime. Accepter ?",
        IGUI_BesoinIntime_Declined = "Proposition refusée.",
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

-- Texte traduit, avec secours intégré si le fichier Translate est absent.
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

-- Paliers : 0 comblé, 1 serein, 2 en manque, 3 frustré, 4 très frustré
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
-- Tick toutes les 10 minutes de jeu : montée + effets négatifs
-- ---------------------------------------------------------------------------
function BI.tickPlayer(player)
    if not player or player:isDead() then return end
    if BI.isCalm(player) then return end

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
-- Lit / canapé
-- ---------------------------------------------------------------------------
local function objectIsBed(obj)
    if not obj or not obj.getSprite then return false end
    local ok, res = pcall(function()
        local sprite = obj:getSprite()
        if sprite and sprite:getProperties() and sprite:getProperties():Is(IsoFlagType.bed) then
            return true
        end
        local props = obj:getProperties()
        return props ~= nil and props:Is(IsoFlagType.bed)
    end)
    if ok and res == true then return true end
    local ok2, byName = pcall(function()
        if obj.isBed and obj:isBed() then return true end
        local sprite = obj:getSprite()
        local n = sprite and sprite:getName() or ""
        n = string.lower(n)
        return n:find("bedding") ~= nil or n:find("_bed") ~= nil or n:find("couch") ~= nil
            or n:find("sofa") ~= nil or n:find("seating_indoor") ~= nil
    end)
    return ok2 and byName == true
end
BI.objectIsBed = objectIsBed

-- Qualité du lit : "goodBed", "averageBed", "badBed" (défaut averageBed)
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

-- Cherche un lit parmi les objets cliqués, sinon dans le 3x3 autour du joueur
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
-- Vérifications
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

-- Retourne ok, cléMessage, lit
function BI.canRelax(player, partner, worldobjects)
    -- Toujours possible, même à 0 % (plaisir / anti-ennui), mais pas à répétition
    local last = player:getModData()[BI.KEY_LAST]
    if last and worldHours() < last + BI.opt("CooldownHours", 2) then
        return false, "IGUI_BesoinIntime_NoDesire"
    end
    if player:getVehicle() then
        return false, "IGUI_BesoinIntime_InVehicle"
    end
    local sq = player:getSquare()
    if not sq or sq:isOutside() or not sq:getRoom() then
        return false, "IGUI_BesoinIntime_NotIndoors"
    end
    local bed = BI.findBed(player, worldobjects)
    if not bed then
        return false, "IGUI_BesoinIntime_NoBed"
    end
    local stats = player:getStats()
    if stats:getFatigue() > 0.85 then
        return false, "IGUI_BesoinIntime_TooTired"
    end
    if stats:getHunger() > 0.7 or stats:getThirst() > 0.7 then
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
    -- Effet réduit quand la jauge est basse (plaisir sans besoin) : de 40 % à 100 %
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
