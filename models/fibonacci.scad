// -----------------------------------------------------------
// CONFIGURATION
// -----------------------------------------------------------

hole_diam = 2;
box_thick = 8;
sep_thick = 4;
sep_teeth_width = 10;
led_diam=12; // 7 per els SMD
box_step_size = 30;
box_inner_depth=120;
sep_depth = 60;
gap=10;

// -----------------------------------------------------------

box_inner_width = box_step_size * 8;
box_inner_height = box_step_size * 5;
box_outer_width = box_inner_width + 2 * box_thick;
box_outer_height = box_inner_height + 2 * box_thick;
box_teeth_width = box_inner_depth / 5;
teeth = box_inner_depth / box_teeth_width;

// -----------------------------------------------------------

module base() {
    difference() {
        square([box_outer_width, box_inner_depth]);
        for(i=[1:2:teeth]) {
            translate([0,i*box_teeth_width,0])
                square([box_thick,box_teeth_width]);
            translate([box_inner_width+box_thick,i*box_teeth_width,0])
                square([box_thick,box_teeth_width]);
        }
    }
}

module face() {
    square([box_inner_width, box_inner_height]);
}

module face_with_holes() {
    difference() {
        face();
        hole = hole_diam / 2;
        hole_center = 10;
        translate([hole_center,hole_center,0]) {
            circle(hole, center=true);
        }
        translate([box_inner_width-hole_center,hole_center,0]) {
            circle(hole, center=true);
        }
        translate([box_inner_width-hole_center,box_inner_height-hole_center,0]) {
            circle(hole, center=true);
        }
        translate([hole_center,box_inner_height-hole_center,0]) {
            circle(hole, center=true);
        }
    }
}

module side() {
    difference() {
        square([box_outer_height, box_inner_depth]);
        for(i=[0:2:teeth]) {
            translate([0,i*box_teeth_width,0])
                square([box_thick,box_teeth_width]);
            translate([box_inner_height+box_thick,i*box_teeth_width,0])
                square([box_thick,box_teeth_width]);
        }
    }
}

module outside_box() {
    gap=5;
    base();
    translate([0,box_inner_depth+gap,0]) base();
    translate([box_outer_width+gap,0,0]) side();
    translate([box_outer_width+gap,box_inner_depth+gap,0]) side();
}


module inside_box_base() {

    led_radii = led_diam/2;
    leds = [
        [2.5,3.5],
        [2.5,4.5],
        [1,4],
        [1,2],
        [2,1],
        [4.25,1.25],
        [4.25,3.75],
        [6.75,1.25],
        [6.75,3.75],
    ];
    

    difference() {

        face_with_holes();

        // DENTS EXTERIORS
        for(i=[1:2:8*2-1]) {
            translate([i*box_step_size/2,sep_thick/2,0])
                square([sep_teeth_width, sep_thick], center=true);
            translate([i*box_step_size/2,box_inner_height-sep_thick/2,0])
                square([sep_teeth_width, sep_thick], center=true);
        }
        for(i=[1:2:5*2-1]) {
            translate([sep_thick/2,i*box_step_size/2,0])
                square([sep_thick,sep_teeth_width], center=true);
            translate([box_inner_width-sep_thick/2,i*box_step_size/2,0])
                square([sep_thick,sep_teeth_width], center=true);
        }
        
        // DENTS INTERIORS
        for(i=[1:2:9])
            translate([box_step_size * 3,i*box_step_size/2,0])
                square([sep_thick, sep_teeth_width], center=true);
        for(i=[1:2:5])
            translate([i*box_step_size/2,3*box_step_size,0])
                square([sep_teeth_width,sep_thick], center=true);
        for(i=[7:2:9])
            translate([box_step_size * 2,i*box_step_size/2,0])
                square([sep_thick, sep_teeth_width], center=true);
        for(i=[5:2:5])
            translate([i*box_step_size/2,4*box_step_size,0])
                square([sep_teeth_width,sep_thick], center=true);

        // FORATS LEDS
        for(led = leds)
            translate([led[0]*box_step_size,led[1]*box_step_size,0])
                circle(led_radii, center=true);
    }
}

module inside_box_wall1() {

    difference() {
        
        union() {
            square([box_inner_width, sep_depth]);
            for(i=[1:2:8*2-1]) {
                translate([i*box_step_size/2,-sep_thick/2,0])
                    square([sep_teeth_width, sep_thick], center=true);
            }
        }

        // DENTS EXTERIORS
        for(i=[1:2:2*2-1]) {
            translate([sep_thick/2,i*box_step_size/2,0])
                square([sep_thick,sep_teeth_width], center=true);
            translate([box_inner_width-sep_thick/2,i*box_step_size/2,0])
                square([sep_thick,sep_teeth_width], center=true);
        }
        
        // DENTS INTERIORS
        for(i=[1:2:5])
            translate([3*box_step_size,i*box_step_size/2,0])
                square([sep_thick, sep_teeth_width], center=true);
        
    }
}

module inside_box_wall2() {
    mirror([0,1,0]) inside_box_wall1();
}

module inside_box_wall3() {

    difference() {
        
        union() {
            square([sep_depth, box_inner_height]);
            for(i=[1:2:5*2-1]) {
                translate([-sep_thick/2,i*box_step_size/2,0])
                    square([sep_thick,sep_teeth_width], center=true);
            }
        }

        // DENTS EXTERIORS
        difference() {
            union() {
                square([sep_depth, sep_thick]);
                translate([0, box_inner_height-sep_thick])
                    square([sep_depth, sep_thick]);
            }
            for(i=[1:2:2*2-1]) {
                translate([i*box_step_size/2,sep_thick/2,0])
                    square([sep_teeth_width, sep_thick], center=true);
                translate([i*box_step_size/2,box_inner_height-sep_thick/2,0])
                    square([sep_teeth_width, sep_thick], center=true);
            }
        }
    }
}

module inside_box_wall4() {
    mirror([1,0,0]) {
        difference() {
            inside_box_wall3();
            for(i=[1:2:5])
                translate([i*box_step_size/2,3*box_step_size,0])
                    square([sep_teeth_width,sep_thick], center=true);
        }
    }
}

module sep_5() {
    difference() {
        inside_box_wall3();
        for(i=[1:2:5])
            translate([i*box_step_size/2,3*box_step_size,0])
                square([sep_teeth_width,sep_thick], center=true);
        for(i=[1:2:5])
            translate([i*box_step_size/2,4*box_step_size,0])
                square([sep_teeth_width,sep_thick], center=true);
    }
}

module sep_3() {
    difference() {
        union() {
            square([3*box_step_size-sep_thick/2, sep_depth]);
            for(i=[1:2:3])
                translate([3*box_step_size,i*box_step_size/2,0])
                    square([sep_thick, sep_teeth_width], center=true);
            for(i=[1:2:5])
                translate([i*box_step_size/2,-sep_thick/2,0])
                    square([sep_teeth_width,sep_thick], center=true);
        }
        
        // DENTS EXTERIORS CAP ENFORA
        difference() {
            square([sep_thick, sep_depth]);
            for(i=[1:2:3])
                translate([sep_thick/2,i*box_step_size/2,0])
                    square([sep_thick, sep_teeth_width], center=true);
        }
        
        // DENTS INTERIORS
        for(i=[1:2:3])
            translate([box_step_size * 2,i*box_step_size/2,0])
                square([sep_thick, sep_teeth_width], center=true);
    }
}

module sep_2() {
    difference() {
        
        union() {
            square([2*box_step_size-sep_thick/2, sep_depth]);
            for(i=[1:2:3])
                translate([2*box_step_size,i*box_step_size/2,0])
                    square([sep_thick, sep_teeth_width], center=true);
            for(i=[1:2:3])
                translate([i*box_step_size/2,-sep_thick/2,0])
                    square([sep_teeth_width,sep_thick], center=true);
        }
        
        // DENTS EXTERIORS CAP ENFORA
        difference() {
            square([sep_thick, sep_depth]);
            for(i=[1:2:3])
                translate([sep_thick/2,i*box_step_size/2,0])
                    square([sep_thick, sep_teeth_width], center=true);
        }
        
        // DENTS INTERIORS
        for(i=[1:2:3])
            translate([box_step_size,i*box_step_size/2,0])
                square([sep_thick, sep_teeth_width], center=true);
    }
}

module sep_1() {
    union() {
        square([box_step_size-sep_thick, sep_depth]);
        for(i=[1:2:3]) {
            translate([-sep_thick/2,i*box_step_size/2,0])
                square([sep_thick, sep_teeth_width], center=true);
            translate([box_step_size-sep_thick/2,i*box_step_size/2,0])
                square([sep_thick, sep_teeth_width], center=true);
        }
        translate([box_step_size/2-sep_thick/2,-sep_thick/2,0])
            square([sep_teeth_width,sep_thick], center=true);
    }
}

module separators() {
    sep_5();
    translate([sep_depth+gap,0]) sep_3();
    translate([sep_depth+gap,sep_depth+gap,0]) sep_2();
    translate([2*sep_depth+2*gap,sep_depth+gap,0]) sep_1();
}

module inside_box() {
    inside_box_base();
    translate([0, box_inner_height + gap]) face_with_holes();
    translate([box_inner_width + gap, box_inner_height + gap]) inside_box_wall1();
    translate([box_inner_width + gap, box_inner_height + 2 * sep_depth + 2*gap]) inside_box_wall2();
    translate([box_inner_width + gap, 0]) inside_box_wall3();
    translate([box_inner_width + 2*sep_depth + 1.5*gap, 0]) inside_box_wall4();
    translate([box_inner_width + 2*sep_depth + 3*gap, 0]) separators();
}

//Caixa exterior (43x25, fusta 8mm)
//outside_box();

// Caixa interior (57x31, fusta 4mm)
//inside_box();

// Tapa (24x15, acrílic neu 3/4mm)
//face();

