// -----------------------------------------------------------
// CONFIGURATION
// -----------------------------------------------------------

hole_diam = 2;
box_thick = 4;
sep_thick = 4;
sep_teeth_width = 10;
tooth_correction = 0.1;
led_diam=8; // 7 per els SMD
box_step_size = 30;
sep_depth = 60;
gap=6;
mill_offset=0;
box_inner_depth=120;

// -----------------------------------------------------------

box_inner_width = box_step_size * 8 + 1;
box_inner_height = box_step_size * 5 + 1;
box_outer_width = box_inner_width + 2 * box_thick;
box_outer_height = box_inner_height + 2 * box_thick;
//box_inner_depth = box_outer_height;
box_teeth_width = box_inner_depth / 9;
teeth = box_inner_depth / box_teeth_width;

// -----------------------------------------------------------

module base() {
    difference() {
        square([box_outer_width, box_inner_depth]);
        for(y=[box_teeth_width:box_teeth_width*2:box_inner_depth-box_teeth_width]) {
            translate([0,y,0])
                square([box_thick,box_teeth_width]);
            translate([box_inner_width+box_thick,y,0])
                square([box_thick,box_teeth_width]);
        }
    }
}

module side() {
    union() {
        square([box_inner_height, box_inner_depth]);
        for(y=[box_teeth_width:box_teeth_width*2:box_inner_depth-box_teeth_width]) {
            translate([-box_thick,y,0])
                square([box_thick,box_teeth_width]);
            translate([box_inner_height,y,0])
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

module back_face() {
    difference() {
        face_with_holes();
        translate([(box_inner_width-80)/2-4,(box_inner_height-51)/2+4,0])
            //rotate(90)
                pcbfootprint();
        translate([36,20,0]) {
            circle(12.5/2, center=true);
        }
    }
}

module pcbfootprint(hole=4) {

    // HOLES
    hole = hole / 2;
    translate([4,4,0]) {
        circle(hole, center=true);
    }
    translate([84,4,0]) {
        circle(hole, center=true);
    }
    translate([4,55,0]) {
        circle(hole, center=true);
    }
    translate([84,55,0]) {
        circle(hole, center=true);
    }
    // BUTTONS
    translate([23,44,0]) {
        square([55,13]);
    }

}
    
 
module outside_box() {
    translate([0,0]) base();
    translate([0,box_inner_depth + gap]) base();
    translate([0, 2*(box_inner_depth+gap)]) side();
    translate([box_inner_height + 2*gap, 2*(box_inner_depth+gap)]) side();
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
    mirror([0,1,0]) {
        difference() {
            inside_box_wall1();
            // DENTS INTERIORS
            for(i=[1:2:5])
                translate([2*box_step_size,i*box_step_size/2,0])
                    square([sep_thick, sep_teeth_width], center=true);
        }
    }
    
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
    translate([sep_depth+0.5*gap,gap]) sep_3();
    translate([sep_depth+0.5*gap,sep_depth+2*gap]) sep_2();
    translate([2*sep_depth+1.7*gap,sep_depth+2*gap]) sep_1();
}

module inside_box() {
    inside_box_base();
    translate([box_inner_width + gap, 0]) back_face();
    translate([0, box_inner_height + gap]) inside_box_wall1();
    translate([0, box_inner_height + 2 * sep_depth + 2*gap]) inside_box_wall2();
    translate([2*box_inner_width + 2*gap, 0]) inside_box_wall3();
    translate([2*box_inner_width + 2*sep_depth + 2.5*gap, 0]) inside_box_wall4();
    translate([2*box_inner_width + 2*sep_depth + 4*gap, 0]) separators();
}

//Caixa exterior (43x25, fusta 8mm)
//outside_box();

// Caixa interior (57x31, fusta 4mm)
//inside_box();
back_face();

// Tapa (24x15, acrílic neu 3/4mm)
//face();

