local imenu = {};
imenu.Cursors = {};

function imenu:Create()
	local Members = {};

	setmetatable(Members, self);
	self.__index = self;

	return Members;
end

local panelFactory = {};
local baseclass = {};

function getBaseClass(name)
	return baseclass[name];
end

function setBaseClass(name, tab)
	if (not baseclass[name]) then
		baseclass[name] = tab;
	else
		table.Merge(baseclass[name], tab);
		setmetatable(baseclass[name], getmetatable(tab));
	end
end

function errorMsg(msg1, msg2)
	error("[IMENU]" .. " \xBF " .. msg1 .. " \xBE  " .. msg2, 3);
end

local _base = require("Mods.Extensions.imenu.gui.imenu_Base");
_base:Create();
setBaseClass("BASE", _base);

--Create a new gui and parents automatically
function _base:Add(controlID)
	if (panelFactory[controlID]) then
		local Mt = panelFactory[controlID];
		local panel = self:Add(Mt.Base);
		if (not panel) then
			errorMsg(Mt.Base, "is an invalid base");
		end
		table.Merge(panel, Mt);

		if (panel.Create) then
			panel:Create();
		end

		panel:ClearChildren(); --! Don't remove or chaos!

		panel:SetName(controlID);

		panel:SetController(self:GetController());
		panel:SetScreen(self:GetScreen());

		panel:SetParent(self);

		if ExtensionMan.EnableDebugPrinting then
			local msg = "Successfully added panel"
			.. "\tcontrolID: " .. controlID
			.. "\tname: " .. panel._name
			.. "\tparent: " .. "Yes"
			if parent ~= nil then
				msg = msg .. "\tparent name: " .. self._name;
			end
			ExtensionMan.print_debug(msg);
		end
		return panel;
	end

	local Mt = getBaseClass(controlID);
	if (not Mt) then
		errorMsg(controlID, "is an invalid controlID");
	end
	local panel = {};
	table.Merge(panel, Mt);
	panel:SetController(self:GetController());
	panel:SetScreen(self:GetScreen());

	return panel;
end

function _base:GetCursor()
	self._cursor = imenu.Cursors[self:GetController().Player] + CameraMan:GetOffset(self:GetScreen());
end

function imenu:RegisterGUI(controlID, panel, base)

	if (panelFactory[controlID]) then
		ExtensionMan.print_notice("[IMENU] Warning!", "This controlID already exist!");
		return;
	end

	panel.Base = base or "BASE";
	panel.Create = panel.Create or function() end;

	panelFactory[controlID] = panel;
	setBaseClass(controlID, panel);

	local Mt = {
	__index = function(Table, k)
		if (panelFactory[panel.Base] and panelFactory[panel.Base][k]) then
			return baseclass[k];
		end
	end};

	setmetatable(panel, Mt);

	return panel;
end

local path = "Mods/Extensions/imenu/gui/";
imenu:RegisterGUI("COLLECTIONBOX", require(path .. "imenu_CollectionBox"), "BASE");
imenu:RegisterGUI("BUTTON", require(path .. "imenu_Button"), "BASE");
imenu:RegisterGUI("LABEL", require(path .. "imenu_Label"), "BASE");
imenu:RegisterGUI("PROGRESSBAR", require(path .. "imenu_ProgressBar"), "BASE");

function imenu:CreateGUI(controlID, parent, name)
	if (panelFactory[controlID]) then
		local Mt = panelFactory[controlID];
		local panel = self:CreateGUI(Mt.Base, parent, name or controlID);
		if (not panel) then
			errorMsg(Mt.Base, "is an invalid base");
		end

		table.Merge(panel, Mt);

		if (panel.Create) then
			panel:Create();
		end

		panel:ClearChildren(); --! Don't remove or chaos!

		panel:SetName(name or controlID);

		panel:SetController(self.Controller);
		panel:SetScreen(self.Screen);
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

	local Mt = getBaseClass(controlID);
	if (not Mt) then
		errorMsg(controlID, "is an invalid controlID");
	end
	local panel = {};
	table.Merge(panel, Mt);
	panel:SetController(self.Controller);
	panel:SetScreen(self.Screen);

	return panel;
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

		local actor = self.Activity:GetControlledActor(self.Player)
		if self.Actor.UniqueID ~= actor.UniqueID then
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
			for _, input in pairs({Controller.SECONDARY_ACTION, Controller.ACTOR_NEXT_PREP, Controller.ACTOR_PREV_PREP}) do
				if self.Controller:IsState(input) then
					self:Remove();
					break;
				end
			end
		end

		if self.Controller then
			if self.Controller:IsMouseControlled() then
				imenu.Cursors[self.Player] = UInputMan:GetMousePos() / FrameMan.ResolutionMultiplier;
			else
				if self.Controller:IsKeyboardOnlyControlled() then
					if self.Controller:IsState(Controller.MOVE_LEFT) then imenu.Cursors[self.Player] = imenu.Cursors[self.Player] - Vector(5, 0); end
					if self.Controller:IsState(Controller.MOVE_RIGHT) then imenu.Cursors[self.Player] = imenu.Cursors[self.Player] + Vector(5, 0); end
					if self.Controller:IsState(Controller.MOVE_UP) then imenu.Cursors[self.Player] = imenu.Cursors[self.Player] - Vector(0, 5); end
					if self.Controller:IsState(Controller.MOVE_DOWN) then imenu.Cursors[self.Player] = imenu.Cursors[self.Player] + Vector(0, 5); end
				elseif self.Controller:IsGamepadControlled() then
					local speed = 7;
					imenu.Cursors[self.Player] = imenu.Cursors[self.Player] + self.Controller.AnalogMove * speed;
				end

				if imenu.Cursors[self.Player].X < 0 then
					imenu.Cursors[self.Player].X = 0;
				elseif imenu.Cursors[self.Player].Y < 0 then
					imenu.Cursors[self.Player].Y = 0;
				elseif imenu.Cursors[self.Player].Y > FrameMan.PlayerScreenHeight then
					imenu.Cursors[self.Player].Y = FrameMan.PlayerScreenHeight - 10;
				elseif imenu.Cursors[self.Player].X > FrameMan.PlayerScreenWidth then
					imenu.Cursors[self.Player].X = FrameMan.PlayerScreenWidth - 10;
				end
			end
		end

		return true;
	end
end

function imenu:DrawCursor()
	PrimitiveMan:DrawBitmapPrimitive(self.Screen, CameraMan:GetOffset(self.Screen) + imenu.Cursors[self.Player] + Vector(5, 5), self.Cursor_Bitmap, 0);
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