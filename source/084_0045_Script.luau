local Seat = script.Parent

local DLSWeldC0 = CFrame.new(-1, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0)
local DLSWeldC1 = CFrame.new(0.5, 0.5, 0, -0, -0, -1, 0, 1, 0, 1, 0, 0)
local DRSWeldC0 = CFrame.new(1, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0)
local DRSWeldC1 = CFrame.new(-0.5, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, -0, -0)

local DLHWeldC0 = CFrame.new(-1, -1, 0, -0, -0, -1, 0, 1, 0, 1, 0, 0)
local DLHWeldC1 = CFrame.new(-0.5, 1, 0, -0, -0, -1, 0, 1, 0, 1, 0, 0)
local DRHWeldC0 = CFrame.new(1, -1, 0, 0, 0, 1, 0, 1, 0, -1, -0, -0)
local DRHWeldC1 = CFrame.new(0.5, 1, 0, 0, 0, 1, 0, 1, 0, -1, -0, -0)

local DNWeldC0 = CFrame.new(0, 1, 0, -1, -0, -0, 0, 0, 1, 0, 1, 0)
local DNWeldC1 = CFrame.new(0, -0.5, 0, -1, -0, -0, 0, 0, 1, 0, 1, 0)

function ChildAdded(Child)
	if Child.Name == "SeatWeld" then

	local Character = Child.Part1.Parent

	Child.C0 = CFrame.new(0, 0, 0.5) * CFrame.fromEulerAnglesXYZ(math.rad(-80), 0, 0)

	if Character.Torso:FindFirstChild("Left Shoulder") then
	Character.Torso["Left Shoulder"].C0 = CFrame.new(-1, 0.5, 0) * CFrame.fromEulerAnglesXYZ(math.rad(40), math.rad(10), math.rad(100))
	Character.Torso["Left Shoulder"].C1 = CFrame.new(0, 0.5, 0) * CFrame.fromEulerAnglesXYZ(0, 0, 0)
	end

	if Character.Torso:FindFirstChild("Right Shoulder") then
	Character.Torso["Right Shoulder"].C0 = CFrame.new(1, 0.5, 0) * CFrame.fromEulerAnglesXYZ(math.rad(40), math.rad(-10), math.rad(-100))
	Character.Torso["Right Shoulder"].C1 = CFrame.new(0, 0.5, 0) * CFrame.fromEulerAnglesXYZ(0, 0, 0)
	end

	if Character.Torso:FindFirstChild("Left Hip") then
	Character.Torso["Left Hip"].C0 = CFrame.new(-0.5, -1, 0) * CFrame.fromEulerAnglesXYZ(math.rad(80), 0, math.rad(90))
	Character.Torso["Left Hip"].C1 = CFrame.new(0, 1, 0) * CFrame.fromEulerAnglesXYZ(0, 0, 0)
	end

	if Character.Torso:FindFirstChild("Right Hip") then
	Character.Torso["Right Hip"].C0 = CFrame.new(0.5, -1, 0) * CFrame.fromEulerAnglesXYZ(math.rad(80), 0, math.rad(-90))
	Character.Torso["Right Hip"].C1 = CFrame.new(0, 1, 0) * CFrame.fromEulerAnglesXYZ(0, 0, 0)
	end

	if Character.Torso:FindFirstChild("Neck") then
	Character.Torso["Neck"].C0 = CFrame.new(0, 1.5, 0) * CFrame.fromEulerAnglesXYZ(math.rad(-10), 0, 0)
	Character.Torso["Neck"].C1 = CFrame.new(0, 0, 0) * CFrame.fromEulerAnglesXYZ(0, 0, 0)
	end

	end
end

function ChildRemoved(Child)
	if Child.Name == "SeatWeld" then

	local Character = Child.Part1.Parent

	if Character.Torso:FindFirstChild("Left Shoulder") then
	Character.Torso["Left Shoulder"].C0 = DLSWeldC0
	Character.Torso["Left Shoulder"].C1 = DLSWeldC1
	end

	if Character.Torso:FindFirstChild("Right Shoulder") then
	Character.Torso["Right Shoulder"].C0 = DRSWeldC0
	Character.Torso["Right Shoulder"].C1 = DRSWeldC1
	end

	if Character.Torso:FindFirstChild("Left Hip") then
	Character.Torso["Left Hip"].C0 = DLHWeldC0
	Character.Torso["Left Hip"].C1 = DLHWeldC1
	end

	if Character.Torso:FindFirstChild("Right Hip") then
	Character.Torso["Right Hip"].C0 = DRHWeldC0
	Character.Torso["Right Hip"].C1 = DRHWeldC1
	end

	if Character.Torso:FindFirstChild("Neck") then
	Character.Torso["Neck"].C0 = DNWeldC0
	Character.Torso["Neck"].C1 = DNWeldC1
	end

	end
end

Seat.ChildAdded:connect(ChildAdded)
Seat.ChildRemoved:connect(ChildRemoved)
