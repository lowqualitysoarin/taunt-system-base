behaviour("TauntModContent")

function TauntModContent:Start()
	-- Confirmation
	self.isATauntMod = true

	-- Data
	self.data = self.gameObject.GetComponent(DataContainer)

	-- Get Taunt Prefabs
	self.taunts = self.data.GetGameObjectArray("taunt")
end
