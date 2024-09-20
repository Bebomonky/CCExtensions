local BASE = {}

function BASE:SetName(str)
	self._name = str
end

function BASE:GetName()
	return self._name
end

function BASE:SetParent(parent)
	self:Remove()
	self._parent = parent
	table.insert(parent._children, self)
end

function BASE:GetParent()
	return self._parent
end

function BASE:SetVisible(bool)
	self._visible = bool
end

function BASE:GetVisible()
	return self._visible
end

function BASE:SmallText(bool)
	self._smallText = bool
end

function BASE:DrawAfterParent(bool)
	self._drawAfterParent = bool
end

function BASE:SetPos(x, y)
	self._x, self._y = x, y
end

function BASE:GetPos()
	return self._x, self._y
end

function BASE:GetPosX()
	return self._x
end

function BASE:GetPosY()
	return self._y
end

function BASE:SetSize(w, h)
	self._w, self._h = w, h
end

function BASE:GetSize()
	return self._w, self._h
end

function BASE:GetWidth()
	return self._w
end

function BASE:GetHeight()
	return self._h
end

function BASE:GetChildren()
	return self._children
end

function BASE:ClearChildren()
	self._children = {}
end

function BASE:GetScreen()
	return self._screen
end

function BASE:SetScreen(screen)
	self._screen = screen
end

function BASE:GetController()
	return self._controller
end

function BASE:SetController(ctrl)
	self._controller = ctrl
end

function BASE:Remove()
	if not self._parent then
		return
	end
	local children = self._parent._children
	if not table.IsEmpty(children) then
		for k, v in ipairs(children) do
			if v == self then
				table.remove(children, k)
			end
		end
	end
end

return BASE