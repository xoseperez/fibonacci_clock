// -----------------------------------------------------------
// CONFIGURATION
// -----------------------------------------------------------

hole_diam = 3;
box_thick = 10;
sep_thick = 4;
sep_teeth_width = 10;
led_diam=7;
box_step_size = 30;
box_inner_depth=100;
sep_depth = 60;


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

module box() {
    gap=5;
    base();
    translate([0,box_inner_depth+gap,0]) base();
    translate([box_outer_width+gap,0,0]) side();
    translate([box_outer_width+gap,box_inner_depth+gap,0]) side();
}

module face() {
    difference() {
        
        square([box_outer_width, box_outer_height]);
        hole = hole_diam / 2;
        hole_center = (box_thick) / 2;
        translate([hole_center,hole_center,0]) {
            circle(hole, center=true);
        }
        translate([box_outer_width-hole_center,hole_center,0]) {
            circle(hole, center=true);
        }
        translate([box_outer_width-hole_center,box_outer_height-hole_center,0]) {
            circle(hole, center=true);
        }
        translate([hole_center,box_outer_height-hole_center,0]) {
            circle(hole, center=true);
        }
    }
}

module sep_base() {
    
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

        square([box_inner_width, box_inner_height]);

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

        for(led = leds)
            translate([led[0]*box_step_size,led[1]*box_step_size,0])
                circle(led_radii, center=true);
    }

}

module sep_5() {
    difference() {
        union() {
            square([sep_depth, box_inner_height]);
            for(i=[1:2:9])
                translate([-sep_thick/2,i*box_step_size/2,0])
                    square([sep_thick, sep_teeth_width], center=true);
        }
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
    gap=10;
    sep_base();
    translate([box_inner_width+gap,0,0]) sep_5();
    translate([0,box_inner_height+gap,0]) sep_3();
    translate([box_step_size*3+gap,box_inner_height+gap,0]) sep_2();
    translate([box_step_size*5+2*gap,box_inner_height+gap,0]) sep_1();
}

//box();
face();
translate([0,box_outer_height+10,0]) separators();