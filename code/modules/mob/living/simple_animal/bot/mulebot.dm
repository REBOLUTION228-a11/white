

// Mulebot - carries crates around for Quartermaster
// Navigates via floor navbeacons
// Remote Controlled from QM's PDA

#define SIGH 0
#define ANNOYED 1
#define DELIGHT 2
#define CHIME 3

/mob/living/simple_animal/bot/mulebot
	name = "MULE-бот"
	desc = "Расшифровывается как \"Multiple Utility Load Effector\"."
	icon_state = "mulebot0"
	density = TRUE
	move_resist = MOVE_FORCE_STRONG
	animate_movement = FORWARD_STEPS
	health = 50
	maxHealth = 50
	speed = 3
	damage_coeff = list(BRUTE = 0.5, BURN = 0.7, TOX = 0, CLONE = 0, STAMINA = 0, OXY = 0)
	a_intent = INTENT_HARM //No swapping
	buckle_lying = 0
	mob_size = MOB_SIZE_LARGE
	buckle_prevents_pull = TRUE // No pulling loaded shit

	radio_key = /obj/item/encryptionkey/headset_cargo
	radio_channel = RADIO_CHANNEL_SUPPLY

	bot_type = MULE_BOT
	model = "MULE"
	bot_core_type = /obj/machinery/bot_core/mulebot
	hud_possible = list(DIAG_STAT_HUD, DIAG_BOT_HUD, DIAG_HUD, DIAG_BATT_HUD, DIAG_PATH_HUD = HUD_LIST_LIST) //Diagnostic HUD views

	var/network_id = NETWORK_BOTS_CARGO
	/// unique identifier in case there are multiple mulebots.
	var/id

	path_image_color = "#7F5200"

	var/base_icon = "mulebot" /// icon_state to use in update_icon_state
	var/atom/movable/load /// what we're transporting
	var/mob/living/passenger /// who's riding us
	var/turf/target /// this is turf to navigate to (location of beacon)
	var/loaddir = 0 /// this the direction to unload onto/load from
	var/home_destination = "" /// tag of home delivery beacon

	var/reached_target = TRUE ///true if already reached the target

	var/auto_return = TRUE /// true if auto return to home beacon after unload
	var/auto_pickup = TRUE /// true if auto-pickup at beacon
	var/report_delivery = TRUE /// true if bot will announce an arrival to a location.

	var/obj/item/stock_parts/cell/cell /// Internal Powercell
	var/cell_move_power_usage = 1///How much power we use when we move.
	var/bloodiness = 0 ///If we've run over a mob, how many tiles will we leave tracks on while moving
	var/num_steps = 0 ///The amount of steps we should take until we rest for a time.



/mob/living/simple_animal/bot/mulebot/Initialize(mapload)
	. = ..()

	RegisterSignal(src, COMSIG_MOB_BOT_PRE_STEP, PROC_REF(check_pre_step))
	RegisterSignal(src, COMSIG_MOB_CLIENT_PRE_MOVE, PROC_REF(check_pre_step))
	RegisterSignal(src, COMSIG_MOB_BOT_STEP, PROC_REF(on_bot_step))
	RegisterSignal(src, COMSIG_MOB_CLIENT_MOVED, PROC_REF(on_bot_step))

	ADD_TRAIT(src, TRAIT_NOMOBSWAP, INNATE_TRAIT)

	if(prob(0.666) && mapload)
		new /mob/living/simple_animal/bot/mulebot/paranormal(loc)
		return INITIALIZE_HINT_QDEL
	wires = new /datum/wires/mulebot(src)

	// Doing this hurts my soul, but simplebot access reworks are for another day.
	var/datum/id_trim/job/cargo_trim = SSid_access.trim_singletons_by_path[/datum/id_trim/job/cargo_technician]
	access_card.add_access(cargo_trim.access + cargo_trim.wildcard_access)
	prev_access = access_card.access.Copy()

	cell = new /obj/item/stock_parts/cell/upgraded(src, 2000)

	var/static/mulebot_count = 0
	mulebot_count += 1
	set_id(suffix || id || "#[mulebot_count]")
	suffix = null
	AddElement(/datum/element/ridable, /datum/component/riding/creature/mulebot)
	diag_hud_set_mulebotcell()

	if(network_id)
		AddComponent(/datum/component/ntnet_interface, network_id)


/mob/living/simple_animal/bot/mulebot/handle_atom_del(atom/A)
	if(A == load)
		unload(0)
	if(A == cell)
		turn_off()
		cell = null
		diag_hud_set_mulebotcell()
	return ..()

/mob/living/simple_animal/bot/mulebot/examine(mob/user)
	. = ..()
	if(open)
		if(cell)
			. += "<hr><span class='notice'>Внутри установлена [cell].</span>"
			. += "\n<span class='info'>Можно использовать <b>ломик</b> для изъятия.</span>"
		else
			. += "<hr><span class='notice'>Внутри отсутствует <b>батарейка</b>.</span>"
	if(load) //observer check is so we don't show the name of the ghost that's sitting on it to prevent metagaming who's ded.
		. += "<hr><span class='notice'>На его платформе [isobserver(load) ? "какая-то призрачная фигура.." : load].</span>"


/mob/living/simple_animal/bot/mulebot/Destroy()
	UnregisterSignal(src, COMSIG_MOB_BOT_PRE_STEP, COMSIG_MOB_CLIENT_PRE_MOVE, COMSIG_MOB_BOT_STEP, COMSIG_MOB_CLIENT_MOVED)
	unload(0)
	QDEL_NULL(wires)
	QDEL_NULL(cell)
	return ..()

/mob/living/simple_animal/bot/mulebot/get_cell()
	return cell

/mob/living/simple_animal/bot/mulebot/turn_on()
	if(!has_power())
		return
	return ..()

/// returns true if the bot is fully powered.
/mob/living/simple_animal/bot/mulebot/proc/has_power(bypass_open_check)
	return (!open || bypass_open_check) && cell && cell.charge > 0 && (!wires.is_cut(WIRE_POWER1) && !wires.is_cut(WIRE_POWER2))


/mob/living/simple_animal/bot/mulebot/proc/set_id(new_id)
	id = new_id
	if(paicard)
		bot_name = "[initial(name)] ([new_id])"
	else
		name = "[initial(name)] ([new_id])"

/mob/living/simple_animal/bot/mulebot/bot_reset()
	..()
	reached_target = FALSE

/mob/living/simple_animal/bot/mulebot/attackby(obj/item/I, mob/living/user, params)
	if(I.tool_behaviour == TOOL_SCREWDRIVER)
		. = ..()
		update_icon()
	else if(istype(I, /obj/item/stock_parts/cell) && open)
		if(cell)
			to_chat(user, span_warning("[capitalize(src.name)] внутри уже есть батарейка!"))
			return
		if(!user.transferItemToLoc(I, src))
			return
		cell = I
		diag_hud_set_mulebotcell()
		visible_message(span_notice("[user] вставляет [cell] в [src.name].") ,
						span_notice("Вставляю [cell] в [src.name]."))
	else if(I.tool_behaviour == TOOL_CROWBAR && open && user.a_intent != INTENT_HARM)
		if(!cell)
			to_chat(user, span_warning("[capitalize(src.name)] не имеет батарейки!"))
			return
		cell.add_fingerprint(user)
		if(Adjacent(user) && !issilicon(user))
			user.put_in_hands(cell)
		else
			cell.forceMove(drop_location())
		visible_message(span_notice("[user] вытаскивает [cell] из [src.name].") ,
						span_notice("Вытаскиваю [cell] из [src.name]."))
		cell = null
		diag_hud_set_mulebotcell()
	else if(is_wire_tool(I) && open)
		return attack_hand(user)
	else if(load && ismob(load))  // chance to knock off rider
		if(prob(1 + I.force * 2))
			unload(0)
			user.visible_message(span_danger("[user] сталкивает [load] с [src.name] используя [I]!") ,
									span_danger("Сталкиваю [load] с [src.name] используя [I]!"))
		else
			to_chat(user, span_warning("Бью [src.name] используя [I], но ничего не происходит!"))
			return ..()
	else
		return ..()

/mob/living/simple_animal/bot/mulebot/emag_act(mob/user)
	if(!emagged)
		emagged = TRUE
	if(!open)
		locked = !locked
		to_chat(user, span_notice("Управление [src.name] [locked ? "заблокировано" : "разблокировано"]!"))
	flick("[base_icon]-emagged", src)
	playsound(src, "sparks", 100, FALSE, SHORT_RANGE_SOUND_EXTRARANGE)

/mob/living/simple_animal/bot/mulebot/update_icon_state() //if you change the icon_state names, please make sure to update /datum/wires/mulebot/on_pulse() as well. <3
	icon_state = "[base_icon][on ? wires.is_cut(WIRE_AVOIDANCE) : 0]"

/mob/living/simple_animal/bot/mulebot/update_overlays()
	. = ..()
	if(open)
		. += "[base_icon]-hatch"
	if(!load || ismob(load)) //mob offsets and such are handled by the riding component / buckling
		return
	var/mutable_appearance/load_overlay = mutable_appearance(load.icon, load.icon_state, layer + 0.01)
	load_overlay.pixel_y = initial(load.pixel_y) + 9
	. += load_overlay

/mob/living/simple_animal/bot/mulebot/ex_act(severity)
	unload(0)
	switch(severity)
		if(EXPLODE_DEVASTATE)
			qdel(src)
		if(EXPLODE_HEAVY)
			wires.cut_random()
			wires.cut_random()
		if(EXPLODE_LIGHT)
			wires.cut_random()


/mob/living/simple_animal/bot/mulebot/bullet_act(obj/projectile/Proj)
	. = ..()
	if(. && !QDELETED(src)) //Got hit and not blown up yet.
		if(prob(50) && !isnull(load))
			unload(0)
		if(prob(25))
			visible_message(span_danger("Что-то закоротило внутри [src.name]!"))
			wires.cut_random()

/mob/living/simple_animal/bot/mulebot/interact(mob/user)
	if(open && !isAI(user))
		wires.interact(user)
	else
		if(wires.is_cut(WIRE_RX) && isAI(user))
			return
		ui_interact(user)

/mob/living/simple_animal/bot/mulebot/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Mule", name)
		ui.open()

/mob/living/simple_animal/bot/mulebot/ui_data(mob/user)
	var/list/data = list()
	data["on"] = on
	data["locked"] = locked
	data["siliconUser"] = user.has_unlimited_silicon_privilege
	data["mode"] = mode ? mode_name[mode] : "Готов"
	data["modeStatus"] = ""
	switch(mode)
		if(BOT_IDLE, BOT_DELIVER, BOT_GO_HOME)
			data["modeStatus"] = "good"
		if(BOT_BLOCKED, BOT_NAV, BOT_WAIT_FOR_NAV)
			data["modeStatus"] = "average"
		if(BOT_NO_ROUTE)
			data["modeStatus"] = "bad"
	data["load"] = get_load_name()
	data["destination"] = destination ? destination : null
	data["home"] = home_destination
	data["destinations"] = GLOB.deliverybeacontags
	data["cell"] = cell ? TRUE : FALSE
	data["cellPercent"] = cell ? cell.percent() : null
	data["autoReturn"] = auto_return
	data["autoPickup"] = auto_pickup
	data["reportDelivery"] = report_delivery
	data["haspai"] = paicard ? TRUE : FALSE
	data["id"] = id
	return data

/mob/living/simple_animal/bot/mulebot/ui_act(action, params)
	. = ..()

	if(. || (locked && !usr.has_unlimited_silicon_privilege))
		return

	switch(action)
		if("lock")
			if(usr.has_unlimited_silicon_privilege)
				locked = !locked
				. = TRUE
		if("power")
			if(on)
				turn_off()
			else if(open)
				to_chat(usr, span_warning("[name] имеет открытую техническую панель!"))
				return
			else if(cell)
				if(!turn_on())
					to_chat(usr, span_warning("Не могу включить [src.name]!"))
					return
			. = TRUE
		else
			bot_control(action, usr, params) // Kill this later.
			. = TRUE

/mob/living/simple_animal/bot/mulebot/bot_control(command, mob/user, list/params = list(), pda = FALSE)
	if(pda && wires.is_cut(WIRE_RX)) // MULE wireless is controlled by wires.
		return

	switch(command)
		if("stop")
			if(mode >= BOT_DELIVER)
				bot_reset()
		if("go")
			if(mode == BOT_IDLE)
				start()
		if("home")
			if(mode == BOT_IDLE || mode == BOT_DELIVER)
				start_home()
		if("destination")
			var/new_dest
			if(pda)
				new_dest = input(user, "Назначение:", name, destination) as null|anything in GLOB.deliverybeacontags
			else
				new_dest = params["value"]
			if(new_dest)
				set_destination(new_dest)
		if("setid")
			var/new_id
			if(pda)
				new_id = stripped_input(user, "Введите ID:", name, id, MAX_NAME_LEN)
			else
				new_id = params["value"]
			if(new_id)
				set_id(new_id)
		if("sethome")
			var/new_home
			if(pda)
				new_home = input(user, "Дом:", name, home_destination) as null|anything in GLOB.deliverybeacontags
			else
				new_home = params["value"]
			if(new_home)
				home_destination = new_home
		if("unload")
			if(load && mode != BOT_HUNT)
				if(loc == target)
					unload(loaddir)
				else
					unload(0)
		if("autoret")
			auto_return = !auto_return
		if("autopick")
			auto_pickup = !auto_pickup
		if("report")
			report_delivery = !report_delivery
		if("ejectpai")
			ejectpairemote(user)

// TODO: remove this; PDAs currently depend on it
/mob/living/simple_animal/bot/mulebot/get_controls(mob/user)
	var/ai = issilicon(user)
	var/dat
	dat += "<h3>Multiple Utility Load Effector Mk. V</h3>"
	dat += "<b>ID:</b> [id]<BR>"
	dat += "<b>Питание:</b> [on ? "Вкл" : "Выкл"]<BR>"
	dat += "<h3>Состояние</h3>"
	dat += "<div class='statusDisplay'>"
	switch(mode)
		if(BOT_IDLE)
			dat += span_good("Готов")
		if(BOT_DELIVER)
			dat += span_good("[mode_name[BOT_DELIVER]]")
		if(BOT_GO_HOME)
			dat += span_good("[mode_name[BOT_GO_HOME]]")
		if(BOT_BLOCKED)
			dat += span_average("[mode_name[BOT_BLOCKED]]")
		if(BOT_NAV,BOT_WAIT_FOR_NAV)
			dat += span_average("[mode_name[BOT_NAV]]")
		if(BOT_NO_ROUTE)
			dat += span_bad("[mode_name[BOT_NO_ROUTE]]")
	dat += "</div>"

	var/load_message = get_load_name()
	dat += "<b>Текущий груз:</b> <i>[load_message ? load_message : "Ничего"]</i><BR>"
	dat += "<b>Цель:</b> [!destination ? "<i>Ничего</i>" : destination]<BR>"
	dat += "<b>Заряд:</b> [cell ? cell.percent() : 0]%"

	if(locked && !ai && !isAdminGhostAI(user))
		dat += "&nbsp;<br /><div class='notice'>Управление заблокировано</div><A href='byond://?src=[REF(src)];op=unlock'>Разблокировать управление</A>"
	else
		dat += "&nbsp;<br /><div class='notice'>Управление разблокировано</div><A href='byond://?src=[REF(src)];op=lock'>Заблокировать управлние</A><BR><BR>"

		dat += "<A href='byond://?src=[REF(src)];op=power'>Переключить питание</A><BR>"
		dat += "<A href='byond://?src=[REF(src)];op=stop'>Стоп</A><BR>"
		dat += "<A href='byond://?src=[REF(src)];op=go'>Двигаться</A><BR>"
		dat += "<A href='byond://?src=[REF(src)];op=home'>Домой</A><BR>"
		dat += "<A href='byond://?src=[REF(src)];op=destination'>Выбрать цель</A><BR>"
		dat += "<A href='byond://?src=[REF(src)];op=setid'>Выбрать ID бота</A><BR>"
		dat += "<A href='byond://?src=[REF(src)];op=sethome'>Выбрать дом</A><BR>"
		dat += "<A href='byond://?src=[REF(src)];op=autoret'>Авто-возвращение домой</A> ([auto_return ? "Вкл":"Выкл"])<BR>"
		dat += "<A href='byond://?src=[REF(src)];op=autopick'>Авто-подбор ящиков</A> ([auto_pickup ? "Вкл":"Выкл"])<BR>"
		dat += "<A href='byond://?src=[REF(src)];op=report'>Оповещать о доставке</A> ([report_delivery ? "Вкл" : "Выкл"])<BR>"
		if(load)
			dat += "<A href='byond://?src=[REF(src)];op=unload'>Разгрузить сейчас</A><BR>"
		dat += "<div class='notice'>Техническая панель закрыта.</div>"

	return dat

/mob/living/simple_animal/bot/mulebot/proc/buzz(type)
	switch(type)
		if(SIGH)
			audible_message(span_hear("[capitalize(src.name)] вздыхающе гудит."))
			playsound(src, 'white/valtos/sounds/error1.ogg', 50, FALSE)
		if(ANNOYED)
			audible_message(span_hear("[capitalize(src.name)] раздражённо жужжит."))
			playsound(src, 'white/valtos/sounds/error2.ogg', 50, FALSE)
		if(DELIGHT)
			audible_message(span_hear("[capitalize(src.name)] делает радостный пинг!"))
			playsound(src, 'sound/machines/ping.ogg', 50, FALSE)
		if(CHIME)
			audible_message(span_hear("[capitalize(src.name)] делает звыньк!"))
			playsound(src, 'sound/machines/chime.ogg', 50, FALSE)
	flick("[base_icon]1", src)


// mousedrop a crate to load the bot
// can load anything if hacked
/mob/living/simple_animal/bot/mulebot/MouseDrop_T(atom/movable/AM, mob/user)
	var/mob/living/L = user

	if (!istype(L))
		return

	if(user.incapacitated() || (istype(L) && L.body_position == LYING_DOWN))
		return

	if(!istype(AM) || isdead(AM) || iscameramob(AM) || istype(AM, /obj/effect/dummy/phased_mob))
		return

	load(AM)


// called to load a crate
/mob/living/simple_animal/bot/mulebot/proc/load(atom/movable/AM)
	if(load || AM.anchored)
		return

	if(!isturf(AM.loc)) //To prevent the loading from stuff from someone's inventory or screen icons.
		return

	var/obj/structure/closet/crate/crate = AM
	if(!istype(crate))
		if(!wires.is_cut(WIRE_LOADCHECK))
			buzz(SIGH)
			return	// if not hacked, only allow crates to be loaded
		crate = null

	if(crate || isobj(AM))
		var/obj/O = AM
		if(O.has_buckled_mobs() || (locate(/mob) in AM)) //can't load non crates objects with mobs buckled to it or inside it.
			buzz(SIGH)
			return

		if(crate)
			crate.close()  //make sure the crate is closed

		O.forceMove(src)

	else if(isliving(AM))
		if(!load_mob(AM)) //forceMove() is handled in buckling
			return

	load = AM
	mode = BOT_IDLE
	update_icon()

///resolves the name to display for the loaded mob. primarily needed for the paranormal subtype since we don't want to show the name of ghosts riding it.
/mob/living/simple_animal/bot/mulebot/proc/get_load_name()
	return load ? load.name : null

/mob/living/simple_animal/bot/mulebot/proc/load_mob(mob/living/M)
	can_buckle = TRUE
	if(buckle_mob(M))
		passenger = M
		load = M
		can_buckle = FALSE
		return TRUE

/mob/living/simple_animal/bot/mulebot/post_unbuckle_mob(mob/living/M)
		load = null
		return ..()

// called to unload the bot
// argument is optional direction to unload
// if zero, unload at bot's location
/mob/living/simple_animal/bot/mulebot/proc/unload(dirn)
	if(QDELETED(load))
		if(load) //if our thing was qdel'd, there's likely a leftover reference. just clear it and remove the overlay. we'll let the bot keep moving around to prevent it abruptly stopping somewhere.
			load = null
			update_icon()
		return

	mode = BOT_IDLE

	var/atom/movable/cached_load = load //cache the load since unbuckling mobs clears the var.

	unbuckle_all_mobs()

	if(load) //don't have to do any of this for mobs.
		load.forceMove(loc)
		load.pixel_y = initial(load.pixel_y)
		load.layer = initial(load.layer)
		load.plane = initial(load.plane)
		load = null

	if(dirn) //move the thing to the delivery point.
		cached_load.Move(get_step(loc,dirn), dirn)

	update_icon()

/mob/living/simple_animal/bot/mulebot/get_status_tab_items()
	. = ..()
	if(cell)
		. += "Заряда осталось: [cell.charge]/[cell.maxcharge]"
	else
		. += text("Нет батарейки!")
	if(load)
		. += "Текущий груз: [get_load_name()]"


/mob/living/simple_animal/bot/mulebot/call_bot()
	..()
	if(path?.len)
		target = ai_waypoint //Target is the end point of the path, the waypoint set by the AI.
		destination = get_area_name(target, TRUE)
		pathset = 1 //Indicates the AI's custom path is initialized.
		start()

/mob/living/simple_animal/bot/mulebot/Move(atom/newloc, direct) //handle leaving bloody tracks. can't be done via Moved() since that can end up putting the tracks somewhere BEFORE we get bloody.
	if(!bloodiness) //important to check this first since Bump() is called in the Move() -> Entered() chain
		return ..()
	var/atom/oldLoc = loc
	. = ..()
	if(!last_move || isspaceturf(oldLoc)) //if we didn't sucessfully move, or if our old location was a spaceturf.
		return
	var/obj/effect/decal/cleanable/blood/tracks/B = new(oldLoc)
	B.add_blood_DNA(return_blood_DNA())
	B.setDir(direct)
	bloodiness--

/mob/living/simple_animal/bot/mulebot/Moved()
	. = ..()

	for(var/mob/living/carbon/human/future_pancake in loc)
		run_over(future_pancake)

	diag_hud_set_mulebotcell()

/mob/living/simple_animal/bot/mulebot/handle_automated_action()
	if(!on)
		return
	if(!has_power())
		turn_off()
		return
	if(mode == BOT_IDLE)
		return
	if(HAS_TRAIT(src, TRAIT_IMMOBILIZED))
		return

	var/speed = (wires.is_cut(WIRE_MOTOR1) ? 0 : 1) + (wires.is_cut(WIRE_MOTOR2) ? 0 : 2)
	if(!speed)//Devide by zero man bad
		return
	num_steps = round(10/speed) //10, 5, or 3 steps, depending on how many wires we have cut
	START_PROCESSING(SSfastprocess, src)

/mob/living/simple_animal/bot/mulebot/process()
	if(!on || client || (num_steps <= 0) || !has_power())
		return PROCESS_KILL
	num_steps--

	switch(mode)
		if(BOT_IDLE) // idle
			return

		if(BOT_DELIVER, BOT_GO_HOME, BOT_BLOCKED) // navigating to deliver,home, or blocked
			if(loc == target) // reached target
				at_target()
				return

			else if(path.len > 0 && target) // valid path
				var/turf/next = path[1]
				reached_target = FALSE
				if(next == loc)
					path -= next
					return
				if(isturf(next))
					if(SEND_SIGNAL(src, COMSIG_MOB_BOT_PRE_STEP) & COMPONENT_MOB_BOT_BLOCK_PRE_STEP)
						return
					var/oldloc = loc
					var/moved = step_towards(src, next) // attempt to move
					if(moved && oldloc!=loc) // successful move
						SEND_SIGNAL(src, COMSIG_MOB_BOT_STEP)
						blockcount = 0
						path -= loc
						if(destination == home_destination)
							mode = BOT_GO_HOME
						else
							mode = BOT_DELIVER

					else // failed to move

						blockcount++
						mode = BOT_BLOCKED
						if(blockcount == 3)
							buzz(ANNOYED)

						if(blockcount > 10) // attempt 10 times before recomputing
							// find new path excluding blocked turf
							buzz(SIGH)
							mode = BOT_WAIT_FOR_NAV
							blockcount = 0
							addtimer(CALLBACK(src, PROC_REF(process_blocked), next), 2 SECONDS)
							return
						return
				else
					buzz(ANNOYED)
					mode = BOT_NAV
					return
			else
				mode = BOT_NAV
				return

		if(BOT_NAV) // calculate new path
			mode = BOT_WAIT_FOR_NAV
			INVOKE_ASYNC(src, PROC_REF(process_nav))

/mob/living/simple_animal/bot/mulebot/proc/process_blocked(turf/next)
	calc_path(avoid=next)
	if(path.len > 0)
		buzz(DELIGHT)
	mode = BOT_BLOCKED

/mob/living/simple_animal/bot/mulebot/proc/process_nav()
	calc_path()

	if(path.len > 0)
		blockcount = 0
		mode = BOT_BLOCKED
		buzz(DELIGHT)

	else
		buzz(SIGH)

		mode = BOT_NO_ROUTE

// calculates a path to the current destination
// given an optional turf to avoid
/mob/living/simple_animal/bot/mulebot/calc_path(turf/avoid = null)
	path = get_path_to(src, target, 250, id=access_card, exclude=avoid)

// sets the current destination
// signals all beacons matching the delivery code
// beacons will return a signal giving their locations
/mob/living/simple_animal/bot/mulebot/proc/set_destination(new_dest)
	new_destination = new_dest
	get_nav()

// starts bot moving to current destination
/mob/living/simple_animal/bot/mulebot/proc/start()
	if(!on)
		return
	if(destination == home_destination)
		mode = BOT_GO_HOME
	else
		mode = BOT_DELIVER
	get_nav()

// starts bot moving to home
// sends a beacon query to find
/mob/living/simple_animal/bot/mulebot/proc/start_home()
	if(!on)
		return
	INVOKE_ASYNC(src, PROC_REF(do_start_home))

/mob/living/simple_animal/bot/mulebot/proc/do_start_home()
	set_destination(home_destination)
	mode = BOT_BLOCKED

// called when bot reaches current target
/mob/living/simple_animal/bot/mulebot/proc/at_target()
	if(!reached_target)
		radio_channel = RADIO_CHANNEL_SUPPLY //Supply channel
		buzz(CHIME)
		reached_target = TRUE

		if(pathset) //The AI called us here, so notify it of our arrival.
			loaddir = dir //The MULE will attempt to load a crate in whatever direction the MULE is "facing".
			if(calling_ai)
				to_chat(calling_ai, span_notice("[icon2html(src, calling_ai)] [src.name] удалённо проигрывает звук!"))
				calling_ai.playsound_local(calling_ai, 'sound/machines/chime.ogg', 40, FALSE)
				calling_ai = null
				radio_channel = RADIO_CHANNEL_AI_PRIVATE //Report on AI Private instead if the AI is controlling us.

		if(load) // if loaded, unload at target
			if(report_delivery)
				speak("Точка назначения <b>[destination]</b> достигнута. Разгружаю [load].",radio_channel)
			unload(loaddir)
		else
			// not loaded
			if(auto_pickup) // find a crate
				var/atom/movable/AM
				if(wires.is_cut(WIRE_LOADCHECK)) // if hacked, load first unanchored thing we find
					for(var/atom/movable/A in get_step(loc, loaddir))
						if(!A.anchored)
							AM = A
							break
				else // otherwise, look for crates only
					AM = locate(/obj/structure/closet/crate) in get_step(loc,loaddir)
				if(AM?.Adjacent(src))
					load(AM)
					if(report_delivery)
						speak("Загружаю [load] в <b>[get_area_name(src)]</b>.", radio_channel)
		// whatever happened, check to see if we return home

		if(auto_return && home_destination && destination != home_destination)
			// auto return set and not at home already
			start_home()
			mode = BOT_BLOCKED
		else
			bot_reset() // otherwise go idle


/mob/living/simple_animal/bot/mulebot/MobBump(mob/M) // called when the bot bumps into a mob
	if(paicard || !isliving(M)) //if there's a PAIcard controlling the bot, they aren't allowed to harm folks.
		return ..()
	var/mob/living/L = M
	if(wires.is_cut(WIRE_AVOIDANCE)) // usually just bumps, but if the avoidance wire is cut, knocks them over.
		if(iscyborg(L))
			visible_message(span_danger("[capitalize(src.name)] влетает в [L]!"))
		else if(L.Knockdown(8 SECONDS))
			log_combat(src, L, "knocked down")
			visible_message(span_danger("[capitalize(src.name)] сбивает [L]!"))
	return ..()

// when mulebot is in the same loc
/mob/living/simple_animal/bot/mulebot/proc/run_over(mob/living/carbon/human/H)
	log_combat(src, H, "run over", null, "(DAMTYPE: [uppertext(BRUTE)])")
	H.visible_message(span_danger("[capitalize(src.name)] давит [H]!") , \
					span_userdanger("[capitalize(src.name)] давит меня!"))
	playsound(src, 'sound/effects/splat.ogg', 50, TRUE)

	var/damage = rand(5,15)
	H.apply_damage(2*damage, BRUTE, BODY_ZONE_HEAD, run_armor_check(BODY_ZONE_HEAD, MELEE))
	H.apply_damage(2*damage, BRUTE, BODY_ZONE_CHEST, run_armor_check(BODY_ZONE_CHEST, MELEE))
	H.apply_damage(0.5*damage, BRUTE, BODY_ZONE_L_LEG, run_armor_check(BODY_ZONE_L_LEG, MELEE))
	H.apply_damage(0.5*damage, BRUTE, BODY_ZONE_R_LEG, run_armor_check(BODY_ZONE_R_LEG, MELEE))
	H.apply_damage(0.5*damage, BRUTE, BODY_ZONE_L_ARM, run_armor_check(BODY_ZONE_L_ARM, MELEE))
	H.apply_damage(0.5*damage, BRUTE, BODY_ZONE_R_ARM, run_armor_check(BODY_ZONE_R_ARM, MELEE))

	var/turf/T = get_turf(src)
	T.add_mob_blood(H)

	var/list/blood_dna = H.get_blood_dna_list()
	add_blood_DNA(blood_dna)
	bloodiness += 4

// player on mulebot attempted to move
/mob/living/simple_animal/bot/mulebot/relaymove(mob/living/user, direction)
	if(user.incapacitated())
		return
	if(load == user)
		unload(0)


//Update navigation data. Called when commanded to deliver, return home, or a route update is needed...
/mob/living/simple_animal/bot/mulebot/proc/get_nav()
	if(!on || wires.is_cut(WIRE_BEACON))
		return

	for(var/obj/machinery/navbeacon/NB in GLOB.deliverybeacons)
		if(NB.location == new_destination) // if the beacon location matches the set destination
									// the we will navigate there
			destination = new_destination
			target = NB.loc
			var/direction = NB.dir // this will be the load/unload dir
			if(direction)
				loaddir = text2num(direction)
			else
				loaddir = 0
			if(destination) // No need to calculate a path if you do not have a destination set!
				calc_path()

/mob/living/simple_animal/bot/mulebot/emp_act(severity)
	. = ..()
	if(cell && !(. & EMP_PROTECT_CONTENTS))
		cell.emp_act(severity)
	if(load)
		load.emp_act(severity)


/mob/living/simple_animal/bot/mulebot/explode()
	visible_message(span_boldannounce("[capitalize(src.name)] взрывается!"))
	var/atom/Tsec = drop_location()

	new /obj/item/assembly/prox_sensor(Tsec)
	new /obj/item/stack/rods(Tsec)
	new /obj/item/stack/rods(Tsec)
	new /obj/item/stack/cable_coil/cut(Tsec)
	if(cell)
		cell.forceMove(Tsec)
		cell.update_icon()
		cell = null

	do_sparks(3, TRUE, src)

	new /obj/effect/decal/cleanable/oil(loc)
	..()

/mob/living/simple_animal/bot/mulebot/remove_air(amount) //To prevent riders suffocating
	return loc ? loc.remove_air(amount) : null

/mob/living/simple_animal/bot/mulebot/resist()
	..()
	if(load)
		unload()

/mob/living/simple_animal/bot/mulebot/UnarmedAttack(atom/A, proximity_flag, list/modifiers)
	if(HAS_TRAIT(src, TRAIT_HANDS_BLOCKED))
		return
	if(isturf(A) && isturf(loc) && loc.Adjacent(A) && load)
		unload(get_dir(loc, A))
	else
		return ..()

/mob/living/simple_animal/bot/mulebot/insertpai(mob/user, obj/item/paicard/card)
	. = ..()
	if(.)
		visible_message(span_notice("[src]'s safeties are locked on."))

/// Checks whether the bot can complete a step_towards, checking whether the bot is on and has the charge to do the move. Returns COMPONENT_MOB_BOT_CANCELSTEP if the bot should not step.
/mob/living/simple_animal/bot/mulebot/proc/check_pre_step(datum/source)
	SIGNAL_HANDLER

	if(!on)
		return COMPONENT_MOB_BOT_BLOCK_PRE_STEP

	if((cell && (cell.charge < cell_move_power_usage)) || !has_power())
		turn_off()
		return COMPONENT_MOB_BOT_BLOCK_PRE_STEP

/// Uses power from the cell when the bot steps.
/mob/living/simple_animal/bot/mulebot/proc/on_bot_step(datum/source)
	SIGNAL_HANDLER

	cell?.use(cell_move_power_usage)

/mob/living/simple_animal/bot/mulebot/paranormal//allows ghosts only unless hacked to actually be useful
	name = "Гульбот"
	desc = "Довольно жутковато выглядящий... Бот с функцией \"Multiple Utility Load Effector\"? Кажется, что он воспринимает только паранормальные силы и по этой причине чертовски бесполезен."
	icon_state = "paranormalmulebot0"
	base_icon = "paranormalmulebot"


/mob/living/simple_animal/bot/mulebot/paranormal/MouseDrop_T(atom/movable/AM, mob/user)
	var/mob/living/L = user

	if(user.incapacitated() || (istype(L) && L.body_position == LYING_DOWN))
		return

	if(!istype(AM) || iscameramob(AM) || istype(AM, /obj/effect/dummy/phased_mob)) //allows ghosts!
		return

	load(AM)

/mob/living/simple_animal/bot/mulebot/paranormal/load(atom/movable/AM)
	if(load || AM.anchored)
		return

	if(!isturf(AM.loc)) //To prevent the loading from stuff from someone's inventory or screen icons.
		return

	if(isobserver(AM))
		visible_message(span_warning("Призрачная фигура появлятся на [src.name]!"))
		RegisterSignal(AM, COMSIG_MOVABLE_MOVED, PROC_REF(ghostmoved))
		AM.forceMove(src)

	else if(!wires.is_cut(WIRE_LOADCHECK))
		buzz(SIGH)
		return // if not hacked, only allow ghosts to be loaded

	else if(isobj(AM))
		var/obj/O = AM
		if(O.has_buckled_mobs() || (locate(/mob) in AM)) //can't load non crates objects with mobs buckled to it or inside it.
			buzz(SIGH)
			return

		if(istype(O, /obj/structure/closet/crate))
			var/obj/structure/closet/crate/crate = O
			crate.close() //make sure it's closed

		O.forceMove(src)

	else if(isliving(AM))
		if(!load_mob(AM)) //buckling is handled in forceMove()
			return

	load = AM
	mode = BOT_IDLE
	update_icon()

/mob/living/simple_animal/bot/mulebot/paranormal/update_overlays()
	. = ..()
	if(!isobserver(load))
		return
	var/mutable_appearance/ghost_overlay = mutable_appearance('icons/mob/mob.dmi', "ghost", layer + 0.01) //use a generic ghost icon, otherwise you can metagame who's dead if they have a custom ghost set
	ghost_overlay.pixel_y = 12
	. += ghost_overlay

/mob/living/simple_animal/bot/mulebot/paranormal/get_load_name() //Don't reveal the name of ghosts so we can't metagame who died and all that.
	. = ..()
	if(. && isobserver(load))
		return "Unknown"

/mob/living/simple_animal/bot/mulebot/paranormal/proc/ghostmoved()
	SIGNAL_HANDLER
	visible_message(span_notice("Призрачная фигура пропадает..."))
	UnregisterSignal(load, COMSIG_MOVABLE_MOVED)
	unload(0)

#undef SIGH
#undef ANNOYED
#undef DELIGHT
#undef CHIME

/obj/machinery/bot_core/mulebot
	req_access = list(ACCESS_CARGO)
