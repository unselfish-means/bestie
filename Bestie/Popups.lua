local ADDON_NAME, Bestie = ...

StaticPopupDialogs["BESTIE_REQUEST"] = {
	text = "%s wants to be Besties.",
	button1 = ACCEPT,
	button2 = DECLINE,
	OnAccept = function(_, tag)
		Bestie.AcceptBestie(tag)
	end,
	OnCancel = function(_, tag)
		Bestie.DeclineBestie(tag)
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = false,
	preferredIndex = 3,
}

function Bestie.ShowIncomingRequestPopup(tag)
	StaticPopup_Show("BESTIE_REQUEST", tag, nil, tag)
end

-- Requests don't expire (SPEC.md), but a StaticPopup itself doesn't survive a /reload or relog if
-- it's dismissed without a choice -- re-show any still-unanswered incoming requests on login.
function Bestie.ShowPendingIncomingPopups()
	for _, entry in pairs(Bestie.db.besties) do
		if entry.status == "PendingIncoming" then
			Bestie.ShowIncomingRequestPopup(entry.battleTag)
		end
	end
end
