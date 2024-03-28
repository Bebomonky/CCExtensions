_G["ExtensionMan"] = {}
ExtensionMan.EnableDebugPrinting = false

local mod_PREFIX = "[EXTENSIONMAN] "
local warn_PREFIX = mod_PREFIX .. "[WARN] "
local notice_PREFIX = " \xD5 "
function ExtensionMan.print_debug(...)if ExtensionMan.EnableDebugPrinting then ConsoleMan:PrintString(...)end end
function ExtensionMan.print_success(...)ConsoleMan:PrintString(... .. " \xD6")end
function ExtensionMan.print_done(...)ConsoleMan:PrintString(... .. " - done! \xD6")end
function ExtensionMan.print_warn(...)local t = ConsoleMan:PrintString(warn_PREFIX .. "\xBF " .. ... .. " \xBE") return t end
function ExtensionMan.print_notice(txt, ...)ConsoleMan:PrintString(tostring(...) .. notice_PREFIX .. txt or "") end

--DO NOT TOUCH THIS!
--Cleaner versions can be found in util

--verify file existance
local function verify(v)if v[2]then return v.onSuccess(v[1])end;return v.onError(v[1])end

--Add files based off Directories
local function basefile(p,oS,oE)local fe={p,LuaMan:FileExists(p)}fe.onSuccess=function(f)if oS then oS(f)end;end;fe.onError=function(f)if oE then oE(f)end;end;verify(fe)end

--Go Through Directories
local function basedir(rte,dir)for f in LuaMan:GetFileList(dir)do if string.find(f,".lua")then basefile(dir..f,function(dir)if dir then require(dir:gsub("Data/"..rte.."/",""):gsub("%.lua$",""))end end)end end;for d in LuaMan:GetDirectoryList(dir)do if d~=""then basedir(rte,dir..d.."/")end end end

--Start Extension Process
local function base_ext(rte,dir)basedir(rte,"Data/"..rte.."/"..dir)end;base_ext("Base.rte","Extensions/lua/")