/// Is `observed_atom` in a mob's field of view? This takes blindness, nearsightness and FOV into consideration
/mob/living/proc/in_fov(atom/observed_atom, ignore_self = FALSE)
	if(ignore_self && observed_atom == src)
		return TRUE
	if(is_blind())
		return FALSE
	. = FALSE
	var/turf/my_turf = get_turf(src) //Because being inside contents of something will cause our x,y to not be updated
	// If turf doesn't exist, then we wouldn't get a fov check called by `play_fov_effect` or presumably other new stuff that might check this.
	//  ^ If that case has changed and you need that check, add it.
	var/rel_x = observed_atom.x - my_turf.x
	var/rel_y = observed_atom.y - my_turf.y
	if(fov_view)
		if(rel_x >= -1 && rel_x <= 1 && rel_y >= -1 && rel_y <= 1) //Cheap way to check inside that 3x3 box around you
			return TRUE //Also checks if both are 0 to stop division by zero

		// Get the vector length so we can create a good directional vector
		var/vector_len = sqrt(abs(rel_x) ** 2 + abs(rel_y) ** 2)

		/// Getting a direction vector
		var/dir_x
		var/dir_y
		switch(dir)
			if(SOUTH)
				dir_x = 0
				dir_y = -vector_len
			if(NORTH)
				dir_x = 0
				dir_y = vector_len
			if(EAST)
				dir_x = vector_len
				dir_y = 0
			if(WEST)
				dir_x = -vector_len
				dir_y = 0

		///Calculate angle
		var/angle = arccos((dir_x * rel_x + dir_y * rel_y) / (sqrt(dir_x**2 + dir_y**2) * sqrt(rel_x**2 + rel_y**2)))

		/// Calculate vision angle and compare
		var/vision_angle = (360 - fov_view) / 2
		if(angle < vision_angle)
			. = TRUE
	else
		. = TRUE

	// Handling nearsightnedness
	if(. && HAS_TRAIT(src, TRAIT_NEARSIGHT))
		//Checking if our dude really is suffering from nearsightness! (very nice nearsightness code)
		if(iscarbon(src))
			var/mob/living/carbon/carbon_me = src
			if(carbon_me.glasses)
				var/obj/item/clothing/glasses/glass = carbon_me.glasses
				if(glass.vision_correction)
					return
		if((rel_x >= NEARSIGHTNESS_FOV_BLINDNESS || rel_x <= -NEARSIGHTNESS_FOV_BLINDNESS) || (rel_y >= NEARSIGHTNESS_FOV_BLINDNESS || rel_y <= -NEARSIGHTNESS_FOV_BLINDNESS))
			return FALSE

/// Updates the applied FOV value and applies the handler to client if able
/mob/living/proc/update_fov()
	var/highest_fov
	if(CONFIG_GET(flag/native_fov))
		highest_fov = native_fov
	for(var/trait_type in fov_traits)
		var/fov_type = fov_traits[trait_type]
		if(fov_type > highest_fov)
			highest_fov = fov_type
	fov_view = highest_fov
	update_fov_client()

/// Updates the FOV for the client.
/mob/living/proc/update_fov_client()
	if(!client)
		return
	var/datum/component/fov_handler/fov_component = GetComponent(/datum/component/fov_handler)
	if(fov_view)
		if(!fov_component)
			AddComponent(/datum/component/fov_handler, fov_view)
		else
			fov_component.set_fov_angle(fov_view)
	else if(fov_component)
		qdel(fov_component)

/// Adds a trait which limits a user's FOV
/mob/living/proc/add_fov_trait(source, type)
	LAZYINITLIST(fov_traits)
	fov_traits[source] = type
	update_fov()

/// Removes a trait which limits a user's FOV
/mob/living/proc/remove_fov_trait(source, type)
	if(!fov_traits) //Clothing equip/unequip is bad code and invokes this several times
		return
	fov_traits -= source
	UNSETEMPTY(fov_traits)
	update_fov()

/// Plays a visual effect representing a sound cue for people with vision obstructed by FOV or blindness
/proc/play_fov_effect(atom/center, range, icon_state, dir = SOUTH, ignore_self = FALSE, angle = 0)
	var/turf/anchor_point = get_turf(center)
	var/image/fov_image
	for(var/mob/living/living_mob in get_hearers_in_view(range, center))
		var/client/mob_client = living_mob.client
		if(!mob_client)
			continue
		if(HAS_TRAIT(living_mob, TRAIT_DEAF)) //Deaf people can't hear sounds so no sound indicators
			continue
		if(living_mob.in_fov(center, ignore_self))
			continue
		if(!fov_image) //Make the image once we found one recipient to receive it
			fov_image = image(icon = 'icons/effects/fov/fov_effects.dmi', icon_state = icon_state, loc = anchor_point)
			fov_image.plane = FULLSCREEN_PLANE
			fov_image.layer = FOV_EFFECTS_LAYER
			fov_image.dir = dir
			fov_image.appearance_flags = RESET_COLOR | RESET_TRANSFORM
			if(angle)
				var/matrix/matrix = new
				matrix.Turn(angle)
				fov_image.transform = matrix
			fov_image.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
		mob_client.images += fov_image
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(remove_image_from_client), fov_image, mob_client), 30)

/atom/movable/screen/fov_blocker
	icon = 'icons/effects/fov/field_of_view.dmi'
	icon_state = "90"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	plane = FIELD_OF_VISION_BLOCKER_PLANE
	screen_loc = "BOTTOM,LEFT"

/atom/movable/screen/fov_shadow
	icon = 'icons/effects/fov/field_of_view.dmi'
	icon_state = "90_v"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	plane = ABOVE_LIGHTING_PLANE
	screen_loc = "BOTTOM,LEFT"
