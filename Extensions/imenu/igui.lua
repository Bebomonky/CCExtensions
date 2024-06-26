local igui = {}
--[[
* We require the entity (aka the actor, to be passed in the update, so that we can consistantly get the player screen)
! These are all default values, do not modify them
? You have to set the parent, after the name or it won't work
? TextAlignment is W.I.P for everything ( left = 0, center = 1, right = 2 )
? ControlTypes don't do anything for now (or never)

TODO Tooltip shown on mouse position
]]

igui.ControlState = {
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
igui.ControlState_Pressed = {}


-- PUBLIC FUNCTIONS ------------------------------------------------------------

function igui.Update(player, screen, cursor_pos)
	if not player then return end
	igui.Player = player
	igui.Controller = ActivityMan:GetActivity():GetPlayerController(player)
	igui.Screen = screen
	igui.Cursor = cursor_pos
end

function igui.CollectionBox()
	local cbox = {}
	cbox.Child = {}

	--String
	util.AccessorFunc(cbox, "Name", "Name", 1)
	util.AccessorFunc(cbox, "Title", "Title", 1)

	--Number
	util.AccessorFunc(cbox, "Color", "Color", 2)
	util.AccessorFunc(cbox, "OutlineColor", "OutlineColor", 2)
	util.AccessorFunc(cbox, "OutlineThickness", "OutlineThickness", 2)
	--Bool
	util.AccessorFunc(cbox, "Visible", "Visible", 3)
	util.AccessorFunc(cbox, "SmallText", "SmallText", 3)
	util.AccessorFunc(cbox, "DrawAfterParent", "DrawAfterParent", 3)

	--Vector
	util.AccessorFunc(cbox, "Pos", "Pos", 4)
	util.AccessorFunc(cbox, "Size", "Size", 4)

	cbox.ControlType = "COLLECTIONBOX"
	cbox.Name = cbox.Name or "CollectionBox"
	cbox.Title = "Title Text"
	cbox.Color = 146
	cbox.OutlineColor = 71
	cbox.OutlineThickness = 0
	cbox.Visible = true
	cbox.SmallText = true
	cbox.DrawAfterParent = true
	cbox.Pos = Vector()
	cbox.Size = Vector(80, 50)

	cbox.Think = nil

	cbox.SetParent = function(self, parent)
		self.Parent = parent
		parent.Child[self.Name] = self
	end

	cbox.GetParent = function(self)
		return self.Parent
	end

	cbox.Update = function(self, entity)
		if not self.Visible then return end
		if not igui.Screen then return end
		if not table.IsEmpty(self.Child) then
			for i, child in pairs(self.Child) do
				if child.DrawAfterParent == false then
					child:Update(entity)
				end
			end
		end
		local pos = (self.Parent and self.Parent.Pos + self.Pos) or self.Pos
		local world_pos = pos + CameraMan:GetOffset(igui.Screen)
		local text_pos = world_pos
		local thickness = self.OutlineThickness
		if thickness ~= 0 then
			PrimitiveMan:DrawBoxFillPrimitive(igui.Screen, world_pos - Vector(thickness, thickness), world_pos + self.Size + Vector(thickness, thickness), self.OutlineColor)
		end
		PrimitiveMan:DrawBoxFillPrimitive(igui.Screen, world_pos, world_pos + self.Size, self.Color)
		PrimitiveMan:DrawTextPrimitive(igui.Screen, text_pos, self.Title, self.SmallText, 0)

		if self.Think then
			self.Think(entity, igui.Screen)
		end

		if not table.IsEmpty(self.Child) then
			for i, child in pairs(self.Child) do
				if child.DrawAfterParent == true then
					child:Update(entity)
				end
			end
		end
	end

	return cbox
end

function igui.Button()
	local button = {}
	button.Child = {}

	--String
	util.AccessorFunc(button, "Name", "Name", 1)
	util.AccessorFunc(button, "Text", "Text", 1)
	util.AccessorFunc(button, "Tooltip", "Tooltip", 1)

	--Number
	util.AccessorFunc(button, "TextAlignment", "TextAlignment", 2)
	util.AccessorFunc(button, "Color", "Color", 2)
	util.AccessorFunc(button, "OutlineColor", "OutlineColor", 2)
	util.AccessorFunc(button, "OutlineThickness", "OutlineThickness", 2)

	--Bool
	util.AccessorFunc(button, "Visible", "Visible", 3)
	util.AccessorFunc(button, "Clickable", "Clickable", 3)
	util.AccessorFunc(button, "SmallText", "SmallText", 3)
	util.AccessorFunc(button, "DrawAfterParent", "DrawAfterParent", 3)

	--Vector
	util.AccessorFunc(button, "Pos", "Pos", 4)
	util.AccessorFunc(button, "Size", "Size", 4)
	util.AccessorFunc(button, "TextPos", "TextPos", 4)

	button.ControlType = "BUTTON"
	button.Name = button.Name or "Button"
	button.Text = ""
	button.Tooltip = ""
	button.TextAlignment = 1
	button.Color = 146
	button.OutlineColor = 71
	button.OutlineThickness = 0
	button.Visible = true
	button.Clickable = true
	button.SmallText = true
	button.DrawAfterParent = true
	button.Pos = Vector()
	button.Size = Vector(80, 50)
	button.TextPos = Vector()

	button.IsHovered = false
	button.Think = nil

	button.SetParent = function(self, parent)
		self.Parent = parent
		parent.Child[self.Name] = self
	end

	button.GetParent = function(self)
		return self.Parent
	end

	button.Update = function(self, entity)
		if not self.Visible then return end
		if not igui.Screen then return end
		if not table.IsEmpty(self.Child) then
			for i, child in pairs(self.Child) do
				if child.DrawAfterParent == false then
					child:Update(entity)
				end
			end
		end
		local pos = (self.Parent and self.Parent.Pos + self.Pos) or self.Pos
		local world_pos = pos + CameraMan:GetOffset(igui.Screen)
		local text_pos = world_pos

		self.IsHovered = false

		if cursor_inside(world_pos, self.Size) then
			self.IsHovered = true
		end

		if self.Clickable and self.IsHovered then
			for _, input in pairs(igui.ControlState) do
				if (self.OnPress) then
					if igui.Controller:IsState(input) then
						if not igui.ControlState_Pressed[input] then
							self.OnPress(input)
							igui.ControlState_Pressed[input] = true
						end
					else
						igui.ControlState_Pressed[input] = false
					end
				end

				if (self.OnHeld) then
					local isHeld = false
					if igui.Controller:IsState(input) then
						isHeld = true
					end

					if isHeld then
						self.OnHeld(input)
					end
				end
			end
		end

		--Center
		if self.TextAlignment == 1 then text_pos = text_pos + self.Size / 2 + Vector(0, -5) end

		local thickness = self.OutlineThickness
		if thickness ~= 0 then
			PrimitiveMan:DrawBoxFillPrimitive(igui.Screen, world_pos - Vector(thickness, thickness), world_pos + self.Size + Vector(thickness, thickness), self.OutlineColor)
		end
		PrimitiveMan:DrawBoxFillPrimitive(igui.Screen, world_pos, world_pos + self.Size, self.Color)

		PrimitiveMan:DrawTextPrimitive(igui.Screen, self.TextPos + text_pos, self.Text, self.SmallText, self.TextAlignment or 0)

		if self.Tooltip ~= "" then
			PrimitiveMan:DrawTextPrimitive(igui.Screen, UInputMan:GetMousePos(), self.Tooltip, true, 0)
		end

		if (self.Think) then
			self.Think(entity, igui.Screen)
		end

		if not table.IsEmpty(self.Child) then
			for i, child in pairs(self.Child) do
				if child.DrawAfterParent == true then
					child:Update(entity)
				end
			end
		end
	end

	return button
end

function igui.ProgressBar()
	local pbar = {}

	--String
	util.AccessorFunc(pbar, "Name", "Name", 1)
	util.AccessorFunc(pbar, "Text", "Text", 1)
	util.AccessorFunc(pbar, "Tooltip", "Tooltip", 1)

	--Number
	util.AccessorFunc(pbar, "FGColor", "FGColor", 2)
	util.AccessorFunc(pbar, "BGColor", "BGColor", 2)
	util.AccessorFunc(pbar, "OutlineColor", "OutlineColor", 2)
	util.AccessorFunc(pbar, "MaxHeight", "MaxHeight", 2)
	util.AccessorFunc(pbar, "Fraction", "Fraction", 2)
	util.AccessorFunc(pbar, "OutlineThickness", "OutlineThickness", 2)

	--Bool
	util.AccessorFunc(pbar, "Visible", "Visible", 3)
	util.AccessorFunc(pbar, "SmallText", "SmallText", 3)
	util.AccessorFunc(pbar, "DrawAfterParent", "DrawAfterParent", 3)

	--Vector
	util.AccessorFunc(pbar, "Pos", "Pos", 4)
	util.AccessorFunc(pbar, "Size", "Size", 4)

	pbar.ControlType = "PROGRESSBAR"
	pbar.Name = pbar.Name or "ProgressBar"
	pbar.Text = ""
	pbar.Tooltip = ""
	pbar.FGColor = 117
	pbar.BGColor = 146
	pbar.OutlineColor = 144
	pbar.MaxHeight = 10
	pbar.OutlineThickness = 2
	pbar.Visible = true
	pbar.SmallText = true
	pbar.DrawAfterParent = true
	pbar.Pos = Vector()
	pbar.Size = Vector(100, 10)

	local min = 0
	local max = 1
	local completed = false

	pbar.OnComplete = nil
	pbar.Think = nil
	pbar.OnProgress = nil

	pbar.SetParent = function(self, parent)
		self.Parent = parent
		for i, child in pairs(parent.Child) do
			if child.Name == self.Name then
				parent.Child[i] = nil
			end
		end
		table.insert(parent.Child, self)
	end

	pbar.GetParent = function(self)
		return self.Parent
	end

	pbar.GetCompleted = function(self)
		return completed
	end

	pbar.SetFraction = function(self, value)
		min = value
	end

	pbar.GetFraction = function(self)
		return min
	end

	pbar.Update = function(self, entity)
		if not self.Visible then return end
		if not igui.Screen then return end
		local pos = (self.Parent and self.Parent.Pos + self.Pos) or self.Pos
		local world_pos = pos + CameraMan:GetOffset(igui.Screen)
		local text_pos = world_pos
		local factor = math.min(min, max)
		local bottomRightPos = world_pos + self.Size + Vector(0, 0.5)
		local bottomRightPos2 = world_pos + Vector(self.Size.X * factor, self.Size.Y)
		local thickness = self.OutlineThickness

		if thickness ~= 0 then
			PrimitiveMan:DrawBoxFillPrimitive(igui.Screen, world_pos - Vector(thickness, thickness), bottomRightPos + Vector(thickness, thickness), self.OutlineColor)
		end
		PrimitiveMan:DrawBoxFillPrimitive(igui.Screen, world_pos, bottomRightPos, self.BGColor)
		if min ~= 0 then
			PrimitiveMan:DrawBoxFillPrimitive(igui.Screen, world_pos, bottomRightPos2, self.FGColor)
		end
		PrimitiveMan:DrawTextPrimitive(igui.Screen, text_pos, self.Text, self.SmallText, 0)

		if not completed then
			if min >= max then
				completed = true
				if (self.OnComplete) then
					self.OnComplete(entity)
					min = 0
					completed = false
				end
			end
		end
		if self.Think then
			self.Think(entity, igui.Screen)
		end
		if self.OnProgress then
			self.OnProgress(entity, igui.Screen)
		end
	end

	return pbar
end

function igui.Label()
	local label = {}

	--String
	util.AccessorFunc(label, "Name", "Name", 1)
	util.AccessorFunc(label, "Text", "Text", 1)

	--Bool
	util.AccessorFunc(label, "Visible", "Visible", 3)
	util.AccessorFunc(label, "SmallText", "SmallText", 3)
	util.AccessorFunc(label, "DrawAfterParent", "DrawAfterParent", 3)

	--Vector
	util.AccessorFunc(label, "Pos", "Pos", 4)

	label.ControlType = "LABEL"
	label.Name = label.Name or "Label"
	label.Text = "Label"
	label.Visible = true
	label.SmallText = true
	label.DrawAfterParent = true
	label.Pos = Vector()

	label.Think = nil

	label.SetParent = function(self, parent)
		self.Parent = parent
		for i, child in pairs(parent.Child) do
			if child.Name == self.Name then
				parent.Child[i] = nil
			end
		end
		table.insert(parent.Child, self)
	end

	label.GetParent = function(self)
		return self.Parent
	end

	label.Update = function(self, entity)
		if not self.Visible then return end
		if not igui.Screen then return end
		local pos = (self.Parent and self.Parent.Pos + self.Pos) or self.Pos
		local world_pos = pos + CameraMan:GetOffset(igui.Screen)
		PrimitiveMan:DrawTextPrimitive(igui.Screen, world_pos, self.Text, self.SmallText, 0)
		if (self.Think) then
			self.Think(entity, igui.Screen)
		end
	end
	return label
end

-- PRIVATE FUNCTIONS -----------------------------------------------------------

function cursor_inside(el_pos, size)
	local el_x = el_pos.X
	local el_y = el_pos.Y

	local el_width = size.X
	local el_height = size.Y

	local mouse_x = igui.Cursor.X
	local mouse_y = igui.Cursor.Y

	return (mouse_x > el_x) and (mouse_x < el_x + el_width) and (mouse_y > el_y) and (mouse_y < el_y + el_height)
end

-- MODULE END ------------------------------------------------------------------

return igui