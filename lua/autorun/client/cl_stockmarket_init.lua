surface.CreateFont("STOCK_FONT_LARGE", {
	font = "Roboto",
	size = 18,
	weight = 200,
	antialias = true
})

surface.CreateFont("STOCK_FONT_MEDIUM", {
	font = "Roboto",
	size = 14,
	weight = 200,
	antialias = true
})

local TotalProfit = 0

StockHistory = StockHistory or {}
StockData = StockData or {}
OwnedStocks = OwnedStocks or {}

local Graphs = {}
local UpdateButtons = {}
local TotalProfitLabel
local OwnedStocksLabel

local StockHistoryLength = STOCKMARKET.StockHistoryLength
local StockPriceMaxGap = STOCKMARKET.StockPriceMaxGap
local StockUpdateDelay = STOCKMARKET.StockUpdateDelay
local StockStartLower = STOCKMARKET.StockStartLower
local StockStartUpper = STOCKMARKET.StockStartUpper
local Stocks = STOCKMARKET.Stocks
if StockHistory[Stocks[1]] and STOCKMARKET.StockHistoryLength ~= #StockHistory[Stocks[1]] then
	StockHistory = {}
	StockData = {}
	OwnedStocks = {}
end

local function AddDataToStock(Stock, Data)
	local New = {}
	for i = 2, StockHistoryLength do
		New[i - 1] = StockHistory[Stock][i]
	end
	New[StockHistoryLength] = Data
	StockHistory[Stock] = New
end

local function StockFormula(Stock)
	local Price = StockHistory[Stock][StockHistoryLength]
	local Flow = StockData[Stock][1]
	local StartPrice = StockData[Stock][2]
	local Gap = math.abs(Price - StartPrice)/(StartPrice * StockPriceMaxGap)
	
	local NewFlow = math.max(math.min(Flow + (math.random() - 0.5) * 20, 8), -8) + ((Price > StartPrice) and -Gap * 3 or Gap * 3)
	StockData[Stock][1] = NewFlow
	local NewPrice = math.max(math.min(Price + NewFlow, StartPrice * (1 + StockPriceMaxGap)), StartPrice * (1 - StockPriceMaxGap))
	AddDataToStock(Stock, NewPrice)
end

for _, v in pairs(Stocks) do
	if not StockHistory[v] then
		local StartPrice = math.random(StockStartLower, StockStartUpper)
		StockHistory[v] = {}
		for i = 1, StockHistoryLength do
			StockHistory[v][i] = StartPrice
		end
		StockData[v] = {0, StartPrice}
		for i = 1, StockHistoryLength do
			StockFormula(v)
		end
	end
end

local function ProfitColor(Difference)
	local Strength = math.min(math.abs(Difference)/50, 1)
	return Difference == 0 and Color(230, 230, 230) or Difference < 0 and Color(200 + 55 * Strength, 160 - 60 * Strength, 160 - 60 * Strength) or Color(160 - 60 * Strength, 200 + 55 * Strength, 160 - 60 * Strength)
end

local MenuOpen

local LocalMoney = LocalPlayer():getDarkRPVar("money")

local function UpdateDisplay()
	local OwnedWorth = 0
	for _, v in pairs(Stocks) do
		if Graphs[v] and Graphs[v][1].SetGraphData then
			Graphs[v][1]:SetGraphData(StockHistory[v])
			local Price = math.Round(StockHistory[v][StockHistoryLength])
			local LastPrice = math.Round(StockHistory[v][StockHistoryLength - 3])
			local Difference = math.Round((Price - LastPrice)/Price, 3)
			Graphs[v][2]:SetText(v.."  $"..Price.."  "..(Difference < 0 and "-" or "").."%"..math.abs(Difference))
			Graphs[v][2].BackgroundColor = Difference < 0 and Color(200, 50, 50) or Color(50, 200, 50)
		end
	end
	for _, v in pairs(OwnedStocks) do
		OwnedWorth = OwnedWorth + StockHistory[v[1]][StockHistoryLength]
	end
	for i, v in pairs(UpdateButtons) do
		if not v[2] or not v[2]:IsValid() then
			UpdateButtons[i] = nil
			continue
		end
		if v[1] == "StockButton" then
			local Price = math.Round(StockHistory[v[3]][StockHistoryLength])
			local Difference = math.Round(Price - v[4])
			v[2]:SetText("Bought for $"..math.Round(v[4]).."  -  Sell for $"..math.abs(Difference)..(Difference < 0 and " loss" or " profit"))
			v[2].BackgroundColor = ProfitColor(Difference)
		elseif v[1] == "BuyButton" then
			local Price = math.Round(StockHistory[v[3]][StockHistoryLength])
			print(LocalMoney)
			v[2]:SetText("Buy stock  -  "..math.Round((Price/LocalMoney) * 100).."% of your money")
			v[2].BackgroundColor = LocalMoney >= Price and Color(255, 255, 255) or Color(255, 120, 120)
		elseif v[1] == "SellButton" then
			local Difference, Owned = 0, 0
			for _, s in pairs(OwnedStocks) do
				if s[1] == v[3] then
					Difference = Difference + math.Round(math.Round(StockHistory[s[1]][StockHistoryLength]) - s[2])
					Owned = Owned + 1
				end
			end
			v[2]:SetText("Sell all stocks $"..math.abs(Difference)..(Difference < 0 and " loss" or " profit"))
			v[2].BackgroundColor = ProfitColor(Difference)
			v[4].ProfitVisible = Owned > 0
			v[4].ProfitColor = ProfitColor(Difference)
		end
	end
	if TotalProfitLabel and TotalProfitLabel:IsValid() then
		TotalProfitLabel:SetText("Total "..(TotalProfit >= 0 and "profit" or "loss")..": $"..math.Round(TotalProfit))
	end
	if OwnedStocksLabel and OwnedStocksLabel:IsValid() then
		OwnedStocksLabel:SetText("Owned stocks worth: $"..math.Round(OwnedWorth))
	end
end

hook.Add("DarkRPVarChanged", "StockmarketUpdate", function(Plr, Var, Old, New)
	if Var == "money" and MenuOpen then
		LocalMoney = New
		UpdateDisplay()
	end
end)

timer.Create("StockHistoryUpdate", StockUpdateDelay, 0, function()
	for _, v in pairs(Stocks) do
		StockFormula(v)
		if Graphs[v] and Graphs[v][1].SetGraphData then
			Graphs[v][1]:SetGraphData(StockHistory[v])
		end
	end
	if MenuOpen then
		UpdateDisplay()
	end
end)

local function OpenMenu()
	if MenuOpen then
		return
	end
	local CanPass = STOCKMARKET.RequiredJobs == nil
	if not CanPass then
		if type(STOCKMARKET.RequiredJobs) == "table" then
			for _, v in pairs(STOCKMARKET.RequiredJobs) do
				if ply:Team() == _G[v] then
					CanPass = true
					break
				end
			end
		else
			if ply:Team() == _G[STOCKMARKET.RequiredJobs] then
				CanPass = true
			end
		end
	end
	if not CanPass then
		return
	end
	MenuOpen = true
	
	local Menu = vgui.Create("DFrame")
    Menu:SetSize(900, 600)
    Menu:SetTitle("Stock Market")
    Menu:Center()
    Menu:ShowCloseButton(true)
    Menu:MakePopup()
	Menu.lblTitle:SetFont("STOCK_FONT_LARGE")
	Menu.btnMaxim:SetVisible(false)
	Menu.btnMinim:SetVisible(false)
	Menu.btnClose.DoClick = function() Menu:Close() MenuOpen = false end
	Menu.btnClose.Paint = function(self, w, h)
		draw.RoundedBoxEx(8, 0, h * 0.1, w, h * 0.58, Color(220, 80, 80), false, true, true, false)
	end
	Menu.Paint = function(self, w, h)
		draw.RoundedBoxEx(8, 0, 0, w, 24, Color(32, 178, 170), false, true, false, false)
		draw.RoundedBoxEx(8, 0, 24, w, h - 24, Color(245, 245, 245), false, false, true, false)
	end
	
	local ColumnSheet = vgui.Create("DColumnSheet", Menu)
	ColumnSheet.Navigation:SetWidth(200)
	ColumnSheet:Dock(FILL)
	
	TotalProfitLabel = vgui.Create("DLabel", ColumnSheet.Navigation)
	TotalProfitLabel:Dock(TOP)
	TotalProfitLabel:SetFont("STOCK_FONT_LARGE")
	TotalProfitLabel:SetTextColor(Color(0, 0, 0))
	TotalProfitLabel:DockMargin(0, 1, 0, 0)
	
	OwnedStocksLabel = vgui.Create("DLabel", ColumnSheet.Navigation)
	OwnedStocksLabel:Dock(TOP)
	OwnedStocksLabel:SetFont("STOCK_FONT_LARGE")
	OwnedStocksLabel:SetTextColor(Color(0, 0, 0))
	OwnedStocksLabel:DockMargin(0, 1, 0, 0)
	
	for _, v in pairs(Stocks) do
		local Panel = vgui.Create("DPanel", ColumnSheet)
		Panel:Dock(FILL)
		Panel.Paint = function(self, w, h)
			surface.SetDrawColor(200, 200, 200)
			surface.DrawRect(0, 0, w, h)
		end
		
		local StockList = vgui.Create("DScrollPanel", Panel)
		StockList:Dock(FILL)
		StockList:DockMargin(10, 0, 10, 0)
		StockList.Paint = function(self, w, h)
			surface.SetDrawColor(Color(255, 255, 255))
			surface.DrawRect(0, 0, w, h)
		end
		
		local SBar = StockList:GetVBar()
		function SBar:Paint(w, h)
			surface.SetDrawColor(160, 160, 160)
			surface.DrawRect(0, 0, w, h)
		end
		function SBar.btnUp:Paint(w, h)
			surface.SetDrawColor(255, 255, 255)
			surface.DrawRect(2, 2, w - 4, h - 4)
		end
		function SBar.btnDown:Paint(w, h)
			surface.SetDrawColor(255, 255, 255)
			surface.DrawRect(2, 2, w - 4, h - 4)
		end
		function SBar.btnGrip:Paint(w, h)
			surface.SetDrawColor(255, 255, 255)
			surface.DrawRect(2, 0, w - 4, h)
		end
		
		local function DrawStockList()
			StockList:Clear()
			for i, s in pairs(OwnedStocks) do
				if s[1] == v then
					local NewButton = vgui.Create("DButton", StockList)
					NewButton:Dock(TOP)
					NewButton:DockMargin(5, 5, 5, 0)
					NewButton:SetFont("STOCK_FONT_LARGE")
					NewButton.BackgroundColor = Color(220, 220, 220)
					NewButton.Paint = function(self, w, h)
						surface.SetDrawColor(self.BackgroundColor)
						surface.DrawRect(0, 0, w, h)
					end
					NewButton.DoClick = function()
						net.Start("STOCKMARKETMONEY")
						net.WriteDouble(StockHistory[v][StockHistoryLength])
						net.SendToServer()
						TotalProfit = TotalProfit + StockHistory[v][StockHistoryLength] - s[2]
						OwnedStocks[i] = nil
						DrawStockList()
						UpdateDisplay()
					end
					StockList:AddItem(NewButton)
					table.insert(UpdateButtons, {"StockButton", NewButton, s[1], s[2]})
				end
			end
		end
		DrawStockList()
		
		local Graph = vgui.Create("DGraphFrame", Panel)
		Graph:Dock(BOTTOM)
		Graph:DockMargin(10, 10, 10, 10)
		Graph:SetHeight(480 * 0.6)
		Graph:SetGraphData(StockHistory[v])
		Graph:SetUpdateDelay(StockUpdateDelay)
		
		local ButtonPanel = vgui.Create("Panel", Panel)
		ButtonPanel:Dock(TOP)
		ButtonPanel:DockMargin(10, 10, 10, 10)
		ButtonPanel:SetHeight(40)
		
		ColumnSheet:AddSheet(v.."   $200  +0.05%", Panel)
		local Item = ColumnSheet.Items[#ColumnSheet.Items]
		Item.Button.BackgroundColor = Color(32, 178, 170)
		Item.Button.ProfitColor = Color(255, 255, 255)
		Item.Button.ProfitVisible = false
		Item.Button.Paint = function(self, w, h)
			surface.SetDrawColor(self.BackgroundColor)
			surface.DrawRect(0, 0, w, h)
			if ColumnSheet.ActiveButton == self then
				surface.SetDrawColor(Color(255, 235, 100))
			else
				surface.SetDrawColor(Color(255, 255, 255))
			end
			surface.DrawRect(2, 2, h - 4, h - 4)
			
			if self.ProfitVisible then
				surface.SetDrawColor(Color(255, 255, 255))
				surface.DrawRect(w - h + 3, 3, h - 6, h - 6)
				
				surface.SetDrawColor(self.ProfitColor)
				surface.DrawRect(w - h + 5, 5, h - 10, h - 10)
			end
		end
		Item.Button:SetFont("STOCK_FONT_MEDIUM")
		Item.Button:SetTextColor(Color(255, 255, 255))
		
		local BuyButton = vgui.Create("DButton", ButtonPanel)
		BuyButton:Dock(LEFT)
		BuyButton:DockMargin(0, 0, 5, 0)
		BuyButton:SetWide(650/2)
		BuyButton:SetFont("STOCK_FONT_LARGE")
		BuyButton.BackgroundColor = Color(255, 255, 255)
		BuyButton.Paint = function(self, w, h)
			surface.SetDrawColor(self.BackgroundColor)
			surface.DrawRect(0, 0, w, h)
		end
		BuyButton.DoClick = function()
			local Owned = 0
			for i, s in pairs(OwnedStocks) do
				if s[1] == v then
					Owned = Owned + 1
				end
			end
			if LocalPlayer():canAfford(StockHistory[v][StockHistoryLength]) and Owned < STOCKMARKET.MaxStocksOwned then
				net.Start("STOCKMARKETMONEY")
				net.WriteDouble(-StockHistory[v][StockHistoryLength])
				net.SendToServer()
				table.insert(OwnedStocks, {v, StockHistory[v][StockHistoryLength]})
				
				DrawStockList()
				UpdateDisplay()
			end
		end
		table.insert(UpdateButtons, {"BuyButton", BuyButton, v})
		
		local SellButton = vgui.Create("DButton", ButtonPanel)
		SellButton:Dock(FILL)
		SellButton:DockMargin(5, 0, 0, 0)
		SellButton:SetFont("STOCK_FONT_LARGE")
		SellButton.BackgroundColor = Color(255, 255, 255)
		SellButton.Paint = function(self, w, h)
			surface.SetDrawColor(self.BackgroundColor)
			surface.DrawRect(0, 0, w, h)
		end
		SellButton.DoClick = function()
			local Total, Owned, Worth = 0, 0, 0
			for i, s in pairs(OwnedStocks) do
				if s[1] == v then
					Total = Total + StockHistory[s[1]][StockHistoryLength]
					Owned = Owned + 1
					Worth = Worth + s[2]
					OwnedStocks[i] = nil
				end
			end
			if Owned > 0 then
				net.Start("STOCKMARKETMONEY")
				net.WriteDouble(Total)
				net.SendToServer()
				TotalProfit = TotalProfit + Total - Worth
				DrawStockList()
				UpdateDisplay()
			end
		end
		table.insert(UpdateButtons, {"SellButton", SellButton, v, Item.Button})
		
		Graphs[v] = {Graph, Item.Button}
	end
	
	UpdateDisplay()
end

concommand.Add("stockmarket", function()
	OpenMenu()
end)