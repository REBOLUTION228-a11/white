// Note: BYOND is object oriented. There is no reason for this to be copy/pasted blood code.

/obj/effect/decal/cleanable/robot_debris
	name = "куски робота"
	desc = "Бесполезная куча мусора... <i>или нет?</i>"
	icon = 'icons/mob/robots.dmi'
	icon_state = "gib1"
	layer = LOW_OBJ_LAYER
	random_icon_states = list("gib1", "gib2", "gib3", "gib4", "gib5", "gib6", "gib7")
	blood_state = BLOOD_STATE_OIL
	bloodiness = BLOOD_AMOUNT_PER_DECAL
	mergeable_decal = FALSE
	beauty = -50
	clean_type = CLEAN_TYPE_BLOOD

/obj/effect/decal/cleanable/robot_debris/Initialize()
	. = ..()
	RegisterSignal(src, COMSIG_MOVABLE_PIPE_EJECTING, PROC_REF(on_pipe_eject))

/obj/effect/decal/cleanable/robot_debris/proc/streak(list/directions, mapload=FALSE)
	var/direction = pick(directions)
	var/delay = 2
	var/range = pick(1, 200; 2, 150; 3, 50; 4, 17; 50) //the 3% chance of 50 steps is intentional and played for laughs.
	if(!step_to(src, get_step(src, direction), 0))
		return
	if(mapload)
		for (var/i in 1 to range)
			if (prob(40))
				new /obj/effect/decal/cleanable/oil/streak(src.loc)
			if (!step_to(src, get_step(src, direction), 0))
				break
		return

	var/datum/move_loop/loop = SSmove_manager.move_to_dir(src, get_step(src, direction), delay = delay, timeout = range * delay, priority = MOVEMENT_ABOVE_SPACE_PRIORITY)
	RegisterSignal(loop, COMSIG_MOVELOOP_POSTPROCESS, PROC_REF(spread_movement_effects))

/obj/effect/decal/cleanable/robot_debris/proc/spread_movement_effects(datum/move_loop/has_target/source)
	SIGNAL_HANDLER
	if (prob(40))
		new /obj/effect/decal/cleanable/oil/streak(src.loc)
	else if (prob(10))
		var/datum/effect_system/spark_spread/s = new /datum/effect_system/spark_spread
		s.set_up(3, 1, src)
		s.start()

/obj/effect/decal/cleanable/robot_debris/proc/on_pipe_eject(atom/source, direction)
	SIGNAL_HANDLER

	var/list/dirs
	if(direction)
		dirs = list(direction, turn(direction, -45), turn(direction, 45))
	else
		dirs = GLOB.alldirs.Copy()

	streak(dirs)

/obj/effect/decal/cleanable/robot_debris/ex_act()
	return

/obj/effect/decal/cleanable/robot_debris/limb
	icon_state = "gibarm"
	random_icon_states = list("gibarm", "gibleg")

/obj/effect/decal/cleanable/robot_debris/up
	icon_state = "gibup1"
	random_icon_states = list("gib1", "gib2", "gib3", "gib4", "gib5", "gib6", "gib7","gibup1","gibup1")

/obj/effect/decal/cleanable/robot_debris/down
	icon_state = "gibdown1"
	random_icon_states = list("gib1", "gib2", "gib3", "gib4", "gib5", "gib6", "gib7","gibdown1","gibdown1")

/obj/effect/decal/cleanable/oil
	name = "моторное масло"
	desc = "Чёрное и грязное. Видимо Бипскай снова нагадил."
	icon = 'icons/mob/robots.dmi'
	icon_state = "floor1"
	random_icon_states = list("floor1", "floor2", "floor3", "floor4", "floor5", "floor6", "floor7")
	blood_state = BLOOD_STATE_OIL
	bloodiness = BLOOD_AMOUNT_PER_DECAL
	beauty = -100
	clean_type = CLEAN_TYPE_BLOOD

/obj/effect/decal/cleanable/oil/Initialize()
	. = ..()
	reagents.add_reagent(/datum/reagent/fuel/oil, 30)

/obj/effect/decal/cleanable/oil/attackby(obj/item/I, mob/living/user)
	var/attacked_by_hot_thing = I.get_temperature()
	if(attacked_by_hot_thing)
		visible_message(span_warning("[user] пытается поджечь [src.name] используя [I]!") , span_warning("Пытаюсь поджечь [src.name] используя [I]."))
		log_combat(user, src, (attacked_by_hot_thing < 480) ? "tried to ignite" : "ignited", I)
		fire_act(attacked_by_hot_thing)
		return
	return ..()

/obj/effect/decal/cleanable/oil/fire_act(exposed_temperature, exposed_volume)
	if(exposed_temperature < 480)
		return
	visible_message(span_danger("[capitalize(src.name)] загорается!"))
	var/turf/T = get_turf(src)
	qdel(src)
	new /obj/effect/hotspot(T)

/obj/effect/decal/cleanable/oil/streak
	icon_state = "streak1"
	random_icon_states = list("streak1", "streak2", "streak3", "streak4", "streak5")
	beauty = -50

/obj/effect/decal/cleanable/oil/slippery/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/slippery, 80, (NO_SLIP_WHEN_WALKING | SLIDE))
