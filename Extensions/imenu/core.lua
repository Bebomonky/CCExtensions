local imenu = {}

function imenu:Create()
	local members = {}
	setmetatable(members, self)

	self.__index = self

	return members
end

-- PUBLIC FUNCTIONS ------------------------------------------------------------

function imenu:Initialize()
	local act = ActivityMan:GetActivity()
	if act == nil then ConsoleMan:PrintString("A activity is required to be running in order to setup menu!"  .. "Warning! \xD5 ") return end

	-- Don't change these
	self.Activity = act
	self.GameActivity = ToGameActivity(self.Activity)
	self.Open = false --If you want your menu to be automatically opened, do it in a update function, check if it's being controlled
	self.Close = true --It's closed by default
	self.Cursor_Bitmap = "Data/Base.rte/GUIs/Skins/Cursor.png"

	self.ForceOpen = false --Will force everything to run once
	self.EntityCurrentlyControlled = false
	self.OneInstance = false
	self.KeepMenuOpen = false
	self.Player = nil
	self.Actor = nil
	self.Controller = nil
end

function imenu:Clear()
	self.GameActivity:LockControlledActor(self.Player, false, Controller.CIM_DISABLED)
	self.Actor = nil
	self.Player = nil
	self.Controller = nil
	self.Open = false
	self.Close = true
end

--[[---------------------------------------------------------
	Name: New( entity, func )
	Desc: When the entity wants to send a message
		It's best to call this one at a time or use ForceOpen (though the menu will be opened automatically!)
	Note: You can use this on anything that can retrieve Messages. (unless forcefully blacklisted)
-----------------------------------------------------------]]
function imenu:New(entity, func)
	if not entity then return "The entity does not exist" end
	if not entity.PlayerControllable then return "The entity cannot be controlled" end

	if self.Player == nil then
		local ctrl = entity:GetController()
		self.Actor = entity
		self.Player = ctrl.Player
		self.Controller = self.Activity:GetPlayerController(ctrl.Player)
	end

	self.Mouse = UInputMan:GetMousePos() / FrameMan.ResolutionMultiplier

	self:SetDrawPos(Vector(entity.Pos.X, entity.Pos.Y))

	if self.ForceOpen then
		if self:ResetInstance(entity, self.OneInstance) then
			return true
		end
	end

	if not self.Open then
		func(entity)
	end

	self.Close = false
	self.Open = not self.Open

	--Since the player is stored, it will fix it right back so we don't get stuck :D
	if self.Player ~= nil then
		self.GameActivity:LockControlledActor(self.Player, self.Open, Controller.CIM_DISABLED)
	end
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
	Name: shouldDisplay( self, entity )
	Desc: true or false statements on should the menu be displayed
-----------------------------------------------------------]]
function imenu:shouldDisplay(entity)
	--[[
	if self.ForceOpen then
		--Just to be sure, we don't want to cursor to still exist if we don't control it
		if entity.Health <= 0 or not entity:IsPlayerControlled() then self.Cursor = nil; end
		return true
	end
	if self.Close == true then self:Remove() return false end
	if self.Open == false then self:Remove() return false end

	return true
	]]

	if self.Actor and self.Actor.Health <= 0 then return false end

	if self.ForceOpen then
		--Just to be sure, we don't want to cursor to still exist if we don't control it
		if not (self.Actor or MovableMan:ValidMO(self.Actor)) then self.Cursor = nil; end
		return false
	end

	if not (self.Actor or MovableMan:ValidMO(self.Actor)) then
		self:Remove()
		return false
	end

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

	if self.Player then
		local screen = self.Activity:ScreenOfPlayer(self.Player)
		local screen_offset = CameraMan:GetOffset(screen)
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

		--Cursor creation, update
		self.Cursor = screen_offset + self.Mouse
	end

	for _, input in pairs({Controller.SECONDARY_ACTION, Controller.ACTOR_NEXT_PREP, Controller.ACTOR_PREV_PREP}) do
		if self.Controller:IsState(input) then
			self:Clear()
			break
		end
	end

	camera(self.DrawPos, entity)

	return true
end

function imenu:GetScreen()
	if self.Player == nil then return nil end
	return self.Activity:ScreenOfPlayer(self.Player)
end

function imenu:DrawCursor(screen)
	if self.Cursor == nil then return end
	if screen == nil then return end
	PrimitiveMan:DrawBitmapPrimitive(screen,
	self.Cursor + Vector(5, 5),
	self.Cursor_Bitmap,
	0)
end

--[[---------------------------------------------------------
	Name: Remove()
	Desc: Removes the menu that is active
		We set certain values regardless, because we are removing it!
-----------------------------------------------------------]]
function imenu:Remove()
	if not self.Cursor then return end
	if self.ForceOpen then
		self.Cursor = nil
		return
	end
	self.Open = false
	self.Close = true
	self.Cursor = nil
end

-- PRIVATE FUNCTIONS -----------------------------------------------------------

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
	}
	for _, input in ipairs(states) do
		ctrl:SetState(input, false)
	end
end

-- MODULE END ------------------------------------------------------------------

return imenu:Create()