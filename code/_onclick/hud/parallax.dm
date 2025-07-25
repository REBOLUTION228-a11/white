
/datum/hud/proc/create_parallax(mob/viewmob, forced_parallax = 0)
	var/mob/screenmob = viewmob || mymob
	var/client/C = screenmob.client
	if (!apply_parallax_pref(viewmob)) //don't want shit computers to crash when specing someone with insane parallax, so use the viewer's pref
		return

	C.parallax_layers_cached = list()

	if(forced_parallax == 1)
		C.parallax_layers_cached += new /atom/movable/screen/parallax_layer/cyberspess(null, C.view)
		C.parallax_layers_cached += new /atom/movable/screen/parallax_layer/mazespace(null, C.view)
	else if(forced_parallax == 2)
		C.parallax_layers_cached += new /atom/movable/screen/parallax_layer/shizospace(null, C.view)
	else if(GLOB.station_orbit_parallax_type == 3)
		C.parallax_layers_cached += new /atom/movable/screen/parallax_layer/ice_surface(null, C.view)
		C.parallax_layers_cached += new /atom/movable/screen/parallax_layer/clouds(null, C.view)
	else if(GLOB.station_orbit_parallax_type == 4)
		C.parallax_layers_cached += new /atom/movable/screen/parallax_layer/fucking(null, C.view)
	else if(GLOB.station_orbit_parallax_type == 5)
		C.parallax_layers_cached += new /atom/movable/screen/parallax_layer/ice_surface(null, C.view)
	else
		C.parallax_layers_cached += new SSparallax.random_space(null, C.view)
		C.parallax_layers_cached += new /atom/movable/screen/parallax_layer/layer_2(null, C.view)
		C.parallax_layers_cached += new /atom/movable/screen/parallax_layer/planet(null, C.view)
		if(SSparallax.random_layer)
			C.parallax_layers_cached += new SSparallax.random_layer
		C.parallax_layers_cached += new /atom/movable/screen/parallax_layer/layer_3(null, C.view)

	C.parallax_layers = C.parallax_layers_cached.Copy()

	if (length(C.parallax_layers) > C.parallax_layers_max)
		C.parallax_layers.len = C.parallax_layers_max

	C.screen |= (C.parallax_layers)
	var/atom/movable/screen/plane_master/PM = screenmob.hud_used.plane_masters["[PLANE_SPACE]"]
	if(screenmob != mymob)
		C.screen -= locate(/atom/movable/screen/plane_master/parallax_white) in C.screen
		C.screen += PM
	if(PM)
		PM.color = list(
			0, 0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0, 0,
			1, 1, 1, 1,
			0, 0, 0, 0
			)


/datum/hud/proc/remove_parallax(mob/viewmob)
	var/mob/screenmob = viewmob || mymob
	var/client/C = screenmob.client
	C.screen -= (C.parallax_layers_cached)
	var/atom/movable/screen/plane_master/PM = screenmob.hud_used.plane_masters["[PLANE_SPACE]"]
	if(screenmob != mymob)
		C.screen -= locate(/atom/movable/screen/plane_master/parallax_white) in C.screen
		C.screen += PM
	if(PM)
		PM.color = initial(PM.color)
	C.parallax_layers = null

/datum/hud/proc/apply_parallax_pref(mob/viewmob)
	var/mob/screenmob = viewmob || mymob

	if (SSlag_switch.measures[DISABLE_PARALLAX] && !HAS_TRAIT(viewmob, TRAIT_BYPASS_MEASURES))
		return FALSE

	var/client/C = screenmob.client
	if(C.prefs)
		var/pref = C.prefs.parallax
		if (isnull(pref))
			pref = PARALLAX_HIGH
		switch(C.prefs.parallax)
			if (PARALLAX_INSANE)
				C.parallax_throttle = FALSE
				C.parallax_layers_max = 5
				return TRUE

			if (PARALLAX_MED)
				C.parallax_throttle = PARALLAX_DELAY_MED
				C.parallax_layers_max = 3
				return TRUE

			if (PARALLAX_LOW)
				C.parallax_throttle = PARALLAX_DELAY_LOW
				C.parallax_layers_max = 1
				return TRUE

			if (PARALLAX_DISABLE)
				return FALSE

	//This is high parallax.
	C.parallax_throttle = PARALLAX_DELAY_DEFAULT
	C.parallax_layers_max = 5
	return TRUE

/datum/hud/proc/update_parallax_pref(mob/viewmob, forced_parallax = 0)
	remove_parallax(viewmob)
	create_parallax(viewmob, forced_parallax)
	update_parallax(viewmob)

// This sets which way the current shuttle is moving (returns true if the shuttle has stopped moving so the caller can append their animation)
/datum/hud/proc/set_parallax_movedir(new_parallax_movedir, skip_windups, mob/viewmob)
	. = FALSE
	var/mob/screenmob = viewmob || mymob
	var/client/C = screenmob.client
	if(new_parallax_movedir == C.parallax_movedir)
		return
	var/animatedir = new_parallax_movedir
	if(new_parallax_movedir == FALSE)
		var/animate_time = 0
		for(var/thing in C.parallax_layers)
			var/atom/movable/screen/parallax_layer/L = thing
			L.icon_state = initial(L.icon_state)
			L.update_o(C.view)
			var/T = PARALLAX_LOOP_TIME / L.speed
			if (T > animate_time)
				animate_time = T
		C.dont_animate_parallax = world.time + min(animate_time, PARALLAX_LOOP_TIME)
		animatedir = C.parallax_movedir

	var/matrix/newtransform
	switch(animatedir)
		if(NORTH)
			newtransform = matrix(1, 0, 0, 0, 1, 480)
		if(SOUTH)
			newtransform = matrix(1, 0, 0, 0, 1,-480)
		if(EAST)
			newtransform = matrix(1, 0, 480, 0, 1, 0)
		if(WEST)
			newtransform = matrix(1, 0,-480, 0, 1, 0)

	var/shortesttimer
	if(!skip_windups)
		for(var/thing in C.parallax_layers)
			var/atom/movable/screen/parallax_layer/L = thing

			var/T = PARALLAX_LOOP_TIME / L.speed
			if (isnull(shortesttimer))
				shortesttimer = T
			if (T < shortesttimer)
				shortesttimer = T
			L.transform = newtransform
			animate(L, transform = matrix(), time = T, easing = QUAD_EASING | (new_parallax_movedir ? EASE_IN : EASE_OUT), flags = ANIMATION_END_NOW)
			if (new_parallax_movedir)
				L.transform = newtransform
				animate(transform = matrix(), time = T) //queue up another animate so lag doesn't create a shutter

	C.parallax_movedir = new_parallax_movedir
	if (C.parallax_animate_timer)
		deltimer(C.parallax_animate_timer)
	var/datum/callback/CB = CALLBACK(src, PROC_REF(update_parallax_motionblur), C, animatedir, new_parallax_movedir, newtransform)
	if(skip_windups)
		CB.Invoke()
	else
		C.parallax_animate_timer = addtimer(CB, min(shortesttimer, PARALLAX_LOOP_TIME), TIMER_CLIENT_TIME|TIMER_STOPPABLE)


/datum/hud/proc/update_parallax_motionblur(client/C, animatedir, new_parallax_movedir, matrix/newtransform)
	if(!C)
		return
	C.parallax_animate_timer = FALSE
	for(var/thing in C.parallax_layers)
		var/atom/movable/screen/parallax_layer/L = thing
		if (!new_parallax_movedir)
			animate(L)
			continue

		var/newstate = initial(L.icon_state)
		var/T = PARALLAX_LOOP_TIME / L.speed

		if (newstate in icon_states(L.icon))
			L.icon_state = newstate
			L.update_o(C.view)

		L.transform = newtransform

		animate(L, transform = L.transform, time = 0, loop = -1, flags = ANIMATION_END_NOW)
		animate(transform = matrix(), time = T)

/datum/hud/proc/update_parallax(mob/viewmob)
	var/mob/screenmob = viewmob || mymob
	var/client/C = screenmob.client
	var/turf/posobj = get_turf(C.eye)
	if(!posobj)
		return
	var/area/areaobj = posobj.loc

	// Update the movement direction of the parallax if necessary (for shuttles)
	set_parallax_movedir(areaobj.parallax_movedir, FALSE, screenmob)

	var/force
	if(!C.previous_turf || (C.previous_turf.z != posobj.z))
		C.previous_turf = posobj
		force = TRUE

	if (!force && world.time < C.last_parallax_shift+C.parallax_throttle)
		return

	//Doing it this way prevents parallax layers from "jumping" when you change Z-Levels.
	var/offset_x = posobj.x - C.previous_turf.x
	var/offset_y = posobj.y - C.previous_turf.y

	if(!offset_x && !offset_y && !force)
		return

	var/last_delay = world.time - C.last_parallax_shift
	last_delay = min(last_delay, C.parallax_throttle)
	C.previous_turf = posobj
	C.last_parallax_shift = world.time

	for(var/thing in C.parallax_layers)
		var/atom/movable/screen/parallax_layer/L = thing
		L.update_status(screenmob)
		if (L.view_sized != C.view)
			L.update_o(C.view)

		var/change_x
		var/change_y

		if(L.absolute)
			L.offset_x = -(posobj.x - SSparallax.planet_x_offset) * L.speed
			L.offset_y = -(posobj.y - SSparallax.planet_y_offset) * L.speed
		else
			L.offset_x -= offset_x * L.speed
			L.offset_y -= offset_y * L.speed

			if(L.offset_x > 240)
				L.offset_x -= 480
			if(L.offset_x < -240)
				L.offset_x += 480
			if(L.offset_y > 240)
				L.offset_y -= 480
			if(L.offset_y < -240)
				L.offset_y += 480


		if(!areaobj.parallax_movedir && C.dont_animate_parallax <= world.time && (offset_x || offset_y) && abs(offset_x) <= max(C.parallax_throttle/world.tick_lag+1,1) && abs(offset_y) <= max(C.parallax_throttle/world.tick_lag+1,1) && (round(abs(change_x)) > 1 || round(abs(change_y)) > 1))
			L.transform = matrix(1, 0, offset_x*L.speed, 0, 1, offset_y*L.speed)
			animate(L, transform=matrix(), time = last_delay)

		L.screen_loc = "CENTER-7:[round(L.offset_x,1)],CENTER-7:[round(L.offset_y,1)]"

/atom/movable/proc/update_parallax_contents()
	if(length(client_mobs_in_contents))
		for(var/mob/client_mob as anything in client_mobs_in_contents)
			if(length(client_mob?.client?.parallax_layers) && client_mob.hud_used)
				client_mob.hud_used.update_parallax()

/mob/proc/update_parallax_teleport()	//used for arrivals shuttle
	if(client?.eye && hud_used && length(client.parallax_layers))
		var/area/areaobj = get_area(client.eye)
		hud_used.set_parallax_movedir(areaobj.parallax_movedir, TRUE)

/atom/movable/screen/parallax_layer
	icon = 'icons/effects/parallax.dmi'
	var/speed = 1
	var/offset_x = 0
	var/offset_y = 0
	var/view_sized
	var/absolute = FALSE
	blend_mode = BLEND_ADD
	plane = PLANE_SPACE_PARALLAX
	screen_loc = "CENTER-7,CENTER-7"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT


/atom/movable/screen/parallax_layer/Initialize(mapload, view)
	. = ..()
	if (!view)
		view = world.view
	update_o(view)

/atom/movable/screen/parallax_layer/proc/update_o(view)
	if (!view)
		view = world.view

	var/list/viewscales = getviewsize(view)
	var/countx = CEILING((viewscales[1]/2)/(480/world.icon_size), 1)+1
	var/county = CEILING((viewscales[2]/2)/(480/world.icon_size), 1)+1
	var/list/new_overlays = new
	for(var/x in -countx to countx)
		for(var/y in -county to county)
			if(x == 0 && y == 0)
				continue
			var/mutable_appearance/texture_overlay = mutable_appearance(icon, icon_state)
			texture_overlay.transform = matrix(1, 0, x*480, 0, 1, y*480)
			new_overlays += texture_overlay
	cut_overlays()
	add_overlay(new_overlays)
	view_sized = view

/atom/movable/screen/parallax_layer/proc/update_status(mob/M)
	return

/atom/movable/screen/parallax_layer/layer_1
	icon_state = "layer1"
	speed = 1
	layer = 1
	color = "#999999"

/atom/movable/screen/parallax_layer/layer_1_2
	icon_state = "layer1_2"
	speed = 1
	layer = 1
	color = "#999999"

/atom/movable/screen/parallax_layer/layer_1_3
	icon_state = "layer1_3"
	speed = 1
	layer = 1
	color = "#999999"

/atom/movable/screen/parallax_layer/layer_1_4
	icon_state = "layer1_4"
	speed = 1
	layer = 1
	color = "#999999"

/atom/movable/screen/parallax_layer/layer_1_5
	icon_state = "layer1_5"
	speed = 1
	layer = 1
	color = "#999999"

/atom/movable/screen/parallax_layer/layer_2
	icon_state = "layer2"
	speed = 1.2
	layer = 2

/atom/movable/screen/parallax_layer/layer_3
	icon_state = "layer3"
	speed = 1.4
	layer = 3

/atom/movable/screen/parallax_layer/random
	blend_mode = BLEND_OVERLAY
	speed = 3
	layer = 5

/atom/movable/screen/parallax_layer/random/space_gas
	icon_state = "space_gas"
	blend_mode = 3

/atom/movable/screen/parallax_layer/random/space_gas/Initialize(mapload, view)
	. = ..()
	src.add_atom_colour(SSparallax.random_parallax_color, ADMIN_COLOUR_PRIORITY)

/atom/movable/screen/parallax_layer/random/asteroids
	icon_state = "asteroids"

/atom/movable/screen/parallax_layer/planet
	icon_state = "planet_lavaland"
	blend_mode = BLEND_OVERLAY
	absolute = TRUE //Status of seperation
	speed = 2.5
	layer = 4

/atom/movable/screen/parallax_layer/planet/update_status(mob/M)
	var/client/C = M.client
	var/turf/posobj = get_turf(C.eye)
	if(!posobj)
		return
	invisibility = is_station_level(posobj.z) ? 0 : INVISIBILITY_ABSTRACT

/atom/movable/screen/parallax_layer/planet/update_o()
	return //Shit won't move

/atom/movable/screen/parallax_layer/nebula
	icon_state = "nebula"
	speed = 2.5
	layer = 4
	blend_mode = 3
	color = "#ffff00"

/atom/movable/screen/parallax_layer/ice_surface
	icon_state = "ice_surface"
	speed = 4
	layer = 3

/atom/movable/screen/parallax_layer/fucking
	icon_state = "fucking"
	speed = 0
	layer = 4

/atom/movable/screen/parallax_layer/clouds
	icon_state = "clouds"
	speed = 2.5
	layer = 4
	blend_mode = 3

/atom/movable/screen/parallax_layer/cyberspess
	icon_state = "cyberspess"
	color = "#ff3333"
	speed = 4
	layer = 1

/atom/movable/screen/parallax_layer/shizospace
	icon_state = "shizospace"
	speed = 0
	layer = 1

/atom/movable/screen/parallax_layer/mazespace
	icon_state = "mazespace"
	color = "#ff3333"
	speed = 16
	alpha = 75
	layer = 2
