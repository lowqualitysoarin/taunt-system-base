behaviour("TauntPrefab")

function TauntPrefab:Start()
	-- Data Container
	self.data = self.gameObject.GetComponent(DataContainer)

	-- Essentials
	self.soundBank = self.gameObject.GetComponent(SoundBank)
	self.mesh = self.targets.mesh.gameObject.GetComponent(SkinnedMeshRenderer)
	self.pivot = self.targets.pivot.transform

	-- Base
	self.animationTime = self.data.GetFloat("playTime")
	self.actorContained = nil

	self.timer = 0

	self.succesfullyGetKiller = false

	-- Finishing Touches
	self:GetKiller()
	
	if (self.soundBank ~= nil) then
		self.soundBank.PlayRandom()
	end

	-- Taunt System Base
	tauntSystemBase = nil

	local tauntOBJ = GameObject.Find("[LQS]TauntSystem(Clone)")

	if (tauntOBJ ~= nil) then
		tauntSystemBase = tauntOBJ.gameObject.GetComponent(TauntSystem)
	end
end

function TauntPrefab:Update()
	-- Call this block if it gets the killer all fine
	if (self.succesfullyGetKiller) then
		-- Apply Skin
		local skinnedMesh = self.actorContained.gameObject.GetComponentInChildren(SkinnedMeshRenderer)

		if (skinnedMesh ~= nil) then
			self.mesh.sharedMesh = skinnedMesh.sharedMesh
			self.mesh.sharedMaterials = skinnedMesh.sharedMaterials
		end

		-- Teleport the actor to the taunt prefab soo they won't go anywhere
		local tpPos = nil

		if (self.actorContained.isPlayer) then
			tpPos = Vector3(self.pivot.position.x, self.pivot.position.y - 1.75, self.pivot.position.z)
		else
			tpPos = Vector3(self.pivot.position.x, self.pivot.position.y - 0.85, self.pivot.position.z)
		end

		self.actorContained.TeleportTo(tpPos, Quaternion.identity)

		-- Destroy Timer
		self.timer = self.timer + 1 * Time.deltaTime
		if (self.timer >= self.animationTime) then
			self:ResetActor()
			GameObject.Destroy(self.gameObject)
		end

		-- Automatically Destroy When The Killer Is Killed
		if (self.actorContained.isDead) then
			self:ResetActor()
			GameObject.Destroy(self.gameObject)
		end
	end
end

function TauntPrefab:ResetActor()
	-- Resets the actor
	self.actorContained.isRendered = true

	self.actorContained.maxBalance = 100
	self.actorContained.balance = self.actorContained.maxBalance

	local actorLoadout = self.actorContained.weaponSlots

	if (#actorLoadout > 0) then
		for _,wep in pairs(actorLoadout) do
			-- Unlock the weapon
			wep.UnlockWeapon()
		end
	else
		local activeWeapon = self.actorContained.activeWeapon

		if (activeWeapon ~= nil) then 
			-- Unlock the weapon
			activeWeapon.UnlockWeapon()
		end
	end

	if (tauntSystemBase ~= nil) then
		-- Remove the current actor from alreadyTauntingList
		if (not self.actorContained.isPlayer) then
			for int,actor in pairs(tauntSystemBase.alreadyTauntingList) do
				if (actor == self.actorContained) then
					table.remove(tauntSystemBase.alreadyTauntingList, int)
					break
				end
			end
		end

	    -- If the actor is a player then do additional stuff
		if (self.actorContained.isPlayer) then
			-- Set camera back to firstperson mode
			if (not self.actorContained.isDead) then
				PlayerCamera.FirstPersonCamera()
			end
	
			-- Hides the player's right hand armature because it doesn't hide the third person weapon
			local rightHand = self.actorContained.GetHumanoidTransformAnimated(HumanBodyBones.RightHand)
			
			if (rightHand ~= nil) then
				rightHand.gameObject.SetActive(true)
			end
	
			-- Set player is taunting to false soo the player can taunt again
			tauntSystemBase.playerIsTaunting = false
		end
	end
end

function TauntPrefab:GetKiller()
	-- Simply gets the killer soo it can get it's data for the mesh and materials
	local killerName = self.transform.GetChild(2).gameObject.name
	local actors = ActorManager.actors

	for _,actor in pairs(actors) do
		if (killerName == actor.name) then
			self.actorContained = actor
			self.succesfullyGetKiller = true
			break
		end
	end
end