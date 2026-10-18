--!strict
-- Client-local procedural animation for streamed R15 law responders.
-- This script is cosmetic only; targeting, movement, firing, and damage remain server-owned.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local MAX_RIGS = 24
local FAR_DISTANCE = 200
local FAR_UPDATE_INTERVAL = 0.25
local AIM_DISTANCE = 110

type Joints = {
	waist: Motor6D,
	rightShoulder: Motor6D,
	leftShoulder: Motor6D,
	rightHip: Motor6D,
	leftHip: Motor6D,
}

type Rig = {
	model: Model,
	humanoid: Humanoid,
	root: BasePart,
	joints: Joints,
	applied: { [Motor6D]: CFrame },
	targets: { [Motor6D]: CFrame },
	connections: { RBXScriptConnection },
	phase: number,
	lastCompute: number,
}

local localPlayer = Players.LocalPlayer
local world = workspace:WaitForChild("RTAWorld")
local responders = world:WaitForChild("Responders")
local rigs: { [Model]: Rig } = {}
local rigCount = 0
local globalConnections: { RBXScriptConnection } = {}
local shuttingDown = false

local function disconnectAll(connections: { RBXScriptConnection })
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
end

local function namedMotor(parent: Instance?, name: string): Motor6D?
	if not parent then
		return nil
	end
	local joint = parent:FindFirstChild(name)
	if joint and joint:IsA("Motor6D") then
		return joint
	end
	return nil
end

local function limbMotor(model: Model, limb: BasePart?, name: string): Motor6D?
	local direct = namedMotor(limb, name)
	if direct then
		return direct
	end
	if limb then
		for _, descendant in model:GetDescendants() do
			if descendant:IsA("Motor6D") and descendant.Name == name and descendant.Part1 == limb then
				return descendant
			end
		end
	end
	return nil
end

local function findJoints(model: Model): Joints?
	local upperTorso = model:FindFirstChild("UpperTorso")
	local rightUpperArm = model:FindFirstChild("RightUpperArm")
	local leftUpperArm = model:FindFirstChild("LeftUpperArm")
	local rightUpperLeg = model:FindFirstChild("RightUpperLeg")
	local leftUpperLeg = model:FindFirstChild("LeftUpperLeg")
	if not (
		upperTorso and upperTorso:IsA("BasePart")
		and rightUpperArm and rightUpperArm:IsA("BasePart")
		and leftUpperArm and leftUpperArm:IsA("BasePart")
		and rightUpperLeg and rightUpperLeg:IsA("BasePart")
		and leftUpperLeg and leftUpperLeg:IsA("BasePart")
	) then
		return nil
	end

	local waist = limbMotor(model, upperTorso, "Waist")
	local rightShoulder = limbMotor(model, rightUpperArm, "RightShoulder")
	local leftShoulder = limbMotor(model, leftUpperArm, "LeftShoulder")
	local rightHip = limbMotor(model, rightUpperLeg, "RightHip")
	local leftHip = limbMotor(model, leftUpperLeg, "LeftHip")
	if not (waist and rightShoulder and leftShoulder and rightHip and leftHip) then
		return nil
	end

	return {
		waist = waist,
		rightShoulder = rightShoulder,
		leftShoulder = leftShoulder,
		rightHip = rightHip,
		leftHip = leftHip,
	}
end

local function removeApplied(rig: Rig)
	for joint, offset in rig.applied do
		if joint.Parent then
			joint.Transform = joint.Transform * offset:Inverse()
		end
	end
	table.clear(rig.applied)
end

local scanResponders: () -> () = function() end

local function removeRig(model: Model)
	local rig = rigs[model]
	if not rig then
		return
	end
	rigs[model] = nil
	rigCount -= 1
	removeApplied(rig)
	disconnectAll(rig.connections)
	if not shuttingDown then
		task.defer(scanResponders)
	end
end

local function lawModelFrom(instance: Instance): Model?
	local current: Instance? = instance
	while current and current ~= responders do
		if current:IsA("Model") then
			local law = current:GetAttribute("RTALaw")
			if law == "Police" or law == "Military" then
				return current
			end
		end
		current = current.Parent
	end
	return nil
end

local function tryRegister(model: Model)
	if shuttingDown or rigs[model] or rigCount >= MAX_RIGS or not model:IsDescendantOf(responders) then
		return
	end
	local law = model:GetAttribute("RTALaw")
	if law ~= "Police" and law ~= "Military" then
		return
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	local joints = findJoints(model)
	if not humanoid or humanoid.RigType ~= Enum.HumanoidRigType.R15 or not root or not root:IsA("BasePart") or not joints then
		return
	end

	local rig: Rig = {
		model = model,
		humanoid = humanoid,
		root = root,
		joints = joints,
		applied = {},
		targets = {},
		connections = {},
		phase = 0,
		lastCompute = -math.huge,
	}
	rigs[model] = rig
	rigCount += 1
	table.insert(rig.connections, humanoid.Died:Connect(function()
		removeRig(model)
	end))
	table.insert(rig.connections, model.AncestryChanged:Connect(function()
		if not model:IsDescendantOf(responders) then
			removeRig(model)
		end
	end))
end

scanResponders = function()
	if shuttingDown or rigCount >= MAX_RIGS then
		return
	end
	for _, descendant in responders:GetDescendants() do
		local model = lawModelFrom(descendant)
		if model then
			tryRegister(model)
			if rigCount >= MAX_RIGS then
				break
			end
		end
	end
end

local function viewerPosition(): Vector3?
	local character = localPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root.Position
	end
	local camera = workspace.CurrentCamera
	return if camera then camera.CFrame.Position else nil
end

local function targetRoot(rig: Rig): BasePart?
	local userId = rig.model:GetAttribute("TargetUserId")
	if typeof(userId) ~= "number" then
		return nil
	end
	local player = Players:GetPlayerByUserId(userId)
	local character = player and player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function computeTargets(rig: Rig, deltaTime: number)
	local velocity = rig.root.AssemblyLinearVelocity
	local horizontalSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
	local walkSpeed = math.max(rig.humanoid.WalkSpeed, 1)
	local movingWeight = math.clamp((horizontalSpeed - 0.5) / 3, 0, 1)
	local speedRatio = math.clamp(horizontalSpeed / walkSpeed, 0, 1.5)
	rig.phase += deltaTime * (5.5 + 4 * speedRatio)
	local stride = math.sin(rig.phase) * math.rad(30) * movingWeight * math.min(speedRatio, 1)
	local bounce = math.abs(math.cos(rig.phase)) * math.rad(2) * movingWeight

	local target = targetRoot(rig)
	local aiming = false
	local aimYaw = 0
	if target then
		local displacement = target.Position - rig.root.Position
		local horizontal = Vector3.new(displacement.X, 0, displacement.Z)
		if horizontal.Magnitude > 0.01 and horizontal.Magnitude <= AIM_DISTANCE then
			aiming = true
			local localDirection = rig.root.CFrame:VectorToObjectSpace(horizontal.Unit)
			aimYaw = math.clamp(math.atan2(-localDirection.X, -localDirection.Z), math.rad(-35), math.rad(35))
		end
	end

	local joints = rig.joints
	local targets = rig.targets
	targets[joints.waist] = CFrame.Angles(-bounce, aimYaw * 0.7, 0)
	targets[joints.rightHip] = CFrame.Angles(-stride, 0, 0)
	targets[joints.leftHip] = CFrame.Angles(stride, 0, 0)
	if aiming then
		targets[joints.rightShoulder] = CFrame.Angles(math.rad(-72), math.rad(-8), math.rad(7))
		targets[joints.leftShoulder] = CFrame.Angles(math.rad(-58), math.rad(19), math.rad(-21))
	else
		-- The equipped gun stays in a low-ready right-arm hold while the left arm counter-swings.
		targets[joints.rightShoulder] = CFrame.Angles(math.rad(-38) + stride * 0.18, math.rad(-8), math.rad(10))
		targets[joints.leftShoulder] = CFrame.Angles(-stride * 0.7, 0, math.rad(-5))
	end
end

local function preAnimation()
	for _, rig in rigs do
		removeApplied(rig)
	end
end

local function preSimulation(deltaTime: number)
	local now = os.clock()
	local viewer = viewerPosition()
	for model, rig in rigs do
		if rig.humanoid.Health <= 0 or not model:IsDescendantOf(responders) then
			removeRig(model)
			continue
		end

		local far = viewer ~= nil and (rig.root.Position - viewer).Magnitude > FAR_DISTANCE
		if not far or now - rig.lastCompute >= FAR_UPDATE_INTERVAL then
			local elapsed = if rig.lastCompute > 0 then now - rig.lastCompute else deltaTime
			rig.lastCompute = now
			computeTargets(rig, math.min(elapsed, FAR_UPDATE_INTERVAL))
		end
		for joint, offset in rig.targets do
			if joint.Parent then
				joint.Transform = joint.Transform * offset
				rig.applied[joint] = offset
			end
		end
	end
end

table.insert(globalConnections, responders.DescendantAdded:Connect(function(descendant)
	local model = lawModelFrom(descendant)
	if model then
		tryRegister(model)
	end
end))
table.insert(globalConnections, RunService.PreAnimation:Connect(preAnimation))
table.insert(globalConnections, RunService.PreSimulation:Connect(preSimulation))
table.insert(globalConnections, script.Destroying:Connect(function()
	shuttingDown = true
	disconnectAll(globalConnections)
	local models = {}
	for model in rigs do
		table.insert(models, model)
	end
	for _, model in models do
		removeRig(model)
	end
end))

scanResponders()
