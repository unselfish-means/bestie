local ADDON_NAME, Bestie = ...

local Print = Bestie.Print

local function NormKey(tag)
	return tag:lower()
end

local function GetEntry(tag)
	return Bestie.db.besties[NormKey(tag)]
end

local function SetEntry(tag, entry)
	entry.battleTag = tag
	Bestie.db.besties[NormKey(tag)] = entry
	return entry
end

local function IsBlocked(tag)
	return Bestie.db.blocked[NormKey(tag)] == true
end

local function GuildOrNil(guildName)
	if guildName and guildName ~= "" then
		return guildName
	end
	return nil
end

Bestie.RegisterProtocolHandler("REQUEST", function(senderInfo, guildName)
	local tag = senderInfo.battleTag
	if IsBlocked(tag) then
		return
	end
	local existing = GetEntry(tag)
	if existing and existing.status == "Active" then
		return
	end
	if existing and existing.status == "PendingOutgoing" then
		-- Simultaneous mutual request: both sides asked at once. Complete the handshake instead
		-- of clobbering our own outgoing request with an incoming one.
		existing.status = "Active"
		existing.muted = false
		existing.lastKnownGuild = GuildOrNil(guildName)
		Bestie.SendProtocolMessage(senderInfo.bnetAccountID, "ACCEPT", Bestie.CurrentGuildName() or "")
		Print("You and " .. tag .. " are now Besties!")
		return
	end
	SetEntry(tag, { status = "PendingIncoming", lastKnownGuild = GuildOrNil(guildName) })
	Bestie.ShowIncomingRequestPopup(tag)
end)

Bestie.RegisterProtocolHandler("ACCEPT", function(senderInfo, guildName)
	local tag = senderInfo.battleTag
	local entry = GetEntry(tag)
	if not entry or entry.status ~= "PendingOutgoing" then
		return
	end
	entry.status = "Active"
	entry.muted = false
	entry.lastKnownGuild = GuildOrNil(guildName)
	Print(tag .. " accepted your Bestie request. You're Besties!")
end)

Bestie.RegisterProtocolHandler("DECLINE", function(senderInfo)
	local tag = senderInfo.battleTag
	local entry = GetEntry(tag)
	if entry and entry.status == "PendingOutgoing" then
		entry.status = "Removed"
	end
	Print(tag .. " declined your Bestie request.")
end)

Bestie.RegisterProtocolHandler("REMOVE", function(senderInfo)
	local entry = GetEntry(senderInfo.battleTag)
	if entry then
		if entry.status == "PendingIncoming" then
			-- Otherwise a stale popup lingers on screen; clicking Accept/Decline on it would
			-- silently no-op since the entry is no longer PendingIncoming.
			StaticPopup_Hide("BESTIE_REQUEST", entry.battleTag)
		end
		entry.status = "Removed"
	end
end)

Bestie.RegisterProtocolHandler("GUILDSYNC", function(senderInfo, guildName)
	local entry = GetEntry(senderInfo.battleTag)
	if entry and entry.status == "Active" then
		entry.lastKnownGuild = GuildOrNil(guildName)
	end
end)

function Bestie.AddBestie(tag)
	if IsBlocked(tag) then
		Print(tag .. " is blocked. Unblock them first with /bestie unblock " .. tag .. ".")
		return
	end
	local existing = GetEntry(tag)
	if existing and existing.status == "Active" then
		Print(tag .. " is already your Bestie.")
		return
	end
	if existing and existing.status == "PendingOutgoing" then
		Print("Already waiting on a response from " .. tag .. ".")
		return
	end
	if existing and existing.status == "PendingIncoming" then
		Print(tag .. " already sent you a Bestie request -- respond to the popup instead.")
		Bestie.ShowIncomingRequestPopup(tag)
		return
	end
	local info = Bestie.GetFriendByBattleTag(tag)
	if not info then
		Print(tag .. " isn't on your Battle.net friends list.")
		return
	end
	if not Bestie.IsOnline(info) then
		Print(tag .. " isn't online right now. Try again when they're in-game.")
		return
	end
	SetEntry(tag, { status = "PendingOutgoing" })
	Bestie.SendProtocolMessage(info.bnetAccountID, "REQUEST", Bestie.CurrentGuildName() or "")
	Print("Bestie request sent to " .. tag .. ".")
end

function Bestie.AcceptBestie(tag)
	local entry = GetEntry(tag)
	if not entry or entry.status ~= "PendingIncoming" then
		return
	end
	entry.status = "Active"
	entry.muted = false
	local info = Bestie.GetFriendByBattleTag(tag)
	if info then
		Bestie.SendProtocolMessage(info.bnetAccountID, "ACCEPT", Bestie.CurrentGuildName() or "")
	end
	Print("You and " .. tag .. " are now Besties!")
end

function Bestie.DeclineBestie(tag)
	local entry = GetEntry(tag)
	if not entry or entry.status ~= "PendingIncoming" then
		return
	end
	entry.status = "Removed"
	local info = Bestie.GetFriendByBattleTag(tag)
	if info then
		Bestie.SendProtocolMessage(info.bnetAccountID, "DECLINE")
	end
	Print("Declined " .. tag .. "'s Bestie request.")
end

function Bestie.RemoveBestie(tag)
	local entry = GetEntry(tag)
	if not entry or entry.status == "Removed" then
		Print(tag .. " isn't on your Besties list.")
		return
	end
	entry.status = "Removed"
	local info = Bestie.GetFriendByBattleTag(tag)
	if info then
		Bestie.SendProtocolMessage(info.bnetAccountID, "REMOVE")
	end
	Print("Removed " .. tag .. " from your Besties.")
end

function Bestie.MuteBestie(tag, muted)
	local entry = GetEntry(tag)
	if not entry or entry.status ~= "Active" then
		Print(tag .. " isn't an active Bestie.")
		return
	end
	entry.muted = muted
	Print(tag .. (muted and " muted." or " unmuted."))
end

function Bestie.BlockTag(tag, blocked)
	Bestie.db.blocked[NormKey(tag)] = blocked or nil
	Print(tag .. (blocked and " blocked." or " unblocked."))
end

function Bestie.ListBesties()
	local any = false
	for _, entry in pairs(Bestie.db.besties) do
		if entry.status ~= "Removed" then
			any = true
			local bits = { entry.battleTag, entry.status }
			if entry.status == "Active" and entry.muted then
				bits[#bits + 1] = "muted"
			end
			Print(table.concat(bits, " - "))
		end
	end
	if not any then
		Print("No besties yet. Add one with /bestie add Name#1234.")
	end
end
