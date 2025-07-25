/obj/item/singularityhammer
	name = "молот сингулярности"
	desc = "Вершина вооружения ближнего боя, этот молот использует силу миниатюрной сингулярности для нанесения сокрушительных ударов."
	icon_state = "singularity_hammer0"
	lefthand_file = 'icons/mob/inhands/weapons/hammers_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/hammers_righthand.dmi'
	worn_icon_state = "singularity_hammer"
	flags_1 = CONDUCT_1
	slot_flags = ITEM_SLOT_BACK
	force = 5
	throwforce = 15
	throw_range = 1
	w_class = WEIGHT_CLASS_HUGE
	armor = list(MELEE = 50, BULLET = 50, LASER = 50, ENERGY = 0, BOMB = 50, BIO = 0, RAD = 0, FIRE = 100, ACID = 100)
	resistance_flags = FIRE_PROOF | ACID_PROOF
	force_string = "LORD SINGULOTH HIMSELF"
	///Is it able to pull shit right now?
	var/charged = TRUE
	///track wielded status on item
	var/wielded = FALSE

/obj/item/singularityhammer/Initialize()
	. = ..()
	RegisterSignal(src, COMSIG_TWOHANDED_WIELD, PROC_REF(on_wield))
	RegisterSignal(src, COMSIG_TWOHANDED_UNWIELD, PROC_REF(on_unwield))

/obj/item/singularityhammer/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/two_handed, force_multiplier=4, icon_wielded="singularity_hammer1")

///triggered on wield of two handed item
/obj/item/singularityhammer/proc/on_wield(obj/item/source, mob/user)
	SIGNAL_HANDLER

	wielded = TRUE

///triggered on unwield of two handed item
/obj/item/singularityhammer/proc/on_unwield(obj/item/source, mob/user)
	SIGNAL_HANDLER

	wielded = FALSE

/obj/item/singularityhammer/update_icon_state()
	. = ..()
	icon_state = "singularity_hammer0"

/obj/item/singularityhammer/proc/recharge()
	charged = TRUE

/obj/item/singularityhammer/proc/vortex(turf/pull, mob/wielder)
	for(var/atom/X in orange(5,pull))
		if(ismovable(X))
			var/atom/movable/A = X
			if(A == wielder)
				continue
			if(A && !A.anchored && !ishuman(X) && !isobserver(X))
				step_towards(A,pull)
				step_towards(A,pull)
				step_towards(A,pull)
			else if(ishuman(X))
				var/mob/living/carbon/human/H = X
				if(istype(H.shoes, /obj/item/clothing/shoes/magboots))
					var/obj/item/clothing/shoes/magboots/M = H.shoes
					if(M.magpulse)
						continue
				H.apply_effect(20, EFFECT_PARALYZE, 0)
				step_towards(H,pull)
				step_towards(H,pull)
				step_towards(H,pull)

/obj/item/singularityhammer/afterattack(atom/A as mob|obj|turf|area, mob/user, proximity)
	. = ..()
	if(!proximity)
		return
	if(wielded)
		if(charged)
			charged = FALSE
			if(istype(A, /mob/living/))
				var/mob/living/Z = A
				Z.take_bodypart_damage(20,0)
			playsound(user, 'sound/weapons/marauder.ogg', 50, TRUE)
			var/turf/target = get_turf(A)
			vortex(target,user)
			addtimer(CALLBACK(src, PROC_REF(recharge)), 100)

/obj/item/mjollnir
	name = "Мьёльнир"
	desc = "Оружие, достойное бога, способное поражать силой молнии. Молот потрескивает от едва сдерживаемой в нём энергии."
	icon_state = "mjollnir0"
	worn_icon_state = "mjolnir"
	lefthand_file = 'icons/mob/inhands/weapons/hammers_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/hammers_righthand.dmi'
	flags_1 = CONDUCT_1
	slot_flags = ITEM_SLOT_BACK
	force = 5
	throwforce = 30
	throw_range = 7
	w_class = WEIGHT_CLASS_HUGE
	var/wielded = FALSE // track wielded status on item

/obj/item/mjollnir/Initialize()
	. = ..()
	RegisterSignal(src, COMSIG_TWOHANDED_WIELD, PROC_REF(on_wield))
	RegisterSignal(src, COMSIG_TWOHANDED_UNWIELD, PROC_REF(on_unwield))

/obj/item/mjollnir/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/two_handed, force_multiplier=5, icon_wielded="mjollnir1", attacksound="sparks")

/// triggered on wield of two handed item
/obj/item/mjollnir/proc/on_wield(obj/item/source, mob/user)
	wielded = TRUE

/// triggered on unwield of two handed item
/obj/item/mjollnir/proc/on_unwield(obj/item/source, mob/user)
	wielded = FALSE

/obj/item/mjollnir/update_icon_state()
	icon_state = "mjollnir0"

/obj/item/mjollnir/proc/shock(mob/living/target)
	target.Stun(1.5 SECONDS)
	target.Knockdown(10 SECONDS)
	var/datum/effect_system/lightning_spread/s = new /datum/effect_system/lightning_spread
	s.set_up(5, 1, target.loc)
	s.start()
	target.visible_message(span_danger("[target.name] поражен [src]!") , \
		span_userdanger("Мощный удар отправляет меня в полет!") , \
		span_hear("Слышу громкий электрический треск!"))
	var/atom/throw_target = get_edge_target_turf(target, get_dir(src, get_step_away(target, src)))
	target.throw_at(throw_target, 200, 4)
	return

/obj/item/mjollnir/attack(mob/living/M, mob/user)
	..()
	if(wielded)
		shock(M)

/obj/item/mjollnir/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	. = ..()
	if(isliving(hit_atom))
		shock(hit_atom)
