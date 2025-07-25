/datum/element/decal
	element_flags = ELEMENT_BESPOKE|ELEMENT_DETACH
	id_arg_index = 2
	/// Whether this decal can be cleaned.
	var/cleanable
	/// A description this decal appends to the target's examine message.
	var/description
	/// If true this was initialized with no set direction - will follow the parent dir.
	var/directional
	/// The base icon state that this decal was initialized with.
	var/base_icon_state
	/// What smoothing junction this was initialized with.
	var/smoothing
	/// The overlay applied by this decal to the target.
	var/mutable_appearance/pic

/// Remove old decals and apply new decals after rotation as necessary
/datum/controller/subsystem/processing/dcs/proc/rotate_decals(datum/source, old_dir, new_dir)
	SIGNAL_HANDLER

	if(old_dir == new_dir)
		return
	var/list/resulting_decals_params = list() // param lists
	var/list/old_decals = list() //instances

	if(!source.comp_lookup || !source.comp_lookup[COMSIG_ATOM_UPDATE_OVERLAYS])
		//should probably also unregister itself
		return

	if(length(source.comp_lookup[COMSIG_ATOM_UPDATE_OVERLAYS]))
		for(var/datum/element/decal/decal in source.comp_lookup[COMSIG_ATOM_UPDATE_OVERLAYS])
			old_decals += decal
			resulting_decals_params += list(decal.get_rotated_parameters(old_dir,new_dir))
	else
		var/datum/element/decal/decal = source.comp_lookup[COMSIG_ATOM_UPDATE_OVERLAYS]
		if(!istype(decal))
			return
		old_decals += decal
		resulting_decals_params += list(decal.get_rotated_parameters(old_dir,new_dir))

	//Instead we could generate ids and only remove duplicates to save on churn on four-corners symmetry ?
	for(var/datum/element/decal/decal in old_decals)
		decal.Detach(source)

	for(var/result in resulting_decals_params)
		source.AddElement(/datum/element/decal, result["icon"], result["icon_state"], result["dir"], result["plane"], result["layer"], result["alpha"], result["color"], result["smoothing"], result["cleanable"], result["desc"])


/datum/element/decal/proc/get_rotated_parameters(old_dir,new_dir)
	var/rotation = 0
	if(directional) //Even when the dirs are the same rotation is coming out as not 0 for some reason
		rotation = SIMPLIFY_DEGREES(dir2angle(new_dir)-dir2angle(old_dir))
		new_dir = turn(pic.dir,-rotation)
	return list(
		"icon" = pic.icon,
		"icon_state" = base_icon_state,
		"dir" = new_dir,
		"plane" = pic.plane,
		"layer" = pic.layer,
		"alpha" = pic.alpha,
		"color" = pic.color,
		"smoothing" = smoothing,
		"cleanable" = cleanable,
		"desc" = description
	)



/datum/element/decal/Attach(atom/target, _icon, _icon_state, _dir, _plane=FLOAT_PLANE, _layer=FLOAT_LAYER, _alpha=255, _color, _smoothing, _cleanable=FALSE, _description, mutable_appearance/_pic)
	. = ..()
	if(!isatom(target))
		return ELEMENT_INCOMPATIBLE
	if(_pic)
		pic = _pic
	else if(!generate_appearance(_icon, _icon_state, _dir, _plane, _layer, _color, _alpha, _smoothing, target))
		return ELEMENT_INCOMPATIBLE
	description = _description
	cleanable = _cleanable
	directional = _dir
	base_icon_state = _icon_state
	smoothing = _smoothing

	RegisterSignal(target,COMSIG_ATOM_UPDATE_OVERLAYS,PROC_REF(apply_overlay), TRUE)
	if(target.flags_1 & INITIALIZED_1)
		target.update_icon() //could use some queuing here now maybe.
	else
		RegisterSignal(target,COMSIG_ATOM_AFTER_SUCCESSFUL_INITIALIZE,PROC_REF(late_update_icon), TRUE)
	if(isitem(target))
		INVOKE_ASYNC(target, TYPE_PROC_REF(/obj/item, update_slot_icon), TRUE)
	if(_dir)
		SSdcs.RegisterSignal(target,COMSIG_ATOM_DIR_CHANGE, /datum/controller/subsystem/processing/dcs/proc/rotate_decals, TRUE)
	if(!isnull(_smoothing))
		RegisterSignal(target, COMSIG_ATOM_SMOOTHED_ICON, PROC_REF(smooth_react), TRUE)
	if(_cleanable)
		RegisterSignal(target, COMSIG_COMPONENT_CLEAN_ACT, PROC_REF(clean_react), TRUE)
	if(_description)
		RegisterSignal(target, COMSIG_PARENT_EXAMINE, PROC_REF(examine),TRUE)

	RegisterSignal(target, COMSIG_TURF_ON_SHUTTLE_MOVE, PROC_REF(shuttle_move_react),TRUE)

/**
 * ## generate_appearance
 *
 * If the decal was not given an appearance, it will generate one based on the other given arguments.
 * element won't be compatible if it cannot do either
 * all args are fed into creating an image, they are byond vars for images you'll recognize in the byond docs
 * (except source, source is the object whose appearance we're copying.)
 */
/datum/element/decal/proc/generate_appearance(_icon, _icon_state, _dir, _plane, _layer, _color, _alpha, _smoothing, source)
	if(!_icon || !_icon_state)
		return FALSE
	var/temp_image = image(_icon, null, isnull(_smoothing) ? _icon_state : "[_icon_state]-[_smoothing]", _layer, _dir)
	pic = new(temp_image)
	pic.plane = _plane
	pic.color = _color
	pic.alpha = _alpha
	return TRUE

/datum/element/decal/Detach(atom/source)
	UnregisterSignal(source, list(COMSIG_ATOM_DIR_CHANGE, COMSIG_COMPONENT_CLEAN_ACT, COMSIG_PARENT_EXAMINE, COMSIG_ATOM_UPDATE_OVERLAYS, COMSIG_TURF_ON_SHUTTLE_MOVE, COMSIG_ATOM_SMOOTHED_ICON))
	SSdcs.UnregisterSignal(source, COMSIG_ATOM_DIR_CHANGE)
	source.update_icon()
	if(isitem(source))
		INVOKE_ASYNC(source, TYPE_PROC_REF(/obj/item, update_slot_icon))
	SEND_SIGNAL(source, COMSIG_TURF_DECAL_DETACHED, description, cleanable, directional, pic)
	return ..()

/datum/element/decal/proc/late_update_icon(atom/source)
	SIGNAL_HANDLER

	if(source && istype(source))
		source.update_icon()
		UnregisterSignal(source, COMSIG_ATOM_AFTER_SUCCESSFUL_INITIALIZE)


/datum/element/decal/proc/apply_overlay(atom/source, list/overlay_list)
	SIGNAL_HANDLER

	overlay_list += pic

/datum/element/decal/proc/clean_react(datum/source, clean_types)
	SIGNAL_HANDLER

	if(clean_types & cleanable)
		Detach(source)
		return COMPONENT_CLEANED
	return NONE

/datum/element/decal/proc/examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER

	examine_list += "\n" + description

/datum/element/decal/proc/shuttle_move_react(datum/source, turf/new_turf)
	SIGNAL_HANDLER

	if(new_turf == source)
		return
	Detach(source)
	new_turf.AddElement(type, pic.icon, base_icon_state, directional, pic.plane, pic.layer, pic.alpha, pic.color, smoothing, cleanable, description)

/**
 * Reacts to the source atom smoothing.
 *
 * Arguments:
 * - [source][/atom]: The source of the signal and recently smoothed atom.
 */
/datum/element/decal/proc/smooth_react(atom/source)
	SIGNAL_HANDLER
	var/smoothing_junction = source.smoothing_junction
	if(smoothing_junction == smoothing)
		return NONE

	Detach(source)
	source.AddElement(type, pic.icon, base_icon_state, directional, pic.plane, pic.layer, pic.alpha, pic.color, smoothing_junction, cleanable, description)
	return NONE
