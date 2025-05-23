
--[[
=head1 NAME

applets.JLCustomClock.JLCustomClockApplet - Clock screensaver with customizable graphics

=head1 DESCRIPTION

Custom Clock is a screen saver for Squeezeplay. It is customizable so you can choose among
a number of different graphics and information to show

=head1 FUNCTIONS

Applet related methods are described in L<jive.Applet>. JLCustomClockApplet overrides the
following methods:

=cut
--]]


-- stuff we use
local pairs, ipairs, tostring, tonumber, setmetatable, package, type = pairs, ipairs, tostring, tonumber, setmetatable, package, type

local oo               = require("loop.simple")
local os               = require("os")
local io               = require("io")
local math             = require("math")
local string           = require("jive.utils.string")
local table            = require("jive.utils.table")
local zip              = require("zipfilter")
local lxp              = require("lxp")

local datetime         = require("jive.utils.datetime")

local Applet           = require("jive.Applet")
local Window           = require("jive.ui.Window")
local Group            = require("jive.ui.Group")
local Label            = require("jive.ui.Label")
local Canvas           = require("jive.ui.Canvas")
local Icon             = require("jive.ui.Icon")
local Textarea         = require("jive.ui.Textarea")
local Font             = require("jive.ui.Font")
local Tile             = require("jive.ui.Tile")
local Popup            = require("jive.ui.Popup")
local Surface          = require("jive.ui.Surface")
local Framework        = require("jive.ui.Framework")
local SimpleMenu       = require("jive.ui.SimpleMenu")
local RadioGroup       = require("jive.ui.RadioGroup")
local RadioButton      = require("jive.ui.RadioButton")
local Timer            = require("jive.ui.Timer")

-- TEC 
-- Looks like CustomVUMeter and CustomSpectrumMeter require "squeezeplay.decode"
--    Since squeezelite/jivelite not same, may have to find equivalent? Is there a "squeezelite.decode"?
-- TEC1 local CustomVUMeter    = require("applets.CustomClock.CustomVUMeter")
-- TEC1 local CustomSpectrumMeter    = require("applets.CustomClock.CustomSpectrumMeter")

local SocketHttp       = require("jive.net.SocketHttp")
local RequestHttp      = require("jive.net.RequestHttp")
local json             = require("cjson")

local debug            = require("jive.utils.debug")

local ltn12            = require("ltn12")
local lfs              = require("lfs")
local socket           = require("socket")
local iconbar          = iconbar
local appletManager    = appletManager
local jiveMain         = jiveMain
local jnt              = jnt
local jive             = jive

local WH_FILL           = jive.ui.WH_FILL
local LAYOUT_NORTH      = jive.ui.LAYOUT_NORTH
local LAYOUT_SOUTH      = jive.ui.LAYOUT_SOUTH
local LAYOUT_CENTER     = jive.ui.LAYOUT_CENTER
local LAYOUT_WEST       = jive.ui.LAYOUT_WEST
local LAYOUT_EAST       = jive.ui.LAYOUT_EAST
local LAYOUT_NONE       = jive.ui.LAYOUT_NONE

module(..., Framework.constants)
oo.class(_M, Applet)

local html_tags = {
	["br"] = '\n',
	["/br"] = '\n',
	["li"] = '',
	["/li"] = '',
	["ul"] = "",
	["/ul"] = "",
	["ol"] = "",
	["/ol"] = "",
	["img"] = '',
	["/tr"] = '',
	["pre"] = "",
	["/pre"] = "",
	["b"] = "*",
	["/b"] = "*",
	["i"] = "/",
	["/i"] = "/",
	["big"] = "",
	["/big"] = "",
	["small"] = "",
	["/small"] = "",
	["strong"] = "*",
	["/strong"] = "*",
	["em"] = "/",
	["/em"] = "/",
	["u"] = "",
	["/u"] = "",
	["div"] = "",
	["/div"] = "",
	["html"] = "",
	["/html"] = "",
	["head"] = "",
	["/head"] = "",
	["body"] = "",
	["/body"] = "",
	["p"] = "",
	["/p"] = "",
	["a"] = "",
	["/a"] = "",
	["hr"] = "\n" .. string.rep("-",44) .. "\n",
	["font"] = "",
	["/font"] = "",
	["!doctype"] = "",
	["void"] = "",
	["/void"] = "",
	["comment"] = "",
	["/comment"] = "",
	["style"] = "",
	["/style"] = "",
	["meta"] = "",
	["tr"] = "",
	["td"] = "\t",
	["/td"] = "",
	["table"] = "",
	["/table"] ="",
	["th"] = "",
	["/th"] = "",
}

local html_coded = {

	["szlig"]	= "ß",
	["Ntilde"]	= "Ñ",
	["ntilde"]	= "ñ",
	["Ccedil"]	= "Ç",
	["ccedil"]	= "ç",
	
	["auml"]	= "ä",
	["euml"]	= "ë",
	["iuml"]	= "ï",
	["ouml"]	= "ö",
	["uuml"]	= "ü",
	["Auml"]	= "Ä",
	["Euml"]	= "Ë",
	["Iuml"]	= "Ï",
	["Ouml"]	= "Ö",
	["Uuml"]	= "Ü",
	["aacute"]	= "á",
	["eacute"]	= "é",
	["iacute"]	= "í",
	["oacute"]	= "ó",
	["uacute"]	= "ú",
	["Aacute"]	= "Á",
	["Eacute"]	= "É",
	["Iacute"]	= "Í",
	["Oacute"]	= "Ó",
	["Uacute"]	= "Ú",
	["acirc"]	= "â",
	["ecirc"]	= "ê",
	["icirc"]	= "î",
	["ocirc"]	= "ô",
	["ucirc"]	= "û",
	["Acirc"]	= "Â",
	["Ecirc"]	= "Ê",
	["Icirc"]	= "Î",
	["Ocirc"]	= "Ô",
	["Ucirc"]	= "Û",
	["agrave"]	= "à",
	["igrave"]	= "ì",
	["egrave"]	= "è",
	["ograve"]	= "ò",
	["ugrave"]	= "ù",
	["Agrave"]	= "À",
	["Igrave"]	= "Ì",
	["Egrave"]	= "È",
	["Ograve"]	= "Ò",
	["Ugrave"]	= "Ù",

	["euro"]	= '',
	["pound"]	= '£',
	["yen"]		= '¥',
	["cent"]	= '¢',
	["iquest"]	= '¿',
	["iexcl"]	= '¡',
	["quot"]	= '"',
	["lt"]		= '<',
	["gt"]		= '>',
	["nbsp"]	= ' ',
	["amp"]		= '&',
	["ndash"]       = '-',
        ["mdash"]       = '—',
}

local html_coded_numeric = {
	["8230"]	= '…',
	["8217"]	= '’',
	["8212"]	= '—',
	["8220"]	= '“',
	["8221"]	= '”',
}

----------------------------------------------------------------------------------------
-- Helper Functions
--

-- display
-- the main applet function, the meta arranges for it to be called
-- by the ScreenSaversApplet.
function openScreensaver1(self)
	self:openScreensaver("config1")
end
function openScreensaver2(self)
	local licensed = true
	if licensed then
		self:openScreensaver("config2")
	else
		self:openScreensaver("config1")
	end
end
function openScreensaver3(self)
	local licensed = true
	if licensed then
		self:openScreensaver("config3")
	else
		self:openScreensaver("config1")
	end
end
function openScreensaver4(self)
	local licensed = true
	if licensed then
		self:openScreensaver("config4")
	else
		self:openScreensaver("config1")
	end
end
function openScreensaver5(self)
	local licensed = true
	if licensed then
		self:openScreensaver("config5")
	else
		self:openScreensaver("config1")
	end
end
function openScreensaver6(self)
	local licensed = true
	if licensed then
		self:openScreensaver("config6")
	else
		self:openScreensaver("config1")
	end
end
function openScreensaver7(self)
	local licensed = true
	if licensed then
		self:openScreensaver("config7")
	else
		self:openScreensaver("config1")
	end
end
function openScreensaver8(self)
	local licensed = true
	if licensed then
		self:openScreensaver("config8")
	else
		self:openScreensaver("config1")
	end
end
function openScreensaver9(self)
	local licensed = true
	if licensed then
		self:openScreensaver("config9")
	else
		self:openScreensaver("config1")
	end
end
function goNowPlaying(self, transition)
	local licensed = true
	if licensed then
		self:openScreensaver("confignowplaying",transition)
	else
		self:openScreensaver("config1",transition)
	end
end
function openCustomClockAlarmWindow(self)
	local licensed = true
	if licensed then
		self:openScreensaver("configalarmactive")
	else
		self:openScreensaver("config1",transition)
	end
end
function openMenu(self,transition)
	local window = Window("text_list",self:string("SCREENSAVER_CUSTOMCLOCK"), 'settingstitle')
	self.customItemTypes = self:getSettings()["customitemtypes"]
	local licensed = true

	local menu = SimpleMenu("menu")
	if not licensed then
		menu:setHeaderWidget(Textarea("help_text", self:string("SCREENSAVER_CUSTOMCLOCK_SETTINGS_UNLICENSED")))
	end
	for i = 1,9 do
		local name = self:getSettings()["config"..i.."style"];
		if _getString(name,nil) and licensed then
			menu:addItem(
				{
					text = name, 
					sound = "WINDOWSHOW",
					callback = function(event, menuItem)
						self:openScreensaver("config"..i)
						return EVENT_CONSUME
					end
				})
		end
	end
        if licensed and menu:numItems() == 0 then
                menu:addItem( {
                        text = "No styles configured", 
                        iconStyle = 'item_no_arrow',
                        weight = 2
                })

	end
	window:addWidget(menu)
	self:tieAndShowWindow(window)
end

function openScreensaver(self,mode, transition)

	log:debug("Open screensaver "..tostring(mode))
	local player = appletManager:callService("getCurrentPlayer")
	local oldMode = self.mode
	self.mode = mode
	local licensed = true
	if ((oldMode and self.mode != oldMode) or self.licensed~=licensed) and self.window then
		self.window:hide()
		self.window = nil
	end
	self.licensed = licensed

	if mode != "configalarmactive" then
		self.prevmode = nil
	end
	self.titleformats = {}
	self.customtitleformats = {}
	if player then
		player:unsubscribe('/slim/customclocktitleformatsupdated')
		player:unsubscribe('/slim/customclockchangedstyles')
		player:unsubscribe('/slim/SuperDateTimeState/dataRefreshState')
		player:unsubscribe('/slim/customclockchangedcustomitems')
		player:subscribe(
			'/slim/customclockchangedstyles',
			function(chunk)
				if not chunk.data[1] or chunk.data[1] ~= "customclockchangedstyles" then
					return
				end
				for i,entry in pairs(chunk.data[2]) do
					local updateStyle = false
					local updatedModes = {}
					for attribute,value in pairs(self:getSettings()) do
						local correctModel = false
						for attribute,value in pairs(entry) do
							if attribute == "models" then
								for _,model in ipairs(value) do
									if model == self.model then
										correctModel = true
										break
									end
								end
							end
						end
						if correctModel and string.find(attribute,"style$") and self:getSettings()[attribute] == entry.name then
							log:debug("Updating "..attribute.."="..tostring(value))
							local config = string.gsub(attribute,"style$","")
							updatedModes[config]=true
							for attribute,value in pairs(self:getSettings()) do
								if string.find(attribute,"^"..config) and attribute != config.."style" then
									self:getSettings()[attribute] = nil
								end
							end
							for attribute,value in pairs(entry) do
								self:getSettings()[config..attribute] = value
							end
							if self.images then
								for attribute,value in pairs(self.images) do
									if string.find(attribute,"^"..config) then
										self.images[attribute] = nil
									end
								end
							end
							updateStyle = true
						else
							log:debug("Ignoring "..attribute.."="..tostring(value))
						end
					end
					if updateStyle then
						log:debug("Storing modified styles")
						self:_storeSettingsWithoutCache()
						if updatedModes[mode] and self.window then
							log:debug("Reopening screen saver with mode: "..mode)
							self.window:hide()
							self.window=nil
							self:openScreensaver(mode)
						end
					end
				end

			end,
			player:getId(),
			{'customclockchangedstyles'}
		)
		player:subscribe(
			'/slim/SuperDateTimeState/dataRefreshState',
			function(chunk)
				if not chunk.data[1] or chunk.data[1] ~= "SuperDateTimeState" or not chunk.data[2] or chunk.data[2] ~= "dataRefreshState" then
					return
				end
				if chunk.data[3] and chunk.data[3]["state"] and (chunk.data[3]["state"] == "Success" or chunk.data[3]["state"] == "Errors") then
					local updatesdtitems = {}
					local no = 1
					for _,item in pairs(self.configItems) do
						local category = nil
						local selectionattribute = nil
						if string.find(item.itemtype,"^sdtsport") then
							category = "sport"
							selectionattribute = category
						elseif string.find(item.itemtype,"^sdtstock") then
							category = "stocks"
							selectionattribute = "stock"
						elseif string.find(item.itemtype,"^sdtmisc") and _getString(item.infotype,nil) then
							category = item.infotype
							selectionattribute = "selected"
						elseif string.find(item.itemtype,"^sdtweathericon") or string.find(item.itemtype,"^sdtweathertext") or item.itemtype == "sdticon" then
							category = "weather"
							selectionattribute = "period"
						elseif item.itemtype == "sdttext" then
							log:debug("Refreshing sdttext:".._getString(item.period,"-1")..",".._getString(item.sdtformat,""))
							self:_updateSDTText(self.items[no],no,item.sdtformat,item.period)
						end
	
						if category then
							if not updatesdtitems[category] then
								updatesdtitems[category] = {
									attribute = selectionattribute,
									items = {}
								}
							end
							updatesdtitems[category].items[no] = item
						end
						no = no + 1
					end
					for category,data in pairs(updatesdtitems) do
						log:debug("Refreshing sdt item for category:"..category)
						if category == "sport" then
							self:_updateSDTSportItem(data.items)
						elseif category == "weather" then
							self:_updateSDTWeatherItem(data.items)
						else
							self:_updateSDTMiscItem(category,data.items,data.attribute)
						end
					end
				elseif chunk.data[3] and chunk.data[3]["state"] and chunk.data[3]["state"] == "MapRefreshSuccess" then
					log:debug("Ignoring SuperDateTime map refresh event="..tostring(chunk.data[3]["state"]))
				elseif chunk.data[3] and chunk.data[3]["state"] and chunk.data[3]["state"] == "Refreshing" then
					log:debug("Ignoring SuperDateTime refresh start event")
				else
					log:warn("Uknown SuperDateTime event state="..tostring(chunk.data[3]["state"]))
				end 
			end,
			player:getId(),
			{'SuperDateTimeState','dataRefreshState'}
		)
		player:subscribe(
			'/slim/customclockchangedcustomitems',
			function(chunk)
				if not chunk.data[1] or chunk.data[1] ~= "customclockchangedcustomitems" then
					return
				end
				local categories = {}
				for _,item in ipairs(chunk.data[2]) do
					categories[item] = item
				end
				if categories then
					local updatepluginitems = {}
					local no = 1
					for _,item in pairs(self.configItems) do
						local category = nil
						if string.find(item.itemtype,"^plugin") and item.infotype and categories[item.infotype] then
							category = item.infotype
						end
	
						if category then
							if not updatepluginitems[category] then
								updatepluginitems[category] = {
									items = {}
								}
							end
							updatepluginitems[category].items[no] = item
						end
						no = no + 1
					end
					for category,data in pairs(updatepluginitems) do
						log:debug("Refreshing plugin item for category:"..category)
						self:_updatePluginItem(category,data.items)
					end
				end 
			end,
			player:getId(),
			{'customclockchangedcustomitems'}
		)
		player:subscribe(
			'/slim/customclocktitleformatsupdated',
			function(chunk)
				if not chunk.data[1] or chunk.data[1] ~= "customclocktitleformatsupdated" then
					return
				end
				local player = appletManager:callService("getCurrentPlayer")
				if player then
					self:_checkAndUpdateTitleFormatInfo(player)
					self:_updateCustomTitleFormatInfo(player)
				end
			end,
			player:getId(),
			{'customclocktitleformatsupdated'}
		)
	end
        -- Create the main window if it doesn't already exist
	if not self.window then
		log:debug("Recreating screensaver window")
		local width,height = Framework.getScreenSize()
		if width == 480 then
			self.model = "touch"
		elseif width == 320 then
			self.model = "radio"
		else
			self.model = "controller"
		end

		self.window = Window("window")
		self.configItems = self:getSettings()[self.mode.."items"]
		if not self.configItems then
			self.configItems = {
				{
					itemtype = "text",
					fontsize = 20,
					posy = 50,
					text = "Not configured"
				}
			}
		end
		self.window:setSkin(self:_getClockSkin(jiveMain:getSelectedSkin()))
		self.window:reSkin()
		self.window:setShowFrameworkWidgets(false)

		self.items = {}
		local no = 1
		self.switchingNowPlaying = false
		self.visibilityGroups = {}
		self.sdtcache = {}
		self.pluginitemcache = {}
		self.rssitemcache = {}
		for _,item in pairs(self.configItems) do
			if _getString(item.visibilitygroup,nil) then
				if not self.visibilityGroups[item.visibilitygroup] then
					self.visibilityGroups[item.visibilitygroup] = {}
					self.visibilityGroups[item.visibilitygroup].current = 0
					self.visibilityGroups[item.visibilitygroup].items = {}
				end
				local idx = #self.visibilityGroups[item.visibilitygroup].items + 1
				self.visibilityGroups[item.visibilitygroup].items[idx] = {}
				self.visibilityGroups[item.visibilitygroup].items[idx].item = no
				self.visibilityGroups[item.visibilitygroup].items[idx].delay = _getNumber(item.visibilitytime,1)	
				self.visibilityGroups[item.visibilitygroup].items[idx].order = _getNumber(item.visibilityorder,100+idx)	
			end
			if string.find(item.itemtype,"^switchingtrack") then
				self.switchingNowPlaying = true
			end
			if string.find(item.itemtype,"text$") then
				local childItems = {
					itemno = Label("item"..no,"")
				}
				self.items[no] = Group("item"..no,childItems)
				self.window:addWidget(self.items[no])
			elseif string.find(item.itemtype,"icon$") then
				local childItems = {
					itemno = Icon("item"..no)
				}
				self.items[no] = Group("item"..no,childItems)
				self.window:addWidget(self.items[no])
-- TEC1			elseif string.find(item.itemtype,"digitalvumeter$") then
-- TEC1				local childItems = {
-- TEC1					itemno = CustomVUMeter("item"..no,"digital",_getString(item.channels,nil))
-- TEC1				}
-- TEC1				self.items[no] = Group("item"..no,childItems)
-- TEC1				self.window:addWidget(self.items[no])
-- TEC1			elseif string.find(item.itemtype,"analogvumeter$") then
-- TEC1				local childItems = {
-- TEC1					itemno = CustomVUMeter("item"..no,"analog",_getString(item.channels,nil))
-- TEC1				}
-- TEC1				self.items[no] = Group("item"..no,childItems)
-- TEC1				self.window:addWidget(self.items[no])
-- TEC1			elseif string.find(item.itemtype,"spectrummeter$") then
-- TEC1				local childItems = {
-- TEC1					itemno = CustomSpectrumMeter("item"..no,_getString(item.channels,nil))
-- TEC1				}
				for attr,value in pairs(item) do
					if string.find(attr,"color$") and _getString(value,nil) then
						local color = string.gsub(attr,"color$","")
						childItems["itemno"]:setColor(color,_getColorNumber(value))
					end
					if string.find(attr,"^attr.") and _getNumber(value,nil) then
						local size = string.gsub(attr,"^attr.","")
						childItems["itemno"]:setAttr(size,tonumber(value))
					end
				end
				self.items[no] = Group("item"..no,childItems)
				self.window:addWidget(self.items[no])
			end
			no = no +1
		end
		for key,group in pairs(self.visibilityGroups) do
			group.items = self:_resortItems(group.items)
		end

		local backgroundItems = {
			background = Icon("background")
		}
		self.backgroundImage = Group("background",backgroundItems)
		self.wallpaperImage = Icon("wallpaper")

		self.canvas = Canvas('debug_canvas',function(screen)
				self:_reDrawAnalog(screen)
			end)
	
		local canvasItems = {
			canvas = self.canvas
		}
		local canvasGroup = Group("canvas",canvasItems)
		self.window:addWidget(self.backgroundImage)
		self.window:addWidget(canvasGroup)

		if mode == "configalarmactive" then
			self.window:setAllowScreensaver(false)
			self.window:addActionListener("power",self,function()
				self.window:hide()
				self.window = nil
				appletManager:callService("alarmOff",true)
				return EVENT_UNUSED
			end)
			self.window:addActionListener("back",self,function()
				self.window:hide()
				self.window = nil
				appletManager:callService("alarmOff",false)
				return EVENT_CONSUME
			end)
			self.window:addActionListener("mute",self,function()
				appletManager:callService("alarmSnooze",true)
				self.window:hide()
				self.window = nil
				if self.prevmode then
					self:openScreensaver(self.prevmode)
				end
				return EVENT_CONSUME
			end)

			self.window:ignoreAllInputExcept(
				--these actions are not ignored
				{ 'go', 'back', 'power', 'mute', 'volume_up', 'volume_down', 'pause' }, 
				-- consumeAction is the callback issued for all "ignored" input
				function()
					log:debug('Consuming this action')
					Framework:playSound("BUMP")
					window:bumpLeft()
					return EVENT_CONSUME
				end
			)
		else
			-- Register custom actions which we want to catch in the screen saver
			local showPlaylistAction = function (self)
				self.window:playSound("WINDOWSHOW")
				local player = appletManager:callService("getCurrentPlayer")
				if player then
					local playlistSize = player and player:getPlaylistSize()
					if playlistSize == 1 then
						appletManager:callService("showTrackOne")
					else
						appletManager:callService("showPlaylist")
					end
				end
				return EVENT_CONSUME
			end

			self.window:addActionListener("go", self, showPlaylistAction)
			self.window:addActionListener("go_now_playing_or_playlist", self, showPlaylistAction)
			self.window:addActionListener("go_home", self, function(self)
				appletManager:callService("goHome")
				return EVENT_CONSUME
			end)
			self.window:addActionListener("add", self, function(self)
				appletManager:callService("showTrackOne")
				return EVENT_CONSUME
			end)
			for i=1,6 do
				local action = 'set_preset_'..tostring(i)
				self.window:addActionListener(action, self, function()
					appletManager:callService("setPresetCurrentTrack",i)
					return EVENT_CONSUME
				end)
			end
			if mode ~= "confignowplaying" then
				-- register window as a screensaver
				local manager = appletManager:getAppletInstance("ScreenSavers")
				manager:screensaverWindow(self.window,nil,{'go','go_home','go_now_playing_or_playlist','add','set_preset_1','set_preset_2','set_preset_3','set_preset_4','set_preset_5','set_preset_6'})
			end
		end

		self.window:addTimer(1000, function() self:_tick() end)
		self.offset = math.random(15)
		self.images = {}
		self.vumeterimages = {}
		self.referenceimages = {}
	end
	if player then
		self:_checkAndUpdateTitleFormatInfo(player)
		self:_updateCustomTitleFormatInfo(player)
	end
	self.sdtSuperDateTimeChecked = false
	self.sdtMacroChecked = false
	self.sdtVersionChecked = false
	self.sdtSongInfoChecked = false
	self.lastminute = 0
	self.lastsecond = 0
	self.secondoffset = 0
	self.nowPlaying = 1
	self:_tick(1)

	if not transition then
		transition = Window.transitionFadeIn
	end
	if self.window then
		-- Show the window
		self.window:show(transition)
		for no,item in pairs(self.configItems) do
			if string.find(item.itemtype,"text$") and _getString(item.animate,"true") == "true" then
				self.items[no]:getWidget("itemno"):animate(true)
			elseif not licensed and not item.free and (item.itemtype == "text" or string.find(item.itemtype,"timetext$") or string.find(item.itemtype,"track.*text$")) then
				self.items[no]:getWidget("itemno"):animate(true)
			end
		end
	end
end

function refreshCustomClockImageType(self,itemType)
	if not self.refreshCustomItemTypes then
		self.refreshCustomItemTypes = {}
	end
	self.refreshCustomItemTypes[itemType.."icon"] = true
end

function refreshCustomClockTextType(self,itemType)
	if not self.refreshCustomItemTypes then
		self.refreshCustomItemTypes = {}
	end
	self.refreshCustomItemTypes[itemType.."text"] = true
end

function addCustomClockImageType(self,itemType,applet,method,data)
	if not self.customItemTypes then
		self.customItemTypes = {}
	end

	self.customItemTypes[itemType.."icon"] = {
		data = data,
		applet = applet,
		method = method
	}
	self:getSettings()["customitemtypes"] = self.customItemTypes
	--We don't need to call self:storeSettings() it will just wast flash write cycles
end

function _storeSettingsWithoutCache(self)
	for attr,value in pairs(self:getSettings()) do
		if string.find(attr,"^itemCache") or string.find(attr,"Installed$") then
			self:getSettings()[attr] = nil
		end
	end
	self:storeSettings()
end

function addCustomClockTextType(self,itemType,applet,method,data)
	if not self.customItemTypes then
		self.customItemTypes = {}
	end

	self.customItemTypes[itemType.."text"] = {
		data = data,
		applet = applet,
		method = method
	}
	self:getSettings()["customitemtypes"] = self.customItemTypes
	--We don't need to call self:storeSettings() it will just wast flash write cycles
end

function _recalculateVisibilityTimes(self,items)
	local maxdelay = {}
	local nodelay = {}
	for no,item in pairs(items) do
		if not _getString(self.configItems[item.item].visibilitytime,nil) and _getString(self.configItems[item.item].interval,nil) then
			local results = nil
			if string.find(self.configItems[item.item].itemtype,"^sdtsport") then
				results = self:_getSDTCacheData("sport",self.configItems[item.item])
			elseif string.find(self.configItems[item.item].itemtype,"^sdtweathericon") or string.find(self.configItems[item.item].itemtype,"^sdtweathertext") then
				results = self:_getSDTCacheData("stocks",self.configItems[item.item])
			elseif string.find(self.configItems[item.item].itemtype,"^sdtstock") then
				results = self:_getSDTCacheData("stocks",self.configItems[item.item])
			elseif string.find(self.configItems[item.item].itemtype,"^sdtmisc") and _getString(self.configItems[item.item].infotype,nil) then
				results = self:_getSDTCacheData(self.configItems[item.item].infotype,self.configItems[item.item])
			elseif string.find(self.configItems[item.item].itemtype,"^plugin") and _getString(self.configItems[item.item].infotype,nil) then
				results = self:_getPluginItemCacheData(self.configItems[item.item].infotype,self.configItems[item.item])
			elseif string.find(self.configItems[item.item].itemtype,"^rss") and _getString(self.configItems[item.item].url,nil) then
				results = self:_getRSSItemCacheData(self.configItems[item.item].url,self.configItems[item.item])
			end
			if results then
				recalculated = true
				item.delay = tonumber(self.configItems[item.item].interval) * tonumber(#results)
				if not maxdelay[item.order] or maxdelay[item.order]<item.delay then
					log:debug("Recalculate visibility times order="..item.order..": "..tonumber(self.configItems[item.item].interval).."*"..tonumber(#results).."="..item.delay)
					maxdelay[item.order] = item.delay
				end
				if item.delay==0 then
					log:debug("Recalculate visibility times order="..item.order..": "..tonumber(self.configItems[item.item].interval).."*"..tonumber(#results).."="..item.delay)
					nodelay[item.order] = true
				end
			end
		end
	end
	for no,item in pairs(items) do
		if maxdelay[item.order] then
			item.delay = maxdelay[item.order]
		elseif nodelay[item.order] then
			item.delay = 0
		end
	end
end

function _resortItems(self,items)
	local sortedItems = {}
	for no,item in ipairs(items) do
		table.insert(sortedItems,item)
	end
	table.sort(sortedItems, function(a,b) 
		if a.order==b.order then 
			return a.delay<b.delay
		else
			return a.order<b.order 
		end
	end
	)
	return sortedItems
end

function closeScreensaver(self)
	if self.window then
		self.window:hide()
		self.window = nil
	end
end

function _updateVisibilityGroups(self)
	local now = socket.gettime()
	for key,group in pairs(self.visibilityGroups) do
		-- We need an extra 0.1 seconds because the timer triggering once per second isn't as accurate as socket.gettime()
		if not group.lastswitchtime or group.lastswitchtime+group.items[group.current].delay<now+0.1 then
			local previous = group.items[group.current]
			local restarted = false
			if group.current >= #group.items then
				group.current = 1
				restarted = true
				self:_recalculateVisibilityTimes(group.items)
				group.items = self:_resortItems(group.items)
				log:debug("Possibly switching to : "..key.."="..group.current.." with visibility time: "..group.items[group.current].delay)
			end
			if not restarted or (group.items[group.current].delay and group.items[group.current].delay==0 and group.current<#group.items) then
				local previousCurrent = group.current
				group.current = group.current + 1
				while group.current<=#group.items and ((previous and group.items[group.current].order==previous.order and group.items[group.current].delay==previous.delay) or (group.items[group.current].delay == 0 and previousCurrent!=group.current)) do
					group.current = group.current + 1
				end
				if group.current>#group.items then
					group.current = 1
					while (group.items[group.current].delay == 0 and previousCurrent!=group.current) do
						group.current = group.current + 1
					end
					self:_recalculateVisibilityTimes(group.items)
					group.items = self:_resortItems(group.items)
					log:debug("Switching to : "..key.."="..group.current.." with visibility time: "..group.items[group.current].delay)
				elseif previous and group.items[group.current].order==previous.order and group.items[group.current].delay>previous.delay then
					log:debug("Continue a while longer, decreasing visibility with :"..previous.delay)
					now = now-previous.delay
				else
					self:_recalculateVisibilityTimes(group.items)
					group.items = self:_resortItems(group.items)
					log:debug("Switching to : "..key.."="..group.current.." with visibility time: "..group.items[group.current].delay)
				end
			end
			group.lastswitchtime = now
			
			local currentorder = nil
			local currentdelay = nil
			for no,item in ipairs(group.items) do
				if (group.current == no or (currentorder and item.order==currentorder)) and item.delay>0 then
					currentorder = item.order
					if not self.items[item.item]:getWindow() then
						self.window:addWidget(self.items[item.item])
					end
				elseif self.items[item.item]:getWindow() then
					self.window:removeWidget(self.items[item.item])
				end
			end
		end
	end
end

function openSettings(self)
	log:debug("Custom Clock settings")
	local width,height = Framework.getScreenSize()
	if width == 480 then
		self.model = "touch"
	elseif width == 320 then
		self.model = "radio"
	elseif width == 800 then
		self.model = "jivelite800x480"
	else
		self.model = "controller"
	end

	self.settingsWindow = Window("text_list", self:string("SCREENSAVER_CUSTOMCLOCK_SETTINGS"), 'settingstitle')
	local licensed = true

	local menu = SimpleMenu("menu")
	if not licensed then
		menu:setHeaderWidget(Textarea("help_text", self:string("SCREENSAVER_CUSTOMCLOCK_SETTINGS_UNLICENSED")))
	end
	for i = 1,9 do
		local name = self:getSettings()["config"..i.."style"];
		if name then
			name = ": "..name
		else
			name = ""
		end
		if licensed or i==1 then
			menu:addItem(
				{
					text = tostring(self:string("SCREENSAVER_CUSTOMCLOCK_SETTINGS_CONFIG")).." #"..i..name, 
					sound = "WINDOWSHOW",
					callback = function(event, menuItem)
						self:defineSettingStyle("config"..i,menuItem)
						return EVENT_CONSUME
					end
				})
		else
			menu:addItem(
				{
					text = tostring(self:string("SCREENSAVER_CUSTOMCLOCK_SETTINGS_CONFIG")).." #"..i..": "..tostring(self:string("SCREENSAVER_CUSTOMCLOCK_NEEDS_LICENSE")),
					sound = "WINDOWSHOW",
					callback = function(event, menuItem)
						return EVENT_CONSUME
					end
				})
		end
	end	
	local name = self:getSettings()["confignowplayingstyle"];
	if name then
		name = ": "..name
	else
		name = ""
	end
	if licensed then
		menu:addItem(
			{
				text = tostring(self:string("SCREENSAVER_CUSTOMCLOCK_SETTINGS_NOWPLAYING"))..name, 
				sound = "WINDOWSHOW",
				callback = function(event, menuItem)
					self:defineSettingStyle("confignowplaying",menuItem)
					return EVENT_CONSUME
				end
			})
	end
	if licensed and appletManager:callService("isPatchInstalled","60a51265-1938-4fd7-b703-12d3725870da") then
		name = self:getSettings()["configalarmactivestyle"];
		if name then
			name = ": "..name
		else
			name = ""
		end
		menu:addItem(
			{
				text = tostring(self:string("SCREENSAVER_CUSTOMCLOCK_SETTINGS_ALARM_ACTIVE"))..name, 
				sound = "WINDOWSHOW",
				callback = function(event, menuItem)
					self:defineSettingStyle("configalarmactive",menuItem)
					return EVENT_CONSUME
				end
			})
	end

	local appletdir = _getAppletDir()
	if lfs.attributes(appletdir.."JLCustomClock/fonts") or lfs.attributes(appletdir.."JLCustomClock/images") then
		menu:addItem(
			{
				text = self:string("SCREENSAVER_CUSTOMCLOCK_SETTINGS_CLEAR_CACHE"), 
				sound = "WINDOWSHOW",
				callback = function(event, menuItem)
					os.execute("rm -rf \""..appletdir.."JLCustomClock/fonts\"")
					os.execute("rm -rf \""..appletdir.."JLCustomClock/images\"")
					self.settingsWindow:hide()
					self.settingsWindow = nil
					self:openSettings()
					return EVENT_CONSUME
				end
			})
	end

--	menu:addItem(
--		{
--			text = self:string("SCREENSAVER_CUSTOMCLOCK_SETTINGS_ALARM"), 
--			sound = "WINDOWSHOW",
--			callback = function(event, menuItem)
--				self:defineSettingStyle("configalarm",menuItem)
--				return EVENT_CONSUME
--			end
--		})
	self.settingsWindow:addWidget(menu)
	self:tieAndShowWindow(self.settingsWindow)
	return self.settingsWindow
end

function init(self)
	jnt:subscribe(self)
	self.titleformats = self.titleformats or {}
	self.customtitleformats = self.customtitleformats or {}
end

function _installCustomNowPlaying(self)
	-- We need to delay this a bit so standard Now Playing applet gets to do its stuff first
	local timer = Timer(100, function() 
			local item = jiveMain:getMenuItem('appletNowPlaying')
			if item then
				log:debug("Setting custom callback to Now Playing menu")
				item.callback = function(event, menuItem)
					self:goNowPlaying(Window.transitionPushLeft)
				end
			end
		end,
		true)
	timer:start()
end

function notify_playerCurrent(self,player)
	if self:getSettings()["confignowplayingstyle"] then
		self:_installCustomNowPlaying()
	end
end

function notify_playerTrackChange(self,player,nowPlaying)
	self:_checkAndUpdateTitleFormatInfo(player)
	self:_updateSongInfoIcons(player)
end

function _updateSongInfoIcons(self,player)
	if self.configItems then
		local width,height = Framework.getScreenSize()
		for no,item in pairs(self.configItems) do
			if item.itemtype == "songinfoicon" then
				self:_updateSongInfoIcon(self.items[no],no,_getNumber(item.width,width),_getNumber(item.height,height),item.songinfomodule,"true",_getString(item.allowproxy,"true"))
			end
		end
	end
end

function _checkAndUpdateTitleFormatInfo(self,player)
	local requestData = false
	if self.configItems then
		for _,item in pairs(self.configItems) do
			if string.find(item.itemtype,"^track") and string.find(item.itemtype,"text$") then
				if string.find(item.text,"BAND") or string.find(item.text,"COMPOSER") or string.find(item.text,"CONDUCTOR") or string.find(item.text,"ALBUMARTIST") or string.find(item.text,"TRACKARTIST") or string.find(item.text,"TRACKNUM") or string.find(item.text,"DISC") or string.find(item.text,"DISCCOUNT") or string.find(item.text,"RATING")then
					requestData = true
					break
				end
			elseif item.itemtype == "ratingicon" or item.itemtype == "ratingplayingicon" or item.itemtype == "ratingstoppedicon" then
				requestData = true
				break
			end
		end	
		if requestData then
			log:debug("Track changed, updating extended title formats")
			self:_updateTitleFormatInfo(player)
		else
			log:debug("Track changed but extended title formats doesn't have to be updated")
		end
	end
end

function _updateCustomTitleFormatInfo(self,player)
	local server = player:getSlimServer()
	if server and not server:isSqueezeNetwork() then
		local licensed = true
		if not self:getSettings()['customClockHelperInstalled'] then
			server:userRequest(function(chunk,err)
					if err then
						log:warn(err)
					else
						if tonumber(chunk.data._can) == 1 then
							self:getSettings()['customClockHelperInstalled'] = true
							self:_updateCustomTitleFormatInfo(player)
						else
							self:getSettings()['customClockHelperInstalled'] = false
						end
					end
				end,
				player and player:getId(),
				{'can','customclock','titleformats','?'}
			)
		else
				server:userRequest(function(chunk,err)
						if err then
							log:warn(err)
						else
							self.customtitleformats = chunk.data.titleformats
							for attribute,value in pairs(self.customtitleformats) do
								log:debug("Title format: "..tostring(attribute).."="..tostring(value))
								if not licensed then
									self.customtitleformats[attribute] = tostring(self:string("SCREENSAVER_CUSTOMCLOCK_NEEDS_LICENSE"))
								end
							end
						end
					end,
					player and player:getId(),
					{'customclock','titleformats'}
				)
		end
	end
end

function _updateTitleFormatInfo(self,player)
	local server = player:getSlimServer()
	if server then
		server:userRequest(function(chunk,err)
				if err then
					log:warn(err)
				else
					local index = chunk.data.playlist_cur_index
					local licensed = true
					if index and chunk.data.playlist_loop[index+1] and licensed then
						self.titleformats["BAND"] = chunk.data.playlist_loop[index+1].band
						self.titleformats["COMPOSER"] = chunk.data.playlist_loop[index+1].composer
						self.titleformats["CONDUCTOR"] = chunk.data.playlist_loop[index+1].conductor
						self.titleformats["TRACKARTIST"] = chunk.data.playlist_loop[index+1].trackartist
						self.titleformats["ALBUMARTIST"] = chunk.data.playlist_loop[index+1].albumartist
						self.titleformats["RATING"] = chunk.data.playlist_loop[index+1].rating
						self.titleformats["TRACKNUM"] = chunk.data.playlist_loop[index+1].tracknum
						self.titleformats["DISC"] = chunk.data.playlist_loop[index+1].disc
						self.titleformats["DISCCOUNT"] = chunk.data.playlist_loop[index+1].disccount
					else
						self.titleformats = {}
					end
				end
			end,
			player and player:getId(),
			{'status','0','100','tags:AtiqR'}
		)
	end
end

function defineSettingStyle(self,mode,menuItem)
	
	local player = appletManager:callService("getCurrentPlayer")
	local licensed = true
	if player then
		local server = player:getSlimServer()
		if server and not server:isSqueezeNetwork() then
			server:userRequest(function(chunk,err)
					if err then
						log:warn(err)
					else
						if licensed and tonumber(chunk.data._can) == 1 then
							log:info("CustomClockHelper is installed retrieving local styles")
							server:userRequest(function(chunk,err)
									if err then
										log:warn(err)
									else
										self:defineSettingStyleSink(menuItem.text,mode,chunk.data)
									end
								end,
								player and player:getId(),
								{'customclock','styles'}
							)
						else
							log:debug("CustomClockHelper isn't installed retrieving online styles")
							self:_getOnlineStylesSink(menuItem.text,mode)
						end
					end
				end,
				player and player:getId(),
				{'can','customclock','styles','?'}
			)
	
			-- create animiation to show while we get data from the server
			local popup = Popup("waiting_popup")
			local icon  = Icon("icon_connecting")
			local label = Label("text", self:string("SCREENSAVER_CUSTOMCLOCK_SETTINGS_FETCHING"))
			popup:addWidget(icon)
			popup:addWidget(label)
			self:tieAndShowWindow(popup)

			self.popup = popup
		else
			log:debug("Server not available retrieving online styles")
			self:_getOnlineStylesSink(menuItem.text,mode)
		end
	else
		log:debug("Player not selected retrieving online styles")
		self:_getOnlineStylesSink(menuItem.text,mode)
	end
end

function _getOnlineStylesSink(self,title,mode)
	if not self.popup then
		-- create animiation to show while we get data from the server
		local popup = Popup("waiting_popup")
		local icon  = Icon("icon_connecting")
		local label = Label("text", self:string("SCREENSAVER_CUSTOMCLOCK_SETTINGS_FETCHING"))
		popup:addWidget(icon)
		popup:addWidget(label)
		self:tieAndShowWindow(popup)

		self.popup = popup
	end
	local http = SocketHttp(jnt, "http://erland.github.io", 80)
	local req = RequestHttp(function(chunk, err)
			if err then
				log:warn(err)
			elseif chunk then
				chunk = json.decode(chunk)
				self:defineSettingStyleSink(title,mode,chunk.data)
			end
		end,
		'GET', "/squeezebox-customclock/clockstyles7.json")
	http:fetch(req)
end

function _uses(parent, value)
        if parent == nil then
                log:warn("nil parent in _uses")
        end
        local style = {}
        setmetatable(style, { __index = parent })
        for k,v in pairs(value or {}) do
                if type(v) == "table" and type(parent[k]) == "table" then
                        -- recursively inherrit from parent style
                        style[k] = _uses(parent[k], v)
                else
                        style[k] = v
                end
        end

        return style
end

function defineSettingStyleSink(self,title,mode,data)
	self.popup:hide()
	
	local style = self:getSettings()[mode.."style"]
	jive.ui.style.item_no_icon = _uses(jive.ui.style.item, {
		order = { 'text', 'check' },
	})
	jive.ui.style.icon_list.menu.item_no_icon = _uses(jive.ui.style.icon_list.menu.item, {
		order = { 'text', 'check' },
	})
	jive.ui.style.icon_list.menu.selected.item_no_icon = _uses(jive.ui.style.icon_list.menu.selected.item, {
		order = { 'text', 'check' },
	})
	jive.ui.style.icon_list.menu.pressed.item_no_icon = _uses(jive.ui.style.icon_list.menu.pressed.item, {
	})

	local window = Window("icon_list", title, 'settingstitle')
	local menu = SimpleMenu("menu")
	menu:setComparator(menu.itemComparatorWeightAlpha)
	local licensed = true
	if not licensed then
		menu:setHeaderWidget(Textarea("help_text", self:string("SCREENSAVER_CUSTOMCLOCK_LICENSE_MORE_STYLES")))
	end
	window:addWidget(menu)
	local group = RadioGroup()
	if mode == "confignowplaying" then
		menu:addItem({
			text = tostring(self:string("SCREENSAVER_CUSTOMCLOCK_SETTINGS_NOWPLAYING_STYLE")).."\n(Logitech)",
			style = 'item_no_icon',
			weight = 1,
			check = RadioButton(
				"radio",
				group,
				function()
					self:getSettings()[mode.."style"] = nil
					self:_storeSettingsWithoutCache()
					log:info("Changing to standard Now Playing applet")
					appletManager:registerService("NowPlaying",'goNowPlaying')
				end,
				style == nil
			),
		})
	elseif mode == "configalarmactive" then
		menu:addItem({
			text = tostring(self:string("SCREENSAVER_CUSTOMCLOCK_SETTINGS_NONE")).."\n(Logitech)",
			style = 'item_no_icon',
			weight = 1,
			check = RadioButton(
				"radio",
				group,
				function()
					self:getSettings()[mode.."style"] = nil
					self:_storeSettingsWithoutCache()
					appletManager:callService("registerAlternativeAlarmWindow",nil)
				end,
				style == nil
			),
		})
	else
		menu:addItem({
			text = tostring(self:string("SCREENSAVER_CUSTOMCLOCK_SETTINGS_NONE")),
			style = 'item_no_icon',
			weight = 1,
			check = RadioButton(
				"radio",
				group,
				function()
					for attribute,value in pairs(self:getSettings()) do
						if string.find(attribute,"^"..mode) then
							self:getSettings()[attribute] = nil
						end
					end
					if self.images then
						for attribute,value in pairs(self.images) do
							if string.find(attribute,"^"..mode) then
								self.images[attribute] = nil
							end
						end
					end
					if self.window then
						self.window:hide()
						self.window=nil
					end
					self:_storeSettingsWithoutCache()
					appletManager:callService("addScreenSaver", 
						tostring(self:string("SCREENSAVER_CUSTOMCLOCK")).."#"..string.gsub(mode,"^config",""), 
						"JLCustomClock",
						"openScreensaver"..string.gsub(mode,"^config",""), 
						self:string("SCREENSAVER_CUSTOMCLOCK_SETTINGS"), 
						"openSettings", 
						nil,
						"closeScreensaver")
				end,
				style == nil
			),
		})
	end

	local player = appletManager:callService("getCurrentPlayer")
	if player then
		local server = player:getSlimServer()
		if server then
			if data.item_loop then
				for _,entry in pairs(data.item_loop) do
					local isCompliant = true
					if entry.models then
						isCompliant = false
						for _,model in pairs(entry.models) do
							if model == self.model then
								isCompliant = true
							end
						end
					else
						log:debug("Supported on all models")
					end 
			
					if isCompliant and entry.name then
						local name = entry.name.."\n"
						if _getString(entry.contributors,nil) then
							name = name.."("..entry.contributors..")"
						end
						menu:addItem({
							text = name,
							style = 'item_no_icon',
							weight = 2,
							check = RadioButton(
								"radio",
								group,
								function()
									for attribute,value in pairs(self:getSettings()) do
										if string.find(attribute,"^"..mode) then
											self:getSettings()[attribute] = nil
										end
									end
									self:getSettings()[mode.."style"] = entry.name
									for attribute,value in pairs(entry) do
										self:getSettings()[mode..attribute] = value
									end
									if self.images then
										for attribute,value in pairs(self.images) do
											if string.find(attribute,"^"..mode) then
												self.images[attribute] = nil
											end
										end
									end
									if self.window then
										self.window:hide()
										self.window=nil
									end
									self:_storeSettingsWithoutCache()
									if mode == "confignowplaying" then
										log:info("Changing to custom Now Playing applet")
										appletManager:registerService("JLCustomClock",'goNowPlaying')
										self:_installCustomNowPlaying()
									elseif mode == "configalarmactive" then
										appletManager:callService("registerAlternativeAlarmWindow","openCustomClockAlarmWindow")
									else
										appletManager:callService("addScreenSaver", 
											tostring(self:string("SCREENSAVER_CUSTOMCLOCK")).."#"..string.gsub(mode,"^config","")..": "..self:getSettings()[mode.."style"], 
											"JLCustomClock",
											"openScreensaver"..string.gsub(mode,"^config",""), 
											self:string("SCREENSAVER_CUSTOMCLOCK_SETTINGS"), 
											"openSettings", 
											nil,
											"closeScreensaver")
									end
								end,
								style == entry.name
							),
						})
					elseif entry.name then
						log:debug("Skipping "..entry.name..", isn't supported on "..self.model)
					else
						log:warn("Skipping style without name, styles without names aren't permitted")
					end
				end
			end
		else
			log:debug("Server not selected, ignoring Picture Gallyery styles")
		end
	else
		log:debug("Player not selected, ignoring Picture Gallyery styles")
	end

	self:tieAndShowWindow(window)
	return window
end

function _getMode(self)
	local player = appletManager:callService("getCurrentPlayer")
	local mode = "off"
	if player then
		local playerStatus = player:getPlayerStatus()
		local alarmstate = playerStatus["alarm_state"]
		if alarmstate == "active" then
			mode = "alarm"
		elseif playerStatus.mode == 'play' then
			mode = "playing"
		elseif playerStatus.mode == "stop" or playerStatus.mode == "pause" then
			mode = "stopped"
		end
	end
	if self:getSettings()[mode.."items"] then
		return mode
	else
		return "default"
	end
end

function _getAppletDir()
	local appletdir = nil
	if lfs.attributes("/usr/share/jive/applets") ~= nil then
		appletdir = "/usr/share/jive/applets/"
	else
		-- find the applet directory
		for dir in package.path:gmatch("([^;]*)%?[^;]*;") do
		        dir = dir .. "applets"
		        local mode = lfs.attributes(dir, "mode")
		        if mode == "directory" then
		                appletdir = dir.."/"
		                break
		        end
		end
	end
	if appletdir then
		log:debug("Applet dir is: "..appletdir)
	else
		log:error("Can't locate lua \"applets\" directory")
	end
	return appletdir
end

function _getLuaDir()
	local luadir = nil
	if lfs.attributes("/usr/share/jive/applets") ~= nil then
		luadir = "/usr/share/jive/"
	else
		-- find the main lua directory
		for dir in package.path:gmatch("([^;]*)%?[^;]*;") do
			local mode = lfs.attributes(dir .. "share", "mode")
			if mode == "directory" and lfs.attributes(dir .. "share/jive", "mode") then
				luadir = dir.."share/jive/"
				break
			end
		end
	end
	if luadir then
		log:debug("Lua dir is: "..luadir)
	else
		log:error("Can't locate lua \"share\" directory")
		luadir = "./"
	end
	return luadir
end

function _retrieveFont(self,fonturl,fontfile,fontSize)
	if fonturl and string.find(fonturl,"^http") then
		if not _getString(fontfile,nil) then
			local name = string.sub(fonturl,string.find(fonturl,"/[^/]+$"))
			fontfile = string.gsub(name,"^/","")
		end

		local luadir = _getLuaDir()
		local appletdir = _getAppletDir()
		lfs.mkdir(appletdir.."JLCustomClock/fonts")
		if lfs.attributes(appletdir.."JLCustomClock/fonts/"..fontfile) ~= nil then
			return self:_loadFont(appletdir.."JLCustomClock/fonts/"..fontfile,fontSize)
		elseif lfs.attributes(luadir.."fonts/"..fontfile) ~= nil then
			return self:_loadFont("fonts/"..fontfile,fontSize)
		else
			local req = nil
			log:debug("Getting "..fonturl)
			if not string.find(fonturl,"%.ttf$") and not string.find(fonturl,"%.TTF$")then
				local sink = ltn12.sink.chain(zip.filter(),self:_downloadFontZipFile(appletdir.."JLCustomClock/fonts/"))
				req = RequestHttp(sink, 'GET', fonturl, {stream = true})
			else
				req = RequestHttp(self:_downloadFontFile(appletdir.."JLCustomClock/fonts/",fontfile), 'GET', fonturl, {stream = true})
			end
			local uri = req:getURI()

			local http = SocketHttp(jnt, uri.host, uri.port, uri.host)
			http:fetch(req)
			return nil
		end
	else
		return self:_loadFont("fonts/"..fontfile,fontSize)
	end
end

function _downloadFontZipFile(self, dir)
        local fh = nil

        return function(chunk)

                if chunk == nil then
                        if fh and fh ~= 'DIR' then
                                fh:close()
                        end
                        fh = nil
			log:debug("Downloaded fonts in "..dir)
			if self.window then
				log:debug("Refreshing skin")
				self.window:setSkin(self:_getClockSkin(jiveMain:getSelectedSkin()))
				self.window:reSkin()
			end
                        return nil

                elseif type(chunk) == "table" then

                        if fh and fh ~= 'DIR' then
		                fh:close()
			end
                        fh = nil
                        local filename = dir .. chunk.filename
                        if string.sub(filename, -1) == "/" then
                                log:debug("creating directory: " .. filename)
                                lfs.mkdir(filename)
                                fh = 'DIR'
                        elseif string.find(filename,"%.ttf") or string.find(filename,"%.TTF") then
                                log:debug("Extracting font file: " .. filename)
                                fh = io.open(filename, "w")
			else
				log:debug("ignoring file: "..filename)
                        end

                else
                        if fh and fh ~= 'DIR' then
                                fh:write(chunk)
                        end
                end

                return 1
        end
end

function _downloadFontFile(self,dir,filename)
        local fh = nil

        return function(chunk)
                if chunk == nil then
                        if fh and fh ~= DIR then
                                fh:close()
                                fh = nil
				log:debug("Downloaded "..dir..filename)
				if self.window then
					log:debug("Refreshing skin")
					self.window:setSkin(self:_getClockSkin(jiveMain:getSelectedSkin()))
					self.window:reSkin()
				end
                                return nil
                        end

                else
                        if fh == nil then
	                        fh = io.open(dir .. filename, "w")
                        end

                        fh:write(chunk)
                end

                return 1
        end
end

function _loadFont(self,font,fontSize)
	log:debug("Loading font: "..font.." of size "..fontSize)
        return Font:load(font, fontSize)
end

-- Get usable wallpaper area
function _getUsableWallpaperArea(self)
	local width,height = Framework.getScreenSize()
	return width,height
end

function _extractTrackInfo(_track, _itemType)
        if _track.track then
		if _itemType == 1 then
			return _track.artist
		elseif _itemType == 2 then
			return _track.album
		else 
			return _track.track
		end
        else
                return _track.text
        end
end

function _updateRatingIcon(self,widget,id,mode,free)
	local player = appletManager:callService("getCurrentPlayer")
	if player then
		local licensed = true
		local playerStatus = player:getPlayerStatus()
		if not mode or (mode == 'play' and playerStatus.mode == 'play') or (mode != 'play' and playerStatus.mode != 'play') then
			local rating = self.titleformats["RATING"]
			local trackstatrating = self.customtitleformats["TRACKSTATRATINGNUMBER"]
			if (licensed or free) and trackstatrating then
				if self.images[self.mode..id.."."..trackstatrating] then
					widget:setWidgetValue("itemno",self.images[self.mode..id.."."..trackstatrating])
				else
					widget:setWidgetValue("itemno",nil)
				end
			elseif (licensed or free) and rating then
				rating = math.floor((rating + 10)/ 20)
				if self.images[self.mode..id.."."..rating] then
					widget:setWidgetValue("itemno",self.images[self.mode..id.."."..rating])
				else
					widget:setWidgetValue("itemno",nil)
				end
			else
				if self.images[self.mode..id..".0"] then
					widget:setWidgetValue("itemno",self.images[self.mode..id..".0"])
				else
					widget:setWidgetValue("itemno",nil)
				end
			end
		end
	else
		widget:setWidgetValue("itemno",nil)
	end
end
function _updateNowPlaying(self,itemType,widget,id,mode,free)
	local player = appletManager:callService("getCurrentPlayer")
	local licensed = true
	if player then
		local playerStatus = player:getPlayerStatus()
		if not mode or (mode == 'play' and playerStatus.mode == 'play') or (mode != 'play' and playerStatus.mode != 'play') then
			if playerStatus.item_loop then
				local trackInfo = _extractTrackInfo(playerStatus.item_loop[1],itemType)
				if (licensed or free) and trackInfo != "" then
					widget:setWidgetValue(id,trackInfo)
				elseif trackInfo != "" then
					widget:setWidgetValue(id,tostring(self:string("SCREENSAVER_CUSTOMCLOCK_NEEDS_LICENSE")))
				end
			else
				widget:setWidgetValue(id,"")
			end
		else
			widget:setWidgetValue(id,"")
		end
	else
		widget:setWidgetValue(id,"")
	end
end

function _updateStaticNowPlaying(self,widget,id,format,mode,free)
	local player = appletManager:callService("getCurrentPlayer")
	local licensed = true
	if player then
		local playerStatus = player:getPlayerStatus()
		if not mode or (mode == 'play' and playerStatus.mode == 'play') or (mode != 'play' and playerStatus.mode != 'play') then
			if playerStatus.item_loop then
				if playerStatus.item_loop[2] and playerStatus.item_loop[2].track then
					text = self:_replaceNextTitleKeywords(playerStatus.item_loop[2], format)
				else
					text = self:_replaceNextTitleKeywords(nil, format)
				end
				local text = self:_replaceTitleKeywords(playerStatus.item_loop[1], text ,playerStatus.item_loop[1].track)
				text = self:_replaceCustomTitleFormats(text)
				text = self:_replaceTitleFormatKeyword(text,"BAND")
				text = self:_replaceTitleFormatKeyword(text,"CONDUCTOR")
				text = self:_replaceTitleFormatKeyword(text,"COMPOSER")
				text = self:_replaceTitleFormatKeyword(text,"TRACKARTIST")
				text = self:_replaceTitleFormatKeyword(text,"ALBUMARTIST")
				text = self:_replaceTitleFormatKeyword(text,"TRACKNUM")
				text = self:_replaceTitleFormatKeyword(text,"DISCCOUNT")
				text = self:_replaceTitleFormatKeyword(text,"DISC")

				if self.titleformats["RATING"] then
					local rating = math.floor((self.titleformats["RATING"] + 10)/ 20)
					text = string.gsub(text,"(%w+)", function(w) if w=="RATING" then return rating else return w end end)
				else
					text = string.gsub(text,"(%w+)", function(w) if w=="RATING" then return "" else return w end end)
				end

				local elapsed, duration = player:getTrackElapsed()
				
				if duration then
					text = string.gsub(text,"(%w+)", function(w) if w=="DURATION" then return _secondsToString(duration) else return w end end)
				else
					text = string.gsub(text,"(%w+)", function(w) if w=="DURATION" then return "" else return w end end)
				end
				if elapsed then
					text = string.gsub(text,"(%w+)", function(w) if w=="ELAPSED" then return _secondsToString(elapsed) else return w end end)
					if duration then
						text = string.gsub(text,"(%w+)", function(w) if w=="REMAINING" then return _secondsToString(duration-elapsed) else return w end end)
					else
						text = string.gsub(text,"(%w+)", function(w) if w=="REMAINING" then return "" else return w end end)
					end
				else
					text = string.gsub(text,"(%w+)", function(w) if w=="ELAPSED" then return "" else return w end end)
					text = string.gsub(text,"(%w+)", function(w) if w=="REMAINING" then return "" else return w end end)
				end

				local playlistsize = player:getPlaylistSize()
				local playlistcurrent = player:getPlaylistCurrentIndex()

				if playlistcurrent>=1 and playlistsize>=1 then
					text = string.gsub(text,"X_Y",tostring(self:string("SCREENSAVER_CUSTOMCLOCK_X_Y",playlistcurrent,playlistsize)))
					text = string.gsub(text,"X_OF_Y",tostring(self:string("SCREENSAVER_CUSTOMCLOCK_X_OF_Y",playlistcurrent,playlistsize)))
				else
					text = string.gsub(text,"X_Y","")
					text = string.gsub(text,"X_OF_Y","")
				end

				if licensed or free or text == "" then
					widget:setWidgetValue(id,text)
				elseif text != "" then
					widget:setWidgetValue(id,tostring(self:string("SCREENSAVER_CUSTOMCLOCK_NEEDS_LICENSE")))				
				end
			else
				widget:setWidgetValue(id,"")
			end
		else
			widget:setWidgetValue(id,"")
		end
	else
		widget:setWidgetValue(id,"")
	end
end

function _replaceTitleFormatKeyword(self,text,keyword)
	if self.titleformats[keyword] then
		text = string.gsub(text,"(%w+)", function(w) if w==keyword then return self.titleformats[keyword] else return w end end)
	else
		text = string.gsub(text,"(%w+)", function(w) if w==keyword then return "" else return w end end)
	end
	return text
end

function _replaceCustomTitleFormats(self,text)
	if self.customtitleformats then
		for attr,value in pairs(self.customtitleformats) do
			text = string.gsub(text,"(%w+)", function(w) if w==attr then return value else return w end end)
		end
	end
	return text
end

function _replaceTitleKeywords(self,_track, text, replaceNonTracks)
	if _track.track then
		text = string.gsub(text,"(%w+)", function(w) if w=="ARTIST" then return _track.artist else return w end end)
		text = string.gsub(text,"(%w+)", function(w) if w=="ALBUM" then return _track.album else return w end end)
		text = string.gsub(text,"(%w+)", function(w) if w=="TITLE" then return _track.track else return w end end)
	elseif replaceNoneTracks then
		text = _track.text
	else
		text = ""
	end
	return text
end

function _replaceNextTitleKeywords(self,_track, text)
	if _track and _track.track then
		text = string.gsub(text,"(%w+)", function(w) if w=="NEXTARTIST" then return _track.artist else return w end end)
		text = string.gsub(text,"(%w+)", function(w) if w=="NEXTALBUM" then return _track.album else return w end end)
		text = string.gsub(text,"(%w+)", function(w) if w=="NEXTTITLE" then return _track.track else return w end end)
	else
		text = string.gsub(text,"(%w+)", function(w) if w=="NEXTARTIST" then return "" else return w end end)
		text = string.gsub(text,"(%w+)", function(w) if w=="NEXTALBUM" then return "" else return w end end)
		text = string.gsub(text,"(%w+)", function(w) if w=="NEXTTITLE" then return "" else return w end end)
	end
	return text
end

function _getCoverSize(self,size)
	local result = _getNumber(size,nil)
	if result then
		return result
	else
		if self.model == "controller" then
			return 240
		elseif self.model == "radio" then
			return 240
		elseif self.model == "touch" then
			return 272
		end
	end
end

function _updateSDTText(self,widget,id,format,period)
	local player = appletManager:callService("getCurrentPlayer")
	period = _getString(period,nil) or "-1" 
	local server = player:getSlimServer()
	if not self.sdtMacroChecked and not self:getSettings()['sdtMacroInstalled'] and server and not server:isSqueezeNetwork() then
		server:userRequest(function(chunk,err)
				if err then
					log:warn(err)
				else
					self.sdtMacroChecked = true
					if tonumber(chunk.data._can) == 1 then
						self:getSettings()['sdtMacroInstalled'] = true
						self:_updateSDTText(widget,id,format,period)
					else	
						self:getSettings()['sdtMacroInstalled'] = false
					end
					
				end
			end,
			nil,
			{'can','sdtMacroString', '?'}
		)
	elseif self:getSettings()['sdtMacroInstalled'] and server and not server:isSqueezeNetwork() then
		server:userRequest(
			function(chunk, err)
				if err then
					log:warn(err)
				elseif chunk then
					local text = chunk.data.macroString
					-- Lets allow time keywords to be specified as %$M instead of %M
					if string.find(text,"%%%$") then
						text = string.gsub(text,"%%%$","%%")
						text = self:_getLocalizedDateInfo(nil,_getString(text,""))
					end
					widget:setWidgetValue("itemno",text)
					self:_storeInCache(id,text)
					log:debug("Result from macroString: "..text)
				end
			end,
			player and player:getId(),
			{ 'sdtMacroString', 'format:'..format, 'period:'..tostring(period)}
		)
	end
end

function _updateSDTSportItem(self,items)
	local player = appletManager:callService("getCurrentPlayer")
	local server = player:getSlimServer()

	if not self.sdtSuperDateTimeChecked and not self:getSettings()['sdtSuperDateTimeInstalled'] and server and not server:isSqueezeNetwork() then
		server:userRequest(function(chunk,err)
				if err then
					log:warn(err)
				else
					self.sdtSuperDateTimeChecked = true
					if tonumber(chunk.data._can) == 1 then
						self:getSettings()['sdtSuperDateTimeInstalled'] = true
						self:_updateSDTSportItem(items)
					else	
						self:getSettings()['sdtSuperDateTimeInstalled'] = false
					end
					
				end
			end,
			nil,
			{'can','SuperDateTime', '?'}
		)
	elseif self:getSettings()['sdtSuperDateTimeInstalled'] and server and not server:isSqueezeNetwork() then
		server:userRequest(
			function(chunk, err)
				if err then
					log:warn(err)
				elseif chunk then
					local sportsData = chunk.data.selsports
					local oldCache = self.sdtcache["sport"]
					self.sdtcache["sport"] = {}
					for no,item in pairs(items) do
						local key = self:_getSDTCacheKey("sport",item)
						if not self.sdtcache["sport"][key] then
							self.sdtcache["sport"][key] = {
								current = nil,
								data = self:_getSDTGames(item,sportsData)
							}
						end
						if not self.sdtcache["sport"][key].current then
							if oldCache and oldCache[key] and oldCache[key].current then
								if oldCache[key].data[oldCache[key].current].uniqueID then
									oldItemNo = 1
									for _,item in ipairs(self.sdtcache["sport"][key].data) do
										if item.uniqueID == oldCache[key].data[oldCache[key].current].uniqueID then
											break
										end
										oldItemNo = oldItemNo + 1
									end
									if self.sdtcache["sport"][key].data[oldItemNo].uniqueID == oldCache[key].data[oldCache[key].current].uniqueID then
										self.sdtcache["sport"][key].current = oldItemNo
									end
								end
							end
							if self.sdtcache["sport"][key].current then
								log:debug("Reselecting sports: "..tostring(self.sdtcache["sport"][key].data[self.sdtcache["sport"][key].current].uniqueID))
							elseif self.sdtcache["sport"][key].data[1] then
								log:debug("Resetting sports:   "..tostring(self.sdtcache["sport"][key].data[1].uniqueID))
							end
							self.sdtcache["sport"][key].current = self:_getNextSDTItem("sport",item)
						end
						item.currentResult = self.sdtcache["sport"][key].current
						self:_changeSDTItem("sport",item,self.items[no],no,"false")
					end
				end
			end,
			player and player:getId(),
			{ 'SuperDateTime', 'selsports'}
		)
	end
end

function _updateSDTWeatherItem(self,items)
	local player = appletManager:callService("getCurrentPlayer")
	local server = player:getSlimServer()

	if not self.sdtSuperDateTimeChecked and not self:getSettings()['sdtSuperDateTimeInstalled'] and server and not server:isSqueezeNetwork() then
		server:userRequest(function(chunk,err)
				if err then
					log:warn(err)
				else
					self.sdtSuperDateTimeChecked = true
					if tonumber(chunk.data._can) == 1 then
						self:getSettings()['sdtSuperDateTimeInstalled'] = true
						self:_updateSDTWeatherItem(items)
					else	
						self:getSettings()['sdtSuperDateTimeInstalled'] = false
					end
					
				end
			end,
			nil,
			{'can','SuperDateTime', '?'}
		)
	elseif self:getSettings()['sdtSuperDateTimeInstalled'] and server and not server:isSqueezeNetwork() then
		server:userRequest(
			function(chunk, err)
				if err then
					log:warn(err)
				elseif chunk then
					local wetData = chunk.data.wetData
					self.sdtcache["weather"] = {}
					for no,item in pairs(items) do
						local key = self:_getSDTCacheKey("weather",item)
						if not self.sdtcache["weather"][key] then
							self.sdtcache["weather"][key] = {
								current = nil,
								data = self:_getSDTWeatherData(item,wetData)
							}
						end
						if not self.sdtcache["weather"][key].current then
							self.sdtcache["weather"][key].current = self:_getNextSDTItem("weather",item)
						end
						if string.find(item.itemtype,"icon$") and not _getString(item.logotype,nil) then
							item.logotype = 'forecastIconURLSmall'
						end
						item.currentResult = self.sdtcache["weather"][key].current
						self:_changeSDTItem("weather",item,self.items[no],no,"false")
					end
				end
			end,
			player and player:getId(),
			{ 'SuperDateTime', 'weather'}
		)
	end
end

function _updateSDTMiscItem(self,category,items,selectionattribute)
	local player = appletManager:callService("getCurrentPlayer")
	local server = player:getSlimServer()

	if not self.sdtSuperDateTimeChecked and not self:getSettings()['sdtSuperDateTimeInstalled'] and server and not server:isSqueezeNetwork() then
		server:userRequest(function(chunk,err)
				if err then
					log:warn(err)
				else
					self.sdtSuperDateTimeChecked = true
					if tonumber(chunk.data._can) == 1 then
						self:getSettings()['sdtSuperDateTimeInstalled'] = true
						self:_updateSDTMiscItem(category,items,selectionattribute)
					else	
						self:getSettings()['sdtSuperDateTimeInstalled'] = false
					end
					
				end
			end,
			nil,
			{'can','SuperDateTime', '?'}
		)
	elseif self:getSettings()['sdtSuperDateTimeInstalled'] and server and not server:isSqueezeNetwork() then
		server:userRequest(
			function(chunk, err)
				if err then
					log:warn(err)
				elseif chunk then
					local miscData = chunk.data.miscData[category]
					local oldCache = self.sdtcache[category]
					self.sdtcache[category] = {}
					if miscData then
						for no,item in pairs(items) do
							local key = self:_getSDTCacheKey(category,item)
							if not self.sdtcache[category][key] then
								self.sdtcache[category][key] = {
									current = nil,
									data = self:_getSDTMiscData(item,selectionattribute,miscData)
								}
							end
							if not self.sdtcache[category][key].current then
								if oldCache and oldCache[key] and oldCache[key].current then
									if oldCache[key].data[oldCache[key].current].uniqueID then
										oldItemNo = 1
										for _,item in ipairs(self.sdtcache[category][key].data) do
											if item.uniqueID == oldCache[key].data[oldCache[key].current].uniqueID then
												break
											end
											oldItemNo = oldItemNo + 1
										end
										if self.sdtcache[category][key].data[oldItemNo].uniqueID == oldCache[key].data[oldCache[key].current].uniqueID then
											self.sdtcache[category][key].current = oldItemNo
										end
									end
								end
								if self.sdtcache[category][key].current then
									log:debug("Reselecting "..category..": "..tostring(self.sdtcache[category][key].data[self.sdtcache[category][key].current].uniqueID))
								elseif self.sdtcache[category][key].data[1] then
									log:debug("Resetting "..category..":   "..tostring(self.sdtcache[category][key].data[1].uniqueID))
								end
								self.sdtcache[category][key].current = self:_getNextSDTItem(category,item)
							end
							item.currentResult = self.sdtcache[category][key].current
							self:_changeSDTItem(category,item,self.items[no],no,"true")
						end
					end
				end
			end,
			player and player:getId(),
			{ 'SuperDateTime', 'misc'}
		)
	end
end

function _updatePluginItem(self,category,items)
	local player = appletManager:callService("getCurrentPlayer")
	local server = player:getSlimServer()

	if not self.ccPluginItemsChecked and not self:getSettings()['ccPluginItemsInstalled'] and server and not server:isSqueezeNetwork() then
		server:userRequest(function(chunk,err)
				if err then
					log:warn(err)
				else
					self.sdtSuperDateTimeChecked = true
					if tonumber(chunk.data._can) == 1 then
						self:getSettings()['ccPluginItemsInstalled'] = true
						self:_updatePluginItem(category,items)
					else	
						self:getSettings()['ccPluginItemsInstalled'] = false
					end
					
				end
			end,
			nil,
			{'can','customclock', 'customitems','?'}
		)
	elseif self:getSettings()['ccPluginItemsInstalled'] and server and not server:isSqueezeNetwork() then
		server:userRequest(
			function(chunk, err)
				if err then
					log:warn(err)
				elseif chunk then
					local itemsData = chunk.data.items[category]
					local oldCache = self.pluginitemcache[category]
					self.pluginitemcache[category] = {}
					if itemsData then
						for no,item in pairs(items) do
							local key = self:_getPluginItemCacheKey(category,item)
							if not self.pluginitemcache[category][key] then
								self.pluginitemcache[category][key] = {
									current = nil,
									data = self:_getPluginItemData(item,itemsData)
								}
							end
							if not self.pluginitemcache[category][key].current then
								if oldCache and oldCache[key] and oldCache[key].current then
									if oldCache[key].data[oldCache[key].current].uniqueID then
										oldItemNo = 1
										for _,item in ipairs(self.pluginitemcache[category][key].data) do
											if item.uniqueID == oldCache[key].data[oldCache[key].current].uniqueID then
												break
											end
											oldItemNo = oldItemNo + 1
										end
										if self.pluginitemcache[category][key].data[oldItemNo].uniqueID == oldCache[key].data[oldCache[key].current].uniqueID then
											self.pluginitemcache[category][key].current = oldItemNo
										end
									end
								end
								if self.pluginitemcache[category][key].current then
									log:debug("Reselecting "..category..": "..tostring(self.pluginitemcache[category][key].data[self.pluginitemcache[category][key].current].uniqueID))
								elseif self.pluginitemcache[category][key].data[1] then
									log:debug("Resetting "..category..":   "..tostring(self.pluginitemcache[category][key].data[1].uniqueID))
								end
								self.pluginitemcache[category][key].current = self:_getNextPluginItem(category,item)
							end
							item.currentResult = self.pluginitemcache[category][key].current
							self:_changePluginItem(category,item,self.items[no],no,"true")
						end
					end
				end
			end,
			player and player:getId(),
			{ 'customclock', 'customitems','category:'..category}
		)
	end
end

function _updateRSSItem(self,category,items)
	local player = appletManager:callService("getCurrentPlayer")
	local server = player:getSlimServer()
	local licensed = true

	local req = RequestHttp(function(chunk, err)
			if err then
				log:warn(err)
			elseif chunk then
				local title = ""
				local description = ""
				local guid = ""
				local url = ""
				local pubDate = ""
				local source = ""
				local credit = ""
				local captureTitle = false
				local captureDescription = false
				local captureGUID = false
				local capturePubDate = false
				local captureSource = false
				local captureCredit = false
				local itemsData = {}
				local index = 0
				local p = lxp.new({
					StartElement = function (parser, name, attr)
						if name == "media:content" and attr.url and (attr.type=="image/jpeg" or attr.type=="image/png" or string.find(attr.url,"jpeg$") or string.find(attr.url,"jpg$") or string.find(attr.url,"png$")) then
							url = attr.url
						elseif name == "enclusure" and attr.url and (attr.type=="image/jpeg" or attr.type=="image/png" or string.find(attr.url,"jpeg$") or string.find(attr.url,"jpg$") or string.find(attr.url,"png$")) then
							url = attr.url
						elseif name =="title" then
							title = ""
							captureTitle = true
						elseif name =="description" then
							description = ""
							captureDescription = true
						elseif name =="guid" then
							guid = ""
							captureGUID = true
						elseif name =="pubDate" then
							pubDate = ""
							capturePubDate = true
						elseif name =="source" then
							source = ""
							captureSource = true
						elseif name =="media:credit" then
							credit = ""
							captureCredit = true
						end
					end,
					CharacterData = function (parser, text)
						if captureTitle then
							title = title .. text
						elseif captureDescription then
							description = description .. text
						elseif captureGUID then
							guid = guid .. text
						elseif capturePubDate then
							pubDate = pubDate .. text
						elseif captureSource then
							source = source .. text
						elseif captureCredit then
							credit = credit .. text
						end
					end,
					EndElement = function(parser, name)
						if name == "title" then
							captureTitle = false
						elseif name == "description" then
							captureDescription = false
						elseif name == "guid" then
							captureGUID = false
						elseif name =="pubDate" then
							capturePubDate = false
						elseif name == "source" then
							captureSource = false
						elseif name == "media:credit" then
							captureCredit = false
						end
						if name == "item" then
							local id = guid
							if id == "" then
								if title != "" then
									id = title
								end
								if description != "" then
									id = id..description
								end
							end
							local text = title
							if not text then
								text = description
							end
							log:debug("Retrieved("..index.."): "..text)
							if not licensed then
								title = tostring(self:string("SCREENSAVER_CUSTOMCLOCK_NEEDS_LICENSE"))..": "..title
								description = tostring(self:string("SCREENSAVER_CUSTOMCLOCK_NEEDS_LICENSE"))..": "..description
							end
							itemsData[index] = {
								uniqueID = id,
								pubDate = pubDate,
								source = source,
								title = title,
								description = description,
								credot = credit,
								url = url
							}
							index=index+1
						end
					end,
				})
				p:parse(chunk)
				p:close()
				local oldCache = self.rssitemcache[category]
				self.rssitemcache[category] = {}
				for no,item in pairs(items) do
					local key = self:_getRSSItemCacheKey(category,item)
					if not self.rssitemcache[category][key] then
						self.rssitemcache[category][key] = {
							current = nil,
							data = self:_getRSSItemData(item,itemsData)
						}
					end
					if not self.rssitemcache[category][key].current then
						if oldCache and oldCache[key] and oldCache[key].current then
							if oldCache[key].data[oldCache[key].current].uniqueID then
								oldItemNo = 1
								for _,item in ipairs(self.rssitemcache[category][key].data) do
									if item.uniqueID == oldCache[key].data[oldCache[key].current].uniqueID then
										break
									end
									oldItemNo = oldItemNo + 1
								end
								if self.rssitemcache[category][key].data[oldItemNo].uniqueID == oldCache[key].data[oldCache[key].current].uniqueID then
									self.rssitemcache[category][key].current = oldItemNo
								end
							end
						end
						if self.rssitemcache[category][key].current then
							log:debug("Reselecting "..category..": "..tostring(self.rssitemcache[category][key].data[self.rssitemcache[category][key].current].uniqueID))
						elseif self.rssitemcache[category][key].data[1] then
							log:debug("Resetting "..category..":   "..tostring(self.rssitemcache[category][key].data[1].uniqueID))
						end
						self.rssitemcache[category][key].current = self:_getNextRSSItem(category,item)
					end
					item.currentResult = self.rssitemcache[category][key].current
					self:_changeRSSItem(category,item,self.items[no],no,"true")
				end
			end
		end,
		'GET', category)
	local uri = req:getURI()
	local http = SocketHttp(jnt, uri.host, uri.port, uri.host)
	http:fetch(req)
end

function _getPluginItemCacheKey(self,category,item)
	if string.find(item.itemtype,"text$") and item.scrolling then
		return "scrolling".._getString(item.selected,"")
	else
		return "switching".._getString(item.selected,"")
	end
end

function _getRSSItemCacheKey(self,category,item)
	if string.find(item.itemtype,"text$") and item.scrolling then
		return "scrolling".._getString(item.selected,"")
	else
		return "switching".._getString(item.selected,"")
	end
end

function _getSDTCacheKey(self,category,item)
	if category == "sport" then
		if item.itemtype == "sdtsporttext" and item.scrolling then
			return "scrolling".._getString(item.sport,"all").._getString(item.gamestatus,"")
		else
			return _getString(item.sport,"all").._getString(item.gamestatus,"")
		end
	elseif category == "stocks" and string.find(item.itemtype,"^sdtstock") then
		if item.itemtype == "sdtstocktext" and item.scrolling then
			return "scrolling".._getString(item.stock,"")
		else
			return "switching".._getString(item.stock,"")
		end
	elseif category == "weather" then
		return "weather".._getString(item.period,"")
	else
		if string.find(item.itemtype,"text$") and item.scrolling then
			return "scrolling".._getString(item.selected,"")
		else
			return "switching".._getString(item.selected,"")
		end
	end
end

function _getSDTCacheData(self,category,item)
	local key = self:_getSDTCacheKey(category,item)
	if self.sdtcache[category] and self.sdtcache[category][key] then
		return self.sdtcache[category][key].data
	else
		return {}
	end
end

function _getSDTCacheIndex(self,category,item)
	local key = self:_getSDTCacheKey(category,item)
	if self.sdtcache[category] and self.sdtcache[category][key] then
		return self.sdtcache[category][key].current
	else
		return nil
	end
end

function _getPluginItemCacheData(self,category,item)
	local key = self:_getPluginItemCacheKey(category,item)
	if self.pluginitemcache[category] and self.pluginitemcache[category][key] then
		return self.pluginitemcache[category][key].data
	else
		return {}
	end
end

function _getPluginItemCacheIndex(self,category,item)
	local key = self:_getPluginItemCacheKey(category,item)
	if self.pluginitemcache[category] and self.pluginitemcache[category][key] then
		return self.pluginitemcache[category][key].current
	else
		return nil
	end
end

function _getRSSItemCacheData(self,category,item)
	local key = self:_getRSSItemCacheKey(category,item)
	if self.rssitemcache[category] and self.rssitemcache[category][key] then
		return self.rssitemcache[category][key].data
	else
		return {}
	end
end

function _getRSSItemCacheIndex(self,category,item)
	local key = self:_getRSSItemCacheKey(category,item)
	if self.rssitemcache[category] and self.rssitemcache[category][key] then
		return self.rssitemcache[category][key].current
	else
		return nil
	end
end

function _getSDTGames(self,item,sportsData)
	local games = {}
	local no = 1
	if _getString(item.sport,nil) then
		local logoURL = nil
		if not sportsData[item.sport] and sportsData[string.upper(item.sport)] then
			item.sport = string.upper(item.sport)
		end
		if sportsData[item.sport] then
			for key,value in pairs(sportsData[item.sport]) do
				if type(value) == 'string' then
					if key == 'logoURL' then
						logoURL = value
					end
				elseif not _getString(item.gamestatus,nil) or 
					(string.find(item.gamestatus,"final$") and _getNumber(value.homeScore,nil) and string.find(value.gameTime,"^F")) or 
					(string.find(item.gamestatus,"^active") and _getNumber(value.homeScore,nil) and not string.find(value.gameTime,"^F")) then
					games[no] = value
					games[no].sport=item.sport
					games[no].uniqueID=key
					no = no + 1
				end
			end
			if logoURL then
				for idx,value in ipairs(games) do
					value.logoURL = logoURL
				end
			end
		end
	else
		for sport,_ in pairs(sportsData) do
			local logoURL = nil
			for key,value in pairs(sportsData[sport]) do
				if type(value) == 'string' then
					if key == 'logoURL' then
						logoURL = value
					end
				elseif not _getString(item.gamestatus,nil) or 
					(string.find(item.gamestatus,"final$") and _getNumber(value.homeScore,nil) and string.find(value.gameTime,"^F")) or 
					(string.find(item.gamestatus,"^active") and _getNumber(value.homeScore,nil) and not string.find(value.gameTime,"^F")) then
					games[no] = value
					games[no].sport = sport
					games[no].uniqueID=key
					no = no + 1
				end
			end
			if logoURL then
				for idx,value in ipairs(games) do
					if value.sport == sport then
						value.logoURL = logoURL
					end
				end
			end
		end
	end
	return games
end

function _getSDTMiscData(self,item,selectionattribute,totalResults)
	local results = {}
	local no = 1
	if _getString(item[selectionattribute],nil) then
		local icons = {}
		for key,value in pairs(totalResults) do
			if type(value) == 'string' then
				icons[key] = value
			end
		end
		if totalResults[item[selectionattribute]] then
			results[no] = totalResults[item[selectionattribute]]
			results[no][selectionattribute] = item[selectionattribute]
			results[no].uniqueID=item[selectionattribute]
			for key,icon in pairs(icons) do
				if not results[no][key] then
					results[no][key] = icon
				end
			end
			no = no + 1
		end
	else
		local icons = {}
		for key,value in pairs(totalResults) do
			if type(value) == 'string' then
				icons[key] = value
			end
		end
		for selection,value in pairs(totalResults) do
			results[no] = value
			results[no][selectionattribute] = selection
			results[no].uniqueID=selection
			for key,icon in pairs(icons) do
				if not results[no][key] then
					results[no][key] = icon
				end
			end
			no = no + 1
		end
	end
	return results
end

function _getPluginItemData(self,item,totalResults)
	local results = {}
	local no = 1
	if _getString(item.selected,nil) then
		if totalResults[item.selected] then
			results[no] = totalResults[item.selected]
			results[no].uniqueID=item.selected
			for key,icon in pairs(icons) do
				if not results[no][key] then
					results[no][key] = icon
				end
			end
			no = no + 1
		end
	else
		for selection,value in pairs(totalResults) do
			results[no] = value
			results[no].uniqueID=selection
			no = no + 1
		end
	end
	return results
end

function _getRSSItemData(self,item,totalResults)
	local results = {}
	local no = 1
	if _getString(item.selected,nil) then
		if totalResults[item.selected] then
			results[no] = totalResults[item.selected]
			results[no].uniqueID=item.selected
			for key,icon in pairs(icons) do
				if not results[no][key] then
					results[no][key] = icon
				end
			end
			no = no + 1
		end
	else
		for selection,value in pairs(totalResults) do
			results[no] = value
			results[no].uniqueID=selection
			no = no + 1
		end
	end
	return results
end

function _getSDTWeatherData(self,item,totalResults)
	local results = {}
	local no = 1
	if _getString(item.period,nil) then
		if totalResults[item.period] then
			results[no] = totalResults[item.period]
			results[no].period = item.period
			results[no].uniqueID=item.period
			if tostring(item.period) == "-1" then
				for selection,value in pairs(totalResults) do
		 			if type(value) ~= 'table' then
		 				if results[1] then
							results[1][selection] = value
						end
					end
				end
			end
			log:debug("Getting specific item for "..item.period)
		elseif string.find(item.period,"^%d+-%d+$") then
			local last = string.gsub(item.period,"^%d+-","")
			local first = string.gsub(item.period,"-%d+$","")
			for i = tonumber(first),tonumber(last) do
				if totalResults[tostring(i)] then
					results[no] = totalResults[tostring(i)]
					results[no].period = tostring(i)
					results[no].uniqueID=tostring(i)
					no = no + 1
				end
			end
			log:debug("Getting interval between "..first.." and "..last)
		elseif string.find(item.period,"^d%d+-d%d+$") then
			local last = string.gsub(item.period,"^d%d+-d","")
			local first = string.gsub(item.period,"-d%d+$","")
			first = string.gsub(first,"^d","")
			for i = tonumber(first),tonumber(last) do
				if totalResults["d"..tostring(i)] then
					results[no] = totalResults["d"..tostring(i)]
					results[no].period = "d"..tostring(i)
					results[no].uniqueID="d"..tostring(i)
					no = no + 1
				end
			end
			log:debug("Getting interval between d"..first.." and d"..last)
		end
	else
		for selection,value in pairs(totalResults) do
			if type(value) == 'table' then
				results[no] = value
				results[no].period = selection
				results[no].uniqueID=selection
				no = no + 1
			end
		end
		for selection,value in pairs(totalResults) do
 			if type(value) ~= 'table' then
 				if results[1] then
					results[1][selection] = value
				end
			end
		end
	end
	return results
end

function _getNextSDTItem(self,category,item)
	local results = self:_getSDTCacheData(category,item)
	local currentResult = self:_getSDTCacheIndex(category,item)
	if currentResult then
		local length = _getNumber(item.noofrows,1)
		if length == 1 and string.find(item.itemtype,category..'text$') and _getString(item.scrolling,"false") == "true" then
			length = #results
		end
		if #results > (currentResult+length+_getNumber(item.step,1)-2) then
			currentResult = currentResult + length +_getNumber(item.step,1) -1
		else
			currentResult = 1
		end
	elseif #results>0 then
		currentResult = 1
	else
	end
	return currentResult
end

function _getNextPluginItem(self,category,item)
	local results = self:_getPluginItemCacheData(category,item)
	local currentResult = self:_getPluginItemCacheIndex(category,item)
	if currentResult then
		local length = _getNumber(item.noofrows,1)
		if length == 1 and string.find(item.itemtype,category..'text$') and _getString(item.scrolling,"false") == "true" then
			length = #results
		end
		if #results > (currentResult+length+_getNumber(item.step,1)-2) then
			currentResult = currentResult + length +_getNumber(item.step,1) -1
		else
			currentResult = 1
		end
	elseif #results>0 then
		currentResult = 1
	else
	end
	return currentResult
end


function _getNextRSSItem(self,category,item)
	local results = self:_getRSSItemCacheData(category,item)
	local currentResult = self:_getRSSItemCacheIndex(category,item)
	if currentResult then
		local length = _getNumber(item.noofrows,1)
		if length == 1 and string.find(item.itemtype,category..'text$') and _getString(item.scrolling,"false") == "true" then
			length = #results
		end
		if #results > (currentResult+length+_getNumber(item.step,1)-2) then
			currentResult = currentResult + length +_getNumber(item.step,1) -1
		else
			currentResult = 1
		end
	elseif #results>0 then
		currentResult = 1
	else
	end
	return currentResult
end

function _changeSDTItem(self,category,item,widget,id,dynamic)
	local results = self:_getSDTCacheData(category,item)
	local currentResult = self:_getSDTCacheIndex(category,item)
	if currentResult then
		if string.find(item.itemtype,'text$') then
			local sdtString = self:_getResultString(item,results,"sdtformat")
			if widget:getWidgetValue("itemno") ~= sdtString then
				widget:setWidgetValue("itemno",sdtString)
				self:_storeInCache(id,sdtString)
			end
		elseif string.find(item.itemtype,'icon$') then
			local player = appletManager:callService("getCurrentPlayer")
			local server = player:getSlimServer()
			local url = nil
			local url = nil
			if #results>=currentResult+_getNumber(item.offset,0) then
				if string.find(item.logotype,"orlogoURL$") then
					url = results[currentResult+_getNumber(item.offset,0)][string.gsub(item.logotype,"orlogoURL$","")]
					if not url then
						url = results[currentResult+_getNumber(item.offset,0)]['logoURL']
					end
				else
					url = results[currentResult+_getNumber(item.offset,0)][item.logotype]
				end
			end
			local allowProxy = "true"
			if url and not string.find(url,"^http") then
				allowProxy = "false"
				local ip,port = server:getIpPort()
				if not string.find(url,"^/") then
					url = "/"..url
				end
				url = "http://"..ip..":"..port..url
				local width = _getNumber(item.width,nil)
				local height = _getNumber(item.height,nil)
				if width and height then
					url = string.gsub(url,".png$","_"..width.."x"..height.."_p.png")
					url = string.gsub(url,".jpg$","_"..width.."x"..height.."_p.jpg")
					url = string.gsub(url,".jpeg$","_"..width.."x"..height.."_p.jpeg")
				end
			end
			if url then
				self.referenceimages[self.mode.."item"..id] = id
				self:_retrieveImage(url,self.mode.."item"..id,_getString(item.allowproxy,allowProxy),dynamic,_getNumber(item.width,nil),_getNumber(item.height,nil),_getNumber(item.clipx,nil),_getNumber(item.clipy,nil),_getNumber(item.clipwidth,nil),_getNumber(item.clipheight,nil))
			else
				widget:setWidgetValue("itemno",nil)
				self:_removeFromCache(id)
			end
		end
	else
		if string.find(item.itemtype,'text$') then
			widget:setWidgetValue("itemno","")
			self:_removeFromCache(id)
		elseif string.find(item.itemtype,'icon$') then
			widget:setWidgetValue("itemno",nil)
			self:_removeFromCache(id)
		end
	end
end

function _changePluginItem(self,category,item,widget,id,dynamic)
	local results = self:_getPluginItemCacheData(category,item)
	local currentResult = self:_getPluginItemCacheIndex(category,item)
	if currentResult then
		if string.find(item.itemtype,'text$') then
			local combinedString = self:_getResultString(item,results,"format")
			if widget:getWidgetValue("itemno") ~= combinedString then
				widget:setWidgetValue("itemno",combinedString)
				self:_storeInCache(id,combinedString)
			end
		elseif string.find(item.itemtype,'icon$') then
			local player = appletManager:callService("getCurrentPlayer")
			local server = player:getSlimServer()
			local url = nil
			if #results>=(currentResult+_getNumber(item.offset,0)) then
				url = results[currentResult+_getNumber(item.offset,0)][item.logotype]
			end
			local allowProxy = "true"
			if url and not string.find(url,"^http") then
				allowProxy = "false"
				local ip,port = server:getIpPort()
				if not string.find(url,"^/") then
					url = "/"..url
				end
				url = "http://"..ip..":"..port..url
				local width = _getNumber(item.width,nil)
				local height = _getNumber(item.height,nil)
				if width and height then
					url = string.gsub(url,".png","_"..width.."x"..height.."_p.png")
					url = string.gsub(url,".jpg","_"..width.."x"..height.."_p.jpg")
					url = string.gsub(url,".jpeg","_"..width.."x"..height.."_p.jpeg")
				end
			end
			if url then
				self.referenceimages[self.mode.."item"..id] = id
				self:_retrieveImage(url,self.mode.."item"..id,_getString(item.allowproxy,allowProxy),dynamic,_getNumber(item.width,nil),_getNumber(item.height,nil),_getNumber(item.clipx,nil),_getNumber(item.clipy,nil),_getNumber(item.clipwidth,nil),_getNumber(item.clipheight,nil))
			else
				widget:setWidgetValue("itemno",nil)
				self:_removeFromCache(id)
			end
		end
	else
		if string.find(item.itemtype,'text$') then
			widget:setWidgetValue("itemno","")
			self:_removeFromCache(id)
		elseif string.find(item.itemtype,'icon$') then
			widget:setWidgetValue("itemno",nil)
			self:_removeFromCache(id)
		end
	end
end

function _changeRSSItem(self,category,item,widget,id,dynamic)
	local results = self:_getRSSItemCacheData(category,item)
	local currentResult = self:_getRSSItemCacheIndex(category,item)
	if currentResult then
		if string.find(item.itemtype,'text$') then
			local combinedString = self:_getResultString(item,results,"format")
			if widget:getWidgetValue("itemno") ~= combinedString then
				widget:setWidgetValue("itemno",combinedString)
				self:_storeInCache(id,combinedString)
			end
		elseif string.find(item.itemtype,'icon$') then
			local player = appletManager:callService("getCurrentPlayer")
			local server = player:getSlimServer()
			local url = nil
			if #results>=(currentResult+_getNumber(item.offset,0)) then
				url = results[currentResult+_getNumber(item.offset,0)].url
			end
			local allowProxy = "true"
			if url and not string.find(url,"^http") then
				allowProxy = "false"
				local ip,port = server:getIpPort()
				if not string.find(url,"^/") then
					url = "/"..url
				end
				url = "http://"..ip..":"..port..url
				local width = _getNumber(item.width,nil)
				local height = _getNumber(item.height,nil)
				if width and height then
					url = string.gsub(url,".png","_"..width.."x"..height.."_p.png")
					url = string.gsub(url,".jpg","_"..width.."x"..height.."_p.jpg")
					url = string.gsub(url,".jpeg","_"..width.."x"..height.."_p.jpeg")
				end
			end
			if url then
				self.referenceimages[self.mode.."item"..id] = id
				self:_retrieveImage(url,self.mode.."item"..id,_getString(item.allowproxy,allowProxy),dynamic,_getNumber(item.width,nil),_getNumber(item.height,nil),_getNumber(item.clipx,nil),_getNumber(item.clipy,nil),_getNumber(item.clipwidth,nil),_getNumber(item.clipheight,nil))
			else
				widget:setWidgetValue("itemno",nil)
				self:_removeFromCache(id)
			end
		end
	else
		if string.find(item.itemtype,'text$') then
			widget:setWidgetValue("itemno","")
			self:_removeFromCache(id)
		elseif string.find(item.itemtype,'icon$') then
			widget:setWidgetValue("itemno",nil)
			self:_removeFromCache(id)
		end
	end
end

function _getResultString(self,item,results,attribute)
	local result = ""
	local length = _getNumber(item.noofrows,1)
	local offset = 0
	if length == 1 and _getString(item.scrolling,"false") == "true" then
		length = #results
		item.currentResult = 1
	else
		offset = _getNumber(item.offset,0)
	end
	if #results>=item.currentResult+offset then
		local first = item.currentResult+offset
		for i=first,(first+length-1) do
			if #results>=i then
				if i>first and (_getString(item.scrolling,"false") == "false" or tonumber(_getNumber(item.noofrows,1))>1 or tonumber(_getNumber(item.linelength,0))>0) then
					if _getString(item.separator,nil) then
						local separator = _getString(item.separator,nil)
						separator = string.gsub(separator,"\\n","\n")
						result = result..separator
					else
						result = result.."\n"
					end
				elseif i>first then
					if _getString(item.separator,nil) then
						local separator = _getString(item.separator,nil)
						separator = string.gsub(separator,"\\n","\n")
						result = result..separator
					else
						result = result.."      "
					end
				end
				local tmp = _getString(item[attribute],"")
				for key,value in pairs(results[i]) do
					local escapedValue = value
					if not _getString(value,nil) then
						tmp = string.gsub(tmp,"%(%%"..key.."%)","")
					else
						escapedValue = string.gsub(_getString(value,""),"%%","%%%%")
					end
					tmp = string.gsub(tmp,"%%"..key,escapedValue)
				end
				if _getString(item.decodehtml,"false") == "true" then
					tmp = _html2txt(tmp)
				end
				if _getString(item.scrolling,"false") == "false" and tonumber(_getNumber(item.linelength,0))>0 and string.len(tmp)>tonumber(_getNumber(item.linelength,0)) then
					tmp = _wordwrap(tmp,tonumber(_getNumber(item.linelength,0)))
				end
				tmp = string.gsub(tmp,"\\n","\n")
				if _getString(item.animate,"true") == "true" then
					tmp = string.gsub(tmp,"\n"," ")
				end
				result = result..tmp
			end
		end
	end
	return result
end
function _token_of(c)
	local x,y = string.match(c,"^%s*([/!]?)%s*(%a+)%s*")
	return (x or "") .. (y or "")
end

function _html2txt(s)
	s = string.gsub(s,"<%s*[Ss][Cc][Rr][Ii][Pp][Tt].->.-<%s*/%s*[Ss][Cc][Rr][Ii][Pp][Tt].->","")
	s = string.gsub(s,"<%s*[Ss][Tt][Yy][Ll][Ee].->.-<%s*/%s*[Ss][Tt][Yy][Ll][Ee].->","")
	s = string.gsub(s,"<([^>]-)>",function(c)
		c = string.lower(c)
		local t = _token_of(c)
		local r = html_tags[t]
		return r
	end)
	s = string.gsub(s,"&(%a-);",function(c)
		c = string.lower(c)
		return html_coded[c] or ("["..c.."]")
	end)
	s = string.gsub(s,"&#(%d-);", function(c)
--	  log.dbg("html2txt &#(%d-); substitution: "..tostring(c))
      	  if tonumber(c) < 256 then
	    return string.char(c)
	  end
	  return html_coded_numeric[c] or "?"
	end)
	return s
end

function _explode ( str, seperator ) 
 	local pos, arr = 0, {}
	for st, sp in function() return string.find( str, seperator, pos, true ) end do -- for each divider found
		table.insert( arr, string.sub( str, pos, st-1 ) ) -- Attach chars left of current divider
		pos = sp + 1 -- Jump past current divider
	end
	table.insert( arr, string.sub( str, pos ) ) -- Attach chars right of last divider
	return arr
end

function _wordwrap(strText,intMaxLength)
    local tblOutput = {}
    
    local intIndex
    local strBuffer = ""
    local tblLines = _explode(strText,"\n")

    for k,strLine in pairs(tblLines) do
        local tblWords = _explode(strLine," ")
        
        if (#tblWords > 0) then
            intIndex = 1
            
            while tblWords[intIndex] do
                local strWord = " " .. tblWords[intIndex]
                if (strBuffer:len() >= intMaxLength) then
                    table.insert(tblOutput,strBuffer:sub(1,intMaxLength))
                    strBuffer = strBuffer:sub(intMaxLength + 1)
                    intIndex = intIndex+1
                else
                    if (strWord:len() > intMaxLength) then
                        strBuffer = strBuffer .. strWord
                    elseif (strBuffer:len() + strWord:len() >= intMaxLength) then
                        table.insert(tblOutput,strBuffer)
                        strBuffer = ""
                    else
                        if (strBuffer == "") then
                            strBuffer = strWord:sub(2)
                        else
                            strBuffer = strBuffer .. strWord
                        end
                        
                        intIndex = intIndex + 1
                    end
                end
            end
            
            if (strBuffer != "") then
                table.insert(tblOutput,strBuffer)
                strBuffer = ""
            end
        end
    end
    
    return table.concat(tblOutput,"\n")
end

function _updateSDTWeatherMapIcon(self,widget,id,item)
	local player = appletManager:callService("getCurrentPlayer")
	local server = player:getSlimServer()
	if not self.sdtVersionChecked and not self:getSettings()['sdtVersionInstalled'] and server and not server:isSqueezeNetwork() then
		server:userRequest(function(chunk,err)
				if err then
					log:warn(err)
				else
					self.sdtVersionChecked = true
					if tonumber(chunk.data._can) == 1 then
						self:getSettings()['sdtVersionInstalled'] = true
						self:_updateSDTWeatherMapIcon(widget,id,item)
					else	
						self:getSettings()['sdtVersionInstalled'] = false
					end
					
				end
			end,
			nil,
			{'can','sdtVersion', '?'}
		)
	elseif self:getSettings()['sdtVersionInstalled'] and server and not server:isSqueezeNetwork() then
		server:userRequest(function(chunk,err)
				if err then
					log:warn(err)
				else
					local url = nil
					if _getString(item.location,nil) and chunk.data.wetmapURL[item.location] and chunk.data.wetmapURL[item.location].URL then
						url = chunk.data.wetmapURL[item.location].URL
					end
					if url then
						self.configItems[id].url = url
						self.referenceimages[self.mode.."item"..id] = id
						self:_retrieveImage(url,self.mode.."item"..id,_getString(item.allowproxy,"true"),"true",_getNumber(width,nil),_getNumber(item.height,nil),_getNumber(item.clipx,nil),_getNumber(item.clipy,nil),_getNumber(item.clipwidth,nil),_getNumber(item.clipheight,nil))
					end
				end
			end,
			player and player:getId(),
			{'SuperDateTime','wetmapURL'}
		)
	end
end

function _updateSongInfoIcon(self,widget,id,width,height,module,dynamic,allowproxy)
	local player = appletManager:callService("getCurrentPlayer")
	local server = player:getSlimServer()
	if not self.sdtSongInfoChecked and not self:getSettings()['sdtSongInfoInstalled'] and server and not server:isSqueezeNetwork() then
		server:userRequest(function(chunk,err)
				if err then
					log:warn(err)
				else
					self.sdtSongInfoChecked = true
					if tonumber(chunk.data._can) == 1 then
						self:getSettings()['sdtSongInfoInstalled'] = true
						self:_updateSongInfoIcon(widget,id,width,height,module,dynamic,allowproxy)
					else	
						self:getSettings()['sdtSongInfoInstalled'] = false
					end
					
				end
			end,
			nil,
			{'can','songinfoitems', '?'}
		)
	elseif self:getSettings()['sdtSongInfoInstalled'] and _getString(module,nil) and server and not server:isSqueezeNetwork() then
		server:userRequest(function(chunk,err)
				if err then
					log:warn(err)
				else
					if chunk.data.item_loop then
						self.configItems[id].urls = {}
						for no,item in ipairs(chunk.data.item_loop) do
							self.configItems[id].urls[no] = item.url
						end
						local imageNo = math.random(1,#self.configItems[id].urls)
						self.referenceimages[self.mode.."item"..id] = id
						self:_retrieveImage(self.configItems[id].urls[imageNo],self.mode.."item"..id,allowproxy,dynamic,_getNumber(width,nil),_getNumber(height,nil))
					else
						self.configItems[id].urls = nil
					end
				end
			end,
			player and player:getId(),
			{'songinfoitems','0','100','module:'..module}
		)
	end
end

function _updateGalleryImage(self,widget,id,width,height,favorite)
	local player = appletManager:callService("getCurrentPlayer")
	local server = player:getSlimServer()
	if server and not server:isSqueezeNetwork() then
		server:userRequest(function(chunk,err)
				if err then
					log:warn(err)
				else
					local cmd = {'gallery','random'}
					if _getNumber(favorite,nil) then
						cmd = {'gallery','random','favid:'.._getNumber(favorite,nil)}
					end
					server:userRequest(function(chunk,err)
							if err then
								log:warn(err)
							else
								local maxwidth,maxheight = self:_getUsableWallpaperArea()
								local url = string.gsub(chunk.data.image,"{resizeParams}","_".._getNumber(width,maxwidth).."x".._getNumber(height,maxheight).."_p")
								local ip,port = server:getIpPort()
								if not string.find(url,"^/") then
									url = "/"..url
								end
								url = "http://"..ip..":"..port..url
								self.referenceimages[self.mode.."item"..id] = id
								self:_retrieveImage(url,self.mode.."item"..id,"false","true")
							end
						end,
						nil,
						cmd
					)
				end
			end,
			nil,
			{'can','gallery','random','?'}
		)
	end
end

function _updateAlbumCover(self,widget,id,size,mode,index,free)
	local player = appletManager:callService("getCurrentPlayer")
	local licensed = true
	if player then
		local playerStatus = player:getPlayerStatus()
		if not mode or (mode == 'play' and playerStatus.mode == 'play') or (mode != 'play' and playerStatus.mode != 'play') then
			if playerStatus.item_loop and (licensed or free) then
				local iconId = nil
				if playerStatus.item_loop[index] then
					iconId = playerStatus.item_loop[index]["icon-id"] or playerStatus.item_loop[index]["icon"]
				end
				local server = player:getSlimServer()
				if _getNumber(size,nil) then
					if iconId then
						log:debug("Get fresh artwork for icon-id "..tostring(iconId))
						if widget then
							server:fetchArtwork(iconId,widget:getWidget(id),size)
						else
							server:fetchArtwork(iconId,Icon("artwork"),size)
						end
					elseif playerStatus.item_loop[index] and playerStatus.item_loop[index]["params"]["track_id"] then
						log:debug("Get fresh artwork for track_id "..tostring(playerStatus.item_loop[index]["params"]["track_id"]))
						if widget then
							server:fetchArtwork(playerStatus.item_loop[index]["params"]["track_id"],widget:getWidget(id),self:_getCoverSize(size),'png')
						else
							server:fetchArtwork(playerStatus.item_loop[index]["params"]["track_id"],Icon("artwork"),size)
						end
					elseif widget then
						widget:setWidgetValue(nil)
					end
				else
					if iconId then
						if widget then
							server:fetchArtwork(iconId,widget:getWidget(id),self:_getCoverSize(size))
						else
							server:fetchArtwork(iconId,Icon("artwork"),self:_getCoverSize(size))
						end
					elseif playerStatus.item_loop[index] and playerStatus.item_loop[index]["params"]["track_id"] then
						if widget then
							server:fetchArtwork(playerStatus.item_loop[index]["params"]["track_id"],widget:getWidget(id),self:_getCoverSize(size),'png')
						else
							server:fetchArtwork(playerStatus.item_loop[index]["params"]["track_id"],Icon("artwork"),self:_getCoverSize(size),'png')
						end
					elseif widget then
						widget:setWidgetValue(nil)
					end
				end
			elseif widget then
				widget:setWidgetValue(id,nil)
			end
		elseif widget then
			widget:setWidgetValue(id,nil)
		end
	elseif widget then
		widget:setWidgetValue(id,nil)
	end
end

-- Update the time and if needed also the wallpaper
function _tick(self,forcedUpdate)
	log:debug("Updating time")

	local second = os.date("%S")
	if tonumber(second)<tonumber(self.lastsecond) then
		self.secondoffset = tonumber(self.secondoffset) + 60
	end
	if second % 3 == 0 then
		if self.nowPlaying>=3 then
			self.nowPlaying = 1
		else
			self.nowPlaying = self.nowPlaying + 1
		end
	end

	local player = appletManager:callService("getCurrentPlayer")
	if self.mode == "configalarmactive" and player then
		local alarmstate = player:getPlayerStatus()["alarm_state"]
		if not alarmstate or alarmstate != "active" then
			self:closeScreensaver()
		end
	end

	self:_updateVisibilityGroups()

	local minute = os.date("%M")

	local updatesdtitems = {}
	local changesdtitems = {}
	local updatepluginitems = {}
	local updaterssitems = {}
	local changepluginitems = {}
	local changerssitems = {}
	local no = 1
	local refreshCustomItemTypes = self.refreshCustomItemTypes
	local licensed = true
	self.refreshCustomItemTypes = {}
	for _,item in pairs(self.configItems) do
		if item.itemtype == "timetext" then
			if licensed or item.free then
				self.items[no]:setWidgetValue("itemno",self:_getLocalizedDateInfo(nil,_getString(item.text,"%H:%M")))
			else
				self.items[no]:setWidgetValue("itemno",tostring(self:string("SCREENSAVER_CUSTOMCLOCK_NEEDS_LICENSE")))
			end
		elseif item.itemtype == "text" then
			if licensed or item.free then
				self.items[no]:setWidgetValue("itemno",item.text)
			else
				self.items[no]:setWidgetValue("itemno",tostring(self:string("SCREENSAVER_CUSTOMCLOCK_NEEDS_LICENSE")))
			end
		elseif item.itemtype == "alarmtimetext" then
			if (licensed or item.free) and player then
				local alarmtime = player:getPlayerStatus()["alarm_next"]
				local alarmstate = player:getPlayerStatus()["alarm_state"]

				if alarmstate=="set" then
					self.items[no]:setWidgetValue("itemno",self:_getLocalizedDateInfo(alarmtime,_getString(item.text,"%H:%M")))
				else
					self.items[no]:setWidgetValue("itemno","")
				end
			elseif (licensed or item.free) then
				self.items[no]:setWidgetValue("itemno","")
			else
				self.items[no]:setWidgetValue("itemno",tostring(self:string("SCREENSAVER_CUSTOMCLOCK_NEEDS_LICENSE")))
			end
		elseif item.itemtype == "wirelessicon" then
			if licensed or item.free then
				local wirelessMode = string.gsub(iconbar.iconWireless:getStyle(),"^button_wireless_","")
				log:debug("Wireless status is "..tostring(wirelessMode))
				if self.images[self.mode.."item"..no.."."..wirelessMode] then
					log:debug("Wireless status is "..wirelessMode)
					self.items[no]:setWidgetValue("itemno",self.images[self.mode.."item"..no.."."..wirelessMode])
				elseif wirelessMode != "NONE" then
					self.items[no]:setWidgetValue("itemno",self.images[self.mode.."item"..no])
				else
					self.items[no]:setWidgetValue("itemno",nil)
				end
			end
		elseif item.itemtype == "sleepicon" then
			if licensed or item.free then
				local sleepMode = string.gsub(iconbar.iconSleep:getStyle(),"^button_sleep_","")
				log:debug("Sleep status is "..tostring(sleepMode))
				if self.images[self.mode.."item"..no.."."..sleepMode] then
					log:debug("Sleep status is "..sleepMode)
					self.items[no]:setWidgetValue("itemno",self.images[self.mode.."item"..no.."."..sleepMode])
				elseif sleepMode == "ON" then
					self.items[no]:setWidgetValue("itemno",self.images[self.mode.."item"..no])
				else
					self.items[no]:setWidgetValue("itemno",nil)
				end
			end
		elseif item.itemtype == "batteryicon" then
			if licensed or item.free then
				local batteryMode = string.gsub(iconbar.iconBattery:getStyle(),"^button_battery_","")
				log:debug("Battery status is "..tostring(batteryMode))
				if self.images[self.mode.."item"..no.."."..batteryMode] then
					self.items[no]:setWidgetValue("itemno",self.images[self.mode.."item"..no.."."..batteryMode])
				elseif batteryMode != "NONE" then
					self.items[no]:setWidgetValue("itemno",self.images[self.mode.."item"..no])
				else
					self.items[no]:setWidgetValue("itemno",nil)
				end
			end
		elseif item.itemtype == "alarmicon" then
			if licensed or item.free then
				if player then
					local alarmstate = player:getPlayerStatus()["alarm_state"]

					log:debug("Alarm state is "..tostring(alarmstate))
					if alarmstate=="active" or alarmstate=="snooze" or alarmstate=="set" then
						if self.images[self.mode.."item"..no.."."..alarmstate] then
							self.items[no]:setWidgetValue("itemno",self.images[self.mode.."item"..no.."."..alarmstate])
						else
							self.items[no]:setWidgetValue("itemno",self.images[self.mode.."item"..no])
						end
					else
						self.items[no]:setWidgetValue("itemno",nil)
					end
				else
					self.items[no]:setWidgetValue("itemno",nil)
				end
			end
		elseif item.itemtype == "shufflestatusicon" then
			if licensed or item.free then
				if player then
					local status = tonumber(player:getPlayerStatus()["playlist shuffle"])
					if status == 1 then
						status = "songs"
					elseif status == 2 then
						status = "albums"
					else
						status = nil
					end
					log:debug("Shuffle state is "..tostring(status))
					if status and self.images[self.mode.."item"..no.."."..status] then
						self.items[no]:setWidgetValue("itemno",self.images[self.mode.."item"..no.."."..status])
					else
						self.items[no]:setWidgetValue("itemno",nil)
					end
				else
					self.items[no]:setWidgetValue("itemno",nil)
				end
			end
		elseif item.itemtype == "repeatstatusicon" then
			if licensed or item.free then
				if player then
					local status = tonumber(player:getPlayerStatus()["playlist repeat"])
					if status == 1 then
						status = "song"
					elseif status == 2 then
						status = "playlist"
					else
						status = nil
					end
					log:debug("Repeat state is "..tostring(status))
					if status and self.images[self.mode.."item"..no.."."..status] then
						self.items[no]:setWidgetValue("itemno",self.images[self.mode.."item"..no.."."..status])
					else
						self.items[no]:setWidgetValue("itemno",nil)
					end
				else
					self.items[no]:setWidgetValue("itemno",nil)
				end
			end
		elseif item.itemtype == "playstatusicon" then
			if licensed or item.free then
				if player then
					local mode = player:getPlayerStatus()["mode"]
					log:debug("Play state is "..tostring(mode))
					if mode and self.images[self.mode.."item"..no.."."..mode] then
						self.items[no]:setWidgetValue("itemno",self.images[self.mode.."item"..no.."."..mode])
					else
						self.items[no]:setWidgetValue("itemno",nil)
					end
				else
					self.items[no]:setWidgetValue("itemno",nil)
				end
			end
		elseif item.itemtype == "timeicon" then
			if licensed or item.free then
				if _getString(item.text,nil) ~= nil then
					local number = _getNumber(os.date(item.text),0)
					if self.images[self.mode.."item"..no] then
						local w,h = self.images[self.mode.."item"..no]:getSize()
						if self.items[no]:getWidget("itemno"):getImage() == nil then
							self.items[no]:setWidgetValue("itemno",Surface:newRGB(item.width,h))
						end
						if self.images[self.mode.."item"..no..".background"] ~= nil then
							self.images[self.mode.."item"..no..".background"]:blit(self.items[no]:getWidget("itemno"):getImage(),0,0)
						end
						if number*item.width<w then
							self.images[self.mode.."item"..no]:blitClip(number*item.width,0,item.width,h,self.items[no]:getWidget("itemno"):getImage(),0,0)
						end
					end
				end
			end
		elseif item.itemtype == "ratingicon" then
			if licensed or item.free then
				self:_updateRatingIcon(self.items[no],"item"..no,nil,item.free)
			end
		elseif item.itemtype == "ratingplayingicon" then
			if licensed or item.free then
				self:_updateRatingIcon(self.items[no],"item"..no,"play",item.free)
			end
		elseif item.itemtype == "ratingstoppedicon" then
			if licensed or item.free then
				self:_updateRatingIcon(self.items[no],"item"..no,"stop",item.free)
			end
		elseif item.itemtype == "switchingtrackplayingtext" then
			self:_updateNowPlaying(self.nowPlaying,self.items[no],"itemno","stop",item.free)
		elseif item.itemtype == "switchingtrackstoppedtext" then
			self:_updateNowPlaying(self.nowPlaying,self.items[no],"itemno","play",item.free)
		elseif item.itemtype == "switchingtracktext" then
			self:_updateNowPlaying(self.nowPlaying,self.items[no],"itemno",nil,item.free)
		elseif item.itemtype == "tracktext" then
			self:_updateStaticNowPlaying(self.items[no],"itemno",item.text,nil,item.free)
		elseif item.itemtype == "trackplayingtext" then
			self:_updateStaticNowPlaying(self.items[no],"itemno",item.text,"play",item.free)
		elseif item.itemtype == "trackstoppedtext" then
			self:_updateStaticNowPlaying(self.items[no],"itemno",item.text,"stop",item.free)
		elseif item.itemtype == "sdttext" then
			if forcedUpdate then
				self:_updateFromCache(no)		
				self:_updateSDTText(self.items[no],no,item.sdtformat,item.period)
			end
		elseif item.itemtype == "sdtweathertext" or item.itemtype == "sdtweathericon" then
			if forcedUpdate then
				self:_updateFromCache(no)		
				if not updatesdtitems["weather"] then
					updatesdtitems["weather"] = {
						attribute = "weather",
						items = {}
					}
				end
				updatesdtitems["weather"].items[no] = item
			elseif second % _getNumber(item.interval,3) == 0 then
				local results = self:_getSDTCacheData("weather",item)
				if results and #results>0 then
					if not changesdtitems["weather"] then
						changesdtitems["weather"] = {}
					end
					changesdtitems["weather"][no] = item
				else
					if string.find(item.itemtype,"text$") then
						self.items[no]:setWidgetValue("itemno","")
					else
						self.items[no]:setWidgetValue("itemno",nil)
					end
				end
			end
		elseif item.itemtype == "sdtsporttext" or item.itemtype == "sdtsporticon" then
			if forcedUpdate then
				self:_updateFromCache(no)		
				if not updatesdtitems["sport"] then
					updatesdtitems["sport"] = {
						attribute = "sport",
						items = {}
					}
				end
				updatesdtitems["sport"].items[no] = item
			elseif second % _getNumber(item.interval,3) == 0 then
				local results = self:_getSDTCacheData("sport",item)
				if results and #results>0 then
					if not changesdtitems["sport"] then
						changesdtitems["sport"] = {}
					end
					changesdtitems["sport"][no] = item
				else
					if string.find(item.itemtype,"text$") then
						self.items[no]:setWidgetValue("itemno","")
					else
						self.items[no]:setWidgetValue("itemno",nil)
					end
				end
			end
		elseif item.itemtype == "sdtstocktext" or item.itemtype == "sdtstockicon" then
			if forcedUpdate then
				self:_updateFromCache(no)		
				if not updatesdtitems["stocks"] then
					updatesdtitems["stocks"] = {
						attribute = "stock",
						items = {}
					}
				end
				updatesdtitems["stocks"].items[no] = item
			elseif second % _getNumber(item.interval,3) == 0 then
				local results = self:_getSDTCacheData("stocks",item)
				if results and #results>0 then
					if not changesdtitems["stocks"] then
						changesdtitems["stocks"] = {}
					end
					changesdtitems["stocks"][no] = item
				else
					if string.find(item.itemtype,"text$") then
						self.items[no]:setWidgetValue("itemno","")
					else
						self.items[no]:setWidgetValue("itemno",nil)
					end
				end
			end
		elseif item.itemtype == "sdtmisctext" or item.itemtype == "sdtmiscicon" then
			local infotype = _getString(item.infotype,"default")
			if forcedUpdate then
				self:_updateFromCache(no)		
				if not updatesdtitems[infotype] then
					updatesdtitems[infotype] = {
						attribute = "selected",
						items = {}
					}
				end
				updatesdtitems[infotype].items[no] = item
			elseif second % _getNumber(item.interval,3) == 0 then
				local results = self:_getSDTCacheData(infotype,item)
				if results and #results>0 then
					if not changesdtitems[infotype] then
						changesdtitems[infotype] = {}
					end
					changesdtitems[infotype][no] = item
				else
					if string.find(item.itemtype,"text$") then
						self.items[no]:setWidgetValue("itemno","")
					else
						self.items[no]:setWidgetValue("itemno",nil)
					end
				end
			end
		elseif item.itemtype == "plugintext" or item.itemtype == "pluginicon" then
			local infotype = _getString(item.infotype,"default")
			if forcedUpdate then
				self:_updateFromCache(no)		
				if not updatepluginitems[infotype] then
					updatepluginitems[infotype] = {
						attribute = "selected",
						items = {}
					}
				end
				updatepluginitems[infotype].items[no] = item
			elseif second % _getNumber(item.interval,3) == 0 then
				local results = self:_getPluginItemCacheData(infotype,item)
				if results and #results>0 then
					if not changepluginitems[infotype] then
						changepluginitems[infotype] = {}
					end
					changepluginitems[infotype][no] = item
				else
					if string.find(item.itemtype,"text$") then
						self.items[no]:setWidgetValue("itemno","")
					else
						self.items[no]:setWidgetValue("itemno",nil)
					end
				end
			end
		elseif item.itemtype == "rsstext" or item.itemtype == "rssicon" then
			local url = _getString(item.url,"default")
			if forcedUpdate or (self.lastminute!=minute  and minute % _getNumber(item.refreshinterval,30) == 0) then
				self:_updateFromCache(no)		
				if not updaterssitems[url] then
					updaterssitems[url] = {
						attribute = "selected",
						items = {}
					}
				end
				updaterssitems[url].items[no] = item
			elseif (self.secondoffset+second) % _getNumber(item.interval,3) == 0 then
				local results = self:_getRSSItemCacheData(url,item)
				if results and #results>0 then
					if not changerssitems[url] then
						changerssitems[url] = {}
					end
					changerssitems[url][no] = item
				else
					if string.find(item.itemtype,"text$") then
						self.items[no]:setWidgetValue("itemno","")
					else
						self.items[no]:setWidgetValue("itemno",nil)
					end
				end
			end
		elseif item.itemtype == "covericon" then
			self:_updateAlbumCover(self.items[no],"itemno",item.size,nil,1,item.free)
			-- Pre-load next artwork
			self:_updateAlbumCover(nil,"itemno",item.size,nil,2,item.free)
		elseif item.itemtype == "coverplayingicon" then
			self:_updateAlbumCover(self.items[no],"itemno",item.size,"play",1,item.free)
			-- Pre-load next artwork
			self:_updateAlbumCover(nil,"itemno",item.size,"play",2,item.free)
		elseif item.itemtype == "coverstoppedicon" then
			self:_updateAlbumCover(self.items[no],"itemno",item.size,"stop",1,item.free)
			-- Pre-load next artwork
			self:_updateAlbumCover(nil,"itemno",item.size,"stop",2,item.free)
		elseif item.itemtype == "covernexticon" then
			self:_updateAlbumCover(self.items[no],"itemno",item.size,nil,2,item.free)
		elseif item.itemtype == "covernextplayingicon" then
			self:_updateAlbumCover(self.items[no],"itemno",item.size,"play",2,item.free)
		elseif item.itemtype == "covernextstoppedicon" then
			self:_updateAlbumCover(self.items[no],"itemno",item.size,"stop",2,item.free)
		elseif item.itemtype == "galleryicon" then
			if forcedUpdate or self.lastminute!=minute or (_getNumber(item.interval,nil) and second % tonumber(item.interval) == 0) then
				self:_updateFromCache(no)		
				self:_updateGalleryImage(self.items[no],no,item.width,item.height,item.favorite)
			end
		elseif item.itemtype == "sdticon" then
			if forcedUpdate then
				self:_updateFromCache(no)		
				if not updatesdtitems["weather"] then
					updatesdtitems["weather"] = {
						attribute = "weather",
						items = {}
					}
				end
				updatesdtitems["weather"].items[no] = item
			end
		elseif item.itemtype == "sdtweathermapicon" then
			if forcedUpdate then
				self:_updateFromCache(no)		
				self:_updateSDTWeatherMapIcon(self.items[no],no,item)
			elseif self.lastminute!=minute and (not item.url or (minute % 15 == 0 and not _getNumber(item.interval,nil)) or (_getNumber(item.interval,nil) and minute % tonumber(item.interval)==0)) then
				if item.url then
					self.referenceimages[self.mode.."item"..no] = no
					self:_retrieveImage(item.url,self.mode.."item"..no,_getString(item.allowproxy,"true"),"true",item.width,item.height,_getNumber(item.clipx,nil),_getNumber(item.clipy,nil),_getNumber(item.clipwidth,nil),_getNumber(item.clipheight,nil))
				else
					self:_updateSDTWeatherMapIcon(self.items[no],no,item)
				end
			end
		elseif item.itemtype == "songinfoicon" then
			if forcedUpdate or (minute % 3 == 0 and self.lastminute!=minute) then
				self:_updateFromCache(no)		
				local width,height = Framework.getScreenSize()
				self:_updateSongInfoIcon(self.items[no],no,_getNumber(item.width,width),_getNumber(item.height,height),item.songinfomodule,"true",_getString(item.allowproxy,"true"))
			elseif second % _getNumber(item.interval,10) == 0 and item.urls and #item.urls>0 then
				local width,height = Framework.getScreenSize()
				local imageNo = math.random(1,#item.urls)
				self.referenceimages[self.mode.."item"..no] = no
				self:_retrieveImage(item.urls[imageNo],self.mode.."item"..no,_getString(item.allowproxy,"true"),"true",_getNumber(item.width,width),_getNumber(item.height,height))
			end
		elseif item.itemtype == "imageicon" and _getString(item.url,nil) then
			if forcedUpdate or (minute % _getNumber(item.interval,30) == 0 and self.lastminute!=minute) then
				self:_updateFromCache(no)		
				self.referenceimages[self.mode.."item"..no] = no
				self:_retrieveImage(item.url,self.mode.."item"..no,_getString(item.allowproxy,"true"),_getString(item.dynamic,"true"),_getNumber(item.width,nil),_getNumber(item.height,nil),_getNumber(item.clipx,nil),_getNumber(item.clipy,nil),_getNumber(item.clipwidth,nil),_getNumber(item.clipheight,nil))
			end
		elseif item.itemtype == "appleticon" then
			if self.customItemTypes and _getString(item.icontype,nil) and self.customItemTypes[item.icontype.."icon"] then
				if forcedUpdate or (refreshCustomItemTypes and refreshCustomItemTypes[item.icontype.."icon"]) or (_getString(item.interval,nil) and second % item.interval == 0) or self.lastminute!=minute then
					local instance = appletManager:loadApplet(self.customItemTypes[item.icontype.."icon"].applet)
					if instance and instance[self.customItemTypes[item.icontype.."icon"].method] then
						log:debug("Getting image for appleticon of type: "..item.icontype.. " and image: "..tostring(item.image))
						instance[self.customItemTypes[item.icontype.."icon"].method](instance,instance[self.customItemTypes[item.icontype.."icon"].data],no,_getString(item.image,nil),_getString(item.width,nil),_getString(item.height,nil),function (no,image)
							self.items[no]:setWidgetValue("itemno",image)
						end)
					end
				end
			else
				log:warn("Unknown appleticon, ignoring "..tostring(item.icontype).."...")
			end
		elseif item.itemtype == "applettext" then
			if self.customItemTypes and _getString(item.texttype,nil) and self.customItemTypes[item.texttype.."text"] then
				if forcedUpdate or (refreshCustomItemTypes and refreshCustomItemTypes[item.texttype.."text"]) or (_getString(item.interval,nil) and second % item.interval == 0) or self.lastminute!=minute then
					local instance = appletManager:loadApplet(self.customItemTypes[item.texttype.."text"].applet)
					if instance and instance[self.customItemTypes[item.texttype.."text"].method] then
						log:debug("Getting text for applettext of type: "..item.texttype.. " and text: "..tostring(item.text))
						instance[self.customItemTypes[item.texttype.."text"].method](instance,instance[self.customItemTypes[item.texttype.."text"].data],no,_getString(item.text,nil),function (no,text)
							if self.items[no]:getWidgetValue("itemno") ~= text then
								self.items[no]:setWidgetValue("itemno",text)
							end
						end)
					end
				end
			else
				log:warn("Unknown appleticon, ignoring "..tostring(item.texttype).."...")
			end
		elseif string.find(item.itemtype,"vumeter$") or string.find(item.itemtype,"spectrummeter$") or string.find(item.itemtype,"image$")then
			-- Do nothing, vu/spectrum meters are updated separately
		else
			log:warn("Unknown item type, ignoring "..tostring(item.itemtype).."...")
		end

		no = no +1
	end

	for category,data in pairs(updatesdtitems) do
		if category == "sport" then
			self:_updateSDTSportItem(data.items)
		elseif category == "weather" then
			self:_updateSDTWeatherItem(data.items)
		else
			self:_updateSDTMiscItem(category,data.items,data.attribute)
		end
	end

	for category,data in pairs(updatepluginitems) do
		self:_updatePluginItem(category,data.items)
	end

	for category,data in pairs(updaterssitems) do
		self:_updateRSSItem(category,data.items)
	end

	for category,data in pairs(changesdtitems) do
		for no,item in pairs(data) do
			local key = self:_getSDTCacheKey(category,item)
			if self.sdtcache[category] and self.sdtcache[category][key] and item.currentResult == self.sdtcache[category][key].current then
				self.sdtcache[category][key].current = self:_getNextSDTItem(category,item)
			end
			item.currentResult = self.sdtcache[category][key].current
			if category == "sport" or category == "weather" then
				self:_changeSDTItem(category,item,self.items[no],no,"false")
			else
				self:_changeSDTItem(category,item,self.items[no],no,"true")
			end
		end
	end
	
	for category,data in pairs(changepluginitems) do
		for no,item in pairs(data) do
			local key = self:_getPluginItemCacheKey(category,item)
			if self.pluginitemcache[category] and self.pluginitemcache[category][key] and item.currentResult == self.pluginitemcache[category][key].current then
				self.pluginitemcache[category][key].current = self:_getNextPluginItem(category,item)
			end
			item.currentResult = self.pluginitemcache[category][key].current
			self:_changePluginItem(category,item,self.items[no],no,"true")
		end
	end

	for category,data in pairs(changerssitems) do
		for no,item in pairs(data) do
			local key = self:_getRSSItemCacheKey(category,item)
			if self.rssitemcache[category] and self.rssitemcache[category][key] and item.currentResult == self.rssitemcache[category][key].current then
				self.rssitemcache[category][key].current = self:_getNextRSSItem(category,item)
			end
			item.currentResult = self.rssitemcache[category][key].current
			self:_changeRSSItem(category,item,self.items[no],no,"true")
		end
	end

	if forcedUpdate or ((minute + self.offset) % 15 == 0 and self.lastminute!=minute) then
		self:_imageUpdate()
	end
	self.lastminute = minute
	self.lastsecond = second
	

	local hasImages = false
	for key,image in pairs(self.images) do
		if string.find(key,"image$") then
			hasImages = true
			break
		end
	end	
	if hasImages then
		self.canvas:reSkin()
		self.canvas:reDraw()
	end
end

function _updateFromCache(self,no)		
	item = self.configItems[no]
	self:getSettings()['itemCache'..self.mode] = self:getSettings()['itemCache'..self.mode] or {}
	local cachedItem = self:getSettings()['itemCache'..self.mode][no]
	if cachedItem and cachedItem.value then
		if string.find(item.itemtype,"text$") and (not self.items[no]:getWidgetValue("itemno") or self.items[no]:getWidgetValue("itemno") == "") then
			self.items[no]:setWidgetValue("itemno",cachedItem.value)
		elseif string.find(item.itemtype,"icon$") and self.items[no]:getWidget("itemno") and not self.items[no]:getWidget("itemno"):getImage() then
			self.items[no]:setWidgetValue("itemno",cachedItem.value)
		end
	end
end

function _getLocalizedDateInfo(self,time,text)
	local weekday = os.date("%w",time)
	local month = os.date("%m",time)
	if text and string.find(text,"%%A") then
		text = string.gsub(text,"%%A",tostring(self:string("WEEKDAY_"..weekday)))
	end
	if text and string.find(text,"%%a") then
		text = string.gsub(text,"%%a",tostring(self:string("WEEKDAY_SHORT_"..weekday)))
	end
	if text and string.find(text,"%%B") then
		text = string.gsub(text,"%%B",tostring(self:string("MONTH_"..month)))
	end
	if text and string.find(text,"%%b") then
		text = string.gsub(text,"%%b",tostring(self:string("MONTH_SHORT_"..month)))
	end
	if text and string.find(text,"%%H1") then
		local hour = os.date("%H",time)
		text = string.gsub(text,"%%H1",tostring(tonumber(hour)))
	end
	if text and string.find(text,"%%I1") then
		local hour = os.date("%I",time)
		text = string.gsub(text,"%%I1",tostring(tonumber(hour)))
	end
	if text and string.find(text,"%%m1") then
		local month = os.date("%m",time)
		text = string.gsub(text,"%%m1",tostring(tonumber(month)))
	end
	if text and string.find(text,"%%d1") then
		local month = os.date("%d",time)
		text = string.gsub(text,"%%d1",tostring(tonumber(month)))
	end
	text = os.date(text,time)
	return text
end

function _secondsToString(seconds)
        local hrs = math.floor(seconds / 3600)
        local min = math.floor((seconds / 60) - (hrs*60))
        local sec = math.floor( seconds - (hrs*3600) - (min*60) )

        if hrs > 0 then
                return string.format("%d:%02d:%02d", hrs, min, sec)
        else
                return string.format("%d:%02d", min, sec)
        end
end

function _blitImage(self,screen,id,posx,posy,angle)
	log:debug("Updating "..tostring(id).." at "..tostring(angle)..", "..tostring(x)..", "..tostring(y))
	local tmp = self.images[id]
	if angle and angle!=0 then
		tmp = tmp:rotozoom(-angle, 1, 5)
	end
	local facew, faceh = tmp:getSize()
	x = math.floor(posx - (facew/2))
	y = math.floor(posy - (faceh/2))
	tmp:blit(screen, x, y)
	if angle and angle!=0 then
		tmp:release()
	end
end

function _reDrawAnalog(self,screen) 
	local m = os.date("%M")
	local h = os.date("%I")
	local s = os.date("%S")
	local ah = nil
	local am = nil
	
	local player = appletManager:callService("getCurrentPlayer")
	if player then
		local alarmstate = player:getPlayerStatus()["alarm_state"]
		if alarmstate and alarmstate == "set" then
			local alarmtime = player:getPlayerStatus()["alarm_next"]
			ah = os.date("%I",alarmtime)
			am = os.date("%M",alarmtime)
		end
	end

	local width,height = self:_getUsableWallpaperArea()
	
	local defaultposx = (width/2)
	local defaultposy = (height/2)

	for no,item in pairs(self.configItems) do
		if item.itemtype == "clockimage" then
			local posx = _getNumber(_getNumber(item.posx,self:getSettings()[self.mode.."clockposx"]),defaultposx)
			local posy = _getNumber(_getNumber(item.posy,self:getSettings()[self.mode.."clockposy"]),defaultposy)
			if self.images[self.mode.."item"..no]  then
				self:_blitImage(screen,
					self.mode.."item"..no,
					posx,
					posy)
			end
			if self.images[self.mode.."item"..no..".alarmhour"] and ah and am then
				self:_blitImage(screen,
					self.mode.."item"..no..".alarmhour",
					posx,
					posy,
					(360 / 12) * (ah + (am/60)))
			end
			if self.images[self.mode.."item"..no..".alarmminute"] and am then
				self:_blitImage(screen,
					self.mode.."item"..no..".alarmminute",
					posx,
					posy,
					(360 / 60) * am)
			end
			if self.images[self.mode.."item"..no..".hour"]  then
				self:_blitImage(screen,
					self.mode.."item"..no..".hour",
					posx,
					posy,
					(360 / 12) * (h + (m/60)))
			end
			if self.images[self.mode.."item"..no..".minute"]  then
				self:_blitImage(screen,
					self.mode.."item"..no..".hour",
					posx,
					posy,
					(360 / 60) * m)
			end
			if self.images[self.mode.."item"..no..".second"]  then
				self:_blitImage(screen,
					self.mode.."item"..no..".hour",
					posx,
					posy,
					(360 / 60) * s)
			end
		end
	end

	for no,item in pairs(self.configItems) do
		if item.itemtype == "hourimage" then
			local posx = _getNumber(_getNumber(item.posx,self:getSettings()[self.mode.."clockposx"]),defaultposx)
			local posy = _getNumber(_getNumber(item.posy,self:getSettings()[self.mode.."clockposy"]),defaultposy)
			if self.images[self.mode.."item"..no]  then
				self:_blitImage(screen,
					self.mode.."item"..no,
					posx,
					posy,
					(360 / 12) * (h + (m/60)))
			end
		end
	end

	for no,item in pairs(self.configItems) do
		if item.itemtype == "minuteimage" then
			local posx = _getNumber(_getNumber(item.posx,self:getSettings()[self.mode.."clockposx"]),defaultposx)
			local posy = _getNumber(_getNumber(item.posy,self:getSettings()[self.mode.."clockposy"]),defaultposy)
			if self.images[self.mode.."item"..no]  then
				self:_blitImage(screen,
					self.mode.."item"..no,
					posx,
					posy,
					(360 / 60) * m)
			end
		end
	end

	for no,item in pairs(self.configItems) do
		if item.itemtype == "secondimage" then
			local posx = _getNumber(_getNumber(item.posx,self:getSettings()[self.mode.."clockposx"]),defaultposx)
			local posy = _getNumber(_getNumber(item.posy,self:getSettings()[self.mode.."clockposy"]),defaultposy)
			if self.images[self.mode.."item"..no]  then
				self:_blitImage(screen,
					self.mode.."item"..no,
					posx,
					posy,
					(360 / 60) * s)
			end
		end
	end

	local imageType = "stopped"
	if player then
		local playerStatus = player:getPlayerStatus()
		if playerStatus.mode == 'play' then
			imageType = "playing"
		end
	end
	local duration = 0
	local elapsed = 1
	if player then
		elapsed,duration = player:getTrackElapsed()
	end
	if not duration or duration == 0 then
		duration = 1
		elapsed = 0
	end
	for no,item in pairs(self.configItems) do
		if string.find(item.itemtype,"^rotatingimage") then
			local id = ""
			local rotating = 1
			if _getString(item["url."..imageType.."rotating"],nil) then
				id = "."..imageType.."rotating"
			elseif _getString(item["url."..imageType],nil) then
				id = "."..imageType
				rotating = 0
			end

			if self.images[self.mode.."item"..no..id] then
				local speed = _getNumber(item.speed,10)
				local angle = (360 / 60) * s * speed * rotating

				self:_blitImage(screen,
					self.mode.."item"..no..id,
					_getNumber(item.posx,defaultposx),
					_getNumber(item.posy,defaultposy),
					angle)
			end
		elseif string.find(item.itemtype,"^elapsedimage") then
			local id = ""
			if _getString(item["url."..imageType.."rotating"],nil) then
				id = "."..imageType.."rotating"
			elseif _getString(item["url.rotating"],nil) then
				id = ".rotating"
			end

			if self.images[self.mode.."item"..no..id] then
				local range = (_getNumber(item.finalangle,360)-_getNumber(item.initialangle,0))
				if range<0 then
					range = -range
				end
				local angle = _getNumber(item.initialangle,0) + (range / duration) * elapsed

				self:_blitImage(screen,
					self.mode.."item"..no..id,
					_getNumber(item.posx,defaultposx),
					_getNumber(item.posy,defaultposy),
					angle)
			end

			id = ""
			if _getString(item["url."..imageType.."clippingx"],nil) then
				id = "."..imageType.."clippingx"
			elseif _getString(item["url.clippingx"],nil) then
				id = ".clippingx"
			end

			if self.images[self.mode.."item"..no..id] then
				local tmp = self.images[self.mode.."item"..no..id]
				local facew, faceh = tmp:getSize()
				x = _getNumber(item.posx,0)
				y = _getNumber(item.posy,0)
				local clipwidth = math.floor(_getNumber(item.width,width) * elapsed / duration)
				log:debug("Updating clipping elapsed image at "..x..", "..y.." with width "..clipwidth)
				tmp:blitClip(0, 0,clipwidth,faceh,screen, x,y)
			end

			id = ""
			if _getString(item["url."..imageType.."slidingx"],nil) then
				id = "."..imageType.."slidingx"
			elseif _getString(item["url.slidingx"],nil) then
				id = ".slidingx"
			end

			if self.images[self.mode.."item"..no..id] then
				local tmp = self.images[self.mode.."item"..no..id]
				local facew, faceh = tmp:getSize()
				local posx = math.floor(_getNumber(item.width,width-facew) * elapsed / duration)
				posx = _getNumber(item.posx,0) + posx
				x = _getNumber(posx,0)
				y = _getNumber(item.posy,0)
				log:debug("Updating sliding elapsed image at "..x..", "..y)
				tmp:blit(screen, x, y)
			end
		end
	end
end

function _retrieveImage(self,url,imageType,allowProxy,dynamic,width,height,clipX,clipY,clipWidth,clipHeight)
	local imagehost = ""
	local imageport = tonumber("80")
	local imagepath = ""

	allowProxy = "false"

	if not _getString(url,nil) then
		return
	end
	local start,stop,value = string.find(url,"http://([^/]+)")
	if value and value != "" then
		imagehost = value
		local start, stop,value = string.find(imagehost,":(.+)$")
		if value and value != "" then
			imageport = tonumber(value)
			imagehost = string.gsub(imagehost,":"..imageport,"")
		end
	end
	start,stop,value = string.find(url,"http://[^/]+(.+)")
	if value and value != "" then
		imagepath = value
	end

	if imagepath != "" and imagehost != "" then
 		if allowProxy == "false" or
			string.find(url, "^http://192%.168") or
			string.find(url, "^http://172%.16%.") or
			string.find(url, "^http://10%.") then
			-- Use direct url
		else
                        imagehost = jnt:getSNHostname()
			imageport = tonumber(80)
			imagepath = '/public/imageproxy?u=' .. string.urlEncode(url)
			if width then
				imagepath = imagepath.."&w="..width
			end				
			if height then
				imagepath = imagepath.."&h="..height
			end
			if width or height then
				imagepath = imagepath.."&m=p"
			end				
                end
		log:debug("Getting image for "..imageType.." from "..imagehost.." and "..imageport.." and "..imagepath)
		local appletdir = _getAppletDir()
		local cacheName = string.urlEncode(url)
		if width then
			cacheName = cacheName.."-w"..width
		end
		if height then
			cacheName = cacheName.."-h"..height
		end
		if _getString(dynamic,"false") == "false" and lfs.attributes(appletdir.."JLCustomClock/images/"..cacheName) then
			log:debug("Image found in cache: "..cacheName)
			local fh = io.open(appletdir.."JLCustomClock/images/"..cacheName, "rb")
			local chunk = fh:read("*all")
			fh:close()
			self:_retrieveImageData(url,imageType,chunk,clipX,clipY,clipWidth,clipHeight)
		else
			log:debug("Image not found in cache, getting from source: "..url)
			local http = SocketHttp(jnt, imagehost, imageport)
			local req = RequestHttp(function(chunk, err)
					if chunk then
						if _getString(dynamic,"false") == "false" then
							lfs.mkdir(appletdir.."JLCustomClock/images")
					                local fh = io.open(appletdir.."JLCustomClock/images/"..cacheName, "w")
					                fh:write(chunk)
							fh:close()
						end
						self:_retrieveImageData(url,imageType,chunk,clipX,clipY,clipWidth,clipHeight)
					elseif err then
						log:warn("error loading picture " .. url .. " (" .. err .. ")")
					end
				end,
				'GET', imagepath)
			http:fetch(req)
		end
	else
		local luadir = _getLuaDir()
		if lfs.attributes(luadir..url) ~= nil then
			local fh = io.open(luadir..url, "rb")
			local chunk = fh:read("*all")
			fh:close()
			self:_retrieveImageData(url,imageType,chunk,clipX,clipY,clipWidth,clipHeight)
		else 
			log:warn("Unable to parse url "..url..", got: "..imagehost..", "..imagepath)
		end
	end
end

function _retrieveImageData(self,url,imageType,chunk,clipX,clipY,clipWidth,clipHeight)
	local width,height = self:_getUsableWallpaperArea()
	local image = Surface:loadImageData(chunk, #chunk)
	if clipWidth and clipHeight and clipX and clipY then
		local newImg = Surface:newRGBA(clipWidth, clipHeight)
        newImg:filledRectangle(0, 0, clipWidth, clipHeight, 0x000000FF)
		image:blitClip(clipX,clipY,clipWidth,clipHeight,newImg,0,0)
		image = newImg
	end
	if string.find(imageType,"background$") then
		local w,h = image:getSize()

		local zoom
		if w>h or self.model == "controller" then
			log:debug("width based zoom ".. width .. "/" .. w .. "=" .. (width/w))
			zoom = width/w
		else
			log:debug("height based zoom ".. height .. "/" .. h .. "=" .. (height/h))
			zoom = height/h
		end
		image = image:rotozoom(0,zoom,1)
		self.backgroundImage:setWidgetValue("background",image)
		self.wallpaperImage:setValue(image)
	end
	log:debug("Storing downloaded image for "..imageType)
	self.images[imageType] = image
	if self.vumeterimages[imageType] ~= nil then
		local id = "background"
		if string.find(imageType,"%.") then
			id = string.gsub(imageType,"^.*%.","")
		end
		log:debug("Setting visualizer image: "..id)
		self.items[self.vumeterimages[imageType]]:getWidget("itemno"):setImage(id,image)
	elseif self.referenceimages[imageType] ~= nil then
		self.items[self.referenceimages[imageType]]:getWidget("itemno"):setValue(image)
		self:_storeInCache(self.referenceimages[imageType],image)
	end
	log:debug("image ready")
end

function _removeFromCache(self,id)
	if self:getSettings()['itemCache'..self.mode] then
		self:getSettings()['itemCache'..self.mode][id] = nil
	end
end

function _storeInCache(self,id,value)
	self:getSettings()['itemCache'..self.mode] = self:getSettings()['itemCache'..self.mode] or {}
	self:getSettings()['itemCache'..self.mode][id] = {
		value = value
	}
end

function _imageUpdate(self)
	log:debug("Initiating image update (offset="..self.offset.. " minutes)")

	local licensed = true
	local no = 1
	for _,item in pairs(self.configItems) do
		if string.find(item.itemtype,"icon$") and item.itemtype ~= "imageicon" and item.itemtype ~= "rssicon" then
			for attr,value in pairs(item) do
				if attr == "url" then
					if _getString(item.url,nil) then
						self:_retrieveImage(item.url,self.mode.."item"..no,_getString(item.allowproxy,"true"),item.dynamic,_getNumber(item.clipx,nil),_getNumber(item.clipy,nil),_getNumber(item.clipwidth,nil),_getNumber(item.clipheight,nil))
					else
						self.images[self.mode.."item"..no] = nil
					end
				elseif string.find(attr,"^url%.") then
					local id = string.gsub(attr,"^url%.","")
					if _getString(value,nil) then
						self:_retrieveImage(value,self.mode.."item"..no.."."..id,_getString(item.allowproxy,"true"),item.dynamic,_getNumber(item.clipx,nil),_getNumber(item.clipy,nil),_getNumber(item.clipwidth,nil),_getNumber(item.clipheight,nil))
					else
						self.images[self.mode.."item"..no.."."..id] = nil
					end
				end
			end
		elseif string.find(item.itemtype,"image$") then
			for attr,value in pairs(item) do
				if attr == "url" then
					if _getString(item.url,nil) then
						self:_retrieveImage(item.url,self.mode.."item"..no,_getString(item.allowproxy,"true"),item.dynamic,_getNumber(item.clipx,nil),_getNumber(item.clipy,nil),_getNumber(item.clipwidth,nil),_getNumber(item.clipheight,nil))
					else
						self.images[self.mode.."item"..no] = nil
					end
				elseif string.find(attr,"^url%.") then
					local id = string.gsub(attr,"^url%.","")
					if _getString(value,nil) then
						self:_retrieveImage(value,self.mode.."item"..no.."."..id,_getString(item.allowproxy,"true"),item.dynamic,_getNumber(item.clipx,nil),_getNumber(item.clipy,nil),_getNumber(item.clipwidth,nil),_getNumber(item.clipheight,nil))
					else
						self.images[self.mode.."item"..no.."."..id] = nil
					end
				end
			end
		elseif string.find(item.itemtype,"vumeter$") then
			for attr,value in pairs(item) do
				if attr == "url" then
					self.vumeterimages[self.mode.."item"..no] = no
					if _getString(item.url,nil) then
						self:_retrieveImage(item.url,self.mode.."item"..no,_getString(item.allowproxy,"true"),item.dynamic,_getNumber(item.clipx,nil),_getNumber(item.clipy,nil),_getNumber(item.clipwidth,nil),_getNumber(item.clipheight,nil))
					else
						self.images[self.mode.."item"..no] = nil
					end
				elseif string.find(attr,"^url%.") then
					local id = string.gsub(attr,"^url%.","")
					self.vumeterimages[self.mode.."item"..no.."."..id] = no
					if _getString(value,nil) then
						self:_retrieveImage(value,self.mode.."item"..no.."."..id,_getString(item.allowproxy,"true"),item.dynamic,_getNumber(item.clipx,nil),_getNumber(item.clipy,nil),_getNumber(item.clipwidth,nil),_getNumber(item.clipheight,nil))
					else
						self.images[self.mode.."item"..no.."."..id] = nil
					end
				end
			end
		end
		no = no +1
	end
	if _getString(self:getSettings()[self.mode.."background"],nil) then
		self:_retrieveImage(self:getSettings()[self.mode.."background"],self.mode.."background","true",self:getSettings()[self.mode.."backgrounddynamic"])
	else
		self.images[self.mode.."background"] = nil
	end
end

function _getColor(color)
	if color == "white" then
		return {0xff, 0xff, 0xff}
	elseif color =="lightgray" then
		return {0xcc, 0xcc, 0xcc}
	elseif color =="gray" then
		return {0x88, 0x88, 0x88}
	elseif color =="darkgray" then
		return {0x44, 0x44, 0x44}
	elseif color =="black" then
		return {0x00, 0x00, 0x00}
	elseif color == "lightred" then
		return {0xff, 0x00, 0x00}
	elseif color == "red" then
		return {0xcc, 0x00, 0x00}
	elseif color == "darkred" then
		return {0x88, 0x00, 0x00} 
	elseif color == "lightyellow" then
		return {0xff, 0xff, 0x00}
	elseif color == "yellow" then
		return {0xcc, 0xcc, 0x00}
	elseif color == "darkyellow" then
		return {0x88, 0x88, 0x00} 
	elseif color == "lightblue" then
		return {0x00, 0x00, 0xff}
	elseif color == "blue" then
		return {0x00, 0x00, 0xcc}
	elseif color == "darkblue" then
		return {0x00, 0x00, 0x88} 
	elseif color == "lightgreen" then
		return {0x00, 0xff, 0x00}
	elseif color == "green" then
		return {0x00, 0xcc, 0x00}
	elseif color == "darkgreen" then
		return {0x00, 0x88, 0x00} 
	elseif color and string.find(color,"^0x") then
		color = string.gsub(color,"^0x","")
		local number = tonumber(color,16)
		return {number/(256*256*256*256),number/(256*256*256),number/(256*256)}
	else
		return {0xcc, 0xcc, 0xcc}
	end
end

function _getColorNumber(color)
	if color == "white" then
		return 0xffffffff
	elseif color =="lightgray" then
		return 0xccccccff
	elseif color =="gray" then
		return 0x888888ff
	elseif color =="darkgray" then
		return 0x444444ff
	elseif color =="black" then
		return 0x000000ff
	elseif color == "lightred" then
		return 0xff0000ff
	elseif color == "red" then
		return 0xcc0000ff
	elseif color == "darkred" then
		return 0x880000ff 
	elseif color == "lightyellow" then
		return 0xffff00ff
	elseif color == "yellow" then
		return 0xcccc00ff
	elseif color == "darkyellow" then
		return 0x888800ff 
	elseif color == "lightblue" then
		return 0x0000ffff
	elseif color == "blue" then
		return 0x0000ccff
	elseif color == "darkblue" then
		return 0x000088ff 
	elseif color == "lightgreen" then
		return 0x00ff00ff
	elseif color == "green" then
		return 0x00cc00ff
	elseif color == "darkgreen" then
		return 0x008800ff 
	elseif string.find(color,"^0x") then
		color = string.gsub(color,"^0x","")
		return tonumber(color,16)
	else
		return 0xccccccff
	end
end

function _getNumber(value,default)
	value = tonumber(value)
	if value then
		return value
	else
		return default
	end
end

function _getString(value,default)
	if value and value != "" then
		return value
	else
		return default
	end
end

function _getClockSkin(self,skin)
	local s = {}
	local width,height = Framework.getScreenSize()

	s.window = {
		canvas = {
			zOrder = 3,
		},
		background = {
			position = LAYOUT_NONE,
			x = 0,
			y = 0,
			background = {
				w = WH_FILL,
				align = 'center',
			},
			zOrder = 1,
		},			
	}
	
	local licensed = true
	local no = 1
	for _,item in pairs(self.configItems) do
		if string.find(item.itemtype,"text$") then
			s.window["item"..no] = {
				position = LAYOUT_NONE,
				y = _getNumber(item.posy,0),
				x = _getNumber(item.posx,0),
				zOrder = _getNumber(item.order,4),
			}
			local fontSize = _getNumber(item.fontsize,20)
			if not item.free and not licensed and fontSize>20 and (item.itemtype == "text" or string.find(item.itemtype,"timetext$") or string.find(item.itemtype,"track.*text$")) then
				fontSize = 20
			end
			local font = nil
			if _getString(item.fonturl,nil) then
				font = self:_retrieveFont(item.fonturl,item.fontfile,fontSize)
			end
			if not font then
				font = self:_loadFont(self:getSettings()["font"],fontSize)
			end
			local extraHeight = 0
			if _getString(item.animate,"true") == "true" then
				extraHeight = math.ceil(_getNumber(item.fontsize,20)/5)
			end
			s.window["item"..no]["item"..no] = {
					border = {_getNumber(item.margin,10),0,_getNumber(item.margin,10),0},
					font = font,
					align = _getString(item.align,"center"),
					w = _getNumber(item.width,WH_FILL),
					h = _getNumber(item.height,_getNumber(item.fontsize,20)+extraHeight),
					fg = _getColor(item.color),
				}
			if _getNumber(item.lineheight,nil) then
				s.window["item"..no]["item"..no].lineHeight = _getNumber(item.lineheight,nil)
			end
			if _getNumber(item.line1height,nil) or _getNumber(item.line1fontsize,nil) then
				local line1font = self:_loadFont(_getString(item.fonturl,self:getSettings()["font"]),_getNumber(item.line1fontsize,_getNumber(item.fontsize,20)))
				s.window["item"..no]["item"..no].line = {}
				s.window["item"..no]["item"..no].line[1] = {
					font = line1font,
					height = _getNumber(item.line1height,_getNumber(item.line1fontsize,_getNumber(item.fontsize,20)))
				}
			end
			if _getNumber(item.line2height,nil) or _getNumber(item.line2fontsize,nil) then
				local line2font = self:_loadFont(_getString(item.fonturl,self:getSettings()["font"]),_getNumber(item.line2fontsize,_getNumber(item.fontsize,20)))
				s.window["item"..no]["item"..no].line = s.window["item"..no]["item"..no].line or {}
				s.window["item"..no]["item"..no].line[2] = {
					font = line2font,
					height = _getNumber(item.line2height,_getNumber(item.line2fontsize,_getNumber(item.fontsize,20)))
				}
			end
			if _getNumber(item.line3height,nil) or _getNumber(item.line3fontsize,nil) then
				local line3font = self:_loadFont(_getString(item.fonturl,self:getSettings()["font"]),_getNumber(item.line3fontsize,_getNumber(item.fontsize,20)))
				s.window["item"..no]["item"..no].line = s.window["item"..no]["item"..no].line or {}
				s.window["item"..no]["item"..no].line[3] = {
					font = line3font,
					height = _getNumber(item.line3height,_getNumber(item.line3fontsize,_getNumber(item.fontsize,20)))
				}
			end
		elseif string.find(item.itemtype,"^cover") then
			local defaultSize = WH_FILL
			if _getNumber(item.posx,nil) then
				defaultSize = self:_getCoverSize(item.size)
			end
			s.window["item"..no] = {
				position = LAYOUT_NONE,
				x = _getNumber(item.posx,0),
				y = _getNumber(item.posy,0),
				zOrder = _getNumber(item.order,2),
			}
			s.window["item"..no]["item"..no] = {
					align = _getString(item.align,"center"),
					w = _getNumber(item.size,defaultSize)
				}
		elseif string.find(item.itemtype,"icon$") then
			s.window["item"..no] = {
				position = LAYOUT_NONE,
				x = _getNumber(item.posx,0),
				y = _getNumber(item.posy,0),
				zOrder = _getNumber(item.order,4),
			}
			s.window["item"..no]["item"..no] = {
					align = 'center',
				}
			if _getNumber(item.framewidth,nil) ~= nil then
				s.window["item"..no]["item"..no].frameWidth = _getNumber(item.framewidth,nil)
			end
			if _getNumber(item.framerate,nil) ~= nil then
				s.window["item"..no]["item"..no].frameRate = _getNumber(item.framerate,nil)
			end
		elseif string.find(item.itemtype,"vumeter$") or string.find(item.itemtype,"spectrummeter$") then
			s.window["item"..no] = {
				position = LAYOUT_NONE,
				x = _getNumber(item.posx,0),
				y = _getNumber(item.posy,0),
				w = _getNumber(item.width,width),
				h = _getNumber(item.height,height),
				zOrder = _getNumber(item.order,4),
			}
			s.window["item"..no]["item"..no] = {
					align = 'center',
					x = _getNumber(item.posx,0),
					y = _getNumber(item.posy,0),
					w = _getNumber(item.width,width),
					h = _getNumber(item.height,height),
				}
		end
		no = no +1
	end

	if self:getSettings()[self.mode.."backgroundtype"] == "black" then
		s.window.bgImg= Tile:fillColor(0x000000ff)
		s.window.background.bgImg= Tile:fillColor(0x000000ff)
	elseif self:getSettings()[self.mode.."backgroundtype"] == "white" then
		s.window.bgImg= Tile:fillColor(0xffffffff)
		s.window.background.bgImg= Tile:fillColor(0x000000ff)
	elseif self:getSettings()[self.mode.."backgroundtype"] == "lightgray" then
		s.window.bgImg= Tile:fillColor(0xccccccff)
		s.window.background.bgImg= Tile:fillColor(0x000000ff)
	elseif self:getSettings()[self.mode.."backgroundtype"] == "darkgray" then
		s.window.bgImg= Tile:fillColor(0x444444ff)
		s.window.background.bgImg= Tile:fillColor(0x000000ff)
	elseif self:getSettings()[self.mode.."backgroundtype"] == "gray" then
		s.window.bgImg= Tile:fillColor(0x888888ff)
		s.window.background.bgImg= Tile:fillColor(0x000000ff)
	end
	return s
end

--[[

=head1 LICENSE

Copyright (C) 2009 Erland Isaksson (erland_i@hotmail.com)

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.
   
This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.
    
You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

=cut
--]]


