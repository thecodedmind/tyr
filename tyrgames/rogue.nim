import "../tyr"
export tyr

proc promptName(s: var State, i:string)=
    var player = s.getEntity(0)
    player.setVar("name", i)
    s.focus(player)
    s.ln("narrator", "Well, hello there,  "&i&". Grab a weapon, and `use` the `teleporter`.")
    s.ln("narrator", "If you survive the Pantheon, maybe we can discuss the matters at hand.")
    s.override()

proc initRogue*(): State =
    var state = newState("rogue", useNavCommands = true)
    state.setVar("author", "Kaiser")
    var start = state.getEntity("start_1")
    start.setVar("name", "Room")
    start.setVar("description", "Just a room?")
    
    discard state.extendZone(start, "Hall", "north")

    var sw = state.spawnEntity(start, "Sword")
    sw.setVar("takeable", "t")
    discard state.spawnEntity(start, "Spear")

    var player = state.getEntity(0)
    state.moveEntity(player, start)
    #player.setVar("inventory_limit", 1)

    state.ln("narrator", "What is your name, rogue?")

    state.override(promptName, "name? > ")
    return state
    
