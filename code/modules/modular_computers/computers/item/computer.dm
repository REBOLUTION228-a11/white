// This is the base type that does all the hardware stuff.
// Other types expand it - tablets use a direct subtypes, and
// consoles and laptops use "procssor" item that is held inside machinery piece
/obj/item/modular_computer
	name = "Модульный микрокомпьютер"
	desc = "Маленький портативный микрокомпьютер."
	icon = 'icons/obj/computer.dmi'
	icon_state = "laptop-open"
	light_on = FALSE
	integrity_failure = 0.5
	max_integrity = 100
	armor = list(MELEE = 0, BULLET = 20, LASER = 20, ENERGY = 100, BOMB = 0, BIO = 100, RAD = 100, FIRE = 0, ACID = 0)

	var/enabled = 0 // Whether the computer is turned on.
	var/screen_on = 1 // Whether the computer is active/opened/it's screen is on.
	var/device_theme = "ntos" // Sets the theme for the main menu, hardware config, and file browser apps. Overridden by certain non-NT devices.
	var/datum/computer_file/program/active_program = null // A currently active program running on the computer.
	var/hardware_flag = 0 // A flag that describes this device type
	var/last_power_usage = 0
	var/last_battery_percent = 0 // Used for deciding if battery percentage has chandged
	var/last_world_time = "00:00"
	var/list/last_header_icons
	///Looping sound for when the computer is on
	var/datum/looping_sound/computer/soundloop
	///Whether or not this modular computer uses the looping sound
	var/looping_sound = TRUE

	var/base_active_power_usage = 50 // Power usage when the computer is open (screen is active) and can be interacted with. Remember hardware can use power too.
	var/base_idle_power_usage = 5 // Power usage when the computer is idle and screen is off (currently only applies to laptops)

	// Modular computers can run on various devices. Each DEVICE (Laptop, Console, Tablet,..)
	// must have it's own DMI file. Icon states must be called exactly the same in all files, but may look differently
	// If you create a program which is limited to Laptops and Consoles you don't have to add it's icon_state overlay for Tablets too, for example.

	var/icon_state_unpowered = null // Icon state when the computer is turned off.
	var/icon_state_powered = null // Icon state when the computer is turned on.
	var/icon_state_menu = "menu" // Icon state overlay when the computer is turned on, but no program is loaded that would override the screen.
	var/display_overlays = TRUE // If FALSE, don't draw overlays on this device at all
	var/max_hardware_size = 0 // Maximal hardware w_class. Tablets/PDAs have 1, laptops 2, consoles 4.
	var/steel_sheet_cost = 5 // Amount of steel sheets refunded when disassembling an empty frame of this computer.

	/// List of "connection ports" in this computer and the components with which they are plugged
	var/list/all_components = list()
	/// Lazy List of extra hardware slots that can be used modularly.
	var/list/expansion_bays
	/// Number of total expansion bays this computer has available.
	var/max_bays = 0

	var/list/idle_threads // Idle programs on background. They still receive process calls but can't be interacted with.
	var/obj/physical = null // Object that represents our computer. It's used for Adjacent() and UI visibility checks.
	var/has_light = FALSE //If the computer has a flashlight/LED light/what-have-you installed
	var/comp_light_luminosity = 3 //The brightness of that light
	var/comp_light_color //The color of that light


/obj/item/modular_computer/Initialize()
	. = ..()
	START_PROCESSING(SSobj, src)
	if(!physical)
		physical = src
	comp_light_color = "#FFFFFF"
	idle_threads = list()
	if(looping_sound)
		soundloop = new(src, enabled)
	update_icon()

/obj/item/modular_computer/Destroy()
	kill_program(forced = TRUE)
	STOP_PROCESSING(SSobj, src)
	for(var/H in all_components)
		var/obj/item/computer_hardware/CH = all_components[H]
		if(CH.holder == src)
			CH.on_remove(src)
			CH.holder = null
			all_components.Remove(CH.device_type)
			qdel(CH)
	//Some components will actually try and interact with this, so let's do it later
	QDEL_NULL(soundloop)
	physical = null
	return ..()

/obj/item/modular_computer/pre_attack_secondary(atom/A, mob/living/user, params)
	if(active_program?.tap(A, user, params))
		user.do_attack_animation(A) //Emulate this animation since we kill the attack in three lines
		playsound(loc, 'sound/weapons/tap.ogg', get_clamped_volume(), TRUE, -1) //Likewise for the tap sound
		addtimer(CALLBACK(src, PROC_REF(play_ping)), 0.5 SECONDS, TIMER_UNIQUE) //Slightly delayed ping to indicate success
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	return ..()
/*
/obj/item/modular_computer/pre_attack(atom/A, mob/living/user, params)
	. = ..()
	if(active_program?.tap(A, user, params))
		user.do_attack_animation(A) //Emulate this animation since we kill the attack in three lines
		playsound(loc, 'sound/weapons/tap.ogg', get_clamped_volume(), TRUE, -1) //Likewise for the tap sound
		addtimer(CALLBACK(src, PROC_REF(play_ping)), 0.5 SECONDS, TIMER_UNIQUE) //Slightly delayed ping to indicate success
		return TRUE
	return FALSE
*/
/**
 * Plays a ping sound.
 *
 * Timers runtime if you try to make them call playsound. Yep.
 */
/obj/item/modular_computer/proc/play_ping()
	playsound(loc, 'sound/machines/ping.ogg', get_clamped_volume(), FALSE, -1)

/obj/item/modular_computer/AltClick(mob/user)
	..()
	if(issilicon(user))
		return

	if(user.canUseTopic(src, BE_CLOSE))
		var/obj/item/computer_hardware/card_slot/card_slot2 = all_components[MC_CARD2]
		var/obj/item/computer_hardware/card_slot/card_slot = all_components[MC_CARD]
		return (card_slot2?.try_eject(user) || card_slot?.try_eject(user)) //Try the secondary one first.

// Gets IDs/access levels from card slot. Would be useful when/if PDAs would become modular PCs.
/obj/item/modular_computer/GetAccess()
	var/obj/item/computer_hardware/card_slot/card_slot = all_components[MC_CARD]
	if(card_slot)
		return card_slot.GetAccess()
	return ..()

/obj/item/modular_computer/GetID()
	var/obj/item/computer_hardware/card_slot/card_slot = all_components[MC_CARD]
	var/obj/item/computer_hardware/card_slot/card_slot2 = all_components[MC_CARD2]

	var/obj/item/card/id/first_id = card_slot?.GetID()
	var/obj/item/card/id/second_id = card_slot2?.GetID()

	// We have two IDs, pick the one with the most command accesses, preferring the primary slot.
	if(first_id && second_id)
		var/first_id_tally = SSid_access.tally_access(first_id, ACCESS_FLAG_COMMAND)
		var/second_id_tally = SSid_access.tally_access(second_id, ACCESS_FLAG_COMMAND)

		return (first_id_tally >= second_id_tally) ? first_id : second_id

	// If we don't have both ID slots filled, pick the one that is filled.
	if(first_id)
		return first_id
	if(second_id)
		return second_id

	// Otherwise, we have no ID at all.
	return ..()

/obj/item/modular_computer/get_id_examine_strings(mob/user)
	. = ..()

	var/obj/item/computer_hardware/card_slot/card_slot2 = all_components[MC_CARD2]
	var/obj/item/computer_hardware/card_slot/card_slot = all_components[MC_CARD]

	var/obj/item/card/id/id_card1 = card_slot?.GetID()
	var/obj/item/card/id/id_card2 = card_slot2?.GetID()

	if(id_card1 || id_card2)
		if(id_card1 && id_card2)
			. += "\The [src] is displaying [id_card1] and [id_card2]."
			var/list/id_icons = list()
			id_icons += id_card1.get_id_examine_strings(user)
			id_icons += id_card2.get_id_examine_strings(user)
			. += id_icons.Join(" ")
		else if(id_card1)
			. += "\The [src] is displaying [id_card1]."
			. += id_card1.get_id_examine_strings(user)
		else
			. += "\The [src] is displaying [id_card2]."
			. += id_card2.get_id_examine_strings(user)

/obj/item/modular_computer/RemoveID()
	var/obj/item/computer_hardware/card_slot/card_slot2 = all_components[MC_CARD2]
	var/obj/item/computer_hardware/card_slot/card_slot = all_components[MC_CARD]

	var/removed_id = (card_slot2?.try_eject() || card_slot?.try_eject())
	if(removed_id)
		if(ishuman(loc))
			var/mob/living/carbon/human/human_wearer = loc
			if(human_wearer.wear_id == src)
				human_wearer.sec_hud_set_ID()
		update_slot_icon()
		return removed_id

	return ..()

/obj/item/modular_computer/InsertID(obj/item/inserting_item)
	var/obj/item/computer_hardware/card_slot/card_slot = all_components[MC_CARD]
	var/obj/item/computer_hardware/card_slot/card_slot2 = all_components[MC_CARD2]
	if(!(card_slot || card_slot2))
		return FALSE

	var/obj/item/card/inserting_id = inserting_item.RemoveID()
	if(!inserting_id)
		return FALSE

	if((card_slot?.try_insert(inserting_id)) || (card_slot2?.try_insert(inserting_id)))
		if(ishuman(loc))
			var/mob/living/carbon/human/human_wearer = loc
			if(human_wearer.wear_id == src)
				human_wearer.sec_hud_set_ID()
		update_slot_icon()
		return TRUE

	return FALSE

/obj/item/modular_computer/MouseDrop(obj/over_object, src_location, over_location)
	var/mob/M = usr
	if((!istype(over_object, /atom/movable/screen)) && usr.canUseTopic(src, BE_CLOSE))
		return attack_self(M)
	return ..()

/obj/item/modular_computer/attack_ai(mob/user)
	return attack_self(user)

/obj/item/modular_computer/attack_ghost(mob/dead/observer/user)
	. = ..()
	if(.)
		return
	if(enabled)
		ui_interact(user)
	else if(isAdminGhostAI(user))
		var/response = tgui_alert(user, "This computer is turned off. Would you like to turn it on?", "Admin Override", list("Yes", "No"))
		if(response == "Yes")
			turn_on(user)

/obj/item/modular_computer/emag_act(mob/user)
	if(!enabled)
		to_chat(user, span_warning("Сначала тебе следует включить [src]."))
		return FALSE
	obj_flags |= EMAGGED //Mostly for consistancy purposes; the programs will do their own emag handling
	var/newemag = FALSE
	var/obj/item/computer_hardware/hard_drive/drive = all_components[MC_HDD]
	for(var/datum/computer_file/program/app in drive.stored_files)
		if(!istype(app))
			continue
		if(app.run_emag())
			newemag = TRUE
	if(newemag)
		to_chat(user, span_notice("Провожу <b>[src.name]</b>. Окно консоли немедленно заполняет экран, а белый текст быстро прокручивается."))
		return TRUE
	to_chat(user, span_notice("Провожу <b>[src.name]</b>. Окно консоли заполняет экран, но оно быстро закрывается после того, как в него записано всего несколько строк."))
	return FALSE

/obj/item/modular_computer/examine(mob/user)
	. = ..()
	if(obj_integrity <= integrity_failure * max_integrity)
		. += "<hr><span class='danger'>Оно сильно повреждено!</span>"
	else if(obj_integrity < max_integrity)
		. += "<hr><span class='warning'>Оно повреждено.</span>"

	. += get_modular_computer_parts_examine(user)

/obj/item/modular_computer/update_icon_state()
	icon_state = enabled ? icon_state_powered : icon_state_unpowered
	return ..()

/obj/item/modular_computer/update_overlays()
	. = ..()
	if(!display_overlays)
		return

	if(enabled)
		. += active_program?.program_icon_state || icon_state_menu
	if(obj_integrity <= integrity_failure * max_integrity)
		. += "bsod"
		. += "broken"


// On-click handling. Turns on the computer if it's off and opens the GUI.
/obj/item/modular_computer/interact(mob/user)
	if(enabled)
		ui_interact(user)
	else
		turn_on(user)

/obj/item/modular_computer/proc/turn_on(mob/user)
	var/issynth = issilicon(user) // Robots and AIs get different activation messages.
	if(obj_integrity <= integrity_failure * max_integrity)
		if(issynth)
			to_chat(user, span_warning("Посылаю сигнал активации <b>[src.name]</b>, но он отвечает кодом ошибки. Должно быть, что он повреждён."))
		else
			to_chat(user, span_warning("Нажимаю кнопку питания, но компьютер не загружается, перед повторным выключением отображается множество ошибок."))
		return FALSE

	// If we have a recharger, enable it automatically. Lets computer without a battery work.
	var/obj/item/computer_hardware/recharger/recharger = all_components[MC_CHARGE]
	if(recharger)
		recharger.enabled = 1

	if(all_components[MC_CPU] && use_power()) // use_power() checks if the PC is powered
		if(issynth)
			to_chat(user, span_notice("Посылаю сигнал активации<b>[src.name]</b>, включая его."))
		else
			to_chat(user, span_notice("Нажимаю кнопку питания и запускаете <b>[src.name]</b>."))
		if(looping_sound)
			soundloop.start()
		enabled = 1
		update_icon()
		ui_interact(user)
		return TRUE
	else // Unpowered
		if(issynth)
			to_chat(user, span_warning("Посылаю сигнал активации<b>[src.name]</b>, но тот не отвечает."))
		else
			to_chat(user, span_warning("Нажимаю кнопку питания <b>[src.name]</b>, но тот не отвечает.."))
		return FALSE

// Process currently calls handle_power(), may be expanded in future if more things are added.
/obj/item/modular_computer/process(delta_time)
	if(!enabled) // The computer is turned off
		last_power_usage = 0
		return

	if(obj_integrity <= integrity_failure * max_integrity)
		shutdown_computer()
		return

	if(active_program && active_program.requires_ntnet && !get_ntnet_status(active_program.requires_ntnet_feature))
		active_program.event_networkfailure(0) // Active program requires NTNet to run but we've just lost connection. Crash.

	for(var/I in idle_threads)
		var/datum/computer_file/program/P = I
		if(P.requires_ntnet && !get_ntnet_status(P.requires_ntnet_feature))
			P.event_networkfailure(1)

	if(active_program)
		if(active_program.program_state != PROGRAM_STATE_KILLED)
			active_program.process_tick(delta_time)
			active_program.ntnet_status = get_ntnet_status()
		else
			active_program = null

	for(var/I in idle_threads)
		var/datum/computer_file/program/P = I
		if(P.program_state != PROGRAM_STATE_KILLED)
			P.process_tick(delta_time)
			P.ntnet_status = get_ntnet_status()
		else
			idle_threads.Remove(P)

	handle_power(delta_time) // Handles all computer power interaction
	//check_update_ui_need()

/**
 * Displays notification text alongside a soundbeep when requested to by a program.
 *
 * After checking tha the requesting program is allowed to send an alert, creates
 * a visible message of the requested text alongside a soundbeep. This proc adds
 * text to indicate that the message is coming from this device and the program
 * on it, so the supplied text should be the exact message and ending punctuation.
 *
 * Arguments:
 * The program calling this proc.
 * The message that the program wishes to display.
 */

/obj/item/modular_computer/proc/alert_call(datum/computer_file/program/caller, alerttext, sound = 'sound/machines/twobeep_high.ogg')
	if(!caller || !caller.alert_able || caller.alert_silenced || !alerttext) //Yeah, we're checking alert_able. No, you don't get to make alerts that the user can't silence.
		return
	playsound(src, sound, 50, TRUE)
	visible_message(span_notice(" [src] отображает [caller.filedesc] уведомление: [alerttext]"))
	var/mob/living/holder = loc
	if(istype(holder))
		to_chat(holder, "[icon2html(src)] <span class='notice'> [src] отображает [caller.filedesc] уведомление: [alerttext]</span>")

// Function used by NanoUI's to obtain data for header. All relevant entries begin with "PC_"
/obj/item/modular_computer/proc/get_header_data()
	var/list/data = list()

	data["PC_device_theme"] = device_theme

	var/obj/item/computer_hardware/battery/battery_module = all_components[MC_CELL]
	var/obj/item/computer_hardware/recharger/recharger = all_components[MC_CHARGE]

	if(battery_module && battery_module.battery)
		switch(battery_module.battery.percent())
			if(80 to 200) // 100 should be maximal but just in case..
				data["PC_batteryicon"] = "batt_100.gif"
			if(60 to 80)
				data["PC_batteryicon"] = "batt_80.gif"
			if(40 to 60)
				data["PC_batteryicon"] = "batt_60.gif"
			if(20 to 40)
				data["PC_batteryicon"] = "batt_40.gif"
			if(5 to 20)
				data["PC_batteryicon"] = "batt_20.gif"
			else
				data["PC_batteryicon"] = "batt_5.gif"
		data["PC_batterypercent"] = "[round(battery_module.battery.percent())]%"
		data["PC_showbatteryicon"] = 1
	else
		data["PC_batteryicon"] = "batt_5.gif"
		data["PC_batterypercent"] = "N/C"
		data["PC_showbatteryicon"] = battery_module ? 1 : 0

	if(recharger && recharger.enabled && recharger.check_functionality() && recharger.use_power(0))
		data["PC_apclinkicon"] = "charging.gif"

	switch(get_ntnet_status())
		if(0)
			data["PC_ntneticon"] = "sig_none.gif"
		if(1)
			data["PC_ntneticon"] = "sig_low.gif"
		if(2)
			data["PC_ntneticon"] = "sig_high.gif"
		if(3)
			data["PC_ntneticon"] = "sig_lan.gif"

	if(idle_threads.len)
		var/list/program_headers = list()
		for(var/I in idle_threads)
			var/datum/computer_file/program/P = I
			if(!P.ui_header)
				continue
			program_headers.Add(list(list(
				"icon" = P.ui_header
			)))

		data["PC_programheaders"] = program_headers

	data["PC_stationtime"] = station_time_timestamp()
	data["PC_hasheader"] = 1
	data["PC_showexitprogram"] = active_program ? 1 : 0 // Hides "Exit Program" button on mainscreen
	return data

// Relays kill program request to currently active program. Use this to quit current program.
/obj/item/modular_computer/proc/kill_program(forced = FALSE)
	if(active_program)
		active_program.kill_program(forced)
		active_program = null
	var/mob/user = usr
	if(user && istype(user))
		ui_interact(user) // Re-open the UI on this computer. It should show the main screen now.
	update_icon()

// Returns 0 for No Signal, 1 for Low Signal and 2 for Good Signal. 3 is for wired connection (always-on)
/obj/item/modular_computer/proc/get_ntnet_status(specific_action = 0)
	var/obj/item/computer_hardware/network_card/network_card = all_components[MC_NET]
	if(network_card)
		return network_card.get_signal(specific_action)
	else
		return 0

/obj/item/modular_computer/proc/add_log(text)
	if(!get_ntnet_status())
		return FALSE
	var/obj/item/computer_hardware/network_card/network_card = all_components[MC_NET]

	return SSnetworks.add_log(text, network_card.network_id, network_card.hardware_id)

/obj/item/modular_computer/proc/shutdown_computer(loud = 1)
	kill_program(forced = TRUE)
	for(var/datum/computer_file/program/P in idle_threads)
		P.kill_program(forced = TRUE)
		idle_threads.Remove(P)
	if(looping_sound)
		soundloop.stop()
	if(loud)
		physical.visible_message(span_notice("<b>[src.name]</b> выключается."))
	enabled = 0
	update_icon()

/**
 * Toggles the computer's flashlight, if it has one.
 *
 * Called from ui_act(), does as the name implies.
 * It is seperated from ui_act() to be overwritten as needed.
*/
/obj/item/modular_computer/proc/toggle_flashlight()
	if(!has_light)
		return FALSE
	set_light_on(!light_on)
	if(light_on)
		set_light(comp_light_luminosity, 1, comp_light_color)
	else
		set_light(0)
	return TRUE

/**
 * Sets the computer's light color, if it has a light.
 *
 * Called from ui_act(), this proc takes a color string and applies it.
 * It is seperated from ui_act() to be overwritten as needed.
 * Arguments:
 ** color is the string that holds the color value that we should use. Proc auto-fails if this is null.
*/
/obj/item/modular_computer/proc/set_flashlight_color(color)
	if(!has_light || !color)
		return FALSE
	comp_light_color = color
	set_light_color(color)
	update_light()
	return TRUE

/obj/item/modular_computer/screwdriver_act(mob/user, obj/item/tool)
	if(!all_components.len)
		to_chat(user, span_warning("На этом устройстве не установлены какие-либо компоненты."))
		return
	var/list/component_names = list()
	for(var/h in all_components)
		var/obj/item/computer_hardware/H = all_components[h]
		component_names.Add(H.name)

	var/choice = input(user, "Which component do you want to uninstall?", "Computer maintenance", null) as null|anything in sort_list(component_names)

	if(!choice)
		return

	if(!Adjacent(user))
		return

	var/obj/item/computer_hardware/H = find_hardware_by_name(choice)

	if(!H)
		return

	uninstall_component(H, user)
	return TRUE


/obj/item/modular_computer/attackby(obj/item/W as obj, mob/user as mob)
	// Check for ID first
	if(istype(W, /obj/item/card/id) && InsertID(W))
		return

	// Insert items into the components
	for(var/h in all_components)
		var/obj/item/computer_hardware/H = all_components[h]
		if(H.try_insert(W, user))
			return

	// Insert new hardware
	if(istype(W, /obj/item/computer_hardware))
		if(install_component(W, user))
			return

	if(W.tool_behaviour == TOOL_WRENCH)
		if(all_components.len)
			to_chat(user, span_warning("Извлеките все компоненты из <b>[src.name]</b> перед его разборкой."))
			return
		new /obj/item/stack/sheet/iron( get_turf(src.loc), steel_sheet_cost )
		physical.visible_message(span_notice("<b>[src.name]</b> разобран [user]."))
		relay_qdel()
		qdel(src)
		return

	if(W.tool_behaviour == TOOL_WELDER)
		if(obj_integrity == max_integrity)
			to_chat(user, span_warning("<b>[src.name]</b> не требуется ремонт."))
			return

		if(!W.tool_start_check(user, amount=1))
			return

		to_chat(user, span_notice("Начинаю ремонтировать повреждения <b>[src.name]</b>..."))
		if(W.use_tool(src, user, 20, volume=50, amount=1))
			obj_integrity = max_integrity
			to_chat(user, span_notice("Чиню<b>[src.name]</b>."))
		return

	var/obj/item/computer_hardware/card_slot/card_slot = all_components[MC_CARD]
	// Check to see if we have an ID inside, and a valid input for money
	if(card_slot?.GetID() && iscash(W))
		var/obj/item/card/id/id = card_slot.GetID()
		id.attackby(W, user) // If we do, try and put that attacking object in
		return
	..()

// Used by processor to relay qdel() to machinery type.
/obj/item/modular_computer/proc/relay_qdel()
	return

// Perform adjacency checks on our physical counterpart, if any.
/obj/item/modular_computer/Adjacent(atom/neighbor)
	if(physical && physical != src)
		return physical.Adjacent(neighbor)
	return ..()
