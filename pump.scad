tube_dia = 5;
pump_wall = 6;
pump_dia = 150;
pump_h = 1.2*tube_dia;

rotor_plate_h = 4.5;

bearing_outer_dia = 22;
bearing_inner_dia = 8 - 0.25;
bearing_h = 7;

m3_head_h = 3.1;
m3_head_dia = 6;

runway_h = 0.3*bearing_h+rotor_plate_h;

module wall_cross_section() {
    translate([pump_dia/2,0]) {
        translate([0,runway_h])
        polygon([
                [-tube_dia/3,0],
                [pump_wall,0],
                [pump_wall, pump_h],
                [-tube_dia/3, pump_h],
                [0, 2*pump_h/3],
                [0, 1*pump_h/3],
                [-tube_dia/3,0],
                ]);
        translate([-tube_dia/3,0])
        square([pump_wall + tube_dia/3, runway_h]);
    }
}

module countersunk_m4() {
    translate([0,0,-1])
    cylinder(r=4/2, h=40);
    translate([0,0,-40])
    cylinder(r=8/2, h=40);
}

module pump_base() {
    base_h = 2;
    base_dia = pump_dia+tube_dia/2+2*pump_wall+15;
    opening_angle=30;
    union() {
        translate([0,0,-pump_h/2-base_h/2])
        difference() {
            union() {
                cylinder(r=base_dia/2, h=base_h, center=true);
                translate([7,0,-4])
                cylinder(r=38/2, h=4);
            }

            // Large cutouts
            for (theta=[45:90:360])
            rotate(theta)
            translate([base_dia/4,0,0])
            cylinder(r=base_dia/7, h=2*base_h, center=true);

            // Small cutouts
            for (theta=[0:90:360])
            rotate(theta)
            translate([3*base_dia/8,0,0])
            cylinder(r=base_dia/15, h=2*base_h, center=true);

            // Shaft hole
            cylinder(r=13/2, h=10*base_h, center=true);
            translate([7,0,0]) {
                for (theta = [-90,90,0, 26.6,-26.6,180-26.6,180+26.6])
                rotate(theta)
                translate([31/2, 0, 0]) {
                    cylinder(r=3.1/2, h=10*base_h, center=true);
                    cylinder(r=m3_head_dia/2, h=2*m3_head_h, center=true);
                }
            }

            // Screw holes
            for (theta = [0:30:360]) {
                rotate(theta)
                translate([base_dia/2-3,0,0])
                cylinder(r=3.1/2, h=10*base_h, center=true, $fn=16);
            }
        }

        difference() {
            translate([0,0,-pump_h/2])
            rotate_extrude()
            wall_cross_section();

            // Cut out opening
            linear_extrude(h=2*pump_h, center=true) {
                scale(2*pump_dia)
                polygon(points=[
                        [0,0],
                        [cos(-opening_angle/2), sin(-opening_angle/2)],
                        [cos(opening_angle/2), sin(opening_angle/2)],
                        [0,0]]);
            }

            // Tubing exit holes
            for (y = [0,1])
            mirror([0,y,0])
            translate([
                    pump_dia/2*cos(-opening_angle/2-15),
                    pump_dia/2*sin(-opening_angle/2-15),
                    runway_h
                ])
            rotate([0,90,30])
            cylinder(r=1.1*tube_dia/2, h=40, center=true);
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

module shaft_clamp(shaft_dia, outer_dia, height, nut_pos=0.5, nut_width=7.1, nut_thickness=3.1, bolt_dia=4) {
    nut_z = height*nut_pos;
    h = height - nut_z + nut_width/2;
    difference() {
        cylinder(r=outer_dia/2, h=height);

        translate([0,0,-height]) cylinder(r=shaft_dia/2, h=3*height);

        translate([shaft_dia/2 + (outer_dia-shaft_dia)/2 - 2*nut_thickness, 0, 0])
        translate([0, 0, nut_z+h-nut_width/2])
        cube([nut_thickness, nut_width, 2*h], center=true);

        translate([0,0, nut_z])
        rotate([0,90,0])
        cylinder(r=bolt_dia/2, h=2*outer_dia);
    }
}

module rotor(include_bearings = false) {
    n_wheels = 4;
    rotor_dia = pump_dia - bearing_outer_dia+2;
    union() {
        color("steelblue")
        translate([0,0,-rotor_plate_h])
        difference() {
            cylinder(r=rotor_dia/2 + bearing_inner_dia/2, h=rotor_plate_h);
            
            // Shaft hole
            cylinder(r=13/2, h=3*rotor_plate_h, center=true);

            // Cut out holes
            for (theta = [360/n_wheels/2:360/n_wheels:360])
            rotate(theta)
            translate([0.3*rotor_dia, 0, -rotor_plate_h])
            cylinder(r=20, h=3*rotor_plate_h);

            // Bearing mounting holes
            for (theta = [0:360/n_wheels:360])
            rotate(theta-16)
            for (phi = [0:8:32])
            rotate(phi)
            translate([-phi/8, 0, 0])
            translate([rotor_dia/2, 0, 3])
            for (i = [0:2]) {
                translate([-6*i, 0, 0])
                countersunk_m4();
            }
        }
            
        color("steelblue")
        rotate(45) shaft_clamp(6+0.4, 25, 15, $fn=40);

        for (theta = [0:360/n_wheels:360])
        rotate(theta)
        translate([rotor_dia/2,0,0]) {
            if (include_bearings)
            color("brown")
            bearing();
        }
    }
}

module bearing_jig() {
    difference() {
        cylinder(r=bearing_inner_dia/2, h=2*bearing_h, $fn=80);
        cylinder(r=4/2+0.1, h=6*bearing_h, center=true, $fn=80);

        // Nut trap
        translate([0,0,2*bearing_h])
        linear_extrude(height=2*3, center=true)
        circle(r=6/2, $fn=6);
    }
}

module motor() {
    color("red")
    translate([0,0,-pump_h/2])
    cylinder(r=6/2, h=15);
}

module mockup() {
    pump_base($fn=80);

    if (true)
    rotate(720*$t)
    translate([0,0,-pump_h/2+rotor_plate_h])
    rotor(true, $fn=48);

    motor();
}

mockup();

//pump_base($fn=80);
//rotor(false, $fn=48);

if (true)
rotate(45)
for (theta = [0:10:30])
rotate(theta)
translate([0.7*pump_dia,0,0])
bearing_jig();

