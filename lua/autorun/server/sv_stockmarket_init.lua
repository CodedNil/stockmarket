hook.Add("PlayerSay", "playersaystockmarket", function(Player, Text)
	if Text == "!stockmarket" or Text == "/stockmarket" then
		Player:ConCommand("stockmarket")
		return ""
	end
end)
util.AddNetworkString("STOCKMARKETMONEY")
net.Receive("STOCKMARKETMONEY", function(len, ply)
	ply:addMoney(net.ReadDouble())
end)