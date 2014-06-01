tube_dia = 8.5;
pump_wall = 6;
pump_dia = 120;
pump_h = 1.6*tube_dia;

rotor_plate_h = 6;

n_rollers = 3;

// 606 bearing
bearing_outer_dia = 22;
bearing_inner_dia = 8 - 0.25;
bearing_h = 7;

m3_dia = 3.2;
m3_head_h = 3.1;
m3_head_dia = 6;
m4_dia = 4.2;
m4_head_h = 4.5; // liberally
m4_head_dia = 7.5;
m4_nut_width = 7.2;
m4_nut_thickness = 3.4;

runway_h = 0.3*bearing_h+rotor_plate_h;

delta = 0.01;

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

module countersunk_m4(h=40) {
    union() {
        cylinder(r=m4_dia/2, h=h);
        translate([0,0,-h])
        cylinder(r=m4_head_dia/2, h=h+delta);
    }
}

module pump_base() {
    base_h = 5;
    base_dia = pump_dia+tube_dia/2+2*pump_wall+15;
    opening_angle=30;
    union() {
        // plate
        translate([0,0,-base_h/2])
        difference() {
            translate([0,0,-base_h])
            union() {
                cylinder(r=base_dia/2, h=base_h);
                translate([7,0,0])
                cylinder(r=38/2, h=base_h);
            }

            // Large cutouts
            for (theta=[45:90:360])
            rotate(theta)
            translate([base_dia/4,0,0])
            cylinder(r=base_dia/8, h=3*base_h, center=true);

            // Small cutouts
            for (theta=[0:90:360])
            rotate(theta)
            translate([0.3*base_dia,0,0])
            cylinder(r=base_dia/16, h=3*base_h, center=true);

            // Shaft hole
            cylinder(r=13/2, h=10*base_h, center=true);
            translate([7,0,0]) {
                for (theta = [-90,90,0, 26.6,-26.6,180-26.6,180+26.6])
                rotate(theta)
                translate([31/2, 0, 0]) {
                    cylinder(r=m3_dia/2, h=10*base_h, center=true);
                    cylinder(r=m3_head_dia/2, h=2*m3_head_h, center=true);
                }
            }

            // Screw holes
            for (theta = [0:30:360]) {
                rotate(theta)
                translate([base_dia/2-4,0,0])
                cylinder(r=m3_dia/2, h=10*base_h, center=true);
            }
        }

        // wall
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

// M4 setscrew
// nut catch centered at origin, extending h in +z
// bolt extending lp in +x direction, lm in -x direction
module setscrew(lm, lp, h) {
    translate([0, -m4_nut_width/2, -m4_nut_width/2])
    cube([m4_nut_thickness, m4_nut_width, h + m4_nut_width/2]);

    rotate([0, 90, 0])
    translate([0, 0, -lm])
    cylinder(r=m4_dia/2, h=lp+lm);
}

module rotor(include_bearings = false) {
    rotor_dia = pump_dia - bearing_outer_dia+3;
    union() {
        color("steelblue")
        difference() {
            union() {
                cylinder(r=rotor_dia/2 + bearing_inner_dia/2, h=rotor_plate_h, $fn=4*$fn);
                cylinder(r=10, h=rotor_plate_h+10);
            }
            
            // Cut out holes
            for (theta = [360/n_rollers/2:360/n_rollers:360])
            rotate(theta)
            translate([0.3*rotor_dia, 0, -rotor_plate_h])
            cylinder(r=20, h=3*rotor_plate_h);

            // Bearing mounting holes
            for (theta = [0:360/n_rollers:360])
            rotate(theta-22)
            for (phi = [0:8:40])
            rotate(phi)
            translate([-phi/16, 0, 0])
            translate([rotor_dia/2 - 1, 0, m4_head_h])
            for (i = [0:1]) {
                translate([-5*i, 0, 0])
                countersunk_m4();
            }

            // Shaft
            cylinder(r=6.2/2, h=30);

            // Set screw for shaft
            rotate(180)
            translate([5, 0, 5])
            setscrew(lm=15, lp=20, h=20);
        }
            
        if (include_bearings)
        rotate(-14)
        for (theta = [0:360/n_rollers:360])
        rotate(theta)
        translate([rotor_dia/2 - 2, 0, rotor_plate_h + 0.5]) {
                color("brown") bearing();
                bearing_pin();
        }
    }
}

module bearing_pin() {
    difference() {
        union() {
            cylinder(r=bearing_inner_dia/2, h=1.5*bearing_h, $fn=2*$fn);

            translate([0, 0, 1.1*bearing_h])
            cylinder(r=bearing_inner_dia/2+1.5, h=5, $fn=2*$fn);
        }

        // Screw hole
        cylinder(r=m4_dia/2+0.1, h=6*bearing_h, center=true, $fn=2*$fn);

        // Nut trap
        translate([0,0,2*bearing_h])
        linear_extrude(height=2*3, center=true)
        circle(r=m4_nut_width/2, $fn=6);
    }
}

module motor() {
    color("red")
    translate([0,0,-pump_h/2])
    cylinder(r=6/2, h=15);
}

module mockup() {
    union() {
        pump_base($fn=30);

        if (true)
        rotate(720*$t)
        translate([0,0,-2])
        rotor(true);

        motor();
    }
}

module print_plate_1() {
    union() {
        rotor(false, $fn=48);

        rotate(45)
        for (theta = [0:10:30])
        rotate(theta)
        translate([0.6*pump_dia,0,0])
        mirror([0,0,180])
        bearing_pin();
    }
}

module print_plate_2() {
    union() {
        pump_base($fn=80);
    }
}

mockup();
//print_plate_1();
//print_plate_2();
//rotor(false, $fn=48);