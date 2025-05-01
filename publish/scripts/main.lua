local inspect = require "lib.inspect"

print("Hello, Lost Skies!")
print '=================== LostMoon ==================='
print("LostMoon: ", inspect(LostMoon, { depth = 1 }))
print "------------------------------------------------"
print("Globals: ", inspect(_G, { depth = 1 }))

print "------------------------------------------------"

Log(string.format("Player Ingame: %s" , tostring(InGame)))
Log(string.format("Player Host: %s" , tostring(IsHost)))