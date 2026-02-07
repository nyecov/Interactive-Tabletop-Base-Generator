---
name: OpenSCAD Cheatsheet
description: A quick reference for OpenSCAD syntax, functions, and modules.
---

# OpenSCAD Cheatsheet

## Syntax
```openscad
var = value;
var = condition ? value_if_true : value_if_false;
var = function(x) x + x;
module name(...) { ... } name();
function name(...) = ... name();
include <....scad>
use <....scad>
```

## Constants
```openscad
undef
PI
```

## Special Variables
```openscad
$fa, $fs, $fn  // Fragment angle, size, number
$t              // Animation time step
$vpr, $vpt, $vpd // Viewport rotation, translation, distance
$children       // Number of children
$preview        // True if in preview mode (F5)
```

## Modifier Characters
```openscad
* // Disable
! // Root (ignore others)
# // Debug (transparent red)
% // Background (transparent gray)
```

## 2D
```openscad
circle(radius | d=diameter)
square(size, center)
square([width, height], center)
polygon([points])
polygon([points], [paths])
text(t, size, font, halign, valign, spacing, direction, language, script)
import("file.dxf", convexity)
projection(cut)
```

## 3D
```openscad
sphere(radius | d=diameter)
cube(size, center)
cube([width, depth, height], center)
cylinder(h, r|d, center)
cylinder(h, r1|d1, r2|d2, center)
polyhedron(points, faces, convexity)
import("file.stl", convexity)
linear_extrude(height, center, convexity, twist, slices)
rotate_extrude(angle, convexity)
surface(file="file.png", center, convexity)
```

## Transformations
```openscad
translate([x, y, z])
rotate([x, y, z])
scale([x, y, z])
resize([x, y, z], auto)
mirror([x, y, z])
multmatrix(m)
color("colorname", alpha)
color([r, g, b, a])
offset(r|delta, chamfer)
hull()
minkowski()
```

## Boolean Operations
```openscad
union()
difference()
intersection()
```

## List Comprehensions
```openscad
[ for (i = range|list) i ]
[ for (init; condition; next) i ]
[ for (i = ...) if (condition(i)) i ]
[ for (i = ...) let (assignments) a ]
```

## Flow Control
```openscad
for (i = [start:end]) { ... }
for (i = [start:step:end]) { ... }
for (i = [..., ...]) { ... }
intersection_for(i = [start:end]) { ... }
if (...) { ... }
else { ... }
```

## Mathematical
```openscad
abs(x), sign(x)
sin(x), cos(x), tan(x)
acos(x), asin(x), atan(x), atan2(y, x)
floor(x), ceil(x), round(x)
ln(x), log(x), pow(x, y), sqrt(x), exp(x)
min(a, b), max(a, b)
rands(min, max, count, seed)
norm(v), cross(v1, v2)
concat(l1, l2)
len(l)
```

## Other
```openscad
echo(...)
render(convexity)
children(idx)
assert(condition, message)
```
