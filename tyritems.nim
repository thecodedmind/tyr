
proc useBasicAttack(s: var State, i:seq[string]) =
    var player = s.player()
    var used = s.getEntity(i[0])
    var enemy = s.getEntity(s.get("battle_id"))
    var dmg = used.intValue("damage")
    
    s.ln "battle", player.value("name")&" uses "&used.value("name")&"!"
    s.takeDamage(enemy, dmg)
    s.ln enemy.value("name"), "Took ("&dmg.intToStr()&") damage!"
    s.ln enemy.value("name"), enemy.intValueAsStr("health")&"/"&enemy.intValueAsStr("maxhealth")&" health remaining."

proc useCompBow(s: var State, i:seq[string]) =
    var player = s.player()
    var used = s.getEntity(i[0])
    var enemy = s.getEntity(s.get("battle_id"))
    s.ln "battle", player.value("name")&" uses "&used.value("name")&" which doesn't have its full functionality yet!"
    s.takeDamage(enemy, 5)
    s.ln enemy.value("name"), "Took (5) damage!"
    s.ln enemy.value("name"), enemy.intValueAsStr("health")&"/"&enemy.intValueAsStr("maxhealth")&" health remaining."

proc useRestB(s: var State, i:seq[string]) =
    var player = s.player()
    var used = s.getEntity(i[0])
    s.ln "developer", "TODO - decide how it works"

    
proc useRestF(s: var State, i:seq[string]) =
    var player = s.player()
    s.ln "developer", "TODO - grant Well Rested effect, cant use while having the effect. Actual effects tbd."


proc useShieldIron(s: var State, i:seq[string]) =
    var player = s.player()
    var used = s.getEntity(i[0])

    if player.intValue("energy") > 1:
        player.setVar("energy", player.intValue("energy") - 1)
        player.setVar("armour", player.intValue("armour") + 3)
        s.ln used.value("name"), "You raise your shield! (+3 armour)"
        s.ln player.value("name"), "Armour: "&player.intValueAsStr("armour")
        
    else:
        s.ln used.value("name"), "You fumbled the shield..."
