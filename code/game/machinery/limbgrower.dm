/// The limbgrower. Makes organd and limbs with synthflesh and chems.
/// See [limbgrower_designs.dm] for everything we can make.
/obj/machinery/limbgrower
	name = "Биосинтезатор"
	desc = "Выращивает органы и конечности из синтетической плоти."
	icon = 'icons/obj/machines/limbgrower.dmi'
	icon_state = "limbgrower_idleoff"
	density = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = 100
	active_power_usage = 10000
	circuit = /obj/item/circuitboard/machine/limbgrower

	/// The category of limbs we're browing in our UI.
	var/selected_category = "human"
	/// If we're currently printing something.
	var/busy = FALSE
	/// How efficient our machine is. Better parts = less chemicals used and less power used. Range of 1 to 0.25.
	var/production_coefficient = 1
	/// How long it takes for us to print a limb. Affected by production_coefficient.
	var/production_speed = 3 SECONDS
	/// The design we're printing currently.
	var/datum/design/being_built
	/// Our internal techweb for limbgrower designs.
	var/datum/techweb/stored_research
	/// All the categories of organs we can print.
	var/list/categories = list("human", "lizard", "moth", "plasmaman", "ethereal", "other")

/obj/machinery/limbgrower/Initialize()
	create_reagents(100, OPENCONTAINER)
	stored_research = new /datum/techweb/specialized/autounlocking/limbgrower
	. = ..()
	AddComponent(/datum/component/plumbing/simple_demand)

/obj/machinery/limbgrower/ui_interact(mob/user, datum/tgui/ui)
	. = ..()
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Limbgrower")
		ui.open()

/obj/machinery/limbgrower/ui_state(mob/user)
	return GLOB.physical_state

/obj/machinery/limbgrower/ui_data(mob/user)
	var/list/data = list()

	for(var/datum/reagent/reagent_id in reagents.reagent_list)
		var/list/reagent_data = list(
			reagent_name = reagent_id.name,
			reagent_amount = reagent_id.volume,
			reagent_type = reagent_id.type
		)
		data["reagents"] += list(reagent_data)

	data["total_reagents"] = reagents.total_volume
	data["max_reagents"] = reagents.maximum_volume
	data["busy"] = busy

	return data

/obj/machinery/limbgrower/ui_static_data(mob/user)
	var/list/data = list()
	data["categories"] = list()

	var/species_categories = categories.Copy()
	for(var/species in species_categories)
		species_categories[species] = list()
	for(var/design_id in stored_research.researched_designs)
		var/datum/design/limb_design = SSresearch.techweb_design_by_id(design_id)
		for(var/found_category in species_categories)
			if(found_category in limb_design.category)
				species_categories[found_category] += limb_design

	for(var/category in species_categories)
		var/list/category_data = list(
			name = category,
			designs = list(),
		)
		for(var/datum/design/found_design in species_categories[category])
			var/list/all_reagents = list()
			for(var/reagent_typepath in found_design.reagents_list)
				var/datum/reagent/reagent_id = find_reagent_object_from_type(reagent_typepath)
				var/list/reagent_data = list(
					name = reagent_id.name,
					amount = (found_design.reagents_list[reagent_typepath] * production_coefficient),
				)
				all_reagents += list(reagent_data)

			category_data["designs"] += list(list(
				parent_category = category,
				name = found_design.name,
				id = found_design.id,
				needed_reagents = all_reagents,
			))

		data["categories"] += list(category_data)

	return data

/obj/machinery/limbgrower/on_deconstruction()
	for(var/obj/item/reagent_containers/glass/our_beaker in component_parts)
		reagents.trans_to(our_beaker, our_beaker.reagents.maximum_volume)
	..()

/obj/machinery/limbgrower/attackby(obj/item/user_item, mob/living/user, params)
	if (busy)
		to_chat(user, "<span class=\"alert\">The Limb Grower is busy. Please wait for completion of previous operation.</span>")
		return

	if(istype(user_item, /obj/item/disk/design_disk/limbs))
		user.visible_message(span_notice("[user] begins to load [user_item] in [src]...") ,
			span_notice("You begin to load designs from [user_item]...") ,
			span_hear("You hear the clatter of a floppy drive."))
		busy = TRUE
		var/obj/item/disk/design_disk/limbs/limb_design_disk = user_item
		if(do_after(user, 2 SECONDS, target = src))
			for(var/datum/design/found_design in limb_design_disk.blueprints)
				stored_research.add_design(found_design)
			update_static_data(user)
		busy = FALSE
		return

	if(default_deconstruction_screwdriver(user, "limbgrower_panelopen", "limbgrower_idleoff", user_item))
		ui_close(user)
		return

	if(panel_open && default_deconstruction_crowbar(user_item))
		return

	if(user.a_intent == INTENT_HARM) //so we can hit the machine
		return ..()

/obj/machinery/limbgrower/ui_act(action, list/params)
	. = ..()
	if(.)
		return

	if (busy)
		to_chat(usr, span_danger("The limb grower is busy. Please wait for completion of previous operation."))
		return

	switch(action)

		if("empty_reagent")
			reagents.del_reagent(text2path(params["reagent_type"]))
			. = TRUE

		if("make_limb")
			being_built = stored_research.isDesignResearchedID(params["design_id"])
			if(!being_built)
				CRASH("[src] was passed an invalid design id!")

			/// All the reagents we're using to make our organ.
			var/list/consumed_reagents_list = being_built.reagents_list.Copy()
			/// The amount of power we're going to use, based on how much reagent we use.
			var/power = 0

			for(var/reagent_id in consumed_reagents_list)
				consumed_reagents_list[reagent_id] *= production_coefficient
				if(!reagents.has_reagent(reagent_id, consumed_reagents_list[reagent_id]))
					audible_message(span_notice("The [src] buzzes."))
					playsound(src, 'white/valtos/sounds/error1.ogg', 50, FALSE)
					return

				power = max(2000, (power + consumed_reagents_list[reagent_id]))

			busy = TRUE
			use_power(power)
			flick("limbgrower_fill",src)
			icon_state = "limbgrower_idleon"
			selected_category = params["active_tab"]
			addtimer(CALLBACK(src, PROC_REF(build_item), consumed_reagents_list), production_speed * production_coefficient)
			. = TRUE

	return

/*
 * The process of beginning to build a limb or organ.
 * Goes through and sanity checks that we actually have enough reagent to build our item.
 * Then, remove those reagents from our reagents datum.
 *
 * After the reagents are handled, we can proceede with making the limb or organ. (Limbs are handled in a separate proc)
 *
 * modified_consumed_reagents_list - the list of reagents we will consume on build, modified by the production coefficient.
 */
/obj/machinery/limbgrower/proc/build_item(list/modified_consumed_reagents_list)
	for(var/reagent_id in modified_consumed_reagents_list)
		if(!reagents.has_reagent(reagent_id, modified_consumed_reagents_list[reagent_id]))
			audible_message(span_notice("The [src] buzzes."))
			playsound(src, 'white/valtos/sounds/error1.ogg', 50, FALSE)
			break

		reagents.remove_reagent(reagent_id, modified_consumed_reagents_list[reagent_id])

	var/built_typepath = being_built.build_path
	// If we have a bodypart, we need to initialize the limb on its own. Otherwise we can build it here.
	if(ispath(built_typepath, /obj/item/bodypart))
		build_limb(built_typepath)
	else
		new built_typepath(loc)

	busy = FALSE
	flick("limbgrower_unfill", src)
	icon_state = "limbgrower_idleoff"

/*
 * The process of putting together a limb.
 * This is called from after we remove the reagents, so this proc is just initializing the limb type.
 *
 * This proc handles skin / mutant color, greyscaling, names and descriptions, and various other limb creation steps.
 *
 * buildpath - the path of the bodypart we're building.
 */
/obj/machinery/limbgrower/proc/build_limb(buildpath)
	/// The limb we're making with our buildpath, so we can edit it.
	var/obj/item/bodypart/limb = new buildpath(loc)
	/// Species with greyscale limbs.
	var/list/greyscale_species = list("human", "lizard", "ethereal")
	if(selected_category in greyscale_species) //Species with greyscale parts should be included here
		if(selected_category == "human") //humans don't use the full colour spectrum, they use random_skin_tone
			limb.skin_tone = random_skin_tone()
		else
			limb.species_color = random_short_color()
		limb.icon = 'icons/mob/human_parts_greyscale.dmi'
		limb.should_draw_greyscale = TRUE
	else
		limb.icon = 'icons/mob/human_parts.dmi'

	// Set this limb up using the species name and body zone
	limb.icon_state = "[selected_category]_[limb.body_zone]"
	limb.name = "\improper biosynthetic [selected_category] [parse_zone(limb.body_zone)]"
	limb.desc = "A synthetically produced [selected_category] limb, grown in a tube. This one is for the [parse_zone(limb.body_zone)]."
	limb.species_id = selected_category
	limb.update_icon_dropped()
	limb.original_owner = WEAKREF(src)  //prevents updating the icon, so a lizard arm on a human stays a lizard arm etc.

/obj/machinery/limbgrower/RefreshParts()
	reagents.maximum_volume = 0
	for(var/obj/item/reagent_containers/glass/our_beaker in component_parts)
		reagents.maximum_volume += our_beaker.volume
		our_beaker.reagents.trans_to(src, our_beaker.reagents.total_volume)
	production_coefficient = 1.25
	for(var/obj/item/stock_parts/manipulator/our_manipulator in component_parts)
		production_coefficient -= our_manipulator.rating * 0.25
	production_coefficient = clamp(production_coefficient, 0, 1) // coefficient goes from 1 -> 0.75 -> 0.5 -> 0.25

/obj/machinery/limbgrower/examine(mob/user)
	. = ..()
	if(in_range(user, src) || isobserver(user))
		. += "<hr><span class='notice'>The status display reads: Storing up to <b>[reagents.maximum_volume]u</b> of reagents.<br>Reagent consumption rate at <b>[production_coefficient * 100]%</b>.</span>"

/*
 * Checks our reagent list to see if a design can be built.
 *
 * limb_design - the design we're checking for buildability.
 *
 * returns TRUE if we have enough reagent to build it. Returns FALSE if we do not.
 */
/obj/machinery/limbgrower/proc/can_build(datum/design/limb_design)
	for(var/datum/reagent/reagent_id in limb_design.reagents_list)
		if(!reagents.has_reagent(reagent_id, limb_design.reagents_list[reagent_id] * production_coefficient))
			return FALSE
	return TRUE

/// Emagging a limbgrower allows you to build synthetic armblades.
/obj/machinery/limbgrower/emag_act(mob/user)
	if(obj_flags & EMAGGED)
		return
	for(var/design_id in SSresearch.techweb_designs)
		var/datum/design/found_design = SSresearch.techweb_design_by_id(design_id)
		if((found_design.build_type & LIMBGROWER) && ("emagged" in found_design.category))
			stored_research.add_design(found_design)
	to_chat(user, span_warning("A warning flashes onto the screen, stating that safety overrides have been deactivated!"))
	obj_flags |= EMAGGED
	update_static_data(user)
