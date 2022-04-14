local WhiteHalo = RegisterMod("White Halo", 1)

WhiteHalo.TRINKET_WHITE_HALO = Isaac.GetTrinketIdByName("White Halo")

local GameState = {}
local json = require("json")

local player

function WhiteHalo:onStart()
	GameState = json.decode(WhiteHalo:LoadData())
	player = Isaac.GetPlayer(0)

	-- External Item Description
	if not __eidTrinketDescriptions then
		__eidTrinketDescriptions = {}
	end
	__eidTrinketDescriptions[WhiteHalo.TRINKET_WHITE_HALO] = "Angel rooms can still spawn after defeating a boss, even if a Devil deal has already been taken"

	if Game():GetFrameCount() == 0 then
		GameState.currRoom = Game():GetRoom()
		GameState.inSafeRoom = GameState.currRoom:IsClear()
	end
end
WhiteHalo:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, WhiteHalo.onStart)

function WhiteHalo:onExit(save)
	WhiteHalo:SaveData(json.encode(GameState))
end
WhiteHalo:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, WhiteHalo.onExit)
WhiteHalo:AddCallback(ModCallbacks.MC_POST_GAME_END, WhiteHalo.onExit)

function WhiteHalo:onUpdate()
	if not GameState.inSafeRoom and GameState.currRoom:IsClear() then
		GameState.inSafeRoom = true
		-- if GameState.currRoom:IsCurrentRoomLastBoss() then
		-- 	if shouldSpawnAngelRoom() then
		-- 		Game():GetLevel():AddAngelRoomChance(1) -- any number above 0 sets angel room chance to 100%
		-- 	end
		-- 	GameState.currLevelIsDecided = true
		-- end
	end
end

function WhiteHalo:onNewLevel()
	GameState.currLevelIsDecided = false
	-- GameState.currLevelIsForgiven = math.random(2) == 1
end

function WhiteHalo:onNewRoom()
	GameState.currRoom = Game():GetRoom()
	GameState.inSafeRoom = GameState.currRoom:IsClear()
	if GameState.currRoom:IsCurrentRoomLastBoss() and shouldSpawnAngelRoom() then
		Game():GetLevel():AddAngelRoomChance(1) -- any number above 0 sets angel room chance to 100%
		GameState.currLevelIsDecided = true
	end
	if GameState.currRoom:GetType() == RoomType.ROOM_DEVIL or GameState.currRoom:GetType() == RoomType.ROOM_ANGEL then
		GameState.currLevelIsDecided = true
	end
end

-- function WhiteHalo:onUseJoker() -- doesn't work (sets chance after devil/angel room is already decidied by game)
-- 	if shouldSpawnAngelRoom() then
-- 		Game():GetLevel():AddAngelRoomChance(1) -- any number above 0 sets angel room chance to 100%
-- 	end
-- 	GameState.currLevelIsDecided = true
-- end

function shouldSpawnAngelRoom()
	if player:HasTrinket(WhiteHalo.TRINKET_WHITE_HALO) and not GameState.currLevelIsDecided and Game():GetLevel():GetStage() >= 3 and Game():GetLevel():GetStage() <= 8 and Game():GetDevilRoomDeals() > 0 then
		GameState.currLevelIsForgiven = false
		-- simulating official angel room chance (coin flips)
		currLevel = Game():GetLevel()
		if currLevel:GetStateFlag(LevelStateFlag.STATE_EVIL_BUM_LEFT) and math.random(100) <= 10 then
			return false
		end
		angelChances = {true, player:HasTrinket(TrinketType.TRINKET_ROSARY_BEAD), Game():GetDonationModAngel() >= 10, player:HasCollectible(CollectibleType.COLLECTIBLE_KEY_PIECE_1), player:HasCollectible(CollectibleType.COLLECTIBLE_KEY_PIECE_2), currLevel:GetStateFlag(LevelStateFlag.STATE_EVIL_BUM_KILLED), currLevel:GetStateFlag(LevelStateFlag.STATE_BUM_LEFT)}
		angelChanceProbs = {50, 50, 50, 25, 25, 25, 10}
		for i=1, #angelChances, 1 do
			if angelChances[i] and math.random(100) <= angelChanceProbs[i] then
				return true
			end
		end
	end
	return false
end

WhiteHalo:AddCallback(ModCallbacks.MC_POST_UPDATE, WhiteHalo.onUpdate)
WhiteHalo:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, WhiteHalo.onNewLevel)
WhiteHalo:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, WhiteHalo.onNewRoom)
-- WhiteHalo:AddCallback(ModCallbacks.MC_USE_CARD, WhiteHalo.onUseJoker, Card.CARD_JOKER)