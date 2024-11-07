local PANEL = {};

local controlState = {
	Controller.PRIMARY_ACTION, --0
	Controller.SECONDARY_ACTION, --1
	Controller.MOVE_RIGHT, --3
	Controller.MOVE_LEFT, --4
	Controller.MOVE_UP, --5
	Controller.MOVE_DOWN, --6
	Controller.BODY_JUMP, --9
	Controller.BODY_CROUCH, --10
	Controller.AIM_UP, --11
	Controller.AIM_DOWN, --12
	Controller.AIM_SHARP, --13
	Controller.WEAPON_RELOAD, --15
	Controller.WEAPON_CHANGE_NEXT, --20
	Controller.WEAPON_CHANGE_PREV, --21
	Controller.WEAPON_PICKUP, --22
	Controller.WEAPON_DROP, --23
	Controller.SCROLL_UP, --43
	Controller.SCROLL_DOWN, --44
	Controller.DEBUG_ONE, --45
};

local controlState_Pressed = {};

function PANEL:Create()
	self:SetControlID("BUTTON");
	self:SetText("Button");
	self:SetSmallText(true);
	self:SetSize(26, 26);
	self._textPos_x = 0;
	self._textPos_y = 0;
	self._clickable = true;
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

function PANEL:SetTextPos(x, y)
	self._textPos_x, self._textPos_y = x, y;
end

function PANEL:GetTextPos()
	return Vector(self._textPos_x, self._textPos_y);
end

function PANEL:SetClickable(canClick)
	self._clickable = canClick;
end

function PANEL:GetClickable()
	return self._clickable;
end

function PANEL:NextUpdate()
	local textWidth = FrameMan:CalculateTextWidth(tostring(self.text), self.smallText);
	local textHeight = FrameMan:CalculateTextHeight(tostring(self.text), 0, self.smallText);

	local world_pos = self:GetAbsolutePos();
	local text_pos = world_pos + Vector((self:GetWidth() * 0.5) - textWidth * 0.5, (self:GetHeight() * 0.5) - textHeight * 0.5);

	if not self:GetHide() then
		PrimitiveMan:DrawTextPrimitive(self:GetScreen(), self:GetTextPos() + text_pos, tostring(self.text), self.smallText, 0);
	end

	if self._clickable and self:IsHovered() and not self:GetHide() then
		for _, input in pairs(controlState) do
			if (self.OnPress) then
				if self._controller:IsState(input) then
					if not controlState_Pressed[input] then
						self.OnPress(input);
						controlState_Pressed[input] = true;
					end
				else
					controlState_Pressed[input] = false;
				end
			end

			if (self.OnHeld) then
				local isHeld = false;
				if self._controller:IsState(input) then
					isHeld = true;
				end

				if isHeld then
					self.OnHeld(input);
				end
			end
		end
	end
end

return PANEL;