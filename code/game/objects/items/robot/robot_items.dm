/**********************************************************************
						Cyborg Spec Items
***********************************************************************/
/obj/item/borg
	icon = 'icons/mob/robot_items.dmi'


/obj/item/borg/stun
	name = "electrically-charged arm"
	icon_state = "elecarm"
	var/charge_cost = 30

/obj/item/borg/stun/attack(mob/living/M, mob/living/user)
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		if(H.check_shields(src, 0, "[M] [name]", MELEE_ATTACK))
			playsound(M, 'sound/weapons/genhit.ogg', 50, TRUE)
			return FALSE
	if(iscyborg(user))
		var/mob/living/silicon/robot/R = user
		if(!R.cell.use(charge_cost))
			return

	user.do_attack_animation(M)
	M.Paralyze(100)
	M.apply_effect(EFFECT_STUTTER, 5)

	M.visible_message(span_danger("[user] prods [M] with [src]!") , \
					span_userdanger("[user] prods you with [src]!"))

	playsound(loc, 'sound/weapons/egloves.ogg', 50, TRUE, -1)

	log_combat(user, M, "stunned", src, "(INTENT: [uppertext(user.a_intent)])")

/obj/item/borg/cyborghug
	name = "hugging module"
	icon_state = "hugmodule"
	desc = "For when a someone really needs a hug."
	var/mode = 0 //0 = Hugs 1 = "Hug" 2 = Shock 3 = CRUSH
	var/ccooldown = 0
	var/scooldown = 0
	var/shockallowed = FALSE//Can it be a stunarm when emagged. Only PK borgs get this by default.
	var/boop = FALSE

/obj/item/borg/cyborghug/attack_self(mob/living/user)
	if(iscyborg(user))
		var/mob/living/silicon/robot/P = user
		if(P.emagged&&shockallowed == 1)
			if(mode < 3)
				mode++
			else
				mode = 0
		else if(mode < 1)
			mode++
		else
			mode = 0
	switch(mode)
		if(0)
			to_chat(user, "Power reset. Hugs!")
		if(1)
			to_chat(user, "Power increased!")
		if(2)
			to_chat(user, "BZZT. Electrifying arms...")
		if(3)
			to_chat(user, "ERROR: ARM ACTUATORS OVERLOADED.")

/obj/item/borg/cyborghug/attack(mob/living/M, mob/living/silicon/robot/user)
	if(M == user)
		return
	switch(mode)
		if(0)
			if(M.health >= 0)
				if(isanimal(M))
					M.attack_hand(user) //This enables borgs to get the floating heart icon and mob emote from simple_animal's that have petbonus == true.
					return
				if(user.zone_selected == BODY_ZONE_HEAD)
					user.visible_message(span_notice("[user] playfully boops [M] on the head!") , \
									span_notice("You playfully boop [M] on the head!"))
					user.do_attack_animation(M, ATTACK_EFFECT_BOOP)
					playsound(loc, 'sound/weapons/tap.ogg', 50, TRUE, -1)
				else if(ishuman(M))
					if(user.body_position == LYING_DOWN)
						user.visible_message(span_notice("[user] shakes [M] trying to get [M.ru_na()] up!") , \
										span_notice("You shake [M] trying to get [M.ru_na()] up!"))
					else
						user.visible_message(span_notice("[user] hugs [M] to make [M.ru_na()] feel better!") , \
								span_notice("You hug [M] to make [M.ru_na()] feel better!"))
					if(M.resting)
						M.set_resting(FALSE, TRUE)
				else
					user.visible_message(span_notice("[user] pets [M]!") , \
							span_notice("You pet [M]!"))
				playsound(loc, 'sound/weapons/thudswoosh.ogg', 50, TRUE, -1)
		if(1)
			if(M.health >= 0)
				if(ishuman(M))
					if(M.body_position == LYING_DOWN)
						user.visible_message(span_notice("[user] shakes [M] trying to get [M.ru_na()] up!") , \
										span_notice("You shake [M] trying to get [M.ru_na()] up!"))
					else if(user.zone_selected == BODY_ZONE_HEAD)
						user.visible_message(span_warning("[user] bops [M] on the head!") , \
										span_warning("You bop [M] on the head!"))
						user.do_attack_animation(M, ATTACK_EFFECT_PUNCH)
					else
						user.visible_message(span_warning("[user] hugs [M] in a firm bear-hug! [M] looks uncomfortable...") , \
								span_warning("You hug [M] firmly to make [M.ru_na()] feel better! [M] looks uncomfortable..."))
					if(M.resting)
						M.set_resting(FALSE, TRUE)
				else
					user.visible_message(span_warning("[user] bops [M] on the head!") , \
							span_warning("You bop [M] on the head!"))
				playsound(loc, 'sound/weapons/tap.ogg', 50, TRUE, -1)
		if(2)
			if(scooldown < world.time)
				if(M.health >= 0)
					if(ishuman(M))
						M.electrocute_act(5, "[user]", flags = SHOCK_NOGLOVES)
						user.visible_message(span_userdanger("[user] electrocutes [M] with [user.ru_ego()] touch!") , \
							span_danger("You electrocute [M] with your touch!"))
					else
						if(!iscyborg(M))
							M.adjustFireLoss(10)
							user.visible_message(span_userdanger("[user] shocks [M]!") , \
								span_danger("You shock [M]!"))
						else
							user.visible_message(span_userdanger("[user] shocks [M]. It does not seem to have an effect") , \
								span_danger("You shock [M] to no effect."))
					playsound(loc, 'sound/effects/sparks2.ogg', 50, TRUE, -1)
					user.cell.charge -= 500
					scooldown = world.time + 20
		if(3)
			if(ccooldown < world.time)
				if(M.health >= 0)
					if(ishuman(M))
						user.visible_message(span_userdanger("[user] crushes [M] in [user.ru_ego()] grip!") , \
							span_danger("You crush [M] in your grip!"))
					else
						user.visible_message(span_userdanger("[user] crushes [M]!") , \
								span_danger("You crush [M]!"))
					playsound(loc, 'sound/weapons/smash.ogg', 50, TRUE, -1)
					M.adjustBruteLoss(15)
					user.cell.charge -= 300
					ccooldown = world.time + 10

/obj/item/borg/cyborghug/peacekeeper
	shockallowed = TRUE

/obj/item/borg/cyborghug/medical
	boop = TRUE

/obj/item/borg/charger
	name = "power connector"
	icon_state = "charger_draw"
	item_flags = NOBLUDGEON
	var/mode = "draw"
	var/static/list/charge_machines = typecacheof(list(/obj/machinery/cell_charger, /obj/machinery/recharger, /obj/machinery/recharge_station, /obj/machinery/mech_bay_recharge_port))
	var/static/list/charge_items = typecacheof(list(/obj/item/stock_parts/cell, /obj/item/gun/energy))

/obj/item/borg/charger/update_icon_state()
	icon_state = "charger_[mode]"

/obj/item/borg/charger/attack_self(mob/user)
	if(mode == "draw")
		mode = "charge"
	else
		mode = "draw"
	to_chat(user, span_notice("You toggle [src] to \"[mode]\" mode."))
	update_icon()

/obj/item/borg/charger/afterattack(obj/item/target, mob/living/silicon/robot/user, proximity_flag)
	. = ..()
	if(!proximity_flag || !iscyborg(user))
		return
	if(mode == "draw")
		if(is_type_in_list(target, charge_machines))
			var/obj/machinery/M = target
			if((M.machine_stat & (NOPOWER|BROKEN)) || !M.anchored)
				to_chat(user, span_warning("[M] is unpowered!"))
				return

			to_chat(user, span_notice("You connect to [M] power line..."))
			while(do_after(user, 15, target = M, progress = 0))
				if(!user || !user.cell || mode != "draw")
					return

				if((M.machine_stat & (NOPOWER|BROKEN)) || !M.anchored)
					break

				if(!user.cell.give(150))
					break

				M.use_power(200)

			to_chat(user, span_notice("You stop charging yourself."))

		else if(is_type_in_list(target, charge_items))
			var/obj/item/stock_parts/cell/cell = target
			if(!istype(cell))
				cell = locate(/obj/item/stock_parts/cell) in target
			if(!cell)
				to_chat(user, span_warning("[target] has no power cell!"))
				return

			if(istype(target, /obj/item/gun/energy))
				var/obj/item/gun/energy/E = target
				if(!E.can_charge)
					to_chat(user, span_warning("[target] has no power port!"))
					return

			if(!cell.charge)
				to_chat(user, span_warning("[target] has no power!"))


			to_chat(user, span_notice("You connect to [target] power port..."))

			while(do_after(user, 15, target = target, progress = 0))
				if(!user || !user.cell || mode != "draw")
					return

				if(!cell || !target)
					return

				if(cell != target && cell.loc != target)
					return

				var/draw = min(cell.charge, cell.chargerate*0.5, user.cell.maxcharge-user.cell.charge)
				if(!cell.use(draw))
					break
				if(!user.cell.give(draw))
					break
				target.update_icon()

			to_chat(user, span_notice("You stop charging yourself."))

	else if(is_type_in_list(target, charge_items))
		var/obj/item/stock_parts/cell/cell = target
		if(!istype(cell))
			cell = locate(/obj/item/stock_parts/cell) in target
		if(!cell)
			to_chat(user, span_warning("[target] has no power cell!"))
			return

		if(istype(target, /obj/item/gun/energy))
			var/obj/item/gun/energy/E = target
			if(!E.can_charge)
				to_chat(user, span_warning("[target] has no power port!"))
				return

		if(cell.charge >= cell.maxcharge)
			to_chat(user, span_warning("[target] is already charged!"))

		to_chat(user, span_notice("You connect to [target] power port..."))

		while(do_after(user, 15, target = target, progress = 0))
			if(!user || !user.cell || mode != "charge")
				return

			if(!cell || !target)
				return

			if(cell != target && cell.loc != target)
				return

			var/draw = min(user.cell.charge, cell.chargerate*0.5, cell.maxcharge-cell.charge)
			if(!user.cell.use(draw))
				break
			if(!cell.give(draw))
				break
			target.update_icon()

		to_chat(user, span_notice("You stop charging [target]."))

/obj/item/harmalarm
	name = "\improper Sonic Harm Prevention Tool"
	desc = "Releases a harmless blast that confuses most organics. For when the harm is JUST TOO MUCH."
	icon = 'icons/obj/device.dmi'
	icon_state = "megaphone"
	var/cooldown = 0

/obj/item/harmalarm/emag_act(mob/user)
	obj_flags ^= EMAGGED
	if(obj_flags & EMAGGED)
		to_chat(user, span_red("You short out the safeties on [src]!"))
	else
		to_chat(user, span_red("You reset the safeties on [src]!"))

/obj/item/harmalarm/attack_self(mob/user)
	var/safety = !(obj_flags & EMAGGED)
	if(cooldown > world.time)
		to_chat(user, span_red("The device is still recharging!"))
		return

	if(iscyborg(user))
		var/mob/living/silicon/robot/R = user
		if(!R.cell || R.cell.charge < 1200)
			to_chat(user, span_warning("You don't have enough charge to do this!"))
			return
		R.cell.charge -= 1000
		if(R.emagged)
			safety = FALSE

	if(safety == TRUE)
		user.visible_message(span_boldwarning("[user] blares out a near-deafening siren from its speakers!"), \
			span_userdanger("The siren pierces your hearing and confuses you!") , \
			span_danger("The siren pierces your hearing!"))
		for(var/mob/living/carbon/M in get_hearers_in_view(9, user))
			if(M.get_ear_protection() == FALSE)
				M.add_confusion(6)
		audible_message(span_boldwarning("HUMAN HARM"))
		playsound(get_turf(src), 'sound/ai/harmalarm.ogg', 70, 3)
		cooldown = world.time + 200
		user.log_message("used a Cyborg Harm Alarm in [AREACOORD(user)]", LOG_ATTACK)
		if(iscyborg(user))
			var/mob/living/silicon/robot/R = user
			to_chat(R.connected_ai, "<br><span class='notice'>NOTICE - Peacekeeping 'HARM ALARM' used by: [user]</span><br>")

		return

	if(safety == FALSE)
		user.audible_message(span_boldwarning("BZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZT"))
		for(var/mob/living/carbon/C in get_hearers_in_view(9, user))
			var/bang_effect = C.soundbang_act(2, 0, 0, 5)
			switch(bang_effect)
				if(1)
					C.add_confusion(5)
					C.stuttering += 10
					C.Jitter(10)
				if(2)
					C.Paralyze(40)
					C.add_confusion(10)
					C.stuttering += 15
					C.Jitter(25)
		playsound(get_turf(src), 'sound/machines/warning-buzzer.ogg', 130, 3)
		cooldown = world.time + 600
		user.log_message("used an emagged Cyborg Harm Alarm in [AREACOORD(user)]", LOG_ATTACK)

#define DISPENSE_LOLLIPOP_MODE 1
#define THROW_LOLLIPOP_MODE 2
#define THROW_GUMBALL_MODE 3
#define DISPENSE_ICECREAM_MODE 4

/obj/item/borg/lollipop
	name = "treat fabricator"
	desc = "Reward humans with various treats. Toggle in-module to switch between dispensing and high velocity ejection modes."
	icon_state = "lollipop"
	var/candy = 30
	var/candymax = 30
	var/charge_delay = 10
	var/charging = FALSE
	var/mode = DISPENSE_LOLLIPOP_MODE

	var/firedelay = 0
	var/hitspeed = 2

/obj/item/borg/lollipop/clown

/obj/item/borg/lollipop/equipped()
	. = ..()
	check_amount()

/obj/item/borg/lollipop/dropped()
	. = ..()
	check_amount()

/obj/item/borg/lollipop/proc/check_amount()	//Doesn't even use processing ticks.
	if(charging)
		return
	if(candy < candymax)
		addtimer(CALLBACK(src, PROC_REF(charge_lollipops)), charge_delay)
		charging = TRUE

/obj/item/borg/lollipop/proc/charge_lollipops()
	candy++
	charging = FALSE
	check_amount()

/obj/item/borg/lollipop/proc/dispense(atom/A, mob/user)
	if(candy <= 0)
		to_chat(user, span_warning("No treats left in storage!"))
		return FALSE
	var/turf/T = get_turf(A)
	if(!T || !istype(T) || !isopenturf(T))
		return FALSE
	if(isobj(A))
		var/obj/O = A
		if(O.density)
			return FALSE

	var/obj/item/food_item
	switch(mode)
		if(DISPENSE_LOLLIPOP_MODE)
			food_item = new /obj/item/food/chewable/lollipop(T)
		if(DISPENSE_ICECREAM_MODE)
			food_item = new /obj/item/food/icecream(T)
			var/obj/item/food/icecream/I = food_item
			I.add_ice_cream("vanilla")
			I.desc = "Eat the ice cream."

	var/into_hands = FALSE
	if(ismob(A))
		var/mob/M = A
		into_hands = M.put_in_hands(food_item)

	candy--
	check_amount()

	if(into_hands)
		user.visible_message(span_notice("[user] dispenses a treat into the hands of [A].") , span_notice("You dispense a treat into the hands of [A].") , span_hear("You hear a click."))
	else
		user.visible_message(span_notice("[user] dispenses a treat.") , span_notice("You dispense a treat.") , span_hear("You hear a click."))

	playsound(src.loc, 'sound/machines/click.ogg', 50, TRUE)
	return TRUE

/obj/item/borg/lollipop/proc/shootL(atom/target, mob/living/user, params)
	if(candy <= 0)
		to_chat(user, span_warning("Not enough lollipops left!"))
		return FALSE
	candy--

	var/obj/item/ammo_casing/caseless/lollipop/A
	var/mob/living/silicon/robot/R = user
	if(istype(R) && R.emagged)
		A = new /obj/item/ammo_casing/caseless/lollipop/harmful(src)
	else
		A = new /obj/item/ammo_casing/caseless/lollipop(src)

	playsound(src.loc, 'sound/machines/click.ogg', 50, TRUE)
	A.fire_casing(target, user, params, 0, 0, null, 0, 0, 0, src)
	user.visible_message(span_warning("[user] blasts a flying lollipop at [target]!"))
	check_amount()

/obj/item/borg/lollipop/proc/shootG(atom/target, mob/living/user, params)	//Most certainly a good idea.
	if(candy <= 0)
		to_chat(user, span_warning("Not enough gumballs left!"))
		return FALSE
	candy--
	var/obj/item/ammo_casing/caseless/gumball/A
	var/mob/living/silicon/robot/R = user
	if(istype(R) && R.emagged)
		A = new /obj/item/ammo_casing/caseless/gumball/harmful(src)
	else
		A = new /obj/item/ammo_casing/caseless/gumball(src)

	A.loaded_projectile.color = rgb(rand(0, 255), rand(0, 255), rand(0, 255))
	playsound(src.loc, 'sound/weapons/bulletflyby3.ogg', 50, TRUE)
	A.fire_casing(target, user, params, 0, 0, null, 0, 0, 0, src)
	user.visible_message(span_warning("[user] shoots a high-velocity gumball at [target]!"))
	check_amount()

/obj/item/borg/lollipop/afterattack(atom/target, mob/living/user, proximity, click_params)
	. = ..()
	check_amount()
	if(iscyborg(user))
		var/mob/living/silicon/robot/R = user
		if(!R.cell.use(12))
			to_chat(user, span_warning("Not enough power."))
			return FALSE
	switch(mode)
		if(DISPENSE_LOLLIPOP_MODE, DISPENSE_ICECREAM_MODE)
			if(!proximity)
				return FALSE
			dispense(target, user)
		if(THROW_LOLLIPOP_MODE)
			shootL(target, user, click_params)
		if(THROW_GUMBALL_MODE)
			shootG(target, user, click_params)

/obj/item/borg/lollipop/attack_self(mob/living/user)
	switch(mode)
		if(DISPENSE_LOLLIPOP_MODE)
			mode = THROW_LOLLIPOP_MODE
			to_chat(user, span_notice("Module is now throwing lollipops."))
		if(THROW_LOLLIPOP_MODE)
			mode = THROW_GUMBALL_MODE
			to_chat(user, span_notice("Module is now blasting gumballs."))
		if(THROW_GUMBALL_MODE)
			mode = DISPENSE_ICECREAM_MODE
			to_chat(user, span_notice("Module is now dispensing ice cream."))
		if(DISPENSE_ICECREAM_MODE)
			mode = DISPENSE_LOLLIPOP_MODE
			to_chat(user, span_notice("Module is now dispensing lollipops."))
	..()

#undef DISPENSE_LOLLIPOP_MODE
#undef THROW_LOLLIPOP_MODE
#undef THROW_GUMBALL_MODE
#undef DISPENSE_ICECREAM_MODE

/obj/item/ammo_casing/caseless/gumball
	name = "Gumball"
	desc = "Why are you seeing this?!"
	projectile_type = /obj/projectile/bullet/reusable/gumball
	click_cooldown_override = 2

/obj/item/ammo_casing/caseless/gumball/harmful
	projectile_type = /obj/projectile/bullet/reusable/gumball/harmful

/obj/projectile/bullet/reusable/gumball
	name = "gumball"
	desc = "Oh noes! A fast-moving gumball!"
	icon_state = "gumball"
	ammo_type = /obj/item/food/chewable/gumball/cyborg
	nodamage = TRUE
	damage = 0
	speed = 0.5

/obj/projectile/bullet/reusable/gumball/harmful
	ammo_type = /obj/item/food/chewable/gumball/cyborg
	nodamage = FALSE
	damage = 3

/obj/projectile/bullet/reusable/gumball/handle_drop()
	if(!dropped)
		var/turf/T = get_turf(src)
		var/obj/item/food/chewable/gumball/S = new ammo_type(T)
		S.color = color
		dropped = TRUE

/obj/item/ammo_casing/caseless/lollipop	//NEEDS RANDOMIZED COLOR LOGIC.
	name = "Lollipop"
	desc = "Why are you seeing this?!"
	projectile_type = /obj/projectile/bullet/reusable/lollipop
	click_cooldown_override = 2

// rejected name: DumDum lollipop (get it, cause it embeds?)
/obj/item/ammo_casing/caseless/lollipop/harmful
	projectile_type = /obj/projectile/bullet/reusable/lollipop/harmful

/obj/projectile/bullet/reusable/lollipop
	name = "lollipop"
	desc = "Oh noes! A fast-moving lollipop!"
	icon_state = "lollipop_1"
	ammo_type = /obj/item/food/chewable/lollipop/cyborg
	nodamage = TRUE
	damage = 0
	speed = 0.5
	var/color2 = rgb(0, 0, 0)

/obj/projectile/bullet/reusable/lollipop/harmful
	embedding = list(embed_chance=35, fall_chance=2, jostle_chance=0, ignore_throwspeed_threshold=TRUE, pain_stam_pct=0.5, pain_mult=3, rip_time=10)
	damage = 3
	nodamage = FALSE
	embed_falloff_tile = 0

/obj/projectile/bullet/reusable/lollipop/Initialize()
	. = ..()
	var/obj/item/food/chewable/lollipop/S = new ammo_type(src)
	color2 = S.headcolor
	var/mutable_appearance/head = mutable_appearance('icons/obj/projectiles.dmi', "lollipop_2")
	head.color = color2
	add_overlay(head)

/obj/projectile/bullet/reusable/lollipop/handle_drop()
	if(!dropped)
		var/turf/T = get_turf(src)
		var/obj/item/food/chewable/lollipop/S = new ammo_type(T)
		S.change_head_color(color2)
		dropped = TRUE

/obj/item/cautery/prt //it's a subtype of cauteries so that it inherits the cautery sprites and behavior and stuff, because I'm too lazy to make sprites for this thing
	name = "plating repair tool"
	desc = "A tiny heating device that's powered by a cyborg's excess heat. Its intended purpose is to repair burnt or damaged hull platings, but it can also be used as a crude lighter or cautery."
	toolspeed = 1.5 //it's not designed to be used as a cautery (although it's close enough to one to be considered to be a proper cautery instead of just a hot object for the purposes of surgery)
	heat = 3800 //this thing is intended for metal-shaping, so it's the same temperature as a lit welder
	resistance_flags = FIRE_PROOF //if it's channeling a cyborg's excess heat, it's probably fireproof
	force = 5
	damtype = BURN
	usesound = list('sound/items/welder.ogg', 'sound/items/welder2.ogg') //the usesounds of a lit welder
	hitsound = 'sound/items/welder.ogg' //the hitsound of a lit welder


#define PKBORG_DAMPEN_CYCLE_DELAY 20

//Peacekeeper Cyborg Projectile Dampenening Field
/obj/item/borg/projectile_dampen
	name = "\improper Hyperkinetic Dampening projector"
	desc = "A device that projects a dampening field that weakens kinetic energy above a certain threshold. <span class='boldnotice'>Projects a field that drains power per second while active, that will weaken and slow damaging projectiles inside its field.</span> Still being a prototype, it tends to induce a charge on ungrounded metallic surfaces."
	icon = 'icons/obj/device.dmi'
	icon_state = "shield"
	var/maxenergy = 1500
	var/energy = 1500
	/// Recharging rate in energy per second
	var/energy_recharge = 37.5
	var/energy_recharge_cyborg_drain_coefficient = 0.4
	var/cyborg_cell_critical_percentage = 0.05
	var/mob/living/silicon/robot/host = null
	var/datum/proximity_monitor/advanced/dampening_field
	var/projectile_damage_coefficient = 0.5
	/// Energy cost per tracked projectile damage amount per second
	var/projectile_damage_tick_ecost_coefficient = 10
	var/projectile_speed_coefficient = 1.5		//Higher the coefficient slower the projectile.
	/// Energy cost per tracked projectile per second
	var/projectile_tick_speed_ecost = 75
	var/list/obj/projectile/tracked
	var/image/projectile_effect
	var/field_radius = 3
	var/active = FALSE
	var/cycle_delay = 0

/obj/item/borg/projectile_dampen/debug
	maxenergy = 50000
	energy = 50000
	energy_recharge = 5000

/obj/item/borg/projectile_dampen/Initialize()
	. = ..()
	projectile_effect = image('icons/effects/fields.dmi', "projectile_dampen_effect")
	tracked = list()
	icon_state = "shield0"
	START_PROCESSING(SSfastprocess, src)
	host = loc
	RegisterSignal(host, COMSIG_LIVING_DEATH, PROC_REF(on_death))

/obj/item/borg/projectile_dampen/proc/on_death(datum/source, gibbed)
	SIGNAL_HANDLER

	deactivate_field()

/obj/item/borg/projectile_dampen/Destroy()
	STOP_PROCESSING(SSfastprocess, src)
	return ..()

/obj/item/borg/projectile_dampen/attack_self(mob/user)
	if(cycle_delay > world.time)
		to_chat(user, span_boldwarning("[capitalize(src.name)] is still recycling its projectors!"))
		return
	cycle_delay = world.time + PKBORG_DAMPEN_CYCLE_DELAY
	if(!active)
		if(!user.has_buckled_mobs())
			activate_field()
		else
			to_chat(user, span_warning("[capitalize(src.name)] safety cutoff prevents you from activating it due to living beings being ontop of you!"))
	else
		deactivate_field()
	update_icon()
	to_chat(user, span_boldnotice("You [active? "activate":"deactivate"] [src]."))

/obj/item/borg/projectile_dampen/update_icon_state()
	icon_state = "[initial(icon_state)][active]"

/obj/item/borg/projectile_dampen/proc/activate_field()
	if(istype(dampening_field))
		QDEL_NULL(dampening_field)
	dampening_field = make_field(/datum/proximity_monitor/advanced/peaceborg_dampener, list("current_range" = field_radius, "host" = src, "projector" = src))
	var/mob/living/silicon/robot/owner = get_host()
	if(owner)
		owner.module.allow_riding = FALSE
	active = TRUE

/obj/item/borg/projectile_dampen/proc/deactivate_field()
	QDEL_NULL(dampening_field)
	visible_message(span_warning("<b>[src.name]</b> shuts off!"))
	for(var/P in tracked)
		restore_projectile(P)
	active = FALSE

	var/mob/living/silicon/robot/owner = get_host()
	if(owner)
		owner.module.allow_riding = TRUE

/obj/item/borg/projectile_dampen/proc/get_host()
	if(istype(host))
		return host
	else
		if(iscyborg(host.loc))
			return host.loc
	return null

/obj/item/borg/projectile_dampen/dropped()
	. = ..()
	host = loc

/obj/item/borg/projectile_dampen/equipped()
	. = ..()
	host = loc

/obj/item/borg/projectile_dampen/cyborg_unequip(mob/user)
	deactivate_field()
	. = ..()

/obj/item/borg/projectile_dampen/process(delta_time)
	process_recharge(delta_time)
	process_usage(delta_time)
	update_location()

/obj/item/borg/projectile_dampen/proc/update_location()
	if(dampening_field)
		dampening_field.HandleMove()

/obj/item/borg/projectile_dampen/proc/process_usage(delta_time)
	var/usage = 0
	for(var/I in tracked)
		var/obj/projectile/P = I
		if(!P.stun && P.nodamage)	//No damage
			continue
		usage += projectile_tick_speed_ecost * delta_time
		usage += tracked[I] * projectile_damage_tick_ecost_coefficient * delta_time
	energy = clamp(energy - usage, 0, maxenergy)
	if(energy <= 0)
		deactivate_field()
		visible_message(span_warning("[capitalize(src.name)] blinks \"ENERGY DEPLETED\"."))

/obj/item/borg/projectile_dampen/proc/process_recharge(delta_time)
	if(!istype(host))
		if(iscyborg(host.loc))
			host = host.loc
		else
			energy = clamp(energy + energy_recharge * delta_time, 0, maxenergy)
			return
	if(host.cell && (host.cell.charge >= (host.cell.maxcharge * cyborg_cell_critical_percentage)) && (energy < maxenergy))
		host.cell.use(energy_recharge * delta_time * energy_recharge_cyborg_drain_coefficient)
		energy += energy_recharge * delta_time

/obj/item/borg/projectile_dampen/proc/dampen_projectile(obj/projectile/P, track_projectile = TRUE)
	if(tracked[P])
		return
	if(track_projectile)
		tracked[P] = P.damage
	P.damage *= projectile_damage_coefficient
	P.speed *= projectile_speed_coefficient
	P.add_overlay(projectile_effect)

/obj/item/borg/projectile_dampen/proc/restore_projectile(obj/projectile/P)
	tracked -= P
	P.damage *= (1/projectile_damage_coefficient)
	P.speed *= (1/projectile_speed_coefficient)
	P.cut_overlay(projectile_effect)

/**********************************************************************
						HUD/SIGHT things
***********************************************************************/
/obj/item/borg/sight
	var/sight_mode = null


/obj/item/borg/sight/xray
	name = "\proper X-ray vision"
	icon = 'icons/obj/decals.dmi'
	icon_state = "securearea"
	sight_mode = BORGXRAY

/obj/item/borg/sight/thermal
	name = "\proper thermal vision"
	sight_mode = BORGTHERM
	icon_state = "thermal"


/obj/item/borg/sight/meson
	name = "\proper meson vision"
	sight_mode = BORGMESON
	icon_state = "meson"

/obj/item/borg/sight/material
	name = "\proper material vision"
	sight_mode = BORGMATERIAL
	icon_state = "material"

/obj/item/borg/sight/hud
	name = "hud"
	var/obj/item/clothing/glasses/hud/hud = null


/obj/item/borg/sight/hud/med
	name = "medical hud"
	icon_state = "healthhud"

/obj/item/borg/sight/hud/med/Initialize()
	. = ..()
	hud = new /obj/item/clothing/glasses/hud/health(src)


/obj/item/borg/sight/hud/sec
	name = "security hud"
	icon_state = "securityhud"

/obj/item/borg/sight/hud/sec/Initialize()
	. = ..()
	hud = new /obj/item/clothing/glasses/hud/security(src)


/**********************************************************************
						Borg apparatus
***********************************************************************/
//These are tools that can hold only specific items. For example, the mediborg gets one that can only hold beakers and bottles.

/obj/item/borg/apparatus/
	name = "unknown storage apparatus"
	desc = "This device seems nonfunctional."
	icon = 'icons/mob/robot_items.dmi'
	icon_state = "hugmodule"
	var/obj/item/stored
	var/list/storable = list()

/obj/item/borg/apparatus/Initialize()
	. = ..()
	RegisterSignal(loc.loc, COMSIG_BORG_SAFE_DECONSTRUCT, PROC_REF(safedecon))

/obj/item/borg/apparatus/Destroy()
	if(stored)
		QDEL_NULL(stored)
	. = ..()

///If we're safely deconstructed, we put the item neatly onto the ground, rather than deleting it.
/obj/item/borg/apparatus/proc/safedecon()
	if(stored)
		stored.forceMove(get_turf(src))
		stored = null

/obj/item/borg/apparatus/Exited(atom/A)
	if(A == stored) //sanity check
		UnregisterSignal(stored, COMSIG_ATOM_UPDATE_ICON)
		stored = null
	update_icon()
	. = ..()

///A right-click verb, for those not using hotkey mode.
/obj/item/borg/apparatus/verb/verb_dropHeld()
	set category = "Объект"
	set name = "Drop"

	if(usr != loc || !stored)
		return
	stored.forceMove(get_turf(usr))
	return

/obj/item/borg/apparatus/attack_self(mob/living/silicon/robot/user)
	if(!stored)
		return ..()
	if(user.client?.keys_held["Alt"])
		stored.forceMove(get_turf(user))
		return
	stored.attack_self(user)

/obj/item/borg/apparatus/pre_attack(atom/A, mob/living/user, params)
	if(!stored)
		var/itemcheck = FALSE
		for(var/i in storable)
			if(istype(A, i))
				itemcheck = TRUE
				break
		if(itemcheck)
			var/obj/item/O = A
			O.forceMove(src)
			stored = O
			RegisterSignal(stored, COMSIG_ATOM_UPDATE_ICON, TYPE_PROC_REF(/atom, update_icon))
			update_icon()
			return
	else
		stored.melee_attack_chain(user, A, params)
		return
	. = ..()

/obj/item/borg/apparatus/attackby(obj/item/W, mob/user, params)
	if(stored)
		W.melee_attack_chain(user, stored, params)
		return
	. = ..()

/////////////////
//beaker holder//
/////////////////

/obj/item/borg/apparatus/beaker
	name = "beaker storage apparatus"
	desc = "A special apparatus for carrying beakers without spilling the contents. Alt-Z or right-click to drop the beaker."
	icon_state = "borg_beaker_apparatus"
	storable = list(/obj/item/reagent_containers/glass/beaker,
				/obj/item/reagent_containers/glass/bottle)

/obj/item/borg/apparatus/beaker/Initialize()
	. = ..()
	stored = new /obj/item/reagent_containers/glass/beaker/large(src)
	RegisterSignal(stored, COMSIG_ATOM_UPDATE_ICON, TYPE_PROC_REF(/atom, update_icon))
	update_icon()

/obj/item/borg/apparatus/beaker/Destroy()
	if(stored)
		var/obj/item/reagent_containers/C = stored
		C.SplashReagents(get_turf(src))
		QDEL_NULL(stored)
	. = ..()

/obj/item/borg/apparatus/beaker/examine()
	. = ..()
	if(stored)
		var/obj/item/reagent_containers/C = stored
		. += "<hr>The apparatus currently has [C] secured, which contains:"
		if(length(C.reagents.reagent_list))
			for(var/datum/reagent/R in C.reagents.reagent_list)
				. += "\n[R.volume] units of [R.name]"
		else
			. += "\nNothing."

/obj/item/borg/apparatus/beaker/update_overlays()
	. = ..()
	var/mutable_appearance/arm = mutable_appearance(icon = icon, icon_state = "borg_beaker_apparatus_arm")
	if(stored)
		COMPILE_OVERLAYS(stored)
		stored.pixel_x = 0
		stored.pixel_y = 0
		var/mutable_appearance/stored_copy = new /mutable_appearance(stored)
		if(istype(stored, /obj/item/reagent_containers/glass/beaker))
			arm.pixel_y = arm.pixel_y - 3
		stored_copy.layer = FLOAT_LAYER
		stored_copy.plane = FLOAT_PLANE
		. += stored_copy
	else
		arm.pixel_y = arm.pixel_y - 5
	. += arm

/obj/item/borg/apparatus/beaker/attack_self(mob/living/silicon/robot/user)
	if(stored && !user.client?.keys_held["Alt"] && user.a_intent != "help")
		var/obj/item/reagent_containers/C = stored
		C.SplashReagents(get_turf(user))
		loc.visible_message(span_notice("[user] spills the contents of the [C] all over the floor."))
		return
	. = ..()

/obj/item/borg/apparatus/beaker/extra
	name = "secondary beaker storage apparatus"
	desc = "A supplementary beaker storage apparatus."

/obj/item/borg/apparatus/beaker/service
	name = "beverage storage apparatus"
	desc = "A special apparatus for carrying drinks without spilling the contents. Alt-Z or right-click to drop the beaker."
	icon_state = "borg_beaker_apparatus"
	storable = list(/obj/item/reagent_containers/food/drinks/,
				/obj/item/reagent_containers/food/condiment)

/obj/item/borg/apparatus/beaker/service/Initialize()
	. = ..()
	stored = new /obj/item/reagent_containers/food/drinks/drinkingglass(src)
	RegisterSignal(stored, COMSIG_ATOM_UPDATE_ICON, TYPE_PROC_REF(/atom, update_icon))
	update_icon()

////////////////////
//engi part holder//
////////////////////

/obj/item/borg/apparatus/circuit
	name = "circuit manipulation apparatus"
	desc = "A special apparatus for carrying and manipulating circuit boards. Alt-Z or right-click to drop the stored object."
	icon_state = "borg_hardware_apparatus"
	storable = list(/obj/item/circuitboard,
				/obj/item/electronics)

/obj/item/borg/apparatus/circuit/Initialize()
	. = ..()
	update_icon()

/obj/item/borg/apparatus/circuit/update_overlays()
	. = ..()
	var/mutable_appearance/arm = mutable_appearance(icon, "borg_hardware_apparatus_arm1")
	if(stored)
		COMPILE_OVERLAYS(stored)
		stored.pixel_x = -3
		stored.pixel_y = 0
		if(!istype(stored, /obj/item/circuitboard))
			arm.icon_state = "borg_hardware_apparatus_arm2"
		var/mutable_appearance/stored_copy = new /mutable_appearance(stored)
		stored_copy.layer = FLOAT_LAYER
		stored_copy.plane = FLOAT_PLANE
		. += stored_copy
	. += arm

/obj/item/borg/apparatus/circuit/examine()
	. = ..()
	if(stored)
		. += "<hr>The apparatus currently has [stored] secured."

/obj/item/borg/apparatus/circuit/pre_attack(atom/A, mob/living/user, params)
	. = ..()
	if(istype(A, /obj/item/ai_module) && !stored) //If an admin wants a borg to upload laws, who am I to stop them? Otherwise, we can hint that it fails
		to_chat(user, span_warning("This circuit board doesn't seem to have standard robot apparatus pin holes. You're unable to pick it up."))
