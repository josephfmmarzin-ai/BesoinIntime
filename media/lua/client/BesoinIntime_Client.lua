-- BesoinIntime : action, menu contextuel, panneau et multijoueur (cote client)
require "BesoinIntime_Shared"
require "TimedActions/ISBaseTimedAction"
require "ISUI/ISPanel"
require "ISUI/ISModalDialog"

local BI = BesoinIntime

---------------------------------------------------------------------------
-- Action chronometree (aucune animation, juste une barre de progression)
---------------------------------------------------------------------------
ISBesoinIntimeAction = ISBaseTimedAction:derive("ISBesoinIntimeAction")

function ISBesoinIntimeAction:isValid()
    return not self.character:isDead()
end

function ISBesoinIntimeAction:update()
    self.tick = (self.tick or 0) + 1
    if self.tick % 60 == 0 and BI.opt("ZombieCheck", true) and BI.zombieNear(self.character) then
        if self.character.setHaloNote then
            self.character:setHaloNote(getText("IGUI_BesoinIntime_Interrupted"), 255, 120, 120, 300)
        end
        self:forceStop()
    end
end

function ISBesoinIntimeAction:start()
    if self.character.setHaloNote then
        self.character:setHaloNote(getText("IGUI_BesoinIntime_Started"), 220, 180, 255, 200)
    end
end

function ISBesoinIntimeAction:stop()
    ISBaseTimedAction.stop(self)
end

function ISBesoinIntimeAction:perform()
    BI.applyRelief(self.character, self.withPartner)
    ISBaseTimedAction.perform(self)
end

function ISBesoinIntimeAction:new(character, withPartner)
    local o = ISBaseTimedAction.new(self, character)
    o.withPartner = withPartner
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = BI.opt("DurationSeconds", 20) * 50
    if withPartner then o.maxTime = o.maxTime * 1.5 end
    if character:isTimedActionInstant() then o.maxTime = 1 end
    return o
end

function BI.startAction(player, withPartner)
    ISTimedActionQueue.add(ISBesoinIntimeAction:new(player, withPartner))
end

---------------------------------------------------------------------------
-- Panneau (jauge) deplacable
---------------------------------------------------------------------------
BesoinIntimePanel = ISPanel:derive("BesoinIntimePanel")
BI.panel = nil

function BesoinIntimePanel:new(x, y, w, h)
    local o = ISPanel:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.6 }
    o.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 1 }
    o.moveWithMouse = true
    return o
end

function BesoinIntimePanel:render()
    ISPanel.render(self)
    local player = getPlayer()
    if not player then return end
    local need = BI.getNeed(player)
    local stage = BI.getStage(need)

    self:drawText(getText("IGUI_BesoinIntime_Title"), 8, 4, 1, 1, 1, 1, UIFont.Small)
    self:drawText(getText("IGUI_BesoinIntime_Stage" .. stage), 8, 20, 0.9, 0.9, 0.9, 1, UIFont.Small)

    local bx, by, bw, bh = 8, 40, self.width - 16, 12
    self:drawRect(bx, by, bw, bh, 0.8, 0.15, 0.15, 0.15)
    local r, g, b = 0.4, 0.8, 0.4
    if stage == 2 then r, g, b = 0.9, 0.8, 0.3
    elseif stage == 3 then r, g, b = 0.95, 0.55, 0.2
    elseif stage == 4 then r, g, b = 0.9, 0.25, 0.25 end
    self:drawRect(bx, by, bw * (need / 100), bh, 0.9, r, g, b)
    self:drawRectBorder(bx, by, bw, bh, 1, 0.6, 0.6, 0.6)
    self:drawText(math.floor(need) .. " %", bx + bw / 2 - 12, by - 1, 1, 1, 1, 1, UIFont.Small)
end

function BI.createPanel()
    if BI.panel then return end
    local x = getCore():getScreenWidth() - 200
    local y = 120
    BI.panel = BesoinIntimePanel:new(x, y, 180, 60)
    BI.panel:initialise()
    BI.panel:addToUIManager()
    local player = getPlayer()
    local visible = player and player:getModData()[BI.PANEL_KEY]
    if visible == nil then visible = true end
    BI.panel:setVisible(visible)
end

function BI.togglePanel()
    if not BI.panel then BI.createPanel() end
    local v = not BI.panel:isVisible()
    BI.panel:setVisible(v)
    local player = getPlayer()
    if player then player:getModData()[BI.PANEL_KEY] = v end
end

---------------------------------------------------------------------------
-- Raccourci clavier (Options > Touches > Besoin intime)
---------------------------------------------------------------------------
table.insert(keyBinding, { value = "[BesoinIntime]", key = nil })
table.insert(keyBinding, { value = "Toggle BesoinIntime Panel", key = Keyboard.KEY_J })

local function onKeyPressed(key)
    if key == getCore():getKey("Toggle BesoinIntime Panel") then
        BI.togglePanel()
    end
end
Events.OnKeyPressed.Add(onKeyPressed)

---------------------------------------------------------------------------
-- Menu contextuel
---------------------------------------------------------------------------
local function showBlocked(player, msgKey)
    if player.setHaloNote then
        player:setHaloNote(getText(msgKey), 255, 200, 120, 300)
    end
end

function BI.onRelax(player)
    local ok, msg = BI.canRelax(player, nil)
    if not ok then showBlocked(player, msg); return end
    BI.startAction(player, false)
end

function BI.onPropose(player, other)
    local ok, msg = BI.canRelax(player, other)
    if not ok then showBlocked(player, msg); return end
    sendClientCommand(player, BI.MODULE, "propose", { target = other:getOnlineID() })
    if player.setHaloNote then
        player:setHaloNote(getText("IGUI_BesoinIntime_ProposalSent"), 220, 180, 255, 300)
    end
end

local function onFillWorldObjectContextMenu(playerNum, context, worldobjects, test)
    if test then return end
    local player = getSpecificPlayer(playerNum)
    if not player or player:isDead() then return end

    local square = nil
    for _, obj in ipairs(worldobjects) do
        if obj and obj:getSquare() then square = obj:getSquare(); break end
    end

    local root = context:addOption(getText("ContextMenu_BesoinIntime_Title"))
    local sub = ISContextMenu:getNew(context)
    context:addSubMenu(root, sub)

    -- Etat (non cliquable)
    local state = sub:addOption(getText("ContextMenu_BesoinIntime_State",
        BI.getStageName(player), tostring(math.floor(BI.getNeed(player)))))
    state.notAvailable = true

    -- Seul
    local relax = sub:addOption(getText("ContextMenu_BesoinIntime_Relax"), player, BI.onRelax)
    local ok, msg = BI.canRelax(player, nil)
    if not ok then
        relax.notAvailable = true
        local tip = ISWorldObjectContextMenu.addToolTip()
        tip.description = getText(msg)
        relax.toolTip = tip
    end

    -- Avec un autre joueur (multi uniquement)
    if isClient() and square then
        local movers = square:getMovingObjects()
        for i = 0, movers:size() - 1 do
            local o = movers:get(i)
            if instanceof(o, "IsoPlayer") and o ~= player and not o:isDead() then
                local name = o:getUsername() or o:getDescriptor():getForename()
                sub:addOption(getText("ContextMenu_BesoinIntime_Propose", name), player, BI.onPropose, o)
            end
        end
    end

    sub:addOption(getText("ContextMenu_BesoinIntime_TogglePanel"), nil, BI.togglePanel)
end
Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)

---------------------------------------------------------------------------
-- Multijoueur : reception des propositions / reponses
---------------------------------------------------------------------------
local function onServerCommand(module, command, args)
    if module ~= BI.MODULE then return end
    local player = getPlayer()
    if not player then return end

    if command == "proposal" then
        local text = getText("IGUI_BesoinIntime_ProposalReceived", args.name)
        local w, h = 320, 120
        local modal = ISModalDialog:new(
            getCore():getScreenWidth() / 2 - w / 2, getCore():getScreenHeight() / 2 - h / 2,
            w, h, text, true, nil,
            function(_, button)
                local accepted = (button.internal == "YES")
                if accepted then
                    local ok, msg = BI.canRelax(player, nil)
                    if not ok then showBlocked(player, msg); accepted = false end
                end
                sendClientCommand(player, BI.MODULE, "answer", { to = args.from, accepted = accepted })
                if accepted then BI.startAction(player, true) end
            end)
        modal:initialise()
        modal:addToUIManager()

    elseif command == "answer" then
        if args.accepted then
            BI.startAction(player, true)
        else
            showBlocked(player, "IGUI_BesoinIntime_Declined")
        end
    end
end
Events.OnServerCommand.Add(onServerCommand)

---------------------------------------------------------------------------
-- Tick toutes les 10 minutes de jeu
---------------------------------------------------------------------------
local function everyTenMinutes()
    for i = 0, getNumActivePlayers() - 1 do
        BI.tickPlayer(getSpecificPlayer(i))
    end
end
Events.EveryTenMinutes.Add(everyTenMinutes)

Events.OnCreatePlayer.Add(function(playerNum)
    if playerNum == 0 then BI.createPanel() end
end)
