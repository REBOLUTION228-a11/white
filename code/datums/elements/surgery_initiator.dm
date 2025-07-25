/// Allows an item to  be used to initiate surgeries.
/datum/element/surgery_initiator
	element_flags = ELEMENT_DETACH

/datum/element/surgery_initiator/Attach(datum/target)
	. = ..()
	if(!isitem(target))
		return ELEMENT_INCOMPATIBLE
	RegisterSignal(target, COMSIG_ITEM_ATTACK, PROC_REF(initiate_surgery_moment))

/datum/element/surgery_initiator/Detach(datum/source)
	UnregisterSignal(source, COMSIG_ITEM_ATTACK)
	return ..()

/// Does the surgery initiation.
/datum/element/surgery_initiator/proc/initiate_surgery_moment(datum/source, atom/target, mob/user)
	SIGNAL_HANDLER
	if(!isliving(target))
		return
	INVOKE_ASYNC(src, PROC_REF(do_initiate_surgery_moment), source, target, user)
	return COMPONENT_CANCEL_ATTACK_CHAIN

/datum/element/surgery_initiator/proc/do_initiate_surgery_moment(datum/source, atom/target, mob/user)
	var/mob/living/livingtarget = target
	var/mob/living/carbon/carbontarget
	var/obj/item/bodypart/affecting
	var/selected_zone = user.zone_selected
	if(iscarbon(livingtarget))
		carbontarget = livingtarget
		affecting = carbontarget.get_bodypart(check_zone(selected_zone))

	var/datum/surgery/current_surgery

	for(var/i_one in livingtarget.surgeries)
		var/datum/surgery/surgeryloop = i_one
		if(surgeryloop.location == selected_zone)
			current_surgery = surgeryloop

	if(!current_surgery)
		var/list/all_surgeries = GLOB.surgeries_list.Copy()
		var/list/available_surgeries = list()

		for(var/i_two in all_surgeries)
			var/datum/surgery/surgeryloop_two = i_two
			if(!surgeryloop_two.possible_locs.Find(selected_zone))
				continue
			if(affecting)
				if(!surgeryloop_two.requires_bodypart)
					continue
				if(surgeryloop_two.requires_bodypart_type && affecting.status != surgeryloop_two.requires_bodypart_type)
					continue
				if(surgeryloop_two.requires_real_bodypart && affecting.is_pseudopart)
					continue
			else if(carbontarget && surgeryloop_two.requires_bodypart) //mob with no limb in surgery zone when we need a limb
				continue
			if(surgeryloop_two.lying_required && livingtarget.body_position != LYING_DOWN)
				continue
			if(!surgeryloop_two.can_start(user, livingtarget))
				continue
			for(var/path in surgeryloop_two.target_mobtypes)
				if(istype(livingtarget, path))
					available_surgeries[surgeryloop_two.name] = surgeryloop_two
					break

		if(!available_surgeries.len)
			return
		var/pick_your_surgery = tgui_input_list(user, "Операция?", "Хирургия", sort_list(available_surgeries))
		//var/pick_your_surgery = input("Begin which procedure?", "Surgery", null, null) as null|anything in sort_list(available_surgeries)
		if(pick_your_surgery && user?.Adjacent(livingtarget) && (source in user))
			var/datum/surgery/surgeryinstance_notonmob = available_surgeries[pick_your_surgery]

			for(var/i_three in livingtarget.surgeries)
				var/datum/surgery/surgeryloop_three = i_three
				if(surgeryloop_three.location == selected_zone)
					return //during the input() another surgery was started at the same location.

			//we check that the surgery is still doable after the input() wait.
			if(carbontarget)
				affecting = carbontarget.get_bodypart(check_zone(selected_zone))
			if(affecting)
				if(!surgeryinstance_notonmob.requires_bodypart)
					return
				if(surgeryinstance_notonmob.requires_bodypart_type && affecting.status != surgeryinstance_notonmob.requires_bodypart_type)
					return
			else if(carbontarget && surgeryinstance_notonmob.requires_bodypart)
				return
			if(surgeryinstance_notonmob.lying_required && livingtarget.body_position != LYING_DOWN)
				return
			if(!surgeryinstance_notonmob.can_start(user, livingtarget))
				return

			if(surgeryinstance_notonmob.ignore_clothes || get_location_accessible(livingtarget, selected_zone))
				var/datum/surgery/procedure = new surgeryinstance_notonmob.type(livingtarget, selected_zone, affecting)
				user.visible_message(span_notice("[user] накладывает [source] на [ru_parse_zone(parse_zone(selected_zone))] [skloname(livingtarget.name, RODITELNI, livingtarget.gender)] для подготовки к операции."), \
					span_notice("Накладываю [source] на [ru_parse_zone(parse_zone(selected_zone))] [skloname(livingtarget.name, RODITELNI, livingtarget.gender)] для подготовки к операции - \an [procedure.name]."))

				log_combat(user, livingtarget, "operated on", null, "(OPERATION TYPE: [procedure.name]) (TARGET AREA: [selected_zone])")
			else
				to_chat(user, span_warning("Для того, чтобы начать операцию на [ru_parse_zone(parse_zone(selected_zone))] [skloname(livingtarget.name, RODITELNI, livingtarget.gender)] необходимо оголить ее!"))

	else if(!current_surgery.step_in_progress)
		attempt_cancel_surgery(current_surgery, source, livingtarget, user)

/// Does the surgery de-initiation.
/datum/element/surgery_initiator/proc/attempt_cancel_surgery(datum/surgery/the_surgery, obj/item/the_item, mob/living/the_patient, mob/user)
	var/selected_zone = user.zone_selected

	if(the_surgery.status == 1)
		the_patient.surgeries -= the_surgery
		user.visible_message(span_notice("[user] убирает [the_item] с [ru_otkuda_zone(parse_zone(selected_zone))] [skloname(the_patient.name, RODITELNI, the_patient.gender)]."), \
			span_notice("Убираю [the_item] с [ru_otkuda_zone(parse_zone(selected_zone))] [skloname(the_patient.name, RODITELNI, the_patient.gender)]."))
		qdel(the_surgery)
		return

	if(!the_surgery.can_cancel)
		return

	var/required_tool_type = TOOL_CAUTERY
	var/obj/item/close_tool = user.get_inactive_held_item()
	var/is_robotic = the_surgery.requires_bodypart_type == BODYPART_ROBOTIC

	if(is_robotic)
		required_tool_type = TOOL_SCREWDRIVER

	if(iscyborg(user))
		close_tool = locate(/obj/item/cautery) in user.held_items
		if(!close_tool)
			to_chat(user, span_warning("Необходимо экипировать прижигатель в неактивный слот для завершения операции на [skloname(the_patient.name, RODITELNI, the_patient.gender)]!"))
			return
	else if(!close_tool || close_tool.tool_behaviour != required_tool_type)
		to_chat(user, span_warning("Необходимо экипировать [is_robotic ? "отвертку" : "прижигатель"] в неактивный слот для завершения операции на [skloname(the_patient.name, RODITELNI, the_patient.gender)]!"))
		return

	if(the_surgery.operated_bodypart)
		the_surgery.operated_bodypart.generic_bleedstacks -= 5

	the_patient.surgeries -= the_surgery
	user.visible_message(span_notice("[user] завершает операцию на [ru_gde_zone(parse_zone(selected_zone))] [skloname(the_patient.name, RODITELNI, the_patient.gender)] при помощи [close_tool] и убирает [the_item]."), \
		span_notice("Завершаю операцию на [ru_gde_zone(parse_zone(selected_zone))] [skloname(the_patient.name, RODITELNI, the_patient.gender)] при помощи [close_tool] и убираю [the_item]."))
	qdel(the_surgery)
