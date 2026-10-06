local ADDON_NAME, Bestie = ...

local function Handle(msg)
	local args = {}
	for word in msg:gmatch("%S+") do
		table.insert(args, word)
	end
	local cmd = table.remove(args, 1)
	local tag = args[1]

	if cmd == "add" and tag then
		Bestie.AddBestie(tag)
	elseif cmd == "remove" and tag then
		Bestie.RemoveBestie(tag)
	elseif cmd == "mute" and tag then
		Bestie.MuteBestie(tag, true)
	elseif cmd == "unmute" and tag then
		Bestie.MuteBestie(tag, false)
	elseif cmd == "block" and tag then
		Bestie.BlockTag(tag, true)
	elseif cmd == "unblock" and tag then
		Bestie.BlockTag(tag, false)
	elseif cmd == "list" then
		Bestie.ListBesties()
	else
		Bestie.Print("Commands:")
		Bestie.Print("  /bestie add Name#1234      - send a Bestie request")
		Bestie.Print("  /bestie remove Name#1234   - remove a Bestie")
		Bestie.Print("  /bestie mute Name#1234     - silence notifications from a Bestie")
		Bestie.Print("  /bestie unmute Name#1234   - restore notifications")
		Bestie.Print("  /bestie block Name#1234    - block future requests from a BattleTag")
		Bestie.Print("  /bestie unblock Name#1234  - allow requests again")
		Bestie.Print("  /bestie list               - show your Besties and their status")
	end
end

SLASH_BESTIE1 = "/bestie"
SlashCmdList.BESTIE = Handle
