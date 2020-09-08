proc takeDamage(s: var State, this:var TEnt, dmg:int) =
    var total = dmg
    
    if this.intValue("armour") > 0:
        total = total - this.intValue("armour")
        this.setVar("armour", this.intValue("armour") - dmg)
        
    if total > 0: 
        this.setVar("health", this.intValue("health") - dmg)
        if this.intValue("health") <= 0:
            if this.id.intToStr() == s.get("battle_id"):
                s.setVar("battle_id", "")
                s.override()
                s.ln "battle", "You won!"
                if this.hasEvent("died"):
                    s.trigger(this, "died")

proc battleRunAI(s:var State, e: var TEnt) =
    case e.value("ai_script", "idle"):
        of "idle":
            s.ln "battle", e.value("name")&" waits."
        else:
            s.ln "battle", e.value("name")&" is unpredictable."
            
proc battleScene(s: var State, i:string) =
    var player = s.player()
    var enemy = s.getEntity(s.get("battle_id"))
    var arena = s.getEntity(player.value("location"))
    
    var args = i.split(" ")
    var c = args.shift()
    
    case c:
        of "check":
            if args.len == 0:
                s.ln player.value("name"), player.intValueAsStr("health")&"/"&player.intValueAsStr("maxhealth")
                s.ln player.value("name"), player.intValueAsStr("energy")&"/"&player.intValueAsStr("maxenergy")&" (+"&player.intValueAsStr("energyregen")&")"
                var a = player.arrayValue(s.containerKey)
                if a.len == 0:
                    s.ln "Inventory", "Nothing."
                else:
                    var outp:seq[string] = @[]
                    for item in a:
                        outp.add s.getEntity(item).value("name")

                    s.ln "Inventory", outp.join(", ")
            else:
                var p = s.getEntities(player, args.join(" "))
                if p.len == 0: s.ln("check", "Check what?")
                elif p.len == 1: s.ln(p[0].value("name"), p[0].value("description", "No description."))
                else:
                    var outp:seq[string] = @[]
                    for item in p:
                        outp.add item.value("name")
                    s.ln "ambiguous choices", outp.join(", ")

        of "look":
            s.ln "battle", "You are facing "&enemy.value("name")&"."
            #s.battleRunAI(enemy)
        of "use":
            var done:bool = false
            
            var o = s.getEntities(player, args.join(" "))
            if o.len == 0: s.ln("use", "Use what?")
            elif o.len == 1:
                if o[0].hasEvent("battle_use"):
                    s.trigger(o[0], "battle_use", @[o[0].id.intToStr()])
                    done = true
                    if enemy.intValue("health") > 0:
                        s.battleRunAI(enemy)
                        player.setVar("energy", player.intValue("energy") + player.intValue("energyregen"))
                        for en in s.getEntities(arena):
                            var env = en
                            if env.hasEvent("battle_tick"):
                                s.trigger(env, "battle_tick")
                else:
                    s.ln "use", "It doesn't do anything."
            else:
                var outp:seq[string] = @[]
                for item in o:
                    outp.add item.value("name")
                s.ln "ambiguous choices", outp.join(", ")
                
            if not done:    
                var l = s.getEntities(arena, args.join(" "))
                if l.len == 0: s.ln("use", "Use what?")
                elif l.len == 1:
                    if l[0].hasEvent("battle_use"):
                        s.trigger(l[0], "battle_use", @[l[0].id.intToStr()])
                        if enemy.intValue("health") > 0:
                            s.battleRunAI(enemy)
                            player.setVar("energy", player.intValue("energy") + player.intValue("energyregen"))
                            for en in s.getEntities(arena):
                                var env = en
                                if env.hasEvent("battle_tick"):
                                    s.trigger(env, "battle_tick")
                    else:
                        s.ln "use", "It doesn't do anything."
                else:
                    var outp:seq[string] = @[]
                    for item in l:
                        outp.add item.value("name")
                    s.ln "ambiguous choices", outp.join(", ")
                

        of "escape":
            s.override()
            s.ln "battle", "Escaped."
            
proc startbattle(s:var State, i:seq[string]) =
    var player = s.player()
    if player.intValue("energy") == 0:
        player.setVar("energy", player.intValue("energyregen"))
    s.setVar("battle_id", i[0])
    s.ln "battle", "Initiated battle against the "&s.getEntity(i[0]).value("name")&"!"
    s.ln "battle", "Choose your command..."
    s.override(battleScene, "!> ")
  
