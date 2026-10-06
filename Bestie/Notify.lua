local ADDON_NAME, Bestie = ...

local function SameGuild(guildA, guildB)
	if not guildA or not guildB then
		return false
	end
	return guildA:lower() == guildB:lower()
end

-- Same-guild detection (SPEC.md Open Design Decision): there's no API to query another player's
-- current guild directly, so each side tells the other its current guild name as part of the
-- relationship protocol -- on request/accept, and again whenever it changes. Best-effort only,
-- same as achievement delivery itself: if a bestie is offline when this fires, they simply learn
-- our guild the next time we're both online together (see SPEC.md's no-offline-queueing non-goal).
function Bestie.BroadcastGuildSync()
	local guildName = Bestie.CurrentGuildName() or ""
	for _, entry in pairs(Bestie.db.besties) do
		if entry.status == "Active" then
			local info = Bestie.GetFriendByBattleTag(entry.battleTag)
			if info and Bestie.IsOnline(info) then
				Bestie.SendProtocolMessage(info.bnetAccountID, "GUILDSYNC", guildName)
			end
		end
	end
end

local function NotifyBesties(achievementID)
	local link = GetAchievementLink(achievementID)
	if not link then
		return
	end
	local message = ("%s earned %s"):format(UnitName("player"), link)
	local myGuild = Bestie.CurrentGuildName()

	for _, entry in pairs(Bestie.db.besties) do
		if entry.status == "Active" and not entry.muted then
			local info = Bestie.GetFriendByBattleTag(entry.battleTag)
			if info and Bestie.IsOnline(info) and not SameGuild(entry.lastKnownGuild, myGuild) then
				pcall(BNSendWhisper, info.bnetAccountID, message)
			end
		end
	end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ACHIEVEMENT_EARNED")
eventFrame:RegisterEvent("PLAYER_GUILD_UPDATE")
eventFrame:SetScript("OnEvent", function(_, event, ...)
	if event == "ACHIEVEMENT_EARNED" then
		local achievementID, alreadyEarned = ...
		if not alreadyEarned then
			NotifyBesties(achievementID)
		end
	elseif event == "PLAYER_GUILD_UPDATE" then
		local unit = ...
		if unit == nil or unit == "player" then
			Bestie.BroadcastGuildSync()
		end
	end
end)
