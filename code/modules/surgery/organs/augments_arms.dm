/obj/item/organ/cyberimp/arm
	name = "имплантат руки"
	desc = "You shouldn't see this! Adminhelp and report this as an issue on github!"
	zone = BODY_ZONE_R_ARM
	icon_state = "implant-toolkit"
	w_class = WEIGHT_CLASS_SMALL
	actions_types = list(/datum/action/item_action/organ_action/toggle)
	///A ref for the arm we're taking up. Mostly for the unregister signal upon removal
	var/obj/hand
	//A list of typepaths to create and insert into ourself on init
	var/list/items_to_create = list()
	/// Used to store a list of all items inside, for multi-item implants.
	var/list/items_list = list()// I would use contents, but they shuffle on every activation/deactivation leading to interface inconsistencies.
	/// You can use this var for item path, it would be converted into an item on New().
	var/obj/item/active_item
	/// Sound played when extending
	var/extend_sound = 'sound/mecha/mechmove03.ogg'
	/// Sound played when retracting
	var/retract_sound = 'sound/mecha/mechmove03.ogg'

/obj/item/organ/cyberimp/arm/Initialize()
	. = ..()
	if(ispath(active_item))
		active_item = new active_item(src)
		items_list += WEAKREF(active_item)

	for(var/typepath in items_to_create)
		var/atom/new_item = new typepath(src)
		items_list += WEAKREF(new_item)

	update_appearance()
	SetSlotFromZone()

/obj/item/organ/cyberimp/arm/Destroy()
	hand = null
	active_item = null
	for(var/datum/weakref/ref in items_list)
		var/obj/item/to_del = ref.resolve()
		if(!to_del)
			continue
		qdel(to_del)
	items_list.Cut()
	return ..()

/obj/item/organ/cyberimp/arm/proc/SetSlotFromZone()
	switch(zone)
		if(BODY_ZONE_L_ARM)
			slot = ORGAN_SLOT_LEFT_ARM_AUG
		if(BODY_ZONE_R_ARM)
			slot = ORGAN_SLOT_RIGHT_ARM_AUG
		else
			CRASH("Invalid zone for [type]")

/obj/item/organ/cyberimp/arm/update_icon()
	. = ..()
	transform = (zone == BODY_ZONE_R_ARM) ? null : matrix(-1, 0, 0, 0, 1, 0)

/obj/item/organ/cyberimp/arm/examine(mob/user)
	. = ..()
	if(status == ORGAN_ROBOTIC)
		. += span_info("[capitalize(src.name)] собран в [zone == BODY_ZONE_R_ARM ? "правой" : "левой"] зоне рук. Можно использовать отвертку для его пересборки.")

/obj/item/organ/cyberimp/arm/screwdriver_act(mob/living/user, obj/item/screwtool)
	. = ..()
	if(.)
		return TRUE
	screwtool.play_tool_sound(src)
	if(zone == BODY_ZONE_R_ARM)
		zone = BODY_ZONE_L_ARM
	else
		zone = BODY_ZONE_R_ARM
	SetSlotFromZone()
	to_chat(user, span_notice("Изменил положение [src] и пересобрал его в [zone == BODY_ZONE_R_ARM ? "правой" : "левой"] руке."))
	update_appearance()

/obj/item/organ/cyberimp/arm/Insert(mob/living/carbon/arm_owner, special = FALSE, drop_if_replaced = TRUE)
	. = ..()
	var/side = zone == BODY_ZONE_R_ARM? RIGHT_HANDS : LEFT_HANDS
	hand = arm_owner.hand_bodyparts[side]
	if(hand)
		RegisterSignal(hand, COMSIG_ITEM_ATTACK_SELF, PROC_REF(on_item_attack_self)) //If the limb gets an attack-self, open the menu. Only happens when hand is empty
		RegisterSignal(arm_owner, COMSIG_KB_MOB_DROPITEM_DOWN, PROC_REF(dropkey)) //We're nodrop, but we'll watch for the drop hotkey anyway and then stow if possible.

/obj/item/organ/cyberimp/arm/Remove(mob/living/carbon/arm_owner, special = 0)
	Retract()
	if(hand)
		UnregisterSignal(hand, COMSIG_ITEM_ATTACK_SELF)
		UnregisterSignal(arm_owner, COMSIG_KB_MOB_DROPITEM_DOWN)
	..()

/obj/item/organ/cyberimp/arm/proc/on_item_attack_self()
	SIGNAL_HANDLER
	INVOKE_ASYNC(src, PROC_REF(ui_action_click))

/obj/item/organ/cyberimp/arm/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF || status == ORGAN_ROBOTIC)
		return
	if(prob(15/severity) && owner)
		to_chat(owner, span_warning("Электромагнитный импульс вызвал неисправность [src]!"))
		// give the owner an idea about why his implant is glitching
		Retract()

/**
 * Called when the mob uses the "drop item" hotkey
 *
 * Items inside toolset implants have TRAIT_NODROP, but we can still use the drop item hotkey as a
 * quick way to store implant items. In this case, we check to make sure the user has the correct arm
 * selected, and that the item is actually owned by us, and then we'll hand off the rest to Retract()
**/
/obj/item/organ/cyberimp/arm/proc/dropkey(mob/living/carbon/host)
	SIGNAL_HANDLER
	if(!host)
		return //How did we even get here
	if(hand != host.hand_bodyparts[host.active_hand_index])
		return //wrong hand
	Retract()

/obj/item/organ/cyberimp/arm/proc/Retract()
	if(!active_item || (active_item in src))
		return

	owner?.visible_message(span_notice("[owner] втягивает [active_item] обратно в [owner.ru_ego()] [zone == BODY_ZONE_R_ARM ? "правую" : "левую"] руку."),
		span_notice("[capitalize(active_item)] возвращается в мою [zone == BODY_ZONE_R_ARM ? "правую" : "левую"] руку."),
		span_hear("Слышу короткий механический шелчок."))

	owner.transferItemToLoc(active_item, src, TRUE)
	active_item = null
	playsound(get_turf(owner), retract_sound, 50, TRUE)

/obj/item/organ/cyberimp/arm/proc/Extend(obj/item/augment)
	if(!(augment in src))
		return

	active_item = augment

	active_item.resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	ADD_TRAIT(active_item, TRAIT_NODROP, HAND_REPLACEMENT_TRAIT)
	active_item.slot_flags = null
	active_item.set_custom_materials(null)

	var/side = zone == BODY_ZONE_R_ARM? RIGHT_HANDS : LEFT_HANDS
	var/hand = owner.get_empty_held_index_for_side(side)
	if(hand)
		owner.put_in_hand(active_item, hand)
	else
		var/list/hand_items = owner.get_held_items_for_side(side, all = TRUE)
		var/success = FALSE
		var/list/failure_message = list()
		for(var/i in 1 to hand_items.len) //Can't just use *in* here.
			var/hand_item = hand_items[i]
			if(!owner.dropItemToGround(hand_item))
				failure_message += span_warning("Мой [hand_item] мешает [src]!")
				continue
			to_chat(owner, span_notice("Бросаю [hand_item] чтобы активировать [src]!"))
			success = owner.put_in_hand(active_item, owner.get_empty_held_index_for_side(side))
			break
		if(!success)
			for(var/i in failure_message)
				to_chat(owner, i)
			return
	owner.visible_message(span_notice("[owner] вытягивает [active_item] из [owner.ru_ego()] [zone == BODY_ZONE_R_ARM ? "правой" : "левой"] руки."),
		span_notice("Вытягиваю [active_item] из моей [zone == BODY_ZONE_R_ARM ? "правой" : "левой"] руки."),
		span_hear("Слышу короткий механический шелчок."))
	playsound(get_turf(owner), extend_sound, 50, TRUE)

/obj/item/organ/cyberimp/arm/ui_action_click()
	if((organ_flags & ORGAN_FAILING) || (!active_item && !contents.len))
		to_chat(owner, span_warning("Имплант не отвечает. Похоже что он сломался..."))
		return

	if(!active_item || (active_item in src))
		active_item = null
		if(contents.len == 1)
			Extend(contents[1])
		else
			var/list/choice_list = list()
			for(var/datum/weakref/augment_ref in items_list)
				var/obj/item/augment_item = augment_ref.resolve()
				if(!augment_item)
					items_list -= augment_ref
					continue
				choice_list[augment_item] = image(augment_item)
			var/obj/item/choice = show_radial_menu(owner, owner, choice_list)
			if(owner && owner == usr && owner.stat != DEAD && (src in owner.internal_organs) && !active_item && (choice in contents))
				// This monster sanity check is a nice example of how bad input is.
				Extend(choice)
	else
		Retract()


/obj/item/organ/cyberimp/arm/gun/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	if(prob(30/severity) && owner && !(organ_flags & ORGAN_FAILING))
		Retract()
		owner.visible_message(span_danger(" Из [owner] [zone == BODY_ZONE_R_ARM ? "правой" : "левой"] руки [owner] раздался громкий хлопок!"))
		playsound(get_turf(owner), 'sound/weapons/flashbang.ogg', 100, TRUE)
		to_chat(owner, span_userdanger("Чувствую взрыв в моей [zone == BODY_ZONE_R_ARM ? "правой" : "левой"] руке, сломался имплант!"))
		owner.adjust_fire_stacks(20)
		owner.IgniteMob()
		owner.adjustFireLoss(25)
		organ_flags |= ORGAN_FAILING


/obj/item/organ/cyberimp/arm/gun/laser
	name = "встроенный в руку лазерный имплант"
	desc = "Вариация импланта ручной пушки которая стреляет смертоносными лазернами лучами. Если не используется то пушка остается внутри руки, при стрельбе высовывается из неё."
	icon_state = "arm_laser"
	items_to_create = list(/obj/item/gun/energy/laser/mounted/augment)

/obj/item/organ/cyberimp/arm/gun/laser/l
	zone = BODY_ZONE_L_ARM

/obj/item/organ/cyberimp/arm/gun/taser
	name = "встроенный в руку тазер"
	desc = "Вариация импланта ручной пушки, которая стреляет электродами и вырубающими снарядами. Если не используется то пушка остается внутри руки, при стрельбе высовывается из неё."
	icon_state = "arm_taser"
	items_to_create = list(/obj/item/gun/energy/e_gun/advtaser/mounted)

/obj/item/organ/cyberimp/arm/gun/taser/l
	zone = BODY_ZONE_L_ARM

/obj/item/organ/cyberimp/arm/toolset
	name = "имплант встроенного набора инструментов"
	desc = "Урезанная версия набора инструментов инженерного киборга, сконструированная для установки в руку. Содержит улучшенные версии всех инструментов."
	items_to_create = list(/obj/item/screwdriver/cyborg, /obj/item/wrench/cyborg, /obj/item/weldingtool/largetank/cyborg,
		/obj/item/crowbar/cyborg, /obj/item/wirecutters/cyborg, /obj/item/multitool/cyborg)

/obj/item/organ/cyberimp/arm/toolset/l
	zone = BODY_ZONE_L_ARM

/obj/item/organ/cyberimp/arm/toolset/emag_act(mob/user)
	for(var/datum/weakref/created_item in items_list)
		var/obj/potential_knife = created_item.resolve()
		if(istype(/obj/item/kitchen/knife/combat/cyborg, potential_knife))
			return FALSE

	to_chat(user, span_notice("You unlock [src]'s integrated knife!"))
	items_list += WEAKREF(new /obj/item/kitchen/knife/combat/cyborg(src))
	return TRUE

/obj/item/organ/cyberimp/arm/esword
	name = "встроенный в руку энергетический клинок"
	desc = "Незаконный и крайне опасный кибернетический имплант способный выпустить смертоносный клинок из концетрированной энергии."
	items_to_create = list(/obj/item/melee/energy/blade/hardlight)

/obj/item/organ/cyberimp/arm/medibeam
	name = "встроенная медицинская лучевая пушка"
	desc = "Кибернетический имплант позволяющий пользователю излучать исцеляющие лучи из своей руки."
	items_to_create = list(/obj/item/gun/medbeam)


/obj/item/organ/cyberimp/arm/flash
	name = "integrated high-intensity photon projector" //Why not
	desc = "An integrated projector mounted onto a user's arm that is able to be used as a powerful flash."
	items_to_create = list(/obj/item/assembly/flash/armimplant)

/obj/item/organ/cyberimp/arm/flash/Initialize()
	. = ..()
	for(var/datum/weakref/created_item in items_list)
		var/obj/potential_flash = created_item.resolve()
		if(!istype(potential_flash, /obj/item/assembly/flash/armimplant))
			continue
		var/obj/item/assembly/flash/armimplant/flash = potential_flash
		flash.arm = WEAKREF(src) // Todo: wipe single letter vars out of assembly code

/obj/item/organ/cyberimp/arm/flash/Extend()
	. = ..()
	active_item.set_light_range(7)
	active_item.set_light_on(TRUE)

/obj/item/organ/cyberimp/arm/flash/Retract()
	active_item.set_light_on(FALSE)
	return ..()

/obj/item/organ/cyberimp/arm/baton
	name = "имплант электрификации руки"
	desc = "Незаконный боевой имплант позволяющий пользователю контролировать обезвреживающие электричество из своей руки."
	items_to_create = list(/obj/item/borg/stun)

/obj/item/organ/cyberimp/arm/combat
	name = "боевой кибернетический имплант"
	desc = "Мощный кибернетический имплант встроенный в руку пользователя и содержащий боевые модули."
	items_to_create = list(/obj/item/melee/energy/blade/hardlight, /obj/item/gun/medbeam, /obj/item/borg/stun, /obj/item/assembly/flash/armimplant)

/obj/item/organ/cyberimp/arm/combat/Initialize()
	. = ..()
	for(var/datum/weakref/created_item in items_list)
		var/obj/potential_flash = created_item.resolve()
		if(!istype(potential_flash, /obj/item/assembly/flash/armimplant))
			continue
		var/obj/item/assembly/flash/armimplant/flash = potential_flash
		flash.arm = WEAKREF(src) // Todo: wipe single letter vars out of assembly code

/obj/item/organ/cyberimp/arm/surgery
	name = "имплант хирургических инструментов"
	desc = "Набор хирургических инструментов скрывающийся за скрытой панелью на руке пользователя."
	icon = 'white/Feline/icons/cyber_arm_surgery.dmi'
	icon_state = "cyber_arm_surgery"
	items_to_create = list(/obj/item/surgical_drapes, /obj/item/scalpel/augment, /obj/item/circular_saw/augment, /obj/item/hemostat/augment, /obj/item/retractor/augment, /obj/item/cautery/augment, /obj/item/bonesetter/augment)
