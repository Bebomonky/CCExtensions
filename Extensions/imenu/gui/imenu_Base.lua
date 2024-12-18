local BASE = {};

function BASE:Create()
	self._owner = nil;
	self._children = {};
	self._name = "";
	self._parent = nil;
	self._visible = true;
	self._screen = -1;
	self._color = 146;
	self._outlineColor = 71;
	self._outlineThickness = 2;
	self._drawAfterParent = true;
	self._hide = false;
	self._x = 0;
	self._y = 0;
	self._w = 80;
	self._h = 50;
	self._cursor = Vector();
end

function BASE:SetOwner(entity)
	self._owner = entity;
end

function BASE:GetOwner()
	return self._owner;
end

function BASE:SetControlID(str)
	self._controlID = str;
end

function BASE:GetControlID(str)
	return self._controlID;
end

function BASE:SetName(str)
	self._name = str;
end

function BASE:GetName()
	return self._name;
end

function BASE:SetParent(parent)
	self:Remove();
	self._parent = parent;
	table.insert(self._parent._children, self);
end

function BASE:GetParent()
	return self._parent;
end

function BASE:SetVisible(bool)
	self._visible = bool;
end

function BASE:GetVisible()
	return self._visible;
end

function BASE:DrawAfterParent(bool)
	self._drawAfterParent = bool;
end

function BASE:SetPos(x, y)
	if self._parent then
		self._x, self._y = self._parent._x + x, self._parent._y + y;
	else
		self._x, self._y = x, y;
	end
end

function BASE:GetRelativePos()
	return Vector(self._x, self._y);
end

function BASE:GetAbsolutePos()
	return Vector(self._x, self._y) + CameraMan:GetOffset(self._screen);
end

function BASE:SetSize(w, h)
	self._w, self._h = w, h;
end

function BASE:GetSize()
	return Vector(self._w, self._h);
end

function BASE:GetWidth()
	return self._w;
end

function BASE:GetHeight()
	return self._h;
end

function BASE:GetChildren()
	return self._children;
end

function BASE:ClearChildren()
	self._children = {};
end

function BASE:GetScreen()
	return self._screen;
end

function BASE:SetScreen(screen)
	self._screen = screen;
end

function BASE:GetController()
	return self._controller;
end

function BASE:SetController(ctrl)
	self._controller = ctrl;
end

function BASE:Color(index)
	self._color = index;
end

function BASE:OutlineColor(index)
	self._outlineColor = index;
end

function BASE:OutlineThickness(num)
	self._outlineThickness = num;
end

function BASE:SetHide(bool)
	self._hide = bool;
end

function BASE:GetHide()
	return self._hide;
end

function BASE:Remove()
	if not self._parent then
		return;
	end
	local children = self._parent._children;
	if not table.IsEmpty(children) then
		for k, v in ipairs(children) do
			if v == self then
				table.remove(children, k);
			end
		end
	end
end

function BASE:IsHovered()
	local cursor = self._cursor;
	local x = self:GetAbsolutePos().X;
	local y = self:GetAbsolutePos().Y;

	local w = self:GetWidth();
	local h = self:GetHeight();

	local mouse_x = cursor.X;
	local mouse_y = cursor.Y;

	return (mouse_x > x) and (mouse_x < x + w) and (mouse_y > y) and (mouse_y < y + h);
end

function BASE:Update()
	if not self._visible then return end

	for i = 1, #self._children do
		local child = self._children[i];
		if child then
			if child._drawAfterParent == false then
				child:Update();
			end
		end
	end

	self:GetCursor();

	local world_pos = self:GetAbsolutePos();
	local size = self:GetSize() - Vector(1, 1);

	if not self._hide then
		local thickness = self._outlineThickness;
		if thickness ~= 0 and math.min(size.X, size.Y) >= 1 then
			PrimitiveMan:DrawBoxFillPrimitive(self._screen,
			world_pos - Vector(thickness, thickness),
			world_pos + size + Vector(thickness, thickness),
			self._outlineColor);
		end
		if math.min(size.X, size.Y) >= 0 then
			PrimitiveMan:DrawBoxFillPrimitive(self._screen, world_pos, world_pos + size, self._color);
		end
	end

	for i = 1, #self._children do
		local child = self._children[i];
		if child then
			if child._drawAfterParent == true then
				child:Update();
			end
		end
	end

	if (self.Think) then
		self:Think();
	end

	if (self.NextUpdate) then
		self:NextUpdate();
	end
end

return BASE;