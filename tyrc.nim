    
proc c_north(s:var State, i:seq[string]) =
    var player = s.getEntity(s.player_tag)
    if s.moveDir(player, "north"):
        s.ln("world", "Entered "&s.getEntity(player.value("location")).value("name"))
    else:
        s.ln "world", "There is nothing there."
    
proc c_south(s:var State, i:seq[string]) =
    var player = s.getEntity(s.player_tag)
    if s.moveDir(player, "south"):
        s.ln("world", "Entered "&s.getEntity(player.value("location")).value("name"))
    else:
        s.ln "world", "There is nothing there."
    
proc c_east(s:var State, i:seq[string]) =
    var player = s.getEntity(s.player_tag)
    if s.moveDir(player, "east"):
        s.ln("world", "Entered "&s.getEntity(player.value("location")).value("name"))
    else:
        s.ln "world", "There is nothing there."
    
proc c_west(s:var State, i:seq[string]) =
    var player = s.getEntity(s.player_tag)
    if s.moveDir(player, "west"):
        s.ln("world", "Entered "&s.getEntity(player.value("location")).value("name"))
    else:
        s.ln "world", "There is nothing there."
   
proc c_in(s:var State, i:seq[string]) =
    var player = s.getEntity(s.player_tag)
    if s.moveDir(player, "in"):
        s.ln("world", "Entered "&s.getEntity(player.value("location")).value("name"))
    else:
        s.ln "world", "There is nothing there."
    
proc c_out(s:var State, i:seq[string]) =
    var player = s.getEntity(s.player_tag)
    if s.moveDir(player, "out"):
        s.ln("world", "Entered "&s.getEntity(player.value("location")).value("name"))
    else:
        s.ln "world", "There is nothing there."
    
    
proc c_up(s:var State, i:seq[string]) =
    var player = s.getEntity(s.player_tag)
    if s.moveDir(player, "up"):
        s.ln("world", "Entered "&s.getEntity(player.value("location")).value("name"))
    else:
        s.ln "world", "There is nothing there."
    
proc c_down(s:var State, i:seq[string]) =
    var player = s.getEntity(s.player_tag)
    if s.moveDir(player, "down"):
        s.ln("world", "Entered "&s.getEntity(player.value("location")).value("name"))
    else:
        s.ln "world", "There is nothing there."
        
proc c_examine(s:var State, i:seq[string]) =
    var objs = s.getEntities(i.join(" "))
    if objs.len == 0:
        s.ln "examine", "What?"
    elif objs.len == 1:
        var o = objs[0]
        if o.hasEvent("examine"):
            s.trigger(o, "examine")
        else:
            s.ln "examine", "You don't want to do that."
    else:
        var outp:seq[string] = @[]
        for item in objs:
            outp.add item.value("name")

        s.ln "ambiguous choices", outp.join(", ")

proc c_touch(s:var State, i:seq[string]) =
    var objs = s.getEntities(i.join(" "))
    if objs.len == 0:
        s.ln "touch", "What?"
    elif objs.len == 1:
        var o = objs[0]
        if o.hasEvent("touch"):
            s.trigger(o, "touch")
        else:
            s.ln "touch", "You don't want to do that."
    else:
        var outp:seq[string] = @[]
        for item in objs:
            outp.add item.value("name")

        s.ln "ambiguous choices", outp.join(", ")        
    
proc c_look(s:var State, i:seq[string]) =
    var player = s.getEntity(s.player_tag)
    var curZone = s.getEntity(player.value("location"))

    s.ln(player.value("name"), "Currently in "&curZone.value("name"))
    if curZone.value("description") != "":
        s.ln(curZone.value("name"), curZone.value("description"))
        
    for d in DIRECTIONS:
        if curZone.value("zone_"&d) != "":
            s.ln "world", "To the "&d&" is "&s.getEntity(curZone.value("zone_"&d)).value("name")
            
    var contents:seq[string] = @[]

    for o in curZone.arrayValue(s.containerKey):
        contents.add s.getEntity(o).value("name")

    if contents.len > 0:
        s.ln curZone.value("name"), "Contains "&contents.join(", ")
                        
proc c_speak(s:var State, i:seq[string]) =
    var objs = s.getEntities(i.join(" "))
    if objs.len == 0:
        s.ln "speak", "Who?"
    elif objs.len == 1:
        var o = objs[0]
        if o.hasEvent("speak"):
            s.trigger(o, "speak")
        else:
            s.ln "speak", "You don't want to do that."
    else:
        var outp:seq[string] = @[]
        for item in objs:
            outp.add item.value("name")

        s.ln "ambiguous choices", outp.join(", ")     
       
proc c_use(s:var State, i:seq[string]) =
    var player = s.getEntity(s.player_tag)
    var objs = s.getEntities(player, i.join(" "))
    if objs.len == 0:
        s.ln "use", "What?"
    elif objs.len == 1:
        var o = objs[0]
        if o.hasEvent("use"):
            s.trigger(o, "use")
        else:
            s.ln "use", "You don't want to do that."
    else:
        var outp:seq[string] = @[]
        for item in objs:
            outp.add item.value("name")

        s.ln "ambiguous choices", outp.join(", ")     

proc c_take(s:var State, i:seq[string]) =
    if i.len == 0:
       s.ln("take", "Take what?")
    else:
        var player = s.getEntity(s.player_tag)

        if player.arrayValue(s.containerKey).len >= player.intValue("inventory_limit", 9999):
            s.ln "inventory", "Can't carry any more."
        else:
            var p = s.getEntities(s.getEntity(player.value("location")), i[0])

            if p.len == 0:
                s.ln("take", "Take what?")
            elif p.len == 1:
                if p[0].bValue("takeable"):
                    s.ln(p[0].value("name"), "Taken.")
                    s.moveEntity(p[0], player)
                else:
                    s.ln "fail", "Can't take that."
            else:
                var outp:seq[string] = @[]
                for item in p:
                    outp.add item.value("name")

                s.ln "ambiguous choices", outp.join(", ")
                
proc c_drop(s:var State, i:seq[string]) =
    if i.len == 0:
        s.ln("drop", "Drop what?")
    else:
        var player = s.getEntity(s.player_tag)
        var p = s.getEntities(player, i[0])
        var l = s.playerLocation()
        if p.len == 0:
            s.ln("drop", "Drop what?")
        elif p.len == 1:
            if not p[0].bValue("nodrop"):
                s.ln(p[0].value("name"), "Dropped.")
                s.moveEntity(p[0], l)
            else:
                s.ln "fail", "Can't drop that."
        else:
            var outp:seq[string] = @[]
            for item in p:
                outp.add item.value("name")

            s.ln "ambiguous choices", outp.join(", ")
                
proc c_check(s:var State, i:seq[string]) =
    var player = s.player()
    
    if i.len == 0:
        var a = player.arrayValue(s.containerKey)
        if player.intValue("inventory_limit") != 0:
            s.ln "Limit", a.len.intToStr()&"/"&player.intValueAsStr("inventory_limit")
        
        if a.len == 0:
            s.ln "Inventory", "Nothing."
        else:
            var outp:seq[string] = @[]
            for item in a:
                outp.add s.getEntity(item).value("name")

            s.ln "Inventory", outp.join(", ")
    else:
        var p = s.getEntities(player, i[0])    
        if p.len == 0:
            s.ln("drop", "Check what?")
            
        elif p.len == 1:
            s.ln(p[0].value("name"), p[0].value("description", "No description."))
            
        else:
            var outp:seq[string] = @[]
            for item in p:
                outp.add item.value("name")

            s.ln "ambiguous choices", outp.join(", ")
            
proc c_save(s:var State, i:seq[string]) =
    var filename = ""
    
    if i.len == 0:
       filename = s.game_id&"_0.tyr"
    else:
       filename = i[0]&".tyr"
       
    s.saveState(filename)

    
proc c_load(s:var State, i:seq[string]) =
    var filename = ""
    
    if i.len == 0:
       filename = s.game_id&"_0.tyr"
    else:
       filename = i[0]&".tyr"
       
    s.loadState(filename)
