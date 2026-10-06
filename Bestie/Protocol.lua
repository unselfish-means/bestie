local ADDON_NAME, Bestie = ...

-- Internal handshake/guild-sync traffic rides on the same BNSendWhisper channel as achievement
-- notifications, marked with a prefix no human would type. Messages carrying this prefix are
-- suppressed from chat and dispatched to a handler instead; anything else (achievement whispers,
-- plain human messages) passes through untouched, so the "no receive-side interception" rule for
-- notifications in SPEC.md still holds -- it only applies to this internal protocol traffic.
local PROTOCOL_MARK = "\1Bestie1\1"
local FIELD_SEP = "\2"

local handlers = {}

function Bestie.RegisterProtocolHandler(command, fn)
	handlers[command] = fn
end

local function Encode(command, ...)
	local fields = { command }
	for i = 1, select("#", ...) do
		fields[#fields + 1] = tostring((select(i, ...)))
	end
	return PROTOCOL_MARK .. table.concat(fields, FIELD_SEP)
end

local function Split(text, sep)
	local parts = {}
	for part in (text .. sep):gmatch("(.-)" .. sep) do
		parts[#parts + 1] = part
	end
	return parts
end

local function Decode(text)
	if text:sub(1, #PROTOCOL_MARK) ~= PROTOCOL_MARK then
		return nil
	end
	local parts = Split(text:sub(#PROTOCOL_MARK + 1), FIELD_SEP)
	local command = table.remove(parts, 1)
	return command, parts
end

function Bestie.SendProtocolMessage(bnetAccountID, command, ...)
	pcall(BNSendWhisper, bnetAccountID, Encode(command, ...))
end

-- CHAT_MSG_BN_WHISPER payload: text, playerName, languageName, channelName, playerName2,
-- specialFlags, zoneChannelID, channelIndex, channelBaseName, unused, lineID, guid, bnSenderID,
-- isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons. Using select() rather than
-- positional underscore params to avoid an off-by-one on bnSenderID's index.
local function OnBnWhisper(_, _, ...)
	local text = ...
	local bnSenderID = select(13, ...)
	local command, args = Decode(text)
	if not command then
		return false
	end
	local senderInfo = Bestie.GetFriendByBnetAccountID(bnSenderID)
	local handler = handlers[command]
	if handler and senderInfo then
		handler(senderInfo, unpack(args))
	end
	return true
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_WHISPER", OnBnWhisper)
