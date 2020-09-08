import strutils
import "../tyr", "../lib/strplus", "../lib/seqplus"
export tyr

proc promptName(s: var State, i:string)=
    if i == ".load":
        s.loadState("rogue_0.tyr")
        s.ln("narrator", "Welcome back, "&s.player().value("name")&".")
        s.override()
    else:
        var player = s.getEntity(0)
        player.setVar("name", i)
        s.focus(player)
        s.ln("narrator", "Well, hello there,  "&i&". Touch one of the chests to choose your equipment.")
        s.ln("narrator", "If you survive the Pantheon, maybe we can discuss the matters at hand.")
        s.ln("narrator", "If you need practice, head to the hall, otherwise, touch the teleporter.")
        s.override()
    
proc playermove(s: var State, i:seq[string])=
    var z = s.getEntity(i[1])
    for ob in z.arrayValue(s.containerKey):
        var e = s.getEntity(ob)
        if e.hasEvent("player_encounter") and e.value("iff") == "hostile":
            s.trigger(e, "player_encounter", @[e.id.intToStr()])

include "../tyrbattle"
include "../tyritems"

proc chooseclass_warrior(s: var State, i:seq[string])=
    if s.get("class") != "":
        s.ln "class", "You already chose "&s.get("class")
    else:
        s.setVar("class", "warrior")
        var player = s.player()
        
        var sw = s.spawnEntity(player, "Sword: Iron")
        sw.setVar("description", "BATTLE: Deals (2) damage.")
        sw.setVar("damage", 2)
        s.onEvent(sw, "battle_use", "use_iron_sword", useBasicAttack)

        var sh = s.spawnEntity(player, "Shield: Iron")
        sh.setVar("description", "[1EN] BATTLE: Generates (3) armour.")
        s.onEvent(sh, "battle_use", "use_iron_shield", useShieldIron)

        var bo = s.spawnEntity(player, "Composite Bow")
        bo.setVar("description", "[2EN] BATTLE: [CHANCE: 75%/25%; Deals (5-15) damage | Miss]")
        s.onEvent(bo, "battle_use", "use_compbow", useCompBow)

        var he = s.spawnEntity(player, "Rest")
        he.setVar("description", "BATTLE: Gain (1) EN regeneration. | [?EN] FIELD: Heal (?) health.")        
        s.onEvent(he, "battle_use", "use_restb", useRestB)
        s.onEvent(he, "use", "use_restf", useRestF)
        
proc chooseclass_mage(s: var State, i:seq[string])=
    if s.get("class") != "":
        s.ln "class", "You already chose "&s.get("class")
    else:
        s.setVar("class", "mage")
        var player = s.player()
        var sw = s.spawnEntity(player, "Spellblade")
        sw.setVar("description", "[?EN] BATTLE: Deals (X) damage.")
        var sh = s.spawnEntity(player, "Barrier")
        sh.setVar("description", "[?EN] BATTLE: Generates (?) armour.")
        var he = s.spawnEntity(player, "Healing")
        he.setVar("description", "[?EN] BATTLE: Heal (?/2) health. | FIELD: Heal (?) health.")
        var bo = s.spawnEntity(player, "Focus")
        bo.setVar("description", "BATTLE: Generate (1-3) EN. [ADDITION: (EN*10)%; Generate additional (10) EN. Take (EN/10) damage.]")
               
proc chooseclass_techno(s: var State, i:seq[string])=
    if s.get("class") != "":
        s.ln "class", "You already chose "&s.get("class")
    else:
        s.setVar("class", "technomancer")
        var player = s.player()
        player.setVar("energyregen", 0)
        var sw = s.spawnEntity(player, "Shock Glove")
        sw.setVar("description", "BATTLE: Deals (1) damage. Generate (3) EN.")
        var sh = s.spawnEntity(player, "Energy Shield")
        sh.setVar("description", "[?EN] BATTLE: Generate (X) armour.")
        var bo = s.spawnEntity(player, "Drone Rifle")
        bo.setVar("description", "BATTLE: Spawn Drone Rifle ally. [PER TURN: Lose (1) EN. Deals (2) damage.]")    
        var he = s.spawnEntity(player, "Bionic Converter")
        he.setVar("description", "BATTLE: Take (1) damage. Generate (2) EN. | [1EN] FIELD: Heal (2) health.")

    
proc initRogue*(): State =
    var state = newState("rogue", useNavCommands = true)
    state.setVar("author", "Kaiser")
    var start = state.getEntity("start_1")
    start.setVar("name", "Room")
    start.setVar("description", "Just a room?")
    
    var th = state.extendZone(start, "Hall", "north")
    var dummy = state.spawnEntity(th, "Training Dummy")
    dummy.setVar("iff", "hostile")
    dummy.setVar("ai_script", "idle")
    dummy.setVar("health", 10)
    dummy.setVar("maxhealth", 10)
    dummy.setVar("armour", 0)
    state.onEvent(dummy, "player_encounter", "player_enc", startbattle)
    state.registerGlobal("cwar", chooseclass_warrior)
    state.registerGlobal("cmag", chooseclass_mage)
    state.registerGlobal("ctec", chooseclass_techno)
    var sw = state.spawnEntity(start, "Warrior Chest")
    sw.onEvent("touch", "cwar")
    var st = state.spawnEntity(start, "Techno Chest")
    st.onEvent("touch", "ctec")
    var sm = state.spawnEntity(start, "Mage Chest")
    sm.onEvent("touch", "cmag")
    
    var player = state.getEntity(0)
    state.moveEntity(player, start)
    player.onEvent("moved", "player_move")
    player.setVar("inventory_limit", 10)
    player.setVar("health", 10)
    player.setVar("maxhealth", 10)
    player.setVar("armour", 0)
    player.setVar("energy", 0)
    player.setVar("energyregen", 1)
    player.setVar("maxenergy", 10)
    
    state.ln("narrator", "What is your name, rogue? (enter `.load` to load save file)")
    state.registerGlobal("player_move", playermove)
    #state.registerGlobal("player_enc", )
    state.override(promptName, "name? > ")
    return state
    
