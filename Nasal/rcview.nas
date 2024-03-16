# Parts taken from the fly-by view and holding the viewer at a
# given radius from the plane

var distime = 4.0; #s
var distmax = 400; #m

var defheight = 1.75; #m
var defradius = 10.0;#m    

var pilot = {
    init : func {
	
	me.height_m = defheight;
	me.radius_m = defradius;
	setprop("sim/rcviewer/height-m",defheight);
	setprop("sim/rcviewer/radius-m",defradius);
	setlistener("sim/rcviewer/height-m", func(node) { me.set_height(node.getValue()) });
	setlistener("sim/rcviewer/radius-m", func(node) { me.set_radius(node.getValue()) });
	

	me.reset();
	
    },

	start : func {
	    me.reset();
    },


	set_height : func (h) {
	    if ( h != nil ){
		me.height_m = h;
	    }   
	    
    },
	
    	set_radius : func (r) {
	    if ( r != nil ){
		me.radius_m = r;
	    }
    },
		
	    
	aircraft_position : func() {
	  return geo.aircraft_position();
	  
    },

	reset : func {
	    me.last = me.aircraft_position();
	    me.setpos(1);
    },
	
	setpos : func(extrapolate=0) {
	    
	    var vn = getprop("/velocities/speed-north-fps");
	    var ve = getprop("/velocities/speed-east-fps");
	    var course = (0.5*math.pi - math.atan2(vn,ve))*R2D;
	    
	    var pos = me.aircraft_position();

	    var dist = 0.0;
	    if ( extrapolate ) {
		# predict distance based on speed
		var mps = math.sqrt( vn*vn + ve*ve ) * FT2M;
		dist = math.max(mps * distime, me.radius_m);
	    } else {
		# use actual distance
		dist = me.last.distance_to(pos);
		# reset when too far (i.e. position changed due to skipping time in replay mode)
		if ( dist > distmax ) return me.reset();
	    }
	    
	    pos.apply_course_distance(course, dist);
	    me.last.set(pos);

	    # apply small random deviation to set aside and 20%
	    # variations in radius
	    var radius = me.radius_m * (0.2 * rand() + 0.8);
	    var angle = (rand() * 0.15 + 0.5) * (rand() < 0.5 ? -math.pi : math.pi);

	    var dev_side = math.sin(angle) * radius;
	    pos.apply_course_distance(course + 90, dev_side);
	    
	    var lat = pos.lat();
	    var lon = pos.lon();
	    var alt = geo.elevation(lat, lon) + me.height_m;

	    setprop("/sim/rcviewer/latitude-deg", lat);
	    setprop("/sim/rcviewer/longitude-deg", lon);
	    setprop("/sim/rcviewer/altitude-ft", alt * M2FT);
	    
	    return 1.0;
    },

	update : func {
	    return me.setpos();
    },
};
