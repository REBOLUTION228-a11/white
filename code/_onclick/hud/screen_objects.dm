/*
	Screen objects
	Todo: improve/re-implement

	Screen objects are only used for the hud and should not appear anywhere "in-game".
	They are used with the client/screen list and the screen_loc var.
	For more information, see the byond documentation on the screen_loc and screen vars.
*/
/atom/movable/screen
	name = ""
	icon = 'icons/hud/screen_gen.dmi'
	plane = HUD_PLANE
	animate_movement = SLIDE_STEPS
	speech_span = SPAN_ROBOT
	vis_flags = VIS_INHERIT_PLANE
	appearance_flags = APPEARANCE_UI
	/// A reference to the object in the slot. Grabs or items, generally.
	var/obj/master = null
	/// A reference to the owner HUD, if any.
	var/datum/hud/hud = null
	/**
	 * Map name assigned to this object.
	 * Automatically set by /client/proc/add_obj_to_map.
	 */
	var/assigned_map
	/**
	 * Mark this object as garbage-collectible after you clean the map
	 * it was registered on.
	 *
	 * This could probably be changed to be a proc, for conditional removal.
	 * But for now, this works.
	 */
	var/del_on_map_removal = TRUE
	var/last_word

/atom/movable/screen/Destroy()
	master = null
	hud = null
	return ..()

/atom/movable/screen/examine(mob/user)
	return list()

/atom/movable/screen/orbit()
	return

/atom/movable/screen/proc/component_click(atom/movable/screen/component_button/component, params)
	return

/atom/movable/screen/text
	icon = null
	icon_state = null
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	screen_loc = "CENTER-7,CENTER-7"
	maptext_height = 480
	maptext_width = 480

/atom/movable/screen/swap_hand
	plane = HUD_PLANE
	name = "сменить руки"

/atom/movable/screen/swap_hand/Click()
	// At this point in client Click() code we have passed the 1/10 sec check and little else
	// We don't even know if it's a middle click
	if(world.time <= usr.next_move)
		return 1

	if(usr.incapacitated())
		return 1

	if(ismob(usr))
		var/mob/M = usr
		M.swap_hand()
	return 1

/atom/movable/screen/skills
	name = "навыки"
	icon = 'icons/hud/screen_midnight.dmi'
	icon_state = "skills"
	screen_loc = ui_skill_menu

/atom/movable/screen/skills/Click()
	if(ishuman(usr))
		var/mob/living/carbon/human/H = usr
		H.mind.print_levels(H)

/atom/movable/screen/craft
	name = "создание предметов"
	icon = 'icons/hud/screen_midnight.dmi'
	icon_state = "craft"
	screen_loc = ui_crafting

/atom/movable/screen/area_creator
	name = "новая зона"
	icon = 'icons/hud/screen_midnight.dmi'
	icon_state = "area_edit"
	screen_loc = ui_building

/atom/movable/screen/area_creator/Click()
	if(usr.incapacitated() || (isobserver(usr) && !isAdminGhostAI(usr)))
		return TRUE
	var/area/A = get_area(usr)
	if(!A.outdoors)
		to_chat(usr, span_warning("There is already a defined structure here."))
		return TRUE
	create_area(usr)

/atom/movable/screen/language_menu
	name = "языки"
	icon = 'icons/hud/screen_midnight.dmi'
	icon_state = "talk_wheel"
	screen_loc = ui_language_menu

/atom/movable/screen/language_menu/Click()
	var/mob/M = usr
	var/datum/language_holder/H = M.get_language_holder()
	H.open_language_menu(usr)

/atom/movable/screen/language_menu/ghost
	screen_loc = ui_ghost_language_menu

/atom/movable/screen/inventory
	/// The identifier for the slot. It has nothing to do with ID cards.
	var/slot_id
	/// Icon when empty. For now used only by humans.
	var/icon_empty
	/// Icon when contains an item. For now used only by humans.
	var/icon_full
	/// The overlay when hovering over with an item in your hand
	var/image/object_overlay
	plane = HUD_PLANE

/atom/movable/screen/inventory/Click(location, control, params)
	// At this point in client Click() code we have passed the 1/10 sec check and little else
	// We don't even know if it's a middle click
	if(world.time <= usr.next_move)
		return TRUE

	if(usr.incapacitated(IGNORE_STASIS))
		return TRUE
	if(ismecha(usr.loc)) // stops inventory actions in a mech
		return TRUE

	if(hud?.mymob && slot_id)
		var/obj/item/inv_item = hud.mymob.get_item_by_slot(slot_id)
		if(inv_item)
			return inv_item.Click(location, control, params)

	if(usr.attack_ui(slot_id))
		usr.update_inv_hands()
	return TRUE

/atom/movable/screen/inventory/MouseEntered()
	..()
	add_overlays()

/atom/movable/screen/inventory/MouseExited()
	..()
	cut_overlay(object_overlay)
	QDEL_NULL(object_overlay)

/atom/movable/screen/inventory/update_icon_state()
	if(!icon_empty)
		icon_empty = icon_state

	if(!hud?.mymob || !slot_id || !icon_full)
		return ..()
	icon_state = hud.mymob.get_item_by_slot(slot_id) ? icon_full : icon_empty
	return ..()

/atom/movable/screen/inventory/proc/add_overlays()
	var/mob/user = hud?.mymob

	if(!user || !slot_id)
		return

	var/obj/item/holding = user.get_active_held_item()

	if(!holding || user.get_item_by_slot(slot_id))
		return

	var/image/item_overlay = image(holding)
	item_overlay.alpha = 92

	if(!user.can_equip(holding, slot_id, TRUE))
		item_overlay.color = "#FF0000"
	else
		item_overlay.color = "#00ff00"

	cut_overlay(object_overlay)
	object_overlay = item_overlay
	add_overlay(object_overlay)

/atom/movable/screen/inventory/hand
	var/mutable_appearance/handcuff_overlay
	var/static/mutable_appearance/blocked_overlay = mutable_appearance('icons/hud/screen_gen.dmi', "blocked")
	var/held_index = 0

/atom/movable/screen/inventory/hand/update_overlays()
	. = ..()

	if(!handcuff_overlay)
		var/state = (!(held_index % 2)) ? "markus" : "gabrielle"
		handcuff_overlay = mutable_appearance('icons/hud/screen_gen.dmi', state)

	if(!hud?.mymob)
		return

	if(iscarbon(hud.mymob))
		var/mob/living/carbon/C = hud.mymob
		if(C.handcuffed)
			. += handcuff_overlay

		if(held_index)
			if(!C.has_hand_for_held_index(held_index))
				. += blocked_overlay

	if(held_index == hud.mymob.active_hand_index)
		. += "hand_active"


/atom/movable/screen/inventory/hand/Click(location, control, params)
	// At this point in client Click() code we have passed the 1/10 sec check and little else
	// We don't even know if it's a middle click
	var/mob/user = hud?.mymob
	if(usr != user)
		return TRUE
	if(world.time <= user.next_move)
		return TRUE
	if(user.incapacitated())
		return TRUE
	if (ismecha(user.loc)) // stops inventory actions in a mech
		return TRUE

	if(user.active_hand_index == held_index)
		var/obj/item/I = user.get_active_held_item()
		if(I)
			I.Click(location, control, params)
	else
		user.swap_hand(held_index)
	return TRUE

/atom/movable/screen/close
	name = "закрыть"
	plane = ABOVE_HUD_PLANE
	icon_state = "backpack_close"

/atom/movable/screen/close/Initialize(mapload, new_master)
	. = ..()
	master = new_master

/atom/movable/screen/close/Click()
	var/datum/component/storage/S = master
	S.hide_from(usr)
	return TRUE

/atom/movable/screen/drop
	name = "бросить"
	icon = 'icons/hud/screen_midnight.dmi'
	icon_state = "act_drop"
	plane = HUD_PLANE

/atom/movable/screen/drop/Click()
	if(usr.stat == CONSCIOUS)
		usr.dropItemToGround(usr.get_active_held_item())

/atom/movable/screen/act_intent
	name = "взаимодействие"
	icon_state = "help"
	screen_loc = ui_acti

/atom/movable/screen/act_intent/Click(location, control, params)
	usr.a_intent_change(INTENT_HOTKEY_RIGHT)

/atom/movable/screen/act_intent/segmented/Click(location, control, params)
	if(usr.client.prefs.toggles & INTENT_STYLE)
		var/_x = text2num(params2list(params)["icon-x"])
		var/_y = text2num(params2list(params)["icon-y"])

		if(_x<=16 && _y<=16)
			usr.a_intent_change(INTENT_HARM)

		else if(_x<=16 && _y>=17)
			usr.a_intent_change(INTENT_HELP)

		else if(_x>=17 && _y<=16)
			usr.a_intent_change(INTENT_GRAB)

		else if(_x>=17 && _y>=17)
			usr.a_intent_change(INTENT_DISARM)
	else
		return ..()

/atom/movable/screen/act_intent/alien
	icon = 'icons/hud/screen_alien.dmi'
	screen_loc = ui_movi

/atom/movable/screen/act_intent/robot
	icon = 'icons/hud/screen_cyborg.dmi'
	screen_loc = ui_borg_intents

/atom/movable/screen/internals
	name = "подача воздуха"
	icon = 'white/valtos/icons/hud.dmi'
	icon_state = "internal0"
	screen_loc = ui_internal

/atom/movable/screen/internals/Click()
	if(!iscarbon(usr))
		return
	var/mob/living/carbon/C = usr
	if(C.incapacitated())
		return

	if(C.internal)
		C.internal = null
		to_chat(C, span_notice("You are no longer running on internals."))
		icon_state = "internal0"
	else
		if(!C.getorganslot(ORGAN_SLOT_BREATHING_TUBE))
			if(!istype(C.wear_mask, /obj/item/clothing/mask))
				to_chat(C, span_warning("You are not wearing an internals mask!"))
				return 1
			else
				var/obj/item/clothing/mask/M = C.wear_mask
				if(M.mask_adjusted) // if mask on face but pushed down
					M.adjustmask(C) // adjust it back
				if( !(M.clothing_flags & MASKINTERNALS) )
					to_chat(C, span_warning("You are not wearing an internals mask!"))
					return

		var/obj/item/I = C.is_holding_item_of_type(/obj/item/tank)
		if(I)
			to_chat(C, span_notice("You are now running on internals from [I] in your [C.get_held_index_name(C.get_held_index_of_item(I))]."))
			C.internal = I
		else if(ishuman(C))
			var/mob/living/carbon/human/H = C
			if(istype(H.s_store, /obj/item/tank))
				to_chat(H, span_notice("You are now running on internals from [H.s_store] on your [H.wear_suit.name]."))
				H.internal = H.s_store
			else if(istype(H.belt, /obj/item/tank))
				to_chat(H, span_notice("You are now running on internals from [H.belt] on your belt."))
				H.internal = H.belt
			else if(istype(H.l_store, /obj/item/tank))
				to_chat(H, span_notice("You are now running on internals from [H.l_store] in your left pocket."))
				H.internal = H.l_store
			else if(istype(H.r_store, /obj/item/tank))
				to_chat(H, span_notice("You are now running on internals from [H.r_store] in your right pocket."))
				H.internal = H.r_store

		//Separate so CO2 jetpacks are a little less cumbersome.
		if(!C.internal && istype(C.back, /obj/item/tank))
			to_chat(C, span_notice("You are now running on internals from [C.back] on your back."))
			C.internal = C.back

		if(C.internal)
			icon_state = "internal1"
		else
			to_chat(C, span_warning("You don't have an oxygen tank!"))
			return
	C.update_action_buttons_icon()

/atom/movable/screen/spacesuit
	name = "Состояние батареи костюма"
	icon = 'white/valtos/icons/hud.dmi'
	icon_state = "spacesuit_0"
	screen_loc = ui_spacesuit

/atom/movable/screen/mov_intent
	name = "бег/шаг"
	icon = 'icons/hud/screen_midnight.dmi'
	icon_state = "running"

/atom/movable/screen/mov_intent/Click()
	toggle(usr)

/atom/movable/screen/mov_intent/update_icon_state()
	switch(hud?.mymob?.m_intent)
		if(MOVE_INTENT_WALK)
			icon_state = "walking"
		if(MOVE_INTENT_RUN)
			icon_state = "running"
		if(MOVE_INTENT_CRAWL)
			icon_state = "crawling"
	return ..()

/atom/movable/screen/mov_intent/proc/toggle(mob/user)
	if(isobserver(user))
		return
	user.toggle_move_intent(user)

/atom/movable/screen/pull
	name = "перестать тащить"
	icon = 'icons/hud/screen_midnight.dmi'
	icon_state = "pull"
	base_icon_state = "pull"

/atom/movable/screen/pull/Click()
	if(isobserver(usr))
		return
	usr.stop_pulling()

/atom/movable/screen/pull/update_icon_state()
	icon_state = "[base_icon_state][hud?.mymob?.pulling ? null : 0]"
	return ..()

/atom/movable/screen/resist
	name = "сопротивляться"
	icon = 'icons/hud/screen_midnight.dmi'
	icon_state = "act_resist"
	plane = HUD_PLANE

/atom/movable/screen/resist/Click()
	if(isliving(usr))
		var/mob/living/L = usr
		L.resist()

/atom/movable/screen/rest
	name = "лежать"
	icon = 'icons/hud/screen_midnight.dmi'
	icon_state = "act_rest"
	base_icon_state = "act_rest"
	plane = HUD_PLANE

/atom/movable/screen/rest/Click()
	if(isliving(usr))
		var/mob/living/L = usr
		L.toggle_resting()

/atom/movable/screen/rest/update_icon_state()
	var/mob/living/user = hud?.mymob
	if(!istype(user))
		return ..()
	icon_state = "[base_icon_state][user.resting ? 0 : null]"
	return ..()


/atom/movable/screen/storage
	name = "хранилище"
	icon_state = "block"
	screen_loc = "7,7 to 10,8"
	plane = HUD_PLANE

/atom/movable/screen/storage/Initialize(mapload, new_master)
	. = ..()
	master = new_master

/atom/movable/screen/storage/Click(location, control, params)
	if(world.time <= usr.next_move)
		return TRUE
	if(usr.incapacitated())
		return TRUE
	if (ismecha(usr.loc)) // stops inventory actions in a mech
		return TRUE
	if(master)
		var/obj/item/I = usr.get_active_held_item()
		if(I)
			master.attackby(null, I, usr, params)
	return TRUE

/atom/movable/screen/throw_catch
	name = "кидать/ловить"
	icon = 'icons/hud/screen_midnight.dmi'
	icon_state = "act_throw_off"

/atom/movable/screen/throw_catch/Click()
	if(iscarbon(usr))
		var/mob/living/carbon/C = usr
		C.toggle_throw_mode()

/atom/movable/screen/zone_sel
	name = "целевая зона"
	icon_state = "zone_sel"
	screen_loc = ui_zonesel
	var/overlay_icon = 'icons/hud/screen_gen.dmi'
	var/static/list/hover_overlays_cache = list()
	var/hovering

/atom/movable/screen/zone_sel/Click(location, control,params)
	if(isobserver(usr))
		return

	var/list/PL = params2list(params)
	var/icon_x = text2num(PL["icon-x"])
	var/icon_y = text2num(PL["icon-y"])
	var/choice = get_zone_at(icon_x, icon_y)
	if (!choice)
		return 1

	return set_selected_zone(choice, usr)

/atom/movable/screen/zone_sel/MouseEntered(location, control, params)
	MouseMove(location, control, params)

/atom/movable/screen/zone_sel/MouseMove(location, control, params)
	if(isobserver(usr))
		return

	var/list/PL = params2list(params)
	var/icon_x = text2num(PL["icon-x"])
	var/icon_y = text2num(PL["icon-y"])
	var/choice = get_zone_at(icon_x, icon_y)

	if(hovering == choice)
		return
	vis_contents -= hover_overlays_cache[hovering]
	hovering = choice

	var/obj/effect/overlay/zone_sel/overlay_object = hover_overlays_cache[choice]
	if(!overlay_object)
		overlay_object = new
		overlay_object.icon_state = "[choice]"
		hover_overlays_cache[choice] = overlay_object
	vis_contents += overlay_object

/obj/effect/overlay/zone_sel
	icon = 'icons/hud/screen_gen.dmi'
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	alpha = 128
	anchored = TRUE
	plane = ABOVE_HUD_PLANE

/atom/movable/screen/zone_sel/MouseExited(location, control, params)
	if(!isobserver(usr) && hovering)
		vis_contents -= hover_overlays_cache[hovering]
		hovering = null

/atom/movable/screen/zone_sel/proc/get_zone_at(icon_x, icon_y)
	switch(icon_y)
		if(1 to 9) //Legs
			switch(icon_x)
				if(10 to 15)
					return BODY_ZONE_R_LEG
				if(17 to 22)
					return BODY_ZONE_L_LEG
		if(10 to 13) //Hands and groin
			switch(icon_x)
				if(8 to 11)
					return BODY_ZONE_R_ARM
				if(12 to 20)
					return BODY_ZONE_PRECISE_GROIN
				if(21 to 24)
					return BODY_ZONE_L_ARM
		if(14 to 22) //Chest and arms to shoulders
			switch(icon_x)
				if(8 to 11)
					return BODY_ZONE_R_ARM
				if(12 to 20)
					return BODY_ZONE_CHEST
				if(21 to 24)
					return BODY_ZONE_L_ARM
		if(23 to 30) //Head, but we need to check for eye or mouth
			if(icon_x in 12 to 20)
				switch(icon_y)
					if(23 to 24)
						if(icon_x in 15 to 17)
							return BODY_ZONE_PRECISE_MOUTH
					if(26) //Eyeline, eyes are on 15 and 17
						if(icon_x in 14 to 18)
							return BODY_ZONE_PRECISE_EYES
					if(25 to 27)
						if(icon_x in 15 to 17)
							return BODY_ZONE_PRECISE_EYES
				return BODY_ZONE_HEAD

/atom/movable/screen/zone_sel/proc/set_selected_zone(choice, mob/user)
	if(user != hud?.mymob)
		return

	if(choice != hud.mymob.zone_selected)
		hud.mymob.zone_selected = choice
		update_icon()

	return TRUE

/atom/movable/screen/zone_sel/update_overlays()
	. = ..()
	if(!hud?.mymob)
		return
	. += mutable_appearance(overlay_icon, "[hud.mymob.zone_selected]")

/atom/movable/screen/zone_sel/alien
	icon = 'icons/hud/screen_alien.dmi'
	overlay_icon = 'icons/hud/screen_alien.dmi'

/atom/movable/screen/zone_sel/robot
	icon = 'icons/hud/screen_cyborg.dmi'

/atom/movable/screen/flash
	name = "flash"
	icon_state = "blank"
	blend_mode = BLEND_ADD
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	layer = FLASH_LAYER
	plane = FULLSCREEN_PLANE

/atom/movable/screen/damageoverlay
	icon = 'icons/hud/screen_full.dmi'
	icon_state = "oxydamageoverlay0"
	name = "dmg"
	blend_mode = BLEND_MULTIPLY
	screen_loc = "CENTER-7,CENTER-7"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = UI_DAMAGE_LAYER
	plane = FULLSCREEN_PLANE

/atom/movable/screen/healths
	name = "здоровье"
	icon_state = "health0"
	screen_loc = ui_health

/atom/movable/screen/healths/alien
	icon = 'icons/hud/screen_alien.dmi'
	screen_loc = ui_alien_health

/atom/movable/screen/healths/robot
	icon = 'icons/hud/screen_cyborg.dmi'
	screen_loc = ui_borg_health

/atom/movable/screen/healths/blob
	name = "масса"
	icon_state = "block"
	screen_loc = ui_internal
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/atom/movable/screen/healths/blob/overmind
	name = "ядро"
	icon = 'icons/hud/blob.dmi'
	icon_state = "corehealth"
	screen_loc = ui_blobbernaut_overmind_health

/atom/movable/screen/healths/guardian
	name = "мастер"
	icon = 'icons/mob/guardian.dmi'
	icon_state = "base"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/atom/movable/screen/healths/revenant
	name = "эссенция"
	icon = 'icons/mob/actions/backgrounds.dmi'
	icon_state = "bg_revenant"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/atom/movable/screen/healths/construct
	icon = 'icons/hud/screen_construct.dmi'
	icon_state = "artificer_health0"
	screen_loc = ui_construct_health
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/atom/movable/screen/healthdoll
	name = "тело"
	screen_loc = ui_healthdoll

/atom/movable/screen/healthdoll/Click()
	if (iscarbon(usr))
		var/mob/living/carbon/C = usr
		C.check_self_for_injuries()

/atom/movable/screen/healthdoll/living
	icon_state = "fullhealth0"
	screen_loc = ui_living_healthdoll
	var/filtered = FALSE //so we don't repeatedly create the mask of the mob every update

/atom/movable/screen/mood
	name = "настроение"
	icon_state = "mood5"
	screen_loc = ui_mood

/atom/movable/screen/mood/attack_tk()
	return

/atom/movable/screen/splash
	icon = 'icons/blank_title.png'
	icon_state = ""
	screen_loc = "1,1"
	plane = SPLASHSCREEN_PLANE
	var/client/holder

/atom/movable/screen/splash/New(client/C, visible, use_previous_title) //TODO: Make this use INITIALIZE_IMMEDIATE, except its not easy
	. = ..()
	if(!istype(C))
		return

	holder = C

	if(!visible)
		alpha = 0

	icon = 'icons/end.png'

	holder.screen += src

/atom/movable/screen/splash/proc/Fade(out, qdel_after = TRUE)
	if(QDELETED(src))
		return
	if(out)
		animate(src, alpha = 0, time = 30)
	else
		alpha = 0
		animate(src, alpha = 255, time = 30)
	if(qdel_after)
		QDEL_IN(src, 30)

/atom/movable/screen/splash/Destroy()
	if(holder)
		holder.screen -= src
		holder = null
	return ..()


/atom/movable/screen/component_button
	var/atom/movable/screen/parent

/atom/movable/screen/component_button/Initialize(mapload, atom/movable/screen/parent)
	. = ..()
	src.parent = parent

/atom/movable/screen/component_button/Click(params)
	if(parent)
		parent.component_click(src, params)

/atom/movable/screen/cooldown_overlay
	name = ""
	icon_state = "cooldown"
	pixel_y = 4
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = RESET_COLOR | PIXEL_SCALE | RESET_TRANSFORM | KEEP_TOGETHER | RESET_ALPHA
	vis_flags = VIS_INHERIT_ID
	var/end_time = 0
	var/atom/movable/screen/parent_button
	var/datum/callback/callback
	var/timer

/atom/movable/screen/cooldown_overlay/Initialize(mapload, button)
	. = ..(mapload)
	parent_button = button

/atom/movable/screen/cooldown_overlay/Destroy()
	stop_cooldown()
	deltimer(timer)
	return ..()

/atom/movable/screen/cooldown_overlay/proc/start_cooldown(end_time, need_timer = TRUE)
	parent_button.color = "#8000007c"
	parent_button.vis_contents += src
	src.end_time = end_time
	set_maptext("[round((end_time - world.time) / 10, 1)]")
	if(need_timer)
		timer = addtimer(CALLBACK(src, PROC_REF(tick)), 1 SECONDS, TIMER_STOPPABLE)

/atom/movable/screen/cooldown_overlay/proc/tick()
	if(world.time >= end_time)
		stop_cooldown()
		return
	set_maptext("[round((end_time - world.time) / 10, 1)]")
	if(timer)
		timer = addtimer(CALLBACK(src, PROC_REF(tick)), 1 SECONDS, TIMER_STOPPABLE)

/atom/movable/screen/cooldown_overlay/proc/stop_cooldown()
	parent_button.color = "#ffffffff"
	parent_button.vis_contents -= src
	if(callback)
		callback.Invoke()

/atom/movable/screen/cooldown_overlay/proc/set_maptext(time)
	maptext = "<div style=\"font-size:6pt;font:'Arial Black';text-align:center;\">[time]</div>"

/proc/start_cooldown(atom/movable/screen/cooldown_overlay/button, time, datum/callback/callback)
	if(!time)
		return
	var/atom/movable/screen/cooldown_overlay/cooldown = new(button, button)
	if(callback)
		cooldown.callback = callback
		cooldown.start_cooldown(time)
	else
		cooldown.start_cooldown(time, FALSE)
	return cooldown

/atom/movable/screen/stamina
	name = "Выносливость"
	icon_state = "stamina0"
	screen_loc = ui_stamina
