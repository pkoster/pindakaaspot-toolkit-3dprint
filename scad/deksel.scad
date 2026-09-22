// ============================================================
// Deksel - Calvé pindakaaspot (medium, 350g)
// ============================================================
// Zelfstandig onderdeel: deksel met schroefdraad en ribbels 
//
// Los renderen/exporteren: 
//   openscad -o deksel.stl deksel.scad
// ============================================================

$fn = 100;

// ---------------- PARAMETERS ----------------
D_out        = 84;    // buitendiameter deksel [mm]
wanddikte    = 1.5;   // wanddikte zijkant [mm]
top_dikte    = 2;     // dikte bovenkant [mm]
H            = 20;    // totale hoogte deksel [mm]

pitch        = 3.5;   // spoed schroefdraad [mm/omwenteling]
windingen    = 1.15;  // aantal windingen schroefdraad
thread_diepte= 1.2;   // diepte/dikte van de draadrib [mm]
thread_breedte = 3.0; // breedte van de draadrib [mm]
thread_start = 6.5;   // start van de schroefdraad vanaf de bodem van het deksel (z=0) [mm]

n_ribs       = 45;    // aantal grip-ribbels buitenkant
rib_breedte  = 1.5;   // breedte per ribbel [mm]
rib_diepte   = 0.6;   // hoe ver de ribbel uitsteekt [mm]

// --- Pot (referentie, alleen voor fit-check t.o.v. het deksel) ---
pot_hals_buiten    = 80;   // buitendiameter hals pot [mm] (over de draad, moet passen in deksel-binnendiameter)
pot_opening_binnen = 72;   // binnendiameter opening pot [mm]
pot_hals_hoogte    = 18;   // hoogte hals pot [mm]
pot_hoogte_totaal  = 136;  // totale hoogte pot [mm]
pot_max_diameter   = 89;   // maximale buitendiameter pot (schouder/body) [mm]
pot_schouder_hoogte = 20;  // hoogte overgang hals->body [mm] (geschat, niet gemeten)

toon_fit_check = false;     // true = deksel + pot samen tonen, false = alleen het deksel

// Accessor-functions zodat andere bestanden (bv. tuit.scad) via `use` deze
// maten kunnen uitlezen. `use` importeert GEEN variabelen, alleen modules en
// functions — dus dit is de manier om D_out/wanddikte/top_dikte door te geven
// zonder ze in elk bestand opnieuw te moeten (en per ongeluk laten afwijken).
function deksel_D_out()     = D_out;
function deksel_wanddikte() = wanddikte;
function deksel_top_dikte() = top_dikte;
function deksel_H()         = H;

// ---------------- MODULES ----------------

// Basis deksel-lichaam: buitenkant vol, binnenkant uitgehold
module deksel_body() {
    difference() {
        cylinder(d = D_out, h = H);
        translate([0, 0, top_dikte])
            cylinder(d = D_out - 2*wanddikte, h = H); // holle binnenkant
    }
}

// Grip-ribbels rondom de buitenkant (verticaal, korte richel per rib)
module ribs() {
    rib_hoogte = (H - top_dikte) * 0.8;
    rib_center_z = top_dikte + (H - top_dikte) / 2;
    for (i = [0 : n_ribs - 1]) {
        rotate([0, 0, i * 360 / n_ribs])
            translate([D_out/2 + rib_diepte/2, 0, rib_center_z])
                cube([rib_diepte, rib_breedte, rib_hoogte], center = true);
    }
}

// Helische schroefdraad-rib aan de binnenkant: steekt thread_diepte [mm] naar
// binnen vanaf de holle binnenwand, met een verticale dikte van thread_breedte [mm].
// Opgebouwd uit dicht opeenvolgende blokjes langs een helixpad met ruime
// onderlinge overlap, zodat de rib aaneengesloten oogt 
module thread() {
    binnen_r = (D_out - 2*wanddikte) / 2;
    hoek_totaal = windingen * 360;
    n_segmenten = max(300, ceil(hoek_totaal * 2)); // voldoende resolutie voor een vloeiende spiraal
    hoek_per_segment = hoek_totaal / n_segmenten;
    z_per_segment = (pitch * windingen) / n_segmenten;

    boog_per_segment = (binnen_r - thread_diepte/2) * hoek_per_segment * PI / 180;
    tangentiele_breedte = boog_per_segment * 3; // ruime overlap tussen segmenten

    // Driehoekig profiel: volle thread_breedte aan de basis (bij de wand),
    // toelopend naar een punt op thread_diepte naar binnen (X=0 is de wand zelf).
    profiel = [[0, -thread_breedte/2], [0, thread_breedte/2], [-thread_diepte, 0]];

    for (i = [0 : n_segmenten - 1]) {
        hoek = i * hoek_per_segment;
        z = thread_start + i * z_per_segment;
        rotate([0, 0, hoek])
            translate([binnen_r, 0, z])
                rotate([90, 0, 0])
                    linear_extrude(height = tangentiele_breedte, center = true)
                        polygon(profiel);
    }
}

// Volledig deksel (gesloten top bij z=0, opening bij z=H)
module deksel() {
    union() {
        union() {
            deksel_body();
            ribs();
        }
        thread(); // protruderende rib, dus toegevoegd i.p.v. afgetrokken
    }
}

// Vereenvoudigd pot-lichaam (hals + schouder + body) voor fit-check.
// Body staat rechtop met de hals boven (z omhoog), opening bovenaan.
module pot_body() {
    body_hoogte = pot_hoogte_totaal - pot_hals_hoogte - pot_schouder_hoogte;
    bore_hoogte = pot_hals_hoogte + pot_schouder_hoogte + 1;

    difference() {
        union() {
            cylinder(d = pot_max_diameter, h = body_hoogte); // body
            translate([0, 0, body_hoogte])
                cylinder(d1 = pot_max_diameter, d2 = pot_hals_buiten, h = pot_schouder_hoogte); // schouder
            translate([0, 0, body_hoogte + pot_schouder_hoogte])
                cylinder(d = pot_hals_buiten, h = pot_hals_hoogte); // hals
        }
        translate([0, 0, pot_hoogte_totaal - bore_hoogte])
            cylinder(d = pot_opening_binnen, h = bore_hoogte + 0.1); // opening
    }
}

// ---------------- STANDALONE ----------------
if (toon_fit_check) {
    color("SaddleBrown", 0.6)
        pot_body();

    translate([0, 0, pot_hoogte_totaal - pot_hals_hoogte + H])
        rotate([180, 0, 0])
            color("SlateGray", 0.85)
                deksel();
} else {
    deksel();
}
