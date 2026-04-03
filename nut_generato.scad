/* [ Main Configuration ] */

// Select the standard ISO/DIN size
Nut_Size = "M3"; // [M3, M4, M5, M6, M8, M10, M12]

// Extra clearance for 3D printing (0.1 to 0.2 is standard for FDM)
Tolerance = 0.15; 

/* [ Thread Geometry ] */

// 0 uses DIN standard pitch, >0 overrides for custom bolts
Manual_Pitch = 0; 

// Smoothness of the model (higher = better quality, slower render)
Resolution = 64; // [32, 64, 128]

/* [ Internal Calculations ] */

// DIN 934 Data Table: [Size, Pitch, Flats(s), Height(m), Chamfer_Dia(da)]
nut_data = [
    ["M3",  0.5,  5.5,  2.4, 3.45],
    ["M4",  0.7,  7.0,  3.2, 4.60],
    ["M5",  0.8,  8.0,  4.0, 5.75],
    ["M6",  1.0,  10.0, 5.0, 6.75],
    ["M8",  1.25, 13.0, 6.5, 9.20],
    ["M10", 1.5,  17.0, 8.0, 11.5],
    ["M12", 1.75, 19.0, 10.0, 14.0]
];

// Lookup logic
function get_data(size) = nut_data[search([size], nut_data)[0]];

p_std     = get_data(Nut_Size)[1];
pitch     = (Manual_Pitch > 0) ? Manual_Pitch : p_std;
s_flats   = get_data(Nut_Size)[2];
m_height  = get_data(Nut_Size)[3];
da_cham   = get_data(Nut_Size)[4];

// Derived Dimensions
d_major = pi_to_num(Nut_Size) + Tolerance; 
d_inner = d_major - (pitch * 1.0825); 
hex_points_dia = s_flats / cos(30);
chamfer_h = (da_cham - d_inner) / 2;

$fn = Resolution;

// Helper to convert "M3" string to number 3
function pi_to_num(s) = 
    (s=="M3")?3:(s=="M4")?4:(s=="M5")?5:(s=="M6")?6:(s=="M8")?8:(s=="M10")?10:12;

/* [ Rendering ] */

render_nut();

module render_nut() {
    difference() {
        // 1. OUTER HEX WITH DOUBLE CHAMFER
        intersection() {
            cylinder(h = m_height, d = hex_points_dia, $fn = 6, center = true);
            union() {
                cylinder(h = m_height/2, d1 = hex_points_dia + 1, d2 = s_flats, center = false);
                mirror([0, 0, 1])
                    cylinder(h = m_height/2, d1 = hex_points_dia + 1, d2 = s_flats, center = false);
            }
        }

        // 2. INTERNAL HOLE + THREADS + 45deg CHAMFERS
        union() {
            // Core hole
            cylinder(h = m_height + 0.2, d = d_inner, center = true);
            
            // Entry/Exit Chamfers
            translate([0, 0, m_height/2 - chamfer_h + 0.01])
                cylinder(h = chamfer_h, d1 = d_inner, d2 = da_cham);
            translate([0, 0, -m_height/2 - 0.01])
                cylinder(h = chamfer_h, d1 = da_cham, d2 = d_inner);

            // Thread cutting tool
            translate([0, 0, -m_height/2])
            intersection() {
                cylinder(h = m_height, d = d_major);
                thread_generator(d_major, pitch, m_height, d_inner);
            }
        }
    }
}

module thread_generator(dia, p, l, inner) {
    steps = 32; 
    total_steps = (l / p) * steps;
    for (i = [0 : total_steps - 1]) {
        hull() {
            thread_profile(i, steps, p, inner, dia);
            thread_profile(i + 1, steps, p, inner, dia);
        }
    }
}

module thread_profile(i, steps, p, inner, dia) {
    rotate([0, 0, i * (360/steps)])
    translate([inner/2 + 0.05, 0, i * (p/steps)])
    rotate([90, 0, 0])
    cylinder(h = (dia - inner) + 0.2, d1 = p * 1.1, d2 = 0, $fn = 3);
}
