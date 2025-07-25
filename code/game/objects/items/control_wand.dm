#define WAND_OPEN "open"
#define WAND_BOLT "bolt"
#define WAND_EMERGENCY "emergency"
#define WAND_SHOCK "shock"

/obj/item/door_remote
	icon_state = "gangtool-white"
	inhand_icon_state = "electronic"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	icon = 'icons/obj/device.dmi'
	name = "пульт управления"
	desc = "Устройство для удаленного управления шлюзами."
	w_class = WEIGHT_CLASS_TINY
	var/mode = WAND_OPEN
	var/region_access = REGION_GENERAL
	var/list/access_list
	network_id = NETWORK_DOOR_REMOTES

/obj/item/door_remote/Initialize(mapload)
	. = ..()
	access_list = SSid_access.get_region_access_list(list(region_access))
	RegisterSignal(src, COMSIG_COMPONENT_NTNET_NAK, PROC_REF(bad_signal))

/obj/item/door_remote/proc/bad_signal(datum/source, datum/netdata/data, error_code)
	SIGNAL_HANDLER
	if(QDELETED(data.user))
		return // can't send a message to a missing user
	if(error_code == NETWORK_ERROR_UNAUTHORIZED)
		to_chat(data.user, span_notice("Этот пульт управления не хочет работать с этим шлюзом."))
	else
		to_chat(data.user, span_notice("ОШИБКА: [error_code]"))

/obj/item/door_remote/attack_self(mob/user)
	var/static/list/desc = list(WAND_OPEN = "Открыть шлюз", WAND_BOLT = "Переключить болты", WAND_EMERGENCY = "Переключить экстренный доступ", WAND_SHOCK = "Медиум-рейр")
	switch(mode)
		if(WAND_OPEN)
			mode = WAND_BOLT
		if(WAND_BOLT)
			mode = WAND_EMERGENCY
		if(WAND_EMERGENCY)
			if(obj_flags & EMAGGED)
				mode = WAND_SHOCK
			else
				mode = WAND_OPEN
		if(WAND_SHOCK)
			mode = WAND_OPEN
	to_chat(user, span_notice("Режим: [desc[mode]]."))

/obj/item/door_remote/emag_act(mob/user, obj/item/card/emag/E)
	. = ..()
	if(obj_flags & EMAGGED)
		return
	obj_flags |= EMAGGED
	to_chat(user, span_warning("Шокирующий режим разблокирован."))

// Airlock remote works by sending NTNet packets to whatever it's pointed at.
/obj/item/door_remote/afterattack(atom/A, mob/user)
	. = ..()
	var/datum/component/ntnet_interface/target_interface = A.GetComponent(/datum/component/ntnet_interface)

	// Try to find an airlock in the clicked turf
	if(!target_interface)
		var/obj/machinery/door/airlock/door = locate() in get_turf(A)
		if(door)
			target_interface = door.GetComponent(/datum/component/ntnet_interface)

	if(!target_interface)
		return

	user.set_machine(src)
	// Generate a control packet.
	var/datum/netdata/data = new(list("data" = mode,"data_secondary" = "toggle"))
	data.receiver_id = target_interface.hardware_id
	data.passkey = access_list
	data.user = user // for responce message

	ntnet_send(data)

/obj/item/door_remote/omni
	name = "всешлюзник"
	desc = "Имеет доступ ко всем шлюзам на этой деревне."
	icon_state = "gangtool-yellow"
	region_access = REGION_ALL_STATION

/obj/item/door_remote/captain
	name = "пульт управления командования"
	icon_state = "gangtool-yellow"
	region_access = REGION_COMMAND

/obj/item/door_remote/chief_engineer
	name = "инженерный пульт управления"
	icon_state = "gangtool-orange"
	region_access = REGION_ENGINEERING

/obj/item/door_remote/research_director
	name = "научный пульт управления"
	icon_state = "gangtool-purple"
	region_access = REGION_RESEARCH

/obj/item/door_remote/head_of_security
	name = "пульт управления безопасности"
	icon_state = "gangtool-red"
	region_access = REGION_SECURITY

/obj/item/door_remote/quartermaster
	name = "пульт управления снабжения"
	desc = "Устройство удаленного доступа к шлюзам. Этот имеет доступ к хранилищу."
	icon_state = "gangtool-green"
	region_access = REGION_SUPPLY

/obj/item/door_remote/chief_medical_officer
	name = "медицинский пульт управления"
	icon_state = "gangtool-blue"
	region_access = REGION_MEDBAY

/obj/item/door_remote/civilian
	name = "гражданский пульт управления"
	icon_state = "gangtool-white"
	region_access = REGION_GENERAL

#undef WAND_OPEN
#undef WAND_BOLT
#undef WAND_EMERGENCY
#undef WAND_SHOCK
