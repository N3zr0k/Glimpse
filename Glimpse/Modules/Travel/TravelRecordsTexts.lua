local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local Travel = Glimpse:GetModule("Travel")

-- Meldungstexte der Rekorde. Mehrere Varianten je Art, eine wird zufällig gewählt; Platzhalter {speed}, {mount},
-- {depth}, {time}, {distance}. Die Sprünge haben einen Text je Meilenstein (Schlüssel = Meilenstein). Fehlt eine
-- Sprache, gilt enUS.

local TEXTS = {
    enUS = {
        walk = {
            "You are in top shape! New running speed record: {speed}.",
            "Your soles are smoking: {speed} is a new running record.",
            "Who let the rabbits out? New running record: {speed}.",
            "That was quick! {speed} is your fastest run on foot yet.",
        },
        mount = {
            "Good job, {mount}! New riding record: {speed}. Extra oats tonight.",
            "Wow, {mount} is really going for it! {speed} is a new riding record. Good mount!",
            "What a ride! {mount} gave everything at {speed}. A treat is well deserved.",
            "New riding record: {speed}! Big praise for {mount}.",
        },
        mountFallback = "your mount",
        fall = {
            "Ouch! New fall record: {depth}. The ground was the plan all along, right?",
            "{depth} of free fall! Your knees are filing a complaint.",
            "New depth record: {depth}. Hopefully on purpose.",
            "That was deep: {depth}! Falling is only dangerous at the end, they say.",
        },
        breath = {
            "Deep breath! New record: {time} under water without air.",
            "Like a fish: {time} holding your breath, a new record!",
            "{time} without air, a new record. Time to come up!",
            "Your lungs say thanks, just barely: {time} under water, a new record.",
        },
        swim = {
            "A real swimmer: {distance} in one go, a new record!",
            "Seahorse? More like shark! {distance} swum without a break, a new record.",
            "Wet feet? For ages! New swimming record: {distance}.",
            "{distance} in the water without a pause: a new record, you water rat.",
        },
        jump = {
            [100] = "100 jumps! Your legs are warm and the ground feels a bit abandoned.",
            [500] = "500 jumps! Hopping seems to be your favorite way to travel.",
            [1000] = "1,000 jumps! A rabbit called and wants its title back.",
            [2500] = "2,500 jumps! Your knees are writing a complaint, but the hopping goes on.",
            [5000] = "5,000 jumps! By now it is clear: walking is overrated.",
            [10000] = "10,000 jumps! The space bar is asking for a vacation.",
            [100000] = "100,000 jumps! You have spent more time in the air than some birds.",
            [1000000] = "ONE MILLION JUMPS! You are officially the hopper of hoppers. There is nothing left to reach.",
        },
    },
    deDE = {
        walk = {
            "Du bist top in Form! Neue Höchstgeschwindigkeit zu Fuß: {speed}.",
            "Die Sohlen qualmen schon: {speed} ist dein neuer Laufrekord.",
            "Wer hat die Hasen losgelassen? Neuer Laufrekord: {speed}.",
            "Das ging flott! Mit {speed} warst du zu Fuß noch nie so schnell.",
        },
        mount = {
            "Gut gemacht, {mount}! Neuer Reitrekord: {speed}. Heute Abend gibt es Extra-Futter.",
            "Hui, {mount} legt sich ins Zeug! {speed} ist ein neuer Reitrekord. Braves Tier!",
            "Was für ein Ritt! Mit {speed} hat {mount} alles gegeben. Ein Leckerli ist verdient.",
            "Neuer Reitrekord: {speed}! Ein dickes Lob für {mount}.",
        },
        mountFallback = "dein Reittier",
        fall = {
            "Autsch! Neuer Fallrekord: {depth} tief. Der Boden war das Ziel, oder?",
            "{depth} im freien Fall! Deine Knie reichen eine Beschwerde ein.",
            "Neuer Tiefenrekord: {depth}. Hoffentlich war das Absicht.",
            "Das war tief: {depth}! Gefährlich ist ja nur das Ende des Fallens, heißt es.",
        },
        breath = {
            "Tief Luft geholt! Neuer Rekord: {time} unter Wasser ohne Atem.",
            "Wie ein Fisch: {time} Atem angehalten, ein neuer Rekord!",
            "{time} ohne Luft, neuer Rekord. Zeit zum Auftauchen!",
            "Die Lunge sagt Danke, aber nur knapp: {time} unter Wasser, neuer Rekord.",
        },
        swim = {
            "Ein echter Schwimmer: {distance} am Stück, neuer Rekord!",
            "Seepferdchen? Eher Hai! {distance} ohne Pause geschwommen, neuer Rekord.",
            "Nasse Füße? Schon lange! Neuer Schwimmrekord: {distance}.",
            "{distance} im Wasser ohne Pause: neuer Rekord, du Wasserratte.",
        },
        jump = {
            [100] = "100 Sprünge! Die Beine sind warm, der Boden fühlt sich ein bisschen verlassen.",
            [500] = "500 Sprünge! Hüpfen ist offenbar dein liebster Weg.",
            [1000] = "1000 Sprünge! Ein Hase hat angerufen und will seinen Titel zurück.",
            [2500] = "2500 Sprünge! Deine Knie schreiben schon eine Beschwerde, aber das Hüpfen geht weiter.",
            [5000] = "5000 Sprünge! Spätestens jetzt ist klar: Laufen wird überbewertet.",
            [10000] = "10000 Sprünge! Die Leertaste bittet um Urlaub.",
            [100000] = "100000 Sprünge! Du warst länger in der Luft als manche Vögel.",
            [1000000] = "EINE MILLION SPRÜNGE! Du bist offiziell der Hüpfer der Hüpfer. Mehr gibt es nicht zu erreichen.",
        },
    },
}

--- Texte einer Art in der Client-Sprache: Liste (Sprünge: nach Meilenstein), bei "mountFallback" ein Text
function Travel:RecordTexts(kind)
    local texts = TEXTS[GetLocale and GetLocale() or "enUS"] or TEXTS.enUS
    return texts[kind] or TEXTS.enUS[kind]
end
