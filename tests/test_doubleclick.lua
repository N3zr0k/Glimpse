-- luacheck: ignore 111 113 122 143 432
local stub = require("wowstub")

-- Doppelklick-Verteiler (Core/DoubleClick) mit nachgebautem Secure-Button und Bindungen
local function setup()
    local Glimpse = stub.newGlimpse()
    Glimpse.name = "Glimpse"
    Glimpse.db = { profile = { debug = false, debugOff = {} } }
    function Glimpse:Print() end
    function Glimpse.db:RegisterNamespace(_, defaults)
        local profile = {}
        for key, value in pairs(defaults.profile) do
            profile[key] = type(value) == "table" and {} or value
        end
        return { profile = profile }
    end
    _G.tContains = function(t, v) for _, x in ipairs(t) do if x == v then return true end end return false end
    stub.load("Core/Debug/DebugTag.lua", "Glimpse")
    stub.load("Core/Debug/Debug.lua", "Glimpse")
    stub.load("Core/Debug/Debugger.lua", "Glimpse")
    stub.load("Core/Debug/Probes.lua", "Glimpse")
    for _, file in ipairs({ "DoubleClick", "DoubleClickSituation", "DoubleClickButton", "DoubleClickOptions",
        "DoubleClickDebug" }) do
        stub.load("Core/DoubleClick/" .. file .. ".lua", "Glimpse")
    end

    local DC = Glimpse.modules.DoubleClick
    local world = { speed = 0, falling = false, swimming = false, submerged = false, mounted = false, indoors = false,
        combat = false, bindings = {} }
    local button = { attributes = {} }
    function button:SetAttribute(key, value) self.attributes[key] = value end
    function button:RegisterForClicks() end
    function button:SetScript(name, func) self[name] = func end

    for key, value in pairs({
        GetTime = function() return stub.now end,
        GetUnitSpeed = function() return world.speed end,
        IsFalling = function() return world.falling end,
        IsSwimming = function() return world.swimming end,
        IsSubmerged = function() return world.submerged end,
        IsMounted = function() return world.mounted end,
        IsFlying = function() return false end,
        IsFlyableArea = function() return world.flyable end,
        IsIndoors = function() return world.indoors end,
        IsOutdoors = function() return not world.indoors end,
        InCombatLockdown = function() return world.combat end,
        UnitAffectingCombat = function() return world.combat end,
        IsShiftKeyDown = function() return stub.keys.shift end,
        IsControlKeyDown = function() return stub.keys.ctrl end,
        IsAltKeyDown = function() return stub.keys.alt end,
        CreateFrame = function() return button end,
        SetOverrideBindingClick = function(_, _, key) world.bindings[key] = true end,
        ClearOverrideBindings = function() world.bindings = {} end,
        After = function(_, func) stub.timers[#stub.timers + 1] = func end,
    }) do DC.api[key] = value end

    DC:OnInitialize()
    Glimpse:BuildDoubleClickOptions(1)
    return Glimpse, DC, world, button
end

-- Zwei Klicks im Abstand von 0,2 s
local function DoubleClick(DC, mouseButton)
    DC:OnMouseDown("GLOBAL_MOUSE_DOWN", mouseButton or "RightButton")
    stub.now = stub.now + 0.2
    DC:OnMouseDown("GLOBAL_MOUSE_DOWN", mouseButton or "RightButton")
end

-- Klick auf den Secure-Button (Down und Up)
local function Press(button)
    button.PreClick(button, "RightButton", true)
    button.PostClick(button, "RightButton", true)
    button.PreClick(button, "RightButton", false)
    button.PostClick(button, "RightButton", false)
end

local function Spell(name)
    return function() return { type = "spell", spell = name } end
end

test("Doppelklick: zweiter Klick bindet die Taste, Prepare setzt den Zauber", function()
    local G, DC, world, button = setup()
    local prepared = 0
    G:RegisterDoubleClick("fishing", { modifier = "SHIFT", Prepare = function(ctx)
        prepared = prepared + 1
        eq(ctx.standing, true, "Lage im ctx")
        return { type = "spell", spell = "Fischen" }
    end })
    stub.keys.shift = true

    DC:OnMouseDown("GLOBAL_MOUSE_DOWN", "RightButton")
    eq(world.bindings["SHIFT-BUTTON2"], nil, "erster Klick bleibt beim Spiel")
    stub.now = stub.now + 0.2
    DC:OnMouseDown("GLOBAL_MOUSE_DOWN", "RightButton")
    eq(world.bindings["SHIFT-BUTTON2"], true, "zweiter Klick gebunden")

    button.PreClick(button, "RightButton", true)
    eq(button.attributes.type, "spell", "Typ")
    eq(button.attributes.spell, "Fischen", "Zauber")
    button.PreClick(button, "RightButton", false)
    eq(prepared, 1, "Prepare nur einmal je Klick")
    button.PostClick(button, "RightButton", false)
    eq(next(world.bindings), nil, "Bindung danach gelöst")
end)

test("Doppelklick: zu langsam, falsche Taste oder Prellen zählt nicht", function()
    local G, DC, world = setup()
    G:RegisterDoubleClick("fishing", { modifier = "SHIFT", Prepare = Spell("Fischen") })
    stub.keys.shift = true

    DC:OnMouseDown(nil, "RightButton")
    stub.now = stub.now + 0.5
    DC:OnMouseDown(nil, "RightButton")
    eq(next(world.bindings), nil, "zu langsam")

    stub.now = stub.now + 0.01
    DC:OnMouseDown(nil, "RightButton")
    eq(next(world.bindings), nil, "Prellen")

    stub.keys.shift = false
    DoubleClick(DC)
    eq(next(world.bindings), nil, "ohne Shift kein Handler")
    DoubleClick(DC, "LeftButton")
    eq(next(world.bindings), nil, "andere Maustaste")
end)

test("Doppelklick: Bedingungen aus when und Match", function()
    local G, DC, world = setup()
    G:RegisterDoubleClick("mount", { modifier = "ALT", when = { canMount = true }, Prepare = Spell("Reiten") })
    G:RegisterDoubleClick("dontdie", { modifier = "ALT", when = { falling = true }, priority = 50,
        Prepare = Spell("Langsamer Fall") })
    G:RegisterDoubleClick("swim", { modifier = "ALT", when = { underwater = true }, Match = function(ctx)
        return ctx.swimming
    end, Prepare = Spell("Wasseratmung") })
    stub.keys.alt = true

    local ctx = DC:Situation("ALT", "RightButton")
    eq(DC:Choose("ALT", "RightButton", ctx), "mount", "draußen im Stehen: Reittier")

    world.falling = true
    ctx = DC:Situation("ALT", "RightButton")
    eq(ctx.standing, false, "fallend steht man nicht")
    eq(DC:Choose("ALT", "RightButton", ctx), "dontdie", "fallend: höhere Priorität")

    world.falling, world.swimming, world.submerged = false, true, true
    ctx = DC:Situation("ALT", "RightButton")
    eq(ctx.canMount, false, "im Wasser kein Reittier")
    eq(DC:Choose("ALT", "RightButton", ctx), "swim", "unter Wasser")

    world.swimming, world.submerged, world.indoors = false, false, true
    local name, reason = DC:Choose("ALT", "RightButton", DC:Situation("ALT", "RightButton"))
    eq(name, nil, "drinnen passt keiner")
    eq(reason ~= nil, true, "Grund fürs Log")

    world.indoors, world.mounted, world.speed = false, true, 7
    ctx = DC:Situation("ALT", "RightButton")
    eq(ctx.mounted, true, "aufgesessen")
    eq(ctx.moving, true, "in Bewegung")
    eq(ctx.canMount, false, "aufgesessen: nicht nochmal")
    eq(ctx.outdoors, true, "draußen")
    eq(ctx.flyable, false, "kein Fluggebiet")
    world.flyable = true
    eq(DC:Situation("ALT", "RightButton").flyable, true, "Fluggebiet")
end)

test("Doppelklick: Priorität und Abschalten in den Optionen", function()
    local G, DC = setup()
    G:RegisterDoubleClick("a", { modifier = "SHIFT", priority = 10, Prepare = Spell("A") })
    G:RegisterDoubleClick("b", { modifier = "SHIFT", priority = 5, Prepare = Spell("B") })
    local ctx = DC:Situation("SHIFT", "RightButton")
    eq(DC:Choose("SHIFT", "RightButton", ctx), "a", "Vorgabe der Addons")

    DC.settings.profile.priority.b = 20
    eq(DC:Choose("SHIFT", "RightButton", ctx), "b", "überschrieben")
    DC.settings.profile.off.b = true
    eq(DC:Choose("SHIFT", "RightButton", ctx), "a", "abgeschaltet")

    DC.settings.profile.off.b = nil
    DC.settings.profile.priority.b = 10
    eq(DC:Choose("SHIFT", "RightButton", ctx), "a", "Gleichstand: Name")
end)

test("Doppelklick: zentrale Taste gilt für alle", function()
    local G, DC, world = setup()
    G:RegisterDoubleClick("fishing", { modifier = function() return "SHIFT" end, Prepare = Spell("Fischen") })
    eq(G:IsDoubleClickCentral(), false, "aus")
    eq(G:GetDoubleClickText("fishing"), "Shift + Double click right", "eigene Taste")

    DC.settings.profile.central = true
    DC.settings.profile.modifier = "CTRL"
    DC.settings.profile.button = "MiddleButton"
    eq(G:IsDoubleClickCentral(), true, "an")
    eq(select(1, G:GetDoubleClickKey("fishing")), "CTRL", "zentrale Zusatztaste")
    eq(G:GetDoubleClickText("fishing"), "Ctrl + Double click middle", "Text")

    stub.keys.ctrl = true
    DoubleClick(DC, "MiddleButton")
    eq(world.bindings["CTRL-BUTTON3"], true, "zentrale Taste gebunden")
end)

test("Doppelklick: im Kampf passiert nichts, danach wird aufgeräumt", function()
    local G, DC, world, button = setup()
    G:RegisterDoubleClick("fishing", { modifier = "SHIFT", Prepare = Spell("Fischen") })
    stub.keys.shift = true
    world.combat = true
    DoubleClick(DC)
    eq(next(world.bindings), nil, "keine Bindung im Kampf")
    eq(DC.log[#DC.log]:find("in combat", 1, true) ~= nil, true, "Log")

    world.combat = false
    DoubleClick(DC)
    world.combat = true
    button.PreClick(button, "RightButton", true)
    eq(button.attributes.type, nil, "Kampf vor dem Klick: nichts wirken")
    world.combat = false
    DC:OnCombatEnd()
    eq(next(world.bindings), nil, "nach dem Kampf gelöst")
end)

test("Doppelklick: Prepare ohne Aktion, Fehler und verfallene Bindung", function()
    local G, DC, world, button = setup()
    local done
    G:RegisterDoubleClick("pole", { modifier = "SHIFT", Prepare = function() return nil end,
        Done = function(_, action) done = action or "none" end })
    stub.keys.shift = true
    DoubleClick(DC)
    Press(button)
    eq(button.attributes.type, nil, "nichts wirken")
    eq(done, "none", "Done aufgerufen")

    G:RegisterDoubleClick("pole", { modifier = "SHIFT", Prepare = function() error("kaputt") end })
    stub.now = stub.now + 1
    DoubleClick(DC)
    Press(button)
    eq(button.attributes.type, nil, "Fehler wirkt nichts")

    stub.now = stub.now + 1
    DoubleClick(DC)
    eq(world.bindings["SHIFT-BUTTON2"], true, "gebunden")
    stub.flush()
    eq(next(world.bindings), nil, "ohne Klick nach dem Fenster gelöst")
end)

test("Doppelklick: Probe und Optionen listen die Handler", function()
    local G, DC = setup()
    G:RegisterDoubleClick("fishing", { title = "Professions: Angeln", modifier = "SHIFT", priority = 10,
        Prepare = Spell("Fischen") })
    local lines = table.concat(G.probes and G.probes["click handlers"] and G.probes["click handlers"].func()
        or DC:HandlerLines(), "\n")
    eq(lines:find("fishing: SHIFT-BUTTON2, priority 10", 1, true) ~= nil, true, "Probe")

    local group = G:BuildDoubleClickOptions(1)
    eq(group.args.on_fishing.name, "Professions: Angeln", "Eintrag in den Optionen")
    G:UnregisterDoubleClick("fishing")
    eq(group.args.on_fishing, nil, "abgemeldet")
    eq(group.args.none ~= nil, true, "Hinweis ohne Handler")
end)

test("Doppelklick: Tastenauswahl für Erweiterungen, ausgegraut bei zentraler Taste", function()
    local G, DC = setup()
    local profile, changed = { castKey = "ALT" }, 0
    local args = G:AddDoubleClickKeyOptions({}, profile, 22, { modifier = "castKey", button = "castButton",
        onChange = function() changed = changed + 1 end })
    eq(args.doubleClickModifier.get(), "ALT", "eigene Zusatztaste")
    eq(args.doubleClickButton.get(), "RightButton", "Standard-Maustaste")
    args.doubleClickButton.set(nil, "MiddleButton")
    eq(profile.castButton, "MiddleButton", "gespeichert im Feld der Erweiterung")
    eq(changed, 1, "onChange")
    eq(args.doubleClickModifier.disabled(), false, "frei")
    eq(args.doubleClickModifier.hidden, nil, "ohne hidden sichtbar")
    local off = false
    args = G:AddDoubleClickKeyOptions(args, profile, 22, { modifier = "castKey", button = "castButton",
        hidden = function() return off end })
    off = true
    eq(args.doubleClickButton.hidden(), true, "ausgeblendet, wenn die Funktion im Addon aus ist")

    DC.settings.profile.central = true
    DC.settings.profile.modifier = "CTRL"
    eq(args.doubleClickModifier.disabled(), true, "zentral: ausgegraut")
    eq(args.doubleClickModifier.get(), "CTRL", "zeigt die zentrale Taste")

    local core = G:BuildDoubleClickOptions(1)
    eq(core.args.doubleClickModifier.disabled(), false, "Core-Block aktiv bei zentraler Taste")
    core.args.doubleClickModifier.set(nil, "ALT")
    eq(DC.settings.profile.modifier, "ALT", "Core-Block schreibt die zentrale Taste")
end)

test("Doppelklick: Mouseover zeigt die eigene Taste des Addons", function()
    local G, DC = setup()
    G:RegisterDoubleClick("fishing", { modifier = "SHIFT", Prepare = Spell("Fischen") })
    local group = G:BuildDoubleClickOptions(1)
    eq(group.args.on_fishing.desc(), "Own key: Shift + Double click right", "eigene Taste")
    DC.settings.profile.central = true
    DC.settings.profile.modifier = "ALT"
    eq(group.args.on_fishing.desc(), "Own key: Shift + Double click right\nCurrently the central key applies: Alt + Double click right",
        "mit zentraler Taste")
end)

test("Doppelklick: abgemeldeter Handler verschwindet aus dem Core-Block", function()
    local G = setup()
    G:RegisterDoubleClick("travel", { modifier = "ALT", Prepare = Spell("Reiten") })
    local group = G:BuildDoubleClickOptions(1)
    eq(group.args.on_travel ~= nil, true, "Eintrag da")
    G:UnregisterDoubleClick("travel")
    eq(group.args.on_travel, nil, "Eintrag weg")
    eq(group.args.prio_travel, nil, "Priorität weg")
end)
