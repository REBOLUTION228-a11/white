// It is a gizmo that flashes a small area

/obj/machinery/flasher
	name = "mounted flash"
	desc = "A wall-mounted flashbulb device."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "mflash1"
	max_integrity = 250
	integrity_failure = 0.4
	light_color = COLOR_WHITE
	light_power = FLASH_LIGHT_POWER
	damage_deflection = 10
	var/obj/item/assembly/flash/handheld/bulb
	var/id = null
	var/range = 2 //this is roughly the size of brig cell
	var/last_flash = 0 //Don't want it getting spammed like regular flashes
	var/strength = 100 //How knocked down targets are when flashed.
	var/base_state = "mflash"

/obj/machinery/flasher/directional/north
	dir = SOUTH
	pixel_y = 26

/obj/machinery/flasher/directional/south
	dir = NORTH
	pixel_y = -26

/obj/machinery/flasher/directional/east
	dir = WEST
	pixel_x = 26

/obj/machinery/flasher/directional/west
	dir = EAST
	pixel_x = -26
/obj/machinery/flasher/portable //Portable version of the flasher. Only flashes when anchored
	name = "portable flasher"
	desc = "A portable flashing device. Wrench to activate and deactivate. Cannot detect slow movements."
	icon_state = "pflash1-p"
	strength = 80
	anchored = FALSE
	base_state = "pflash"
	density = TRUE
	light_system = MOVABLE_LIGHT //Used as a flash here.
	light_range = FLASH_LIGHT_RANGE
	light_on = FALSE
	layer = ABOVE_OBJ_LAYER // no hiding it under a pile of laundry

/obj/machinery/flasher/Initialize(mapload, ndir = 0, built = 0)
	. = ..() // ..() is EXTREMELY IMPORTANT, never forget to add it
	if(built)
		setDir(ndir)
		pixel_x = (dir & 3)? 0 : (dir == 4 ? -28 : 28)
		pixel_y = (dir & 3)? (dir ==1 ? -28 : 28) : 0
	else
		bulb = new(src)


/obj/machinery/flasher/connect_to_shuttle(obj/docking_port/mobile/port, obj/docking_port/stationary/dock)
	id = "[port.id]_[id]"

/obj/machinery/flasher/Destroy()
	QDEL_NULL(bulb)
	return ..()

/obj/machinery/flasher/powered()
	if(!anchored || !bulb)
		return FALSE
	return ..()

/obj/machinery/flasher/update_icon_state()
	if (powered())
		if(bulb.burnt_out)
			icon_state = "[base_state]1-p"
		else
			icon_state = "[base_state]1"
	else
		icon_state = "[base_state]1-p"

//Don't want to render prison breaks impossible
/obj/machinery/flasher/attackby(obj/item/W, mob/user, params)
	add_fingerprint(user)
	if (W.tool_behaviour == TOOL_WIRECUTTER)
		if (bulb)
			user.visible_message(span_notice("[user] begins to disconnect [src] flashbulb.") , span_notice("You begin to disconnect [src] flashbulb..."))
			if(W.use_tool(src, user, 30, volume=50) && bulb)
				user.visible_message(span_notice("[user] disconnects [src] flashbulb!") , span_notice("You disconnect [src] flashbulb."))
				bulb.forceMove(loc)
				bulb = null
				power_change()

	else if (istype(W, /obj/item/assembly/flash/handheld))
		if (!bulb)
			if(!user.transferItemToLoc(W, src))
				return
			user.visible_message(span_notice("[user] installs [W] into [src].") , span_notice("You install [W] into [src]."))
			bulb = W
			power_change()
		else
			to_chat(user, span_warning("A flashbulb is already installed in [src]!"))

	else if (W.tool_behaviour == TOOL_WRENCH)
		if(!bulb)
			to_chat(user, span_notice("You start unsecuring the flasher frame..."))
			if(W.use_tool(src, user, 40, volume=50))
				to_chat(user, span_notice("You unsecure the flasher frame."))
				deconstruct(TRUE)
		else
			to_chat(user, span_warning("Remove a flashbulb from [src] first!"))
	else
		return ..()

//Let the AI trigger them directly.
/obj/machinery/flasher/attack_ai()
	if (anchored)
		return flash()

/obj/machinery/flasher/proc/flash()
	if (!powered() || !bulb)
		return

	if (bulb.burnt_out || (last_flash && world.time < src.last_flash + 150))
		return

	if(!bulb.flash_recharge(30)) //Bulb can burn out if it's used too often too fast
		power_change()
		return

	playsound(src.loc, 'sound/weapons/flash.ogg', 100, TRUE)
	flick("[base_state]_flash", src)
	set_light_on(TRUE)
	addtimer(CALLBACK(src, PROC_REF(flash_end)), FLASH_LIGHT_DURATION, TIMER_OVERRIDE|TIMER_UNIQUE)

	last_flash = world.time
	use_power(1000)

	var/flashed = FALSE
	for (var/mob/living/L in viewers(src, null))
		if (get_dist(src, L) > range)
			continue

		if(L.flash_act(affect_silicon = 1))
			L.log_message("was AOE flashed by an automated portable flasher",LOG_ATTACK)
			L.Paralyze(strength)
			flashed = TRUE

	if(flashed)
		bulb.times_used++

	return 1


/obj/machinery/flasher/proc/flash_end()
	set_light_on(FALSE)


/obj/machinery/flasher/emp_act(severity)
	. = ..()
	if(!(machine_stat & (BROKEN|NOPOWER)) && !(. & EMP_PROTECT_SELF))
		if(bulb && prob(75/severity))
			flash()
			bulb.burn_out()
			power_change()

/obj/machinery/flasher/obj_break(damage_flag)
	. = ..()
	if(. && bulb)
		bulb.burn_out()
		power_change()

/obj/machinery/flasher/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		if(bulb)
			bulb.forceMove(loc)
			bulb = null
		if(disassembled)
			var/obj/item/wallframe/flasher/F = new(get_turf(src))
			transfer_fingerprints_to(F)
			F.id = id
			playsound(loc, 'sound/items/deconstruct.ogg', 50, TRUE)
		else
			new /obj/item/stack/sheet/iron (loc, 2)
	qdel(src)

/obj/machinery/flasher/portable/Initialize()
	. = ..()
	proximity_monitor = new(src, 0)

/obj/machinery/flasher/portable/HasProximity(atom/movable/AM)
	if (last_flash && world.time < last_flash + 150)
		return

	if(istype(AM, /mob/living/carbon))
		var/mob/living/carbon/M = AM
		if (M.m_intent != (MOVE_INTENT_WALK || MOVE_INTENT_CRAWL) && anchored)
			flash()

/obj/machinery/flasher/portable/attackby(obj/item/W, mob/user, params)
	if (W.tool_behaviour == TOOL_WRENCH)
		W.play_tool_sound(src, 100)

		if (!anchored && !isinspace())
			to_chat(user, span_notice("[capitalize(src.name)] is now secured."))
			add_overlay("[base_state]-s")
			set_anchored(TRUE)
			power_change()
			proximity_monitor.SetRange(range)
		else
			to_chat(user, span_notice("[capitalize(src.name)] can now be moved."))
			cut_overlays()
			set_anchored(FALSE)
			power_change()
			proximity_monitor.SetRange(0)

	else
		return ..()

/obj/item/wallframe/flasher
	name = "mounted flash frame"
	desc = "Used for building wall-mounted flashers."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "mflash_frame"
	result_path = /obj/machinery/flasher
	var/id = null

/obj/item/wallframe/flasher/examine(mob/user)
	. = ..()
	. += "<hr><span class='notice'>Its channel ID is '[id]'.</span>"

/obj/item/wallframe/flasher/after_attach(obj/O)
	..()
	var/obj/machinery/flasher/F = O
	F.id = id
