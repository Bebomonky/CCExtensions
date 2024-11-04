local PANEL = {};

function PANEL:Create()
	self:SetControlID("COLLECTIONBOX");
	self:SetTitle("Title");
	self:SetSmallText(true);
	self:SetSize(100, 100);
end

function PANEL:SetTitle(str)
	self.title = str;
end

function PANEL:GetTitle()
	return self.title;
end

function PANEL:SetSmallText(isSmall)
	self.smallText = isSmall;
end

function PANEL:GetSmallText()
	return self.smallText;
end

function PANEL:NextUpdate()
	local world_pos = self:GetPos();

	if not self:GetHide() then
		PrimitiveMan:DrawTextPrimitive(self:GetScreen(), world_pos, tostring(self.title), self.smallText, 0);
	end
end

return PANEL;