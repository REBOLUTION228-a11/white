


/*
field_generator power level display
The icon used for the field_generator need to have 6 icon states
named 'Field_Gen +p[num]' where 'num' ranges from 1 to 6

The power level is displayed using overlays. The current displayed power level is stored in 'powerlevel'.
The overlay in use and the powerlevel variable must be kept in sync.  A powerlevel equal to 0 means that
no power level overlay is currently in the overlays list.
-Aygar
*/

#define field_generator_max_power 250

#define FG_OFFLINE 0
#define FG_CHARGING 1
#define FG_ONLINE 2

//field generator construction defines
#define FG_UNSECURED 0
#define FG_SECURED 1
#define FG_WELDED 2

/obj/machinery/field/generator
	name = "генератор поля"
	desc = "Огромная машина, которая создаёт защитное поле за счёт поступающей на неё энергии."
	icon = 'icons/obj/machines/field_generator.dmi'
	icon_state = "Field_Gen"
	anchored = FALSE
	density = TRUE
	use_power = NO_POWER_USE
	max_integrity = 500
	CanAtmosPass = ATMOS_PASS_YES
	//100% immune to lasers and energy projectiles since it absorbs their energy.
	armor = list(MELEE = 25, BULLET = 10, LASER = 100, ENERGY = 100, BOMB = 0, BIO = 0, RAD = 0, FIRE = 50, ACID = 70)
	var/power_level = 0
	var/active = FG_OFFLINE
	var/power = 20  // Current amount of power
	var/state = FG_UNSECURED
	var/warming_up = 0
	var/list/obj/machinery/field/containment/fields
	var/list/obj/machinery/field/generator/connected_gens
	var/clean_up = 0

/obj/machinery/field/generator/update_overlays()
	. = ..()
	if(warming_up)
		. += "+a[warming_up]"
	if(LAZYLEN(fields))
		. += "+on"
	if(power_level)
		. += "+p[power_level]"


/obj/machinery/field/generator/Initialize()
	. = ..()
	fields = list()
	connected_gens = list()
	RegisterSignal(src, COMSIG_ATOM_SINGULARITY_TRY_MOVE, PROC_REF(block_singularity_if_active))

/obj/machinery/field/generator/anchored/Initialize()
	. = ..()
	set_anchored(TRUE)

/obj/machinery/field/generator/ComponentInitialize()
	. = ..()
	AddElement(/datum/element/empprotection, EMP_PROTECT_SELF | EMP_PROTECT_WIRES)

/obj/machinery/field/generator/process()
	if(active == FG_ONLINE)
		calc_power()

/obj/machinery/field/generator/interact(mob/user)
	if(state == FG_WELDED)
		if(get_dist(src, user) <= 1)//Need to actually touch the thing to turn it on
			if(active >= FG_CHARGING)
				to_chat(user, span_warning("Не могу выключить <b>[src]</b> пока он заряжен!"))
				return 1
			else
				user.visible_message(span_notice("<b>[user]</b> включает <b>[src]</b>.") , \
					span_notice("Включаю <b>[src]</b>.") , \
					span_hear("Слышу тяжёлое жужжание."))
				turn_on()
				investigate_log("<font color='green'>activated</font> by [key_name(user)].", INVESTIGATE_SINGULO)

				add_fingerprint(user)
	else
		to_chat(user, span_warning("<b>[src]</b> должен быть надёжно закреплён на полу!"))

/obj/machinery/field/generator/set_anchored(anchorvalue)
	. = ..()
	if(isnull(.))
		return
	if(active)
		turn_off()
	state = anchorvalue ? FG_SECURED : FG_UNSECURED

/obj/machinery/field/generator/can_be_unfasten_wrench(mob/user, silent)
	if(active)
		if(!silent)
			to_chat(user, span_warning("Надо бы отключить <b>[src]</b> для начала!"))
		return FAILED_UNFASTEN

	else if(state == FG_WELDED)
		if(!silent)
			to_chat(user, span_warning("<b>[src]</b> приварен к полу намертво!"))
		return FAILED_UNFASTEN

	return ..()

/obj/machinery/field/generator/wrench_act(mob/living/user, obj/item/I)
	..()
	default_unfasten_wrench(user, I)
	return TRUE

/obj/machinery/field/generator/welder_act(mob/living/user, obj/item/I)
	. = ..()
	if(active)
		to_chat(user, span_warning("<b>[src]</b> должен быть выключен!"))
		return TRUE

	switch(state)
		if(FG_UNSECURED)
			to_chat(user, span_warning("<b>[src]</b> должен быть прикручен к полу!"))

		if(FG_SECURED)
			if(!I.tool_start_check(user, amount=0))
				return TRUE
			user.visible_message(span_notice("<b>[user]</b> начинает приваривать <b>[src]</b> к полу.") , \
				span_notice("Начинаю приваривать <b>[src]</b> к полу...") , \
				span_hear("Слышу сварку."))
			if(I.use_tool(src, user, 20, volume=50) && state == FG_SECURED)
				state = FG_WELDED
				to_chat(user, span_notice("Привариваю генератор поля к полу."))

		if(FG_WELDED)
			if(!I.tool_start_check(user, amount=0))
				return TRUE
			user.visible_message(span_notice("<b>[user]</b> начинает отваривать <b>[src]</b> от пола.") , \
				span_notice("Начинаю отваривать <b>[src]</b> от пола...") , \
				span_hear("Слышу сварку."))
			if(I.use_tool(src, user, 20, volume=50) && state == FG_WELDED)
				state = FG_SECURED
				to_chat(user, span_notice("Отвариваю <b>[src]</b> от пола."))

	return TRUE


/obj/machinery/field/generator/attack_animal(mob/living/simple_animal/M)
	if(M.environment_smash & ENVIRONMENT_SMASH_RWALLS && active == FG_OFFLINE && state != FG_UNSECURED)
		set_anchored(FALSE)
		M.visible_message(span_warning("<b>[M.name]</b> вырывает <b>[src.name]</b> с места!"))
	else
		..()
	if(!anchored)
		step(src, get_dir(M, src))

/obj/machinery/field/generator/blob_act(obj/structure/blob/B)
	if(active)
		return FALSE
	else
		return ..()

/obj/machinery/field/generator/bullet_act(obj/projectile/Proj)
	if(Proj.flag != BULLET)
		power = min(power + Proj.damage, field_generator_max_power)
		check_power_level()
	. = ..()


/obj/machinery/field/generator/Destroy()
	cleanup()
	return ..()

/**
 *The power level is displayed using overlays. The current displayed power level is stored in 'powerlevel'.
 *The overlay in use and the powerlevel variable must be kept in sync.  A powerlevel equal to 0 means that
 *no power level overlay is currently in the overlays list.
 */
/obj/machinery/field/generator/proc/check_power_level()
	var/new_level = round(6 * power / field_generator_max_power)
	if(new_level != power_level)
		power_level = new_level
		update_icon()

/obj/machinery/field/generator/proc/turn_off()
	active = FG_OFFLINE
	CanAtmosPass = ATMOS_PASS_YES
	air_update_turf(TRUE)
	INVOKE_ASYNC(src, PROC_REF(cleanup))
	addtimer(CALLBACK(src, PROC_REF(cool_down)), 50)

/obj/machinery/field/generator/proc/cool_down()
	if(active || warming_up <= 0)
		return
	warming_up--
	update_icon()
	if(warming_up > 0)
		addtimer(CALLBACK(src, PROC_REF(cool_down)), 50)

/obj/machinery/field/generator/proc/turn_on()
	active = FG_CHARGING
	addtimer(CALLBACK(src, PROC_REF(warm_up)), 50)

/obj/machinery/field/generator/proc/warm_up()
	if(!active)
		return
	warming_up++
	update_icon()
	if(warming_up >= 3)
		start_fields()
	else
		addtimer(CALLBACK(src, PROC_REF(warm_up)), 50)

/obj/machinery/field/generator/proc/calc_power(set_power_draw)
	var/power_draw = 2 + fields.len
	if(set_power_draw)
		power_draw = set_power_draw

	if(draw_power(round(power_draw/2,1)))
		check_power_level()
		return TRUE
	else
		visible_message(span_danger("<b>[capitalize(name)]</b> вырубается!") , span_hear("Что-то вырубилось."))
		turn_off()
		investigate_log("ran out of power and <font color='red'>deactivated</font>", INVESTIGATE_SINGULO)
		power = 0
		check_power_level()
		return FALSE

//This could likely be better, it tends to start loopin if you have a complex generator loop setup.  Still works well enough to run the engine fields will likely recode the field gens and fields sometime -Mport
/obj/machinery/field/generator/proc/draw_power(draw = 0, failsafe = FALSE, obj/machinery/field/generator/G = null, obj/machinery/field/generator/last = null)
	if((G && (G == src)) || (failsafe >= 8))//Loopin, set fail
		return FALSE
	else
		failsafe++

	if(power >= draw)//We have enough power
		power -= draw
		return TRUE

	else//Need more power
		draw -= power
		power = 0
		for(var/CG in connected_gens)
			var/obj/machinery/field/generator/FG = CG
			if(FG == last)//We just asked you
				continue
			if(G)//Another gen is askin for power and we dont have it
				if(FG.draw_power(draw,failsafe,G,src))//Can you take the load
					return TRUE
				else
					return FALSE
			else//We are askin another for power
				if(FG.draw_power(draw,failsafe,src,src))
					return TRUE
				else
					return FALSE


/obj/machinery/field/generator/proc/start_fields()
	if(state != FG_WELDED || !anchored)
		turn_off()
		return
	move_resist = INFINITY
	CanAtmosPass = ATMOS_PASS_NO
	air_update_turf(TRUE)
	addtimer(CALLBACK(src, PROC_REF(setup_field), 1), 1)
	addtimer(CALLBACK(src, PROC_REF(setup_field), 2), 2)
	addtimer(CALLBACK(src, PROC_REF(setup_field), 4), 3)
	addtimer(CALLBACK(src, PROC_REF(setup_field), 8), 4)
	addtimer(VARSET_CALLBACK(src, active, FG_ONLINE), 5)

/obj/machinery/field/generator/proc/setup_field(NSEW)
	var/turf/T = loc
	if(!istype(T))
		return FALSE

	var/obj/machinery/field/generator/G = null
	var/steps = 0
	if(!NSEW)//Make sure its ran right
		return FALSE
	for(var/dist in 0 to 7) // checks out to 8 tiles away for another generator
		T = get_step(T, NSEW)
		if(T.density)//We cant shoot a field though this
			return FALSE

		G = locate(/obj/machinery/field/generator) in T
		if(G)
			steps -= 1
			if(!G.active)
				return FALSE
			break

		for(var/TC in T.contents)
			var/atom/A = TC
			if(ismob(A))
				continue
			if(A.density)
				return FALSE

		steps++

	if(!G)
		return FALSE

	T = loc
	for(var/dist in 0 to steps) // creates each field tile
		var/field_dir = get_dir(T,get_step(G.loc, NSEW))
		T = get_step(T, NSEW)
		if(!locate(/obj/machinery/field/containment) in T)
			var/obj/machinery/field/containment/CF = new(T)
			CF.set_master(src,G)
			CF.setDir(field_dir)
			fields += CF
			G.fields += CF
			for(var/mob/living/L in T)
				CF.on_entered(src, L)

	connected_gens |= G
	G.connected_gens |= src
	shield_floor(TRUE)
	update_icon()


/obj/machinery/field/generator/proc/cleanup()
	clean_up = 1
	for (var/F in fields)
		qdel(F)

	shield_floor(FALSE)

	for(var/CG in connected_gens)
		var/obj/machinery/field/generator/FG = CG
		FG.connected_gens -= src
		if(!FG.clean_up)//Makes the other gens clean up as well
			FG.cleanup()
		connected_gens -= FG
	clean_up = 0
	update_icon()

	move_resist = initial(move_resist)

/obj/machinery/field/generator/proc/shield_floor(create)
	if(connected_gens.len < 2)
		return
	var/CGcounter
	for(CGcounter = 1; CGcounter < connected_gens.len, CGcounter++)

		var/list/CGList = ((connected_gens[CGcounter].connected_gens & connected_gens[CGcounter+1].connected_gens)^src)
		if(!CGList.len)
			return
		var/obj/machinery/field/generator/CG = CGList[1]

		var/x_step
		var/y_step
		if(CG.x > x && CG.y > y)
			for(x_step=x; x_step <= CG.x; x_step++)
				for(y_step=y; y_step <= CG.y; y_step++)
					place_floor(locate(x_step,y_step,z),create)
		else if(CG.x > x && CG.y < y)
			for(x_step=x; x_step <= CG.x; x_step++)
				for(y_step=y; y_step >= CG.y; y_step--)
					place_floor(locate(x_step,y_step,z),create)
		else if(CG.x < x && CG.y > y)
			for(x_step=x; x_step >= CG.x; x_step--)
				for(y_step=y; y_step <= CG.y; y_step++)
					place_floor(locate(x_step,y_step,z),create)
		else
			for(x_step=x; x_step >= CG.x; x_step--)
				for(y_step=y; y_step >= CG.y; y_step--)
					place_floor(locate(x_step,y_step,z),create)


/obj/machinery/field/generator/proc/place_floor(Location,create)
	if(create && !locate(/obj/effect/shield) in Location)
		new/obj/effect/shield(Location)
	else if(!create)
		var/obj/effect/shield/S=locate(/obj/effect/shield) in Location
		if(S)
			qdel(S)

/obj/machinery/field/generator/proc/block_singularity_if_active()
	SIGNAL_HANDLER

	if (active)
		return SINGULARITY_TRY_MOVE_BLOCK

/obj/machinery/field/generator/shock(mob/living/user)
	if(fields.len)
		..()

/obj/machinery/field/generator/bump_field(atom/movable/AM as mob|obj)
	if(fields.len)
		..()

#undef FG_UNSECURED
#undef FG_SECURED
#undef FG_WELDED

#undef FG_OFFLINE
#undef FG_CHARGING
#undef FG_ONLINE
