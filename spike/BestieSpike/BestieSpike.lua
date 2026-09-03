local function Print(msg)
	print("|cff33ff99[BestieSpike]|r " .. tostring(msg))
end

local function DumpArgs(label, ...)
	local n = select("#", ...)
	Print(label .. " -- " .. n .. " args")
	for i = 1, n do
		print(("  [%d] %s"):format(i, tostring((select(i, ...)))))
	end
end

BestieSpikeDB = BestieSpikeDB or { log = {} }

local function LogEvent(kind, data)
	table.insert(BestieSpikeDB.log, { time = date("%H:%M:%S"), kind = kind, data = data })
end

local function HasModernFriendAPI()
	return C_BattleNet ~= nil and type(C_BattleNet.GetFriendAccountInfo) == "function"
end

local function GetNumBNetFriends()
	if type(BNGetNumFriends) == "function" then
		local ok, total = pcall(BNGetNumFriends)
		if ok then return total end
	end
	if C_BattleNet and type(C_BattleNet.GetNumFriends) == "function" then
		local ok, total = pcall(C_BattleNet.GetNumFriends)
		if ok then return total end
	end
	return nil
end

-- Normalizes across the modern (C_BattleNet) and legacy (BNGetFriendInfo) APIs so the rest
-- of the spike doesn't need to know which one the current client actually has.
local function GetFriendInfo(index)
	if HasModernFriendAPI() then
		local ok, info = pcall(C_BattleNet.GetFriendAccountInfo, index)
		if ok and info then
			local game = info.gameAccountInfo
			return {
				accountName = info.accountName or info.battleTag,
				isOnline = info.isOnline,
				bnetAccountID = info.bnetAccountID,
				characterName = game and game.characterName,
				realmName = game and game.realmName,
				factionName = game and game.factionName,
			}
		end
		return nil, info
	elseif type(BNGetFriendInfo) == "function" then
		local ok, battleTag, accountName, _, _, toonName, toonID, _, isOnline = pcall(BNGetFriendInfo, index)
		if ok then
			return {
				accountName = accountName or battleTag,
				isOnline = isOnline,
				bnetAccountID = toonID,
				characterName = toonName,
			}
		end
		return nil, battleTag
	end
	return nil, "no BNet friend-info API found (neither C_BattleNet.GetFriendAccountInfo nor BNGetFriendInfo exists)"
end

-- Unknown 1: resolve a BattleTag to a target usable with BNSendWhisper.
local function GetFriendInfoByTag(tag)
	local total = GetNumBNetFriends() or 0
	for i = 1, total do
		local info = GetFriendInfo(i)
		if info and info.accountName and info.accountName:lower() == tag:lower() then
			return info
		end
	end
	return nil
end

local function ListFriends()
	local total = GetNumBNetFriends()
	Print("GetNumBNetFriends() = " .. tostring(total))
	for i = 1, (total or 0) do
		local info, err = GetFriendInfo(i)
		if info then
			local characterBit = ""
			if info.characterName then
				characterBit = (" | char=%s realm=%s faction=%s"):format(
					tostring(info.characterName), tostring(info.realmName), tostring(info.factionName))
			end
			Print(("#%d %s online=%s bnetAccountID=%s%s"):format(
				i, tostring(info.accountName), tostring(info.isOnline), tostring(info.bnetAccountID), characterBit))
		else
			Print(("#%d -- failed to read friend info: %s"):format(i, tostring(err)))
		end
	end
end

-- Unknowns 2 + 4: send a whisper carrying an achievement link, mirroring guild-announcement phrasing.
local function SendTestAchievement(tag, achievementID)
	if not tag then
		Print("Usage: /bspike send <BattleTag> <achievementID>")
		return
	end
	local info = GetFriendInfoByTag(tag)
	if not info then
		Print("No BNet friend found matching '" .. tag .. "'. Run /bspike friends first.")
		return
	end
	if not info.isOnline then
		Print(tag .. " is not currently online -- sending anyway for the spike, but note this for the presence-check requirement.")
	end

	local achID = tonumber(achievementID)
	if not achID then
		Print("Usage: /bspike send <BattleTag> <achievementID>")
		return
	end
	local link = GetAchievementLink(achID)
	if not link then
		Print("GetAchievementLink(" .. achID .. ") returned nil -- bad achievement ID?")
		return
	end

	local message = ("%s earned %s"):format(UnitName("player"), link)
	Print("Payload length: " .. #message .. " chars")
	Print("Sending to bnetAccountID " .. tostring(info.bnetAccountID) .. ": " .. message)

	local ok, err = pcall(BNSendWhisper, info.bnetAccountID, message)
	if ok then
		Print("BNSendWhisper call completed without error.")
	else
		Print("BNSendWhisper errored: " .. tostring(err))
	end
	LogEvent("sent", { to = tag, achievementID = achID, message = message })
end

local watcher = CreateFrame("Frame")
watcher:RegisterEvent("PLAYER_LOGIN")
watcher:RegisterEvent("CHAT_MSG_BN_WHISPER")
watcher:RegisterEvent("ACHIEVEMENT_EARNED")
watcher:SetScript("OnEvent", function(_, event, ...)
	if event == "PLAYER_LOGIN" then
		Print("Loaded. Type /bspike for commands.")
		Print("Modern API (C_BattleNet.GetFriendAccountInfo): " .. tostring(HasModernFriendAPI()))
		Print("Legacy API (BNGetFriendInfo): " .. tostring(type(BNGetFriendInfo) == "function"))
	elseif event == "CHAT_MSG_BN_WHISPER" then
		-- Unknown 2: what actually arrives, in what order, and does the achievement link render?
		DumpArgs("CHAT_MSG_BN_WHISPER received", ...)
		local text = ...
		local achID = text and text:match("|Hachievement:(%d+)")
		if achID then
			Print("Detected achievement link in message, achievementID=" .. achID)
		end
		LogEvent("received", { args = { ... } })
	elseif event == "ACHIEVEMENT_EARNED" then
		local achievementID, alreadyEarned = ...
		Print(("You earned achievement %s (alreadyEarned=%s): %s"):format(
			tostring(achievementID), tostring(alreadyEarned), tostring(GetAchievementLink(achievementID))))
	end
end)

SLASH_BESTIESPIKE1 = "/bspike"
SlashCmdList.BESTIESPIKE = function(msg)
	local args = {}
	for word in msg:gmatch("%S+") do table.insert(args, word) end
	local cmd = table.remove(args, 1)

	if cmd == "friends" then
		ListFriends()
	elseif cmd == "online" then
		local tag = args[1]
		if not tag then
			Print("Usage: /bspike online <BattleTag>")
		else
			local info = GetFriendInfoByTag(tag)
			Print(info and (tag .. " isOnline=" .. tostring(info.isOnline)) or ("No BNet friend found matching '" .. tag .. "'."))
		end
	elseif cmd == "send" then
		SendTestAchievement(args[1], args[2])
	elseif cmd == "log" then
		Print(#BestieSpikeDB.log .. " logged events. Run /dump BestieSpikeDB.log to inspect.")
	elseif cmd == "clearlog" then
		BestieSpikeDB.log = {}
		Print("Log cleared.")
	else
		Print("Commands:")
		Print("  /bspike friends                          -- list BNet friends + presence info")
		Print("  /bspike online <BattleTag>               -- check one friend's online status")
		Print("  /bspike send <BattleTag> <achievementID> -- send a test achievement whisper")
		Print("  /bspike log / clearlog                   -- inspect or clear the received-event log")
	end
end
