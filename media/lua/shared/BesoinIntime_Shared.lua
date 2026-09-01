-- BesoinIntime : logique partagee (client + serveur)
BesoinIntime = BesoinIntime or {}
local BI = BesoinIntime

BI.KEY = "BesoinIntime_Need"
BI.PANEL_KEY = "BesoinIntime_PanelVisible"
BI.MODULE = "BesoinIntime"

-- Lecture d'une option Sandbox avec valeur de secours
function BI.opt(name, default)
    local sv = SandboxVars and SandboxVars.BesoinIntime
    if sv and sv[name] ~= nil then return sv[name] end
    return default
end

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

function BI.getNeed(player)
    local md = player:getModData()
    return md[BI.KEY] or 0
end

function BI.setNeed(player, value)
    player:getModData()[BI.KEY] = clamp(value, 0, 100)
end

-- Paliers : 0 comble, 1 calme, 2 envie, 3 frustre, 4 tres frustre
function BI.getStage(need)
    if need < 15 then return 0 end
    if need < 40 then return 1 end
    if need < 65 then return 2 end
    if need < 85 then return 3 end
    return 4
end

function BI.getStageName(player)
    return getText("IGUI_BesoinIntime_Stage" .. BI.getStage(BI.getNeed(player)))
end

-- Montee du besoin et effets negatifs (appele toutes les 10 min de jeu)
function BI.tickPlayer(player)
    if not player or player:isDead() then return end
    local hours = BI.opt("HoursToFull", 48)
    local need = BI.getNeed(player) + 100 / (hours * 6)
    BI.setNeed(player, need)

    if need > 50 then
        local ratio = (need - 50) / 50
        local stats = player:getStats()
        local gain = BI.opt("StressPerTick", 0.006) * ratio
        stats:setStress(clamp(stats:getStress() + gain, 0, 1))
        if need > 75 then
            local bd = player:getBodyDamage()
            bd:setUnhappynessLevel(clamp(bd:getUnhappynessLevel() + 0.3 * ratio, 0, 100))
        end
    end
end

-- Soulagement : remise a zero + baisse stress / tristesse / ennui
function BI.applyRelief(player, withPartner)
    if not player or player:isDead() then return end
    local mult = withPartner and BI.opt("PartnerBonus", 1.5) or 1.0
    local stats = player:getStats()
    local bd = player:getBodyDamage()

    stats:setStress(clamp(stats:getStress() - BI.opt("StressRelief", 0.4) * mult, 0, 1))
    stats:setPanic(clamp(stats:getPanic() - 10 * mult, 0, 100))
    bd:setUnhappynessLevel(clamp(bd:getUnhappynessLevel() - BI.opt("UnhappyRelief", 15) * mult, 0, 100))
    bd:setBoredomLevel(clamp(bd:getBoredomLevel() - 10 * mult, 0, 100))
    stats:setFatigue(clamp(stats:getFatigue() + 0.04, 0, 1))
    BI.setNeed(player, 0)

    if player.setHaloNote then
        player:setHaloNote(getText("IGUI_BesoinIntime_Relieved"), 150, 255, 150, 400)
    end
end

-- Un zombie (vivant) est-il proche ?
function BI.zombieNear(player)
    local radius = BI.opt("ZombieRadius", 8)
    local cell = player:getCell()
    if not cell then return false end
    local list = cell:getZombieList()
    for i = 0, list:size() - 1 do
        local z = list:get(i)
        if z and not z:isDead() and z:DistTo(player) < radius then
            return true
        end
    end
    return false
end

-- Un autre joueur (hors partenaire) est-il proche ?
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

-- Peut-on lancer l'action ? Retourne ok, cleMessage
function BI.canRelax(player, partner)
    if BI.getNeed(player) < BI.opt("MinNeed", 20) then
        return false, "IGUI_BesoinIntime_NoDesire"
    end
    if player:getVehicle() then
        return false, "IGUI_BesoinIntime_InVehicle"
    end
    if BI.opt("ZombieCheck", true) and BI.zombieNear(player) then
        return false, "IGUI_BesoinIntime_ZombiesNear"
    end
    if BI.opt("RequirePrivacy", false) and BI.playerNear(player, 8, partner) then
        return false, "IGUI_BesoinIntime_NoPrivacy"
    end
    return true, nil
end
