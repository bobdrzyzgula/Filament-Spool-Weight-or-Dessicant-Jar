// Spool Weight Jar  v1.0.0
// A screw-top jar that sits in a filament spool's center hole and holds
// steel BBs, so a nearly empty spool stays seated in the AMS instead of
// riding up as filament is pulled. Built to survive a ~4 ft drop onto
// concrete when printed in PETG with solid walls (see notes at the end).
// Optional perforated body for use as a desiccant holder.
//
// Written by Claude (Anthropic) at the direction of Bob Drzyzgula.
// Self-contained: no libraries required. License: MIT.
//
// Thread: a rounded (sinusoidal) single-start right-hand thread, made by
// twist-extruding an off-center circle. It has no sharp roots to start
// cracks, prints without supports in both parts, and the lid seats firmly
// on the jar's shoulder, so impact loads go through the full wall rather
// than through the thread.

/* [Part] */
// What to render. "print" lays out both parts in print orientation.
part = "print"; // [print, jar, lid, assembled, cutaway]

/* [Overall size] */
// Outside diameter of jar and lid (they are flush; must fit the spool hole)
outer_d = 50; // [30:0.5:80]
// Assembled height, jar bottom to lid top
height = 75; // [40:0.5:150]

/* [Wall thicknesses] */
// Jar side wall
wall = 3.2; // [1.6:0.1:6]
// Jar floor
floor_t = 3.2; // [1.6:0.1:6]
// Lid top plate
lid_top_t = 3.2; // [1.6:0.1:6]
// Lid skirt, measured outside the deepest point of its thread
lid_wall = 3.2; // [1.6:0.1:6]
// Jar neck, measured inside the root of its thread
neck_wall = 2.4; // [1.6:0.1:5]

/* [Thread] */
thread_pitch = 5; // [3:0.5:8]
// Full radial depth of the thread (peak to root)
thread_depth = 1.5; // [0.8:0.1:2.5]
// Length of neck / depth of lid skirt
thread_length = 12; // [6:0.5:25]
// Radial clearance between jar and lid threads
thread_clearance = 0.35; // [0.1:0.05:0.8]
// Space between the neck rim and the inside of the lid top
top_gap = 0.5; // [0.2:0.1:2]

/* [Edges] */
// Chamfer on the jar bottom edge and lid top edge
edge_chamfer = 1.5; // [0:0.25:3]
// Small chamfer where lid meets jar, so the joint can't catch
joint_chamfer = 0.6; // [0:0.1:1.5]
// Inside floor/wall fillet (45-degree chamfer) to spread impact stress
inner_fillet = 2; // [0:0.25:4]

/* [Lid grip] */
// Number of vertical grip grooves around the lid (0 for none)
grip_grooves = 30; // [0:1:60]
grip_depth = 0.6; // [0:0.1:1.2]

/* [Perforations (desiccant)] */
perforated = false;
// Diamond hole width (point to point). Keep smaller than your beads.
hole_size = 2.0; // [1:0.1:4]
// Holes per row around the jar
holes_around = 24; // [8:1:48]
// Vertical spacing between rows (alternate rows are staggered)
hole_row_pitch = 4; // [2:0.5:10]
// Solid band kept above the floor fillet and below the shoulder
hole_margin = 3; // [1:0.5:10]

/* [Fill estimate] */
// Steel BB diameter (standard .177 / 4.5 mm)
bb_d = 4.5; // [3:0.05:8]
// Mass of one BB in grams
bb_g = 0.35; // [0.1:0.01:2]
// Random packing fraction for loose spheres
packing = 0.62; // [0.5:0.01:0.7]

/* [Rendering] */
$fn = 120; // [48:12:240]
// Twist-extrude slices per thread turn
slices_per_turn = 48; // [16:4:120]

/* [Hidden] */
eps = 0.01;
R = outer_d / 2;
e = thread_depth / 2;                       // eccentricity of thread circle

// Thread radii (radius of the off-center generating circle)
Rc_int = R - lid_wall - e;                  // lid: deepest groove at R - lid_wall
Rc_ext = Rc_int - thread_clearance;         // jar
r_ext_min = Rc_ext - e;                     // root of jar thread
r_ext_max = Rc_ext + e;                     // crest of jar thread
r_int_min = Rc_int - e;                     // crest of lid thread
r_neck = r_ext_min - neck_wall;             // neck bore (mouth) radius
r_body = R - wall;                          // body bore radius

lid_h = lid_top_t + thread_length + top_gap;
shoulder_z = height - lid_h;                // where the lid skirt seats
neck_top = shoulder_z + thread_length;
cone_h = r_body - r_neck;                   // 45-degree interior shoulder
body_bore_top = shoulder_z - cone_h;

assert(r_neck > 5, "Neck bore too small: reduce wall/thread values or increase outer_d");
assert(body_bore_top > floor_t + inner_fillet + 1, "Jar too short for these settings");
assert(r_ext_max < r_int_min + thread_depth, "Thread geometry inconsistent");

// ---------- Capacity estimate ----------
vol_body = PI * r_body * r_body * (body_bore_top - floor_t)
         - PI * r_body * inner_fillet * inner_fillet;          // approx fillet loss
vol_cone = PI * cone_h / 3 * (r_body*r_body + r_body*r_neck + r_neck*r_neck);
vol_neck = PI * r_neck * r_neck * (neck_top - shoulder_z);
vol_mm3 = vol_body + vol_cone + vol_neck;
bb_vol = PI / 6 * pow(bb_d, 3);
bb_count = floor(vol_mm3 * packing / bb_vol);
echo(str("Mouth (neck bore) diameter: ", 2*r_neck, " mm"));
echo(str("Interior volume to neck rim: ", round(vol_mm3/100)/10, " cm^3"));
echo(str("Full of ", bb_d, " mm BBs: about ", bb_count, " BBs, ",
         round(bb_count*bb_g), " g"));
if (perforated && hole_size >= bb_d)
    echo("WARNING: hole_size is not smaller than bb_d; BBs may fall out.");
if (perforated)
    echo(str("Perforations: ", holes_around, " per row, ", n_rows(), " rows, ",
             holes_around * n_rows(), " holes"));

// ---------- Helpers ----------

// Solid helical thread body in assembled coordinates (z = height above jar bottom).
// Generating circle of radius rc, offset e, phase locked to absolute z so jar and
// lid threads always correspond.
module helix(rc, z0, h) {
    translate([0, 0, z0])
        linear_extrude(height = h, twist = -360 * h / thread_pitch,
                       slices = max(8, ceil(h / thread_pitch * slices_per_turn)),
                       convexity = 4)
            rotate(360 * z0 / thread_pitch)
                translate([e, 0]) circle(r = rc);
}

function n_rows() =
    let(z_lo = floor_t + inner_fillet + hole_margin + hole_size/2,
        z_hi = body_bore_top - hole_margin - hole_size/2)
    z_hi > z_lo ? floor((z_hi - z_lo) / hole_row_pitch) + 1 : 0;

module perforations() {
    z_lo = floor_t + inner_fillet + hole_margin + hole_size/2;
    s = hole_size / sqrt(2);                // square side for a diamond of width hole_size
    for (i = [0 : n_rows() - 1])
        for (j = [0 : holes_around - 1])
            rotate(360 / holes_around * (j + (i % 2) / 2))
                translate([R - wall/2, 0, z_lo + i * hole_row_pitch])
                    rotate([0, 90, 0]) rotate(45)
                        cube([s, s, wall + 2], center = true);
}

// ---------- Jar ----------
module jar() {
    difference() {
        union() {
            // Body with chamfered bottom edge and small chamfer at the joint
            rotate_extrude()
                polygon([
                    [0, 0],
                    [R - edge_chamfer, 0],
                    [R, edge_chamfer],
                    [R, shoulder_z - joint_chamfer],
                    [R - joint_chamfer, shoulder_z],
                    [0, shoulder_z]
                ]);
            // Threaded neck, with a 45-degree lead-in at the top
            intersection() {
                helix(Rc_ext, shoulder_z - eps, thread_length + eps);
                rotate_extrude()
                    polygon([
                        [0, shoulder_z - 1],
                        [R, shoulder_z - 1],
                        [R, neck_top - (R - r_ext_min) - 0.3],
                        [r_ext_min - 0.3, neck_top],
                        [0, neck_top]
                    ]);
            }
        }
        // Interior: floor fillet, body bore, 45-degree shoulder, neck bore
        rotate_extrude()
            polygon([
                [0, floor_t],
                [r_body - inner_fillet, floor_t],
                [r_body, floor_t + inner_fillet],
                [r_body, body_bore_top],
                [r_neck, shoulder_z],
                [r_neck, neck_top + 1],
                [0, neck_top + 1]
            ]);
        // Small chamfer on the inside of the rim
        translate([0, 0, neck_top - 0.6])
            cylinder(h = 0.6 + eps, r1 = r_neck, r2 = r_neck + 0.6 + eps);
        if (perforated) perforations();
    }
}

// ---------- Lid (modeled in assembled position) ----------
module lid() {
    z_bot = shoulder_z;
    z_ceil = height - lid_top_t;
    difference() {
        rotate_extrude()
            polygon([
                [0, z_bot],
                [R - joint_chamfer, z_bot],
                [R, z_bot + joint_chamfer],
                [R, height - edge_chamfer],
                [R - edge_chamfer, height],
                [0, height]
            ]);
        // Internal thread
        helix(Rc_int, z_bot - 1, z_ceil - z_bot + 1);
        // Clear the space above the thread up to the lid ceiling
        translate([0, 0, z_ceil - top_gap - eps])
            cylinder(h = top_gap + eps, r = r_int_min);
        // 45-degree lead-in chamfer at the skirt mouth
        translate([0, 0, z_bot - eps])
            cylinder(h = (R - lid_wall) - r_int_min + 0.3 + eps,
                     r1 = R - lid_wall + 0.3, r2 = r_int_min - eps);
        // Grip grooves
        if (grip_grooves > 0 && grip_depth > 0) {
            gr = 1.2;
            for (k = [0 : grip_grooves - 1])
                rotate(360 / grip_grooves * k)
                    translate([R + gr - grip_depth, 0, z_bot + joint_chamfer + 1])
                        cylinder(h = lid_h - joint_chamfer - edge_chamfer - 2, r = gr, $fn = 24);
        }
    }
}

// Lid flipped for printing, top plate on the bed
module lid_print() {
    translate([0, 0, height]) rotate([180, 0, 0]) lid();
}

// ---------- Output ----------
if (part == "jar") jar();
else if (part == "lid") lid_print();
else if (part == "print") {
    jar();
    translate([outer_d + 8, 0, 0]) lid_print();
}
else if (part == "assembled") {
    color("SteelBlue") jar();
    color("Orange") lid();
}
else if (part == "cutaway") {
    difference() {
        union() { color("SteelBlue") jar(); color("Orange") lid(); }
        translate([0, -outer_d, -1]) cube([outer_d, 2*outer_d, height + 2]);
    }
}

// ---------- Print notes ----------
// Material: PETG (or PETG-CF). PLA is too brittle for a 4 ft drop with
//   ~half a kilogram of steel inside.
// Make the walls solid: in Bambu Studio set Wall loops high enough to fill
//   the wall (3.2 mm / 0.42 mm line ~ 8 loops) and 8+ top/bottom shell
//   layers, or just use 100% infill. Solid perimeters are what make it tough.
// Layer adhesion is the usual failure in a drop: print PETG on the warm end
//   of its range with modest part cooling. 0.16-0.2 mm layers suit the thread.
// Orientation: jar upright, lid upside down (top on the plate). No supports.
