--!strict
-- Client-only procedural weapon posing. Gameplay, ammo, damage, and fire cadence stay server-owned.

local RunService = game:GetService("RunService")

local FADE_SPEED = 14
local FIRE_DURATION = 0.16

type JointMap = {
	root: Motor6D?,
	waist: Motor6D?,
	neck: Motor6D?,
	rightShoulder: Motor6D?,
	leftShoulder: Motor6D?,
}

export type WeaponPose = {
	equip: (self: WeaponPose, tool: Tool) -> (),
	aim: (self: WeaponPose, enabled: boolean) -> (),
	fire: (self: WeaponPose) -> (),
	reload: (self: WeaponPose, seconds: number) -> (),
	unequip: (self: WeaponPose) -> (),
	destroy: (self: WeaponPose) -> (),
}

type Internal = WeaponPose & {
	_character: Model,
	_humanoid: Humanoid,
	_joints: JointMap,
	_applied: { [Motor6D]: CFrame },
	_connections: { RBXScriptConnection },
	_toolConnections: { RBXScriptConnection },
	_tool: Tool?,
	_equipped: boolean,
	_aiming: boolean,
	_reloadStarted: number?,
	_reloadDuration: number,
	_fireStarted: number?,
	_weight: number,
	_destroyed: boolean,
}

local WeaponPose = {}
WeaponPose.__index = WeaponPose

local function motor(parent: Instance?, name: string): Motor6D?
	if not parent then
		return nil
	end
	local child = parent:FindFirstChild(name)
	if child and child:IsA("Motor6D") then
		return child
	end
	return nil
end

local function findJoints(character: Model, rigType: Enum.HumanoidRigType): JointMap
	if rigType == Enum.HumanoidRigType.R15 then
		local upperTorso = character:FindFirstChild("UpperTorso")
		local lowerTorso = character:FindFirstChild("LowerTorso")
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		return {
			root = motor(rootPart, "Root") or motor(lowerTorso, "Root"),
			waist = motor(upperTorso, "Waist") or motor(lowerTorso, "Waist"),
			neck = motor(character:FindFirstChild("Head"), "Neck") or motor(upperTorso, "Neck"),
			rightShoulder = motor(character:FindFirstChild("RightUpperArm"), "RightShoulder") or motor(upperTorso, "RightShoulder"),
			leftShoulder = motor(character:FindFirstChild("LeftUpperArm"), "LeftShoulder") or motor(upperTorso, "LeftShoulder"),
		}
	end

	local torso = character:FindFirstChild("Torso")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	return {
		root = motor(rootPart, "RootJoint") or motor(torso, "RootJoint"),
		waist = nil,
		neck = motor(torso, "Neck"),
		rightShoulder = motor(torso, "Right Shoulder"),
		leftShoulder = motor(torso, "Left Shoulder"),
	}
end

local function disconnectAll(connections: { RBXScriptConnection })
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
end

local function blendFactor(speed: number, deltaTime: number): number
	return 1 - math.exp(-speed * math.min(deltaTime, 1 / 15))
end

local function setTarget(targets: { [Motor6D]: CFrame }, joint: Motor6D?, value: CFrame)
	if joint then
		targets[joint] = value
	end
end

function WeaponPose:_removeApplied()
	local self = self :: Internal
	for joint, offset in self._applied do
		if joint.Parent then
			joint.Transform = joint.Transform * offset:Inverse()
		end
	end
	table.clear(self._applied)
end

function WeaponPose:_targets(now: number): { [Motor6D]: CFrame }
	local self = self :: Internal
	local targets: { [Motor6D]: CFrame } = {}
	local joints = self._joints
	local rigType = self._humanoid.RigType
	local aiming = self._aiming and self._reloadStarted == nil

	if rigType == Enum.HumanoidRigType.R15 then
		setTarget(targets, joints.waist, CFrame.Angles(math.rad(-3), math.rad(aiming and -8 or -4), 0))
		setTarget(targets, joints.neck, CFrame.Angles(math.rad(2), math.rad(aiming and 7 or 3), 0))
		setTarget(targets, joints.rightShoulder, CFrame.Angles(math.rad(aiming and -70 or -32), math.rad(-10), math.rad(8)))
		setTarget(targets, joints.leftShoulder, CFrame.Angles(math.rad(aiming and -62 or -40), math.rad(aiming and 18 or 10), math.rad(-18)))
	else
		setTarget(targets, joints.root, CFrame.Angles(math.rad(-2), math.rad(aiming and -7 or -3), 0))
		setTarget(targets, joints.neck, CFrame.Angles(math.rad(2), math.rad(aiming and 6 or 2), 0))
		setTarget(targets, joints.rightShoulder, CFrame.Angles(math.rad(aiming and -58 or -28), math.rad(-8), math.rad(12)))
		setTarget(targets, joints.leftShoulder, CFrame.Angles(math.rad(aiming and -52 or -34), math.rad(aiming and 14 or 8), math.rad(-18)))
	end

	if self._reloadStarted then
		local alpha = math.clamp((now - self._reloadStarted) / self._reloadDuration, 0, 1)
		local lift = math.sin(alpha * math.pi)
		local settle = math.sin(alpha * math.pi * 2) * (1 - alpha)
		setTarget(targets, joints.waist, CFrame.Angles(math.rad(-5 * lift), math.rad(-18 * lift), math.rad(-4 * lift)))
		setTarget(targets, joints.rightShoulder, CFrame.Angles(math.rad(-38 - 24 * lift), math.rad(-15), math.rad(10 + 12 * lift)))
		setTarget(targets, joints.leftShoulder, CFrame.Angles(math.rad(-30 - 42 * lift), math.rad(20 + 18 * lift), math.rad(-25 - 12 * settle)))
		if alpha >= 1 then
			self._reloadStarted = nil
		end
	end

	if self._fireStarted then
		local alpha = (now - self._fireStarted) / FIRE_DURATION
		if alpha >= 1 then
			self._fireStarted = nil
		else
			local kick = math.sin(alpha * math.pi) * (1 - alpha)
			local recoil = CFrame.Angles(math.rad(9 * kick), 0, math.rad(2 * kick))
			if joints.rightShoulder then
				targets[joints.rightShoulder] = (targets[joints.rightShoulder] or CFrame.identity) * recoil
			end
			if joints.waist then
				targets[joints.waist] = (targets[joints.waist] or CFrame.identity) * CFrame.Angles(math.rad(2 * kick), 0, 0)
			elseif joints.root then
				targets[joints.root] = (targets[joints.root] or CFrame.identity) * CFrame.Angles(math.rad(2 * kick), 0, 0)
			end
		end
	end

	return targets
end

function WeaponPose:_step(deltaTime: number)
	local self = self :: Internal
	if self._destroyed then
		return
	end

	local targetWeight = if self._equipped and self._tool and self._tool.Parent == self._character then 1 else 0
	self._weight += (targetWeight - self._weight) * blendFactor(FADE_SPEED, deltaTime)
	if self._weight < 0.001 then
		self._weight = 0
		return
	end

	local targets = self:_targets(os.clock())
	for joint, target in targets do
		if joint.Parent then
			local offset = CFrame.identity:Lerp(target, self._weight)
			joint.Transform = joint.Transform * offset
			self._applied[joint] = offset
		end
	end
end

function WeaponPose.new(character: Model): WeaponPose
	assert(RunService:IsClient(), "WeaponPose must be constructed on the client")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	assert(humanoid, "WeaponPose requires a character Humanoid")

	local self: Internal = setmetatable({
		_character = character,
		_humanoid = humanoid,
		_joints = findJoints(character, humanoid.RigType),
		_applied = {},
		_connections = {},
		_toolConnections = {},
		_tool = nil,
		_equipped = false,
		_aiming = false,
		_reloadStarted = nil,
		_reloadDuration = 1,
		_fireStarted = nil,
		_weight = 0,
		_destroyed = false,
	}, WeaponPose) :: any

	-- Remove our previous additive offset before Animator evaluates this frame, then
	-- compose the new offset after animation evaluation and before physics.
	table.insert(self._connections, RunService.PreAnimation:Connect(function()
		self:_removeApplied()
	end))
	table.insert(self._connections, RunService.PreSimulation:Connect(function(deltaTime)
		self:_step(deltaTime)
	end))
	table.insert(self._connections, humanoid.Died:Connect(function()
		self:destroy()
	end))
	table.insert(self._connections, character.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			self:destroy()
		end
	end))

	return self
end

function WeaponPose:equip(tool: Tool)
	local self = self :: Internal
	if self._destroyed then
		return
	end
	self:unequip()
	self._tool = tool
	self._equipped = tool.Parent == self._character
	table.insert(self._toolConnections, tool.Unequipped:Connect(function()
		self:unequip()
	end))
	table.insert(self._toolConnections, tool.AncestryChanged:Connect(function(_, parent)
		if parent ~= self._character then
			self:unequip()
		end
	end))
end

function WeaponPose:aim(enabled: boolean)
	local self = self :: Internal
	if self._destroyed or not self._equipped then
		return
	end
	self._aiming = enabled == true
end

function WeaponPose:fire()
	local self = self :: Internal
	if self._destroyed or not self._equipped then
		return
	end
	self._fireStarted = os.clock()
end

function WeaponPose:reload(seconds: number)
	local self = self :: Internal
	if self._destroyed or not self._equipped then
		return
	end
	self._reloadDuration = math.clamp(if seconds == seconds then seconds else 1, 0.1, 10)
	self._reloadStarted = os.clock()
	self._fireStarted = nil
end

function WeaponPose:unequip()
	local self = self :: Internal
	disconnectAll(self._toolConnections)
	self._tool = nil
	self._equipped = false
	self._aiming = false
	self._reloadStarted = nil
	self._fireStarted = nil
end

function WeaponPose:destroy()
	local self = self :: Internal
	if self._destroyed then
		return
	end
	self._destroyed = true
	self:unequip()
	self:_removeApplied()
	disconnectAll(self._connections)
end

return WeaponPose
