# playerKillCount
[TES3MP] 0.7 script that stores kill count per player / can be set so kills are shared within the same cell

## Configurables
### config.resetKillsRank
0 - everyone is allowed to reset their kills\
1 - moderator\
2 - admin\
3 - server owner

### config.cellShared
true - any kill that happens in the cell is shared among players within the same cell\
false - kills are assigned merely to killers

## Installation

1. Download the ```main.lua``` and put it in */server/scripts/custom/playerKillCount*
2. Download the ```namesData.lua``` and put it in */server/scripts/custom/*
3. Open ```customScripts.lua``` and add this code on separate line: ```require("custom.playerKillCount.main")```

## Showcase
![](https://cdn.discordapp.com/attachments/663977921282834432/874265121092952104/unknown.png)
