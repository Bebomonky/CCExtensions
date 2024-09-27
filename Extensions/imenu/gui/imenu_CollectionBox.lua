local PANEL = {}

function PANEL:Initialize()
	self._controlType = "COLLECTIONBOX"
	self._children = {}
	self._name = ""
	self._title = "Title"
	self._color = 146
	self._outlineColor = 71
	self._outlineThickness = 2
	self._parent = nil
	self._visible = true
	self._screen = -1
	self._smallText = true
	self._drawAfterParent = true
	self._divided = false
	self._x = 0
	self._y = 0
	self._w = 80
	self._h = 50
end

function PANEL:SetTitle(str)
	self._title = str
end

function PANEL:GetTitle()
	return self._title
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

function PANEL:DividedFromMenu(bool)
	self._divided = bool
end

function PANEL:IsDivided()
	return self._divided
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

	local pos = Vector()
	pos.X = self._parent and (self._parent._x + self._x) or self._x
	pos.Y = self._parent and (self._parent._y + self._y) or self._y
	local size = Vector(self._w, self._h)
	local world_pos
	if self._divided == true then
		world_pos = pos
	else
		world_pos = pos + CameraMan:GetOffset(self._screen)
	end
	local text_pos = world_pos

	local thickness = self._outlineThickness
	if thickness ~= 0 then
		PrimitiveMan:DrawBoxFillPrimitive(self._screen,
		world_pos - Vector(thickness, thickness),
		world_pos + size + Vector(thickness, thickness),
		self._outlineColor)
	end

	PrimitiveMan:DrawBoxFillPrimitive(self._screen, world_pos, world_pos + size, self._color)
	PrimitiveMan:DrawTextPrimitive(self._screen, text_pos, self._title, self._smallText, 0)

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

return PANEL