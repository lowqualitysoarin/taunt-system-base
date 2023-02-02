-- low_quality_soarin © 2023-2024
behaviour("TauntSystem")

function TauntSystem:Start()
	-- Essentials
	self.data = self.gameObject.GetComponent(DataContainer)
	self.emptyCopy = self.targets.empty.gameObject

	-- Taunt Prefabs
	self.tauntPrefabs = {}
	self.alreadyTauntingList = {}

	self.playerTauntPrefab = nil

	-- Configuration
	self.chance = self.script.mutator.GetConfigurationRange("chance")

	local teamAssigned = self.script.mutator.GetConfigurationDropdown("assignedTeam")
	self.chosenTeam = nil

	if (teamAssigned == 0) then
		self.chosenTeam = Team.Blue
	elseif (teamAssigned == 1) then
		self.chosenTeam = Team.Red
	else
		self.chosenTeam = "Both"
	end

	-- Base
	self.tauntSystemReady = false

	self.playerIsTaunting = false
	self.firstButtonPressed = false
	self.canCancelTaunt = false
	self.resetTime = false

	self.pressTime = 0

	-- Keybinds
	self.tauntBind = self.script.mutator.GetConfigurationString("tauntBind")

	-- Listeners
	GameEvents.onActorDied.AddListener(self, "OnActorDied")

	-- Finishing Touches
	self.script.StartCoroutine(self:GetTauntMods())
end

function TauntSystem:OnActorDied(actor, killer)
	-- Initiate taunt for bots
	if (killer ~= nil) then
		if (killer.team == self.chosenTeam or self.chosenTeam == "Both") then
			if (self:CheckIfAllowedToTaunt(killer, actor) and self.tauntSystemReady) then
				local luck = Random.Range(0, 100)
		
				if (luck < self.chance) then
					self:BotTaunt(killer)
				end
			end
		end
	end
end

function TauntSystem:CheckIfAllowedToTaunt(actor, victim)
	-- Checks If the killer is allowed to taunt
	local allowed = false

	if (not actor.isPlayer) then
		if (actor.team ~= victim.team) then
			if (actor.activeVehicle == nil) then
				if (not actor.isInWater) then
					if (not actor.isFallenOver) then
						if (not actor.isParachuteDeployed) then
							allowed = true
						end
					end
				end
			end
		end
	end

	return allowed
end

function TauntSystem:Update()
	-- Manual taunt only for the player
	local player = Player.actor

	if (player ~= nil) then
		if (not player.isDead and player.activeVehicle == nil and not player.isInWater and not player.isFallenOver and not player.isParachuteDeployed) then
			-- Taunt alone when pressed once taunt with squad if double pressed
			if (Input.GetKeyDown(self.tauntBind) and not self.playerIsTaunting and self.firstButtonPressed) then
				if (Time.time - self.pressTime < 0.5) then
					if (self:CheckSquad(player)) then
						self:TauntWithSquad(player)
					else
						self:PlayerTaunt(player)
					end

					self.playerIsTaunting = true
				end

				self.resetTime = true
			end

			-- Gives the pressTime and sets firstButtonPressed to true
			if (Input.GetKeyDown(self.tauntBind) and not self.firstButtonPressed and not self.playerIsTaunting) then
				self.pressTime = Time.time
				self.firstButtonPressed = true
			end

			-- If the pressTime has been overdued over 0.15 then taunt alone
			if (Time.time - self.pressTime > 0.15 and self.firstButtonPressed and not self.playerIsTaunting) then
				self:PlayerTaunt(player)
				self.playerIsTaunting = true

				self.resetTime = true
			end

			-- Resets the bool
			if (self.resetTime) then
				self.firstButtonPressed = false
				self.resetTime = false
			end

			-- Stops the taunting animation
			if (Input.GetKeyDown(self.tauntBind) and self.canCancelTaunt and self.playerTauntPrefab ~= nil) then
				self:CancelTaunt(self.playerTauntPrefab)
				self.canCancelTaunt = false
			end
		end
	end
end

function TauntSystem:CancelTaunt(tauntPrefab)
	local tauntScript = tauntPrefab.gameObject.GetComponent(ScriptedBehaviour).self

	if (tauntScript ~= nil) then
		tauntScript.timer = tauntScript.animationTime
	end
end

function TauntSystem:CheckSquad(player)
	-- A function that checks if the player has a squad
	if (player.squad ~= nil) then
		return true
	else
		return false
	end
end

function TauntSystem:TauntWithSquad(player)
	-- Taunt with squad
	local squadMembers = player.squad.members
	
	for _,actor in pairs(squadMembers) do
		if (actor.isPlayer) then
			self:PlayerTaunt(actor)
		else
			self:BotTaunt(actor)
		end
	end
end

function TauntSystem:BotTaunt(bot)
	-- Check for overlaps
	local actorIsAlreadyTaunting = false

	for _,actor in pairs(self.alreadyTauntingList) do
		if (bot == actor) then
			actorIsAlreadyTaunting = true
			break
		end
	end

	if (actorIsAlreadyTaunting) then return end

	-- Create the taunt prefab
	local chosenTaunt = self.tauntPrefabs[math.random(#self.tauntPrefabs)]
	local dupeTaunt = GameObject.Instantiate(chosenTaunt, bot.transform.position, bot.transform.rotation)

	-- Give the killer name in a separate gameObject as a child (Doing this way because passing values is fucked)
	local emptyCopy = GameObject.Instantiate(self.emptyCopy, dupeTaunt.transform)
	emptyCopy.name = bot.name

	-- Teleport the killer to the taunt prefab
	bot.TeleportTo(dupeTaunt.transform.position, bot.transform.rotation)

	-- Hide the killer
	bot.isRendered = false

	bot.maxBalance = 1000
	bot.balance = bot.maxBalance

	local botWeapons = bot.weaponSlots

	if (#botWeapons > 0) then
		for _,wep in pairs(botWeapons) do
			wep.LockWeapon()
		end
	else
		local activeWeapon = bot.activeWeapon

		if (activeWeapon ~= nil) then 
			activeWeapon.LockWeapon()
		end
	end

	-- Add to alreadyTauntingList to prevent double taunts lmaoo
	self.alreadyTauntingList[#self.alreadyTauntingList+1] = bot
end

function TauntSystem:PlayerTaunt(player)
	-- Similar how does the bot ones work
	-- Create the taunt prefab
	local chosenTaunt = self.tauntPrefabs[math.random(#self.tauntPrefabs)]
	local dupeTaunt = GameObject.Instantiate(chosenTaunt, player.transform.position, player.transform.rotation)

	-- Create a data prefab
	local emptyCopy = GameObject.Instantiate(self.emptyCopy, dupeTaunt.transform)
	emptyCopy.name = player.name

	-- Teleport the player to the taunt prefab
	player.TeleportTo(dupeTaunt.transform.position, player.transform.rotation)

	-- Hide the player
	player.isRendered = false

	player.maxBalance = 1000
	player.balance = player.maxBalance

	local playerWeapons = player.weaponSlots

	if (#playerWeapons > 0) then
		for _,wep in pairs(playerWeapons) do
			-- Lock the weapon
			wep.LockWeapon()
		end
	else
		local activeWeapon = player.activeWeapon

		if (activeWeapon ~= nil) then 
			-- Lock the weapon
			activeWeapon.LockWeapon()
		end
	end

	-- Hides the player's right hand armature because it doesn't hide the third person weapon
	local rightHand = player.GetHumanoidTransformAnimated(HumanBodyBones.RightHand)

	if (rightHand ~= nil) then
		rightHand.gameObject.SetActive(false)
	end

	-- Set camera to thirdperson mode
	PlayerCamera.ThirdPersonCamera()

	-- Assign the taunt prefab
	self.playerTauntPrefab = dupeTaunt

	-- Call the cancel taunt coroutine soo the player can cancel the taunt
	self.script.StartCoroutine(self:CancelTauntTime())
end

function TauntSystem:GetTauntMods()
	return function()
		print("<color=aqua>[TS] low_quality_soarin's Taunts Active</color>")
		coroutine.yield(WaitForSeconds(0.25))
		print("<color=aqua>[TS] Initializing Taunt Sytem...</color>")
		coroutine.yield(WaitForSeconds(0.15))
		print("<color=aqua>[TS] Getting Taunt Mods...</color>")
		coroutine.yield(WaitForSeconds(0.05))

		-- Gets the taunt mods
		local getAllScriptedBehaviours = GameObject.FindObjectsOfType(ScriptedBehaviour)
		local tauntModsFound = {}

		for _,behavior in pairs(getAllScriptedBehaviours) do
			local script = behavior.self

			if (script.isATauntMod ~= nil) then
				if (script.isATauntMod) then
					tauntModsFound[#tauntModsFound+1] = script
				end
			end
		end

		-- Extracting prefabs
		if (#tauntModsFound > 0) then
			print("<color=aqua>[TS] Found </color>" .. #tauntModsFound .. " <color=aqua>Mods</color>")
			print("<color=aqua>[TS] Extracting Assets...</color>")

			for _,tauntContent in pairs(tauntModsFound) do
				local taunts = tauntContent.taunts

				for _,taunt in pairs(taunts) do
					self.tauntPrefabs[#self.tauntPrefabs+1] = taunt
				end
			end

			self.tauntSystemReady = true
		end

		coroutine.yield(WaitForSeconds(0.15))

		if (self.tauntSystemReady) then
			print("<color=aqua>[TS] Taunt System Is Ready!</color>")
		else
			print("<color=red>[TS] Taunt System Disabled. No Taunt Mods Found.</color>")
		end
	end
end

function TauntSystem:CancelTauntTime()
	return function()
		coroutine.yield(WaitForSeconds(0.45))
		self.canCancelTaunt = true
	end
end
