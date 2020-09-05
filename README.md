# tyr
A WIP engine for rapid creation of command-line RPG/adventure games.
The idea is, a simple API-driven object which can be used to easily spin up simple text based RPG games, but modular and extendible enough to expand the core in to external adapters, such as integration with discord bots, or GUI's.

## TODO
- [x] Command Parser
- [x] Globals
- [x] Save/Load
- [ ] Dynamic content creation
- [ ] Battle system extension
- [ ] Actor events and triggers
  - [ ] Use for speak and touch commands, for example
- [ ] Test external adapters
  - [ ] Discord
  - [ ] GUI

## Example
A basic game initiation system. (WIP: need to optimise more, maybe add more dynamicism, maybe nimscript?)
```nim
# Import the core library
import "../tyr"
export tyr

# Defining a function we'll use later for a global function
proc promptName(s: var State, i:string)=
    # getEntity lets us find an in-game object and store it as a variable
    # can use various tags for finding an object, either an id int, a tag or a name string.
    # id 0 is always player actor
    # id 1 is always first zone where the player actor exists
    var player = s.getEntity(0)
    # setVar sets a local variable for the object, in this case we're taking the functions arguement and using that as the players name
    player.setVar("name", i)
    
    # state.focus sets the object as our "player" object. it is what any commands and functions use to decide which object is the main character
    s.focus(player)
    
    # ln sends new message to the text buffer
    s.ln("narrator", "Well, hello there,  "&i&". Grab a weapon, and `use` the `teleporter`.")
    s.ln("narrator", "If you survive the Pantheon, maybe we can discuss the matters at hand.")
    
    # release the override, see the other call 
    s.override()

proc initRogue*(): State =
    # creating new state. first arg string is the game id. then takes some boolean flags for wether we enable some core command packages
    var state = newState("rogue", useNavCommands = true)
    
    #state has its own global variables, here we set an author name
    state.setVar("author", "TCM")
    
    # getting the starting room, by default its tag is start_1
    var start = state.getEntity("start_1")
    
    # modifying start room values. once its renamed, its tag changes to room_1, the tag uses its current name, lower-cased, and its id
    start.setVar("name", "Room")
    start.setVar("description", "Just a room?")
    
    # spawns a new zone, with a given name, in a given direction from the first zone
    # returns the created zone. discarded here because I don't have any use in modifying the new zone yet.
    discard state.extendZone(start, "Hall", "north")

    # creating a new entity in-game in the specified zone.
    # can take another actor as zone, will be considered being in that actors "inventory"
    var sw = state.spawnEntity(start, "Sword")
    # vars are arbitrary and can be used for internal checks and the like. but there are some used by the engine.
    # takeable set to any truthy value decides wether it can be added to the players inventory through the take command
    # nodrop set to any truthy value decides if player can drop the item from inventory
    # inventory_limit sets a cap on how many items any container object can store, if null or 0, storage is infinite (default)
    sw.setVar("takeable", "t")
    discard state.spawnEntity(start, "Spear")

    var player = state.getEntity(0)
    # moveEntity moves an entity to specific zone
    state.moveEntity(player, start)

    state.ln("narrator", "What is your name, rogue?")

    # by default, the runtime loop sends inputs to the command parser. 
    # override redirects the inputs to another function, with a given prompt.
    state.override(promptName, "name? > ")
    return state
    
```
```nim
# loading the above file
import tyrgames/rogue

# calling the modules setup
var s = initRogue()
# prints the current buffer, called after each loop, also called now in case the module sends anything during setup, like intro text.
# function can be redirected to an arbtirary function instead of echoing (API in-progress)
s.outputBuffer()
# starts the default loop, in this case a command-like REPL. can be hijacked to use other means of input, such as discord bot messages. (API in-progress)
s.loop()

```
