import json, tables, strutils
import lib/strplus, lib/seqplus, rdstdin
export json, tables
const DIRECTIONS_ALL = @["north", "east", "south", "west", "up", "down", "in", "out", "n", "e", "w", "s", "u", "d", "i", "o"]
const DIRECTIONS_SHORT = @["n", "e", "w", "s", "u", "d", "i", "o"]
const DIRECTIONS = @["north", "east", "south", "west", "up", "down", "in", "out"]

proc expandDirection*(s:string):string =
    case s:
        of "n":
            return "north"
        of "s":
            return "south"
        of "w":
            return "west"
        of "e":
            return "east"
        of "u":
            return "up"
        of "d":
            return "down"
        of "i":
            return "in"
        of "o":
            return "out"
        else:
            return s
    
proc shortenDirection*(s:string):string =
    case s:
        of "north":
            return "n"
        of "south":
            return "s"
        of "west":
            return "w"
        of "east":
            return "e"
        of "up":
            return "u"
        of "down":
            return "d"
        of "in":
            return "i"
        of "out":
            return "o"
        else:
            return s
            
proc invertDirection*(s:string):string =
    case s:
        of "north":
            return "south"
        of "south":
            return "north"
        of "west":
            return "east"
        of "east":
            return "west"
        of "up":
            return "down"
        of "down":
            return "up"
        of "in":
            return "out"
        of "out":
            return "in"
        of "n":
            return "s"
        of "s":
            return "n"
        of "w":
            return "e"
        of "e":
            return "w"
        of "u":
            return "d"
        of "d":
            return "u"
        of "i":
            return "o"
        of "o":
            return "i"
        else:
            return s
            

type
    Entitytype = enum
        actor, zone
    
    TEnt = object
        data: JsonNode
        id*: int
        etype*: EntityType
        
    State* = object
        game_id*: string
        entities*: Table[string, TEnt] #seq[TEnt]
        variables*: Table[string, string]
        commands*, globals*: Table[string, proc(s:var State, i:seq[string])]
        prompt*, containerKey*: string
        buffer: seq[Table[string, string]]
        cproc: proc(s:var State, i:string)
        outputproc: proc(s:var State)
        player_tag: string

include tyrh
include tyrc

proc saveState*(s: var State, filename:string) =
    var d = newJObject()
    d["player_tag"] = s.player_tag.newJString()
    d["entities"] = newJArray()
    d["variables"] = newJObject()
    for k, e in s.entities.pairs:
        var j = newJObject()
        j["data"] = e.data
        j["etype"] = newJString($e.etype)
        j["id"] = e.id.newJInt()
        j["_key"] = k.newJString()
        d["entities"].add j
        
    for k, v in s.variables.pairs:
        d["variables"][k] = v.newJString()
    writeFile(filename, d.pretty)
        
proc loadState*(s: var State, filename:string) =
    var d = parseFile(filename)
    s.player_tag = d["player_tag"].getStr
    s.entities = initTable[string, TEnt]()
    s.variables = initTable[string, string]()
    for e in d["entities"].items:
        var n = TEnt()
        n.id = e["id"].getInt
        n.data = e["data"]
        if e["etype"].getStr == "actor":
            n.etype = actor
        else:
            n.etype = zone
        s.entities[e["_key"].getStr] = n
        
    for k, v in d["variables"].pairs:
        s.variables[k] = v.getStr
        
            
        
proc ln*(s:var State, key, text:string) =
    s.buffer.add {"name": key, "message": text}.toTable

proc getBuffer*(s: var State): seq[Table[string, string]] =
    return s.buffer

proc purgeBuffer*(s:var State) =
    s.buffer = newSeq[Table[string, string]]()
    
proc outputBuffer*(s:var State) =
    for ln in s.buffer:
        echo ln["name"]&": "&ln["message"]
    s.purgeBuffer()
    
proc processInput(s:var State, i:string) =
    var p = i.split(" ")
    var com = p.shift()
    if com == "":
        s.ln "state", "What?"
        return
        
    if s.commands.hasKey(com):
        s.commands[com](s, p)
    else:
        var t:seq[string] = @[]
        for c in s.commands.keys:
            if c.startsWith(com):
               t.add c
        if t.len == 0:
            s.ln "invalid action", com
        elif t.len == 1:
            s.commands[t[0]](s, p)
        else:
            s.ln "ambiguous action", t.join(", ")
            
proc override*(s: var State, n: proc(s:var State, i:string), prompt:string = "?> ") =
    s.prompt = prompt
    s.cproc = n
    
proc override*(s: var State) =
    s.prompt = "> "
    s.cproc = processInput
    
proc loop*(s:var State) =
    while true:
        s.cproc(s, readLineFromStdin(s.prompt))
        s.outputProc(s)
        
proc focus*(s: var State, tag:string) =
    s.player_tag = tag
    
proc focus*(s: var State, t:TEnt) =
    if t.etype == actor:
        s.player_tag = t.tag()
        
proc focus*(s: var State):string =
    return s.player_tag
    
proc player*(s: var State):TEnt =
    return s.getEntity(s.player_tag)
    
proc playerLocation*(s: var State):TEnt =
    return s.getEntity(s.player().value("location"))
    
proc registerCommand*(s: var State, name:string, n: proc(s:var State, i:seq[string])) =
    s.commands[name] = n

proc unregisterCommand*(s: var State, name:string) =
    s.commands.del(name)
       
proc registerGlobal*(s: var State, name:string, n: proc(s:var State, i:seq[string])) =
    s.globals[name] = n
    
proc global*(s: var State, name:string, args:seq[string] = @[]) =
    if s.globals.hasKey(name):
        s.globals[name](s, args)
    

proc defaultCommands*(s:var State) =
    s.registerCommand("look", c_look)
    s.registerCommand("examine", c_examine)
    s.registerCommand("touch", c_touch)
    s.registerCommand("speak", c_speak)
    
proc navCommands*(s:var State) =
    s.registerCommand("north", c_north)
    s.registerCommand("south", c_south)
    s.registerCommand("east", c_east)
    s.registerCommand("west", c_west)
    s.registerCommand("up", c_up)
    s.registerCommand("down", c_down)
    s.registerCommand("in", c_in)
    s.registerCommand("out", c_out)
    
proc inventoryCommands*(s:var State) =
    s.registerCommand("take", c_take)
    s.registerCommand("drop", c_drop)
    s.registerCommand("use", c_use)
    s.registerCommand("check", c_check)
    
proc saveLoadCommands*(s:var State) =
    s.registerCommand("save", c_save)
    s.registerCommand("load", c_load)
    
proc newState*(game_id:string, baseCommands:bool = true,
               useNavCommands:bool = true, useInventoryCommands:bool = true, useSaveLoad:bool = true): State =
    result.game_id = game_id
    result.cproc = processInput
    result.outputproc = outputBuffer
    result.prompt = "> "
    result.containerKey = "contains"
    result.entities["player"] = TEnt()
    result.entities["player"].data = newJObject()
    result.entities["player"].data["name"] = newJString("Player")
    result.entities["player"].id = 0
    result.entities["player"].etype = actor
    result.focus("player_0")
    result.entities["start"] = TEnt()
    result.entities["start"].data = newJObject()
    result.entities["start"].data["name"] = newJString("START")
    result.entities["start"].id = 1
    result.entities["start"].etype = zone    
    for d in DIRECTIONS:
        result.entities["start"].setVar("zone_"&d, "")
        result.entities["start"].setVar("lock_"&d, "")
    if baseCommands:
        result.defaultCommands()
    if useNavCommands:
        result.navCommands()
    if useInventoryCommands:
        result.inventoryCommands()
    if useSaveLoad:
        result.saveLoadCommands() 
proc exists*(s: TEnt, key:string): bool =
    if s.data.hasKey(key):
        return true
    else:
        return false

proc value*(s: TEnt, key:string, default:string = ""): string =
    return s.data{key}.getStr(default)

proc bValue*(s: TEnt, key:string): bool =
    return s.data{key}.getStr().boolify()
    
proc intValue*(s: TEnt, key:string, default:int = 0): int =
    return s.data{key}.getInt(default)
    
proc intValueFromStr*(s: TEnt, key:string, default:int = 0): int =
    return s.data{key}.getStr(default.intToStr()).parseInt()
    
proc intValueAsStr*(s: TEnt, key:string, default:string = "0"): string =
    return s.data{key}.getInt(default.parseInt()).intToStr()
    
proc setVar*(s: var TEnt, key:string, n:string) =
    s.data[key] = newJString(n)

proc setVar*(s: var TEnt, key:string, n:int) =
    s.data[key] = newJInt(n)
       
proc arrayValue*(s: TEnt, key:string): seq[string] =
    if s.exists(key):
        for i in s.data[key]:
            result.add i.getStr()
    
proc setVarArray*(s: var TEnt, key:string, n:varargs[string]) =
    s.data[key] = newJArray()
    for en in n.items():
        s.data[key].add en.newJString()
        
proc addVarArray*(s: var TEnt, key:string, n:varargs[string]) =
    for en in n.items():
        s.data[key].add en.newJString()
        
proc hasVarArray*(s: var TEnt, key:string, n:string):bool =
    try:
        var t = s.data[key].toStrArray()
        for en in t:
            if n == en:
                return true
    except:
        return false
        
proc newVarArray*(s: var TEnt, key:string) =
    s.data[key] = newJArray()
    
proc remVarArray*(s: TEnt, key:string, n:varargs[string]) =
    var t = s.data[key].toStrArray()
    for en in n.items():
        t - en
            
    s.data[key] = newJArray()
    for en in t:
        s.data[key].add en.newJString()

        
proc get*(s: State, key:string, default:string = ""): string =
    if not s.variables.hasKey(key):
        return default
    return s.variables[key]
    
proc getInt*(s: State, key:string, default:int = 0): int =
    if not s.variables.hasKey(key):
        return default
    return s.variables[key].parseInt()
    
proc getBool*(s: State, key:string, default:bool = false): bool =
    if not s.variables.hasKey(key):
        return default
    return s.variables[key].boolify()

proc setVar*(s: var State, key:string, n:string) =
    s.variables[key] = n
proc exists*(s: State, key:string): bool =
    if s.variables.hasKey(key):
        return true
    else:
        return false    


proc tag*(s:TEnt): string =
    return s.value("name", "DEFAULT_ENTITY_NAME").toLowerAscii().replace(" ", "_")&"_"&s.id.intToStr()

proc newActor*(s:var State, name:string):TEnt =
    result.data = newJObject()
    result.data["name"] = newJString(name)
    result.id = s.entities.len
    result.etype = actor
    s.entities[result.tag()] = result
        
proc newZone*(s:var State, name:string):TEnt =
    result.data = newJObject()
    result.data["name"] = newJString(name)
    result.id = s.entities.len
    result.etype = zone
    
    for d in DIRECTIONS:
        result.setVar("zone_"&d, "")
        result.setVar("lock_"&d, "")

    s.entities[result.tag()] = result
    
proc linkZone*(first, second:var TEnt, dir:string) =
    if dir in DIRECTIONS_ALL and first.etype == zone and second.etype == zone:
        first.setVar("zone_"&dir, second.tag())
        second.setVar("zone_"&dir.invertDirection(), first.tag())
    else:
        echo "ERR: Invalid zone link"
        
proc extendZone*(s: var State, z: var TEnt, name, dir:string):TEnt =
    if dir in DIRECTIONS_ALL and z.etype == zone:
        result = s.newZone(name)
        z.setVar("zone_"&dir, result.tag())
        result.setVar("zone_"&dir.invertDirection(), z.tag())
    else:
        echo "ERR: Invalid zone link"
        echo "dir_check:" & $(dir in DIRECTIONS_ALL)
        echo "etype_check:" & $z.etype                
        
proc getEntity*(s:State, v:string): TEnt =
    for k, ent in s.entities.pairs:
        if ent.value("name") == v or ent.tag() == v or ent.id.intToStr() == v:
            return ent
            
proc getEntities*(s:State, v:string): seq[TEnt] =
    for k, ent in s.entities.pairs:
        if ent.value("name") == v or ent.value("name").toLowerAscii().startsWith(v) or ent.tag() == v or ent.id.intToStr() == v:
            result.add ent
            
proc getEntity*(s:State, v:int): TEnt =
    for k, ent in s.entities.pairs:
        if ent.id == v:
            return ent
            
proc getEntity*(s:State, z:TEnt, v:string): TEnt =
    for k, ent in s.entities.pairs:
        if ent.value("name") == v or ent.tag() == v or ent.id.intToStr() == v:
            if ent.value("location") == z.id.intToStr():
                return ent
                
proc getEntities*(s:State, z:TEnt, v:string): seq[TEnt] =
    for k, ent in s.entities.pairs:
        if ent.value("name") == v or ent.value("name").toLowerAscii().startsWith(v) or ent.tag() == v or ent.id.intToStr() == v:
            if ent.value("location") == z.id.intToStr():
                result.add ent
                
proc getEntity*(s:State, z:TEnt, v:int): TEnt =
    for k, ent in s.entities.pairs:
        if ent.id == v:
            if ent.value("location") == z.id.intToStr():
                return ent
    
proc moveEntity*(s:var State, e: var TEnt, i:var TEnt) =
    if e.etype == actor:
        for k, ent in s.entities.pairs:
            if e.value("location") == ent.id.intToStr():
                ent.remVarArray(s.containerKey, e.id.intToStr())

        if not i.exists(s.containerKey):
            i.newVarArray(s.containerKey)

        i.addVarArray(s.containerKey, e.id.intToStr())
        e.setVar("location", i.id.intToStr())
        
proc moveDir*(s:var State, ent:var TEnt, dir:string):bool =
    var curZone = s.getEntity(ent.value("location"))
    if curZone.value("zone_"&dir) == "":
        return false
        
    var nextZone = s.getEntity(curZone.value("zone_"&dir))
    s.moveEntity(ent, nextZone)
    return true

proc moveDirGetValue*(s:var State, ent:var TEnt, dir:string, v:string = "name"):string =
    var curZone = s.getEntity(ent.value("location"))
    if curZone.value("zone_"&dir) == "":
        return ""
        
    var nextZone = s.getEntity(curZone.value("zone_"&dir))
    s.moveEntity(ent, nextZone)
    return nextZone.value(v)   

proc spawnEntity*(s:var State, inZone:var TEnt, name:string):TEnt =
    result = s.newActor(name)
    s.moveEntity(result, inZone)
    
proc takeDamage*(this:var TEnt, dmg:int) =
    echo this.value("name")&" took dmg."
