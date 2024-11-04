local imenu = {};

function imenu:Create()
	local Members = {};

	setmetatable(Members, self);
	self.__index = self;

	return Members;
end

local panelFactory = {};

local _base = require("Mods.Extensions.imenu.gui.imenu_Base");
_base:Create();
--Create a new gui and parents automatically
function _base:Add(controlID, name)
	local panel = imenu:CreateGUI(controlID, self, name);
	return panel;
end

function imenu:RegisterGUI(controlID, panel, base)

	if (panelFactory[controlID]) then
		ExtensionMan.print_notice("[IMENU] Warning!", "This controlID already exist!");
		return;
	end

	local Mt = {
		__index = base
	};
	setmetatable(panel, Mt);

	if (panel.Create) then
		panel:Create();
	end
	local classname = panel:GetControlID();
	panelFactory[classname] = panel;
end

for files in LuaMan:GetFileList("Mods/Extensions/imenu/gui/") do
	local controlID = files:gsub("imenu_", "" ):gsub("%.lua$", "");
	if controlID ~= "Base" then
		local file = "Mods.Extensions.imenu.gui." .. files:gsub("%.lua$", "");
		local panel = require(file);
		imenu:RegisterGUI(controlID, panel, _base);
	end
end

function imenu:CreateGUI(controlID, parent, name)
	if (panelFactory[controlID]) then
		local Mt = {
			__index = parent or panelFactory[controlID]
		};
		local panel = setmetatable({}, Mt);

		--Apply all default properties
		for k, v in pairs(panelFactory[controlID]) do
			panel[k] = v;
		end

		panel:ClearChildren(); --!Don't remove or stack overflow!

		panel:SetController(self.Controller);
		panel:SetScreen(self.Screen);
		panel:SetName(name or controlID);
		if parent ~= nil and type(parent) == "table" then
			panel:SetParent(parent);
		end

		if ExtensionMan.EnableDebugPrinting then
			local msg = "Successfully created panel"
			.. "\tcontrolID: " .. controlID
			.. "\tname: " .. panel._name
			.. "\tparent: " .. (parent and "Yes" or "No")
			if parent ~= nil then
				msg = msg .. "\tparent name: " .. parent._name;
			end
			ExtensionMan.print_debug(msg);
		end
		return panel;
	end

	ExtensionMan.print_warn("[IMENU] " .. controlID .. " is an invalid controlID");
	return nil;
end

function imenu:Initialize()
	local act = ActivityMan:GetActivity();
	if act == nil then ExtensionMan.print_notice("[IMENU] Warning!", "A activity is required to be running in order to initialize imenu!") return end

	-- Don't change these
	self.Activity = act;
	self.GameActivity = ToGameActivity(act);
	self.Cursor_Bitmap = "Data/Base.rte/GUIs/Skins/Cursor.png";
	self._open = false;
	self._locked = false;
	self.Player = -1;
	self.Controller = nil;
	self._enterMenuTimer = Timer();
	self.Actor = nil;
end

--[[---------------------------------------------------------
	Name: ToOpen( actor, inputMode )
	Desc: returns true if the menu is truely open
	advised to be with IsOpen() if running instantly
-----------------------------------------------------------]]
function imenu:ToOpen(actor, inputMode)
	self:SetActor(actor);
	if not self.Actor or not MovableMan:ValidMO(self.Actor) then return false; end
	if not self.Actor.PlayerControllable then return false; end

	local success = self:SetPlayerMenu(self.Actor:GetController().Player);
	if not success then
		return false;
	end

	inputMode = inputMode or Controller.CIM_AI;
	local toLock = not self._locked;

	local success = self.GameActivity:LockControlledActor(self.Player, toLock, inputMode);
	if not success then
		ExtensionMan.print_notice("[IMENU] Warning!", "Unable to lock actor");
		return false;
	end

	self._enterMenuTimer:Reset();

	self._locked = true;

	self:SwitchState();

	return self._open;
end

--[[---------------------------------------------------------
	Name: SetPlayerMenu()
	Desc: returns true if valid player and not in odd view states
-----------------------------------------------------------]]
function imenu:SetPlayerMenu(player)
	if player ~= -1 then
		self.Player = player;
	end

	if (self.Activity:GetViewState(self.Player) ~= Activity.DEATHWATCH and
	self.Activity:GetViewState(self.Player) ~= Activity.ACTORSELECT and
	self.Activity:GetViewState(self.Player) ~= Activity.AIGOTOPOINT) then
		self.Controller = self.Activity:GetPlayerController(self.Player);
		self.Screen = self.Activity:ScreenOfPlayer(self.Player);
		return true;
	end
end

function imenu:SwitchState()
	self._open = not self._open;
end

function imenu:IsOpen()
	return self._open == true;
end

function imenu:SetActor(entity)
	self.Actor = entity;
end

function imenu:ValidPlayer()
	return self.Player ~= -1;
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
			self:Remove();
			return false;
		end

		local states = {
			Controller.MOVE_UP, Controller.MOVE_DOWN, Controller.BODY_JUMPSTART, Controller.BODY_JUMP, Controller.MOVE_LEFT,
			Controller.MOVE_RIGHT, Controller.MOVE_FAST, Controller.AIM_UP, Controller.AIM_DOWN, Controller.AIM_SHARP
		};

		for _, input in ipairs(states) do
			self.Actor:GetController():SetState(input, false);
		end

		if self._enterMenuTimer:IsPastSimMS(50) then
			for _, input in pairs({Controller.PRESS_SECONDARY, Controller.ACTOR_NEXT_PREP, Controller.ACTOR_PREV_PREP}) do
				if self.Controller:IsState(input) then
					self:Remove();
					break;
				end
			end
		end

		local offset = CameraMan:GetOffset(self.Player);
		local mouse = Vector();
		if self.Controller and self.Controller:IsMouseControlled() then
			mouse = offset + (UInputMan:GetMousePos() / FrameMan.ResolutionMultiplier);
		end

		self.Cursor = mouse;
		_base:_SetCursor(self.Cursor);

		return true;
	end
end

function imenu:DrawCursor()
	if self.Controller and self.Controller:IsMouseControlled() then
		PrimitiveMan:DrawBitmapPrimitive(self.Screen, self.Cursor + Vector(5, 5), self.Cursor_Bitmap, 0);
	end
end

--[[---------------------------------------------------------
	Name: Remove()
	Desc: Releases the controlled actor, returns if it was successful or not (ONLY ONCE)
-----------------------------------------------------------]]
function imenu:Remove()
	if self.Player ~= -1 then
		if self._locked == true then
			self.GameActivity:LockControlledActor(self.Player, false, Controller.CIM_PLAYER);
			self.Controller = nil;
			self.Actor = nil;
			self._open = false;
			self._locked = false;
		end
	end
end

return imenu:Create();