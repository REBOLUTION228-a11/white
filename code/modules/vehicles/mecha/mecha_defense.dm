/*!
 * # Mecha defence explanation
 * Mechs focus is on a more heavy-but-slower damage approach
 * For this they have the following mechanics
 *
 * ## Backstab
 * Basically the tldr is that mechs are less flexible so we encourage good positioning, pretty simple
 * ## Armor modules
 * Pretty simple, adds armor, you can choose against what
 * ## Internal damage
 * When taking damage will force you to take some time to repair, encourages improvising in a fight
 * Targetting different def zones will damage them to encurage a more strategic approach to fights
 * where they target the "dangerous" modules
 */

/// returns a number for the damage multiplier for this relative angle/dir
/obj/vehicle/sealed/mecha/proc/get_armour_facing(relative_dir)
	switch(relative_dir)
		if(180) // BACKSTAB!
			return facing_modifiers[MECHA_BACK_ARMOUR]
		if(0, 45) // direct or 45 degrees off
			return facing_modifiers[MECHA_FRONT_ARMOUR]
	return facing_modifiers[MECHA_SIDE_ARMOUR] //if its not a front hit or back hit then assume its from the side

///tries to deal internal damaget depending on the damage amount
/obj/vehicle/sealed/mecha/proc/try_deal_internal_damage(damage)
	if(damage < internal_damage_threshold)
		return
	if(!prob(internal_damage_probability))
		return
	var/internal_damage_to_deal = possible_int_damage
	internal_damage_to_deal &= ~mecha_flags
	if(internal_damage_to_deal)
		set_internal_damage(pick(bitfield2list(internal_damage_to_deal)))

/// tries to damage mech equipment depending on damage and where is being targetted
/obj/vehicle/sealed/mecha/proc/try_damage_component(damage, def_zone)
	if(damage < component_damage_threshold)
		return
	var/obj/item/mecha_parts/mecha_equipment/gear
	switch(def_zone)
		if(BODY_ZONE_L_ARM)
			gear = equip_by_category[MECHA_L_ARM]
		if(BODY_ZONE_R_ARM)
			gear = equip_by_category[MECHA_R_ARM]
	if(!gear)
		return
	var/brokenstatus = gear.get_integrity()
	// always leave at least 1 health
	brokenstatus--
	var/damage_to_deal = min(brokenstatus, damage)
	if(!damage_to_deal)
		return
	gear.take_damage(damage_to_deal)

/obj/vehicle/sealed/mecha/take_damage(damage_amount, damage_type = BRUTE, damage_flag = 0, sound_effect = 1, attack_dir)
	. = ..()
	if(. && obj_integrity > 0)
		spark_system.start()
		try_deal_internal_damage(.)
		if(. >= 5 || prob(33))
			to_chat(occupants, "[icon2html(src, occupants)][span_userdanger("Получаем урон!")]")
		log_message("Took [.] points of damage. Damage type: [damage_type]", LOG_MECHA)

/obj/vehicle/sealed/mecha/run_obj_armor(damage_amount, damage_type, damage_flag = 0, attack_dir, armour_penentration)
	. = ..()
	if(attack_dir)
		var/facing_modifier = get_armour_facing(abs(dir2angle(dir) - dir2angle(attack_dir)))
		if(.)
			. *= facing_modifier

/obj/vehicle/sealed/mecha/attack_hand(mob/living/user)
	. = ..()
	if(.)
		return
	user.changeNext_move(CLICK_CD_MELEE) // Ugh. Ideally we shouldn't be setting cooldowns outside of click code.
	user.do_attack_animation(src, ATTACK_EFFECT_PUNCH)
	playsound(loc, 'sound/weapons/tap.ogg', 40, TRUE, -1)
	user.visible_message(span_danger("<b>[user]</b> бьёт <b>[name]</b>. Ничего не происходит."), null, null, COMBAT_MESSAGE_RANGE)
	log_message("Attack by hand/paw (no damage). Attacker - [user].", LOG_MECHA, color="red")

/obj/vehicle/sealed/mecha/attack_paw(mob/user as mob)
	return attack_hand(user)

/obj/vehicle/sealed/mecha/attack_alien(mob/living/user)
	log_message("Attack by alien. Attacker - [user].", LOG_MECHA, color="red")
	playsound(loc, 'sound/weapons/slash.ogg', 100, TRUE)
	attack_generic(user, rand(user.melee_damage_lower, user.melee_damage_upper), BRUTE, MELEE, 0)

/obj/vehicle/sealed/mecha/attack_animal(mob/living/simple_animal/user)
	log_message("Attack by simple animal. Attacker - [user].", LOG_MECHA, color="red")
	if(!user.melee_damage_upper && !user.obj_damage)
		user.emote("custom", message = "[user.friendly_verb_continuous] [src].")
		return 0
	else
		var/play_soundeffect = 1
		if(user.environment_smash)
			play_soundeffect = 0
			playsound(src, 'sound/effects/bang.ogg', 50, TRUE)
		var/animal_damage = rand(user.melee_damage_lower,user.melee_damage_upper)
		if(user.obj_damage)
			animal_damage = user.obj_damage
		animal_damage = min(animal_damage, 20*user.environment_smash)
		log_combat(user, src, "attacked")
		attack_generic(user, animal_damage, user.melee_damage_type, MELEE, play_soundeffect)
		return 1


/obj/vehicle/sealed/mecha/hulk_damage()
	return 15

/obj/vehicle/sealed/mecha/attack_hulk(mob/living/carbon/human/user)
	. = ..()
	if(.)
		log_message("Attack by hulk. Attacker - [user].", LOG_MECHA, color="red")
		log_combat(user, src, "punched", "hulk powers")

/obj/vehicle/sealed/mecha/blob_act(obj/structure/blob/B)
	log_message("Attack by blob. Attacker - [B].", LOG_MECHA, color="red")
	take_damage(30, BRUTE, MELEE, 0, get_dir(src, B))

/obj/vehicle/sealed/mecha/attack_tk()
	return

/obj/vehicle/sealed/mecha/hitby(atom/movable/AM, skipcatch, hitpush, blocked, datum/thrownthing/throwingdatum) //wrapper
	log_message("Hit by [AM].", LOG_MECHA, color="red")
	return ..()

/obj/vehicle/sealed/mecha/bullet_act(obj/projectile/hitting_projectile, def_zone, piercing_hit) //wrapper
	if(!enclosed && LAZYLEN(occupants) && !(mecha_flags  & SILICON_PILOT) && (hitting_projectile.def_zone == BODY_ZONE_HEAD || hitting_projectile.def_zone == BODY_ZONE_CHEST)) //allows bullets to hit the pilot of open-canopy mechs
		for(var/mob/living/hitmob as anything in occupants)
			hitmob.bullet_act(hitting_projectile, def_zone, piercing_hit) //If the sides are open, the occupant can be hit
		return BULLET_ACT_HIT
	log_message("Hit by projectile. Type: [hitting_projectile]([hitting_projectile.damage_type]).", LOG_MECHA, color="red")
	// yes we *have* to run the armor calc proc here I love tg projectile code too
	try_damage_component(run_obj_armor(hitting_projectile.damage, hitting_projectile.damage_type, hitting_projectile.damage_type, 0, REVERSE_DIR(hitting_projectile.dir), hitting_projectile.armour_penetration), hitting_projectile.def_zone)
	return ..()

/obj/vehicle/sealed/mecha/ex_act(severity, target)
	log_message("Affected by explosion of severity: [severity].", LOG_MECHA, color="red")
	return ..()

/obj/vehicle/sealed/mecha/contents_explosion(severity, target)
	severity--

	switch(severity)
		if(EXPLODE_DEVASTATE)
			if(flat_equipment)
				SSexplosions.high_mov_atom += flat_equipment
			if(trackers)
				SSexplosions.high_mov_atom += trackers
			if(occupants)
				SSexplosions.high_mov_atom += occupants
		if(EXPLODE_HEAVY)
			if(flat_equipment)
				SSexplosions.med_mov_atom += flat_equipment
			if(trackers)
				SSexplosions.med_mov_atom += trackers
			if(occupants)
				SSexplosions.med_mov_atom += occupants
		if(EXPLODE_LIGHT)
			if(flat_equipment)
				SSexplosions.low_mov_atom += flat_equipment
			if(trackers)
				SSexplosions.low_mov_atom += trackers
			if(occupants)
				SSexplosions.low_mov_atom += occupants

/obj/vehicle/sealed/mecha/handle_atom_del(atom/A)
	if(A in occupants) //todo does not work and in wrong file
		LAZYREMOVE(occupants, A)
		icon_state = initial(icon_state)+"-open"
		setDir(dir_in)

/obj/vehicle/sealed/mecha/emp_act(severity)
	. = ..()
	if (. & EMP_PROTECT_SELF)
		return
	if(get_charge())
		use_power((cell.charge/3)/(severity*2))
		take_damage(30 / severity, BURN, ENERGY, 1)
	log_message("EMP detected", LOG_MECHA, color="red")

	if(istype(src, /obj/vehicle/sealed/mecha/combat)) //todo this stupid mouse icon should be a flag
		mouse_pointer = 'icons/effects/mouse_pointers/mecha_mouse-disable.dmi'
		for(var/occus in occupants)
			var/mob/living/occupant = occus
			occupant.update_mouse_pointer()
	if(!equipment_disabled && LAZYLEN(occupants)) //prevent spamming this message with back-to-back EMPs
		to_chat(occupants, span_warning("Ошибка -- Соединение с оборудованием прервано."))
	addtimer(CALLBACK(src, TYPE_PROC_REF(/obj/vehicle/sealed/mecha, restore_equipment)), 3 SECONDS, TIMER_UNIQUE | TIMER_OVERRIDE)
	equipment_disabled = TRUE

/obj/vehicle/sealed/mecha/should_atmos_process(datum/gas_mixture/air, exposed_temperature)
	return exposed_temperature > max_temperature

/obj/vehicle/sealed/mecha/atmos_expose(datum/gas_mixture/air, exposed_temperature)
	log_message("Exposed to dangerous temperature.", LOG_MECHA, color="red")
	take_damage(5, BURN, 0, 1)

/obj/vehicle/sealed/mecha/attackby_secondary(obj/item/weapon, mob/user, params)
	if(istype(weapon, /obj/item/mecha_parts))
		var/obj/item/mecha_parts/parts = weapon
		parts.try_attach_part(user, src, TRUE)
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	return ..()

/obj/vehicle/sealed/mecha/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/mmi))
		if(mmi_move_inside(W,user))
			to_chat(user, span_notice("[capitalize(src.name)]-[W] интерфейс инициализирован успешно."))
		else
			to_chat(user, span_warning("[capitalize(src.name)]-[W] интерфейс инициализирован с ошибкой."))
		return

	if(istype(W, /obj/item/mecha_ammo))
		ammo_resupply(W, user)
		return

	if(W.GetID())
		if((mecha_flags & ADDING_ACCESS_POSSIBLE) || (mecha_flags & ADDING_MAINT_ACCESS_POSSIBLE))
			if(internals_access_allowed(user))
				ui_interact(user)
				return
			to_chat(user, span_warning("Неправильный ID: Доступ запрещён."))
			return
		to_chat(user, span_warning("Технические протоколы заблокированы оператором."))
		return

	if(istype(W, /obj/item/stock_parts/cell))
		if(construction_state == MECHA_OPEN_HATCH)
			if(!cell)
				if(!user.transferItemToLoc(W, src, silent = FALSE))
					return
				var/obj/item/stock_parts/cell/C = W
				to_chat(user, span_notice("Устанавливаю аккумулятор."))
				playsound(src, 'sound/items/screwdriver2.ogg', 50, FALSE)
				cell = C
				log_message("Power cell installed", LOG_MECHA)
			else
				to_chat(user, span_warning("Аккумулятор уже установлен!"))
		return

	if(istype(W, /obj/item/stock_parts/scanning_module))
		if(construction_state == MECHA_OPEN_HATCH)
			if(!scanmod)
				if(!user.transferItemToLoc(W, src))
					return
				to_chat(user, span_notice("Устанавливаю сканирующий модуль."))
				playsound(src, 'sound/items/screwdriver2.ogg', 50, FALSE)
				scanmod = W
				log_message("[W] installed", LOG_MECHA)
				update_part_values()
			else
				to_chat(user, span_warning("Сканирующий модуль уже установлен!"))
		return

	if(istype(W, /obj/item/stock_parts/capacitor))
		if(construction_state == MECHA_OPEN_HATCH)
			if(!capacitor)
				if(!user.transferItemToLoc(W, src))
					return
				to_chat(user, span_notice("Устанавливаю конденсатор."))
				playsound(src, 'sound/items/screwdriver2.ogg', 50, FALSE)
				capacitor = W
				log_message("[W] installed", LOG_MECHA)
				update_part_values()
			else
				to_chat(user, span_warning("Конденсатор установлен!"))
		return

	if(istype(W, /obj/item/mecha_parts))
		var/obj/item/mecha_parts/P = W
		P.try_attach_part(user, src, FALSE)
		return
	. = ..()
	log_message("Attacked by [W]. Attacker - [user], Damage - [.]", LOG_MECHA)
	if(isliving(user))
		var/mob/living/living_user = user
		try_damage_component(., living_user.zone_selected)

/obj/vehicle/sealed/mecha/wrench_act(mob/living/user, obj/item/I)
	..()
	. = TRUE
	if(construction_state == MECHA_SECURE_BOLTS)
		construction_state = MECHA_LOOSE_BOLTS
		to_chat(user, span_notice("Расслабляю защитные болты."))
		return
	if(construction_state == MECHA_LOOSE_BOLTS)
		construction_state = MECHA_SECURE_BOLTS
		to_chat(user, span_notice("Затягиваю защитные болты."))

/obj/vehicle/sealed/mecha/crowbar_act(mob/living/user, obj/item/I)
	..()
	. = TRUE
	if(construction_state == MECHA_LOOSE_BOLTS)
		construction_state = MECHA_OPEN_HATCH
		to_chat(user, span_notice("Открываю щиток с доступом к аккумулятору."))
		return
	if(construction_state == MECHA_OPEN_HATCH)
		construction_state = MECHA_LOOSE_BOLTS
		to_chat(user, span_notice("Закрываю щиток с доступом к аккумулятору."))

/obj/vehicle/sealed/mecha/welder_act(mob/living/user, obj/item/W)
	. = ..()
	if(user.a_intent == INTENT_HARM)
		return
	. = TRUE
	if(obj_integrity < max_integrity)
		if(!W.use_tool(src, user, 0, volume=50, amount=1))
			return
		user.visible_message(span_notice("[user] немного чинит [name].") , span_notice("Немного чиню [src]."))
		obj_integrity += min(10, max_integrity-obj_integrity)
		if(obj_integrity == max_integrity)
			to_chat(user, span_notice("Теперь всё в порядке."))
		return
	to_chat(user, span_warning("[src] цел!"))

/obj/vehicle/sealed/mecha/proc/full_repair(charge_cell)
	obj_integrity = max_integrity
	if(cell && charge_cell)
		cell.charge = cell.maxcharge
	if(internal_damage & MECHA_INT_FIRE)
		clear_internal_damage(MECHA_INT_FIRE)
	if(internal_damage & MECHA_INT_TEMP_CONTROL)
		clear_internal_damage(MECHA_INT_TEMP_CONTROL)
	if(internal_damage & MECHA_INT_SHORT_CIRCUIT)
		clear_internal_damage(MECHA_INT_SHORT_CIRCUIT)
	if(internal_damage & MECHA_INT_TANK_BREACH)
		clear_internal_damage(MECHA_INT_TANK_BREACH)
	if(internal_damage & MECHA_INT_CONTROL_LOST)
		clear_internal_damage(MECHA_INT_CONTROL_LOST)

/obj/vehicle/sealed/mecha/narsie_act()
	emp_act(EMP_HEAVY)

/obj/vehicle/sealed/mecha/do_attack_animation(atom/A, visual_effect_icon, obj/item/used_item, no_effect)
	if(!no_effect && !visual_effect_icon)
		visual_effect_icon = ATTACK_EFFECT_SMASH
		if(damtype == BURN)
			visual_effect_icon = ATTACK_EFFECT_MECHFIRE
		else if(damtype == TOX)
			visual_effect_icon = ATTACK_EFFECT_MECHTOXIN
	..()

/obj/vehicle/sealed/mecha/obj_destruction()
	if(wreckage)
		var/mob/living/silicon/ai/AI
		for(var/crew in occupants)
			if(isAI(crew))
				if(AI)
					var/mob/living/silicon/ai/unlucky_ais = crew
					unlucky_ais.gib()
					continue
				AI = crew
		var/obj/structure/mecha_wreckage/WR = new wreckage(loc, AI)
		for(var/obj/item/mecha_parts/mecha_equipment/E in flat_equipment)
			if(E.detachable && prob(30))
				WR.crowbar_salvage += E
				E.detach(WR) //detaches from src into WR
				E.equip_ready = 1
			else
				E.detach(loc)
				qdel(E)
		if(cell)
			WR.crowbar_salvage += cell
			cell.forceMove(WR)
			cell.charge = rand(0, cell.charge)
			cell = null
		if(internal_tank)
			WR.crowbar_salvage += internal_tank
			internal_tank.forceMove(WR)
			cell = null
	. = ..()
