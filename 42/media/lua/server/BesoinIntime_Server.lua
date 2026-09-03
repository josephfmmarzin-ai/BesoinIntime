-- Besoin Intime - relais serveur des propositions entre joueurs (multijoueur)
require "BesoinIntime_Shared"
local BI = BesoinIntime

if isServer() then
    local function onClientCommand(module, command, player, args)
        if module ~= BI.MODULE or not args then return end

        if command == "propose" then
            local target = getPlayerByOnlineID(args.target)
            if target and not target:isDead() and target:DistTo(player) < 4 then
                sendServerCommand(target, BI.MODULE, "proposal",
                    { from = player:getOnlineID(), name = player:getUsername() })
            end

        elseif command == "answer" then
            local proposer = getPlayerByOnlineID(args.to)
            if proposer then
                sendServerCommand(proposer, BI.MODULE, "answer",
                    { accepted = args.accepted == true, name = player:getUsername() })
            end
        end
    end
    Events.OnClientCommand.Add(onClientCommand)
end
