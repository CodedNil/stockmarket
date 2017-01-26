local PANEL = {}

function PANEL:Init()
	self:SetSize(100, 100)
	self:Center()
	
	self.GraphData = {0, 0}
	self.UpdateDelay = 10
end

local function DrawThickLine(x, y, e, r, t)
	for i = -0.5 * t, 0.5 * t do
		surface.DrawLine(x, y + i, e, r + i)
	end
	for i = -0.5 * t, 0.5 * t do
		surface.DrawLine(x + i, y, e + i, r)
	end
end

local function Lerp(a, b, t)
    return a * (1 - t) + (b * t)
end

local function DrawCircle(x, y, radius, seg)
	local cir = {}

	table.insert(cir, {x = x, y = y, u = 0.5, v = 0.5})
	for i = 0, seg do
		local a = math.rad((i / seg) * -360)
		table.insert(cir, {x = x + math.sin(a) * radius, y = y + math.cos(a) * radius, u = math.sin(a) / 2 + 0.5, v = math.cos(a) / 2 + 0.5})
	end

	local a = math.rad(0)
	table.insert(cir, {x = x + math.sin(a) * radius, y = y + math.cos(a) * radius, u = math.sin(a) / 2 + 0.5, v = math.cos(a) / 2 + 0.5})

	draw.NoTexture()
	surface.DrawPoly(cir)
end

local function FormatSeconds(Seconds)
	return math.abs(Seconds) >= 60 and (tostring(math.Round(Seconds/60, 1)).." minutes") or tostring(Seconds).." seconds"
end

function PANEL:Paint(w, h)
	surface.SetDrawColor(245, 245, 245)
	surface.DrawRect(0, 0, w, h)
	
	local Min, Max = 99999, 0
	for _, v in pairs(self.GraphData) do
		if v < Min then
			Min = v
		end
		if v > Max then
			Max = v
		end
	end
	
	surface.SetFont("STOCK_FONT_MEDIUM")
	surface.SetTextColor(180, 180, 180)
	
	surface.SetDrawColor(180, 180, 180)
	for i = 0.2, 0.8, 0.12 do
		local TrueI = math.Round(Min + (math.Round(1 - ((i - 0.2) * (1 / 0.6)), 2) * (Max - Min)))
		surface.DrawLine(0, i * h, 18, i * h)
		surface.SetTextPos(20, i * h - 7)
		surface.DrawText(TrueI)
		surface.DrawLine(20 + surface.GetTextSize(TrueI), i * h, w, i * h)
	end
	
	for i = 44, w - 26, (w - 26 - 44)/5 do
		surface.DrawLine(i, 0.8 * h, i, 0.83 * h)
		if i == w - 26 then
			surface.SetTextPos(i - 20, 0.84 * h)
			surface.DrawText("Current")
		else
			local TrueI = -(1 - math.Round((i - 44)/(w - 26 - 44), 2)) * (self.UpdateDelay * #self.GraphData)
			surface.SetTextPos(i - surface.GetTextSize(FormatSeconds(TrueI))/2, 0.84 * h)
			surface.DrawText(FormatSeconds(TrueI))
		end
	end
	
	local LastLength, LastHeight
	for i, v in pairs(self.GraphData) do
		local Height = (1 - (0.2 + 0.6 * ((v - Min)/(Max - Min)))) * h
		local Length = 44 + (w - 70) * ((i - 1)/(#self.GraphData - 1))
		if LastLength then
			if Height == LastHeight then
				surface.SetDrawColor(200, 200, 50)
			elseif Height < LastHeight then
				surface.SetDrawColor(50, 200, 50)
				Direction = 1
			else
				surface.SetDrawColor(200, 50, 50)
				Direction = -1
			end
			DrawThickLine(LastLength, LastHeight, Length, Height, 4)
		end
		LastLength, LastHeight = Length, Height
	end
	
	surface.SetDrawColor(110, 110, 110)
	surface.SetTextColor(220, 220, 220)
	local MX, MY = self:LocalCursorPos()
	if MX >= 44 and MY >= h * 0.2 and MX <= w - 26 and MY <= h * 0.8 then
		DrawThickLine(MX, h * 0.16, MX, h * 0.86, 2)
		
		local Percent = (MX - 44)/(w - 70)
		
		local Now, Next, NowPercent, NextPercent
		for i, v in pairs(self.GraphData) do
			local n = ((i - 1)/(#self.GraphData - 1))
			if Percent >= n then
				Now, Next, NowPercent, NextPercent = v, self.GraphData[i + 1], (i - 1)/(#self.GraphData - 1), i/(#self.GraphData - 1)
			end
		end
		if Next then
			local T = Lerp(Now, Next, (Percent - NowPercent)/(NextPercent - NowPercent))
			local Height = (1 - (0.2 + 0.6 * ((T - Min)/(Max - Min)))) * h
			DrawCircle(MX, Height, 6, 15)
			
			draw.RoundedBoxEx(8, MX - 70, h * 0.03, 140, h * 0.13, Color(110, 110, 110), false, true, true, false)
			
			surface.SetTextPos(MX - surface.GetTextSize("$"..math.Round(Now))/2, h * 0.04)
			surface.DrawText("$"..math.Round(Now))
			
			local Seconds = math.Round(-(1 - Percent) * (self.UpdateDelay * #self.GraphData))
			surface.SetTextPos(MX - surface.GetTextSize(FormatSeconds(Seconds))/2, h * 0.1)
			surface.DrawText(FormatSeconds(Seconds))
		end
	end
end

function PANEL:SetGraphData(Data)
	self.GraphData = Data
end

function PANEL:SetUpdateDelay(Delay)
	self.UpdateDelay = Delay
end

vgui.Register("DGraphFrame", PANEL, "Panel")