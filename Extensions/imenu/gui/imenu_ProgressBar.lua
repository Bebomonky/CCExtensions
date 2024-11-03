local PANEL = {};
local min = 0;
local max = 1;
local completed = false;

function PANEL:Create()
	self:SetControlID("PROGRESSBAR");
	self:SetText("");
	self:SetSmallText(true);
	self:Color(146);
	self:BGColor(117);
	self:OutlineColor(144);
	self:SetFraction(0);
	self:SetSize(100, 10);
	completed = false;
end

function PANEL:SetText(str)
	self.text = str;
end

function PANEL:GetText()
	return self.text;
end

function PANEL:SetSmallText(isSmall)
	self.smallText = isSmall;
end

function PANEL:GetSmallText()
	return self.smallText;
end

function PANEL:BGColor(index)
	self.bgColor = index;
end

function PANEL:GetCompleted()
	return completed;
end

function PANEL:SetFraction(value)
	min = value;
end

function PANEL:GetFraction()
	return min;
end

function PANEL:NextUpdate()
	local world_pos = self:GetPos();

	local factor = math.min(min, max);
	local size = self:GetSize();
	local barEnd = world_pos + Vector(size.X * factor, size.Y);

	if not self:Hide() then
		if min ~= 0 then
			PrimitiveMan:DrawBoxFillPrimitive(self:GetScreen(), world_pos, barEnd, self.bgColor);
		end

		PrimitiveMan:DrawTextPrimitive(self:GetScreen(), world_pos, self.text, self.smallText, 0);
	end

	if completed == false then
		if min >= max then
			completed = true;
			if (self.OnComplete) then
				self.OnComplete();
				min = 0;
				completed = false;
			end
		end

		if (self.OnProgress) then
			self.OnProgress();
		end
	end
end

return PANEL;