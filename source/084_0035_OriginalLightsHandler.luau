													--[[
██████╗░███████╗██████╗░███████╗██╗██╗░░░██╗███████╗
██╔══██╗██╔════╝██╔══██╗██╔════╝██║██║░░░██║██╔════╝
██████╔╝█████╗░░██████╔╝█████╗░░██║╚██╗░██╔╝█████╗░░
██╔═══╝░██╔══╝░░██╔══██╗██╔══╝░░██║░╚████╔╝░██╔══╝░░
██║░░░░░███████╗██║░░██║██║░░░░░██║░░╚██╔╝░░███████╗
╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░╚═╝░░░╚══════╝
													]]--

-- Emissive Folder (Pacific Hills > 11_Lamps > Emissive)
local emissiveFolder = workspace["Pacific Hills"]["11_Lamps"].Emissive
local emissiveAFolder = emissiveFolder.EmissiveA
local emissiveBFolder = emissiveFolder.EmissiveB

local StreetLamps1 = emissiveFolder["Meshes/11_0x7D497778_StreetLamps_L_1"]
local StreetLamps2 = emissiveFolder["Meshes/11_0x7D497778_StreetLamps_L_2"]
local ParkLamps = emissiveFolder["Meshes/11_0xE28EC6C8_ParkLamps_L"]

while wait(1) do
	if (game.Lighting.ClockTime > 6.3) and (game.Lighting.ClockTime < 17.7) then
		StreetLamps1.Mesh.VertexColor = Vector3.new(1,1,1)
		StreetLamps2.Mesh.VertexColor = Vector3.new(1,1,1)
		ParkLamps.Mesh.VertexColor = Vector3.new(1,1,1)
		
		for _, part in ipairs(emissiveAFolder:GetChildren()) do
			if part:IsA("BasePart") then
				local attachment = part:FindFirstChild("Attachment")
				if attachment and attachment:IsA("Attachment") then
					local pointLight = attachment:FindFirstChild("PointLight")
					if pointLight and pointLight:IsA("PointLight") then
						pointLight.Enabled = false
					end
				end
			end
		end
		
		for _, part in ipairs(emissiveBFolder:GetChildren()) do
			if part:IsA("BasePart") then
				local attachment = part:FindFirstChild("Attachment")
				if attachment and attachment:IsA("Attachment") then
					local pointLight = attachment:FindFirstChild("PointLight")
					if pointLight and pointLight:IsA("PointLight") then
						pointLight.Enabled = false
					end
				end
			end
		end
		
	else
		StreetLamps1.Mesh.VertexColor = Vector3.new(4,4,4)
		StreetLamps2.Mesh.VertexColor = Vector3.new(4,4,4)
		ParkLamps.Mesh.VertexColor = Vector3.new(4,4,4)
		
		for _, part in ipairs(emissiveAFolder:GetChildren()) do
			if part:IsA("BasePart") then
				local attachment = part:FindFirstChild("Attachment")
				if attachment and attachment:IsA("Attachment") then
					local pointLight = attachment:FindFirstChild("PointLight")
					if pointLight and pointLight:IsA("PointLight") then
						pointLight.Enabled = true
					end
				end
			end
		end
		
		for _, part in ipairs(emissiveBFolder:GetChildren()) do
			if part:IsA("BasePart") then
				local attachment = part:FindFirstChild("Attachment")
				if attachment and attachment:IsA("Attachment") then
					local pointLight = attachment:FindFirstChild("PointLight")
					if pointLight and pointLight:IsA("PointLight") then
						pointLight.Enabled = true
					end
				end
			end
		end
		
	end 
end