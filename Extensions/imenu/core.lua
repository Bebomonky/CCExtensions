local imenu = {}
local core_func = require("Mods.Extensions.imenu.gui.imenu_Base")

function imenu:Create()
	local members = {}

	setmetatable(members, self)
	self.__index = self

	return members
end

local panelFactory = {}
for files in LuaMan:GetFileList("Mods/Extensions/imenu/gui/") do
	local file = files:gsub("imenu_", "" ):gsub("%.lua$", "")
	if file ~= "Base" then
		panelFactory[file] = require("Mods.Extensions.imenu.gui." .. files:gsub("%.lua$", ""))
	end
end

function imenu:CreateGUI(control_ID, parent, name)
	if panelFactory[control_ID] then
		local panel = table.Copy(panelFactory[control_ID])
		panel:Initialize()

		--Copy functions from core_func first
		for k, v in pairs(core_func) do
			panel[k] = v
		end

		--Pre setup
		local activity = ActivityMan:GetActivity()
		panel:SetController(activity:GetPlayerController(self.Player))
		panel:SetScreen(activity:ScreenOfPlayer(self.Player))

		if name ~= nil and type(name) == "string" then
			panel:SetName(name)
		end
		if parent ~= nil and type(parent) == "table" then
			panel:SetParent(parent)
		end

		if ExtensionMan.EnableDebugPrinting then
			local msg = "Successfully created panel,"
			.. " control_ID: " .. control_ID
			.. " name: " .. panel._name
			.. " parent: " .. parent ~= nil and "Yes" or "No"
			if parent ~= nil then
				msg = msg .. " parent control_ID: " .. parent._controlType
			end
			ExtensionMan.print_debug(msg)
		end
		return panel
	end

	ExtensionMan.print_warn(control_ID .. " is an invalid controlType")
	return nil
end

function imenu:Initialize()
	local act = ActivityMan:GetActivity()
	if act == nil then ExtensionMan.print_notice("Warning!", "A activity is required to be running in order to setup menu!") return end

	-- Don't change these
	self.Activity = act
	self.GameActivity = ToGameActivity(act)
	self.Open = false --If you want your menu to be automatically opened, do it in a update function, check if it's being controlled
	self.Close = true --It's closed by default
	self.Cursor_Bitmap = "Data/Base.rte/GUIs/Skins/Cursor.png"

	self.ForceOpen = false --Will force everything to run once
	self.EntityCurrentlyControlled = false
	self.OneInstance = false
	self.KeepMenuOpen = false

	self.Player = -1
	self.Controller = nil
	self.EnterMenuTimer = Timer()
end

--[[---------------------------------------------------------
	Name: New( entity, func )
	Desc: Open a new menu everytime, or use a instance
-----------------------------------------------------------]]
function imenu:New(entity, func)
	if not entity then return "The entity does not exist" end
	if not entity.PlayerControllable then return "The entity cannot be controlled" end

	local ctrl = entity:GetController()
	self.Player = ctrl.Player
	self.Controller = self.Activity:GetPlayerController(ctrl.Player)
	self.Screen = self.Activity:ScreenOfPlayer(ctrl.Player)
	self.Mouse = UInputMan:GetMousePos() / FrameMan.ResolutionMultiplier

	self:SetDrawPos(Vector(entity.Pos.X, entity.Pos.Y))

	if self.ForceOpen then
		if self:ResetInstance(entity, self.OneInstance) then
			return true
		end
	end

	self.EnterMenuTimer:Reset()

	if not self.Open then
		func(entity)
	end

	self.Close = false
	self.Open = not self.Open

	return true
end

function imenu:SetDrawPos(pos)
	self.DrawPos = pos
end

function imenu:ResetInstance(entity, func, oneInstance)
	local playerControlled = entity:IsPlayerControlled()
	if playerControlled then
		if not self.EntityCurrentlyControlled then
			self.Open, self.KeepMenuOpen = instance(entity, func, oneInstance, self.Open, self.KeepMenuOpen)
			self.EntityCurrentlyControlled = true
		end
		return self.KeepMenuOpen
	end
	self.EntityCurrentlyControlled = false
	if oneInstance then return self.KeepMenuOpen end
	self.Open = false
end

function imenu:SwitchState()
	self.Open = not self.Open
	self.Close = not self.Close
end

--[[---------------------------------------------------------
	Name: shouldDisplay()
	Desc: true or false statements on should the menu be displayed
-----------------------------------------------------------]]
function imenu:shouldDisplay(entity)

	if self.Close == true then self:Remove() return false end
	if self.Open == false then self:Remove() return false end

	return true
end

--[[---------------------------------------------------------
	Name: Update( entity )
	Desc: Update function requires a entity to be passed, returns if the menu should be updating
-----------------------------------------------------------]]
function imenu:Update(entity)
	if not self:shouldDisplay(entity) then return false end

	cursor(self)

	if self.EnterMenuTimer:IsPastSimMS(50) then
		for _, input in pairs({Controller.SECONDARY_ACTION, Controller.ACTOR_NEXT_PREP, Controller.ACTOR_PREV_PREP}) do
			if self.Controller:IsState(input) then
				self:Remove()
				break
			end
		end
	end

	camera(self.DrawPos, entity)

	return true
end

function imenu:DrawCursor(screen)
	PrimitiveMan:DrawBitmapPrimitive(self.Screen, self.Cursor + Vector(5, 5), self.Cursor_Bitmap, 0)
end

--[[---------------------------------------------------------
	Name: Remove()
	Desc: Removes the menu that is active
		We set certain values regardless, because we are removing it!
-----------------------------------------------------------]]
function imenu:Remove()
	if self.Close == true then return end
	self.Open = false
	self.Close = true
end

function imenu:cursor_inside(el_pos, size)
	local el_x = el_pos.X
	local el_y = el_pos.Y

	local el_width = size.X
	local el_height = size.Y

	local mouse_x = self.Cursor.X
	local mouse_y = self.Cursor.Y

	return (mouse_x > el_x) and (mouse_x < el_x + el_width) and (mouse_y > el_y) and (mouse_y < el_y + el_height)
end

--[[---------------------------------------------------------
	Name: instance( entity, func, oneInstance, isOpen, stayedOpen )
	Desc: For each instance call, should the instance stay or should it be recreated everytime?
-----------------------------------------------------------]]
function instance(entity, func, oneInstance, isOpen, stayedOpen)
	stayedOpen = stayedOpen
	isOpen = isOpen
	if oneInstance then
		if not stayedOpen then
			func()
			isOpen = true
			stayedOpen = true
		end
		return isOpen, stayedOpen
	end
	func()
	isOpen = true

	return isOpen, stayedOpen
end

--[[---------------------------------------------------------
	Name: Camera()
	Desc: Sets everything to a static position (disables entity movement)
-----------------------------------------------------------]]
function camera(drawPos, entity)
	if SceneMan:ShortestDistance(drawPos, Vector(entity.Pos.X, entity.Pos.Y), SceneMan.SceneWrapsX):MagnitudeIsGreaterThan(2.0) then
		drawPos = Vector(entity.Pos.X, entity.Pos.Y)
	end

	local ctrl = entity:GetController()
	local states = {
		Controller.MOVE_UP, Controller.MOVE_DOWN, Controller.BODY_JUMPSTART, Controller.BODY_JUMP, Controller.BODY_CROUCH, Controller.MOVE_LEFT, Controller.MOVE_RIGHT,
		Controller.MOVE_IDLE, Controller.MOVE_FAST, Controller.AIM_UP, Controller.AIM_DOWN, Controller.AIM_SHARP, Controller.WEAPON_FIRE, Controller.WEAPON_RELOAD,
		Controller.WEAPON_CHANGE_NEXT, Controller.WEAPON_CHANGE_PREV
	}
	for _, input in ipairs(states) do
		ctrl:SetState(input, false)
	end
end

function cursor(self)
	local screen_offset = CameraMan:GetOffset(self.Screen)
	if self.Controller:IsMouseControlled() then
		self.Mouse = UInputMan:GetMousePos() / FrameMan.ResolutionMultiplier
	else
		if self.Controller:IsState(Controller.MOVE_LEFT) then
			self.Mouse = self.Mouse + Vector(-5, 0)
		end

		if self.Controller:IsState(Controller.MOVE_RIGHT) then
			self.Mouse = self.Mouse + Vector(5, 0)
		end

		if self.Controller:IsState(Controller.MOVE_UP) then
			self.Mouse = self.Mouse + Vector(0, -5)
		end

		if self.Controller:IsState(Controller.MOVE_DOWN) then
			self.Mouse = self.Mouse + Vector(0, 5)
		end
	end

	self.Cursor = screen_offset + self.Mouse
end

return imenu:Create()