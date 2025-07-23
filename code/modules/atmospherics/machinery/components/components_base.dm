// So much of atmospherics.dm was used solely by components, so separating this makes things all a lot cleaner.
// On top of that, now people can add component-speciic procs/vars if they want!

/obj/machinery/atmospherics/components
	hide = FALSE

	var/welded = FALSE //Used on pumps and scrubbers
	var/showpipe = TRUE
	var/shift_underlay_only = TRUE //Layering only shifts underlay?

	var/update_parents_after_rebuild = FALSE

	var/list/datum/pipeline/parents
	var/list/datum/gas_mixture/airs
	///Handles whether the custom reconcilation handling should be used
	var/custom_reconcilation = FALSE

	var/startingvolume = 200

/obj/machinery/atmospherics/components/New()
	parents = new(device_type)
	airs = new(device_type)

	..()

	for(var/i in 1 to device_type)
		if(airs[i])
			continue
		var/datum/gas_mixture/component_mixture = new
		component_mixture.set_volume(startingvolume)
		airs[i] = component_mixture

/obj/machinery/atmospherics/components/Initialize()
	. = ..()

	if(hide)
		RegisterSignal(src, COMSIG_OBJ_HIDE, PROC_REF(hide_pipe))

// Iconnery

/obj/machinery/atmospherics/components/proc/update_icon_nopipes()
	return

/obj/machinery/atmospherics/components/proc/hide_pipe(datum/source, covered)
	showpipe = !covered
	update_icon()

/obj/machinery/atmospherics/components/update_icon()
	update_icon_nopipes()

	underlays.Cut()

	color = null
	plane = showpipe ? GAME_PLANE : FLOOR_PLANE

	if(!showpipe)
		return ..()

	var/connected = 0 //Direction bitset

	for(var/i in 1 to device_type) //adds intact pieces
		if(!nodes[i])
			continue
		var/obj/machinery/atmospherics/node = nodes[i]
		var/image/img = get_pipe_underlay("pipe_intact", get_dir(src, node), pipe_color)
		underlays += img
		connected |= img.dir

	for(var/direction in GLOB.cardinals)
		if((initialize_directions & direction) && !(connected & direction))
			underlays += get_pipe_underlay("pipe_exposed", direction, pipe_color)

	if(!shift_underlay_only)
		PIPING_LAYER_SHIFT(src, piping_layer)
	return ..()

/obj/machinery/atmospherics/components/proc/get_pipe_underlay(state, dir, color = null)
	if(color)
		. = getpipeimage('icons/obj/atmospherics/components/binary_devices.dmi', state, dir, color, piping_layer = shift_underlay_only ? piping_layer : 3)
	else
		. = getpipeimage('icons/obj/atmospherics/components/binary_devices.dmi', state, dir, piping_layer = shift_underlay_only ? piping_layer : 3)

// Pipenet stuff; housekeeping

/obj/machinery/atmospherics/components/nullify_node(i)
	if(parents[i])
		nullify_pipenet(parents[i])
	airs[i] = null
	return ..()

/obj/machinery/atmospherics/components/on_construction()
	. = ..()
	update_parents()

/obj/machinery/atmospherics/components/build_network()
	for(var/i in 1 to device_type)
		if(!parents[i])
			parents[i] = new /datum/pipeline()
			var/datum/pipeline/P = parents[i]
			P.build_pipeline(src)

/obj/machinery/atmospherics/components/proc/nullify_pipenet(datum/pipeline/reference)
	if(!reference)
		CRASH("nullify_pipenet(null) called by [type] on [COORD(src)]")

	for (var/i in 1 to parents.len)
		if (parents[i] == reference)
			reference.other_airs -= airs[i] // Disconnects from the pipeline side
			parents[i] = null // Disconnects from the machinery side.

	reference.other_atmos_machines -= src

	if(!length(reference.other_atmos_machines) && !length(reference.members))
		if(QDESTROYING(reference))
			CRASH("nullify_pipenet() called on qdeleting [reference]")
		qdel(reference)

// We should return every air sharing a parent
/obj/machinery/atmospherics/components/return_pipenet_airs(datum/pipeline/reference)
	var/list/returned_air = list()

	for (var/i in 1 to parents.len)
		if (parents[i] == reference)
			returned_air += airs[i]
	return returned_air

/obj/machinery/atmospherics/components/pipeline_expansion(datum/pipeline/reference)
	if(reference)
		return list(nodes[parents.Find(reference)])
	return ..()

/obj/machinery/atmospherics/components/set_pipenet(datum/pipeline/reference, obj/machinery/atmospherics/A)
	parents[nodes.Find(A)] = reference

/obj/machinery/atmospherics/components/return_pipenet(obj/machinery/atmospherics/A = nodes[1]) //returns parents[1] if called without argument
	return parents[nodes.Find(A)]

/obj/machinery/atmospherics/components/replace_pipenet(datum/pipeline/Old, datum/pipeline/New)
	parents[parents.Find(Old)] = New

/obj/machinery/atmospherics/components/unsafe_pressure_release(mob/user, pressures)
	..()

	var/turf/T = get_turf(src)
	if(T)
		//Remove the gas from airs and assume it
		var/datum/gas_mixture/environment = T.return_air()
		var/lost = null
		var/times_lost = 0
		for(var/i in 1 to device_type)
			var/datum/gas_mixture/air = airs[i]
			lost += pressures*environment.return_volume()/(air.return_temperature() * R_IDEAL_GAS_EQUATION)
			times_lost++
		var/shared_loss = lost/times_lost

		for(var/i in 1 to device_type)
			var/datum/gas_mixture/air = airs[i]
			T.assume_air_moles(air, shared_loss)

/obj/machinery/atmospherics/components/proc/safe_input(title, text, default_set)
	var/new_value = input(usr,text,title,default_set) as num|null

	if (isnull(new_value))
		return default_set

	if(usr.canUseTopic(src))
		return new_value

	return default_set

// Helpers

/obj/machinery/atmospherics/components/proc/update_parents()
	if(!SSair.initialized)
		return
	if(rebuilding)
		update_parents_after_rebuild = TRUE
		return
	for(var/i in 1 to device_type)
		var/datum/pipeline/parent = parents[i]
		if(!parent)
			SSair.add_to_rebuild_queue(src)
			continue
		parent.update = TRUE

/obj/machinery/atmospherics/components/returnPipenets()
	. = list()
	for(var/i in 1 to device_type)
		. += return_pipenet(nodes[i])

/obj/machinery/atmospherics/components/proc/return_pipenets_for_reconcilation(datum/pipeline/requester)
	return list()

/obj/machinery/atmospherics/components/proc/return_airs_for_reconcilation(datum/pipeline/requester)
	return list()

// UI Stuff

/obj/machinery/atmospherics/components/ui_status(mob/user)
	if(allowed(user))
		return ..()
	to_chat(user, span_danger("Доступ запрещён."))
	return UI_CLOSE

// Tool acts


/obj/machinery/atmospherics/components/proc/disconnect_nodes()
	for(var/i in 1 to device_type)
		var/obj/machinery/atmospherics/node = nodes[i]
		if(node)
			if(src in node.nodes) //Only if it's actually connected. On-pipe version would is one-sided.
				node.disconnect(src)
			nodes[i] = null
		if(parents[i])
			nullify_pipenet(parents[i])

/obj/machinery/atmospherics/components/proc/connect_nodes()
	atmos_init()
	for(var/i in 1 to device_type)
		var/obj/machinery/atmospherics/node = nodes[i]
		if(node)
			node.atmos_init()
			node.add_member(src)
	SSair.add_to_rebuild_queue(src)

/obj/machinery/atmospherics/components/proc/change_nodes_connection(disconnect)
	if(disconnect)
		disconnect_nodes()
		return
	connect_nodes()

/obj/machinery/atmospherics/components/return_analyzable_air()
	return airs

/obj/machinery/atmospherics/components/paint(paint_color)
	if(paintable)
		add_atom_colour(paint_color, FIXED_COLOUR_PRIORITY)
		pipe_color = paint_color
		update_node_icon()
	return paintable
