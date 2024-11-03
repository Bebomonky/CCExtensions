local PANEL = {};

function PANEL:Create()
	self:SetControlID("LABEL");
	self:SetText("Label")
	self:SetSmallText(true);
	self:SetContentAlignment(0);
	self:SetSize(0, 0);
	self:Hide(true);
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

function PANEL:SetContentAlignment(num)
	self.textAlignment = num;
end

function PANEL:Update()
	if not self._visible then return end

	local textWidth = FrameMan:CalculateTextWidth(tostring(self.text), self.smallText);
	local textHeight = FrameMan:CalculateTextHeight(tostring(self.text), 0, self.smallText);

	if self.textAlignment == 1 then --bottom-left

		local h = self.smallText and textHeight - 3 or textHeight - 4;
		self:SetPos(0, self:GetHeight() - h);

	elseif self.textAlignment == 2 then --bottom-center

		local h = self.smallText and textHeight - 3 or textHeight - 4;
		local w = self.smallText and textWidth or textWidth;
		self:SetPos((self:GetWidth() * 0.5) - w * 0.5, self:GetHeight() - h);

	elseif self.textAlignment == 3 then --bottom-right

		local h = self.smallText and textHeight - 3 or textHeight - 4;
		self:SetPos(self:GetWidth() - (textWidth - 1), self:GetHeight() - h);

	elseif self.textAlignment == 4 then --middle-left

		local h = self.smallText and textHeight - 1 or textHeight;
		self:SetPos(0, (self:GetHeight() * 0.5) - h * 0.5);

	elseif self.textAlignment == 5 then --center

		self:SetPos((self:GetWidth() * 0.5) - textWidth * 0.5, (self:GetHeight() * 0.5) - textHeight * 0.5);

	elseif self.textAlignment == 6 then --middle-right

		local h = self.smallText and textHeight - 1 or textHeight;
		local w = self.smallText and textWidth - 1 or textWidth - 3;
		self:SetPos(self:GetWidth() - w, (self:GetHeight() * 0.5) - h * 0.5);

	elseif self.textAlignment == 7 then --top-left

		local h = self.smallText and - 2 or - 3;
		self:SetPos(0, h);

	elseif self.textAlignment == 8 then --top-center

		local h = self.smallText and -2 or -4;
		self:SetPos((self:GetWidth() * 0.5) - textWidth * 0.5, h);

	elseif self.textAlignment == 9 then --top-right

		local h = self.smallText and -2 or -4;
		self:SetPos(self:GetWidth() - (textWidth - 1), h);
	end

	local world_pos = self:GetPos();

	PrimitiveMan:DrawTextPrimitive(self:GetScreen(), world_pos, tostring(self.text), self.smallText, 0);
end

return PANEL;