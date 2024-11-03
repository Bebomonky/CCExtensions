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
	self.Cursor_Bitmap = "Data/Base.rte/GUIs/Skins/Cursor.png"
	self._open = false
	self._locked = false
	self.Player = -1
	self.Controller = nil
	self._enterMenuTimer = Timer()
	self.Actor = nil
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

function imenu:SwitchState()
	self.Open = not self.Open
	self.Close = not self.Close
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

	return true
end

function imenu:DrawCursor(screen)
	PrimitiveMan:DrawBitmapPrimitive(screen, self.Cursor + Vector(5, 5), self.Cursor_Bitmap, 0)
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

return imenu:Create()