proc setVar*(s: var State, key:string, n:string)
proc setVar*(s: var TEnt, key:string, n:string)
proc intValue*(s: TEnt, key:string, default:int = 0): int
proc getEntity*(s:State, v:string): TEnt
proc getEntity*(s:State, v:int): TEnt
proc getEntity*(s:State, z:TEnt, v:int): TEnt
proc value*(s: TEnt, key:string, default:string = ""): string
proc tag*(s:TEnt): string
proc moveEntity*(s:var State, e: var TEnt, i:var TEnt)
proc moveDirGetValue*(s:var State, ent:var TEnt, dir:string, v:string = "name"):string
proc arrayValue*(s: TEnt, key:string): seq[string]
proc moveDir*(s:var State, ent:var TEnt, dir:string):bool
proc ln*(s:var State, key, text:string)
proc spawnEntity*(s:var State, inZone:var TEnt, name:string):TEnt
proc getEntities*(s:State, z:TEnt, v:string): seq[TEnt]
proc getEntities*(s:State, v:string): seq[TEnt]
proc player*(s: var State):TEnt
proc intValueAsStr*(s: TEnt, key:string, default:string = "0"): string
proc intValueFromStr*(s: TEnt, key:string, default:int = 0): int
proc bValue*(s: TEnt, key:string): bool
proc playerLocation*(s: var State):TEnt
proc registerGlobal*(s: var State, name:string, n: proc(s:var State, i:seq[string]))
proc saveState*(s: var State, sv:string = "")
proc loadState*(s: var State, sv:string = "")
proc global*(s: var State, name:string, args:seq[string] = @[])
proc hasEvent*(s: var TEnt, event:string):bool
proc trigger*(state:var State, s: var TEnt, event:string, i:seq[string] = @[], verbose:bool = false)
proc onEvent*(st: var State, e: var TEnt, event, fn: string, g:proc (s: var State, i: seq[string]))
proc getEntities*(s:State, z:TEnt): seq[TEnt]
