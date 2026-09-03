-- ===========================================================================
-- Besoin Intime 2.2.1 — action, menu contextuel, panneau, multijoueur (client) — Build 42
-- ===========================================================================
require "BesoinIntime_Shared"
require "TimedActions/ISBaseTimedAction"
require "ISUI/ISPanel"
require "ISUI/ISModalDialog"

local BI = BesoinIntime

local function halo(player, key, r, g, b)
    if player and player.setHaloNote then
        player:setHaloNote(BI.T(key), r or 255, g or 200, b or 120, 300)
    end
end

-- ---------------------------------------------------------------------------
-- Action chronométrée (aucune animation, barre de progression standard)
-- ---------------------------------------------------------------------------
ISBesoinIntimeAction = ISBaseTimedAction:derive("ISBesoinIntimeAction")

function ISBesoinIntimeAction:isValid()
    return not self.character:isDead()
end

function ISBesoinIntimeAction:update()
    self.tick = (self.tick or 0) + 1
    if self.tick % 60 == 0 and BI.opt("ZombieCheck", true) and BI.zombieNear(self.character) then
        halo(self.character, "IGUI_BesoinIntime_Interrupted", 255, 120, 120)
        self:forceStop()
    end
end

local function setSitting(character, on)
    if not BI.opt("SitPose", true) then return end
    pcall(function()
        if character.setSitOnGround then character:setSitOnGround(on) end
    end)
end

function ISBesoinIntimeAction:start()
    setSitting(self.character, true)
    halo(self.character, "IGUI_BesoinIntime_Started", 220, 180, 255)
end

function ISBesoinIntimeAction:stop()
    setSitting(self.character, false)
    ISBaseTimedAction.stop(self)
end

function ISBesoinIntimeAction:perform()
    setSitting(self.character, false)
    BI.applyRelief(self.character, self.withPartner, self.bedQuality)
    ISBaseTimedAction.perform(self)
end

function ISBesoinIntimeAction:new(character, withPartner, bedQuality)
    local o = ISBaseTimedAction.new(self, character)
    o.withPartner = withPartner
    o.bedQuality = bedQuality
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = BI.opt("DurationSeconds", 20) * 50
    if withPartner then o.maxTime = o.maxTime * 1.5 end
    if character:isTimedActionInstant() then o.maxTime = 1 end
    return o
end

function BI.startAction(player, withPartner, bed)
    local quality = bed and BI.bedQuality(bed) or "averageBed"
    if bed and bed:getSquare() then
        -- Marcher jusque sur le lit (pose assise dessus), sinon à côté
        local ok = pcall(function()
            ISTimedActionQueue.add(ISWalkToTimedAction:new(player, bed:getSquare()))
        end)
        if not ok and luautils and luautils.walkAdj then
            luautils.walkAdj(player, bed:getSquare(), true)
        end
    end
    ISTimedActionQueue.add(ISBesoinIntimeAction:new(player, withPartner, quality))
end

-- ---------------------------------------------------------------------------
-- Panneau (jauge), déplaçable
-- ---------------------------------------------------------------------------
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
    local ok, err = pcall(self.renderInner, self)
    if not ok and not self.loggedErr then
        self.loggedErr = true
        print("[BesoinIntime] panel render error: " .. tostring(err))
    end
end

function BesoinIntimePanel:renderInner()
    local player = getPlayer()
    if not player then return end
    local need = BI.getNeed(player)
    local stage = BI.getStage(need)
    local label = BI.isCalm(player) and BI.T("IGUI_BesoinIntime_Calm") or BI.T("IGUI_BesoinIntime_Stage" .. stage)

    self:drawText(BI.T("IGUI_BesoinIntime_Title"), 8, 4, 1, 1, 1, 1, UIFont.Small)
    self:drawText(label, 8, 20, 0.9, 0.9, 0.9, 1, UIFont.Small)

    local bx, by, bw, bh = 8, 40, self.width - 16, 12
    self:drawRect(bx, by, bw, bh, 0.8, 0.15, 0.15, 0.15)
    local r, g, b = 0.4, 0.8, 0.4
    if stage == 2 then r, g, b = 0.9, 0.8, 0.3
    elseif stage == 3 then r, g, b = 0.95, 0.55, 0.2
    elseif stage == 4 then r, g, b = 0.9, 0.25, 0.25 end
    self:drawRect(bx, by, bw * (need / 100), bh, 0.9, r, g, b)
    self:drawRectBorder(bx, by, bw, bh, 1, 0.6, 0.6, 0.6)
    self:drawText(tostring(math.floor(need)) .. " %", bx + bw / 2 - 12, by - 1, 1, 1, 1, 1, UIFont.Small)
end

function BI.createPanel()
    if BI.panel then return end
    BI.panel = BesoinIntimePanel:new(getCore():getScreenWidth() - 230, 120, 210, 60)
    BI.panel:initialise()
    BI.panel:addToUIManager()
    local player = getPlayer()
    local visible = player and player:getModData()[BI.PANEL_KEY]
    if visible == nil then visible = BI.opt("PanelDefault", true) end
    BI.panel:setVisible(visible)
end

function BI.togglePanel()
    if not BI.panel then BI.createPanel() end
    local v = not BI.panel:isVisible()
    BI.panel:setVisible(v)
    local player = getPlayer()
    if player then player:getModData()[BI.PANEL_KEY] = v end
end

-- ---------------------------------------------------------------------------
-- Moodle intégré (icône dans la colonne de droite, déplaçable, info-bulle)
-- ---------------------------------------------------------------------------
BesoinIntimeMoodle = ISPanel:derive("BesoinIntimeMoodle")
BI.moodle = nil

function BesoinIntimeMoodle:new(x, y)
    local o = ISPanel:new(x, y, 32, 32)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    o.moveWithMouse = true
    o.textures = {
        calm = getTexture("media/ui/BesoinIntime_moodle_calm.png"),
        [2] = getTexture("media/ui/BesoinIntime_moodle_2.png"),
        [3] = getTexture("media/ui/BesoinIntime_moodle_3.png"),
        [4] = getTexture("media/ui/BesoinIntime_moodle_4.png"),
    }
    return o
end

function BesoinIntimeMoodle:currentKey(player)
    if BI.isCalm(player) then return "calm" end
    local need = BI.getNeed(player)
    if need < BI.opt("MoodleThreshold", 70) then return nil end
    local stage = BI.getStage(need)
    if stage < 2 then stage = 2 end
    return stage
end

function BesoinIntimeMoodle:render()
    local ok, err = pcall(self.renderInner, self)
    if not ok and not self.loggedErr then
        self.loggedErr = true
        print("[BesoinIntime] moodle render error: " .. tostring(err))
    end
end

function BesoinIntimeMoodle:renderInner()
    local player = getPlayer()
    if not player or not BI.opt("MoodleEnabled", true) then return end
    local key = self:currentKey(player)
    if not key then return end
    local tex = self.textures[key]
    if tex then self:drawTextureScaled(tex, 0, 0, 32, 32, 1, 1, 1, 1) end

    if self:isMouseOver() then
        local title = (key == "calm") and BI.T("IGUI_BesoinIntime_Calm") or BI.T("IGUI_BesoinIntime_Stage" .. key)
        local desc = (key == "calm") and BI.T("IGUI_BesoinIntime_MoodleCalm") or BI.T("IGUI_BesoinIntime_MoodleDesc" .. key)
        local w = math.max(getTextManager():MeasureStringX(UIFont.Small, desc), getTextManager():MeasureStringX(UIFont.Small, title)) + 16
        local h = 44
        local x = -w - 6
        self:drawRect(x, 0, w, h, 0.85, 0.05, 0.05, 0.05)
        self:drawRectBorder(x, 0, w, h, 0.9, 0.5, 0.5, 0.5)
        self:drawText(title, x + 8, 4, 1, 1, 1, 1, UIFont.Small)
        self:drawText(desc, x + 8, 22, 0.85, 0.85, 0.85, 1, UIFont.Small)
    end
end

function BesoinIntimeMoodle:onMouseUp(x, y)
    ISPanel.onMouseUp(self, x, y)
    local player = getPlayer()
    if player then
        player:getModData()[BI.MOODLE_POS_KEY] = { x = self:getX(), y = self:getY() }
    end
end

function BI.createMoodle()
    if BI.moodle then return end
    local sw = getCore():getScreenWidth()
    local x, y = sw - 42, 420
    -- Se placer juste sous la colonne de moodles vanilla si possible
    pcall(function()
        local ui = MoodlesUI.getInstance()
        if ui then
            x = ui:getX() + math.floor((ui:getWidth() - 32) / 2)
            y = ui:getY() + ui:getHeight() + 6
        end
    end)
    local player = getPlayer()
    local saved = player and player:getModData()[BI.MOODLE_POS_KEY]
    if saved and saved.x and saved.y then x, y = saved.x, saved.y end
    BI.moodle = BesoinIntimeMoodle:new(x, y)
    BI.moodle:initialise()
    BI.moodle:addToUIManager()
    BI.moodle:setVisible(true)
end

-- Raccourci (Options > Touches > Besoin intime)
if keyBinding then
    table.insert(keyBinding, { value = "[BesoinIntime]", key = nil })
    table.insert(keyBinding, { value = "Toggle BesoinIntime Panel", key = Keyboard.KEY_J })
end

local function toggleKey()
    local ok, k = pcall(function() return getCore():getKey("Toggle BesoinIntime Panel") end)
    if ok and k and k ~= 0 then return k end
    return Keyboard.KEY_J
end

Events.OnKeyPressed.Add(function(key)
    if key == toggleKey() then BI.togglePanel() end
end)

-- ---------------------------------------------------------------------------
-- Menu contextuel
-- ---------------------------------------------------------------------------
function BI.onRelax(player, bed)
    local ok, msg, foundBed = BI.canRelax(player, nil, nil)
    if not ok then halo(player, msg); return end
    BI.startAction(player, false, bed or foundBed)
end

function BI.onPropose(player, other)
    local ok, msg = BI.canRelax(player, other, nil)
    if not ok then halo(player, msg); return end
    sendClientCommand(player, BI.MODULE, "propose", { target = other:getOnlineID() })
    halo(player, "IGUI_BesoinIntime_ProposalSent", 220, 180, 255)
end

local function addTooltip(option, text)
    local ok, tip = pcall(function()
        if ISWorldObjectContextMenu and ISWorldObjectContextMenu.addToolTip then
            return ISWorldObjectContextMenu.addToolTip()
        end
        local t = ISToolTip:new()
        t:initialise()
        t:setVisible(false)
        return t
    end)
    if ok and tip then
        tip.description = text
        option.toolTip = tip
    end
end

local function fillContextMenu(playerNum, context, worldobjects, test)
    if test then return end
    local player = getSpecificPlayer(playerNum)
    if not player or player:isDead() then return end

    local square = nil
    for _, obj in ipairs(worldobjects) do
        if obj and obj:getSquare() then square = obj:getSquare(); break end
    end

    -- Le menu n'apparaît que sur un lit/canapé cliqué, à côté d'un lit,
    -- ou sur un autre joueur (multi).
    local bed = BI.findBed(player, worldobjects)
    local others = {}
    if isClient() and square then
        local movers = square:getMovingObjects()
        for i = 0, movers:size() - 1 do
            local o = movers:get(i)
            if instanceof(o, "IsoPlayer") and o ~= player and not o:isDead() then
                table.insert(others, o)
            end
        end
    end
    if not bed and #others == 0 then return end

    local root = context:addOption(BI.T("ContextMenu_BesoinIntime_TitleState",
        BI.getStageName(player), tostring(math.floor(BI.getNeed(player)))))
    local sub = ISContextMenu:getNew(context)
    context:addSubMenu(root, sub)

    if bed then
        local relax = sub:addOption(BI.T("ContextMenu_BesoinIntime_Relax"), player, BI.onRelax, bed)
        local ok, msg = BI.canRelax(player, nil, worldobjects)
        if not ok then
            relax.notAvailable = true
            addTooltip(relax, BI.T(msg))
        end
    end

    for _, o in ipairs(others) do
        local name = o:getUsername() or o:getDescriptor():getForename()
        local opt = sub:addOption(BI.T("ContextMenu_BesoinIntime_Propose", name), player, BI.onPropose, o)
        local ok, msg = BI.canRelax(player, o, nil)
        if not ok then
            opt.notAvailable = true
            addTooltip(opt, BI.T(msg))
        end
    end

    sub:addOption(BI.T("ContextMenu_BesoinIntime_TogglePanel"), nil, BI.togglePanel)
end
local function onFillWorldObjectContextMenu(playerNum, context, worldobjects, test)
    local ok, err = pcall(fillContextMenu, playerNum, context, worldobjects, test)
    if not ok then print("[BesoinIntime] context menu error: " .. tostring(err)) end
end
Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)

-- ---------------------------------------------------------------------------
-- Multijoueur : réception des propositions / réponses
-- ---------------------------------------------------------------------------
local function onServerCommand(module, command, args)
    if module ~= BI.MODULE or not args then return end
    local player = getPlayer()
    if not player then return end

    if command == "proposal" then
        local text = BI.T("IGUI_BesoinIntime_ProposalReceived", tostring(args.name))
        local w, h = 340, 130
        local modal = ISModalDialog:new(
            getCore():getScreenWidth() / 2 - w / 2, getCore():getScreenHeight() / 2 - h / 2,
            w, h, text, true, nil,
            function(_, button)
                local accepted = (button.internal == "YES")
                local bed = nil
                if accepted then
                    local ok, msg, foundBed = BI.canRelax(player, nil, nil)
                    if not ok then halo(player, msg); accepted = false end
                    bed = foundBed
                end
                sendClientCommand(player, BI.MODULE, "answer", { to = args.from, accepted = accepted })
                if accepted then BI.startAction(player, true, bed) end
            end)
        modal:initialise()
        modal:addToUIManager()

    elseif command == "answer" then
        if args.accepted then
            local _, _, bed = BI.canRelax(player, nil, nil)
            BI.startAction(player, true, bed)
        else
            halo(player, "IGUI_BesoinIntime_Declined")
        end
    end
end
Events.OnServerCommand.Add(onServerCommand)

-- ---------------------------------------------------------------------------
-- Tick 10 minutes de jeu + création du panneau
-- ---------------------------------------------------------------------------
Events.EveryTenMinutes.Add(function()
    for i = 0, getNumActivePlayers() - 1 do
        BI.tickPlayer(getSpecificPlayer(i))
    end
end)

Events.OnCreatePlayer.Add(function(playerNum)
    if playerNum == 0 then
        BI.createPanel()
        BI.createMoodle()
    end
end)
