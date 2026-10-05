local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local L = Glimpse.L

-- Seit Dragonflight liegen die Addon-Funktionen in C_AddOns, die alten Globals können weg sein.
local AddOns = C_AddOns or {}
local GetNumAddOns = AddOns.GetNumAddOns or GetNumAddOns
local GetAddOnInfo = AddOns.GetAddOnInfo or GetAddOnInfo
local GetAddOnDependencies = AddOns.GetAddOnDependencies or GetAddOnDependencies
local IsAddOnLoaded = AddOns.IsAddOnLoaded or IsAddOnLoaded

local ICON_SIZE = 16

-- ---------------------------------------------------------------------------
-- Icons und Versionen
-- ---------------------------------------------------------------------------

--- Texturpfad des Addons aus der TOC (## IconTexture), oder nil.
function Glimpse:GetIcon(addonName)
    local icon = self:GetMeta("IconTexture", addonName)
    if icon and icon ~= "" then return icon end
end

--- Setzt das TOC-Icon des Addons als kleine Inline-Textur vor den Text.
-- Hat das Addon kein Icon, kommt der Text unverändert zurück.
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

-- true, wenn version kleiner als minimum ist. Bei unlesbaren Angaben false (kein Fehlalarm).
local function IsOlder(version, minimum)
    local a1, a2, a3 = ParseVersion(version)
    local b1, b2, b3 = ParseVersion(minimum)
    if not (a1 and b1) then return false end

    if a1 ~= b1 then return a1 < b1 end
    if a2 ~= b2 then return a2 < b2 end
    return a3 < b3
end

-- ---------------------------------------------------------------------------
-- Übersichtsseite
-- ---------------------------------------------------------------------------

-- Alle Addons, die Glimpse als Abhängigkeit eintragen (also die Erweiterungen), nach Name sortiert
local function FindExtensions()
    local found = {}
    if not (GetNumAddOns and GetAddOnInfo and GetAddOnDependencies) then return found end

    for index = 1, GetNumAddOns() do
        -- je nach Clientstand liefert GetAddOnInfo eine Tabelle oder mehrere Werte
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

-- Ein Eintrag der Addon-Liste: Icon, Titel, Version in Grün, darunter die Beschreibung
local function ExtensionBlock(addonName)
    local title = Glimpse:GetMeta("Title", addonName) or addonName
    local version = Glimpse:GetMeta("Version", addonName) or "?"
    -- Titel in Gold, dahinter die Version in Grün: "Glimpse (v0.0.1)"
    local head = format("|cffffd100%s|r |cff40ff40(v%s)|r", title, version)
    local lines = { Glimpse:WithAddonIcon(head, addonName) }

    if IsAddOnLoaded and not IsAddOnLoaded(addonName) then
        tinsert(lines, "    |cff888888" .. L["Not loaded"] .. "|r")
    end

    -- Braucht die Erweiterung ein neueres Glimpse (## X-Glimpse-MinVersion), gibt es einen Hinweis
    local minimum = Glimpse:GetMeta("X-Glimpse-MinVersion", addonName)
    if minimum and IsOlder(Glimpse:GetMeta("Version"), minimum) then
        tinsert(lines, "    |cffff4040" .. format(L["Requires Glimpse %s or newer"], minimum) .. "|r")
    end

    local notes = Glimpse:GetMeta("Notes", addonName)
    if notes and notes ~= "" then tinsert(lines, "    |cffcccccc" .. notes .. "|r") end

    return table.concat(lines, "\n")
end

-- Nur die Erweiterungen, der Core steht oben auf der Seite und nicht in der Liste
local function ExtensionList()
    local names = FindExtensions()
    if #names == 0 then return "|cff888888" .. L["No extensions installed."] .. "|r" end

    local blocks = {}
    for _, addonName in ipairs(names) do tinsert(blocks, ExtensionBlock(addonName)) end
    return table.concat(blocks, "\n\n")
end

-- Zeile "Label: Wert" mit goldenem Label, wie bei /gli info
local function Field(label, value)
    return format("|cffffd100%s:|r %s", label, value)
end

function Glimpse:BuildOverview()
    return {
        type = "group", order = 1, name = L["Overview"],
        args = {
            title = {
                type = "description", order = 1, fontSize = "large",
                name = function() return self:GetMeta("Title") or self.name end,
                image = function() return self:GetIcon(self.name) end,
                imageWidth = 32, imageHeight = 32,
            },
            -- GetAddOnMetadata liefert "Notes" automatisch in der Clientsprache (Notes-deDE ...)
            -- und fällt auf das englische Notes zurück, wenn es die Sprache nicht gibt.
            notes = {
                type = "description", order = 2, fontSize = "medium",
                name = function() return self:GetMeta("Notes") or "" end,
            },
            -- als Funktionen, damit die Werte erst beim Anzeigen ausgelesen werden
            info = {
                type = "description", order = 3, fontSize = "medium",
                name = function()
                    local _, _, _, toc = GetBuildInfo()
                    return table.concat({
                        Field(L["Version"], self:GetMeta("Version") or "?"),
                        Field(L["Author"], self:GetMeta("Author") or "?"),
                        Field(L["Game version"], "Interface " .. tostring(toc)),
                    }, "\n")
                end,
            },
            extensionsHeader = { type = "header", order = 10, name = L["Installed extensions"] },
            extensions = {
                type = "description", order = 11, fontSize = "medium",
                name = ExtensionList,
            },
        },
    }
end

-- ---------------------------------------------------------------------------
-- Optionen
-- ---------------------------------------------------------------------------

-- Die Options-Tabelle im AceConfig-Format. Wird in SetupOptions registriert.
-- Die Seiten des Core sind Tabs, die Erweiterungen hängen als eigene Einträge darunter.
function Glimpse:BuildOptions()
    return {
        type = "group",
        childGroups = "tab",
        -- Titel aus der TOC, dadurch ist er automatisch lokalisiert (Title-deDE)
        name = self:GetMeta("Title") or self.name,
        args = {
            overview = self:BuildOverview(),
            general = {
                type = "group", order = 2, name = L["General"],
                args = {
                    debug = {
                        type = "toggle", order = 1,
                        name = L["Debug mode"],
                        desc = L["Prints additional diagnostic messages to chat."],
                        get = function() return self.db.profile.debug end,
                        -- über SetDebug, damit die Chat-Meldung auch beim Klick kommt
                        set = function(_, value) self:SetDebug(value) end,
                    },
                },
            },
            -- "profiles" (Order 100) kommt in SetupOptions dazu, falls AceDBOptions geladen ist
        },
    }
end

--- Baut die einheitliche Optionsseite einer Erweiterung. Alle Erweiterungen sehen dadurch gleich aus:
--
--   [Icon] Glimpse: Name        (Titel aus der TOC, wird in RegisterAddonOptions gesetzt)
--   Beschreibung                (Notes aus der TOC, klein und grau)
--   +-- Optionen -------------+
--   |  args der Erweiterung   |
--   +-------------------------+
--   Version x.y.z               (klein und grau)
--
-- args sind die Optionen der Erweiterung im AceConfig-Format (nur der Inhalt von "args").
function Glimpse:BuildAddonPage(addonName, args, tabs)
    local function Grey(text) return "|cff999999" .. text .. "|r" end

    local function VersionText()
        return Grey(L["Version"] .. ": " .. (self:GetMeta("Version", addonName) or "?"))
    end

    local page = {
        type = "group",
        name = self:GetMeta("Title", addonName) or addonName,
        args = {
            -- Das Icon steht links neben der Beschreibung, direkt unter der Panel-Überschrift
            notes = {
                type = "description", order = 2, width = "full", fontSize = "small",
                name = function()
                    local notes = self:GetMeta("Notes", addonName)
                    return notes and Grey(notes) or ""
                end,
                image = function() return self:GetIcon(addonName) end,
                imageWidth = 32, imageHeight = 32,
            },
        },
    }

    if tabs then
        -- Mit Tabs sind args selbst die Tab-Gruppen. Alles, was keine Gruppe ist, zeichnet
        -- AceConfig oberhalb der Tabs, deshalb steht die Version hier direkt unter der Beschreibung.
        page.childGroups = "tab"
        page.args.version = { type = "description", order = 3, width = "full", fontSize = "small", name = VersionText }
        for key, group in pairs(args) do page.args[key] = group end
    else
        -- eine inline-Gruppe wird mit Rahmen gezeichnet und hebt die Optionen ab
        page.args.options = { type = "group", inline = true, order = 10, name = L["Options"], args = args }
        -- AceConfig kann Text nicht rechtsbündig setzen, deshalb steht die Version linksbündig unter dem Rahmen
        page.args.version = { type = "description", order = 91, width = "full", fontSize = "small", name = VersionText }
    end

    return page
end

--- Registriert die Optionsseite einer Erweiterung im einheitlichen Aufbau (BuildAddonPage).
-- Das ist der Normalfall für Erweiterungen. Der TOC-Titel heißt "Glimpse: Name" und ist die
-- Überschrift des Panels (mit Icon). Im Einstellungsbaum steht darunter nur "Name" mit Icon,
-- das "Glimpse: " wird dafür abgeschnitten, weil der Eintrag ohnehin unter Glimpse hängt.
-- Mit tabs = true sind args keine einzelnen Optionen, sondern Tab-Gruppen (type = "group"),
-- die statt des Rahmens "Optionen" als Tabs angezeigt werden.
function Glimpse:RegisterAddonOptions(addonName, args, tabs)
    local title = self:GetMeta("Title", addonName) or addonName
    local page = self:BuildAddonPage(addonName, args, tabs)

    local prefix = (self:GetMeta("Title") or self.name) .. ": "
    local treeName = title
    if strsub(title, 1, #prefix) == prefix then treeName = strsub(title, #prefix + 1) end

    -- Einträge im Einstellungsbaum sind standardmäßig weiß, per Farbcode werden sie gelb
    local frame = self:RegisterOptions(addonName, page, "|cffffd100" .. treeName .. "|r", addonName)

    -- AceConfigDialog nimmt für Baumeintrag und Panel-Überschrift denselben Text. Die Überschrift
    -- setzen wir deshalb danach selbst.
    local widget = frame and frame.obj
    if widget and widget.SetTitle then
        widget:SetTitle(self:WithAddonIcon(title, addonName))
    end
    return frame
end

--- Hängt eine weitere Options-Tabelle als Unterpunkt unter das Haupt-Panel.
-- key muss pro Addon eindeutig sein. Das Haupt-Panel muss schon existieren, also
-- frühestens im OnInitialize eines Moduls aufrufen.
-- addonName ist optional: mit dem Namen der Erweiterung steht ihr TOC-Icon vor dem Eintrag.
function Glimpse:RegisterOptions(key, options, displayName, addonName)
    local appName = self.name .. "_" .. key
    LibStub("AceConfig-3.0"):RegisterOptionsTable(appName, options)

    local label = displayName or options.name or key
    if addonName then label = self:WithAddonIcon(label, addonName) end
    -- AceConfigDialog sucht die Elternkategorie über den angezeigten Namen (mit Icon), nicht über den Addon-Namen
    return LibStub("AceConfigDialog-3.0"):AddToBlizOptions(appName, label, self.categoryName)
end

function Glimpse:SetupOptions()
    local options = self:BuildOptions()

    -- AceDBOptions ist optional. Mit true bekommen wir nil statt eines Fehlers,
    -- falls die Lib in der Ace3-Kopie fehlt. Dann gibt es eben keinen Profil-Tab.
    local AceDBOptions = LibStub("AceDBOptions-3.0", true)
    if AceDBOptions then
        local profiles = AceDBOptions:GetOptionsTable(self.db)
        profiles.order = 100
        profiles.name = L["Profiles"]
        options.args.profiles = profiles
    end

    LibStub("AceConfig-3.0"):RegisterOptionsTable(self.name, options)

    -- Der zweite Rückgabewert ist die Kategorie-ID fürs neue Settings-Fenster.
    -- Je nach Ace3-Version kann das anders aussehen, falls /gli config mal nichts öffnet hier schauen.
    local title = self:WithAddonIcon(self:GetMeta("Title") or self.name, self.name)
    self.categoryName = title
    local _, categoryID = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(self.name, title)
    self.categoryID = categoryID
end

function Glimpse:OpenOptions()
    if Settings and Settings.OpenToCategory and self.categoryID then
        Settings.OpenToCategory(self.categoryID)
    else
        -- Fallback: eigenes Ace-Fenster
        LibStub("AceConfigDialog-3.0"):Open(self.name)
    end
end
