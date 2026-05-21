## 1. Goals:

The script...:
Finds a part named VisiblePart
Finds the 8 corners of the part in 3D
Finds the position of those corners in 2D screen space
Tests whether any of the 8 corners are on screen
If none are visible: Tests whether the part still intersects with the screen edges.
If visible:
Adds a frame to a timer
Updates GUI text

## 2. Services
```lua
    local Players = game:GetService("Players")
    local FrameService = game:GetService("RunService")
```
    
Explanation

    Players 
    
Used to access information about players.

    RunService
    
Used to manage frame updates.

## 3. Player + Camera
```lua
local Player = Players.LocalPlayer
local TargetPart = workspace:WaitForChild("VisiblePart")
local ActiveCamera = workspace.CurrentCamera
```
Meaning:
LocalPlayer = the local player who is currently using the game.
VisiblePart = the actual part we want to check for visibility.
CurrentCamera = the camera that the local player is viewing the game through.

## 4. Math for Part Size
```lua
local PartSize = TargetPart.Size
local HalfSize = PartSize * 0.5
```
If:
```lua

PartSize = Vector3.new(10, 6, 4)
```

Then:
```lua
HalfSize = Vector3.new(5, 3, 2)
```
Because why:

Part is in the middle.

When to determine corners you move...

±X
±Y
±Z

from the middle of the part.

## 5. All 8 Corner Coordinates
```lua
local CornerData = {
Vector3.new(HalfSize.X, HalfSize.Y, HalfSize.Z),
...
}
```
This will save all 8 of the possible corner offsets. There are:

`left/right`
`top/bottom`
`front/back`

Of a cube, which adds up to:

2 * 2 * 2=8 corners

## 6. Geometry Concept: Bounding Box

The script treats the part as a rectangular box.

These 8 points define its bounding box.

Visualization:
```
      (+,+,+) -------- (+,+,-)
         /|              /|
        / |             / |
(-,+,+) -------- (-,+,-) |
       |  |            | |
       | (+,-,+) ------|- (+,-,-)
       | /             | /
       |/              |/
(-,-,+) -------- (-,-,-)
```

## 7. BuildWorldCorners()
```lua
Corners[Index] = (ObjectFrame + CornerData[Index]).Position
```
This is VERY important mathematically.

## 8. CFrame Mathematics
What is CFrame?

A CFrame stores:

position and
rotation 
of an object.

Key Idea

ObjectFrame + offset

means:

"Move in the object's LOCAL coordinate system."

This is NOT simple vector addition.

Roblox internally transforms the local offset using rotation matrices.

## 9. Rotation Matrix Concept

When an object rotates:
```
Local X axis changes
Local Y axis changes
Local Z axis changes
```
So adding:
```lua
Vector3.new(5,0,0)
```
does NOT always move world-right.

It moves along the object's rotated right direction.

## 10. The Mathematics Used
This internally uses:

Coordinate Transformation

A local point becomes world point using:

P(world) =R⋅P(local) +T 

Where:
```
R = rotation matrix
Plocal = local corner offset
T = object position
```
This is foundational 3D graphics math.

## 11. DrawCornerMarkers()

Creates tiny neon cubes at each corner.

Purpose:

* debugging
* visualization
### 12. Time Formatting
```lua
local Days = math.floor(TotalSeconds / 86400)
```
86400 seconds = 1 day.

Modular Arithmetic Used
```lua
TotalSeconds % 86400
```
This removes complete days.

That is modulo arithmetic.

## 13. WorldToViewportPoint()

This is the MOST important graphics concept here.
```lua
ActiveCamera:WorldToViewportPoint(Corners[Index])
```
Converts:
```
3D world point
|
v
2D screen point
```
## 14. Projection Mathematics

Games use perspective projection.

Objects farther away appear smaller.

The camera transforms world coordinates into screen coordinates using projection matrices.

Conceptually:
```lua
P(screen) = ProjectionMatrix x ViewMatrix x Pworld
```

## 15. What Returned Point Contains
```
Point.X
Point.Y
Point.Z
X/Y
```
Screen coordinates.
```
Z
```
Depth from camera.

Important:
```
Point.Z > 0
```
means:

point is in **front** of camera

If negative:

**behind** camera

## 16. Visibility Test
```lua
Point.X >= 0 and Point.X <= Width
```

Checks if point lies inside screen rectangle.

This is basic rectangle boundary mathematics.
## 17. Why Checking Corners Is Not Enough

Imagine giant object:
```
+------------------+
|                  |
|     SCREEN       |
|                  |
+------------------+
```
Object may cover screen while ALL corners are outside.

Example:
```
Corner ----------- Corner
     \ SCREEN /
Corner ----------- Corner
```
No corner inside.

BUT object visible.

So another test is needed.

## 18. Intersection of segments - Mathematics

Function:
```
SegmentsOverlap()
```
This function tells you if two line segments intersect.

This is called computational geometry.

## 19. Mathematics - the kernel

It's all based on determinants.

Divider
```
local Divider =
(AX-BX)*(CY-DY)
-
(AY-BY)*(CX-DX)
```
This is related to:

2D Cross Product

Used for:
```
 orientation
 parallelism
 intersection
```
## 20. Math - Parallel lines
```lua
if Divider == 0 then
 return false
end
```

If the determinant is zero, then the lines are parallel. Thus, no intersection

## 21. Parametric Line Equations

The ratios:

Ratio1
Ratio2

come from solving:
```
A+t(B−A)=C+u(D−C)
```
Where:

* t
* u

are interpolation parameters.


## 22. Meaning of Ratios

If :
```
0<=t<=1
```
point is on segment AB.
If:
```
0<=u<=1
```
point is on segment CD.
Both true segments have intersection points.

## 23. Screen Borders
```
ScreenBorders = { {LeftTop,RightTop},{...}}
```

The 4 borders of the screen are defined.
```
Top
Right
Bottom
Left
```
## 24. Heartbeat Loop
```lua
    FrameService.Heartbeat:Connect(function(DeltaTime)
```
Every frame will be called.

## 25. DeltaTime Mathematics
```
    VisibleTime += DeltaTime
```
This has frame independent time tracking.
If the game runs at:

    30 Fps
    144 Fps

The timer will still be correct, because:

    DeltaTime = actual passed seconds

26. Visibility Algorithm

The script
```
Step 1
Get all corners
Step 2
Project to screen.
Step 3
Check :
    any corner is inside the screen?
    Yes
        visible
    No:
        check if lines intersect screen borders
        Yes
            visible
```
## 27. The Script has Hidden Issue
This section:
```lua
    local PreviousPoint = ScreenPoints[#ScreenPoints]
    for _, CurrentPoint in ipairs(ScreenPoints) do
```
connects the corners in order of the box (which is incorrect as corners don't represent the sides). So some of the lines connecting corners to the edges of the screen is not correct.

## 28. This issue can be solved by:
```lua
Edges = { {1,2},{1,3},{...}}
```
It has to check each edge from the box, not corner connecting corner.

# 29. This script has one major issue too:
It is not considering occlusion of other objects, for example:

    Camera
        Wall
            VisiblePart

The script still marks "VisiblePart" as visible since it's checking screen visibility only, and not considering the Wall object and casting ray through it, to see if "VisiblePart" should be visible.

## 30. Real Vs Screen Visibility:
The script only check screen visibility, and not the actual visibility on screen.Games usually use techniques such as:
* Ray casting
* Depth buffering
* Frustum culling
* Occlusion culling

## 31. Performance Concept:
The script creates tables, transform 8 points, projection and collision checking on every frame, which can seem expensive for a single object, but for multiple objects in game it gets more expensive.

## References:
https://en.wikipedia.org/wiki/Line%E2%80%93line_intersection

https://www.lighthouse3d.com/tutorials/view-frustum-culling/
