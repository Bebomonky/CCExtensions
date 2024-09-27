local PANEL = {}
local min = 0
local max = 1
local completed = false

function PANEL:Initialize()
    self._controlType = "PROGRESSBAR"
	self._children = {}
	self._name = ""
	self._text = ""
    self._fgColor = 117
    self._bgColor = 146
	self._outlineColor = 71
    self._maxHeight = 10
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

    min = 0
    completed = false
end

function PANEL:SetText(str)
	self._text = str
end

function PANEL:GetText()
	return self._text
end

function PANEL:BGColor(index)
	self._fgColor = index
end

function PANEL:FGColor(index)
	self._bgColor = index
end

function PANEL:OutlineColor(index)
	self._outlineColor = index
end

function PANEL:OutlineThickness(num)
	self._outlineThickness = num
end

function PANEL:GetCompleted()
    return completed
end

function PANEL:SetFraction(value)
	min = value
end

function PANEL:GetFraction()
	return min
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
    local factor = math.min(min, max)
    local bottomRightPos = world_pos + size + Vector(0, 0.5)
    local bottomRightPos2 = world_pos + Vector(size.X * factor, size.Y)

	local thickness = self._outlineThickness
	if thickness ~= 0 then
		PrimitiveMan:DrawBoxFillPrimitive(self._screen,
		world_pos - Vector(thickness, thickness),
		world_pos + size + Vector(thickness, thickness),
		self._outlineColor)
	end

    PrimitiveMan:DrawBoxFillPrimitive(self._screen, world_pos, bottomRightPos, self._fgColor)
    if min ~= 0 then
        PrimitiveMan:DrawBoxFillPrimitive(self._screen, world_pos, bottomRightPos2, self._bgColor)
    end
    PrimitiveMan:DrawTextPrimitive(self._screen, text_pos, self._text, self._smallText, 0)

    if completed == false then
        if min >= max then
            completed = true
            if (self.OnComplete) then
                self.OnComplete(entity, self._screen)
                min = 0
                completed = false
            end
        end
    end

    if (self.Think) then
        self.Think(entity, self._screen)
    end
    if (self.OnProgress) then
        self.OnProgress(entity, self._screen)
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