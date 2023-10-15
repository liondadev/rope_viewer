-- Rope Manager
-- Written by @liondadev

-- This isn't perfect, I couldn't find a perfect way to detect when ropes were created without making a new rope tool
-- this just uses CanRope with a very bad hook name, should work fine for most purposes
-- if a rope is removed, this also doesn't clean it up.
--
-- this is mainly just a proof of concept.

if SERVER then
    util.AddNetworkString("RopeMan:SyncRopes") -- Sends clients the data about where ropes start and end

    -- {"Player Name", "Player SteamID64", Position}
    local ropes = {}
    local last = 0 -- used to only sync data when we need to, this is not a good way of doing this but whatever
    local lastSent = 0

    local function addRope(ply, pos)
        table.insert(ropes, {
            ply:Nick(), ply:SteamID64(), pos
        })
    end

    local function sendRopeData(ply)
        net.Start("RopeMan:SyncRopes")
            net.WriteTable(ropes)
        net.Send(ply)
    end

    hook.Add("CanTool", "zzzzzz:RopeMan", function(ply, tr, toolname, _, button)
        if not IsValid(ply) or toolname ~= "rope" then return end
        if not tr.Hit then return end
        if not tr.HitPos then return end

        print("Adding Rope")
        addRope(ply, tr.HitPos)
        last = last + 1 -- increment last
    end)

    timer.Create("RopeMan:SyncData", 5, 0, function()
        if lastSent == last then return end -- clients already have all the data they need

        sendRopeData(player.GetAll())
    end)
else
    local ropes = {}

    net.Receive("RopeMan:SyncRopes", function()
        local data = net.ReadTable()
        if data == nil then return end -- how?
        if not istable(data) then return end -- impossible but whatever...

        ropes = data
    end)

    local showConvar = CreateClientConVar("ropeman_enabled", "0", true, false)

    hook.Add("HUDPaint", "RopeMan:DrawRopePoses", function()
        if not showConvar:GetBool() then return end

        for _, d in ipairs(ropes) do
            local point = d[3]:ToScreen() -- i fucking hate one based indexing omfg
            local name = d[1]
            local sid = d[2]

            draw.SimpleText(name .. " - " .. sid, "DermaDefault", point.x, point.y, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end)
end
