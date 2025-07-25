
// **** Security gas mask ****

// Cooldown times
#define PHRASE_COOLDOWN 	30
#define OVERUSE_COOLDOWN 	180

// Aggression levels
#define AGGR_GOOD_COP 	1
#define AGGR_BAD_COP 	2
#define AGGR_SHIT_COP 	3
#define AGGR_BROKEN 	4

// Phrase list index markers
#define EMAG_PHRASE 		1	// index of emagged phrase
#define GOOD_COP_PHRASES 	6 	// final index of good cop phrases
#define BAD_COP_PHRASES 	12 	// final index of bad cop phrases
#define BROKE_PHRASES 		13 	// starting index of broken phrases
#define ALL_PHRASES 		19 	// total phrases

// All possible hailer phrases
// Remember to modify above index markers if changing contents
GLOBAL_LIST_INIT(hailer_phrases, list(
	/datum/hailer_phrase/emag,
	/datum/hailer_phrase/halt,
	/datum/hailer_phrase/bobby,
	/datum/hailer_phrase/compliance,
	/datum/hailer_phrase/justice,
	/datum/hailer_phrase/running,
	/datum/hailer_phrase/dontmove,
	/datum/hailer_phrase/floor,
	/datum/hailer_phrase/robocop,
	/datum/hailer_phrase/god,
	/datum/hailer_phrase/freeze,
	/datum/hailer_phrase/imperial,
	/datum/hailer_phrase/bash,
	/datum/hailer_phrase/harry,
	/datum/hailer_phrase/asshole,
	/datum/hailer_phrase/stfu,
	/datum/hailer_phrase/shutup,
	/datum/hailer_phrase/super,
	/datum/hailer_phrase/dredd
))

/obj/item/clothing/mask/gas/sechailer
	name = "противогаз охраны"
	desc = "Стандартный выпуск Защитный противогаз со встроенным устройством Compli-o-nator 3000. Воспроизведение более десятка предварительно записанных фраз о соответствии, разработанных, чтобы заставить подонков стоять на месте, пока вы их надеваете. Не ломать устройство."
	actions_types = list(/datum/action/item_action/halt, /datum/action/item_action/adjust)
	icon_state = "sechailer"
	inhand_icon_state = "sechailer"
	clothing_flags = BLOCK_GAS_SMOKE_EFFECT | MASKINTERNALS
	flags_inv = HIDEFACIALHAIR | HIDEFACE | HIDESNOUT
	w_class = WEIGHT_CLASS_SMALL
	visor_flags = BLOCK_GAS_SMOKE_EFFECT | MASKINTERNALS
	visor_flags_inv = HIDEFACIALHAIR | HIDEFACE | HIDESNOUT
	flags_cover = MASKCOVERSMOUTH | MASKCOVERSEYES | PEPPERPROOF
	visor_flags_cover = MASKCOVERSMOUTH | MASKCOVERSEYES | PEPPERPROOF
	var/aggressiveness = AGGR_BAD_COP
	var/overuse_cooldown = FALSE
	var/recent_uses = 0
	var/broken_hailer = FALSE
	var/safety = TRUE

/obj/item/clothing/mask/gas/sechailer/swat
	name = "маска спецназа"
	desc = "Обтягивающая тактическая маска с особо агрессивным Compli-o-nator 3000."
	actions_types = list(/datum/action/item_action/halt)
	icon_state = "swat"
	inhand_icon_state = "swat"
	aggressiveness = AGGR_SHIT_COP
	flags_inv = HIDEFACIALHAIR | HIDEFACE | HIDEEYES | HIDEEARS | HIDEHAIR | HIDESNOUT
	visor_flags_inv = 0

/obj/item/clothing/mask/gas/sechailer/swat/spacepol
	name = "маска космокопа"
	desc = "Обтягивающая тактическая маска, созданная в сотрудничестве с определенной мегакорпорацией, поставляется с особенно агрессивным Compli-o-nator 3000."
	icon_state = "spacepol"
	inhand_icon_state = "spacepol"

/obj/item/clothing/mask/gas/sechailer/cyborg
	name = "гавкатель"
	desc = "Набор распознаваемых предварительно записанных сообщений для киборгов, используемых при задержании преступников."
	icon = 'icons/obj/device.dmi'
	icon_state = "taperecorder_idle"
	slot_flags = null
	aggressiveness = AGGR_GOOD_COP // Borgs are nicecurity!
	actions_types = list(/datum/action/item_action/halt)

/obj/item/clothing/mask/gas/sechailer/screwdriver_act(mob/living/user, obj/item/I)
	. = TRUE
	if(..())
		return
	else if (aggressiveness == AGGR_BROKEN)
		to_chat(user, span_danger("Настраиваю ограничитель, но ничего не происходит. Похоже он сломан."))
		return
	var/position = aggressiveness == AGGR_GOOD_COP ? "середину" : aggressiveness == AGGR_BAD_COP ? "максимум" : "минимум"
	to_chat(user, span_notice("Настраиваю ограничитель на [position]."))
	aggressiveness = aggressiveness % 3 + 1 // loop AGGR_GOOD_COP -> AGGR_SHIT_COP

/obj/item/clothing/mask/gas/sechailer/wirecutter_act(mob/living/user, obj/item/I)
	. = TRUE
	..()
	if(aggressiveness != AGGR_BROKEN)
		to_chat(user, span_danger("Ограничитель сломан!"))
		aggressiveness = AGGR_BROKEN

/obj/item/clothing/mask/gas/sechailer/ui_action_click(mob/user, action)
	if(istype(action, /datum/action/item_action/halt))
		halt()
	else
		adjustmask(user)

/obj/item/clothing/mask/gas/sechailer/attack_self()
	halt()
/obj/item/clothing/mask/gas/sechailer/emag_act(mob/user)
	if(safety)
		safety = FALSE
		to_chat(user, span_warning("Незаметно зашквариваю [src.name] голосовую схему криптографическим секвенсором."))

/obj/item/clothing/mask/gas/sechailer/verb/halt()
	set category = "Объект"
	set name = "СТОЯТЬ"
	set src in usr
	if(!isliving(usr) || !can_use(usr) || cooldown)
		return
	if(broken_hailer)
		to_chat(usr, span_warning("Кричалка [src.name] сломана."))
		return

	// handle recent uses for overuse
	recent_uses++
	if(!overuse_cooldown) // check if we can reset recent uses
		recent_uses = 0
		overuse_cooldown = TRUE
		addtimer(CALLBACK(src, TYPE_PROC_REF(/obj/item/clothing/mask/gas/sechailer, reset_overuse_cooldown)), OVERUSE_COOLDOWN)

	switch(recent_uses)
		if(3)
			to_chat(usr, span_warning("Кричалка [src.name] начинает нагреваться."))
		if(4)
			to_chat(usr, span_userdanger("Кричалка [src.name] нагревается достаточно сильно!"))
		if(5) // overload
			broken_hailer = TRUE
			to_chat(usr, span_userdanger("Кричалка [src.name] перегревается и сгорает."))
			return

	// select phrase to play
	play_phrase(usr, GLOB.hailer_phrases[select_phrase()])


/obj/item/clothing/mask/gas/sechailer/proc/select_phrase()
	if (!safety)
		return EMAG_PHRASE
	else
		var/upper_limit
		switch (aggressiveness)
			if (AGGR_GOOD_COP)
				upper_limit = GOOD_COP_PHRASES
			if (AGGR_BAD_COP)
				upper_limit = BAD_COP_PHRASES
			else
				upper_limit = ALL_PHRASES
		return rand(aggressiveness == AGGR_BROKEN ? BROKE_PHRASES : EMAG_PHRASE + 1, upper_limit)

/obj/item/clothing/mask/gas/sechailer/proc/play_phrase(mob/user, datum/hailer_phrase/phrase)
	. = FALSE
	if (!cooldown)
		usr.audible_message("[usr] Compli-o-Nator: <font color='red' size='4'><b>[initial(phrase.phrase_text)]</b></font>")
		playsound(src, "sound/runtime/complionator/[initial(phrase.phrase_sound)].ogg", 100, FALSE, 4)
		cooldown = TRUE
		addtimer(CALLBACK(src, TYPE_PROC_REF(/obj/item/clothing/mask/gas/sechailer, reset_cooldown)), PHRASE_COOLDOWN)
		. = TRUE

/obj/item/clothing/mask/gas/sechailer/proc/reset_cooldown()
	cooldown = FALSE

/obj/item/clothing/mask/gas/sechailer/proc/reset_overuse_cooldown()
	overuse_cooldown = FALSE

/obj/item/clothing/mask/whistle
	name = "полицейский свисток"
	desc = "Полицейский свисток, когда вам нужно убедиться, что преступники вас слышат."
	icon_state = "whistle"
	inhand_icon_state = "whistle"
	slot_flags = ITEM_SLOT_MASK|ITEM_SLOT_NECK
	custom_price = PAYCHECK_HARD * 1.5
	actions_types = list(/datum/action/item_action/halt)

/obj/item/clothing/mask/whistle/ui_action_click(mob/user, action)
	if(cooldown < world.time - 100)
		usr.audible_message("<font color='red' size='5'><b>СТОЯТЬ!</b></font>")
		playsound(src, 'sound/misc/whistle.ogg', 100, FALSE, 4)
		cooldown = world.time

#undef PHRASE_COOLDOWN
#undef OVERUSE_COOLDOWN
#undef AGGR_GOOD_COP
#undef AGGR_BAD_COP
#undef AGGR_SHIT_COP
#undef AGGR_BROKEN
#undef EMAG_PHRASE
#undef GOOD_COP_PHRASES
#undef BAD_COP_PHRASES
#undef BROKE_PHRASES
#undef ALL_PHRASES
