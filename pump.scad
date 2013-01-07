tube_dia = 5;
pump_wall = 6;
pump_dia = 150;
pump_h = 2*tube_dia;

fudge = 0.3*tube_dia;
rotor_plate_h = 2;

bearing_outer_dia = 22;
bearing_inner_dia = 8;
bearing_h = 7;

module pump_base() {
    base_h = 2;
    base_dia = pump_dia+tube_dia/2+2*pump_wall+15;
    opening_angle=80;
    union() {
        translate([0,0,-pump_h/2-base_h/2])
        difference() {
            cylinder(r=base_dia/2, h=base_h, center=true);
            for (theta = [0:30:360]) {
                rotate(theta)
                translate([base_dia/2-3,0,0])
                cylinder(r=3/2, h=2*base_h, center=true, $fn=16);
            }
        }

        difference() {
            cylinder(r=pump_dia/2+pump_wall, h=pump_h, center=true);
            cylinder(r=pump_dia/2, h=2*pump_h, center=true);

            // Cut out opening
            linear_extrude(h=2*pump_h, center=true) {
                scale(2*pump_dia)
                polygon(points=[
                        [0,0],
                        [cos(-opening_angle/2), sin(-opening_angle/2)],
                        [cos(opening_angle/2), sin(opening_angle/2)],
                        [0,0]]);
            }
        }
    }
}

module bearing() {
    difference() {
        cylinder(r=bearing_outer_dia/2, h=bearing_h);
        translate([0,0,-bearing_h/2])
        cylinder(r=bearing_inner_dia/2, h=2*bearing_h);
    }
}

module rotor(include_bearings = false) {
    n_wheels = 4;
    rotor_dia = pump_dia - bearing_outer_dia - 2*fudge;
    union() {
        color("steelblue")
        translate([0,0,-rotor_plate_h])
        cylinder(r=rotor_dia/2 + bearing_inner_dia/2, h=rotor_plate_h);

        for (theta = [0:360/n_wheels:360])
        rotate(theta)
        translate([rotor_dia/2,0,0]) {
            color("steelblue")
            cylinder(r=bearing_inner_dia/2, h=1.2*bearing_h);

            if (include_bearings)
            color("brown")
            bearing();
        }
    }
}

pump_base($fn=80);
translate([0,0,-pump_h/2+rotor_plate_h])
rotor(true);

