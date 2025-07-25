// CHAPLAIN CUSTOM ARMORS //

/obj/item/clothing/head/helmet/chaplain/clock
	name = "forgotten helmet"
	desc = "It has the unyielding gaze of a god eternally forgotten."
	icon_state = "clockwork_helmet"
	inhand_icon_state = "clockwork_helmet_inhand"
	armor = list(MELEE = 50, BULLET = 10, LASER = 10, ENERGY = 10, BOMB = 0, BIO = 0, RAD = 0, FIRE = 80, ACID = 80)
	flags_inv = HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE|HIDEHAIR|HIDESNOUT
	flags_cover = HEADCOVERSEYES | HEADCOVERSMOUTH
	strip_delay = 8 SECONDS
	dog_fashion = null

/obj/item/clothing/suit/armor/riot/chaplain/clock
	name = "forgotten armour"
	desc = "It sounds like hissing steam, ticking cogs, gone silent, It looks like a dead machine, trying to tick with life."
	icon_state = "clockwork_cuirass"
	inhand_icon_state = "clockwork_cuirass_inhand"
	allowed = list(/obj/item/storage/book/bible, /obj/item/nullrod, /obj/item/reagent_containers/food/drinks/bottle/holywater, /obj/item/storage/fancy/candle_box, /obj/item/candle, /obj/item/tank/internals/emergency_oxygen, /obj/item/tank/internals/plasmaman)
	slowdown = 0
	clothing_flags = NONE

/obj/item/clothing/head/helmet/chaplain
	name = "crusader helmet"
	desc = "Deus Vult."
	icon_state = "knight_templar"
	inhand_icon_state = "knight_templar"
	armor = list(MELEE = 50, BULLET = 10, LASER = 10, ENERGY = 10, BOMB = 0, BIO = 0, RAD = 0, FIRE = 80, ACID = 80)
	flags_inv = HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE|HIDEHAIR|HIDESNOUT
	flags_cover = HEADCOVERSEYES | HEADCOVERSMOUTH
	strip_delay = 80
	dog_fashion = null

/obj/item/clothing/suit/armor/riot/chaplain
	name = "crusader armour"
	desc = "God wills it!"
	icon_state = "knight_templar"
	inhand_icon_state = "knight_templar"
	allowed = list(/obj/item/storage/book/bible, /obj/item/nullrod, /obj/item/reagent_containers/food/drinks/bottle/holywater, /obj/item/storage/fancy/candle_box, /obj/item/candle, /obj/item/tank/internals/emergency_oxygen, /obj/item/tank/internals/plasmaman)
	slowdown = 0
	clothing_flags = NONE

/obj/item/choice_beacon/holy
	name = "armaments beacon"
	desc = "Contains a set of armaments for the chaplain."

/obj/item/choice_beacon/holy/canUseBeacon(mob/living/user)
	if(user.mind && user.mind.holy_role)
		return ..()
	else
		playsound(src, 'white/valtos/sounds/error1.ogg', 40, TRUE)
		return FALSE

/obj/item/choice_beacon/holy/generate_display_names()
	var/static/list/holy_item_list
	if(!holy_item_list)
		holy_item_list = list()
		var/list/templist = typesof(/obj/item/storage/box/holy)
		for(var/V in templist)
			var/atom/A = V
			holy_item_list[initial(A.name)] = A
	return holy_item_list

/obj/item/choice_beacon/holy/spawn_option(obj/choice,mob/living/M)
	if(!GLOB.holy_armor_type)
		..()
		playsound(src, 'sound/effects/pray_chaplain.ogg', 40, TRUE)
		SSblackbox.record_feedback("tally", "chaplain_armor", 1, "[choice]")
		GLOB.holy_armor_type = choice
	else
		to_chat(M, span_warning("A selection has already been made. Self-Destructing..."))
		return


/obj/item/storage/box/holy/clock
	name = "Forgotten kit"

/obj/item/storage/box/holy/clock/PopulateContents()
	new /obj/item/clothing/head/helmet/chaplain/clock(src)
	new /obj/item/clothing/suit/armor/riot/chaplain/clock(src)

/obj/item/storage/box/holy
	name = "Templar Kit"

/obj/item/storage/box/holy/PopulateContents()
	new /obj/item/clothing/head/helmet/chaplain(src)
	new /obj/item/clothing/suit/armor/riot/chaplain(src)

/obj/item/storage/box/holy/student
	name = "Profane Scholar Kit"

/obj/item/storage/box/holy/student/PopulateContents()
	new /obj/item/clothing/suit/armor/riot/chaplain/studentuni(src)
	new /obj/item/clothing/head/helmet/chaplain/cage(src)

/obj/item/clothing/suit/armor/riot/chaplain/studentuni
	name = "student robe"
	desc = "The uniform of a bygone institute of learning."
	icon_state = "studentuni"
	inhand_icon_state = "studentuni"
	body_parts_covered = ARMS|CHEST

/obj/item/clothing/head/helmet/chaplain/cage
	name = "cage"
	desc = "A cage that restrains the will of the self, allowing one to see the profane world for what it is."
	flags_inv = NONE
	worn_icon = 'icons/mob/large-worn-icons/64x64/head.dmi'
	icon_state = "cage"
	inhand_icon_state = "cage"
	worn_x_dimension = 64
	worn_y_dimension = 64
	clothing_flags = LARGE_WORN_ICON
	dynamic_hair_suffix = ""

/obj/item/storage/box/holy/sentinel
	name = "Stone Sentinel Kit"

/obj/item/storage/box/holy/sentinel/PopulateContents()
	new /obj/item/clothing/suit/armor/riot/chaplain/ancient(src)
	new /obj/item/clothing/head/helmet/chaplain/ancient(src)

/obj/item/clothing/head/helmet/chaplain/ancient
	name = "ancient helmet"
	desc = "None may pass!"
	icon_state = "knight_ancient"
	inhand_icon_state = "knight_ancient"

/obj/item/clothing/suit/armor/riot/chaplain/ancient
	name = "ancient armour"
	desc = "Defend the treasure..."
	icon_state = "knight_ancient"
	inhand_icon_state = "knight_ancient"

/obj/item/storage/box/holy/witchhunter
	name = "Witchhunter Kit"

/obj/item/storage/box/holy/witchhunter/PopulateContents()
	new /obj/item/clothing/suit/armor/riot/chaplain/witchhunter(src)
	new /obj/item/clothing/head/helmet/chaplain/witchunter_hat(src)

/obj/item/clothing/suit/armor/riot/chaplain/witchhunter
	name = "witchunter garb"
	desc = "This worn outfit saw much use back in the day."
	icon_state = "witchhunter"
	inhand_icon_state = "witchhunter"
	body_parts_covered = CHEST|GROIN|LEGS|ARMS

/obj/item/clothing/head/helmet/chaplain/witchunter_hat
	name = "witchunter hat"
	desc = "This hat saw much use back in the day."
	icon_state = "witchhunterhat"
	inhand_icon_state = "witchhunterhat"
	flags_cover = HEADCOVERSEYES
	flags_inv = HIDEEYES|HIDEHAIR

/obj/item/storage/box/holy/adept
	name = "Divine Adept Kit"

/obj/item/storage/box/holy/adept/PopulateContents()
	new /obj/item/clothing/suit/armor/riot/chaplain/adept(src)
	new /obj/item/clothing/head/helmet/chaplain/adept(src)

/obj/item/clothing/head/helmet/chaplain/adept
	name = "adept hood"
	desc = "Its only heretical when others do it."
	icon_state = "crusader"
	inhand_icon_state = "crusader"
	flags_cover = HEADCOVERSEYES
	flags_inv = HIDEHAIR|HIDEFACE|HIDEEARS

/obj/item/clothing/suit/armor/riot/chaplain/adept
	name = "adept robes"
	desc = "The ideal outfit for burning the unfaithful."
	icon_state = "crusader"
	inhand_icon_state = "crusader"

/obj/item/storage/box/holy/follower
	name = "Followers of the Chaplain Kit"

/obj/item/storage/box/holy/follower/PopulateContents()
	new /obj/item/clothing/suit/hooded/chaplain_hoodie/leader(src)
	new /obj/item/clothing/suit/hooded/chaplain_hoodie(src)
	new /obj/item/clothing/suit/hooded/chaplain_hoodie(src)
	new /obj/item/clothing/suit/hooded/chaplain_hoodie(src)
	new /obj/item/clothing/suit/hooded/chaplain_hoodie(src)

/obj/item/storage/box/mothic_rations
	name = "Mothic Rations Pack"
	desc = "A box containing a few rations and some Activin gum, for keeping a starving moth going."
	icon_state = "moth_package"
	illustration = null

/obj/item/storage/box/mothic_rations/PopulateContents()
	for(var/i in 1 to 3)
		var/randomFood = pickweight(list(/obj/item/food/sustenance_bar = 10,
							  /obj/item/food/sustenance_bar/cheese = 5,
							  /obj/item/food/sustenance_bar/mint = 5,
							  /obj/item/food/sustenance_bar/neapolitan = 5,
							  /obj/item/food/sustenance_bar/wonka = 1))
		new randomFood(src)
	new /obj/item/storage/box/gum/wake_up(src)
/obj/item/clothing/suit/hooded/chaplain_hoodie
	name = "follower hoodie"
	desc = "Hoodie made for acolytes of the chaplain."
	icon_state = "chaplain_hoodie"
	inhand_icon_state = "chaplain_hoodie"
	body_parts_covered = CHEST|GROIN|LEGS|ARMS
	allowed = list(/obj/item/storage/book/bible, /obj/item/nullrod, /obj/item/reagent_containers/food/drinks/bottle/holywater, /obj/item/storage/fancy/candle_box, /obj/item/candle, /obj/item/tank/internals/emergency_oxygen, /obj/item/tank/internals/plasmaman)
	hoodtype = /obj/item/clothing/head/hooded/chaplain_hood

/obj/item/clothing/head/hooded/chaplain_hood
	name = "follower hood"
	desc = "Hood made for acolytes of the chaplain."
	icon_state = "chaplain_hood"
	body_parts_covered = HEAD
	flags_inv = HIDEHAIR|HIDEFACE|HIDEEARS

/obj/item/clothing/suit/hooded/chaplain_hoodie/leader
	name = "leader hoodie"
	desc = "Now you're ready for some 50 dollar bling water."
	icon_state = "chaplain_hoodie_leader"
	inhand_icon_state = "chaplain_hoodie_leader"
	hoodtype = /obj/item/clothing/head/hooded/chaplain_hood/leader

/obj/item/clothing/head/hooded/chaplain_hood/leader
	name = "leader hood"
	desc = "I mean, you don't /have/ to seek bling water. I just think you should."
	icon_state = "chaplain_hood_leader"


// CHAPLAIN NULLROD AND CUSTOM WEAPONS //

/obj/item/nullrod
	name = "null rod"
	desc = "A rod of pure obsidian; its very presence disrupts and dampens 'magical forces'. That's what the guidebook says, anyway."
	icon_state = "nullrod"
	inhand_icon_state = "nullrod"
	lefthand_file = 'icons/mob/inhands/weapons/melee_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/melee_righthand.dmi'
	force = 18
	throw_speed = 3
	throw_range = 4
	throwforce = 10
	slot_flags = ITEM_SLOT_BELT
	w_class = WEIGHT_CLASS_TINY
	obj_flags = UNIQUE_RENAME
	wound_bonus = -10
	var/reskinned = FALSE
	var/chaplain_spawnable = TRUE

/obj/item/nullrod/Initialize()
	. = ..()
	AddComponent(/datum/component/anti_magic, TRUE, TRUE, FALSE, null, null, FALSE)

/obj/item/nullrod/suicide_act(mob/user)
	user.visible_message(span_suicide("[user] is killing [user.ru_na()]self with [src]! It looks like [user.p_theyre()] trying to get closer to god!"))
	return (BRUTELOSS|FIRELOSS)

/obj/item/nullrod/attack_self(mob/user)
	if(user.mind && (user.mind.holy_role) && !reskinned)
		reskin_holy_weapon(user)

/**
 * reskin_holy_weapon: Shows a user a list of all available nullrod reskins and based on his choice replaces the nullrod with the reskinned version
 *
 * Arguments:
 * * M The mob choosing a nullrod reskin
 */
/obj/item/nullrod/proc/reskin_holy_weapon(mob/M)
	if(GLOB.holy_weapon_type)
		return
	var/list/display_names = list()
	var/list/nullrod_icons = list()
	for(var/rod in typesof(/obj/item/nullrod))
		var/obj/item/nullrod/rodtype = rod
		if(initial(rodtype.chaplain_spawnable))
			display_names[initial(rodtype.name)] = rodtype
			nullrod_icons += list(initial(rodtype.name) = image(icon = initial(rodtype.icon), icon_state = initial(rodtype.icon_state)))

	nullrod_icons = sort_list(nullrod_icons)
	var/choice = show_radial_menu(M, src , nullrod_icons, custom_check = CALLBACK(src, PROC_REF(check_menu), M), radius = 42, require_near = TRUE)
	if(!choice || !check_menu(M))
		return

	var/picked_rod_type = display_names[choice] // This needs to be on a separate var as list member access is not allowed for new
	var/obj/item/nullrod/holy_weapon = new picked_rod_type(M.drop_location())
	GLOB.holy_weapon_type = holy_weapon.type

	SSblackbox.record_feedback("tally", "chaplain_weapon", 1, "[choice]")

	if(holy_weapon)
		holy_weapon.reskinned = TRUE
		qdel(src)
		M.put_in_hands(holy_weapon)

/**
 * check_menu: Checks if we are allowed to interact with a radial menu
 *
 * Arguments:
 * * user The mob interacting with a menu
 */
/obj/item/nullrod/proc/check_menu(mob/user)
	if(!istype(user))
		return FALSE
	if(QDELETED(src) || reskinned)
		return FALSE
	if(user.incapacitated() || !user.is_holding(src))
		return FALSE
	return TRUE

/obj/item/nullrod/godhand
	icon_state = "disintegrate"
	inhand_icon_state = "disintegrate"
	lefthand_file = 'icons/mob/inhands/misc/touchspell_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/touchspell_righthand.dmi'
	name = "god hand"
	desc = "This hand of yours glows with an awesome power!"
	slot_flags = null
	item_flags = ABSTRACT | DROPDEL
	w_class = WEIGHT_CLASS_HUGE
	hitsound = 'sound/weapons/sear.ogg'
	damtype = BURN
	attack_verb_continuous = list("бьёт", "скрещивает пальцы", "вмазывает")
	attack_verb_simple = list("бьёт", "скрещивает пальцы", "вмазывает")

/obj/item/nullrod/godhand/Initialize()
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, HAND_REPLACEMENT_TRAIT)

/obj/item/nullrod/staff
	icon_state = "godstaff-red"
	inhand_icon_state = "godstaff-red"
	lefthand_file = 'icons/mob/inhands/weapons/staves_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/staves_righthand.dmi'
	name = "красный holy staff"
	desc = "It has a mysterious, protective aura."
	w_class = WEIGHT_CLASS_HUGE
	force = 5
	slot_flags = ITEM_SLOT_BACK
	block_chance = 50
	var/shield_icon = "shield-red"

/obj/item/nullrod/staff/worn_overlays(isinhands)
	. = list()
	if(isinhands)
		. += mutable_appearance('icons/effects/effects.dmi', shield_icon, MOB_SHIELD_LAYER)

/obj/item/nullrod/staff/blue
	name = "синий holy staff"
	icon_state = "godstaff-blue"
	inhand_icon_state = "godstaff-blue"
	shield_icon = "shield-old"

/obj/item/nullrod/claymore
	icon_state = "claymore_gold"
	inhand_icon_state = "claymore_gold"
	worn_icon_state = "claymore_gold"
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	name = "holy claymore"
	desc = "A weapon fit for a crusade!"
	w_class = WEIGHT_CLASS_BULKY
	slot_flags = ITEM_SLOT_BACK|ITEM_SLOT_BELT
	block_chance = 30
	sharpness = SHARP_EDGED
	hitsound = 'sound/weapons/bladeslice.ogg'
	attack_verb_continuous = list("атакует", "рубит", "кромсает", "разрывает", "протыкает", "колбасит", "делит", "режет")
	attack_verb_simple = list("атакует", "рубит", "кромсает", "разрывает", "протыкает", "колбасит", "делит", "режет")

/obj/item/nullrod/claymore/hit_reaction(mob/living/carbon/human/owner, atom/movable/hitby, attack_text = "атаку", final_block_chance = 0, damage = 0, attack_type = MELEE_ATTACK)
	if(attack_type == PROJECTILE_ATTACK)
		final_block_chance = 0 //Don't bring a sword to a gunfight
	return ..()

/obj/item/nullrod/claymore/darkblade
	name = "dark blade"
	desc = "Spread the glory of the dark gods!"
	icon_state = "cultblade"
	inhand_icon_state = "cultblade"
	worn_icon_state = "cultblade"
	lefthand_file = 'icons/mob/inhands/64x64_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/64x64_righthand.dmi'
	inhand_x_dimension = 64
	inhand_y_dimension = 64
	hitsound = 'sound/hallucinations/growl1.ogg'

/obj/item/nullrod/claymore/chainsaw_sword
	icon_state = "chainswordon"
	inhand_icon_state = "chainswordon"
	worn_icon_state = "chainswordon"
	name = "sacred chainsaw sword"
	desc = "Suffer not a heretic to live."
	slot_flags = ITEM_SLOT_BELT
	attack_verb_continuous = list("пилит", "рвёт", "режет", "рубит", "делит")
	attack_verb_simple = list("пилит", "рвёт", "режет", "рубит", "делит")
	hitsound = 'sound/weapons/chainsawhit.ogg'
	tool_behaviour = TOOL_SAW
	toolspeed = 1.5 //slower than a real saw

/obj/item/nullrod/claymore/glowing
	icon_state = "swordon"
	inhand_icon_state = "swordon"
	worn_icon_state = "swordon"
	name = "force weapon"
	desc = "The blade glows with the power of faith. Or possibly a battery."

/obj/item/nullrod/claymore/katana
	name = "\improper Hanzo steel"
	desc = "Capable of cutting clean through a holy claymore."
	icon_state = "katana"
	inhand_icon_state = "katana"
	worn_icon_state = "katana"

/obj/item/nullrod/claymore/multiverse
	name = "extradimensional blade"
	desc = "Once the harbinger of an interdimensional war, its sharpness fluctuates wildly."
	icon_state = "multiverse"
	inhand_icon_state = "multiverse"
	worn_icon_state = "multiverse"
	slot_flags = ITEM_SLOT_BACK|ITEM_SLOT_BELT
	force = 15

/obj/item/nullrod/claymore/multiverse/melee_attack_chain(mob/user, atom/target, params)
	var/old_force = force
	force += rand(-14, 15)
	. = ..()
	force = old_force

/obj/item/nullrod/claymore/saber
	name = "light energy sword"
	hitsound = 'sound/weapons/blade1.ogg'
	icon = 'icons/obj/transforming_energy.dmi'
	icon_state = "e_sword_on_blue"
	inhand_icon_state = "e_sword_on_blue"
	worn_icon_state = "swordblue"
	slot_flags = ITEM_SLOT_BELT
	desc = "If you strike me down, I shall become more robust than you can possibly imagine."

/obj/item/nullrod/claymore/saber/red
	name = "dark energy sword"
	desc = "Woefully ineffective when used on steep terrain."
	icon_state = "e_sword_on_red"
	inhand_icon_state = "e_sword_on_red"
	worn_icon_state = "swordred"

/obj/item/nullrod/claymore/saber/pirate
	name = "nautical energy sword"
	desc = "Convincing HR that your religion involved piracy was no mean feat."
	icon_state = "e_cutlass_on"
	inhand_icon_state = "e_cutlass_on"
	worn_icon_state = "swordred"

/obj/item/nullrod/sord
	name = "\improper UNREAL SORD"
	desc = "This thing is so unspeakably HOLY you are having a hard time even holding it."
	icon_state = "sord"
	inhand_icon_state = "sord"
	worn_icon_state = "sord"
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	force = 4.13
	throwforce = 1
	slot_flags = ITEM_SLOT_BELT
	hitsound = 'sound/weapons/bladeslice.ogg'
	attack_verb_continuous = list("НЕРЕАЛЬНО рубит", "НЕРЕАЛЬНО режет", "НЕРЕАЛЬНО кромсает", "НЕРЕАЛЬНО разрывает", "НЕРЕАЛЬНО протыкает", "НЕРЕАЛЬНО атакует", "НЕРЕАЛЬНО делит", "НЕРЕАЛЬНО колбасит")
	attack_verb_simple = list("НЕРЕАЛЬНО рубит", "НЕРЕАЛЬНО режет", "НЕРЕАЛЬНО кромсает", "НЕРЕАЛЬНО разрывает", "НЕРЕАЛЬНО протыкает", "НЕРЕАЛЬНО атакует", "НЕРЕАЛЬНО делит", "НЕРЕАЛЬНО колбасит")

/obj/item/nullrod/sord/suicide_act(mob/user) //a near-exact copy+paste of the actual sord suicide_act()
	user.visible_message(span_suicide("[user] пытается impale [user.ru_na()]self with [src]! It might be a suicide attempt if it weren't so HOLY.") , \
	span_suicide("Пытаюсь impale yourself with [src], but it's TOO HOLY..."))
	return SHAME

/obj/item/nullrod/scythe
	icon_state = "scythe1"
	inhand_icon_state = "scythe1"
	lefthand_file = 'icons/mob/inhands/weapons/polearms_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/polearms_righthand.dmi'
	name = "reaper scythe"
	desc = "Ask not for whom the bell tolls..."
	w_class = WEIGHT_CLASS_BULKY
	armour_penetration = 35
	slot_flags = ITEM_SLOT_BACK
	sharpness = SHARP_EDGED
	attack_verb_continuous = list("рубит", "режет", "косит", "скашивает")
	attack_verb_simple = list("рубит", "режет", "косит", "скашивает")

/obj/item/nullrod/scythe/Initialize()
	. = ..()
	AddComponent(/datum/component/butchering, 70, 110) //the harvest gives a high bonus chance

/obj/item/nullrod/scythe/vibro
	icon_state = "hfrequency0"
	inhand_icon_state = "hfrequency1"
	worn_icon_state = "hfrequency0"
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	name = "high frequency blade"
	desc = "Bad references are the DNA of the soul."
	attack_verb_continuous = list("рубит", "режет", "кромсает", "зандатсуирует")
	attack_verb_simple = list("рубит", "режет", "кромсает", "зандатсуирует")
	hitsound = 'sound/weapons/rapierhit.ogg'

/obj/item/nullrod/scythe/spellblade
	icon_state = "spellblade"
	inhand_icon_state = "spellblade"
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	worn_icon_state = "spellblade"
	icon = 'icons/obj/guns/magic.dmi'
	name = "dormant spellblade"
	desc = "The blade grants the wielder nearly limitless power...if they can figure out how to turn it on, that is."
	hitsound = 'sound/weapons/rapierhit.ogg'

/obj/item/nullrod/scythe/talking
	icon_state = "talking_sword"
	inhand_icon_state = "talking_sword"
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	worn_icon_state = "talking_sword"
	name = "possessed blade"
	desc = "When the station falls into chaos, it's nice to have a friend by your side."
	attack_verb_continuous = list("рубит", "нарезает", "режет")
	attack_verb_simple = list("рубит", "нарезает", "режет")
	hitsound = 'sound/weapons/rapierhit.ogg'
	var/possessed = FALSE

/obj/item/nullrod/scythe/talking/relaymove(mob/living/user, direction)
	return //stops buckled message spam for the ghost.

/obj/item/nullrod/scythe/talking/attack_self(mob/living/user)
	if(possessed)
		return
	if(!(GLOB.ghost_role_flags & GHOSTROLE_STATION_SENTIENCE))
		to_chat(user, span_notice("Anomalous otherworldly energies block you from awakening the blade!"))
		return

	to_chat(user, span_notice("You attempt to wake the spirit of the blade..."))

	possessed = TRUE

	var/list/mob/dead/observer/candidates = poll_ghost_candidates("Хочешь быть духом меча [user.real_name]?", ROLE_PAI, FALSE, 100, POLL_IGNORE_POSSESSED_BLADE)

	if(LAZYLEN(candidates))
		var/mob/dead/observer/C = pick(candidates)
		var/mob/living/simple_animal/shade/S = new(src)
		S.ckey = C.ckey
		S.fully_replace_character_name(null, "The spirit of [name]")
		S.status_flags |= GODMODE
		S.copy_languages(user, LANGUAGE_MASTER)	//Make sure the sword can understand and communicate with the user.
		S.update_atom_languages()
		grant_all_languages(FALSE, FALSE, TRUE)	//Grants omnitongue
		var/input = sanitize_name(stripped_input(S,"What are you named?", ,"", MAX_NAME_LEN))

		if(src && input)
			name = input
			S.fully_replace_character_name(null, "The spirit of [input]")
	else
		to_chat(user, span_warning("The blade is dormant. Maybe you can try again later."))
		possessed = FALSE

/obj/item/nullrod/scythe/talking/Destroy()
	for(var/mob/living/simple_animal/shade/S in contents)
		to_chat(S, span_userdanger("You were destroyed!"))
		qdel(S)
	return ..()

/obj/item/nullrod/scythe/talking/chainsword
	icon_state = "chainswordon"
	inhand_icon_state = "chainswordon"
	worn_icon_state = "chainswordon"
	name = "possessed chainsaw sword"
	desc = "Suffer not a heretic to live."
	chaplain_spawnable = FALSE
	force = 30
	slot_flags = ITEM_SLOT_BELT
	attack_verb_continuous = list("пилит", "рвёт", "режет", "рубит", "делит")
	attack_verb_simple = list("пилит", "рвёт", "режет", "рубит", "делит")
	hitsound = 'sound/weapons/chainsawhit.ogg'
	tool_behaviour = TOOL_SAW
	toolspeed = 0.5 //faster than normal saw

/obj/item/nullrod/hammmer
	name = "relic war hammer"
	desc = "This war hammer cost the chaplain forty thousand space dollars."
	icon_state = "hammeron"
	inhand_icon_state = "hammeron"
	worn_icon_state = "hammeron"
	lefthand_file = 'icons/mob/inhands/weapons/hammers_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/hammers_righthand.dmi'
	w_class = WEIGHT_CLASS_BULKY
	attack_verb_continuous = list("лупит", "бьёт", "молотит", "уничтожает")
	attack_verb_simple = list("лупит", "бьёт", "молотит", "уничтожает")

/obj/item/nullrod/chainsaw
	name = "chainsaw hand"
	desc = "Good? Bad? You're the guy with the chainsaw hand."
	icon_state = "chainsaw_on"
	inhand_icon_state = "mounted_chainsaw"
	lefthand_file = 'icons/mob/inhands/weapons/chainsaw_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/chainsaw_righthand.dmi'
	w_class = WEIGHT_CLASS_HUGE
	slot_flags = null
	item_flags = ABSTRACT
	sharpness = SHARP_EDGED
	attack_verb_continuous = list("пилит", "рвёт", "режет", "рубит", "делит")
	attack_verb_simple = list("пилит", "рвёт", "режет", "рубит", "делит")
	hitsound = 'sound/weapons/chainsawhit.ogg'
	tool_behaviour = TOOL_SAW
	toolspeed = 2 //slower than a real saw

/obj/item/nullrod/chainsaw/Initialize()
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, HAND_REPLACEMENT_TRAIT)
	AddComponent(/datum/component/butchering, 30, 100, 0, hitsound)

/obj/item/nullrod/clown
	name = "clown dagger"
	desc = "Used for absolutely hilarious sacrifices."
	icon = 'icons/obj/wizard.dmi'
	icon_state = "clownrender"
	inhand_icon_state = "render"
	worn_icon_state = "render"
	hitsound = 'sound/items/bikehorn.ogg'
	sharpness = SHARP_EDGED
	attack_verb_continuous = list("атакует", "режет", "протыкает", "нарезает", "рвёт", "разрывает", "делит", "кромсает")
	attack_verb_simple = list("атакует", "режет", "протыкает", "нарезает", "рвёт", "разрывает", "делит", "кромсает")

#define CHEMICAL_TRANSFER_CHANCE 30

/obj/item/nullrod/pride_hammer
	name = "Pride-struck Hammer"
	desc = "It resonates an aura of Pride."
	icon_state = "pride"
	inhand_icon_state = "pride"
	worn_icon_state = "pride"
	lefthand_file = 'icons/mob/inhands/weapons/hammers_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/hammers_righthand.dmi'
	force = 16
	throwforce = 15
	w_class = WEIGHT_CLASS_BULKY
	slot_flags = ITEM_SLOT_BACK
	attack_verb_continuous = list("атакует", "лупит", "покушается", "нежит", "засаживает")
	attack_verb_simple = list("атакует", "лупит", "покушается", "нежит", "засаживает")
	hitsound = 'sound/weapons/blade1.ogg'


/obj/item/nullrod/pride_hammer/Initialize()
	. = ..()
	AddElement(/datum/element/kneejerk)
	AddElement(
		/datum/element/chemical_transfer,\
		span_notice("Your pride reflects on %VICTIM."),\
		span_userdanger("You feel insecure, taking on %ATTACKER's burden."),\
		CHEMICAL_TRANSFER_CHANCE\
	)

#undef CHEMICAL_TRANSFER_CHANCE

/obj/item/nullrod/whip
	name = "holy whip"
	desc = "What a terrible night to be on Space Station 13."
	icon_state = "chain"
	inhand_icon_state = "chain"
	worn_icon_state = "whip"
	lefthand_file = 'icons/mob/inhands/weapons/melee_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/melee_righthand.dmi'
	slot_flags = ITEM_SLOT_BELT
	attack_verb_continuous = list("хлыстает", "приручает")
	attack_verb_simple = list("хлыстает", "приручает")
	hitsound = 'sound/weapons/chainhit.ogg'

/obj/item/nullrod/fedora
	name = "atheist's fedora"
	desc = "The brim of the hat is as sharp as your wit. The edge would hurt almost as much as disproving the existence of God."
	icon_state = "fedora"
	inhand_icon_state = "fedora"
	slot_flags = ITEM_SLOT_HEAD
	icon = 'icons/obj/clothing/hats.dmi'
	force = 0
	throw_speed = 4
	throw_range = 7
	throwforce = 30
	sharpness = SHARP_EDGED
	attack_verb_continuous = list("просветляет", "краснопилюлит")
	attack_verb_simple = list("просветляет", "краснопилюлит")

/obj/item/nullrod/armblade
	name = "dark blessing"
	desc = "Particularly twisted deities grant gifts of dubious value."
	icon = 'icons/obj/changeling_items.dmi'
	icon_state = "arm_blade"
	inhand_icon_state = "arm_blade"
	lefthand_file = 'icons/mob/inhands/antag/changeling_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/antag/changeling_righthand.dmi'
	slot_flags = null
	item_flags = ABSTRACT
	w_class = WEIGHT_CLASS_HUGE
	sharpness = SHARP_EDGED
	wound_bonus = -20
	bare_wound_bonus = 25

/obj/item/nullrod/armblade/Initialize()
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, HAND_REPLACEMENT_TRAIT)
	AddComponent(/datum/component/butchering, 80, 70)

/obj/item/nullrod/armblade/tentacle
	name = "unholy blessing"
	icon_state = "tentacle"
	inhand_icon_state = "tentacle"

/obj/item/nullrod/carp
	name = "carp-sie plushie"
	desc = "An adorable stuffed toy that resembles the god of all carp. The teeth look pretty sharp. Activate it to receive the blessing of Carp-Sie."
	icon = 'icons/obj/plushes.dmi'
	icon_state = "carpplush"
	inhand_icon_state = "carp_plushie"
	worn_icon_state = "nullrod"
	lefthand_file = 'icons/mob/inhands/items_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/items_righthand.dmi'
	force = 15
	attack_verb_continuous = list("кусает", "грызёт", "шлёпает плавником")
	attack_verb_simple = list("кусает", "грызёт", "шлёпает плавником")
	hitsound = 'sound/weapons/bite.ogg'

/obj/item/nullrod/carp/Initialize()
	. = ..()
	AddComponent(/datum/component/faction_granter, "carp", holy_role_required = HOLY_ROLE_PRIEST, grant_message = span_boldnotice("You are blessed by Carp-Sie. Wild space carp will no longer attack you."))

/obj/item/nullrod/claymore/bostaff //May as well make it a "claymore" and inherit the blocking
	name = "monk's staff"
	desc = "A long, tall staff made of polished wood. Traditionally used in ancient old-Earth martial arts, it is now used to harass the clown."
	w_class = WEIGHT_CLASS_BULKY
	force = 15
	block_chance = 40
	slot_flags = ITEM_SLOT_BACK
	sharpness = NONE
	hitsound = "swing_hit"
	attack_verb_continuous = list("сносит", "бьёт", "колотит", "стучит")
	attack_verb_simple = list("сносит", "бьёт", "колотит", "стучит")
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "bostaff0"
	inhand_icon_state = "bostaff0"
	worn_icon_state = "bostaff0"
	lefthand_file = 'icons/mob/inhands/weapons/staves_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/staves_righthand.dmi'

/obj/item/nullrod/tribal_knife
	icon_state = "crysknife"
	desc = "They say fear is the true mind killer, but stabbing them in the head works too. Honour compels you to not sheathe it once drawn."
	inhand_icon_state = "crysknife"
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	name = "arrhythmic knife"
	w_class = WEIGHT_CLASS_HUGE
	sharpness = SHARP_EDGED
	slot_flags = null
	hitsound = 'sound/weapons/bladeslice.ogg'
	attack_verb_continuous = list("атакует", "режет", "кромсает", "нарезает", "протыкает", "втыкает", "разрезает", "мясит")
	attack_verb_simple = list("атакует", "режет", "кромсает", "нарезает", "протыкает", "втыкает", "разрезает", "мясит")
	item_flags = SLOWS_WHILE_IN_HAND

/obj/item/nullrod/tribal_knife/Initialize(mapload)
	. = ..()
	START_PROCESSING(SSobj, src)
	AddComponent(/datum/component/butchering, 50, 100)

/obj/item/nullrod/tribal_knife/Destroy()
	STOP_PROCESSING(SSobj, src)
	. = ..()

/obj/item/nullrod/tribal_knife/process()
	slowdown = rand(-10, 10)/10
	if(iscarbon(loc))
		var/mob/living/carbon/wielder = loc
		if(wielder.is_holding(src))
			wielder.update_equipment_speed_mods()

/obj/item/nullrod/pitchfork
	name = "unholy pitchfork"
	desc = "Holding this makes you look absolutely devilish."
	icon_state = "pitchfork0"
	worn_icon_state = "pitchfork0"
	lefthand_file = 'icons/mob/inhands/weapons/polearms_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/polearms_righthand.dmi'
	worn_icon_state = "pitchfork0"
	w_class = WEIGHT_CLASS_BULKY
	slot_flags = ITEM_SLOT_BACK
	attack_verb_continuous = list("насаживает", "пробивает", "втыкает", "макаронит")
	attack_verb_simple = list("насаживает", "пробивает", "втыкает", "макаронит")
	hitsound = 'sound/weapons/bladeslice.ogg'
	sharpness = SHARP_EDGED

/obj/item/nullrod/egyptian
	name = "egyptian staff"
	desc = "A tutorial in mummification is carved into the staff. You could probably craft the wraps if you had some cloth."
	icon = 'icons/obj/guns/magic.dmi'
	icon_state = "pharoah_sceptre"
	inhand_icon_state = "pharoah_sceptre"
	lefthand_file = 'icons/mob/inhands/weapons/staves_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/staves_righthand.dmi'
	worn_icon_state = "pharoah_sceptre"
	w_class = WEIGHT_CLASS_NORMAL
	slot_flags = ITEM_SLOT_BACK
	attack_verb_continuous = list("лупит", "бьёт", "атакует")
	attack_verb_simple = list("лупит", "бьёт", "атакует")

/obj/item/nullrod/hypertool
	name = "hypertool"
	desc = "A tool so powerful even you cannot perfectly use it."
	icon = 'icons/obj/device.dmi'
	icon_state = "hypertool"
	inhand_icon_state = "hypertool"
	worn_icon_state = "hypertool"
	lefthand_file = 'icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/tools_righthand.dmi'
	slot_flags = ITEM_SLOT_BELT
	damtype = BRAIN
	armour_penetration = 35
	attack_verb_continuous = list("пульсирует", "спаивает", "режет")
	attack_verb_simple = list("пульсирует", "спаивает", "режет")
	hitsound = 'sound/effects/sparks4.ogg'

/obj/item/nullrod/spear
	name = "ancient spear"
	desc = "An ancient spear made of brass, I mean gold, I mean bronze. It looks highly mechanical."
	icon = 'icons/obj/clockwork_objects.dmi'
	icon_state = "ratvarian_spear"
	inhand_icon_state = "ratvarian_spear"
	lefthand_file = 'icons/mob/inhands/antag/clockwork_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/antag/clockwork_righthand.dmi'
	slot_flags = ITEM_SLOT_BELT
	armour_penetration = 10
	sharpness = SHARP_POINTY
	w_class = WEIGHT_CLASS_HUGE
	attack_verb_continuous = list("насаживает", "пробивает", "втыкает", "макаронит")
	attack_verb_simple = list("насаживает", "пробивает", "втыкает", "макаронит")
	hitsound = 'sound/weapons/bladeslice.ogg'
