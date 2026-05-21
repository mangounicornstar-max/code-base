local Players = game:GetService("Players")
local FrameService = game:GetService("RunService")

local Player = Players.LocalPlayer

local TargetPart = workspace:WaitForChild("VisiblePart")
local ActiveCamera = workspace.CurrentCamera

local PartSize = TargetPart.Size
local HalfSize = PartSize * 0.5
local VisibleTime = 0

local CounterLabel = Player:WaitForChild("PlayerGui")
	:WaitForChild("LookTime")
	:WaitForChild("Frame")
	:WaitForChild("Counter")


local CornerData = {
	Vector3.new(HalfSize.X, HalfSize.Y, HalfSize.Z),
	Vector3.new(HalfSize.X, HalfSize.Y, -HalfSize.Z),
	Vector3.new(HalfSize.X, -HalfSize.Y, HalfSize.Z),
	Vector3.new(HalfSize.X, -HalfSize.Y, -HalfSize.Z),

	Vector3.new(-HalfSize.X, HalfSize.Y, HalfSize.Z),
	Vector3.new(-HalfSize.X, HalfSize.Y, -HalfSize.Z),
	Vector3.new(-HalfSize.X, -HalfSize.Y, HalfSize.Z),
	Vector3.new(-HalfSize.X, -HalfSize.Y, -HalfSize.Z),
}

local ScreenBorders = {}

local function BuildWorldCorners()
	local Corners = table.create(8)
	local ObjectFrame = TargetPart.CFrame

	for Index = 1, 8 do
		Corners[Index] = (ObjectFrame + CornerData[Index]).Position
	end

	return Corners
end


local function DrawCornerMarkers(Corners)
	for _, Corner in ipairs(Corners) do
		local Marker = Instance.new("Part")

		Marker.Anchored = true
		Marker.CanCollide = false
		Marker.Material = Enum.Material.Neon
		Marker.Color = Color3.fromRGB(255, 0, 0)
		Marker.Size = Vector3.new(2, 2, 2)
		Marker.CFrame = CFrame.new(Corner)
		Marker.Parent = workspace
		Marker.Transparency = 1
	end
end

local function FormatTime(TotalSeconds)
	local Days = math.floor(TotalSeconds / 86400)
	local Hours = math.floor((TotalSeconds % 86400) / 3600)
	local Minutes = math.floor((TotalSeconds % 3600) / 60)
	local Seconds = math.floor(TotalSeconds % 60)

	return string.format("%d:%02d:%02d:%02d", Days, Hours, Minutes, Seconds)
end

local function ConvertToScreenSpace(Corners)
	local Points = table.create(8)

	for Index = 1, 8 do
		Points[Index] = ActiveCamera:WorldToViewportPoint(Corners[Index])
	end

	return Points
end

local function IsPointInsideView(Point, Width, Height)
	return
		Point.Z > 0 and
		Point.X >= 0 and Point.X <= Width and
		Point.Y >= 0 and Point.Y <= Height
end

local function SegmentsOverlap(A, B, C, D)
	local AX, AY = A.X, A.Y
	local BX, BY = B.X, B.Y
	local CX, CY = C.X, C.Y
	local DX, DY = D.X, D.Y

	local Divider = (AX - BX) * (CY - DY) - (AY - BY) * (CX - DX)

	if Divider == 0 then
		return false
	end

	local Ratio1 = ((AX - CX) * (CY - DY) - (AY - CY) * (CX - DX)) / Divider
	local Ratio2 = ((AX - CX) * (AY - BY) - (AY - CY) * (AX - BX)) / Divider

	return
		Ratio1 >= 0 and Ratio1 <= 1 and
		Ratio2 >= 0 and Ratio2 <= 1
end

local function SetupScreenBounds()
	local ViewSize = ActiveCamera.ViewportSize

	local LeftTop = Vector3.zero
	local RightTop = Vector3.new(ViewSize.X, 0, 0)

	local LeftBottom = Vector3.new(0, ViewSize.Y, 0)
	local RightBottom = Vector3.new(ViewSize.X, ViewSize.Y, 0)

	ScreenBorders = {
		{LeftTop, RightTop},
		{RightTop, RightBottom},
		{RightBottom, LeftBottom},
		{LeftBottom, LeftTop},
	}

	return ViewSize
end

local InitialCorners = BuildWorldCorners()

DrawCornerMarkers(InitialCorners)

FrameService.Heartbeat:Connect(function(DeltaTime)
	local CurrentCorners = BuildWorldCorners()
	local ScreenPoints = ConvertToScreenSpace(CurrentCorners)

	local ViewSize = SetupScreenBounds()

	local ObjectVisible = false

	for _, Point in ipairs(ScreenPoints) do
		if IsPointInsideView(Point, ViewSize.X, ViewSize.Y) then
			ObjectVisible = true
			break
		end
	end

	if not ObjectVisible then
		local PreviousPoint = ScreenPoints[#ScreenPoints]

		for _, CurrentPoint in ipairs(ScreenPoints) do
			if CurrentPoint.Z > 0 and PreviousPoint.Z > 0 then
				for _, Border in ipairs(ScreenBorders) do
					if SegmentsOverlap(PreviousPoint, CurrentPoint, Border[1], Border[2]) then
						ObjectVisible = true
						break
					end
				end
			end

			if ObjectVisible then
				break
			end

			PreviousPoint = CurrentPoint
		end
	end
	local IsVisible = ObjectVisible

	if IsVisible then
		VisibleTime += DeltaTime
	end

	CounterLabel.Text = FormatTime(VisibleTime)
	print(ObjectVisible)
end)
