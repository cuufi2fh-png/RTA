-- StarterPlayer.StarterPlayerScripts.RTA.CrimeEffects
-- Client-only presentation for server-approved crime events. This module never applies damage.

local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local MAX_WARNINGS = 6
local MAX_EFFECTS = 40
local REDUCED_EFFECTS_THRESHOLD = 30
local MAX_WARNING_SECONDS = 30
local MAX_RADIUS = 200

-- Both sounds were found in the installed Roblox Studio content folder. They remain editable
-- placeholders and require playback verification in the target place.
local ASSETS = {
	Explosion = "rbxasset://sounds/impact_explosion_03.mp3",
	Alarm = "rbxasset://sounds/volume_slider.ogg",
	ParticleTexture = "rbxasset://textures/particles/sparkles_main.dds",
}

export type Effects = {
	warning: (self: Effects, id: string, position: Vector3, radius: number, seconds: number) -> (),
	explode: (self: Effects, id: string, position: Vector3, radius: number) -> (),
	cancel: (self: Effects, id: string) -> (),
	alarm: (self: Effects, position: Vector3) -> (),
	destroy: (self: Effects) -> (),
}

type WarningRecord = {
	root: Part,
	label: TextLabel,
	deadline: number,
	token: number,
}

type PrivateEffects = Effects & {
	_folder: Folder,
	_warnings: { [string]: WarningRecord },
	_warningCount: number,
	_active: { [Instance]: true },
	_activeCount: number,
	_nextToken: number,
	_destroyed: boolean,
}

local Effects = {}
Effects.__index = Effects
Effects.Assets = ASSETS

local function isFiniteNumber(value: number): boolean
	return value == value and math.abs(value) < math.huge
end

local function isFiniteVector(value: Vector3): boolean
	return isFiniteNumber(value.X) and isFiniteNumber(value.Y) and isFiniteNumber(value.Z)
end

local function makeEmitter(parent: Instance, name: string): ParticleEmitter
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = name
	emitter.Enabled = false
	emitter.Texture = ASSETS.ParticleTexture
	emitter.LightEmission = 1
	emitter.LockedToPart = false
	emitter.Parent = parent
	return emitter
end

local function playSound(root: BasePart, soundId: string, volume: number, playbackSpeed: number)
	if soundId == "" then
		return
	end

	local sound = Instance.new("Sound")
	sound.Name = "ReplaceableSFX"
	sound.SoundId = soundId
	sound.Volume = volume
	sound.PlaybackSpeed = playbackSpeed
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMinDistance = 12
	sound.RollOffMaxDistance = 220
	sound.Parent = root
	sound:Play()
end

function Effects.new(): Effects
	assert(RunService:IsClient(), "CrimeEffects must be constructed by a LocalScript")

	local folder = Instance.new("Folder")
	folder.Name = "RTACrimeEffects"
	folder.Archivable = false
	folder.Parent = workspace

	local self: PrivateEffects = setmetatable({
		_folder = folder,
		_warnings = {},
		_warningCount = 0,
		_active = {},
		_activeCount = 0,
		_nextToken = 0,
		_destroyed = false,
	}, Effects) :: any
	return self
end

function Effects._effectRoot(self: PrivateEffects, name: string, position: Vector3, lifetime: number): Part?
	if self._destroyed or self._activeCount >= MAX_EFFECTS or not isFiniteVector(position) then
		return nil
	end

	local root = Instance.new("Part")
	root.Name = name
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = false
	root.CanTouch = false
	root.CastShadow = false
	root.Transparency = 1
	root.Size = Vector3.one * 0.1
	root.Position = position
	root.Archivable = false
	root.Parent = self._folder

	self._active[root] = true
	self._activeCount += 1
	root.Destroying:Connect(function()
		if self._active[root] then
			self._active[root] = nil
			self._activeCount -= 1
		end
	end)
	Debris:AddItem(root, lifetime)
	return root
end

function Effects._removeWarning(self: PrivateEffects, id: string)
	local record = self._warnings[id]
	if not record then
		return
	end
	self._warnings[id] = nil
	self._warningCount -= 1
	if record.root.Parent then
		record.root:Destroy()
	end
end

function Effects._tickWarning(self: PrivateEffects, id: string, token: number)
	local record = self._warnings[id]
	if self._destroyed or not record or record.token ~= token or not record.root.Parent then
		return
	end

	local remaining = math.max(0, math.ceil(record.deadline - os.clock()))
	record.label.Text = if remaining > 0 then string.format("위험 · %d", remaining) else "위험"
	if remaining <= 0 then
		self:_removeWarning(id)
		return
	end

	-- One bounded callback per warning-second; no frame event or permanent loop.
	task.delay(math.clamp(record.deadline - os.clock(), 0.05, 1), function()
		self:_tickWarning(id, token)
	end)
end

function Effects.warning(self: PrivateEffects, id: string, position: Vector3, radius: number, seconds: number)
	if self._destroyed
		or type(id) ~= "string"
		or #id < 1
		or #id > 64
		or not isFiniteVector(position)
		or not isFiniteNumber(radius)
		or not isFiniteNumber(seconds)
	then
		return
	end

	radius = math.clamp(radius, 2, MAX_RADIUS)
	seconds = math.clamp(seconds, 0.5, MAX_WARNING_SECONDS)
	self:_removeWarning(id)
	if self._warningCount >= MAX_WARNINGS then
		return
	end

	local root = Instance.new("Part")
	root.Name = "DangerWarning_" .. id
	root.Shape = Enum.PartType.Cylinder
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = false
	root.CanTouch = false
	root.CastShadow = false
	root.Material = Enum.Material.Neon
	root.Color = Color3.fromRGB(255, 42, 42)
	root.Transparency = 0.46
	root.Size = Vector3.new(0.1, radius * 2, radius * 2)
	root.CFrame = CFrame.new(position + Vector3.new(0, 0.055, 0)) * CFrame.Angles(0, 0, math.rad(90))
	root.Archivable = false
	root.Parent = self._folder

	local outline = Instance.new("SelectionBox")
	outline.Name = "DangerOutline"
	outline.Adornee = root
	outline.Color3 = Color3.fromRGB(255, 225, 190)
	outline.LineThickness = 0.04
	outline.SurfaceTransparency = 1
	outline.Parent = root

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Countdown"
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.MaxDistance = 350
	billboard.Size = UDim2.fromOffset(180, 46)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 2.6, 0)
	billboard.Adornee = root
	billboard.Parent = root

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundColor3 = Color3.fromRGB(75, 8, 8)
	label.BackgroundTransparency = 0.18
	label.BorderSizePixel = 0
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(255, 238, 222)
	label.TextStrokeColor3 = Color3.fromRGB(40, 0, 0)
	label.TextStrokeTransparency = 0.35
	label.TextScaled = true
	label.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label

	self._nextToken += 1
	local token = self._nextToken
	self._warnings[id] = {
		root = root,
		label = label,
		deadline = os.clock() + seconds,
		token = token,
	}
	self._warningCount += 1
	self:_tickWarning(id, token)
end

function Effects.explode(self: PrivateEffects, id: string, position: Vector3, radius: number)
	if self._destroyed or type(id) ~= "string" or not isFiniteVector(position) or not isFiniteNumber(radius) then
		return
	end
	self:_removeWarning(id)
	radius = math.clamp(radius, 2, MAX_RADIUS)

	local root = self:_effectRoot("CosmeticBlast", position, 2)
	if not root then
		return
	end
	local reducedEffects = self._activeCount >= REDUCED_EFFECTS_THRESHOLD
	local scale = math.clamp(radius / 24, 0.45, 2.5)

	local fireball = makeEmitter(root, "Fireball")
	fireball.Color = ColorSequence.new(Color3.fromRGB(255, 245, 165), Color3.fromRGB(255, 67, 20))
	fireball.Lifetime = NumberRange.new(0.18, 0.38)
	fireball.Speed = NumberRange.new(7 * scale, 18 * scale)
	fireball.SpreadAngle = Vector2.new(180, 180)
	fireball.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.4 * scale),
		NumberSequenceKeypoint.new(0.4, 2.8 * scale),
		NumberSequenceKeypoint.new(1, 0),
	})
	fireball.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(1, 1),
	})
	fireball:Emit(if reducedEffects then 8 else 18)

	local debris = makeEmitter(root, "DebrisSparks")
	debris.Color = ColorSequence.new(Color3.fromRGB(255, 198, 86), Color3.fromRGB(92, 68, 48))
	debris.Lifetime = NumberRange.new(0.35, 0.8)
	debris.Speed = NumberRange.new(12 * scale, 26 * scale)
	debris.SpreadAngle = Vector2.new(180, 180)
	debris.Acceleration = Vector3.new(0, -45, 0)
	debris.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.13 * scale),
		NumberSequenceKeypoint.new(1, 0),
	})
	debris.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.08),
		NumberSequenceKeypoint.new(1, 1),
	})
	debris:Emit(if reducedEffects then 7 else 16)

	if not reducedEffects then
		local light = Instance.new("PointLight")
		light.Name = "BlastLight"
		light.Color = Color3.fromRGB(255, 117, 45)
		light.Brightness = 5
		light.Range = math.min(radius * 1.4, 80)
		light.Shadows = false
		light.Parent = root
		TweenService:Create(light, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Brightness = 0,
			Range = 2,
		}):Play()
	end

	playSound(root, ASSETS.Explosion, 0.62, 0.96)
end

function Effects.cancel(self: PrivateEffects, id: string)
	if self._destroyed or type(id) ~= "string" then
		return
	end
	self:_removeWarning(id)
end

function Effects.alarm(self: PrivateEffects, position: Vector3)
	if self._destroyed or not isFiniteVector(position) then
		return
	end

	local root = self:_effectRoot("RobberyAlarm", position, 1.4)
	if not root then
		return
	end

	local light = Instance.new("PointLight")
	light.Name = "AmberAlert"
	light.Color = Color3.fromRGB(255, 166, 50)
	light.Brightness = if self._activeCount >= REDUCED_EFFECTS_THRESHOLD then 1.2 else 2.8
	light.Range = 18
	light.Shadows = false
	light.Parent = root
	TweenService:Create(light, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Brightness = 0,
		Range = 4,
	}):Play()

	playSound(root, ASSETS.Alarm, 0.28, 1.35)
end

function Effects.destroy(self: PrivateEffects)
	if self._destroyed then
		return
	end
	self._destroyed = true
	self._folder:Destroy()
	table.clear(self._warnings)
	table.clear(self._active)
	self._warningCount = 0
	self._activeCount = 0
end

return Effects
