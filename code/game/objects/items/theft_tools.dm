//Items for nuke theft, supermatter theft traitor objective


// STEALING THE NUKE

//the nuke core - objective item
/obj/item/nuke_core
	name = "plutonium core"
	desc = "Extremely radioactive. Wear goggles."
	icon = 'icons/obj/nuke_tools.dmi'
	icon_state = "plutonium_core"
	inhand_icon_state = "plutoniumcore"
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	var/pulse = 0
	var/cooldown = 0
	var/pulseicon = "plutonium_core_pulse"

/obj/item/nuke_core/Initialize()
	. = ..()
	START_PROCESSING(SSobj, src)

/obj/item/nuke_core/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/item/nuke_core/attackby(obj/item/nuke_core_container/container, mob/user)
	if(istype(container))
		container.load(src, user)
	else
		return ..()

/obj/item/nuke_core/process()
	if(cooldown < world.time - 60)
		cooldown = world.time
		flick(pulseicon, src)
		radiation_pulse(src, 400, 2)

/obj/item/nuke_core/suicide_act(mob/user)
	user.visible_message(span_suicide("[user] is rubbing [src] against [user.ru_na()]self! It looks like [user.p_theyre()] trying to commit suicide!"))
	return (TOXLOSS)

//nuke core box, for carrying the core
/obj/item/nuke_core_container
	name = "nuke core container"
	desc = "Solid container for radioactive objects."
	icon = 'icons/obj/nuke_tools.dmi'
	icon_state = "core_container_empty"
	inhand_icon_state = "tile"
	lefthand_file = 'icons/mob/inhands/misc/tiles_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/tiles_righthand.dmi'
	var/obj/item/nuke_core/core

/obj/item/nuke_core_container/Destroy()
	QDEL_NULL(core)
	return ..()

/obj/item/nuke_core_container/proc/load(obj/item/nuke_core/ncore, mob/user)
	if(core || !istype(ncore))
		return FALSE
	ncore.forceMove(src)
	core = ncore
	icon_state = "core_container_loaded"
	to_chat(user, span_warning("Container is sealing..."))
	addtimer(CALLBACK(src, PROC_REF(seal)), 50)
	return TRUE

/obj/item/nuke_core_container/proc/seal()
	if(istype(core))
		STOP_PROCESSING(SSobj, core)
		icon_state = "core_container_sealed"
		playsound(src, 'sound/items/deconstruct.ogg', 60, TRUE)
		if(ismob(loc))
			to_chat(loc, span_warning("[capitalize(src.name)] is permanently sealed, [core] radiation is contained."))

/obj/item/nuke_core_container/attackby(obj/item/nuke_core/core, mob/user)
	if(istype(core))
		if(!user.temporarilyRemoveItemFromInventory(core))
			to_chat(user, span_warning("The [core] is stuck to your hand!"))
			return
		else
			load(core, user)
	else
		return ..()

//snowflake screwdriver, works as a key to start nuke theft, traitor only
/obj/item/screwdriver/nuke
	name = "screwdriver"
	desc = "A screwdriver with an ultra thin tip that's carefully designed to boost screwing speed."
	icon = 'white/valtos/icons/items.dmi'
	icon_state = "screwdriver_nuke"
	inhand_icon_state = "screwdriver_nuke"
	toolspeed = 0.5
	random_color = FALSE

/obj/item/paper/guides/antag/nuke_instructions
	info = "How to break into a Nanotrasen self-destruct terminal and remove its plutonium core:<br>\
	<ul>\
	<li>Use a screwdriver with a very thin tip (provided) to unscrew the terminal's front panel</li>\
	<li>Dislodge and remove the front panel with a crowbar</li>\
	<li>Cut the inner metal plate with a welding tool</li>\
	<li>Pry off the inner plate with a crowbar to expose the radioactive core</li>\
	<li>Use the core container to remove the plutonium core; the container will take some time to seal</li>\
	<li>???</li>\
	</ul>"

// STEALING SUPERMATTER

/obj/item/paper/guides/antag/supermatter_sliver
	info = "How to safely extract a supermatter sliver:<br>\
	<ul>\
	<li>Approach an active supermatter crystal with radiation shielded personal protective equipment. DO NOT MAKE PHYSICAL CONTACT.</li>\
	<li>Use a supermatter scalpel (provided) to slice off a sliver of the crystal.</li>\
	<li>Use supermatter extraction tongs (also provided) to safely pick up the sliver you sliced off.</li>\
	<li>Physical contact of any object with the sliver will dust the object, as well as yourself.</li>\
	<li>Use the tongs to place the sliver into the provided container, which will take some time to seal.</li>\
	<li>Get the hell out before the crystal delaminates.</li>\
	<li>???</li>\
	</ul>"

/obj/item/nuke_core/supermatter_sliver
	name = "supermatter sliver"
	desc = "A tiny, highly volatile sliver of a supermatter crystal. Do not handle without protection!"
	icon_state = "supermatter_sliver"
	inhand_icon_state = "supermattersliver"
	pulseicon = "supermatter_sliver_pulse"
	layer = ABOVE_MOB_LAYER
	plane = GAME_PLANE_UPPER


/obj/item/nuke_core/supermatter_sliver/attack_tk(mob/user) // no TK dusting memes
	return


/obj/item/nuke_core/supermatter_sliver/can_be_pulled(user) // no drag memes
	return FALSE

/obj/item/nuke_core/supermatter_sliver/attackby(obj/item/W, mob/living/user, params)
	if(istype(W, /obj/item/hemostat/supermatter))
		var/obj/item/hemostat/supermatter/tongs = W
		if (tongs.sliver)
			to_chat(user, span_warning("\The [tongs] is already holding a supermatter sliver!"))
			return FALSE
		forceMove(tongs)
		tongs.sliver = src
		tongs.update_icon()
		to_chat(user, span_notice("You carefully pick up [src] with [tongs]."))
	else if(istype(W, /obj/item/scalpel/supermatter) || istype(W, /obj/item/nuke_core_container/supermatter/)) // we don't want it to dust
		return
	else
		to_chat(user, span_notice("As it touches <b>[src.name]</b>, both <b>[src.name]</b> and [W] burst into dust!"))
		radiation_pulse(user, 100)
		playsound(src, 'sound/effects/supermatter.ogg', 50, TRUE)
		qdel(W)
		qdel(src)

/obj/item/nuke_core/supermatter_sliver/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	if(!isliving(hit_atom))
		return ..()
	var/mob/living/victim = hit_atom
	if(victim.incorporeal_move || victim.status_flags & GODMODE) //try to keep this in sync with supermatter's consume fail conditions
		return ..()
	if(throwingdatum?.thrower)
		var/mob/user = throwingdatum.thrower
		log_combat(throwingdatum?.thrower, hit_atom, "consumed", src)
		message_admins("[src] has consumed [key_name_admin(victim)] [ADMIN_JMP(src)], thrown by [key_name_admin(user)].")
		investigate_log("has consumed [key_name(victim)], thrown by [key_name(user)]", INVESTIGATE_SUPERMATTER)
	else
		message_admins("[src] has consumed [key_name_admin(victim)] [ADMIN_JMP(src)] via throw impact.")
		investigate_log("has consumed [key_name(victim)] via throw impact.", INVESTIGATE_SUPERMATTER)
	victim.visible_message(span_danger("As [victim] is hit by [src], both flash into dust and silence fills the room...") ,\
		span_userdanger("You're hit by [src] and everything suddenly goes silent.\n[src] flashes into dust, and soon as you can register this, you do as well.") ,\
		span_hear("Everything suddenly goes silent."))
	victim.dust()
	radiation_pulse(src, 500, 2)
	playsound(src, 'sound/effects/supermatter.ogg', 50, TRUE)
	qdel(src)

/obj/item/nuke_core/supermatter_sliver/pickup(mob/living/user)
	..()
	if(!isliving(user) || user.status_flags & GODMODE) //try to keep this in sync with supermatter's consume fail conditions
		return FALSE
	user.visible_message(span_danger("[user] reaches out and tries to pick up [src]. [user.ru_ego()] body starts to glow and bursts into flames before flashing into dust!") ,\
			span_userdanger("You reach for [src] with your hands. That was dumb.") ,\
			span_hear("Everything suddenly goes silent."))
	radiation_pulse(user, 500, 2)
	playsound(src, 'sound/effects/supermatter.ogg', 50, TRUE)
	user.dust()

/obj/item/nuke_core_container/supermatter
	name = "supermatter bin"
	desc = "A tiny receptacle that releases an inert hyper-noblium mix upon sealing, allowing a sliver of a supermatter crystal to be safely stored."
	var/obj/item/nuke_core/supermatter_sliver/sliver

/obj/item/nuke_core_container/supermatter/Destroy()
	QDEL_NULL(sliver)
	return ..()

/obj/item/nuke_core_container/supermatter/load(obj/item/hemostat/supermatter/T, mob/user)
	if(!istype(T) || !T.sliver)
		return FALSE
	T.sliver.forceMove(src)
	sliver = T.sliver
	T.sliver = null
	T.icon_state = "supermatter_tongs"
	icon_state = "core_container_loaded"
	to_chat(user, span_warning("Container is sealing..."))
	addtimer(CALLBACK(src, PROC_REF(seal)), 50)
	return TRUE

/obj/item/nuke_core_container/supermatter/seal()
	if(istype(sliver))
		STOP_PROCESSING(SSobj, sliver)
		icon_state = "core_container_sealed"
		playsound(src, 'sound/items/Deconstruct.ogg', 60, TRUE)
		if(ismob(loc))
			to_chat(loc, span_warning("[capitalize(src.name)] is permanently sealed, [sliver] is safely contained."))

/obj/item/nuke_core_container/supermatter/attackby(obj/item/hemostat/supermatter/tongs, mob/user)
	if(istype(tongs))
		//try to load shard into core
		load(tongs, user)
	else
		return ..()

/obj/item/scalpel/supermatter
	name = "supermatter scalpel"
	desc = "A scalpel with a fragile tip of condensed hyper-noblium gas, searingly cold to the touch, that can safely shave a sliver off a supermatter crystal."
	icon = 'icons/obj/nuke_tools.dmi'
	icon_state = "supermatter_scalpel"
	toolspeed = 0.5
	damtype = BURN
	usesound = 'sound/weapons/bladeslice.ogg'
	var/usesLeft

/obj/item/scalpel/supermatter/Initialize()
	. = ..()
	usesLeft = rand(2, 4)

/obj/item/hemostat/supermatter
	name = "supermatter extraction tongs"
	desc = "A pair of tongs made from condensed hyper-noblium gas, searingly cold to the touch, that can safely grip a supermatter sliver."
	icon = 'icons/obj/nuke_tools.dmi'
	icon_state = "supermatter_tongs"
	lefthand_file = 'icons/mob/inhands/items_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/items_righthand.dmi'
	inhand_icon_state = "supermatter_tongs"
	toolspeed = 0.75
	damtype = BURN
	var/obj/item/nuke_core/supermatter_sliver/sliver

/obj/item/hemostat/supermatter/Destroy()
	QDEL_NULL(sliver)
	return ..()

/obj/item/hemostat/supermatter/update_icon_state()
	icon_state = "supermatter_tongs[sliver ? "_loaded" : null]"
	inhand_icon_state = "supermatter_tongs[sliver ? "_loaded" : null]"

/obj/item/hemostat/supermatter/afterattack(atom/O, mob/user, proximity)
	. = ..()
	if(!sliver)
		return
	if(proximity && ismovable(O) && O != sliver)
		Consume(O, user)

/obj/item/hemostat/supermatter/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum) // no instakill supermatter javelins
	if(sliver)
		sliver.forceMove(loc)
		visible_message(span_notice("\The [sliver] falls out of <b>[src.name]</b> as it hits the ground."))
		sliver = null
		update_icon()
	return ..()

/obj/item/hemostat/supermatter/proc/Consume(atom/movable/AM, mob/living/user)
	if(ismob(AM))
		if(!isliving(AM))
			return
		var/mob/living/victim = AM
		if(victim.incorporeal_move || victim.status_flags & GODMODE) //try to keep this in sync with supermatter's consume fail conditions
			return
		victim.dust()
		message_admins("[src] has consumed [key_name_admin(victim)] [ADMIN_JMP(src)].")
		investigate_log("has consumed [key_name(victim)].", INVESTIGATE_SUPERMATTER)
	else if(istype(AM, /obj/singularity))
		return
	else
		investigate_log("has consumed [AM].", INVESTIGATE_SUPERMATTER)
		qdel(AM)
	if (user)
		log_combat(user, AM, "consumed", sliver, "via [src]")
		user.visible_message(span_danger("As [user] touches [AM] with <b>[src.name]</b>, both flash into dust and silence fills the room...") ,\
			span_userdanger("You touch [AM] with [src], and everything suddenly goes silent.\n[AM] and [sliver] flash into dust, and soon as you can register this, you do as well.") ,\
			span_hear("Everything suddenly goes silent."))
		user.dust()
	radiation_pulse(src, 500, 2)
	playsound(src, 'sound/effects/supermatter.ogg', 50, TRUE)
	QDEL_NULL(sliver)
	update_icon()
