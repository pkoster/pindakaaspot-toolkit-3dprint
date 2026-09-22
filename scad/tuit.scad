// ============================================================
// Schenktuit + deksel-met-gat - Calvé pindakaaspot
// ============================================================
// Importeert deksel.scad (het kale deksel-lichaam) en levert daarmee de
// uiteindelijke, printbare "deksel met gat" op — samen met de losse tuit die
// er vanaf de onderkant wordt ingelijmd. 
// ============================================================

$fn = 100; 

use <deksel.scad>

// D_out/wanddikte/top_dikte komen uit deksel.scad
D_out     = deksel_D_out();
wanddikte = deksel_wanddikte();
top_dikte = deksel_top_dikte();

// --- Schenktuit ---
// Ronde tuit aan de rand van het deksel. Wordt als LOS object geprint en
// achteraf vanaf de onderkant van het deksel vastgelijmd. 
schenktuit_diameter       = 10;    // diameter van het kanaal [mm]
schenktuit_lengte         = 50;    // lengte van de tuit vanaf het bovenvlak van het deksel [mm]
schenktuit_wand           = 1.2;   // wanddikte van de ronde tuit [mm]
schenktuit_koppel_breedte = 3;     // breedte van de verzonken flens rond de opening [mm]
schenktuit_buiten_diameter = schenktuit_diameter + 2*schenktuit_wand;
// Bij het deksel is de opening taps toelopend onder 45° 
schenktuit_verruiming     = 2;     // extra diameter bij het deksel t.o.v. de rest van de tuit [mm]
schenktuit_bore_basis     = schenktuit_diameter + schenktuit_verruiming;
schenktuit_buiten_basis   = schenktuit_buiten_diameter + schenktuit_verruiming;

schenktuit_randmarge = 0.2;
schenktuit_flens_buiten_r = schenktuit_bore_basis/2 + schenktuit_koppel_breedte;
schenktuit_center_r = (D_out/2 - wanddikte) - schenktuit_randmarge - max(schenktuit_buiten_basis/2, schenktuit_flens_buiten_r);
// Hoek waarop het gat/de verzinking in het deksel staat. 
schenktuit_hoek = 180;

afstand_tot_deksel = 20; // gewenste tussenruimte tussen deksel en tuit bij "alle" [mm]

// Voor losse STL-export via de command line, bv.:
//   openscad -D 'export_mode="deksel"' -o deksel_met_gat.stl tuit.scad
//   openscad -D 'export_mode="tuit"'   -o tuit.stl tuit.scad
// "alle" (standaard) toont beide samen, naast elkaar.
export_mode = "alle";

// ---------------- MODULES ----------------

// 
module schenktuit_opening() {
    translate([schenktuit_center_r, 0, -0.5])
        cylinder(d = schenktuit_buiten_diameter, h = 0.5);
    translate([schenktuit_center_r, 0, 0])
        cylinder(d1 = schenktuit_buiten_diameter, d2 = schenktuit_buiten_basis, h = top_dikte/2);
}

// Verzonken rand rond de tuit-opening, aan de ONDERKANT van het deksel
module schenktuit_verzinking() {
    r_buiten = schenktuit_bore_basis/2 + schenktuit_koppel_breedte;
    translate([schenktuit_center_r, 0, top_dikte/2])
        cylinder(r = r_buiten, h = top_dikte/2 + 0.5);
}

// Ronde, holle schenktuit die vanaf het bovenvlak van het deksel (z=0) naar
// buiten steekt, geplaatst aan de rand van het deksel. Het uiteinde is onder
// 45° afgeschuind
module schenktuit_tuit() {
    r_buiten = schenktuit_buiten_diameter / 2;
    marge = r_buiten + 1; // extra lengte zodat de afschuining het volume niet doorbreekt
    buis_hoogte = schenktuit_lengte + marge; // hoofdbuis: van de tip tot het buitenvlak (z=0)

    intersection() {
        union() {
            // Hoofdbuis
            translate([schenktuit_center_r, 0, -buis_hoogte])
                difference() {
                    cylinder(d = schenktuit_buiten_diameter, h = buis_hoogte);
                    translate([0, 0, -0.5])
                        cylinder(d = schenktuit_diameter, h = buis_hoogte + 1);
                }
            // Taps verruimd deel: van z=0 (onveranderde maat) naar z=top_dikte/2 (verruimd), onder 45°
            translate([schenktuit_center_r, 0, 0])
                difference() {
                    cylinder(d1 = schenktuit_buiten_diameter, d2 = schenktuit_buiten_basis, h = top_dikte/2);
                    translate([0, 0, -0.5])
                        cylinder(d1 = schenktuit_diameter, d2 = schenktuit_bore_basis, h = top_dikte/2 + 1);
                }
        }

        translate([schenktuit_center_r, 0, -schenktuit_lengte])
            rotate([0, 45, 0])
                translate([-1000, -1000, 0])
                    cube([2000, 2000, 2000]);
    }
}

// Flens aan de basis van de losse tuit: vult de verzonken rand
// (schenktuit_verzinking) precies op, van de buitenkant van het verruimde
// (taps toelopende) deel van de tuit tot de buitenrand van de uitsparing,
// met dezelfde diepte (top_dikte/2).
module schenktuit_flens() {
    r_binnen = schenktuit_bore_basis/2;
    r_buiten = schenktuit_bore_basis/2 + schenktuit_koppel_breedte;
    translate([schenktuit_center_r, 0, top_dikte/2])
        difference() {
            cylinder(r = r_buiten, h = top_dikte/2);
            translate([0, 0, -0.5])
                cylinder(r = r_binnen, h = top_dikte + 1);
        }
}

// Complete losse tuit: buis + flens, als apart te printen en te lijmen object.
module schenktuit_los() {
    union() {
        schenktuit_tuit();
        schenktuit_flens();
    }
}

// Het geïmporteerde kale deksel (deksel() uit deksel.scad), met de tuit-opening
// en -verzinking erdoorheen gesneden.
module deksel_met_gat() {
    difference() {
        deksel();
        rotate([0, 0, schenktuit_hoek]) {
            schenktuit_opening();
            schenktuit_verzinking();
        }
    }
}

// ---------------- ASSEMBLAGE ----------------
module tuit_scene() {
    toon_deksel  = (export_mode == "alle" || export_mode == "deksel");
    toon_tuit    = (export_mode == "alle" || export_mode == "tuit");
    naast_elkaar = (export_mode == "alle");

    if (toon_deksel) {
        deksel_met_gat();
    }

    if (toon_tuit) {
        schenktuit_x = naast_elkaar ? D_out/2 + afstand_tot_deksel - (schenktuit_center_r - schenktuit_flens_buiten_r) : 0;
        translate([schenktuit_x, 0, top_dikte])
            rotate([180, 0, 0])
                schenktuit_los();
    }
}

tuit_scene();
