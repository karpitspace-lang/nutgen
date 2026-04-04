/* [Nut Selection] */
// Select the standard DIN934 size
M_Size = 6; // [3, 4, 5, 6, 8, 10, 12]

/* [Tolerances] */
// Added to both Major and Minor diameters
Diameter_Offset = 0.2; 

/* [Rendering Quality] */
// Smoothness of circular parts
$fn = 64; 

// --- DIN 934 Standard Data Lookup ---
// Format: [M_size, Pitch, S_Flats, M_Height, D_Minor, Da_Chamfer]
function din_data(m) = 
    (m == 3)  ? [3,  0.5,  5.5,  2.4,  2.459,  3.45] :
    (m == 4)  ? [4,  0.7,  7.0,  3.2,  3.242,  4.60] :
    (m == 5)  ? [5,  0.8,  8.0,  4.0,  4.134,  5.75] :
    (m == 6)  ? [6,  1.0,  10.0, 5.0,  4.917,  6.90] :
    (m == 8)  ? [8,  1.25, 13.0, 6.5,  6.647,  9.20] :
    (m == 10) ? [10, 1.5,  17.0, 8.0,  8.376,  11.50] :
    (m == 12) ? [12, 1.75, 19.0, 10.0, 10.106, 14.00] : 
    [3, 0.5, 5.5, 2.4, 2.459, 3.45]; // Default M3

// --- Apply Parameters ---
row        = din_data(M_Size);
pitch      = row[1];
s_flats    = row[2];
m_height   = row[3];
d_major    = row[0] + Diameter_Offset; 
d_inner    = row[4] + Diameter_Offset; 
da_chamfer = row[5]; 

hex_points_dia = s_flats / cos(30);
chamfer_h = (da_chamfer - d_inner) / 2; 

// --- Main Construction ---
difference() {
    // 1. THE CHAMFERED HEX BODY
    intersection() {
        cylinder(h = m_height, d = hex_points_dia, $fn = 6, center = true);
        union() {
            // Chamfering logic for the outer edges
            cylinder(h = m_height/2, d1 = hex_points_dia + 1, d2 = s_flats, center = false);
            mirror([0, 0, 1])
                cylinder(h = m_height/2, d1 = hex_points_dia + 1, d2 = s_flats, center = false);
        }
    }

    // 2. THE THREADED HOLE
    union() {
        // Main core hole
        cylinder(h = m_height + 0.5, d = d_inner, center = true);
        
        // Entry Chamfers (45 deg)
        translate([0, 0, m_height/2 - chamfer_h + 0.01])
            cylinder(h = chamfer_h, d1 = d_inner, d2 = da_chamfer);
            
        translate([0, 0, -m_height/2 - 0.01])
            cylinder(h = chamfer_h, d1 = da_chamfer, d2 = d_inner);

        // The Thread Cutter
        translate([0, 0, -m_height/2])
        intersection() {
            cylinder(h = m_height, d = d_major);
            thread_tool(d_major, pitch, m_height, d_inner);
        }
    }
}

// --- Threading Modules ---
module thread_tool(dia, p, l, d_in) {
    steps = 32; 
    total_steps = (l / p) * steps;
    // We add a few extra steps to ensure the thread clears the ends
    for (i = [-steps : total_steps + steps]) {
        hull() {
            thread_pt(i, steps, p, d_in, dia);
            thread_pt(i + 1, steps, p, d_in, dia);
        }
    }
}

module thread_pt(i, steps, p, d_in, d_maj) {
    rotate([0, 0, i * (360/steps)])
    translate([d_in/2 - 0.1, 0, i * (p/steps)])
    rotate([90, 0, 0])
    // Triangle cutter profile
    cylinder(h = (d_maj - d_in) + 0.5, d1 = p * 1.1, d2 = 0, $fn = 3);
}
