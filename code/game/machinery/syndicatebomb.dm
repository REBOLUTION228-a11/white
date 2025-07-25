#define BUTTON_COOLDOWN 60 // cant delay the bomb forever
#define BUTTON_DELAY	50 //five seconds

/obj/machinery/syndicatebomb
	icon = 'icons/obj/assemblies.dmi'
	name = "syndicate bomb"
	icon_state = "syndicate-bomb"
	desc = "A large and menacing device. Can be bolted down with a wrench."

	anchored = FALSE
	density = FALSE
	layer = BELOW_MOB_LAYER //so people can't hide it and it's REALLY OBVIOUS
	resistance_flags = FIRE_PROOF | ACID_PROOF
	processing_flags = START_PROCESSING_MANUALLY
	subsystem_type = /datum/controller/subsystem/processing/fastprocess

	interaction_flags_machine = INTERACT_MACHINE_WIRES_IF_OPEN | INTERACT_MACHINE_OFFLINE

	var/minimum_timer = 90
	var/timer_set = 90
	var/maximum_timer = 60000

	var/can_unanchor = TRUE

	var/open_panel = FALSE 	//are the wires exposed?
	var/active = FALSE		//is the bomb counting down?
	var/obj/item/bombcore/payload = /obj/item/bombcore
	var/beepsound = 'sound/items/timer.ogg'
	var/delayedbig = FALSE	//delay wire pulsed?
	var/delayedlittle  = FALSE	//activation wire pulsed?
	var/obj/effect/countdown/syndicatebomb/countdown

	var/next_beep
	var/detonation_timer
	var/explode_now = FALSE

/obj/machinery/syndicatebomb/proc/try_detonate(ignore_active = FALSE)
	. = (payload in src) && (active || ignore_active)
	if(.)
		payload.detonate()

/obj/machinery/syndicatebomb/obj_break()
	if(!try_detonate())
		..()

/obj/machinery/syndicatebomb/obj_destruction()
	if(!try_detonate())
		..()

/obj/machinery/syndicatebomb/process()
	if(!active)
		end_processing()
		detonation_timer = null
		next_beep = null
		countdown.stop()
		if(payload in src)
			payload.defuse()
		return

	if(!isnull(next_beep) && (next_beep <= world.time))
		var/volume
		switch(seconds_remaining())
			if(0 to 5)
				volume = 50
			if(5 to 10)
				volume = 40
			if(10 to 15)
				volume = 30
			if(15 to 20)
				volume = 20
			if(20 to 25)
				volume = 10
			else
				volume = 5
		playsound(loc, beepsound, volume, FALSE)
		next_beep = world.time + 10

	if(active && ((detonation_timer <= world.time) || explode_now))
		active = FALSE
		timer_set = initial(timer_set)
		update_icon()
		try_detonate(TRUE)

/obj/machinery/syndicatebomb/Initialize()
	. = ..()
	wires = new /datum/wires/syndicatebomb(src)
	if(payload)
		payload = new payload(src)
	update_icon()
	countdown = new(src)
	end_processing()

/obj/machinery/syndicatebomb/Destroy()
	QDEL_NULL(wires)
	QDEL_NULL(countdown)
	end_processing()
	return ..()

/obj/machinery/syndicatebomb/examine(mob/user)
	. = ..()
	. += {"<hr>A digital display on it reads "[seconds_remaining()]"."}

/obj/machinery/syndicatebomb/update_icon_state()
	icon_state = "[initial(icon_state)][active ? "-active" : "-inactive"][open_panel ? "-wires" : ""]"

/obj/machinery/syndicatebomb/proc/seconds_remaining()
	if(active)
		. = max(0, round((detonation_timer - world.time) / 10))
	else
		. = timer_set

/obj/machinery/syndicatebomb/attackby(obj/item/I, mob/user, params)
	if(HAS_TRAIT(user, TRAIT_PACIFISM))
		to_chat(user, span_warning("Не могу как-то взаимодействовать с бомбой!"))
		return FALSE
	if(I.tool_behaviour == TOOL_WRENCH && can_unanchor)
		if(!anchored)
			if(!isturf(loc) || isspaceturf(loc))
				to_chat(user, span_notice("The bomb must be placed on solid ground to attach it."))
			else
				to_chat(user, span_notice("You firmly wrench the bomb to the floor."))
				I.play_tool_sound(src)
				set_anchored(TRUE)
				if(active)
					to_chat(user, span_notice("The bolts lock in place."))
		else
			if(!active)
				to_chat(user, span_notice("You wrench the bomb from the floor."))
				I.play_tool_sound(src)
				set_anchored(FALSE)
			else
				to_chat(user, span_warning("The bolts are locked down!"))

	else if(I.tool_behaviour == TOOL_SCREWDRIVER)
		open_panel = !open_panel
		update_icon()
		to_chat(user, span_notice("You [open_panel ? "open" : "close"] the wire panel."))

	else if(is_wire_tool(I) && open_panel)
		wires.interact(user)

	else if(I.tool_behaviour == TOOL_CROWBAR)
		if(open_panel && wires.is_all_cut())
			if(payload)
				to_chat(user, span_notice("You carefully pry out [payload]."))
				payload.forceMove(drop_location())
				payload = null
			else
				to_chat(user, span_warning("Нечего вытаскивать!"))
		else if (open_panel)
			to_chat(user, span_warning("Провода, соединяющие оболочку со взрывчаткой удерживают её!"))
		else
			to_chat(user, span_warning("Крышка прикручена, она не вскрывается!"))
	else if(istype(I, /obj/item/bombcore))
		if(!payload)
			if(!user.transferItemToLoc(I, src))
				return
			payload = I
			to_chat(user, span_notice("Помещаю [payload] в [src]."))
		else
			to_chat(user, span_warning("[payload] уже загружена в [src]! Нужно бы вытянуть её сначала."))
	else if(I.tool_behaviour == TOOL_WELDER)
		if(payload || !wires.is_all_cut() || !open_panel)
			return

		if(!I.tool_start_check(user, amount=5))  //uses up 5 fuel
			return

		to_chat(user, span_notice("Начинаю разрезать [src] на части..."))
		if(I.use_tool(src, user, 20, volume=50, amount=5)) //uses up 5 fuel
			to_chat(user, span_notice("Разрезал [src] на части."))
			new /obj/item/stack/sheet/plasteel( loc, 5)
			qdel(src)
	else
		var/old_integ = obj_integrity
		. = ..()
		if((old_integ > obj_integrity) && active  && (payload in src))
			to_chat(user, span_warning("Кажется это плохая идея..."))

/obj/machinery/syndicatebomb/interact(mob/user)
	wires.interact(user)
	if(!open_panel)
		if(!active)
			settings(user)
		else if(anchored)
			to_chat(user, span_warning("Бомба прикручена к полу!"))

/obj/machinery/syndicatebomb/proc/activate()
	active = TRUE
	begin_processing()
	countdown.start()
	next_beep = world.time + 10
	detonation_timer = world.time + (timer_set * 10)
	playsound(loc, 'sound/machines/click.ogg', 30, TRUE)
	notify_ghosts("<b>[src.name]</b> has been activated at [get_area(src)]!", source = src, action = NOTIFY_ORBIT, flashwindow = FALSE, header = "Bomb Planted")

/obj/machinery/syndicatebomb/proc/settings(mob/user)
	if(HAS_TRAIT(user, TRAIT_PACIFISM))
		to_chat(user, span_warning("Не могу заставить себя поставить бомбу! Это ведь навредит кому-то!"))
		return FALSE

	var/new_timer = input(user, "Please set the timer.", "Timer", "[timer_set]") as num|null

	if (isnull(new_timer))
		return

	if(in_range(src, user) && isliving(user)) //No running off and setting bombs from across the station
		timer_set = clamp(new_timer, minimum_timer, maximum_timer)
		loc.visible_message(span_notice("[icon2html(src, viewers(src))] timer set for [timer_set] seconds."))
	if(tgui_alert(user,"Would you like to start the countdown now?",,list("Yes","No")) == "Yes" && in_range(src, user) && isliving(user))
		if(!active)
			visible_message(span_danger("[icon2html(src, viewers(loc))] [timer_set] секунд до детонации, пожалуйста, покиньте зону."))
			activate()
			update_icon()
			add_fingerprint(user)

			if(payload && !istype(payload, /obj/item/bombcore/training))
				log_bomber(user, "has primed a", src, "for detonation (Payload: [payload.name])")
				payload.adminlog = "The [name] that [key_name(user)] had primed detonated!"

///Bomb Subtypes///

/obj/machinery/syndicatebomb/training
	name = "тренировочная бомба"
	icon_state = "training-bomb"
	desc = "Устройство Синдиката с вынутой взрывчаткой внутри, которая используется для тренировки начинающих сапёров."
	payload = /obj/item/bombcore/training

/obj/machinery/syndicatebomb/emp
	name = "ЭМИ бомба"
	desc = "Модифицированная бомба, сделанная для выпуска разрушительного электромагнетического пульса вместо взрыва."
	payload = /obj/item/bombcore/emp

/obj/machinery/syndicatebomb/badmin
	name = "generic summoning badmin bomb"
	desc = "О боже, что это за штука?"
	payload = /obj/item/bombcore/badmin/summon

/obj/machinery/syndicatebomb/badmin/clown
	name = "клоунская бомба"
	icon_state = "clown-bomb"
	desc = "ХОНК."
	payload = /obj/item/bombcore/badmin/summon/clown
	beepsound = 'sound/items/bikehorn.ogg'

/obj/machinery/syndicatebomb/empty
	name = "бомба"
	icon_state = "base-bomb"
	desc = "Зловеще выглядящее устройство, предназначенное для детонации взрывного боезаряда. Может быть прикручено к полу с помощью гаечного ключа."
	payload = null
	open_panel = TRUE
	timer_set = 120

/obj/machinery/syndicatebomb/empty/Initialize()
	. = ..()
	wires.cut_all()

/obj/machinery/syndicatebomb/self_destruct
	name = "механизм самоуничтожения"
	desc = "Не трогать. Гарантия недействительна, если подвергается высоким температурам. Не подходит для агентов возрастом ниже трёх лет."
	payload = /obj/item/bombcore/large
	can_unanchor = FALSE

///Bomb Cores///

/obj/item/bombcore
	name = "боезаряд бомбы"
	desc = "Мощная взрывчатка неизвестной структуры произведённая Синдикатом. Она должна быть стабильной в нормальных условиях..."
	icon = 'icons/obj/assemblies.dmi'
	icon_state = "bombcore"
	inhand_icon_state = "eshield0"
	lefthand_file = 'icons/mob/inhands/equipment/shields_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/shields_righthand.dmi'
	w_class = WEIGHT_CLASS_NORMAL
	resistance_flags = FLAMMABLE //Burnable (but the casing isn't)
	var/adminlog = null
	var/range_heavy = 3
	var/range_medium = 9
	var/range_light = 17
	var/range_flame = 17

/obj/item/bombcore/ex_act(severity, target) // Little boom can chain a big boom.
	detonate()


/obj/item/bombcore/burn()
	detonate()
	..()

/obj/item/bombcore/proc/detonate()
	if(adminlog)
		message_admins(adminlog)
		log_game(adminlog)
	explosion(src, range_heavy, range_medium, range_light, flame_range = range_flame)
	if(loc && istype(loc, /obj/machinery/syndicatebomb/))
		qdel(loc)
	qdel(src)

/obj/item/bombcore/proc/defuse()
//Note: 	the machine's defusal is mostly done from the wires code, this is here if you want the core itself to do anything.

///Bomb Core Subtypes///

/obj/item/bombcore/training
	name = "тренировочный боезаряд"
	desc = "Точная копия боезаряда Синдиката, сделанная NanoTrasen. Полностью лишенная взрывчатки, на ней можно практиковать свои навыки обезвреживания бомб."
	var/defusals = 0
	var/attempts = 0

/obj/item/bombcore/training/proc/reset()
	var/obj/machinery/syndicatebomb/holder = loc
	if(istype(holder))
		if(holder.wires)
			holder.wires.repair()
			holder.wires.shuffle_wires()
		holder.delayedbig = FALSE
		holder.delayedlittle = FALSE
		holder.explode_now = FALSE
		holder.update_icon()
		holder.updateDialog()
		STOP_PROCESSING(SSfastprocess, holder)

/obj/item/bombcore/training/detonate()
	var/obj/machinery/syndicatebomb/holder = loc
	if(istype(holder))
		attempts++
		holder.loc.visible_message(span_danger("[icon2html(holder, viewers(holder))] Внимание: Бомба сдетонировала. Теперь ваш счёт [defusals] на [attempts]. Перенастройка проводов в течение 5 секунд..."))
		reset()
	else
		qdel(src)

/obj/item/bombcore/training/defuse()
	var/obj/machinery/syndicatebomb/holder = loc
	if(istype(holder))
		attempts++
		defusals++
		holder.loc.visible_message(span_notice("[icon2html(holder, viewers(holder))] Внимание: Бомба обезврежена. Теперь ваш счёт [defusals] на [attempts]! Перенастройка проводов в течение 5 секунд..."))
		sleep(50)	//Just in case someone пытается remove the bomb core this gives them a little window to crowbar it out
		if(istype(holder))
			reset()

/obj/item/bombcore/badmin
	name = "badmin payload"
	desc = "Если вы видите это, значит кто-то обосрался!"

/obj/item/bombcore/badmin/defuse() //because we wouldn't want them being harvested by players
	var/obj/machinery/syndicatebomb/B = loc
	qdel(B)
	qdel(src)

/obj/item/bombcore/badmin/summon
	var/summon_path = /obj/item/food/cookie
	var/amt_summon = 1

/obj/item/bombcore/badmin/summon/detonate()
	var/obj/machinery/syndicatebomb/B = loc
	spawn_and_random_walk(summon_path, src, amt_summon, walk_chance=50, admin_spawn=TRUE)
	qdel(B)
	qdel(src)

/obj/item/bombcore/badmin/summon/clown
	summon_path = /mob/living/simple_animal/hostile/clown
	amt_summon 	= 50

/obj/item/bombcore/badmin/summon/clown/defuse()
	playsound(src, 'sound/misc/sadtrombone.ogg', 50)
	..()

/obj/item/bombcore/large
	name = "боезаряд большой бомбы"
	range_heavy = 5
	range_medium = 10
	range_light = 20
	range_flame = 20

/obj/item/bombcore/miniature
	name = "ядро малой бомбы"
	w_class = WEIGHT_CLASS_SMALL
	range_heavy = 1
	range_medium = 2
	range_light = 4
	range_flame = 2

/obj/item/bombcore/chemical
	name = "химичиский заряд"
	desc = "Взрывоопасный заряд предназначенный для распространения химикатов. Свойства ядра могут варьироваться с типом корпуса гранаты. Граната должна быть установлена перед использованием"
	icon_state = "chemcore"
	var/list/beakers = list()
	var/max_beakers = 1 // Read on about grenade casing properties below
	var/spread_range = 5
	var/temp_boost = 50
	var/time_release = 0

/obj/item/bombcore/chemical/detonate()

	if(time_release > 0)
		var/total_volume = 0
		for(var/obj/item/reagent_containers/RC in beakers)
			total_volume += RC.reagents.total_volume

		if(total_volume < time_release) // If it's empty, the detonation is complete.
			if(loc && istype(loc, /obj/machinery/syndicatebomb/))
				qdel(loc)
			qdel(src)
			return

		var/fraction = time_release/total_volume
		var/datum/reagents/reactants = new(time_release)
		reactants.my_atom = src
		for(var/obj/item/reagent_containers/RC in beakers)
			RC.reagents.trans_to(reactants, RC.reagents.total_volume*fraction, 1, 1, 1)
		chem_splash(get_turf(src), spread_range, list(reactants), temp_boost)

		// Detonate it again in one second, until it's out of juice.
		addtimer(CALLBACK(src, PROC_REF(detonate)), 10)

	// If it's not a time release bomb, do normal explosion

	var/list/reactants = list()

	for(var/obj/item/reagent_containers/glass/G in beakers)
		reactants += G.reagents

	for(var/obj/item/slime_extract/S in beakers)
		if(S.Uses)
			for(var/obj/item/reagent_containers/glass/G in beakers)
				G.reagents.trans_to(S, G.reagents.total_volume)

			if(S && S.reagents && S.reagents.total_volume)
				reactants += S.reagents

	if(!chem_splash(get_turf(src), spread_range, reactants, temp_boost))
		playsound(loc, 'sound/items/screwdriver2.ogg', 50, TRUE)
		return // The Explosion didn't do anything. No need to log, or disappear.

	if(adminlog)
		message_admins(adminlog)
		log_game(adminlog)

	playsound(loc, 'sound/effects/bamf.ogg', 75, TRUE, 5)

	if(loc && istype(loc, /obj/machinery/syndicatebomb/))
		qdel(loc)
	qdel(src)

/obj/item/bombcore/chemical/attackby(obj/item/I, mob/user, params)
	if(I.tool_behaviour == TOOL_CROWBAR && beakers.len > 0)
		I.play_tool_sound(src)
		for (var/obj/item/B in beakers)
			B.forceMove(drop_location())
			beakers -= B
		return
	else if(istype(I, /obj/item/reagent_containers/glass/beaker) || istype(I, /obj/item/reagent_containers/glass/bottle))
		if(beakers.len < max_beakers)
			if(!user.transferItemToLoc(I, src))
				return
			beakers += I
			to_chat(user, span_notice("Устанавливаю [src] вместе с [I]."))
		else
			to_chat(user, span_warning("[I] не вмещается! <b>[src.name]</b> может содержать до [max_beakers] контейнеров."))
			return
	..()

/obj/item/bombcore/chemical/CheckParts(list/parts_list)
	..()
	// Using different grenade casings, causes the payload to have different properties.
	var/obj/item/stock_parts/matter_bin/MB = locate(/obj/item/stock_parts/matter_bin) in src
	if(MB)
		max_beakers += MB.rating	// max beakers = 2-5.
		qdel(MB)
	for(var/obj/item/grenade/chem_grenade/G in src)

		if(istype(G, /obj/item/grenade/chem_grenade/large))
			var/obj/item/grenade/chem_grenade/large/LG = G
			max_beakers += 1 // Adding two large grenades only allows for a maximum of 7 beakers.
			spread_range += 2 // Extra range, reduced density.
			temp_boost += 50 // maximum of +150K blast using only large beakers. Not enough to self ignite.
			for(var/obj/item/slime_extract/S in LG.beakers) // And slime cores.
				if(beakers.len < max_beakers)
					beakers += S
					S.forceMove(src)
				else
					S.forceMove(drop_location())

		if(istype(G, /obj/item/grenade/chem_grenade/cryo))
			spread_range -= 1 // Reduced range, but increased density.
			temp_boost -= 100 // minimum of -150K blast.

		if(istype(G, /obj/item/grenade/chem_grenade/pyro))
			temp_boost += 150 // maximum of +350K blast, which is enough to self ignite. Which means a self igniting bomb can't take advantage of other grenade casing properties. Sorry?

		if(istype(G, /obj/item/grenade/chem_grenade/adv_release))
			time_release += 50 // A typical bomb, using basic beakers, will explode over 2-4 seconds. Using two will make the reaction last for less time, but it will be more dangerous overall.

		for(var/obj/item/reagent_containers/glass/B in G)
			if(beakers.len < max_beakers)
				beakers += B
				B.forceMove(src)
			else
				B.forceMove(drop_location())

		qdel(G)

/obj/item/bombcore/emp
	name = "ЭМИ заряд"
	desc = "Сборка сверхпроводящих электромагнитных катушек предназначенных для выпуска мощного импульса для того, чтобы уничтожить электронику"
	range_heavy = 15
	range_medium = 25

/obj/item/bombcore/emp/detonate()
	if(adminlog)
		message_admins(adminlog)
		log_game(adminlog)

	empulse(src, range_heavy, range_medium)

	qdel(src)

///Syndicate Detonator (aka the big red button)///

/obj/item/syndicatedetonator
	name = "большая красная кнопка"
	desc = "Кнопка синхронизации взрыва нескольких бомб. Чтобы избежать инцидентов, взрыв бомб происходит спустя пять секунд после активации."
	icon = 'icons/obj/assemblies.dmi'
	icon_state = "bigred"
	inhand_icon_state = "electronic"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	w_class = WEIGHT_CLASS_TINY
	var/timer = 0
	var/detonated =	0
	var/existent =	0

/obj/item/syndicatedetonator/attack_self(mob/user)
	if(timer < world.time)
		for(var/obj/machinery/syndicatebomb/B in GLOB.machines)
			if(B.active)
				B.detonation_timer = world.time + BUTTON_DELAY
				detonated++
			existent++
		playsound(user, 'sound/machines/click.ogg', 20, TRUE)
		to_chat(user, span_notice("Найдено [existent] бомб. Активировано [detonated] бомб."))
		if(detonated)
			detonated--
			log_bomber(user, "remotely detonated [detonated ? "syndicate bombs" : "a syndicate bomb"] using a", src)
		detonated =	0
		existent =	0
		timer = world.time + BUTTON_COOLDOWN



#undef BUTTON_COOLDOWN
#undef BUTTON_DELAY
