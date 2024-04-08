module("util", package.seeall)

--[[---------------------------------------------------------
	Prints a table to the console
-----------------------------------------------------------]]
function PrintTable( t, indent, done )

	done = done or {}
	indent = indent or 0
	local keys = table.GetKeys( t )

	table.sort( keys, function( a, b )
		if ( type( a ) == "number" and type( b ) == "number" ) then return a < b end
		return tostring( a ) < tostring( b )
	end )

	done[ t ] = true

	for i = 1, #keys do
		local key = keys[ i ]
		local value = t[ key ]

		if  ( type( value ) == "table" and not done[ value ] ) then

			done[ value ] = true
			ConsoleMan:PrintString( "\t " .. key .. ":" )
			PrintTable ( value, indent + 2, done )
			done[ value ] = nil

		else

			ConsoleMan:PrintString( key .. "\t=\t" .. tostring( value ) )

		end

	end

end

--[[---------------------------------------------------------
	Returns a random vector
-----------------------------------------------------------]]
function VectorRand( min, max )
	min = min or -1
	max = max or 1
	return Vector( math.Rand( min, max ), math.Rand( min, max ) )
end

--[[---------------------------------------------------------
	Returns a random angle
-----------------------------------------------------------]]
function AngleRand( min, max )
	return math.Rand( min or -90, max or 90 ), math.Rand( min or -180, max or 180 )
end

--[[---------------------------------------------------------
	Returns a random color
-----------------------------------------------------------]]
function ColorRand()

	return math.random( 0, 255 )
end

--[[---------------------------------------------------------
	AccessorFunc
	Quickly make Get/Set accessor fuctions on the specified table
-----------------------------------------------------------]]
function AccessorFunc( tab, varname, name, iForce )

	if ( not tab ) then return debug.traceback(tostring(tab)) end

	tab[ "Get" .. name ] = function( self ) return self[ varname ] end

	if ( iForce == "FORCE_STRING" or iForce == 1 ) then
		tab[ "Set" .. name ] = function( self, v ) self[ varname ] = tostring( v ) end
	return end

	if ( iForce == "FORCE_NUMBER" or iForce == 2 ) then
		tab[ "Set" .. name ] = function( self, v ) self[ varname ] = tonumber( v ) end
	return end

	if ( iForce == "FORCE_BOOL" or iForce == 3 ) then
		tab[ "Set" .. name ] = function( self, v ) self[ varname ] = tobool( v ) end
	return end

	if ( iForce == "FORCE_VECTOR" or iForce == 4 ) then
		tab[ "Set" .. name ] = function( self, v ) self[ varname ] = Vector(v.X, v.Y) end
	return end

	tab[ "Set" .. name ] = function( self, v ) self[ varname ] = v end

end

--[[---------------------------------------------------------
	Returns the entitys ClassName.
	Don't use this if you want to do something like ToMOSRotatng()
-----------------------------------------------------------]]
function ToEntity(entity)
	if not entity.ClassName then return end
	return _G[ "To" .. entity.ClassName ]( entity )
end

--[[---------------------------------------------------------
	Simple lerp
-----------------------------------------------------------]]
function Lerp( delta, from, to )

	if ( delta > 1 ) then return to end
	if ( delta < 0 ) then return from end

	return from + ( to - from ) * delta

end

--[[---------------------------------------------------------
	Convert Var to Bool
-----------------------------------------------------------]]
function tobool( val )
	if ( val == nil or val == false or val == 0 or val == "0" or val == "false" ) then return false end
	return true
end

--[[---------------------------------------------------------
	Given a number, returns the right 'th
-----------------------------------------------------------]]
local STNDRD_TBL = { "st", "nd", "rd" }
function STNDRD( num )
	num = num % 100
	if ( num > 10 and num < 20 ) then
		return "th"
	end

	return STNDRD_TBL[ num % 10 ] or "th"
end

--[[---------------------------------------------------------
	Is module mounted?
-----------------------------------------------------------]]
function IsMounted( name )
	if PresetMan:GetModuleID(name .. ".rte") then return true end
	return false
end

--[[---------------------------------------------------------
	Replacement for C++'s iff ? aa : bb
-----------------------------------------------------------]]
function Either( iff, aa, bb )
	if ( iff ) then return aa end
	return bb
end

--[[---------------------------------------------------------
	Verify sent value to then decide if it was successful or not
-----------------------------------------------------------]]

--Cleaner Version from ExtensionMan
function Verify( value )
	if value[2] then
		return value.onSuccess( value[1] )
	end
	return value.onError( value[1] )
end

--[[---------------------------------------------------------
	Checking for file existance
	when true onSuccess function will run
	when false onError function will run

	Verify file to then decide if it was successful or not
-----------------------------------------------------------]]
function AddFile( path, onSuccess, onError )
	local fileExists = { path, LuaMan:FileExists( path ) }

	fileExists.onSuccess = function( file )
		if ( onSuccess ) then
			onSuccess( file )
		end
		if ExtensionMan.EnableDebugPrinting then
			ExtensionMan.print_success( file:match("[^/]+%.lua$"):gsub( ".lua", "" ) .. " - done!" )
		end
	end

	fileExists.onError = function( file )
		if ( onError ) then
			onError( file )
		end
		ExtensionMan.print_warn( "failed to load " .. file:match("[^/]+%.lua$") .. ". Skipping..." )
	end

	Verify( fileExists )
end

--[[---------------------------------------------------------
	Go through all the directories on the initial path
	Looks for all lua files that will be loaded
	Subtracts directory structure [require cannot have direct paths]
	1: module.rte
	2: .lua for file
-----------------------------------------------------------]]

function AddDir( loadtype, modulename, directory )

	for folder in LuaMan:GetDirectoryList(directory) do
		if folder ~= "" then
			AddDir( loadtype, modulename, directory .. folder .. "/" )
		end
	end

	for file in LuaMan:GetFileList( directory ) do
		if string.EndsWith( file, ".lua" ) then
			AddFile( directory .. file,
			function( dir )
				if ( dir ) then
					if loadtype == "require" then
						require( dir:gsub( "Mods/" .. modulename .. "/", "" ):gsub( "%.lua$", "" ) )
					elseif loadtype == "dofile" then
						dofile(dir)
					else
						ExtensionMan.print_warn("Failed to retrieve load type!")
					end
				end
			end)
		end
	end
end

--[[---------------------------------------------------------
	loadtype is either dofile or require
	modulename is your rte folder
	list your directory within the mod
-----------------------------------------------------------]]
function LoadExtension( loadtype, modulename, directory )
	ExtensionMan.print_notice("loading", "Locating Extensions: " .. modulename)
	AddDir( loadtype, modulename, "Mods/" .. modulename .. "/" .. directory ) 
	ExtensionMan.print_success( "All Extensions loaded!" )
end