/// Station home gateway
GLOBAL_DATUM(the_gateway, /obj/machinery/gateway/centerstation)
/// List of possible gateway destinations.
GLOBAL_LIST_EMPTY(gateway_destinations)

/**
 * Corresponds to single entry in gateway control.
 *
 * Will NOT be added automatically to GLOB.gateway_destinations list.
 */
/datum/gateway_destination
	var/name = "Unknown Destination"
	var/wait = 0 /// How long after roundstart this destination becomes active
	var/enabled = TRUE /// If disabled, the destination won't be available
	var/hidden = FALSE /// Will not show on gateway controls at all.

/* Can a gateway link to this destination right now. */
/datum/gateway_destination/proc/is_available()
	return enabled && (world.time - SSticker.round_start_time >= wait)

/* Returns user-friendly description why you can't connect to this destination, displayed in UI */
/datum/gateway_destination/proc/get_available_reason()
	. = "Unreachable"
	if(world.time - SSticker.round_start_time < wait)
		. = "Connection desynchronized. Recalibration in progress."

/* Check if the movable is allowed to arrive at this destination (exile implants mostly) */
/datum/gateway_destination/proc/incoming_pass_check(atom/movable/AM)
	return TRUE

/* Get the actual turf we'll arrive at */
/datum/gateway_destination/proc/get_target_turf()
	CRASH("get target turf not implemented for this destination type")

/* Called after moving the movable to target turf */
/datum/gateway_destination/proc/post_transfer(atom/movable/AM)
	if (ismob(AM))
		var/mob/M = AM
		if (M.client)
			M.client.move_delay = max(world.time + 5, M.client.move_delay)

/* Called when gateway activates with this destination. */
/datum/gateway_destination/proc/activate(obj/machinery/gateway/activated)
	return

/* Called when gateway targeting this destination deactivates. */
/datum/gateway_destination/proc/deactivate(obj/machinery/gateway/deactivated)
	return

/* Returns data used by gateway controller ui */
/datum/gateway_destination/proc/get_ui_data()
	. = list()
	.["ref"] = REF(src)
	.["name"] = name
	.["available"] = is_available()
	.["reason"] = get_available_reason()
	if(wait)
		.["timeout"] = max(1 - (wait - (world.time - SSticker.round_start_time)) / wait, 0)

/* Destination is another gateway */
/datum/gateway_destination/gateway
	/// The gateway this destination points at
	var/obj/machinery/gateway/target_gateway

/* We set the target gateway target to activator gateway */
/datum/gateway_destination/gateway/activate(obj/machinery/gateway/activated)
	if(!target_gateway.target)
		target_gateway.activate(activated)

/* We turn off the target gateway if it's linked with us */
/datum/gateway_destination/gateway/deactivate(obj/machinery/gateway/deactivated)
	if(target_gateway.target == deactivated.destination)
		target_gateway.deactivate()

/datum/gateway_destination/gateway/is_available()
	return ..() && target_gateway.calibrated && !target_gateway.target && target_gateway.powered()

/datum/gateway_destination/gateway/get_available_reason()
	. = ..()
	if(!target_gateway.calibrated)
		. = "Exit gateway malfunction. Manual recalibration required."
	if(target_gateway.target)
		. = "Exit gateway in use."
	if(!target_gateway.powered())
		. = "Exit gateway unpowered."

/datum/gateway_destination/gateway/get_target_turf()
	return get_step(target_gateway.portal,SOUTH)

/datum/gateway_destination/gateway/post_transfer(atom/movable/AM)
	. = ..()
	addtimer(CALLBACK(AM,TYPE_PROC_REF(/atom/movable, setDir),SOUTH),0)

/* Special home destination, so we can check exile implants */
/datum/gateway_destination/gateway/home

/datum/gateway_destination/gateway/home/incoming_pass_check(atom/movable/AM)
	if(isliving(AM))
		if(check_exile_implant(AM))
			return FALSE
	else
		for(var/mob/living/L in AM.contents)
			if(check_exile_implant(L))
				target_gateway.say("Rejecting [AM]: Exile implant detected in contained lifeform.")
				return FALSE
	if(AM.has_buckled_mobs())
		for(var/mob/living/L in AM.buckled_mobs)
			if(check_exile_implant(L))
				target_gateway.say("Rejecting [AM]: Exile implant detected in close proximity lifeform.")
				return FALSE
	return TRUE

/datum/gateway_destination/gateway/home/proc/check_exile_implant(mob/living/L)
	for(var/obj/item/implant/exile/E in L.implants)//Checking that there is an exile implant
		to_chat(L, span_userdanger("Механизм врат обнаружил твой имплант ссылки и не пропускает тебя."))
		return TRUE
	return FALSE


/* Destination is one ore more turfs - created by landmarks */
/datum/gateway_destination/point
	var/list/target_turfs = list()
	/// Used by away landmarks
	var/id

/datum/gateway_destination/point/get_target_turf()
	return pick(target_turfs)

/* Dense invisible object starting the teleportation. Created by gateways on activation. */
/obj/effect/gateway_portal_bumper
	var/obj/machinery/gateway/gateway
	density = TRUE
	invisibility = INVISIBILITY_ABSTRACT
	var/cooldown = 1 SECONDS
	var/last_bump = 0

/obj/effect/gateway_portal_bumper/Bumped(atom/movable/AM)
	if(get_dir(src,AM) == SOUTH && world.time > last_bump + cooldown)
		last_bump = world.time
		gateway.Transfer(AM)

/obj/effect/gateway_portal_bumper/Destroy(force)
	. = ..()
	gateway = null

/obj/machinery/gateway
	name = "Врата"
	desc = "Таинственные врата, построенные кем-то неизвестным. Позволяют путешествовать в отдаленные места на сверхсветовых скоростях."
	icon = 'icons/obj/machines/gateway.dmi'
	icon_state = "portal_frame"
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF

	// 3x2 offset by one row
	pixel_x = -32
	pixel_y = -32
	bound_height = 64
	bound_width = 96
	bound_x = -32
	bound_y = 0
	density = TRUE

	use_power = IDLE_POWER_USE
	idle_power_usage = 100
	active_power_usage = 5000

	var/calibrated = TRUE
	/// Type of instanced gateway destination, needs to be subtype of /datum/gateway_destination/gateway
	var/destination_type = /datum/gateway_destination/gateway
	/// Name of the generated destination
	var/destination_name = "Unknown Gateway"
	/// This is our own destination, pointing at this gateway
	var/datum/gateway_destination/gateway/destination
	/// This is current active destination
	var/datum/gateway_destination/target
	/// bumper object, the thing that starts actual teleport
	var/obj/effect/gateway_portal_bumper/portal
	/// Visual object for handling the viscontents
	var/obj/effect/gateway_portal_effect/portal_visuals

/obj/machinery/gateway/Initialize()
	generate_destination()
	update_icon()
	portal_visuals = new
	vis_contents += portal_visuals
	return ..()

/obj/machinery/gateway/Destroy()
	destination.target_gateway = null
	GLOB.gateway_destinations -= destination
	destination = null
	return ..()

/obj/machinery/gateway/proc/generate_destination()
	destination = new destination_type
	destination.name = destination_name
	destination.target_gateway = src
	GLOB.gateway_destinations += destination

/obj/machinery/gateway/proc/deactivate()
	var/datum/gateway_destination/dest = target
	target = null
	dest.deactivate(src)
	QDEL_NULL(portal)
	update_use_power(IDLE_POWER_USE)
	update_appearance()
	portal_visuals.reset_visuals()

/obj/machinery/gateway/process()
	if((machine_stat & (NOPOWER)) && use_power)
		if(target)
			deactivate()
		return
/obj/machinery/gateway/safe_throw_at(atom/target, range, speed, mob/thrower, spin = TRUE, diagonals_first = FALSE, datum/callback/callback, force = MOVE_FORCE_STRONG, gentle = FALSE)
	return

/obj/machinery/gateway/proc/generate_bumper()
	portal = new(get_turf(src))
	portal.gateway = src

/obj/machinery/gateway/proc/activate(datum/gateway_destination/D)
	if(!powered() || target)
		return
	target = D
	target.activate(destination)
	portal_visuals.setup_visuals(target)
	generate_bumper()
	update_use_power(ACTIVE_POWER_USE)
	update_appearance()

/obj/machinery/gateway/proc/Transfer(atom/movable/AM)
	if(!target || !target.incoming_pass_check(AM))
		return
	AM.forceMove(target.get_target_turf())
	target.post_transfer(AM)

/* Station's primary gateway */
/obj/machinery/gateway/centerstation
	destination_type = /datum/gateway_destination/gateway/home
	destination_name = "Home Gateway"

/obj/machinery/gateway/centerstation/Initialize()
	. = ..()
	if(!GLOB.the_gateway)
		GLOB.the_gateway = src

/obj/machinery/gateway/centerstation/Destroy()
	if(GLOB.the_gateway == src)
		GLOB.the_gateway = null
	return ..()

/obj/machinery/gateway/multitool_act(mob/living/user, obj/item/I)
	if(calibrated)
		to_chat(user, span_alert("Врата откалиброваны, больше ничего делать не нужно."))
	else
		to_chat(user, "<span class='boldnotice'>Успешная рекалибровка!</span>: Системы врат налажены. Теперь через них можно проходить.")
		calibrated = TRUE
	return TRUE

/* Doesn't need control console or power, always links to home when interacting. */
/obj/machinery/gateway/away
	density = TRUE
	use_power = NO_POWER_USE

/obj/machinery/gateway/away/interact(mob/user, special_state)
	. = ..()
	if(!target)
		if(!GLOB.the_gateway)
			to_chat(user,span_warning("Начальные врата не отвечают!"))
		if(GLOB.the_gateway.target)
			GLOB.the_gateway.deactivate() //this will turn the home gateway off so that it's free for us to connect to
		activate(GLOB.the_gateway.destination)
	else
		deactivate()

/* Gateway control computer */
/obj/machinery/computer/gateway_control
	name = "Интерфейс врат"
	desc = "Удобный человеческому глазу интерфейс для врат, стоящих рядом."
	var/obj/machinery/gateway/G

/obj/machinery/computer/gateway_control/Initialize(mapload, obj/item/circuitboard/C)
	. = ..()
	try_to_linkup()

/obj/machinery/computer/gateway_control/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Gateway", name)
		ui.open()

/obj/machinery/computer/gateway_control/ui_data(mob/user)
	. = ..()
	.["gateway_present"] = G
	.["gateway_found"]   = GLOB.isGatewayLoaded
	.["gateway_status"]  = G ? G.powered() : FALSE
	.["current_target"]  = G?.target?.get_ui_data()
	var/list/destinations = list()
	if(G)
		for(var/datum/gateway_destination/D in GLOB.gateway_destinations)
			if(D == G.destination)
				continue
			destinations += list(D.get_ui_data())
	.["destinations"] = destinations

/obj/machinery/computer/gateway_control/ui_act(action, list/params)
	. = ..()
	if(.)
		return
	switch(action)
		if("linkup")
			try_to_linkup()
			return TRUE
		if("activate")
			var/datum/gateway_destination/D = locate(params["destination"]) in GLOB.gateway_destinations
			try_to_connect(D)
			return TRUE
		if("deactivate")
			if(G?.target)
				G.deactivate()
			return TRUE
		if("find_new")
			if(!GLOB.isGatewayLoaded)
				message_admins("[ADMIN_LOOKUPFLW(usr)] активирует врата.")
				log_game("[key_name(usr)] активирует врата.")
				priority_announce("Началась операция по поиску новых врат в отдалённых секторах. Это займёт некоторое время.", "Звёздные врата", 'white/valtos/sounds/trevoga4.ogg')
				GLOB.isGatewayLoaded = TRUE
				createRandomZlevel()
			return TRUE

/obj/machinery/computer/gateway_control/proc/try_to_linkup()
	G = locate(/obj/machinery/gateway) in view(7,get_turf(src))

/obj/machinery/computer/gateway_control/proc/try_to_connect(datum/gateway_destination/D)
	if(!D || !G)
		return
	if(!D.is_available() || G.target)
		return
	G.activate(D)

/obj/item/paper/fluff/gateway
	info = "Поздравляем,<br><br>Ваша станция была выбрана для нашего проекта \"Врата\".<br><br>Мы пришлем вам оборудование в следующем квартале.<br> Оборудуйте защищенное помещение по требованиям, приведенным в прикрепленных документах.<br><br>--Исследовательский Центр Блюспейса NanoTrasen"
	name = "Конфиденциальная переписка, стр 1"

/obj/effect/gateway_portal_effect
	appearance_flags = KEEP_TOGETHER|TILE_BOUND|PIXEL_SCALE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	vis_flags = VIS_INHERIT_ID
	layer = GATEWAY_UNDERLAY_LAYER //Slightly lower than gateway itself
	var/alpha_icon = 'icons/obj/machines/gateway.dmi'
	var/alpha_icon_state = "portal_mask"
	var/datum/gateway_destination/our_destination


/obj/effect/gateway_portal_effect/proc/setup_visuals(datum/gateway_destination/D)
	our_destination = D
	update_portal_filters()

/obj/effect/gateway_portal_effect/proc/reset_visuals()
	our_destination = null
	update_portal_filters()

/obj/effect/gateway_portal_effect/proc/update_portal_filters()
	clear_filters()
	vis_contents = null

	if(!our_destination)
		return

	add_filter("portal_alpha", 1, list("type" = "alpha", "icon" = icon(alpha_icon, alpha_icon_state), "x" = 32, "y" = 32))
	add_filter("portal_blur", 1, list("type" = "blur", "size" = 0.5))
	add_filter("portal_ripple", 1, list("type" = "ripple", "size" = 2, "radius" = 1, "falloff" = 1, "y" = 7))

	animate(get_filter("portal_ripple"), time = 1.3 SECONDS, loop = -1, easing = LINEAR_EASING, radius = 32)

	var/turf/center_turf = our_destination.get_target_turf()
	if(center_turf)
		vis_contents += block(locate(center_turf.x - 1, center_turf.y - 1, center_turf.z), locate(center_turf.x + 1, center_turf.y + 1, center_turf.z))
