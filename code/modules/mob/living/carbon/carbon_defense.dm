
#define SHAKE_ANIMATION_OFFSET 4

/mob/living/carbon/get_eye_protection()
	. = ..()
	var/obj/item/organ/eyes/E = getorganslot(ORGAN_SLOT_EYES)
	if(!E)
		return INFINITY //Can't get flashed without eyes
	else
		. += E.flash_protect
	if(isclothing(head)) //Adds head protection
		. += head.flash_protect
	if(isclothing(glasses)) //Glasses
		. += glasses.flash_protect
	if(isclothing(wear_mask)) //Mask
		. += wear_mask.flash_protect

/mob/living/carbon/get_ear_protection()
	. = ..()
	var/obj/item/organ/ears/E = getorganslot(ORGAN_SLOT_EARS)
	if(!E)
		return INFINITY
	else
		. += E.bang_protect

/mob/living/carbon/is_mouth_covered(head_only = 0, mask_only = 0)
	if( (!mask_only && head && (head.flags_cover & HEADCOVERSMOUTH)) || (!head_only && wear_mask && (wear_mask.flags_cover & MASKCOVERSMOUTH)) )
		return TRUE

/mob/living/carbon/is_eyes_covered(check_glasses = TRUE, check_head = TRUE, check_mask = TRUE)
	if(check_head && head && (head.flags_cover & HEADCOVERSEYES))
		return head
	if(check_mask && wear_mask && (wear_mask.flags_cover & MASKCOVERSEYES))
		return wear_mask
	if(check_glasses && glasses && (glasses.flags_cover & GLASSESCOVERSEYES))
		return glasses
/mob/living/carbon/is_pepper_proof(check_head = TRUE, check_mask = TRUE)
	if(check_head &&(head?.flags_cover & PEPPERPROOF))
		return head
	if(check_mask &&(wear_mask?.flags_cover & PEPPERPROOF))
		return wear_mask

/mob/living/carbon/check_projectile_dismemberment(obj/projectile/P, def_zone)
	var/obj/item/bodypart/affecting = get_bodypart(def_zone)
	if(affecting && affecting.dismemberable && affecting.get_damage() >= (affecting.max_damage - P.dismemberment))
		affecting.dismember(P.damtype, TRUE, FALSE)

/mob/living/carbon/proc/can_catch_item(skip_throw_mode_check)
	. = FALSE
	if(!skip_throw_mode_check && !throw_mode)
		return
	if(get_active_held_item())
		return
	if(HAS_TRAIT(src, TRAIT_HANDS_BLOCKED))
		return
	return TRUE

/mob/living/carbon/hitby(atom/movable/AM, skipcatch, hitpush = TRUE, blocked = FALSE, datum/thrownthing/throwingdatum)
	if(!skipcatch && can_catch_item() && istype(AM, /obj/item) && isturf(AM.loc))
		var/obj/item/I = AM
		I.attack_hand(src)
		if(get_active_held_item() == I) //if our attack_hand() picks up the item...
			visible_message(span_warning("<b>[src]</b> ловит <b>[I.name]</b>!") , \
							span_userdanger("Ловлю <b>[I.name]</b>!"))
			throw_mode_off(THROW_MODE_TOGGLE)
			return TRUE
	return ..()


/mob/living/carbon/attacked_by(obj/item/I, mob/living/user)
	var/obj/item/bodypart/affecting
	if(user == src)
		affecting = get_bodypart(check_zone(user.zone_selected)) //we're self-mutilating! yay!
	else
		var/zone_hit_chance = 80
		if(body_position == LYING_DOWN) // half as likely to hit a different zone if they're on the ground
			zone_hit_chance += 10
		affecting = get_bodypart(ran_zone(user.zone_selected, zone_hit_chance))
	if(!affecting) //missing limb? we select the first bodypart (you can never have zero, because of chest)
		affecting = bodyparts[1]
	SEND_SIGNAL(I, COMSIG_ITEM_ATTACK_ZONE, src, user, affecting)
	send_item_attack_message(I, user, affecting.name, affecting)
	if(I.force)
		var/attack_direction = get_dir(user, src)
		apply_damage(I.force, I.damtype, affecting, wound_bonus = I.wound_bonus, bare_wound_bonus = I.bare_wound_bonus, sharpness = I.get_sharpness(), attack_direction = attack_direction)
		if(I.damtype == BRUTE && affecting.status == BODYPART_ORGANIC)
			if(prob(33))
				I.add_mob_blood(src)
				var/turf/location = get_turf(src)
				add_splatter_floor(location)
				if(get_dist(user, src) <= 1)	//people with TK won't get smeared with blood
					user.add_mob_blood(src)
				if(affecting.body_zone == BODY_ZONE_HEAD)
					if(wear_mask)
						wear_mask.add_mob_blood(src)
						update_inv_wear_mask()
					if(wear_neck)
						wear_neck.add_mob_blood(src)
						update_inv_neck()
					if(head)
						head.add_mob_blood(src)
						update_inv_head()

		return TRUE //successful attack

/mob/living/carbon/send_item_attack_message(obj/item/I, mob/living/user, hit_area, obj/item/bodypart/hit_bodypart)
	if(!I.force && !length(I.attack_verb_simple) && !length(I.attack_verb_continuous))
		return
	var/message_verb_continuous = length(I.attack_verb_continuous) ? "[pick(I.attack_verb_continuous)]" : "бьёт"
	var/message_verb_simple = length(I.attack_verb_simple) ? "[pick(I.attack_verb_simple)]" : "бьёт"

	var/extra_wound_details = ""
	if(I.damtype == BRUTE && hit_bodypart.can_dismember())
		var/mangled_state = hit_bodypart.get_mangled_state()
		var/bio_state = get_biological_state()
		if(mangled_state == BODYPART_MANGLED_BOTH)
			extra_wound_details = ", угрожая разорвать полностью"
		else if((mangled_state == BODYPART_MANGLED_FLESH && I.get_sharpness()) || (mangled_state & BODYPART_MANGLED_BONE && bio_state == BIO_JUST_BONE))
			extra_wound_details = ", [I.get_sharpness() == SHARP_EDGED ? "прорезаясь" : "протыкая"] до костей"
		else if((mangled_state == BODYPART_MANGLED_BONE && I.get_sharpness()) || (mangled_state & BODYPART_MANGLED_FLESH && bio_state == BIO_JUST_FLESH))
			extra_wound_details = ", [I.get_sharpness() == SHARP_EDGED ? "прорезаясь через" : "протыкая"] оставшуюся плоть"

	var/message_hit_area = ""
	if(hit_area)
		message_hit_area = "в [ru_parse_zone(hit_area)]"
	var/attack_message_spectator = "<b>[src]</b> [message_verb_continuous] [message_hit_area] <b>[skloname(I.name, TVORITELNI, I.gender)][extra_wound_details]</b>!"
	var/attack_message_victim = "[capitalize(message_verb_continuous)] [message_hit_area] <b>[skloname(I.name, TVORITELNI, I.gender)][extra_wound_details]</b>!"
	var/attack_message_attacker = "Моя атака [message_verb_simple] <b>[src]</b> [message_hit_area] <b>[skloname(I.name, TVORITELNI, I.gender)]</b>!"
	if(user in viewers(src, null))
		attack_message_spectator = "<b>[user]</b> [message_verb_continuous] <b>[skloname(src.name, VINITELNI, gender)]</b> [message_hit_area] [skloname(I.name, TVORITELNI, I.gender)]![extra_wound_details]!"
		attack_message_victim = "<b>[user]</b> [message_verb_continuous] меня [message_hit_area] [skloname(I.name, TVORITELNI, I.gender)]!"
	if(user == src)
		attack_message_victim = "Моя атака [message_verb_simple] меня [message_hit_area] [skloname(I.name, TVORITELNI, I.gender)]!"
	visible_message(span_danger("[attack_message_spectator]") ,\
		span_userdanger("[attack_message_victim]") , null, COMBAT_MESSAGE_RANGE, user)
	if(user != src)
		to_chat(user, span_danger("[attack_message_attacker]"))
	return TRUE


/mob/living/carbon/attack_drone(mob/living/simple_animal/drone/user)
	return //so we don't call the carbon's attack_hand().

//ATTACK HAND IGNORING PARENT RETURN VALUE
/mob/living/carbon/attack_hand(mob/living/carbon/human/user)

	if(SEND_SIGNAL(src, COMSIG_ATOM_ATTACK_HAND, user) & COMPONENT_CANCEL_ATTACK_CHAIN)
		. = TRUE
	for(var/thing in diseases)
		var/datum/disease/D = thing
		if(D.spread_flags & DISEASE_SPREAD_CONTACT_SKIN)
			user.ContactContractDisease(D)

	for(var/thing in user.diseases)
		var/datum/disease/D = thing
		if(D.spread_flags & DISEASE_SPREAD_CONTACT_SKIN)
			ContactContractDisease(D)

	for(var/datum/surgery/S in surgeries)
		if(body_position == LYING_DOWN || !S.lying_required)
			if(user.a_intent == INTENT_HELP || user.a_intent == INTENT_DISARM)
				if(S.next_step(user, user.a_intent))
					return TRUE

	for(var/i in all_wounds)
		var/datum/wound/W = i
		if(W.try_handling(user))
			return TRUE

	if (user.apply_martial_art(src))
		return TRUE

	return FALSE


/mob/living/carbon/attack_paw(mob/living/carbon/human/M)

	if(try_inject(M, injection_flags = INJECT_TRY_SHOW_ERROR_MESSAGE))
		for(var/thing in diseases)
			var/datum/disease/D = thing
			if((D.spread_flags & DISEASE_SPREAD_CONTACT_SKIN) && prob(85))
				M.ContactContractDisease(D)

	for(var/thing in M.diseases)
		var/datum/disease/D = thing
		if(D.spread_flags & DISEASE_SPREAD_CONTACT_SKIN)
			ContactContractDisease(D)

	if(M.a_intent == INTENT_HELP)
		help_shake_act(M)
		return FALSE

	if(..()) //successful monkey bite.
		for(var/thing in M.diseases)
			var/datum/disease/D = thing
			ForceContractDisease(D)
		return TRUE


/mob/living/carbon/attack_slime(mob/living/simple_animal/slime/M)
	if(..()) //successful slime attack
		if(M.powerlevel > 0)
			var/stunprob = M.powerlevel * 7 + 10  // 17 at level 1, 80 at level 10
			if(prob(stunprob))
				M.powerlevel -= 3
				if(M.powerlevel < 0)
					M.powerlevel = 0

				visible_message(span_danger("<b>[M.name]</b> ударил током <b>[src]</b>!") , \
				span_userdanger("<b>[M.name]</b> ударил меня током!"))

				do_sparks(5, TRUE, src)
				var/power = M.powerlevel + rand(0,3)
				Paralyze(power*20)
				if(stuttering < power)
					stuttering = power
				if (prob(stunprob) && M.powerlevel >= 8)
					adjustFireLoss(M.powerlevel * rand(6,10))
					updatehealth()
		return 1

/mob/living/carbon/proc/dismembering_strike(mob/living/attacker, dam_zone, rl = FALSE)
	if(!attacker.limb_destroyer && !rl)
		return dam_zone
	var/obj/item/bodypart/affecting
	if(dam_zone && attacker.client)
		affecting = get_bodypart(ran_zone(dam_zone))
	else
		var/list/things_to_ruin = shuffle(bodyparts.Copy())
		for(var/B in things_to_ruin)
			var/obj/item/bodypart/bodypart = B
			if(bodypart.body_zone == BODY_ZONE_HEAD || bodypart.body_zone == BODY_ZONE_CHEST)
				continue
			if(!affecting || ((affecting.get_damage() / affecting.max_damage) < (bodypart.get_damage() / bodypart.max_damage)))
				affecting = bodypart
	if(affecting)
		dam_zone = affecting.body_zone
		if(affecting.get_damage() >= affecting.max_damage)
			affecting.dismember()
			return null
		return affecting.body_zone
	return dam_zone

/**
 * Attempt to disarm the target mob.
 * Will shove the target mob back, and drop them if they're in front of something dense
 * or another carbon.
*/
/mob/living/carbon/proc/disarm(mob/living/carbon/target)
	if(zone_selected == BODY_ZONE_PRECISE_MOUTH)
		var/target_on_help_and_unarmed = target.a_intent == INTENT_HELP && !target.get_active_held_item()
		if(target_on_help_and_unarmed || HAS_TRAIT(target, TRAIT_RESTRAINED))
			do_slap_animation(target)
			playsound(target.loc, 'sound/weapons/slap.ogg', 50, TRUE, -1)
			visible_message(span_danger("[capitalize(src.name)] slaps [target] in the face!") ,
				span_notice("You slap [target] in the face! ") ,\
			"You hear a slap.")
			target.dna?.species?.stop_wagging_tail(target)
			return
	do_attack_animation(target, ATTACK_EFFECT_DISARM)
	playsound(target, 'sound/weapons/thudswoosh.ogg', 50, TRUE, -1)
	if (ishuman(target))
		var/mob/living/carbon/human/human_target = target
		human_target.w_uniform?.add_fingerprint(src)

	SEND_SIGNAL(target, COMSIG_HUMAN_DISARM_HIT, src, zone_selected)

	var/turf/target_oldturf = target.loc
	var/shove_dir = get_dir(loc, target_oldturf)
	var/turf/target_shove_turf = get_step(target.loc, shove_dir)
	var/mob/living/carbon/target_collateral_carbon
	var/obj/structure/table/target_table
	var/obj/machinery/disposal/bin/target_disposal_bin
	var/turf/open/indestructible/pool/target_pool	//This list is getting pretty long, but its better than calling shove_act or something on every atom
	var/shove_blocked = FALSE //Used to check if a shove is blocked so that if it is knockdown logic can be applied

	//Thank you based whoneedsspace
	target_collateral_carbon = locate(/mob/living/carbon) in target_shove_turf.contents

	// If we can't shove the target into the carbon (such as if it's an alien), then just pretend nothing was there
	if (!target_collateral_carbon?.can_be_shoved_into)
		target_collateral_carbon = null

	if(target_collateral_carbon)
		shove_blocked = TRUE
	else
		target.Move(target_shove_turf, shove_dir)
		if(get_turf(target) == target_oldturf)
			target_table = locate(/obj/structure/table) in target_shove_turf.contents
			target_disposal_bin = locate(/obj/machinery/disposal/bin) in target_shove_turf.contents
			target_pool = istype(target_shove_turf, /turf/open/indestructible/pool) ? target_shove_turf : null
			shove_blocked = TRUE

	if(target.IsKnockdown() && !target.IsParalyzed())
		target.Paralyze(SHOVE_CHAIN_PARALYZE)
		target.visible_message(span_danger("<b>[name]</b> кладет <b>[skloname(target.name, VINITELNI, target.gender)]</b> на лопатки!") ,
						span_userdanger("<b>[name]</b> кладет меня на лопатки!") , span_hear("Слышу агрессивную потасовку сопровождающуюся громким стуком!") , COMBAT_MESSAGE_RANGE, src)
		to_chat(src, span_danger("Укладываю <b>[skloname(target.name, VINITELNI, target.gender)]</b> на лопатки!"))
		addtimer(CALLBACK(target, TYPE_PROC_REF(/mob/living, SetKnockdown), 0), SHOVE_CHAIN_PARALYZE)
		log_combat(src, target, "kicks", "onto their side (paralyzing)")

	if(shove_blocked && !target.is_shove_knockdown_blocked() && !target.buckled)
		var/directional_blocked = FALSE
		if(shove_dir in GLOB.cardinals) //Directional checks to make sure that we're not shoving through a windoor or something like that
			var/target_turf = get_turf(target)
			for(var/obj/obj_content in target_turf)
				if(obj_content.flags_1 & ON_BORDER_1 && obj_content.dir == shove_dir && obj_content.density)
					directional_blocked = TRUE
					break
			if(target_turf != target_shove_turf) //Make sure that we don't run the exact same check twice on the same tile
				for(var/obj/obj_content in target_shove_turf)
					if(obj_content.flags_1 & ON_BORDER_1 && obj_content.dir == turn(shove_dir, 180) && obj_content.density)
						directional_blocked = TRUE
						break
		if((!target_table && !target_collateral_carbon && !target_disposal_bin && !target_pool) || directional_blocked)
			target.Knockdown(SHOVE_KNOCKDOWN_SOLID)
			target.visible_message(span_danger("<b>[name]</b> толкает <b>[skloname(target.name, VINITELNI, target.gender)]</b>, повалив на пол!") ,
							span_danger("Меня толкает <b>[name]</b>, повалив на пол!") , span_hear("Слышу агрессивную потасовку сопровождающуюся громким стуком!") , COMBAT_MESSAGE_RANGE, src)
			to_chat(src, span_danger("Толкаю <b>[skloname(target.name, VINITELNI, target.gender)]</b>, повалив на пол!"))
			log_combat(src, target, "shoved", "knocking them down")
		else if(target_table)
			target.Knockdown(SHOVE_KNOCKDOWN_TABLE)
			target.visible_message(span_danger("<b>[name]</b> заталкивает <b>[skloname(target.name, VINITELNI, target.gender)]</b> на [target_table]!") ,
							span_userdanger("Меня заталкивает <b>[name]</b> на [target_table]!") , span_hear("Слышу агрессивную потасовку сопровождающуюся громким стуком!") , COMBAT_MESSAGE_RANGE, src)
			to_chat(src, span_danger("Заталкиваю <b>[skloname(target.name, VINITELNI, target.gender)]</b> на [target_table]!"))
			target.throw_at(target_table, 1, 1, null, FALSE) //1 speed throws with no spin are basically just forcemoves with a hard collision check
			log_combat(src, target, "shoved", "onto [target_table] (table)")
		else if(target_collateral_carbon)
			target.Knockdown(SHOVE_KNOCKDOWN_HUMAN)
			target_collateral_carbon.Knockdown(SHOVE_KNOCKDOWN_COLLATERAL)
			target.visible_message(span_danger("<b>[name]</b> толкает <b>[skloname(target.name, VINITELNI, target.gender)]</b> в [target_collateral_carbon.name]!") ,
				span_userdanger("Меня толкает <b>[name]</b> в [target_collateral_carbon.name]!") , span_hear("Слышу агрессивную потасовку сопровождающуюся громким стуком!") , COMBAT_MESSAGE_RANGE, src)
			to_chat(src, span_danger("Толкаю <b>[skloname(target.name, VINITELNI, target.gender)]</b> в [target_collateral_carbon.name]!"))
			log_combat(src, target, "shoved", "into [target_collateral_carbon.name]")
		else if(target_disposal_bin)
			target.Knockdown(SHOVE_KNOCKDOWN_SOLID)
			target.forceMove(target_disposal_bin)
			target.visible_message(span_danger("<b>[name]</b> толкает <b>[skloname(target.name, VINITELNI, target.gender)]</b> в [target_disposal_bin]!") ,
				span_userdanger("Меня толкает <b>[name]</b> в [target_disposal_bin]!</span>!") , span_hear("Слышу агрессивную потасовку сопровождающуюся громким стуком!") , COMBAT_MESSAGE_RANGE, src)
			to_chat(src, span_danger("Толкаю <b>[skloname(target.name, VINITELNI, target.gender)]</b> прямо в [target_disposal_bin]!"))
			log_combat(src, target, "shoved", "into [target_disposal_bin] (disposal bin)")
		else if(target_pool)
			target.Knockdown(SHOVE_KNOCKDOWN_SOLID)
			target.forceMove(target_pool)
			target.visible_message(span_danger("<b>[name]</b> толкает <b>[skloname(target.name, VINITELNI, target.gender)]</b> в [target_pool]!") ,
				span_userdanger("Меня толкает <b>[name]</b> в [target_pool]!</span>!") , span_hear("Слышу агрессивную потасовку сопровождающуюся громким стуком!") , COMBAT_MESSAGE_RANGE, src)
			log_combat(src, target, "shoved", "into [target_pool] (swimming pool)")
	else
		target.visible_message(span_danger("<b>[name]</b> толкает <b>[skloname(target.name, VINITELNI, target.gender)]</b>!") ,
						span_userdanger("Меня толкает <b>[name]</b>!") , span_hear("Слышу агрессивную потасовку!") , COMBAT_MESSAGE_RANGE, src)
		to_chat(src, span_danger("Толкаю <b>[skloname(target.name, VINITELNI, target.gender)]</b>!"))
		var/target_held_item = target.get_active_held_item()
		var/knocked_item = FALSE
		if(!is_type_in_typecache(target_held_item, GLOB.shove_disarming_types))
			target_held_item = null
		if(!target.has_movespeed_modifier(/datum/movespeed_modifier/shove))
			target.add_movespeed_modifier(/datum/movespeed_modifier/shove)
			if(target_held_item)
				target.visible_message(span_danger("Захват <b>[skloname(target.name, VINITELNI, target.gender)]</b> на [target_held_item] слабеет!") ,
					span_warning("Мой захват [target_held_item] слабеет!") , null, COMBAT_MESSAGE_RANGE)
			addtimer(CALLBACK(target, TYPE_PROC_REF(/mob/living/carbon/human, clear_shove_slowdown)), SHOVE_SLOWDOWN_LENGTH)
		else if(target_held_item)
			target.dropItemToGround(target_held_item)
			knocked_item = TRUE
			target.visible_message(span_danger("<b>[target.name]</b> роняет [target_held_item]!") ,
				span_warning("Роняю [target_held_item]!") , null, COMBAT_MESSAGE_RANGE)
		var/append_message = ""
		if(target_held_item)
			if(knocked_item)
				append_message = "выбив из рук [target_held_item]"
			else
				append_message = "ослабив захват [target_held_item]"
		log_combat(src, target, "shoved", append_message)

/mob/living/carbon/proc/is_shove_knockdown_blocked() //If you want to add more things that block shove knockdown, extend this
	for (var/obj/item/clothing/clothing in get_equipped_items())
		if(clothing.clothing_flags & BLOCKS_SHOVE_KNOCKDOWN)
			return TRUE
	return FALSE

/mob/living/carbon/proc/clear_shove_slowdown()
	remove_movespeed_modifier(/datum/movespeed_modifier/shove)
	var/active_item = get_active_held_item()
	if(is_type_in_typecache(active_item, GLOB.shove_disarming_types))
		visible_message(span_warning("[name] regains their grip on [active_item]!") , span_warning("You regain your grip on [active_item]") , null, COMBAT_MESSAGE_RANGE)

/mob/living/carbon/blob_act(obj/structure/blob/B)
	if (stat == DEAD)
		return
	else
		show_message(span_userdanger("The blob attacks!"))
		adjustBruteLoss(10)

/mob/living/carbon/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_CONTENTS)
		return
	for(var/X in internal_organs)
		var/obj/item/organ/O = X
		O.emp_act(severity)

///Adds to the parent by also adding functionality to propagate shocks through pulling and doing some fluff effects.
/mob/living/carbon/electrocute_act(shock_damage, source, siemens_coeff = 1, flags = NONE)
	. = ..()
	if(!.)
		return
	//Propagation through pulling, fireman carry
	if(!(flags & SHOCK_ILLUSION))
		var/list/shocking_queue = list()
		if(iscarbon(pulling) && source != pulling)
			shocking_queue += pulling
		if(iscarbon(pulledby) && source != pulledby)
			shocking_queue += pulledby
		if(iscarbon(buckled) && source != buckled)
			shocking_queue += buckled
		for(var/mob/living/carbon/carried in buckled_mobs)
			if(source != carried)
				shocking_queue += carried
		//Found our victims, now lets shock them all
		for(var/victim in shocking_queue)
			var/mob/living/carbon/C = victim
			C.electrocute_act(shock_damage*0.75, src, 1, flags)
	//Stun
	var/should_stun = (!(flags & SHOCK_TESLA) || siemens_coeff > 0.5) && !(flags & SHOCK_NOSTUN)
	if(should_stun)
		Paralyze(40)
	//Jitter and other fluff.
	jitteriness += 1000
	do_jitter_animation(jitteriness)
	stuttering += 2
	addtimer(CALLBACK(src, PROC_REF(secondary_shock), should_stun), 20)
	return shock_damage

///Called slightly after electrocute act to reduce jittering and apply a secondary stun.
/mob/living/carbon/proc/secondary_shock(should_stun)
	jitteriness = max(jitteriness - 990, 10)
	if(should_stun)
		Paralyze(60)

/mob/living/carbon/proc/help_shake_act(mob/living/carbon/M)
	if(on_fire)
		to_chat(M, span_warning("Не могу дотронуться до н[ru_ego()] голыми руками!"))
		return

	if(M == src && check_self_for_injuries())
		return

	if(body_position == LYING_DOWN)
		if(buckled)
			to_chat(M, span_warning("Тебе нужно отстегнуться от [src.name], чтобы сделать это!"))
			return
		M.visible_message(span_notice("[M] встряхивает [src] пытаясь поднять [ru_ego()]!") , \
						null, span_hear("Слышу шуршание одежды.") , DEFAULT_MESSAGE_RANGE, list(M, src))
		to_chat(M, span_notice("Встряхиваю [src] пытаясь поднять [ru_ego()]!"))
		to_chat(src, span_notice("[M] пытается поднять меня!"))
	else if(check_zone(M.zone_selected) == BODY_ZONE_HEAD) //Headpats!
		SEND_SIGNAL(src, COMSIG_CARBON_HEADPAT, M)
		M.visible_message(span_notice("[M] гладит по головке [skloname(name, VINITELNI, gender)]!") , \
					null, span_hear("Слышу мягкое похлопывание.") , DEFAULT_MESSAGE_RANGE, list(M, src))
		to_chat(M, span_notice("Глажу [skloname(name, VINITELNI, gender)] по головке!"))
		to_chat(src, span_notice("[M] гладит меня по головке! "))

		if(HAS_TRAIT(src, TRAIT_BADTOUCH))
			to_chat(M, span_warning("[src] выглядит расстроенно, как только вы гладите [ru_ego()] по голове."))

	else if((check_zone(M.zone_selected) == BODY_ZONE_L_ARM) || ((check_zone(M.zone_selected) == BODY_ZONE_R_ARM)))
		M.visible_message(span_notice("[M] крепко пожимает руку [skloname(name, VINITELNI, gender)]!"), \
					null, span_hear("Слышу, как пожимают руки."), DEFAULT_MESSAGE_RANGE, list(M, src))
		to_chat(M, span_notice("Пожимаю руку [skloname(name, VINITELNI, gender)]!"))
		to_chat(src, span_notice("[M] пожимает мне руку!"))

	else
		SEND_SIGNAL(src, COMSIG_CARBON_HUGGED, M)
		SEND_SIGNAL(M, COMSIG_CARBON_HUG, M, src)
		M.visible_message(span_notice("[M] обнимает [skloname(name, VINITELNI, gender)]!") , \
					null, span_hear("Слышу шуршание одежды.") , DEFAULT_MESSAGE_RANGE, list(M, src))
		to_chat(M, span_notice("Обнимаю [skloname(name, VINITELNI, gender)]!"))
		to_chat(src, span_notice("[M] обнимает меня!"))

		// Warm them up with hugs
		share_bodytemperature(M)

		// No moodlets for people who hate touches
		if(!HAS_TRAIT(src, TRAIT_BADTOUCH))
			if(bodytemperature > M.bodytemperature)
				if(!HAS_TRAIT(M, TRAIT_BADTOUCH))
					SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "hug", /datum/mood_event/warmhug, src) // Hugger got a warm hug (Unless they hate hugs)
				SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, "hug", /datum/mood_event/hug) // Reciver always gets a mood for being hugged
			else
				SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, "hug", /datum/mood_event/warmhug, M) // You got a warm hug

		// Let people know if they hugged someone really warm or really cold
		if(M.bodytemperature > BODYTEMP_HEAT_DAMAGE_LIMIT)
			to_chat(src, span_warning("Чувствую тепло при объятиях с <b>[M]</b>."))
		else if(M.bodytemperature < BODYTEMP_COLD_DAMAGE_LIMIT)
			to_chat(src, span_warning("Чувствую холод при объятиях с <b>[M]</b>."))

		if(bodytemperature > BODYTEMP_HEAT_DAMAGE_LIMIT)
			to_chat(M, span_warning("Чувствую тепло при объятиях с <b>[M]</b>."))
		else if(bodytemperature < BODYTEMP_COLD_DAMAGE_LIMIT)
			to_chat(M, span_warning("Чувствую холод при объятиях с <b>[M]</b>."))

		if(HAS_TRAIT(M, TRAIT_HACKER))
			RemoveElement(/datum/element/glitch)

		if(HAS_TRAIT(M, TRAIT_FRIENDLY))
			var/datum/component/mood/hugger_mood = M.GetComponent(/datum/component/mood)
			if (hugger_mood.sanity >= SANITY_GREAT)
				new /obj/effect/temp_visual/heart(loc)
				SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, "friendly_hug", /datum/mood_event/besthug, M)
			else if (hugger_mood.sanity >= SANITY_DISTURBED)
				SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, "friendly_hug", /datum/mood_event/betterhug, M)

		if(HAS_TRAIT(src, TRAIT_BADTOUCH))
			to_chat(M, span_warning("[src] выглядит расстроенно, как только вы обнимаете [ru_ego()]."))

	AdjustStun(-60)
	AdjustKnockdown(-60)
	AdjustUnconscious(-60)
	AdjustSleeping(-100)
	AdjustParalyzed(-60)
	AdjustImmobilized(-60)
	set_resting(FALSE)
	if(body_position != STANDING_UP && !resting && !buckled && !HAS_TRAIT(src, TRAIT_FLOORED))
		get_up(TRUE)

	playsound(loc, 'sound/weapons/thudswoosh.ogg', 50, TRUE, -1)

	// Shake animation
	if (incapacitated())
		var/direction = prob(50) ? -1 : 1
		animate(src, pixel_x = pixel_x + SHAKE_ANIMATION_OFFSET * direction, time = 1, easing = QUAD_EASING | EASE_OUT, flags = ANIMATION_PARALLEL)
		animate(pixel_x = pixel_x - (SHAKE_ANIMATION_OFFSET * 2 * direction), time = 1)
		animate(pixel_x = pixel_x + SHAKE_ANIMATION_OFFSET * direction, time = 1, easing = QUAD_EASING | EASE_IN)

/// Check ourselves to see if we've got any shrapnel, return true if we do. This is a much simpler version of what humans do, we only indicate we're checking ourselves if there's actually shrapnel
/mob/living/carbon/proc/check_self_for_injuries()
	if(stat >= UNCONSCIOUS)
		return

	var/embeds = FALSE
	for(var/X in bodyparts)
		var/obj/item/bodypart/LB = X
		for(var/obj/item/I in LB.embedded_objects)
			if(!embeds)
				embeds = TRUE
				// this way, we only visibly try to examine ourselves if we have something embedded, otherwise we'll still hug ourselves :)
				visible_message(span_notice("[capitalize(src.name)] осматривает себя.") , \
					span_notice("Осматриваю себя в поисках осколков."))
			if(I.isEmbedHarmless())
				to_chat(src, "\t <a href='?src=[REF(src)];embedded_object=[REF(I)];embedded_limb=[REF(LB)]' class='warning'>Здесь [I] застрявший в [ru_gde_zone(LB.name)]!</a>")
			else
				to_chat(src, "\t <a href='?src=[REF(src)];embedded_object=[REF(I)];embedded_limb=[REF(LB)]' class='warning'>Здесь [I] впившийся в [ru_gde_zone(LB.name)]!</a>")

	return embeds


/mob/living/carbon/flash_act(intensity = 1, override_blindness_check = 0, affect_silicon = 0, visual = 0, type = /atom/movable/screen/fullscreen/flash, length = 25)
	var/obj/item/organ/eyes/eyes = getorganslot(ORGAN_SLOT_EYES)
	if(!eyes) //can't flash what can't see!
		return

	. = ..()

	var/damage = intensity - get_eye_protection()
	if(.) // we've been flashed
		if(visual)
			return

		if (damage == 1)
			to_chat(src, span_warning("Мои глаза покалывает слегка."))
			if(prob(40))
				eyes.applyOrganDamage(1)

		else if (damage == 2)
			to_chat(src, span_warning("Мои глаза горят."))
			eyes.applyOrganDamage(rand(2, 4))

		else if( damage >= 3)
			to_chat(src, span_warning("Мои глаза сильно горят и слезятся!"))
			eyes.applyOrganDamage(rand(12, 16))

		if(eyes.damage > 10)
			blind_eyes(damage)
			blur_eyes(damage * rand(3, 6))

			if(eyes.damage > 20)
				if(prob(eyes.damage - 20))
					if(!HAS_TRAIT(src, TRAIT_NEARSIGHT))
						to_chat(src, span_warning("Мои глаза начали неприятно гореть!"))
					become_nearsighted(EYE_DAMAGE)

				else if(prob(eyes.damage - 25))
					if(!is_blind())
						to_chat(src, span_warning("Перестаю видеть!"))
					eyes.applyOrganDamage(eyes.maxHealth)

			else
				to_chat(src, span_warning("ГЛАЗА БОЛЯТ! Это не очень полезно для меня!"))
		if(has_bane(BANE_LIGHT))
			mind.disrupt_spells(-500)
		return 1
	else if(damage == 0) // just enough protection
		if(prob(20))
			to_chat(src, span_notice("Замечаю как что-то вспыхнуло краем глаза!"))
		if(has_bane(BANE_LIGHT))
			mind.disrupt_spells(0)


/mob/living/carbon/soundbang_act(intensity = 1, stun_pwr = 20, damage_pwr = 5, deafen_pwr = 15)
	var/list/reflist = list(intensity) // Need to wrap this in a list so we can pass a reference
	SEND_SIGNAL(src, COMSIG_CARBON_SOUNDBANG, reflist)
	intensity = reflist[1]
	var/ear_safety = get_ear_protection()
	var/obj/item/organ/ears/ears = getorganslot(ORGAN_SLOT_EARS)
	var/effect_amount = intensity - ear_safety
	if(effect_amount > 0)
		if(stun_pwr)
			Paralyze((stun_pwr*effect_amount)*0.1)
			Knockdown(stun_pwr*effect_amount)

		if(ears && (deafen_pwr || damage_pwr))
			var/ear_damage = damage_pwr * effect_amount
			var/deaf = deafen_pwr * effect_amount
			ears.adjustEarDamage(ear_damage,deaf)

			if(ears.damage >= 15)
				to_chat(src, span_warning("В моих ушах начало звенеть сильно!"))
				if(prob(ears.damage - 5))
					to_chat(src, span_userdanger("Ничего не слышу!"))
					ears.damage = min(ears.damage, ears.maxHealth) // does this actually do anything useful? all this would do is set an upper bound on damage, is this supposed to be a max?
					// you need earmuffs, inacusiate, or replacement
			else if(ears.damage >= 5)
				to_chat(src, span_warning("В моих ушах начало звенеть!"))
			SEND_SOUND(src, sound('sound/weapons/flash_ring.ogg',0,1,0,250))
		return effect_amount //how soundbanged we are


/mob/living/carbon/damage_clothes(damage_amount, damage_type = BRUTE, damage_flag = 0, def_zone)
	if(damage_type != BRUTE && damage_type != BURN)
		return
	damage_amount *= 0.5 //0.5 multiplier for balance reason, we don't want clothes to be too easily destroyed
	if(!def_zone || def_zone == BODY_ZONE_HEAD)
		var/obj/item/clothing/hit_clothes
		if(wear_mask)
			hit_clothes = wear_mask
		if(wear_neck)
			hit_clothes = wear_neck
		if(head)
			hit_clothes = head
		if(hit_clothes)
			hit_clothes.take_damage(damage_amount, damage_type, damage_flag, 0)

/mob/living/carbon/can_hear()
	. = FALSE
	var/obj/item/organ/ears/ears = getorganslot(ORGAN_SLOT_EARS)
	if(ears && !HAS_TRAIT(src, TRAIT_DEAF))
		. = TRUE


/mob/living/carbon/adjustOxyLoss(amount, updating_health = TRUE, forced = FALSE)
	. = ..()
	if(isnull(.))
		return
	if(. <= 50)
		if(getOxyLoss() > 50)
			ADD_TRAIT(src, TRAIT_KNOCKEDOUT, OXYLOSS_TRAIT)
	else if(getOxyLoss() <= 50)
		REMOVE_TRAIT(src, TRAIT_KNOCKEDOUT, OXYLOSS_TRAIT)

/mob/living/carbon/proc/get_interaction_efficiency(zone)
	var/obj/item/bodypart/limb = get_bodypart(zone)
	if(!limb)
		return

/mob/living/carbon/setOxyLoss(amount, updating_health = TRUE, forced = FALSE)
	. = ..()
	if(isnull(.))
		return
	if(. <= 50)
		if(getOxyLoss() > 50)
			ADD_TRAIT(src, TRAIT_KNOCKEDOUT, OXYLOSS_TRAIT)
	else if(getOxyLoss() <= 50)
		REMOVE_TRAIT(src, TRAIT_KNOCKEDOUT, OXYLOSS_TRAIT)

/mob/living/carbon/get_organic_health()
	. = health
	for (var/_limb in bodyparts)
		var/obj/item/bodypart/limb = _limb
		if (limb.status != BODYPART_ORGANIC)
			. += (limb.brute_dam * limb.body_damage_coeff) + (limb.burn_dam * limb.body_damage_coeff)

/mob/living/carbon/grabbedby(mob/living/carbon/user, supress_message = FALSE)
	if(user != src)
		return ..()

	var/obj/item/bodypart/grasped_part = get_bodypart(zone_selected)
	if(!grasped_part?.get_bleed_rate())
		return
	var/starting_hand_index = active_hand_index
	if(starting_hand_index == grasped_part.held_index)
		to_chat(src, span_danger("You can't grasp your [grasped_part.name] with itself!"))
		return

	to_chat(src, span_warning("You try grasping at your [grasped_part.name], trying to stop the bleeding..."))
	if(!do_after(src, 1.5 SECONDS))
		to_chat(src, span_danger("You fail to grasp your [grasped_part.name]."))
		return

	var/obj/item/self_grasp/grasp = new
	if(starting_hand_index != active_hand_index || !put_in_active_hand(grasp))
		to_chat(src, span_danger("You fail to grasp your [grasped_part.name]."))
		QDEL_NULL(grasp)
		return
	grasp.grasp_limb(grasped_part)

/// an abstract item representing you holding your own limb to staunch the bleeding, see [/mob/living/carbon/proc/grabbedby] will probably need to find somewhere else to put this.
/obj/item/self_grasp
	name = "self-grasp"
	desc = "Sometimes all you can do is slow the bleeding."
	icon_state = "latexballon"
	inhand_icon_state = "nothing"
	force = 0
	throwforce = 0
	slowdown = 1
	item_flags = DROPDEL | ABSTRACT | NOBLUDGEON | SLOWS_WHILE_IN_HAND | HAND_ITEM
	/// The bodypart we're staunching bleeding on, which also has a reference to us in [/obj/item/bodypart/var/grasped_by]
	var/obj/item/bodypart/grasped_part
	/// The carbon who owns all of this mess
	var/mob/living/carbon/user

/obj/item/self_grasp/Destroy()
	if(user)
		to_chat(user, span_warning("You stop holding onto your[grasped_part ? " [grasped_part.name]" : "self"]."))
		UnregisterSignal(user, COMSIG_PARENT_QDELETING)
	if(grasped_part)
		UnregisterSignal(grasped_part, list(COMSIG_CARBON_REMOVE_LIMB, COMSIG_PARENT_QDELETING))
		grasped_part.grasped_by = null
	grasped_part = null
	user = null
	return ..()

/// The limb or the whole damn person we were grasping got deleted or dismembered, so we don't care anymore
/obj/item/self_grasp/proc/qdel_void()
	qdel(src)

/// We've already cleared that the bodypart in question is bleeding in [the place we create this][/mob/living/carbon/proc/grabbedby], so set up the connections
/obj/item/self_grasp/proc/grasp_limb(obj/item/bodypart/grasping_part)
	user = grasping_part.owner
	if(!istype(user))
		stack_trace("[src] attempted to try_grasp() with [istype(user, /datum) ? user.type : isnull(user) ? "null" : user] user")
		qdel(src)
		return

	grasped_part = grasping_part
	grasped_part.grasped_by = src
	RegisterSignal(user, COMSIG_PARENT_QDELETING, PROC_REF(qdel_void))
	RegisterSignal(grasped_part, list(COMSIG_CARBON_REMOVE_LIMB, COMSIG_PARENT_QDELETING), PROC_REF(qdel_void))

	user.visible_message(span_danger("[user] grasps at [user.ru_ego()] [grasped_part.name], trying to stop the bleeding.") , span_notice("You grab hold of your [grasped_part.name] tightly.") , vision_distance=COMBAT_MESSAGE_RANGE)
	playsound(get_turf(src), 'sound/weapons/thudswoosh.ogg', 50, TRUE, -1)
	return TRUE

#undef SHAKE_ANIMATION_OFFSET
