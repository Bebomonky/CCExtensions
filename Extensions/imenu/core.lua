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
	Name: ToOpen( actor, lock, inputMode )
	Desc: returns true if the menu is truely open
	advised to be with IsOpen() if running instantly
-----------------------------------------------------------]]
function imenu:ToOpen(actor, inputMode)
	self:SetActor(actor)
	if not self.Actor or not MovableMan:ValidMO(self.Actor) then return false end
	if not self.Actor.PlayerControllable then return false end

	local success = self:SetPlayerMenu(self.Actor:GetController().Player)
	if not success then
		return false
	end

	inputMode = inputMode or Controller.CIM_AI
	local toLock = not self._locked

	local success = self.GameActivity:LockControlledActor(self.Player, toLock, inputMode)
	if not success then
		ExtensionMan.print_notice("[IMENU] Warning!", "Unable to lock actor")
		return false
	end

	self._enterMenuTimer:Reset()

	self._locked = true

	self:SwitchState()

	return self._open
end

--[[---------------------------------------------------------
	Name: SetPlayerMenu()
	Desc: returns true if valid player and not in odd view states
-----------------------------------------------------------]]
function imenu:SetPlayerMenu(player)
	if player ~= -1 then
		self.Player = player
	end

	if (self.Activity:GetViewState(self.Player) ~= Activity.DEATHWATCH and
	self.Activity:GetViewState(self.Player) ~= Activity.ACTORSELECT and
	self.Activity:GetViewState(self.Player) ~= Activity.AIGOTOPOINT) then
		self.Controller = self.Activity:GetPlayerController(self.Player)
		self.Screen = self.Activity:ScreenOfPlayer(self.Player)
		return true
	end
end

function imenu:SwitchState()
	self._open = not self._open
end

function imenu:IsOpen()
	return self._open == true
end

function imenu:SetActor(entity)
	self.Actor = entity
end

function imenu:ValidPlayer()
	return self.Player ~= -1
end

--[[---------------------------------------------------------
	Name: Update()
	Desc: returns if the menu should be updating based on various conditions
-----------------------------------------------------------]]
function imenu:Update()
	if (self.Player ~= -1 and
	self.Activity:GetViewState(self.Player) ~= Activity.DEATHWATCH and
	self.Activity:GetViewState(self.Player) ~= Activity.ACTORSELECT and
	self.Activity:GetViewState(self.Player) ~= Activity.AIGOTOPOINT) then

		--make sure to remove if nothing qualifys
		if (not self:IsOpen() or (not self.Controller or not self.Actor or not MovableMan:ValidMO(self.Actor) ) ) then
			self:Remove()
			return false
		end

		local states = {
			Controller.MOVE_UP, Controller.MOVE_DOWN, Controller.BODY_JUMPSTART, Controller.BODY_JUMP, Controller.MOVE_LEFT,
			Controller.MOVE_RIGHT, Controller.MOVE_FAST, Controller.AIM_UP, Controller.AIM_DOWN, Controller.AIM_SHARP
		}

		for _, input in ipairs(states) do
			self.Actor:GetController():SetState(input, false)
		end

		if self._enterMenuTimer:IsPastSimMS(50) then
			for _, input in pairs({Controller.PRESS_SECONDARY, Controller.ACTOR_NEXT_PREP, Controller.ACTOR_PREV_PREP}) do
				if self.Controller:IsState(input) then
					self:Remove()
					break
				end
			end
		end

		local offset = CameraMan:GetOffset(self.Player)
		local mouse = Vector()
		if self.Controller and self.Controller:IsMouseControlled() then
			mouse = offset + (UInputMan:GetMousePos() / FrameMan.ResolutionMultiplier)
		end

		self.Cursor = mouse

		return true
	end
end

function imenu:DrawCursor()
	if self.Controller and self.Controller:IsMouseControlled() then
		PrimitiveMan:DrawBitmapPrimitive(self.Screen, self.Cursor + Vector(5, 5), self.Cursor_Bitmap, 0)
	end
end

--[[---------------------------------------------------------
	Name: Remove()
	Desc: Releases the controlled actor, returns if it was successful or not (ONLY ONCE)
-----------------------------------------------------------]]
function imenu:Remove()
	if self.Player ~= -1 then
		if self._locked == true then
			self.GameActivity:LockControlledActor(self.Player, false, Controller.CIM_PLAYER)
			self.Controller = nil
			self.Actor = nil
			self._open = false
			self._locked = false
		end
	end
end

return imenu:Create()