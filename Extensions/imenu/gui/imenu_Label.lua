local PANEL = {}

function PANEL:Initialize()
    self._controlType = "LABEL"
	self._children = {}
	self._name = ""
	self._text = ""
    self._color = 146
	self._parent = nil
	self._visible = true
	self._screen = -1
	self._smallText = true
	self._drawAfterParent = true
	self._x = 0
	self._y = 0
	self._w = 80
	self._h = 50
end

function PANEL:SetText(str)
	self._text = str
end

function PANEL:GetText()
	return self._text
end

function PANEL:Update(entity)
	if not self._visible then return end
	if not table.IsEmpty(self._children) then
		for i, child in ipairs(self._children) do
			if child._drawAfterParent == false then
				child:Update(entity)
			end
		end
	end

	local pos = Vector()
	pos.X = self._parent and (self._parent._x + self._x) or self._x
	pos.Y = self._parent and (self._parent._y + self._y) or self._y
	local size = Vector(self._w, self._h)
	local world_pos = pos + CameraMan:GetOffset(self._screen)

    PrimitiveMan:DrawTextPrimitive(self._screen, world_pos, self._text, self._smallText, 0)

    if (self.Think) then
        self.Think(entity, self._screen)
    end

	if not table.IsEmpty(self._children) then
		for i, child in ipairs(self._children) do
			if child._drawAfterParent == true then
				child:Update(entity)
			end
		end
	end
end

return PANEL