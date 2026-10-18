-- StarterPlayer.StarterPlayerScripts.RTA.WeaponEffects
-- Client-only cosmetic effects. The authoritative weapon service owns hit validation and damage.

local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local MAX_ACTIVE_EFFECTS = 100
local REDUCED_EFFECTS_THRESHOLD = 75
local MAX_TRACER_DISTANCE = 1_500

-- Centralized so project-owned audio/textures can replace the built-in placeholders.
-- The sound files were found in the installed Roblox Studio content folder, but still need a
-- target-place playback test. Replace them with project-owned firearm audio before release.
local ASSETS = {
	Gunshot = "rbxasset://sounds/impact_explosion_03.mp3",
	Reload = "rbxasset://sounds/action_get_up.mp3",
	SparkTexture = "rbxasset://textures/particles/sparkles_main.dds",
}

local WEAPON_STYLE = {
	Pistol = { tracerWidth = 0.035, flashCount = 5, volume = 0.34, playbackSpeed = 1.12 },
	SMG = { tracerWidth = 0.03, flashCount = 4, volume = 0.28, playbackSpeed = 1.18 },
	Rifle = { tracerWidth = 0.045, flashCount = 6, volume = 0.42, playbackSpeed = 0.98 },
	Shotgun = { tracerWidth = 0.065, flashCount = 9, volume = 0.5, playbackSpeed = 0.86 },
}

local DEFAULT_STYLE = WEAPON_STYLE.Rifle

export type Effects = {
	shot: (self: Effects, origin: Vector3, finish: Vector3, weaponId: string) -> (),
	impact: (self: Effects, position: Vector3, normal: Vector3) -> (),
	reload: (self: Effects, position: Vector3) -> (),
	destroy: (self: Effects) -> (),
}

type PrivateEffects = Effects & {
	_folder: Folder,
	_active: { [Instance]: true },
	_activeCount: number,
	_destroyed: boolean,
}

local Effects = {}
Effects.__index = Effects
Effects.Assets = ASSETS

local function isFiniteVector(value: Vector3): boolean
	return value.X == value.X
		and value.Y == value.Y
		and value.Z == value.Z
		and math.abs(value.X) < math.huge
		and math.abs(value.Y) < math.huge
		and math.abs(value.Z) < math.huge
end

local function makeEmitter(parent: Instance, name: string): ParticleEmitter
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = name
	emitter.Enabled = false
	emitter.Texture = ASSETS.SparkTexture
	emitter.LightEmission = 1
	emitter.LockedToPart = false
	emitter.Parent = parent
	return emitter
end

function Effects.new(): Effects
	assert(RunService:IsClient(), "WeaponEffects must be constructed by a LocalScript")

	local folder = Instance.new("Folder")
	folder.Name = "RTAWeaponEffects"
	folder.Archivable = false
	folder.Parent = workspace

	local self: PrivateEffects = setmetatable({
		_folder = folder,
		_active = {},
		_activeCount = 0,
		_destroyed = false,
	}, Effects) :: any

	return self
end

function Effects._root(self: PrivateEffects, name: string, position: Vector3, lifetime: number): Part?
	if self._destroyed or self._activeCount >= MAX_ACTIVE_EFFECTS or not isFiniteVector(position) then
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
	sound.RollOffMinDistance = 8
	sound.RollOffMaxDistance = 150
	sound.Parent = root
	sound:Play()
end

function Effects.shot(self: PrivateEffects, origin: Vector3, finish: Vector3, weaponId: string)
	if self._destroyed or not isFiniteVector(origin) or not isFiniteVector(finish) then
		return
	end

	local delta = finish - origin
	if not isFiniteVector(delta) then
		return
	end
	local distance = delta.Magnitude
	if distance ~= distance or distance == math.huge or distance < 0.05 then
		return
	end
	if distance > MAX_TRACER_DISTANCE then
		finish = origin + delta.Unit * MAX_TRACER_DISTANCE
		delta = finish - origin
		distance = MAX_TRACER_DISTANCE
	end

	local style = WEAPON_STYLE[weaponId] or DEFAULT_STYLE
	local reducedEffects = self._activeCount >= REDUCED_EFFECTS_THRESHOLD
	local midpoint = origin:Lerp(finish, 0.5)
	local tracerRoot = if reducedEffects then nil else self:_root("Tracer", midpoint, 0.12)
	if tracerRoot then
		tracerRoot.CFrame = CFrame.lookAt(midpoint, finish)

		local startAttachment = Instance.new("Attachment")
		startAttachment.Name = "Start"
		startAttachment.Position = Vector3.new(0, 0, distance * 0.5)
		startAttachment.Parent = tracerRoot

		local endAttachment = Instance.new("Attachment")
		endAttachment.Name = "Finish"
		endAttachment.Position = Vector3.new(0, 0, -distance * 0.5)
		endAttachment.Parent = tracerRoot

		local beam = Instance.new("Beam")
		beam.Name = "TracerBeam"
		beam.Attachment0 = startAttachment
		beam.Attachment1 = endAttachment
		beam.FaceCamera = true
		beam.LightEmission = 1
		beam.Color = ColorSequence.new(Color3.fromRGB(255, 226, 135), Color3.fromRGB(255, 151, 50))
		beam.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(0.8, 0.25),
			NumberSequenceKeypoint.new(1, 0.85),
		})
		beam.Width0 = style.tracerWidth
		beam.Width1 = style.tracerWidth * 0.55
		beam.Parent = tracerRoot
		TweenService:Create(beam, TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Width0 = 0,
			Width1 = 0,
		}):Play()
	end

	local muzzleRoot = self:_root("MuzzleFlash", origin, 1.6)
	if muzzleRoot then
		muzzleRoot.CFrame = CFrame.lookAt(origin, finish)

		local flash = makeEmitter(muzzleRoot, "Flash")
		flash.Color = ColorSequence.new(Color3.fromRGB(255, 245, 190), Color3.fromRGB(255, 113, 32))
		flash.Lifetime = NumberRange.new(0.035, 0.07)
		flash.Speed = NumberRange.new(4, 9)
		flash.SpreadAngle = Vector2.new(12, 12)
		flash.EmissionDirection = Enum.NormalId.Front
		flash.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.24),
			NumberSequenceKeypoint.new(0.35, 0.11),
			NumberSequenceKeypoint.new(1, 0),
		})
		flash.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.05),
			NumberSequenceKeypoint.new(1, 1),
		})
		flash:Emit(if reducedEffects then 2 else style.flashCount)

		if not reducedEffects then
			local light = Instance.new("PointLight")
			light.Name = "FlashLight"
			light.Color = Color3.fromRGB(255, 170, 72)
			light.Brightness = 1.8
			light.Range = 8
			light.Shadows = false
			light.Parent = muzzleRoot
			TweenService:Create(light, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Brightness = 0,
				Range = 2,
			}):Play()
		end

		playSound(muzzleRoot, ASSETS.Gunshot, style.volume, style.playbackSpeed)
	end
end

function Effects.impact(self: PrivateEffects, position: Vector3, normal: Vector3)
	if self._destroyed or not isFiniteVector(position) or not isFiniteVector(normal) then
		return
	end
	if normal.Magnitude < 0.05 then
		normal = Vector3.yAxis
	else
		normal = normal.Unit
	end

	local root = self:_root("Impact", position + normal * 0.03, 0.65)
	if not root then
		return
	end
	root.CFrame = CFrame.lookAt(root.Position, root.Position + normal)

	local sparks = makeEmitter(root, "Sparks")
	sparks.Color = ColorSequence.new(Color3.fromRGB(255, 232, 160), Color3.fromRGB(255, 119, 45))
	sparks.Lifetime = NumberRange.new(0.12, 0.28)
	sparks.Speed = NumberRange.new(7, 17)
	sparks.SpreadAngle = Vector2.new(55, 55)
	sparks.EmissionDirection = Enum.NormalId.Front
	sparks.Acceleration = Vector3.new(0, -32, 0)
	sparks.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.075),
		NumberSequenceKeypoint.new(1, 0),
	})
	sparks.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(1, 1),
	})
	local reducedEffects = self._activeCount >= REDUCED_EFFECTS_THRESHOLD
	sparks:Emit(if reducedEffects then 3 else 7)

	if not reducedEffects then
		local dust = makeEmitter(root, "Dust")
		dust.Color = ColorSequence.new(Color3.fromRGB(170, 164, 150))
		dust.LightEmission = 0
		dust.Lifetime = NumberRange.new(0.18, 0.4)
		dust.Speed = NumberRange.new(0.8, 2.6)
		dust.SpreadAngle = Vector2.new(75, 75)
		dust.EmissionDirection = Enum.NormalId.Front
		dust.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.13),
			NumberSequenceKeypoint.new(1, 0.38),
		})
		dust.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.55),
			NumberSequenceKeypoint.new(1, 1),
		})
		dust:Emit(3)
	end
end

function Effects.reload(self: PrivateEffects, position: Vector3)
	if self._destroyed or not isFiniteVector(position) then
		return
	end

	local root = self:_root("ReloadSFX", position, 1.2)
	if root then
		playSound(root, ASSETS.Reload, 0.24, 1.05)
	end
end

function Effects.destroy(self: PrivateEffects)
	if self._destroyed then
		return
	end
	self._destroyed = true
	self._folder:Destroy()
	table.clear(self._active)
	self._activeCount = 0
end

return Effects
