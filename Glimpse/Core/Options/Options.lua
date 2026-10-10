local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local L = Glimpse.L

-- Ältere Clients haben nur die Globals
local AddOns = C_AddOns or {}
local GetNumAddOns = AddOns.GetNumAddOns or GetNumAddOns
local GetAddOnInfo = AddOns.GetAddOnInfo or GetAddOnInfo
local GetAddOnDependencies = AddOns.GetAddOnDependencies or GetAddOnDependencies
local IsAddOnLoaded = AddOns.IsAddOnLoaded or IsAddOnLoaded

local ICON_SIZE = 16
-- Icon neben der Beschreibung, Pixel
local PAGE_ICON_SIZE = 48

-- ---------------------------------------------------------------------------
-- Icons und Versionen
-- ---------------------------------------------------------------------------

--- Texturpfad des Addons aus der TOC (## IconTexture), oder nil.
function Glimpse:GetIcon(addonName)
    local icon = self:GetMeta("IconTexture", addonName)
    if icon and icon ~= "" then return icon end
end

--- TOC-Icon als Inline-Textur vor den Text, ohne Icon unverändert.
function Glimpse:WithAddonIcon(text, addonName)
    local icon = self:GetIcon(addonName)
    if not icon then return text end
    return format("|T%s:%d:%d:0:0|t %s", icon, ICON_SIZE, ICON_SIZE, text)
end

-- "1.2.3" -> 1, 2, 3. Fehlende Teile zählen als 0, Unlesbares ergibt nil.
local function ParseVersion(version)
    local major, minor, patch = strmatch(version or "", "^(%d+)%.?(%d*)%.?(%d*)")
    if not major then return nil end
    return tonumber(major), tonumber(minor) or 0, tonumber(patch) or 0
end

-- Unlesbare Versionen ergeben false (kein Fehlalarm)
local function IsOlder(version, minimum)
    local a1, a2, a3 = ParseVersion(version)
    local b1, b2, b3 = ParseVersion(minimum)
    if not (a1 and b1) then return false end

    if a1 ~= b1 then return a1 < b1 end
    if a2 ~= b2 then return a2 < b2 end
    return a3 < b3
end

--- Beschreibung (Notes aus der TOC, klein und grau) mit dem Icon daneben. Gleich für jede Seite.
function Glimpse:BuildNotes(addonName, order)
    return {
        type = "description", order = order, width = "full", fontSize = "small",
        name = function()
            local notes = self:GetMeta("Notes", addonName)
            return notes and ("|cff999999" .. notes .. "|r") or ""
        end,
        image = function() return self:GetIcon(addonName) end,
        imageWidth = PAGE_ICON_SIZE, imageHeight = PAGE_ICON_SIZE,
    }
end

-- ---------------------------------------------------------------------------
-- Übersichtsseite
-- ---------------------------------------------------------------------------

-- Erweiterungen = Addons mit Glimpse als Abhängigkeit, sortiert
local function FindExtensions()
    local found = {}
    if not (GetNumAddOns and GetAddOnInfo and GetAddOnDependencies) then return found end

    for index = 1, GetNumAddOns() do
        -- GetAddOnInfo liefert je nach Client Tabelle oder Einzelwerte
        local info = GetAddOnInfo(index)
        local name = type(info) == "table" and info.name or info

        if name and name ~= Glimpse.name then
            for _, dependency in ipairs({ GetAddOnDependencies(index) }) do
                if dependency == Glimpse.name then
                    tinsert(found, name)
                    break
                end
            end
        end
    end

    table.sort(found)
    return found
end

local function ExtensionBlock(addonName)
    local title = Glimpse:GetMeta("Title", addonName) or addonName
    local version = Glimpse:GetMeta("Version", addonName) or "?"
    local head = format("|cffffd100%s|r |cff40ff40(v%s)|r", title, version)
    local lines = { Glimpse:WithAddonIcon(head, addonName) }

    if IsAddOnLoaded and not IsAddOnLoaded(addonName) then
        tinsert(lines, "    |cff888888" .. L["Not loaded"] .. "|r")
    end

    -- ## X-Glimpse-MinVersion
    local minimum = Glimpse:GetMeta("X-Glimpse-MinVersion", addonName)
    if minimum and IsOlder(Glimpse:GetMeta("Version"), minimum) then
        tinsert(lines, "    |cffff4040" .. format(L["Requires Glimpse %s or newer"], minimum) .. "|r")
    end

    local notes = Glimpse:GetMeta("Notes", addonName)
    if notes and notes ~= "" then tinsert(lines, "    |cffcccccc" .. notes .. "|r") end

    return table.concat(lines, "\n")
end

-- Ohne Core, der steht oben auf der Seite
local function ExtensionList()
    local names = FindExtensions()
    if #names == 0 then return "|cff888888" .. L["No extensions installed."] .. "|r" end

    local blocks = {}
    for _, addonName in ipairs(names) do tinsert(blocks, ExtensionBlock(addonName)) end
    return table.concat(blocks, "\n\n")
end

local function Field(label, value)
    return format("|cffffd100%s:|r %s", label, value)
end

function Glimpse:BuildOverview()
    local overview = {
        type = "group", order = 1, name = L["Overview"],
        args = {
            -- erst beim Anzeigen auslesen
            info = {
                type = "description", order = 3, fontSize = "medium",
                name = function()
                    local _, _, _, toc = GetBuildInfo()
                    local game = Field(L["Game version"], "Interface " .. tostring(toc))
                    -- Ohne Fußzeile steht die Version hier
                    if self.versionFooter then return game end
                    return Field(L["Version"], self:GetMeta("Version") or "?") .. "\n" .. game
                end,
            },
            extensionsHeader = { type = "header", order = 10, name = L["Installed extensions"] },
            extensions = {
                type = "description", order = 11, fontSize = "medium",
                name = ExtensionList,
            },
        },
    }
    for key, option in pairs(self:BuildCreditsArgs(20)) do overview.args[key] = option end
    return overview
end

-- ---------------------------------------------------------------------------
-- Optionen
-- ---------------------------------------------------------------------------

-- Core-Seiten als Tabs, Erweiterungen als eigene Einträge darunter
function Glimpse:BuildOptions()
    return {
        type = "group",
        childGroups = "tab",
        -- TOC-Titel ist schon lokalisiert (Title-deDE)
        name = self:GetMeta("Title") or self.name,
        args = {
            -- wie bei den Erweiterungen: Icon und Beschreibung stehen über den Tabs
            notes = self:BuildNotes(self.name, 0),
            overview = self:BuildOverview(),
            general = {
                type = "group", order = 2, name = L["General"],
                args = {
                    -- Debug immer als erste Option
                    debug = {
                        type = "toggle", order = 1, width = "full",
                        name = L["Debug mode"],
                        desc = L["Prints additional diagnostic messages to chat."],
                        get = function() return self.db.profile.debug end,
                        -- über SetDebug für die Chat-Meldung
                        set = function(_, value) self:SetDebug(value) end,
                    },
                    distanceUnit = self:BuildDistanceOptions(2),
                    doubleclick = self:BuildDoubleClickOptions(3),
                },
            },
            combat = self:BuildCombatOptions(2.5),
            records = self.BuildRecordOptions and self:BuildRecordOptions(2.6) or nil,
            data = self:BuildDataOptions(3),
            -- "profiles" (order 100) kommt in SetupOptions dazu
        },
    }
end

--- Einheitliche Optionsseite einer Erweiterung:
--
--   [Icon] Glimpse: Name        (TOC-Titel, gesetzt in RegisterAddonOptions)
--   Beschreibung                (Notes aus der TOC, klein und grau)
--   [Optionen] [...]            (Tabs; Credits stehen gesammelt in der Core-Übersicht)
--   +-------------------------+
--   |  args der Erweiterung   |
--   +-------------------------+
--   Version x.y.z               (klein und grau, unter dem ganzen Rahmen)
--
-- args = Inhalt von "args" im AceConfig-Format
function Glimpse:BuildAddonPage(addonName, args, tabs, credits)
    local page = {
        type = "group",
        name = self:GetMeta("Title", addonName) or addonName,
        args = {
            notes = self:BuildNotes(addonName, 2),
        },
    }

    -- tabs = true: args sind selbst Tab-Gruppen, sonst Tab "Optionen". Nicht-Gruppen zeichnet AceConfig
    -- über den Tabs, deshalb steht die Version unter dem Rahmen (AddVersionFooter).
    page.childGroups = "tab"
    if tabs then
        for key, group in pairs(args) do page.args[key] = group end
    else
        page.args.options = { type = "group", order = 1, name = L["Options"], args = args }
    end
    self:AddCredits(addonName, credits)

    return page
end

-- Pixel
local FOOTER_HEIGHT = 14

--- Version unter den Panel-Rahmen setzen. AceConfig kann nichts unter Tabs zeichnen, deshalb wird
-- der Inhalt der BlizOptionsGroup um eine Zeile gekürzt. false, wenn das Widget nicht passt.
function Glimpse:AddVersionFooter(widget, addonName)
    local frame, content = widget and widget.frame, widget and widget.content
    if not (frame and content and frame.CreateFontString and content.SetPoint) then return false end

    -- SetTitle setzt die Anker zurück und wird bei jedem Öffnen aufgerufen, daher nach jedem Aufruf neu setzen
    content:SetPoint("BOTTOMRIGHT", -10, 10 + FOOTER_HEIGHT)
    local setTitle = widget.SetTitle
    if setTitle then
        widget.SetTitle = function(this, ...)
            setTitle(this, ...)
            content:SetPoint("BOTTOMRIGHT", -10, 10 + FOOTER_HEIGHT)
        end
    end
    local setHeight = widget.OnHeightSet
    if setHeight then
        widget.OnHeightSet = function(this, height) setHeight(this, height - FOOTER_HEIGHT) end
        local height = frame.GetHeight and frame:GetHeight() or 0
        if height > 0 then widget:OnHeightSet(height) end
    end

    -- Eigener Frame mit hohem Level, sonst malt der Tab-Rahmen Rand und Schatten darüber
    local holder = frame
    if CreateFrame then
        holder = CreateFrame("Frame", nil, frame)
        holder:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 12, 4)
        holder:SetSize(300, 16)
        holder:SetFrameLevel((frame.GetFrameLevel and frame:GetFrameLevel() or 0) + 50)
    end
    local text = holder:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    if holder == frame then
        text:SetPoint("BOTTOMLEFT", 17, 4)
    else
        text:SetPoint("LEFT", holder, "LEFT", 5, 0)
    end
    text:SetJustifyH("LEFT")
    text:SetText(L["Version"] .. ": " .. (self:GetMeta("Version", addonName) or "?"))

    return true
end

--- Standardweg für Erweiterungen: Seite aus BuildAddonPage registrieren.
-- Panel-Überschrift = TOC-Titel "Glimpse: Name", im Baum nur "Name" (hängt eh unter Glimpse).
-- tabs/credits wie bei BuildAddonPage.
function Glimpse:RegisterAddonOptions(addonName, args, tabs, credits)
    local title = self:GetMeta("Title", addonName) or addonName
    local page = self:BuildAddonPage(addonName, args, tabs, credits)

    local prefix = (self:GetMeta("Title") or self.name) .. ": "
    local treeName = title
    if strsub(title, 1, #prefix) == prefix then treeName = strsub(title, #prefix + 1) end

    -- Baumeintrag gelb statt weiß
    local frame = self:RegisterOptions(addonName, page, "|cffffd100" .. treeName .. "|r", addonName)

    -- AceConfigDialog nutzt denselben Text für Baum und Überschrift, Überschrift daher selbst setzen
    local widget = frame and frame.obj
    if widget and widget.SetTitle then
        widget:SetTitle(self:WithAddonIcon(title, addonName))
    end

    -- Fallback: Version als letzte Zeile in jedem Tab
    do
        local ok, done = pcall(self.AddVersionFooter, self, widget, addonName)
        if not (ok and done) then
            for _, group in pairs(page.args) do
                if type(group) == "table" and group.type == "group" then
                    group.args = group.args or {}
                    group.args.version = group.args.version or {
                        type = "description", order = 999, width = "full", fontSize = "small",
                        name = "|cff999999" .. L["Version"] .. ": " .. (self:GetMeta("Version", addonName) or "?") .. "|r",
                    }
                end
            end
        end
    end
    return frame
end

--- Options-Tabelle als Unterpunkt des Haupt-Panels. key eindeutig pro Addon,
-- frühestens in OnInitialize eines Moduls. Mit addonName steht dessen TOC-Icon davor.
function Glimpse:RegisterOptions(key, options, displayName, addonName)
    local appName = self.name .. "_" .. key
    LibStub("AceConfig-3.0"):RegisterOptionsTable(appName, options)

    local label = displayName or options.name or key
    if addonName then label = self:WithAddonIcon(label, addonName) end
    -- Elternkategorie wird über den angezeigten Namen (mit Icon) gefunden
    return LibStub("AceConfigDialog-3.0"):AddToBlizOptions(appName, label, self.categoryName)
end

function Glimpse:SetupOptions()
    local options = self:BuildOptions()

    -- optional, ohne Lib kein Profil-Tab
    local AceDBOptions = LibStub("AceDBOptions-3.0", true)
    if AceDBOptions then
        local profiles = AceDBOptions:GetOptionsTable(self.db)
        profiles.order = 100
        profiles.name = L["Profiles"]
        options.args.profiles = profiles
    end

    LibStub("AceConfig-3.0"):RegisterOptionsTable(self.name, options)

    -- 2. Rückgabe = Kategorie-ID fürs Settings-Fenster. Öffnet /gli config nichts, hier zuerst schauen (Ace3-Version).
    local title = self:WithAddonIcon(self:GetMeta("Title") or self.name, self.name)
    self.categoryName = title
    local frame, categoryID = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(self.name, title)
    self.categoryID = categoryID

    -- Version unter dem Tab-Rahmen wie bei den Erweiterungen
    local ok, done = pcall(self.AddVersionFooter, self, frame and frame.obj, self.name)
    self.versionFooter = ok and done
end

function Glimpse:OpenOptions()
    if Settings and Settings.OpenToCategory and self.categoryID then
        Settings.OpenToCategory(self.categoryID)
    else
        LibStub("AceConfigDialog-3.0"):Open(self.name)
    end
end
