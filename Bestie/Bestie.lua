local ADDON_NAME, Bestie = ...

local function Print(msg)
	print("|cff33ff99Bestie:|r " .. tostring(msg))
end
Bestie.Print = Print

local DB_DEFAULTS = {
	besties = {},
	blocked = {},
}

local function InitDB()
	BestieDB = BestieDB or {}
	for key, default in pairs(DB_DEFAULTS) do
		BestieDB[key] = BestieDB[key] or default
	end
	Bestie.db = BestieDB
end

-- Mirrors the spike's confirmed fallback: BNGetNumFriends is the one that actually returned a
-- count in testing, with C_BattleNet.GetNumFriends kept only as a speculative fallback.
local function GetNumBNetFriends()
	if type(BNGetNumFriends) == "function" then
		local ok, total = pcall(BNGetNumFriends)
		if ok and total then
			return total
		end
	end
	if C_BattleNet and type(C_BattleNet.GetNumFriends) == "function" then
		local ok, total = pcall(C_BattleNet.GetNumFriends)
		if ok and total then
			return total
		end
	end
	return 0
end

-- Battle.net friend lookups, current-Retail modern API only (see spike/README.md for the
-- accountName-vs-battleTag and nested-isOnline gotchas this already accounts for).
function Bestie.GetFriendByBattleTag(tag)
	local total = GetNumBNetFriends()
	for i = 1, total do
		local ok, info = pcall(C_BattleNet.GetFriendAccountInfo, i)
		if ok and info and info.battleTag and info.battleTag:lower() == tag:lower() then
			return info
		end
	end
	return nil
end

function Bestie.GetFriendByBnetAccountID(bnetAccountID)
	local total = GetNumBNetFriends()
	for i = 1, total do
		local ok, info = pcall(C_BattleNet.GetFriendAccountInfo, i)
		if ok and info and info.bnetAccountID == bnetAccountID then
			return info
		end
	end
	return nil
end

function Bestie.IsOnline(info)
	return info ~= nil and info.gameAccountInfo ~= nil and info.gameAccountInfo.isOnline == true
end

function Bestie.CurrentGuildName()
	local ok, name = pcall(GetGuildInfo, "player")
	if ok then
		return name
	end
	return nil
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(_, event, name)
	if event == "ADDON_LOADED" and name == ADDON_NAME then
		InitDB()
	elseif event == "PLAYER_LOGIN" then
		Bestie.ShowPendingIncomingPopups()
		Bestie.BroadcastGuildSync()
	end
end)
