local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local L = Glimpse.L

-- Credits der ganzen Suite, einmal in der Core-Übersicht unter einer Trennlinie. Erweiterungen haben keinen eigenen
-- Credits-Tab; was sie bei RegisterAddonOptions als credits mitgeben, erscheint hier mit ihrem Titel.

-- { Name, Rolle (Locale-Key) }
local SPECIAL_THANKS = {
    { "Flovy", "Tester" },
    { "sMash", "Tester" },
}

-- Bildnachweise der Erweiterungen: Addon-Ordner -> { Bild (Locale-Key), Autor, Link }
local IMAGE_CREDITS = {
    Glimpse_GatheringTooltip = {
        { "Pin", "Karacis (Flaticon)", "https://www.flaticon.com/de/kostenloses-icon/ort_5338544" },
        { "Solid pin", "Magnific (Flaticon)", "https://www.flaticon.com/de/kostenloses-icon/standort_3699580" },
        { "Outline pin", "Magnific (Flaticon)", "https://www.flaticon.com/de/kostenloses-icon/ort_2794702" },
        { "Person", "kawalanicon (Flaticon)", "https://www.flaticon.com/de/kostenloses-icon/weiblicher-benutzer_18851090" },
        { "Arrow", "Magnific (Flaticon)", "https://www.flaticon.com/de/kostenloses-icon/navigation_3699548" },
    },
    Glimpse_Statistics = {
        { "Analytics", "Pixel perfect (Flaticon)", "https://www.flaticon.com/free-icon/analytics_731794" },
    },
}

Glimpse.addonCredits = {} -- Addon-Ordner -> credits aus RegisterAddonOptions

local function Gold(text)
    return "|cffffd100" .. text .. "|r"
end

local function Link(url)
    return " |cff66ccff(" .. url .. ")|r"
end

--- credits einer Erweiterung merken: { contributors = { "Name (wofür)" }, images = { "..." }, thanks = { "..." } }
function Glimpse:AddCredits(addonName, credits)
    if type(credits) == "table" then self.addonCredits[addonName] = credits end
end

local function Sorted(map)
    local names = {}
    for name in pairs(map) do names[#names + 1] = name end
    table.sort(names)
    return names
end

-- Listen der Suite: Mitwirkende, Bildnachweise, Dank; jeder Eintrag mit dem Titel seines Addons
function Glimpse:CollectCredits()
    local lists = { contributors = {}, images = {}, thanks = {} }
    local known = {} -- Links aus IMAGE_CREDITS, damit Erweiterungen sie nicht doppelt liefern

    for _, addonName in ipairs(Sorted(IMAGE_CREDITS)) do
        local title = self:GetMeta("Title", addonName) or addonName
        for _, image in ipairs(IMAGE_CREDITS[addonName]) do
            known[image[3]] = true
            tinsert(lists.images, format("%s: %s - %s%s", title, L[image[1]], image[2], Link(image[3])))
        end
    end

    for _, addonName in ipairs(Sorted(self.addonCredits)) do
        local title = self:GetMeta("Title", addonName) or addonName
        for kind, list in pairs(lists) do
            for _, entry in ipairs(self.addonCredits[addonName][kind] or {}) do
                local url = entry:match("https?://[^%s%)|]+")
                if not (url and known[url]) then tinsert(list, format("%s: %s", title, entry)) end
            end
        end
    end

    for _, entry in ipairs(SPECIAL_THANKS) do
        tinsert(lists.thanks, format("%s (%s)", entry[1], L[entry[2]]))
    end
    return lists
end

--- Credits-Bereich (Trennlinie mit Überschrift + Text) für die Core-Übersicht. Autor aus ## Author.
function Glimpse:BuildCreditsArgs(order)
    order = order or 90
    return {
        creditsHeader = { type = "header", order = order, name = L["Credits"] },
        credits = {
            type = "description", order = order + 1, width = "full", fontSize = "medium",
            name = function()
                local blocks = {}
                local author = self:GetMeta("Author")
                if author and author ~= "" then blocks[#blocks + 1] = Gold(L["Author"] .. ":") .. " " .. author end
                local lists = self:CollectCredits()
                for _, block in ipairs({
                    { L["Contributors"], lists.contributors },
                    { L["Image credits"], lists.images },
                    { L["Special thanks"], lists.thanks },
                }) do
                    if #block[2] > 0 then
                        local lines = { Gold(block[1] .. ":") }
                        for _, entry in ipairs(block[2]) do lines[#lines + 1] = "- " .. entry end
                        blocks[#blocks + 1] = table.concat(lines, "\n")
                    end
                end
                return table.concat(blocks, "\n\n")
            end,
        },
    }
end
