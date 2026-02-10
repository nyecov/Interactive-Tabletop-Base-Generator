/*
    Wargaming Miniature Base Generator
    Units: mm (Standard for 3D printing). Presets may include inch equivalents.
*/

/* [1. Base Configuration] */
// Standard base size preset
base_size_preset = "40mm"; // [1 inch, 2 inch, 3 inch, 25mm, 28mm, 32mm, 40mm, 50mm, 60mm, 70mm, 80mm, 90mm, 100mm, 130mm, 160mm, Custom]

// Use custom size instead of preset
use_custom_size = false;

// Custom base size in mm (only used when use_custom_size is checked)
custom_size_mm = 50.0; // [10.0:1.0:300.0]

// Height/Thickness of the base in mm
base_height_mm = 4.5; // [1.0:0.1:20.0]

// Flare angle (slope of the side) in degrees from vertical
flare_angle = 15; // [0:1:45]

// Minimum outer wall thickness (between magnets and base edge) in mm
min_outer_wall_mm = 2.0; // [0.6:0.1:10.0]

// Bottom chamfer size (45° bevel on bottom edge) in mm. 0 = no chamfer.
bottom_chamfer_mm = 0.6; // [0.0:0.1:10.0]

/* [2. Shape Details] */
// Type of base shape
base_type = "Round"; // [Round, Polygon, Oval]

// Number of sides (only for Polygon base type, min 3)
poly_sides = 4; // [3:1:20]

// Corner rounding radius for polygon corners in mm (0 = sharp corners)
polygon_corner_radius_mm = 0.8; // [0.0:0.1:5.0]

// Standard oval base size preset (only used when base_type = Oval)
oval_preset = "90x52mm"; // [60x35mm, 75x42mm, 90x52mm, 105x70mm, 120x92mm, 150x95mm, 170x105mm, Custom]

// Use custom oval dimensions
use_custom_oval = false;

// Custom oval length (major axis) in mm
custom_oval_length_mm = 90.0; // [20.0:1.0:200.0]

// Custom oval width (minor axis) in mm
custom_oval_width_mm = 52.0; // [20.0:1.0:200.0]

/* [Hidden] */
// CLI Override for base shape (0=Round, 1=Polygon, 2=Oval, -1=Use base_type)
base_shape_index = -1;
actual_base_type = (base_shape_index == 0) ? "Round" : 
                  (base_shape_index == 1) ? "Polygon" : 
                  (base_shape_index == 2) ? "Oval" : base_type;

/* [3. Hollowing / Shelling] */
// Enable shelling (hollow base to save material)
enable_shelling = true;

// Shell wall thickness in mm (outer walls)
shell_wall_thickness_mm = 2.0; // [0.6:0.1:5.0]

// Shell top thickness in mm (top surface)
shell_top_thickness_mm = 0.8; // [0.6:0.1:5.0]

// Thickness of structural reinforcement layer under top shell (0 = disabled)
reinforcement_layer_mm = 1.0; // [0.0:0.1:5.0]

// Enable reinforcement ribs for magnet pockets
enable_ribs = true;

// Thickness of reinforcement ribs in mm
rib_thickness_mm = 0.8; // [0.4:0.1:3.0]

// Number of reinforcement ribs per magnet pocket (minimum 1)
ribs_per_pocket = 3; // [1:1:12]

// Automatically set rib height to 75% of pocket depth
auto_rib_height = true;

// Manual rib height in mm (ignored if auto_rib_height is enabled)
rib_height_mm = 2.0; // [0.5:0.1:10.0]

// Rib length in mm (0 = auto-extend to base edge)
rib_length_mm = 0.0; // [0.0:1.0:100.0]

// Recess for magnet pillars from bottom edge in mm (ensure flushness)
pillar_recess_mm = 0.5; // [0.0:0.1:2.0]

/* [4. Magnet System] */
// Enable magnet pockets (uncheck to remove all magnet features)
enable_magnet_pockets = true;

// Shape of the magnet pocket underneath
magnet_shape = "Round"; // [None, Round, Square, Rectangular]

// Magnet Diameter (Round) or Side A Length (Square/Rect) in mm
magnet_dim_a_mm = 8.0; // [1.0:0.1:50.0]

// Magnet Side B Width (only for Rectangular) in mm
magnet_dim_b_mm = 3.0; // [1.0:0.1:50.0]

// Thickness of the MAGNET (depth of pocket) in mm
magnet_thick_mm = 2.0; // [0.5:0.1:10.0]

// Extra clearance for magnet fit (per side) in mm. Total pocket width = magnet + 2*tolerance
magnet_tolerance_mm = 0.1; // [0.00:0.05:1.0]

// Additional depth for magnet recess (magnet sits deeper than surface)
magnet_recess_mm = 0.2; // [0.0:0.1:5.0]


// Number of magnets (1=center, 2=axis, 3+=center+ring)
magnet_count = 1; // [1:1:12]

// Automatically position magnets based on base size (overrides manual distances below)
auto_magnet_placement = true;

// Distance between 2 magnet centers (only for 2-magnet mode) in mm
magnet_pair_distance_mm = 10.0; // [2.0:0.5:50.0]

// Ring radius for 3+ magnets (distance from center to ring magnets) in mm. 
// Ignored if magnet_count <= 2. For 3+, outer magnets are placed on this ring.
magnet_ring_radius_mm = 8.0; // [2.0:0.5:40.0]

/* [5. Glue Retention] */
// Enable helical/slanted glue channels in magnet pockets
glue_channels_enabled = true;

// Number of glue channels per pocket (Round magnets only)
glue_channel_count = 4; // [1:1:5]

// Channel rotation/slant in degrees (Spiral for Round, Tilt for Square/Rect)
glue_channel_rotation_deg = 45; // [0:15:720]

// Channel diameter in mm (cross-section of the groove)
glue_channel_diameter_mm = 0.8; // [0.3:0.1:2.0]

/* [6. Model Quality] */
// Model resolution (polycount/smoothness)
model_resolution = 100; // [20:10:200]

/* [Hidden] */
// === CONSTANTS (Internal - not exposed in Customizer) ===
$fn = $preview ? max(32, model_resolution / 2) : model_resolution; // Resolution for round shapes (reduced in preview)
in_to_mm = 25.4;              // Inches to mm conversion factor
OVERLAP = 0.05;               // Standard overlap for boolean operations (avoids co-planar artifacts)
MIN_TOP_SOLID = 0.6;          // Minimum solid material above magnet pocket
MIN_WALL_BETWEEN = 0.8;       // Minimum wall thickness between magnet pockets
HARD_MIN_OUTER_WALL = 0.6;    // Absolute minimum outer wall (structural integrity)
POCKET_CHAMFER = 0.4;         // Chamfer size for magnet entry

// Parameters already normalized above

// === PRESET SIZE CONVERSION ===
// Convert preset string to mm value
function preset_to_mm(preset) = 
    (preset == "1 inch") ? 1 * in_to_mm :
    (preset == "2 inch") ? 2 * in_to_mm :
    (preset == "3 inch") ? 3 * in_to_mm :
    (preset == "25mm") ? 25 :
    (preset == "28mm") ? 28 :
    (preset == "32mm") ? 32 :
    (preset == "40mm") ? 40 :
    (preset == "50mm") ? 50 :
    (preset == "60mm") ? 60 :
    (preset == "70mm") ? 70 :
    (preset == "80mm") ? 80 :
    (preset == "90mm") ? 90 :
    (preset == "100mm") ? 100 :
    (preset == "130mm") ? 130 :
    (preset == "160mm") ? 160 :
    custom_size_mm; // "Custom" or unknown defaults to custom

// Determine actual base size in mm (for round/polygon only)
base_size = use_custom_size ? custom_size_mm : preset_to_mm(base_size_preset);

// === OVAL PRESET CONVERSION ===
// Returns [length, width] for oval preset
function oval_preset_to_dims(preset) = 
    (preset == "60x35mm") ? [60, 35] :
    (preset == "75x42mm") ? [75, 42] :
    (preset == "90x52mm") ? [90, 52] :
    (preset == "105x70mm") ? [105, 70] :
    (preset == "120x92mm") ? [120, 92] :
    (preset == "150x95mm") ? [150, 95] :
    (preset == "170x105mm") ? [170, 105] :
    [custom_oval_length_mm, custom_oval_width_mm]; // Custom

// Determine oval dimensions
oval_dims = use_custom_oval ? [custom_oval_length_mm, custom_oval_width_mm] : oval_preset_to_dims(oval_preset);
oval_length = oval_dims[0]; // Major axis
oval_width = oval_dims[1];  // Minor axis

// For ovals, use the minor axis (width) as the "size" for magnet boundary calculations
// since it's the limiting dimension
is_oval = (actual_base_type == "Oval");

// === EARLY DIMENSION VALIDATION ===
// Validate oval dimensions
assert(!is_oval || oval_length > 0,
    str("\nERROR: Oval length must be positive!\n",
        "FIX: Increase 'custom_oval_length_mm' (current: ", oval_length, "mm)."));
assert(!is_oval || oval_width > 0,
    str("\nERROR: Oval width must be positive!\n",
        "FIX: Increase 'custom_oval_width_mm' (current: ", oval_width, "mm)."));
assert(!is_oval || oval_length >= oval_width,
    str("\nERROR: Oval length must be greater than or equal to width!\n",
        "FIX: Ensure 'Length' (", oval_length, "mm) >= 'Width' (", oval_width, "mm). Swap them if needed."));

// Validate custom size when enabled
assert(!use_custom_size || custom_size_mm > 0,
    "\nERROR: Custom size must be positive!\nFIX: Set 'custom_size_mm' > 0.");




// Magnet dims are now in mm
magnet_dim_a = magnet_dim_a_mm;
magnet_dim_b = magnet_dim_b_mm;
magnet_thick = magnet_thick_mm;
magnet_tol = magnet_tolerance_mm;

// Internal Constants/Limits
min_top_solid = MIN_TOP_SOLID;
SHELL_MIN = 0.6;
total_magnet_clearance = magnet_tol * 2;

// Function to calculate the effective radius of a magnet plus clearance
function get_magnet_effective_radius(dim_a, dim_b, shape, clearance) = 
    (shape == "Round") ? (dim_a + clearance) / 2 :
    (shape == "Square") ? (dim_a + clearance) * sqrt(2) / 2 :
    (shape == "Rectangular") ? sqrt(pow(dim_a + clearance, 2) + pow(dim_b + clearance, 2)) / 2 :
    0;

// Logic
has_magnet = enable_magnet_pockets && (magnet_shape != "None");
actual_pillar_recess = (has_magnet && enable_shelling) ? pillar_recess_mm : 0;

// Glue slant: 45 default for Round, 17 default for Square/Rect
actual_glue_slant = (glue_channel_rotation_deg == 45 && magnet_shape != "Round") ? 17 : glue_channel_rotation_deg;

// Geometry Checks
actual_recess = max(0.2, magnet_recess_mm);
// pocket_depth is the depth of the hole itself (excluding pillar recess)
pocket_depth = magnet_thick + actual_recess; 

// Total vertical space taken from bottom edge (includes pillar recess for shelled bases)
total_pocket_height = pocket_depth + actual_pillar_recess;

// MINIMUM VIABLE BASE HEIGHT
// Hard requirement: Must account for Top Shell + Magnet + Recesses
min_solid_cap = enable_shelling ? shell_top_thickness_mm : MIN_TOP_SOLID;
min_viable_base_height = total_pocket_height + min_solid_cap;

// Base height - automatically use the larger of the user input or the minimum viable height
base_height = max(base_height_mm, min_viable_base_height);

// Actual Reinforcement Layer (filler)
// It fills the available cavity space up to reinforcement_layer_mm.
// We cap it so it doesn't exceed the available space (leaving 0.2mm cavity for safety).
max_avail_reinforcement = max(0, base_height - shell_top_thickness_mm - 0.2);
actual_reinforcement = (enable_shelling && reinforcement_layer_mm > 0) ? min(reinforcement_layer_mm, max_avail_reinforcement) : 0;

// Notify user in console if height was adjusted (using small tolerance for precision)
if (base_height > base_height_mm + 1e-4) {
    echo(str("WARNING: base_height_mm (", base_height_mm, "mm) is too thin for current settings. Adjusting to minimum viable height: ", base_height, "mm."));
}

remaining_thickness = base_height - total_pocket_height;

// Calculate Geometry
// For flare: tan(angle) = (bottom_r - top_r) / height
// top_r = bottom_r - (height * tan(angle))
// NOTE: OpenSCAD cylinder r1 is bottom, r2 is top.
// For polygon, cylinder r acts as outer radius of vertices if not careful, 
// but user usually expects flat-to-flat size.
// For regular polygon: Flat-to-Flat (Apothem * 2) = S. Radius (R) = S / (2 * cos(180/n)) isn't quite right for cylinder inputs.
// cylinder(r=...) in OpenSCAD defines the circle circumscribing the polygon vertices.
// We want "size" to mean flat-to-flat width (like a hex nut size).
// Radius (circumscribed) = (Size/2) / cos(180/sides)

function get_radius(size, sides, is_poly) = 
    is_poly ? (size / 2) / cos(180 / sides) : (size / 2);

sides_fn = (actual_base_type == "Polygon") ? poly_sides : $fn;
is_polygon = (actual_base_type == "Polygon");

// Bottom Radius (Base)
r_bottom = get_radius(base_size, sides_fn, is_polygon);

// Calculate Top Radius based on Flare Angle
// The flare angle reduces the radius as we go up.
// Reduction in Radius = height * tan(angle)
// For Polygons, the user expects the "Flare Angle" to be on the flat face.
// Since we are defining the cylinder by the Circumradius (Vertex), we need to scale the reduction.
// dR_vertex = dR_face / cos(180/n)
angle_correction = is_polygon ? cos(180 / poly_sides) : 1;
r_reduction = (base_height * tan(flare_angle)) / angle_correction;
r_top = r_bottom - r_reduction;

// === ASSERTIONS ===
// These will halt rendering and display an error message if conditions are not met.

// 2. Base flare validation
max_flare_angle = atan(r_bottom / base_height);
assert(r_top > 0, 
    str("\nERROR: Flare angle too steep for this height!\n",
        "FIX: Reduce 'flare_angle' to ", floor(max_flare_angle * 10) / 10, "° or less (current: ", flare_angle, "°)."));

// Oval flare validation - ensure top dimensions remain positive
oval_flare_reduction = base_height * tan(flare_angle);
oval_max_flare = is_oval ? atan((min(oval_length, oval_width) / 2) / base_height) : 45;
assert(!is_oval || (oval_width - 2 * oval_flare_reduction) > 0,
    str("\nERROR: Flare angle too steep for this oval width!\n",
        "FIX: Reduce 'flare_angle' to ", floor(oval_max_flare * 10) / 10, "° or less (current: ", flare_angle, "°)."));


// Final safety check for remaining top thickness (should now be guaranteed by auto-correction)
assert(!has_magnet || remaining_thickness >= min_solid_cap - OVERLAP, "Internal Error: Base thickness calculation failed.");

assert(actual_base_type != "Polygon" || poly_sides >= 3,
    str("\nERROR: Invalid polygon sides!\n",
        "FIX: Set 'poly_sides' to 3 or more (current: ", poly_sides, ")."));

// Corner radius validation - must not exceed apothem (inscribed circle radius)
max_corner_radius = is_polygon ? (base_size / 2) * cos(180 / poly_sides) : 0;
assert(!is_polygon || polygon_corner_radius_mm <= max_corner_radius,
    str("\nERROR: Corner radius too large for this polygon size!\n",
        "FIX: Reduce 'polygon_corner_radius_mm' to ", floor(max_corner_radius * 10) / 10, "mm or less."));

assert(base_size > 0, "\nERROR: Base size must be positive!\nFIX: Select a valid preset or set 'custom_size_mm' > 0.");
assert(base_height_mm > 0, "\nERROR: Base height must be positive!\nFIX: Increase 'base_height_mm'.");

// Chamfer validation
// Must not exceed height (vertical) or radius (radial)
assert(bottom_chamfer_mm >= 0 && bottom_chamfer_mm <= base_height,
    str("\nERROR: Bottom chamfer height out of range!\n",
        "FIX: Set 'bottom_chamfer_mm' between 0 and ", base_height, "mm (current: ", bottom_chamfer_mm, "mm)."));

// Check if chamfer is too wide for the base radius
max_radial_chamfer = is_oval ? (oval_width / 2) : (base_size / 2);
assert(bottom_chamfer_mm < max_radial_chamfer,
    str("\nERROR: Bottom chamfer is too wide for the base size!\n",
        "FIX: Reduce 'bottom_chamfer_mm' to less than ", floor(max_radial_chamfer * 10) / 10, "mm."));

// Shell thickness validation
max_shell_for_base = base_height - (has_magnet ? total_pocket_height : 0);
assert(!enable_shelling || shell_wall_thickness_mm < base_boundary_radius,
    str("\nERROR: Shell wall too thick for this base!\n",
        "FIX: Reduce 'shell_wall_thickness_mm' to less than ", floor(base_boundary_radius * 10) / 10, "mm."));
assert(!enable_shelling || shell_wall_thickness_mm >= SHELL_MIN,
    str("\nERROR: Shell wall too thin!\n",
        "FIX: Increase 'shell_wall_thickness_mm' to ", SHELL_MIN, "mm or more (current: ", shell_wall_thickness_mm, "mm)."));
assert(!enable_shelling || shell_top_thickness_mm >= SHELL_MIN,
    str("\nERROR: Shell top too thin!\n",
        "FIX: Increase 'shell_top_thickness_mm' to ", SHELL_MIN, "mm or more (current: ", shell_top_thickness_mm, "mm)."));
// Shell thickness remains within base (guaranteed by auto-correction)
assert(!enable_shelling || shell_top_thickness_mm <= max_shell_for_base + OVERLAP, "Internal Error: Shell thickness check failed.");
// Magnet limits
assert(!has_magnet || magnet_dim_a > 0,
    "\nERROR: Magnet size must be positive!\nFIX: Increase 'magnet_dim_a_mm'.");
assert(!has_magnet || magnet_shape != "Rectangular" || magnet_dim_b > 0,
    "\nERROR: Rectangular magnet width must be positive!\nFIX: Increase 'magnet_dim_b_mm'.");
assert(!has_magnet || magnet_thick > 0,
    "\nERROR: Magnet thickness must be positive!\nFIX: Increase 'magnet_thick_mm'.");

// === MULTI-MAGNET GEOMETRY ===

// Base boundary: use inscribed circle for polygon (flat-to-flat radius = base_size/2)
// For round base, it's also base_size/2
// For oval base, use the minor axis (width/2) as it's the limiting dimension
base_boundary_radius = is_oval ? oval_width / 2 : base_size / 2;

// Auto-Placement Logic
actual_pair_distance = (auto_magnet_placement) ? 
    (is_oval ? oval_length / 2 : base_boundary_radius) : 
    magnet_pair_distance_mm;

actual_ring_radius = auto_magnet_placement ? base_boundary_radius / 2 : magnet_ring_radius_mm;

// Oval Ring Semi-Axes (Parametric Ellipse)
// Follows the same "half-radius" logic: A = L/4, B = W/4
oval_ring_a = auto_magnet_placement ? oval_length / 4 : magnet_ring_radius_mm * (oval_length / oval_width);
oval_ring_b = auto_magnet_placement ? oval_width / 4 : magnet_ring_radius_mm;

// Effective magnet count (1 if pockets are disabled)
effective_count = has_magnet ? magnet_count : 1;


// Calculate the effective magnet radius (for boundary checks)
magnet_effective_radius = get_magnet_effective_radius(magnet_dim_a, magnet_dim_b, magnet_shape, total_magnet_clearance);

// For 2-magnet mode, each magnet is offset by pair_distance/2 from center
// For 3+ mode, ring magnets are at actual_ring_radius
max_magnet_offset = 
    (effective_count == 1) ? 0 :
    (effective_count == 2) ? actual_pair_distance / 2 :
    actual_ring_radius;

// The outermost point of any magnet from center
max_magnet_extent = max_magnet_offset + magnet_effective_radius;

// Boundary logic moved up for auto-placement calculations

// === OUTER WALL VALIDATION ===
assert(min_outer_wall_mm >= HARD_MIN_OUTER_WALL,
    str("\nERROR: Outer wall dangerously thin!\n",
        "FIX: Increase 'min_outer_wall_mm' to ", HARD_MIN_OUTER_WALL, "mm or more (current: ", min_outer_wall_mm, "mm)."));

// Effective boundary for magnets = base radius - required wall thickness
effective_boundary = base_boundary_radius - min_outer_wall_mm;

// Calculate max allowed ring radius or pair distance (accounting for wall)
max_pair_distance = (effective_boundary - magnet_effective_radius) * 2;
max_ring_radius = effective_boundary - magnet_effective_radius;

// Boundary validation (magnets must stay within effective boundary)
if (is_oval) {
    // Check both major and minor axes for ovals
    effective_boundary_l = (oval_length / 2) - min_outer_wall_mm;
    effective_boundary_w = (oval_width / 2) - min_outer_wall_mm;
    
    max_extent_l = (effective_count == 2) ? (actual_pair_distance / 2 + magnet_effective_radius) : 
                   (effective_count > 2) ? (oval_ring_a + magnet_effective_radius) : magnet_effective_radius;
    max_extent_w = (effective_count > 2) ? (oval_ring_b + magnet_effective_radius) : magnet_effective_radius;
    
    assert(!has_magnet || (max_extent_l <= effective_boundary_l && max_extent_w <= effective_boundary_w),
        str("\nERROR: Magnet(s) extend beyond the oval boundary!\n",
            "FIX: Increase base dimensions or use fewer/smaller magnets."));
} else {
    assert(!has_magnet || max_magnet_extent <= effective_boundary,
        str("\nERROR: Magnet(s) extend beyond the base edge!\n",
            "FIX: ", (effective_count == 2) ? 
                str("Reduce 'magnet_pair_distance_mm' to ", floor(max_pair_distance * 10) / 10, "mm or less.") :
                str("Reduce 'magnet_ring_radius_mm' to ", floor(max_ring_radius * 10) / 10, "mm or less, OR use smaller magnets.")));
}

// === MINIMUM WALL BETWEEN MAGNETS ===

// Calculate minimum gap between any two magnets
ring_count = (effective_count > 2) ? effective_count - 1 : 0;
chord_distance = (ring_count > 0) ? 2 * actual_ring_radius * sin(180 / ring_count) : 0;

min_gap = 
    (effective_count == 1) ? 999 : // No gap check needed for single magnet
    (effective_count == 2) ? actual_pair_distance - 2 * magnet_effective_radius :
    min(
        actual_ring_radius - 2 * magnet_effective_radius, // center to ring
        chord_distance - 2 * magnet_effective_radius         // ring to ring
    );

// Calculate minimum required spacing
min_pair_distance = 2 * magnet_effective_radius + MIN_WALL_BETWEEN;
min_ring_radius_for_center = 2 * magnet_effective_radius + MIN_WALL_BETWEEN;
// For ring-to-ring: chord >= 2*radius + wall => 2*R*sin(180/n) >= 2r+w => R >= (2r+w)/(2*sin(180/n))
min_ring_radius_for_ring = (ring_count > 0) ? (2 * magnet_effective_radius + MIN_WALL_BETWEEN) / (2 * sin(180 / ring_count)) : 0;
min_ring_radius = max(min_ring_radius_for_center, min_ring_radius_for_ring);

assert(!has_magnet || effective_count == 1 || min_gap >= MIN_WALL_BETWEEN,
    str("\nERROR: Magnets overlap or are too close together!\n",
        "FIX: ", (effective_count == 2) ? 
            str("Increase 'magnet_pair_distance_mm' to ", ceil(min_pair_distance * 10) / 10, "mm or more.") :
            str("Increase 'magnet_ring_radius_mm' to ", ceil(min_ring_radius * 10) / 10, "mm or more.")));


// === RENDER MODEL ===

// ==========================================
//    MODEL ASSEMBLY & GLOBAL ORIENTATION
// ==========================================

// Module to assemble the full model (base + magnet preview)
module full_model_assembly() {
    base_body();
}

// Apply rotation and potential flip for shelling
rotate([0, 0, 45]) {
    if (enable_shelling) {
        // Flip upside down for printing optimization
        // Rotate 180 around X, then translate up by height to put top on Z=0
        translate([0, 0, base_height])
        rotate([180, 0, 0])
        full_model_assembly();
    } else {
        full_model_assembly();
    }
}


// ==========================================
//          MAIN GEOMETRY MODULES
// ==========================================

module base_body() {
    // Chamfer logic: 
    // We construct the body in two pieces: 
    // 1. The chamfer zone (from bottom to bottom_chamfer_mm)
    // 2. The main flared body (from bottom_chamfer_mm to base_height)
    
    // Calculate intermediate dimensions at the chamfer-edge height
    // Note: Chamfer is usually 45 degrees, so radial reduction = height
    chamfer_h = bottom_chamfer_mm;
    
    difference() {
        union() {
            if (is_oval) {
                // Layer 1: Chamfer (bottom to flare start)
                oval_tapered_layer(h = chamfer_h, 
                                   l1 = oval_length - 2*bottom_chamfer_mm, w1 = oval_width - 2*bottom_chamfer_mm,
                                   l2 = oval_length, w2 = oval_width);
                
                // Layer 2: Main Body (flare start to top)
                translate([0, 0, chamfer_h])
                oval_tapered_layer(h = base_height - chamfer_h,
                                   l1 = oval_length, w1 = oval_width,
                                   l2 = oval_length - 2*oval_flare_reduction, w2 = oval_width - 2*oval_flare_reduction);
            } else if (is_polygon && polygon_corner_radius_mm > 0) {
                // Layer 1: Chamfer
                rounded_tapered_polygon_layer(h = chamfer_h, 
                                              r1 = r_bottom - bottom_chamfer_mm, r2 = r_bottom, 
                                              corner_r = polygon_corner_radius_mm);
                
                // Layer 2: Main Body
                translate([0, 0, chamfer_h])
                rounded_tapered_polygon_layer(h = base_height - chamfer_h, 
                                              r1 = r_bottom, r2 = r_top, 
                                              corner_r = polygon_corner_radius_mm);
            } else {
                // Standard cylinder / Polygon
                // Layer 1: Chamfer
                cylinder(r1 = r_bottom - bottom_chamfer_mm, r2 = r_bottom, h = chamfer_h, $fn = sides_fn);
                
                // Layer 2: Main Body
                translate([0, 0, chamfer_h])
                cylinder(r1 = r_bottom, r2 = r_top, h = base_height - chamfer_h, $fn = sides_fn);
            }
        }
        
        // Magnet Pockets
        if (has_magnet) {
            translate([0, 0, actual_pillar_recess - OVERLAP]) // Overlap for clean cut
            union() all_magnet_pockets();
        }
        
        // Shelling cavity (hollow out the interior)
        if (enable_shelling) {
            shell_cavity();
        }
    }
}

// Shell cavity module - creates the hollow interior while preserving magnet pocket walls
module shell_cavity() {
    wall_inset = shell_wall_thickness_mm / cos(flare_angle);
    keepout_radius = magnet_effective_radius + shell_wall_thickness_mm;
    
    // The "base" cavity ceiling (reinforced/filler zone)
    main_cavity_height = base_height - shell_top_thickness_mm - actual_reinforcement;
    
    difference() {
        union() {
            // 1. Primary cavity shape (shorter if reinforcement is active)
            if (is_oval) {
                // Oval cavity
                interior_length = oval_length - 2 * wall_inset;
                interior_width = oval_width - 2 * wall_inset;
                flare_reduction = base_height * tan(flare_angle);
                // Adjust top dimensions for the lower reinforcement ceiling
                top_interior_length = max(0.1, interior_length - 2 * flare_reduction * (main_cavity_height/base_height));
                top_interior_width = max(0.1, interior_width - 2 * flare_reduction * (main_cavity_height/base_height));
                
                translate([0, 0, -OVERLAP])
                hull() {
                    scale([interior_length/2, interior_width/2, 1]) cylinder(r = 1, h = 0.01, $fn = $fn);
                    translate([0, 0, main_cavity_height])
                    scale([top_interior_length/2, top_interior_width/2, 1]) cylinder(r = 1, h = 0.01, $fn = $fn);
                }
            } else {
                // Round/Polygon cavity
                interior_r_bottom = r_bottom - wall_inset;
                // Calculate r_top at the reinforcement ceiling height
                interior_r_top = r_bottom - wall_inset - (main_cavity_height * tan(flare_angle) / angle_correction);
                
                translate([0, 0, -OVERLAP])
                cylinder(r1 = interior_r_bottom, r2 = interior_r_top, 
                         h = main_cavity_height + OVERLAP, 
                         $fn = sides_fn);
            }
            
            // 2. Clearances for magnets (Pillar areas stay at full shell height)
            if (has_magnet && actual_reinforcement > 0) {
                place_at_magnet_positions() {
                    translate([0, 0, main_cavity_height - OVERLAP])
                    cylinder(r = keepout_radius, h = actual_reinforcement + OVERLAP * 2, $fn = $fn);
                }
            }
        }
        
        // 3. Subtract keepout zones around magnet pockets (these stayed solid inside the cavity)
        if (has_magnet) {
            union() magnet_pocket_keepouts();
        }
    }
}


// ==========================================
//          MAGNET SYSTEM MODULES
// ==========================================

// Creates solid keepout zones around each magnet pocket position
// These zones prevent the shell cavity from cutting into the pocket walls
module magnet_pocket_keepouts() {
    // Keepout size = magnet effective radius + wall thickness
    keepout_radius = magnet_effective_radius + shell_wall_thickness_mm;
    
    // We need to know if we are at a center position or ring position
    // and if we are the only pocket or one of many.
    
    // Logic: 
    // 1. Single magnet (center) -> standard X pattern (4 ribs)
    // 2. Multiple magnets (center + ring) -> Center gets NO ribs, ring pockets get ribs_per_pocket
    // 3. Ring magnets -> First rib points to center, others equally spaced.
    
    union() {
        if (has_magnet) {
            if (effective_count == 1) {
                // Case 1: Single pocket - standard 4-way support
                translate([0, 0, actual_pillar_recess - OVERLAP])
                cylinder(r = keepout_radius, h = base_height - shell_top_thickness_mm - actual_pillar_recess + OVERLAP * 2, $fn = $fn);
                
                if (enable_ribs) {
                    render_pocket_ribs(keepout_radius, ribs_per_pocket, true); // True = centered X pattern
                }
            } else {
                // Case 2 & 3: Multi-magnet
                // Loop through positions manually to handle center vs outer logic
                
                // Outer Pockets (Case 3)
                if (effective_count == 2) {
                    for (i = [0, 180]) {
                        rotate([0, 0, i])
                        translate([actual_pair_distance / 2, 0, 0]) {
                            translate([0, 0, actual_pillar_recess - OVERLAP])
                            cylinder(r = keepout_radius, h = base_height - shell_top_thickness_mm - actual_pillar_recess + OVERLAP * 2, $fn = $fn);
                            
                            if (enable_ribs) render_pocket_ribs(keepout_radius, ribs_per_pocket, false);
                        }
                    }
                } else {
                    // Center Pocket (Case 2: NO RIBS)
                    translate([0, 0, actual_pillar_recess - OVERLAP])
                    cylinder(r = keepout_radius, h = base_height - shell_top_thickness_mm - actual_pillar_recess + OVERLAP * 2, $fn = $fn);
                    // No render_pocket_ribs() called for center!
                    
                    // Ring Pockets (Case 3)
                    ring_count = effective_count - 1;
                    for (i = [1 : ring_count]) {
                        angle = i * 360 / ring_count;
                        
                        // Placement logic duplication from place_at_magnet_positions
                        // (Parametric ellipse if oval + 4+ ring magnets)
                        offset = (is_oval && ring_count >= 4) ? 
                                 [oval_ring_a * cos(angle), oval_ring_b * sin(angle), 0] :
                                 [actual_ring_radius * cos(angle), actual_ring_radius * sin(angle), 0];
                                 
                        translate(offset) {
                            translate([0, 0, actual_pillar_recess - OVERLAP])
                            cylinder(r = keepout_radius, h = base_height - shell_top_thickness_mm - actual_pillar_recess + OVERLAP * 2, $fn = $fn);
                            
                            if (enable_ribs) {
                                // Rotate ribs to face origin
                                rib_rotation = (is_oval && ring_count >= 4) ? atan2(offset[1], offset[0]) * 180 / PI : angle;
                                render_pocket_ribs(keepout_radius, ribs_per_pocket, false, rib_rotation);
                            }
                        }
                    }
                }
            }
        }
    }
}

// Helper to render ribs for a single pocket
// center_mode: if true, uses 45-deg offsets (standard X). If false, first rib points to origin.
module render_pocket_ribs(keepout_radius, count, center_mode, base_rotation = 0) {
    max_dim = is_oval ? max(oval_length, oval_width) : base_size;
    eff_rib_cube_len = (rib_length_mm > 0) ? (keepout_radius + rib_length_mm) * 2 : max_dim * 2;
    eff_rib_h = auto_rib_height ? (pocket_depth * 0.75) : rib_height_mm;
    start_z = base_height - shell_top_thickness_mm;
    
    // Angle spacing
    angle_step = 360 / count;
    // Initial offset: 180 points to center in the local frame of ring magnets
    // center_mode uses 45 for the X look.
    start_angle = center_mode ? 45 : 180 + base_rotation;
    
    for (i = [0 : count - 1]) {
        rotate([0, 0, start_angle + i * angle_step])
        translate([eff_rib_cube_len/2 - keepout_radius, 0, start_z - eff_rib_h / 2])
        cube([eff_rib_cube_len, rib_thickness_mm, eff_rib_h], center=true);
    }
}

// Helper to place magnet pockets at all positions
module all_magnet_pockets() {
    place_at_magnet_positions() {
        magnet_pocket();
    }
}

module magnet_pocket() {
    side_a = magnet_dim_a + total_magnet_clearance;
    side_b = magnet_dim_b + total_magnet_clearance;
    depth = pocket_depth; 
    
    union() {
        if (magnet_shape == "Round") {
            pocket_radius = side_a / 2;
            
            // Main pocket
            cylinder(d = side_a, h = depth, $fn = $fn);
            // Entry chamfer (cone at bottom)
            translate([0, 0, -OVERLAP])
            cylinder(d1 = side_a + POCKET_CHAMFER * 2, d2 = side_a, h = POCKET_CHAMFER + OVERLAP, $fn = $fn);
            
            // Glue channels (helical half-circles along pocket edge)
            if (glue_channels_enabled) {
                channel_r = glue_channel_diameter_mm / 2;
                for (i = [0 : glue_channel_count - 1]) {
                    start_angle = i * 360 / glue_channel_count;
                    rotate([0, 0, start_angle])
                    glue_channel_helix(depth, glue_channel_rotation_deg, channel_r, pocket_radius);
                }
            }
            
        } else if (magnet_shape == "Square" || magnet_shape == "Rectangular") {
            // Square is just a rectangle with equal sides
            dim_x = side_a;
            dim_y = (magnet_shape == "Square") ? side_a : side_b;
            
            // Main pocket
            translate([-dim_x/2, -dim_y/2, 0])
            cube([dim_x, dim_y, depth]);
            
            // Entry chamfer
            hull() {
                translate([0, 0, -OVERLAP])
                translate([-(dim_x + POCKET_CHAMFER * 2)/2, -(dim_y + POCKET_CHAMFER * 2)/2, 0])
                cube([dim_x + POCKET_CHAMFER * 2, dim_y + POCKET_CHAMFER * 2, 0.01]);
                
                translate([0, 0, POCKET_CHAMFER])
                translate([-dim_x/2, -dim_y/2, 0])
                cube([dim_x, dim_y, 0.01]);
            }
            
            // Glue channels (center of each face)
            if (glue_channels_enabled) {
                channel_r = glue_channel_diameter_mm / 2;
                slant = actual_glue_slant;
                
                // X-faces
                translate([dim_x/2, 0, 0])  glue_channel_linear(depth, channel_r, slant);
                rotate([0, 0, 180]) translate([dim_x/2, 0, 0]) glue_channel_linear(depth, channel_r, slant);
                
                // Y-faces
                rotate([0, 0, 90])  translate([dim_y/2, 0, 0]) glue_channel_linear(depth, channel_r, slant);
                rotate([0, 0, 270]) translate([dim_y/2, 0, 0]) glue_channel_linear(depth, channel_r, slant);
            }
        }
    }
}


// ==========================================
//          GEOMETRY HELPERS
// ==========================================

// Helper module - places children() at all magnet positions
// Placement logic:
// 1 magnet: center
// 2 magnets: offset along X axis by pair_distance/2
// 3+ magnets: 1 center + (N-1) on a ring
module place_at_magnet_positions() {
    if (effective_count == 1) {
        children();
    } else if (effective_count == 2) {
        for (i = [0, 180]) {
            rotate([0, 0, i])
            translate([actual_pair_distance / 2, 0, 0])
            children();
        }
    } else {
        // Center magnet
        children();
        // Ring magnets
        ring_count = effective_count - 1;
        for (i = [1 : ring_count]) {
            angle = i * 360 / ring_count;
            if (is_oval && ring_count >= 4) {
                // Parametric ellipse distribution
                // x = a*cos(t), y=b*sin(t)
                x = oval_ring_a * cos(angle);
                y = oval_ring_b * sin(angle);
                translate([x, y, 0])
                rotate([0, 0, atan2(y, x) * 180 / PI]) // Face center
                children();
            } else {
                // Standard circular distribution
                rotate([0, 0, angle])
                translate([actual_ring_radius, 0, 0])
                children();
            }
        }
    }
}

// Oval tapered layer helper
module oval_tapered_layer(h, l1, w1, l2, w2) {
    if (h > 0) {
        hull() {
            // Bottom ellipse
            scale([l1/2, w1/2, 1]) cylinder(r = 1, h = 0.01, $fn = $fn);
            
            // Top ellipse
            translate([0, 0, h - 0.01])
            scale([l2/2, w2/2, 1]) cylinder(r = 1, h = 0.01, $fn = $fn);
        }
    }
}

// Rounded polygon layer helper
// Rounded polygon layer helper
module rounded_tapered_polygon_layer(h, r1, r2, corner_r) {
    if (h > 0) {
        // Hull two thin 2D slices instead of N 3D cylinders
        // This reduces the complexity of the 3D hull operation significantly
        hull() {
            translate([0,0,-OVERLAP]) linear_extrude(0.01+OVERLAP) rounded_polygon_2d(r1, corner_r);
            translate([0,0,h-0.01]) linear_extrude(0.01+OVERLAP) rounded_polygon_2d(r2, corner_r);
        }
    }
}

// 2D helper: Creates the rounded polygon profile
module rounded_polygon_2d(r, corner_r) {
    // r is the circumradius of the ideal sharp polygon
    // The centers of the corner circles must be placed such that the outer edge is at r
    // For a circle at distance d with radius c, the outer extent is d+c.
    // So we position at r - corner_r.
    r_adj = r - corner_r;
    
    hull() {
        for (i = [0 : poly_sides - 1]) {
            rotate([0, 0, i * 360 / poly_sides])
            translate([r_adj, 0, 0])
            circle(r = corner_r);
        }
    }
}

// Helical glue channel helper - creates a spiral groove that orbits around the pocket center
// Optimized using native linear_extrude with twist for significantly faster rendering.
module glue_channel_helix(height, rotation_deg, channel_radius, pocket_radius) {
    // Resolution capping for small features (faster rendering)
    channel_fn = 12;
    
    // Create the helix by extruding a circle with twist
    // We translate the circle to the pocket radius first
    translate([0, 0, -OVERLAP])
    linear_extrude(height = height + OVERLAP * 2, twist = rotation_deg, slices = max(10, abs(rotation_deg)/10), convexity = 4)
    translate([pocket_radius, 0, 0])
    circle(r = channel_radius, $fn = channel_fn);
}


// Slanted glue channel helper - creates a vertical groove that can tilt
// channel_radius: cross-section radius of the channel
// slant_angle: tilt angle in degrees (diagonal across the face)
module glue_channel_linear(height, channel_radius, slant_angle=0) {
    // Simple vertical cylinder that can be tilted
    // It's tilted around the normal axis of the face it's placed on
    translate([0, 0, -OVERLAP])
    rotate([slant_angle, 0, 0])
    cylinder(r = channel_radius, h = (height + OVERLAP * 2) / cos(abs(slant_angle)), $fn = 12);
}


