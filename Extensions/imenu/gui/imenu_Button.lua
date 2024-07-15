local PANEL = {}

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
}
local controlState_Pressed = {}

function PANEL:Initialize()
	self._controlType = "BUTTON"
	self._children = {}
	self._name = ""
	self._text = ""
	self._textPos = Vector()
	self._textAlignment = 1
	self._color = 146
	self._outlineColor = 71
	self._outlineThickness = 2
	self._parent = nil
	self._visible = true
	self._screen = -1
	self._smallText = true
	self._drawAfterParent = true
	self._controller = -1
	self.x = 0
	self.y = 0
	self.w = 80
	self.h = 50
	self.Clickable = true
	self.IsHovered = false
end

function PANEL:SetText(str)
	self._text = str
end

function PANEL:GetText()
	return self._text
end

function PANEL:Color(index)
	self._color = index
end

function PANEL:OutlineColor(index)
	self._outlineColor = index
end

function PANEL:OutlineThickness(num)
	self._outlineThickness = num
end

function PANEL:TextPos(x, y)
	self._textPos.X, self._textPos.Y = x, y
end

function PANEL:SetContentAlignment(num)
	self._textAlignment = num
end

function PANEL:Update(entity, ...)
	if not self._visible then return end

	if not table.IsEmpty(self._children) then
		for i, child in ipairs(self._children) do
			if child._drawAfterParent == false then
				child:Update(entity, ...)
			end
		end
	end

	local args = ...
	local cursor_pos = Vector()
	if args.Cursor then
		cursor_pos = args.Cursor
	end

	local pos = Vector()
	pos.X = self._parent and (self._parent._x + self._x) or self._x
	pos.Y = self._parent and (self._parent._y + self._y) or self._y
	local size = Vector(self._w, self._h)
	local world_pos = pos + CameraMan:GetOffset(self._screen)
	local text_pos = world_pos

	self.IsHovered = false

	if cursor_inside(cursor_pos, world_pos, size) then
		self.IsHovered = true
	end

	if self.Clickable and self.IsHovered then
		for _, input in pairs(controlState) do
			if (self.OnPress) then
				if self._controller:IsState(input) then
					if not controlState_Pressed[input] then
						self.OnPress(input)
						controlState_Pressed[input] = true
					end
				else
					controlState_Pressed[input] = false
				end
			end

			if (self.OnHeld) then
				local isHeld = false
				if self._controller:IsState(input) then
					isHeld = true
				end

				if isHeld then
					self.OnHeld(input)
				end
			end
		end
	end

	--Center
	if self._textAlignment == 1 then text_pos = text_pos + size / 2 + Vector(0, -5) end

	local thickness = self._outlineThickness
	if thickness ~= 0 then
		PrimitiveMan:DrawBoxFillPrimitive(self._screen,
		world_pos - Vector(thickness, thickness),
		world_pos + size + Vector(thickness, thickness),
		self._outlineColor)
	end

	PrimitiveMan:DrawBoxFillPrimitive(self._screen, world_pos, world_pos + size, self._color)
	PrimitiveMan:DrawTextPrimitive(self._screen, self._textPos + text_pos, self._text, self._smallText, self._textAlignment or 0)

	if (self.Think) then
		self.Think(entity, self._screen)
	end

	if not table.IsEmpty(self._children) then
		for i, child in ipairs(self._children) do
			if child._drawAfterParent == true then
				child:Update(entity, ...)
			end
		end
	end
end

function cursor_inside(cursor_pos, el_pos, size)
	local el_x = el_pos.X
	local el_y = el_pos.Y

	local el_width = size.X
	local el_height = size.Y

	local mouse_x = cursor_pos.X
	local mouse_y = cursor_pos.Y

	return (mouse_x > el_x) and (mouse_x < el_x + el_width) and (mouse_y > el_y) and (mouse_y < el_y + el_height)
end

return PANEL