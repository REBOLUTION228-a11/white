////////////////////////////////////////////////////////////////////////////////
/// Drinks.
////////////////////////////////////////////////////////////////////////////////
/obj/item/reagent_containers/food/drinks
	name = "drink"
	desc = "yummy"
	icon = 'icons/obj/drinks.dmi'
	icon_state = null
	lefthand_file = 'icons/mob/inhands/misc/food_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/food_righthand.dmi'
	reagent_flags = OPENCONTAINER | DUNKABLE
	var/gulp_size = 5 //This is now officially broken ... need to think of a nice way to fix it.
	possible_transfer_amounts = list(5,10,15,20,25,30,50)
	volume = 50
	resistance_flags = NONE
	var/isGlass = TRUE //Whether the 'bottle' is made of glass or not so that milk cartons dont shatter when someone gets hit by it

/obj/item/reagent_containers/food/drinks/attack(mob/living/M, mob/user, def_zone)

	if(!reagents || !reagents.total_volume)
		to_chat(user, span_warning("[src.name] пуст!"))
		return FALSE

	if(!canconsume(M, user))
		return FALSE

	if (!is_drainable())
		to_chat(user, span_warning("Крышка [src.name] не открыта!"))
		return FALSE

	if(M == user)
		if(user.hydration >= HYDRATION_LEVEL_OVERHYDRATED)
			to_chat(M, span_warning("В меня больше не лезет содержимое [src.name]!"))
			return
		user.visible_message(span_notice("[user] делает глоток из [src.name].") , \
			span_notice("Делаю глоток из [src.name]."))
		if(HAS_TRAIT(M, TRAIT_VORACIOUS))
			M.changeNext_move(CLICK_CD_MELEE * 0.5) //chug! chug! chug!

	else
		if(M.hydration >= HYDRATION_LEVEL_OVERHYDRATED)
			M.visible_message(span_danger("[user] не может больше напоить [M] содержимым [src.name]."), \
			span_userdanger("[user] больше не может напоить меня содержимым [src.name]."))
			return
		M.visible_message(span_danger("[user] пытается напоить [M] содержимым [src.name].") , \
			span_userdanger("[user] пытается напоить меня содержимым [src.name]."))
		if(!do_mob(user, M))
			return
		if(!reagents || !reagents.total_volume)
			return // The drink might be empty after the delay, such as by spam-feeding
		M.visible_message(span_danger("[user] поит [M] содержимым [src.name].") , \
			span_userdanger("[user] поит меня содержимым [src.name]."))
		log_combat(user, M, "fed", reagents.log_list())

	for(var/datum/reagent/R in reagents.reagent_list)
		if(R in M.known_reagent_sounds)
			continue
		M.known_reagent_sounds += R
		SEND_SOUND(M, R.special_sound)
		break

	SEND_SIGNAL(src, COMSIG_DRINK_DRANK, M, user)
	var/fraction = min(gulp_size/reagents.total_volume, 1)
	reagents.trans_to(M, gulp_size, transfered_by = user, methods = INGEST)
	checkLiked(fraction, M)

	playsound(M.loc,'sound/items/drink.ogg', rand(10,50), TRUE)
	if(iscarbon(M))
		var/mob/living/carbon/carbon_drinker = M
		var/list/diseases = carbon_drinker.get_static_viruses()
		if(LAZYLEN(diseases))
			var/list/datum/disease/diseases_to_add = list()
			for(var/d in diseases)
				var/datum/disease/malady = d
				if(malady.spread_flags & DISEASE_SPREAD_CONTACT_FLUIDS)
					diseases_to_add += malady
			if(LAZYLEN(diseases_to_add))
				AddComponent(/datum/component/infective, diseases_to_add)
	return TRUE

/*
 * On accidental consumption, make sure the container is partially glass, and continue to the reagent_container proc
 */
/obj/item/reagent_containers/food/drinks/on_accidental_consumption(mob/living/carbon/M, mob/living/carbon/user, obj/item/source_item,  discover_after = TRUE)
	if(isGlass && !custom_materials)
		set_custom_materials(list(GET_MATERIAL_REF(/datum/material/glass) = 5))
	return ..()

/obj/item/reagent_containers/food/drinks/afterattack(obj/target, mob/user , proximity)
	. = ..()
	if(!proximity)
		return

	if(target.is_refillable() && is_drainable()) //Something like a glass. Player probably wants to transfer TO it.
		if(!reagents.total_volume)
			to_chat(user, span_warning("[src.name] пуст."))
			return

		if(target.reagents.holder_full())
			to_chat(user, span_warning("[target] полный."))
			return

		var/refill = reagents.get_master_reagent_id()
		var/trans = src.reagents.trans_to(target, amount_per_transfer_from_this, transfered_by = user)
		to_chat(user, span_notice("Переливаю [trans] единиц жидкости в [target]."))

		playsound(get_turf(user), pick(WATER_FLOW_MINI), 50, TRUE)

		if(iscyborg(user)) //Cyborg modules that include drinks automatically refill themselves, but drain the borg's cell
			var/mob/living/silicon/robot/bro = user
			bro.cell.use(30)
			addtimer(CALLBACK(reagents, TYPE_PROC_REF(/datum/reagents, add_reagent), refill, trans), 600)

	else if(target.is_drainable()) //A dispenser. Transfer FROM it TO us.
		if (!is_refillable())
			to_chat(user, span_warning("Крышка [src.name] не открыта!"))
			return

		if(!target.reagents.total_volume)
			to_chat(user, span_warning("[target] пуст."))
			return

		if(reagents.holder_full())
			to_chat(user, span_warning("[src.name] полон."))
			return

		var/trans = target.reagents.trans_to(src, amount_per_transfer_from_this, transfered_by = user)
		to_chat(user, span_notice("Переливаю в [src.name] [trans] единиц из [target]."))

		playsound(get_turf(user), pick(WATER_FLOW_MINI), 50, TRUE)

/obj/item/reagent_containers/food/drinks/attackby(obj/item/I, mob/user, params)
	var/hotness = I.get_temperature()
	if(hotness && reagents)
		reagents.expose_temperature(hotness)
		to_chat(user, span_notice("Нагреваю [name] при помощи [I.name]!"))

	//Cooling method
	if(istype(I, /obj/item/extinguisher))
		var/obj/item/extinguisher/extinguisher = I
		if(extinguisher.safety)
			return
		if(extinguisher.reagents.total_volume < 1)
			to_chat(user, span_warning("[capitalize(extinguisher)] пуст!"))
			return
		var/cooling = (0 - reagents.chem_temp) * (extinguisher.cooling_power * 2)
		reagents.expose_temperature(cooling)
		to_chat(user, span_notice("Охлаждаю [name] при помощи [I]!"))
		playsound(loc, 'sound/effects/extinguish.ogg', 75, TRUE, -3)
		extinguisher.reagents.remove_all(1)

	..()

/obj/item/reagent_containers/food/drinks/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	. = ..()
	if(!.) //if the bottle wasn't caught
		smash(hit_atom, throwingdatum?.thrower, TRUE)

/obj/item/reagent_containers/food/drinks/proc/smash(atom/target, mob/thrower, ranged = FALSE)
	if(!isGlass)
		return
	if(QDELING(src) || !target)		//Invalid loc
		return
	if(bartender_check(target) && ranged)
		return
	var/obj/item/broken_bottle/B = new (loc)
	B.icon_state = icon_state
	var/icon/I = new('icons/obj/drinks.dmi', src.icon_state)
	I.Blend(B.broken_outline, ICON_OVERLAY, rand(5), 1)
	I.SwapColor(rgb(255, 0, 220, 255), rgb(0, 0, 0, 0))
	B.icon = I
	B.name = "разбитый [name]"
	if(prob(33))
		var/obj/item/shard/S = new(drop_location())
		target.Bumped(S)
	playsound(src, "shatter", 70, TRUE)
	transfer_fingerprints_to(B)
	qdel(src)
	target.Bumped(B)

/obj/item/reagent_containers/food/drinks/bullet_act(obj/projectile/P)
	. = ..()
	if(!(P.nodamage) && P.damage_type == BRUTE && !QDELETED(src))
		var/atom/T = get_turf(src)
		smash(T)
		return



////////////////////////////////////////////////////////////////////////////////
/// Drinks. END
////////////////////////////////////////////////////////////////////////////////


/obj/item/reagent_containers/food/drinks/trophy
	name = "pewter cup"
	desc = "Everyone gets a trophy."
	icon_state = "pewter_cup"
	w_class = WEIGHT_CLASS_TINY
	force = 1
	throwforce = 1
	amount_per_transfer_from_this = 5
	custom_materials = list(/datum/material/iron=100)
	possible_transfer_amounts = list()
	volume = 5
	flags_1 = CONDUCT_1
	spillable = TRUE
	resistance_flags = FIRE_PROOF
	isGlass = FALSE

/obj/item/reagent_containers/food/drinks/trophy/gold_cup
	name = "gold cup"
	desc = "You're winner!"
	icon_state = "golden_cup"
	w_class = WEIGHT_CLASS_BULKY
	force = 14
	throwforce = 10
	amount_per_transfer_from_this = 20
	custom_materials = list(/datum/material/gold=1000)
	volume = 150

/obj/item/reagent_containers/food/drinks/trophy/silver_cup
	name = "silver cup"
	desc = "Best loser!"
	icon_state = "silver_cup"
	w_class = WEIGHT_CLASS_NORMAL
	force = 10
	throwforce = 8
	amount_per_transfer_from_this = 15
	custom_materials = list(/datum/material/silver=800)
	volume = 100


/obj/item/reagent_containers/food/drinks/trophy/bronze_cup
	name = "bronze cup"
	desc = "At least you ranked!"
	icon_state = "bronze_cup"
	w_class = WEIGHT_CLASS_SMALL
	force = 5
	throwforce = 4
	amount_per_transfer_from_this = 10
	custom_materials = list(/datum/material/iron=400)
	volume = 25

///////////////////////////////////////////////Drinks
//Notes by Darem: Drinks are simply containers that start preloaded. Unlike condiments, the contents can be ingested directly
//	rather then having to add it to something else first. They should only contain liquids. They have a default container size of 50.
//	Formatting is the same as food.

/obj/item/reagent_containers/food/drinks/coffee
	name = "robust coffee"
	desc = "Careful, the beverage you're about to enjoy is extremely hot."
	icon_state = "coffee"
	list_reagents = list(/datum/reagent/consumable/coffee = 30)
	spillable = TRUE
	resistance_flags = FREEZE_PROOF
	isGlass = FALSE
	foodtype = BREAKFAST

/obj/item/reagent_containers/food/drinks/ice
	name = "ice cup"
	desc = "Careful, cold ice, do not chew."
	custom_price = PAYCHECK_PRISONER * 0.6
	icon_state = "coffee"
	list_reagents = list(/datum/reagent/consumable/ice = 30)
	spillable = TRUE
	isGlass = FALSE

/obj/item/reagent_containers/food/drinks/ice/prison
	name = "dirty ice cup"
	desc = "Either Nanotrasen's water supply is contaminated, or this machine actually vends lemon, chocolate, and cherry snow cones."
	list_reagents  = list(/datum/reagent/consumable/ice = 25, /datum/reagent/liquidgibs = 5)

/obj/item/reagent_containers/food/drinks/mug // parent type is literally just so empty mug sprites are a thing
	name = "mug"
	desc = "A drink served in a classy mug."
	icon_state = "tea"
	inhand_icon_state = "coffee"
	spillable = TRUE

/obj/item/reagent_containers/food/drinks/mug/update_icon_state()
	. = ..()
	icon_state = reagents.total_volume ? "tea" : "tea_empty"

/obj/item/reagent_containers/food/drinks/mug/tea
	name = "Duke Purple tea"
	desc = "An insult to Duke Purple is an insult to the Space Queen! Any proper gentleman will fight you, if you sully this tea."
	list_reagents = list(/datum/reagent/consumable/tea = 30)

/obj/item/reagent_containers/food/drinks/mug/coco
	name = "Dutch hot coco"
	desc = "Made in Space South America."
	list_reagents = list(/datum/reagent/consumable/hot_coco = 15, /datum/reagent/consumable/sugar = 5)
	foodtype = SUGAR
	resistance_flags = FREEZE_PROOF
	custom_price = PAYCHECK_ASSISTANT * 1.2


/obj/item/reagent_containers/food/drinks/dry_ramen
	name = "cup ramen"
	desc = "Just add 5ml of water, self heats! A taste that reminds you of your school years. Now new with salty flavour!"
	icon_state = "ramen"
	list_reagents = list(/datum/reagent/consumable/dry_ramen = 15, /datum/reagent/consumable/salt = 3)
	foodtype = GRAIN
	isGlass = FALSE
	custom_price = PAYCHECK_ASSISTANT * 0.9

/obj/item/reagent_containers/food/drinks/waterbottle
	name = "bottle of water"
	desc = "A bottle of water filled at an old Earth bottling facility."
	icon = 'icons/obj/drinks.dmi'
	icon_state = "smallbottle"
	inhand_icon_state = "bottle"
	list_reagents = list(/datum/reagent/water = 99.5, /datum/reagent/fluorine = 0.5)//see desc, don't think about it too hard
	custom_materials = list(/datum/material/plastic=1000)
	volume = 100
	amount_per_transfer_from_this = 10
	fill_icon_thresholds = list(0, 10, 25, 50, 75, 80, 90)
	isGlass = FALSE
	// The 2 bottles have separate cap overlay icons because if the bottle falls over while bottle flipping the cap stays fucked on the moved overlay
	var/cap_icon_state = "bottle_cap_small"
	var/cap_on = TRUE
	var/cap_lost = FALSE
	var/mutable_appearance/cap_overlay
	var/flip_chance = 10
	custom_price = PAYCHECK_PRISONER * 0.8

/obj/item/reagent_containers/food/drinks/waterbottle/Initialize()
	. = ..()
	cap_overlay = mutable_appearance(icon, cap_icon_state)
	if(cap_on)
		spillable = FALSE
		update_icon()

/obj/item/reagent_containers/food/drinks/waterbottle/update_overlays()
	. = ..()
	if(cap_on)
		. += cap_overlay

/obj/item/reagent_containers/food/drinks/waterbottle/examine(mob/user)
	. = ..()
	if(cap_lost)
		. += "<hr><span class='notice'>The cap seems to be missing.</span>"
	else if(cap_on)
		. += "<hr><span class='notice'>The cap is firmly on to prevent spilling. ПКМ to remove the cap.</span>"
	else
		. += "<hr><span class='notice'>The cap has been taken off. ПКМ to put a cap on.</span>"

/obj/item/reagent_containers/food/drinks/waterbottle/AltClick(mob/user)
	. = ..()
	if(cap_lost)
		to_chat(user, span_warning("The cap seems to be missing! Where did it go?"))
		return

	var/fumbled = HAS_TRAIT(user, TRAIT_CLUMSY) && prob(5)
	if(cap_on || fumbled)
		cap_on = FALSE
		spillable = TRUE
		animate(src, transform = null, time = 2, loop = 0)
		if(fumbled)
			to_chat(user, span_warning("You fumble with [src] cap! The cap falls onto the ground and simply vanishes. Where the hell did it go?"))
			cap_lost = TRUE
		else
			to_chat(user, span_notice("You remove the cap from [src]."))
	else
		cap_on = TRUE
		spillable = FALSE
		to_chat(user, span_notice("You put the cap on [src]."))
	update_icon()

/obj/item/reagent_containers/food/drinks/waterbottle/is_refillable()
	if(cap_on)
		return FALSE
	. = ..()

/obj/item/reagent_containers/food/drinks/waterbottle/is_drainable()
	if(cap_on)
		return FALSE
	. = ..()

/obj/item/reagent_containers/food/drinks/waterbottle/attack(mob/target, mob/user, def_zone)
	if(!target)
		return

	if(user.a_intent != INTENT_HARM)
		if(cap_on && reagents.total_volume && istype(target))
			to_chat(user, span_warning("You must remove the cap before you can do that!"))
			return

		return ..()

	if(!cap_on)
		SplashReagents(target)

/obj/item/reagent_containers/food/drinks/waterbottle/afterattack(obj/target, mob/user, proximity)
	if(cap_on && (target.is_refillable() || target.is_drainable() || (reagents.total_volume && user.a_intent == INTENT_HARM)))
		to_chat(user, span_warning("You must remove the cap before you can do that!"))
		return

	else if(istype(target, /obj/item/reagent_containers/food/drinks/waterbottle))
		var/obj/item/reagent_containers/food/drinks/waterbottle/WB = target
		if(WB.cap_on)
			to_chat(user, span_warning("[WB] has a cap firmly twisted on!"))
	. = ..()

// heehoo bottle flipping
/obj/item/reagent_containers/food/drinks/waterbottle/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	. = ..()
	if(!QDELETED(src) && cap_on && reagents.total_volume)
		if(prob(flip_chance)) // landed upright
			src.visible_message(span_notice("[capitalize(src.name)] lands upright!"))
			if(throwingdatum.thrower)
				SEND_SIGNAL(throwingdatum.thrower, COMSIG_ADD_MOOD_EVENT, "bottle_flip", /datum/mood_event/bottle_flip)
		else // landed on it's side
			animate(src, transform = matrix(prob(50)? 90 : -90, MATRIX_ROTATE), time = 3, loop = 0)

/obj/item/reagent_containers/food/drinks/waterbottle/pickup(mob/user)
	. = ..()
	animate(src, transform = null, time = 1, loop = 0)

/obj/item/reagent_containers/food/drinks/waterbottle/empty
	list_reagents = list()
	cap_on = FALSE

/obj/item/reagent_containers/food/drinks/waterbottle/large
	desc = "A fresh commercial-sized bottle of water."
	icon_state = "largebottle"
	custom_materials = list(/datum/material/plastic=3000)
	list_reagents = list(/datum/reagent/water = 150)
	volume = 150
	amount_per_transfer_from_this = 10
	possible_transfer_amounts = list(5,10,15,20,25,30,50,100)
	cap_icon_state = "bottle_cap"

/obj/item/reagent_containers/food/drinks/waterbottle/large/empty
	list_reagents = list()
	cap_on = FALSE

// Admin spawn
/obj/item/reagent_containers/food/drinks/waterbottle/relic
	name = "mysterious bottle"
	desc = "A bottle quite similar to a water bottle, but with some words scribbled on with a marker. It seems to be radiating some kind of energy."
	flip_chance = 100 // FLIPP

/obj/item/reagent_containers/food/drinks/waterbottle/relic/Initialize()
	var/reagent_id = get_random_reagent_id()
	var/datum/reagent/random_reagent = new reagent_id
	list_reagents = list(random_reagent.type = 50)
	. = ..()
	desc += span_notice("The writing reads '[random_reagent.name]'.")
	update_icon()

/obj/item/reagent_containers/food/drinks/beer
	name = "space beer"
	desc = "Beer. In space."
	icon_state = "beer"
	list_reagents = list(/datum/reagent/consumable/ethanol/beer = 30)
	foodtype = GRAIN | ALCOHOL
	custom_price = PAYCHECK_EASY

/obj/item/reagent_containers/food/drinks/beer/light
	name = "Carp Lite"
	desc = "Brewed with \"Pure Ice Asteroid Spring Water\"."
	list_reagents = list(/datum/reagent/consumable/ethanol/beer/light = 30)

/obj/item/reagent_containers/food/drinks/ale
	name = "Magm-Ale"
	desc = "A true dorf's drink of choice."
	icon_state = "alebottle"
	inhand_icon_state = "beer"
	list_reagents = list(/datum/reagent/consumable/ethanol/ale = 30)
	foodtype = GRAIN | ALCOHOL
	custom_price = PAYCHECK_EASY

/obj/item/reagent_containers/food/drinks/sillycup
	name = "бумажный стаканчик"
	desc = "Для воды."
	icon_state = "water_cup_e"
	possible_transfer_amounts = list()
	volume = 10
	spillable = TRUE
	isGlass = FALSE

/obj/item/reagent_containers/food/drinks/sillycup/update_icon_state()
	. = ..()
	icon_state = reagents.total_volume ? "water_cup" : "water_cup_e"

/obj/item/reagent_containers/food/drinks/sillycup/smallcarton
	name = "small carton"
	desc = "A small carton, intended for holding drinks."
	icon_state = "juicebox"
	volume = 15 //I figure if you have to craft these it should at least be slightly better than something you can get for free from a watercooler

/obj/item/reagent_containers/food/drinks/sillycup/smallcarton/on_reagent_change(datum/reagents/holder, ...)
	. = ..()
	if(!length(reagents.reagent_list))
		name = "small carton"
		desc = "A small carton, intended for holding drinks."
		foodtype = NONE
		return

	switch(reagents.get_master_reagent_id()) // - [] TODO: Unshitcode this. Right now I'm just passing through and this really needs it's own dedicated PR.
		if(/datum/reagent/consumable/orangejuice)
			name = "orange juice box" // I know this shouldn't be here, but I really don't have the time to fix this right now. Blame the last guy
			desc = "A great source of vitamins. Stay healthy!" // Ditto
			foodtype = FRUIT | BREAKFAST // Ditto
		if(/datum/reagent/consumable/milk)
			name = "carton of milk"
			desc = "An excellent source of calcium for growing space explorers."
			foodtype = DAIRY | BREAKFAST
		if(/datum/reagent/consumable/applejuice)
			name = "apple juice box"
			desc = "Sweet apple juice. Don't be late for school!"
			foodtype = FRUIT
		if(/datum/reagent/consumable/grapejuice)
			name = "grape juice box"
			desc = "Tasty grape juice in a fun little container. Non-alcoholic!"
			foodtype = FRUIT
		if(/datum/reagent/consumable/pineapplejuice)
			name = "pineapple juice box"
			desc = "Why would you even want this?"
			foodtype = FRUIT | PINEAPPLE
		if(/datum/reagent/consumable/milk/chocolate_milk)
			name = "carton of chocolate milk"
			desc = "Milk for cool kids!"
			foodtype = SUGAR
		if(/datum/reagent/consumable/ethanol/eggnog)
			name = "carton of eggnog"
			desc = "For enjoying the most wonderful time of the year."
			foodtype = MEAT

/obj/item/reagent_containers/food/drinks/sillycup/smallcarton/update_icon_state()
	. = ..()
	if(!length(reagents.reagent_list))
		icon_state = "juicebox"
		return

	switch(reagents.get_master_reagent_id()) // Thanks to update_name not existing we need to do this whole switch twice
		if(/datum/reagent/consumable/orangejuice)
			icon_state = "orangebox"
		if(/datum/reagent/consumable/milk)
			icon_state = "milkbox"
		if(/datum/reagent/consumable/applejuice)
			icon_state = "juicebox"
		if(/datum/reagent/consumable/grapejuice)
			icon_state = "grapebox"
		if(/datum/reagent/consumable/pineapplejuice)
			icon_state = "pineapplebox"
		if(/datum/reagent/consumable/milk/chocolate_milk)
			icon_state = "chocolatebox"
		if(/datum/reagent/consumable/ethanol/eggnog)
			icon_state = "nog2"

/obj/item/reagent_containers/food/drinks/sillycup/smallcarton/smash(atom/target, mob/thrower, ranged = FALSE)
	if(bartender_check(target) && ranged)
		return
	var/obj/item/broken_bottle/B = new (loc)
	B.icon_state = icon_state
	var/icon/I = new('icons/obj/drinks.dmi', src.icon_state)
	I.Blend(B.broken_outline, ICON_OVERLAY, rand(5), 1)
	I.SwapColor(rgb(255, 0, 220, 255), rgb(0, 0, 0, 0))
	B.icon = I
	B.name = "broken [name]"
	B.force = 0
	B.throwforce = 0
	B.desc = "A carton with the bottom half burst open. Might give you a papercut."
	transfer_fingerprints_to(B)
	qdel(src)
	target.Bumped(B)

/obj/item/reagent_containers/food/drinks/colocup
	name = "colo cup"
	desc = "A cheap, mass produced style of cup, typically used at parties. They never seem to come out red, for some reason..."
	icon = 'icons/obj/drinks.dmi'
	icon_state = "colocup"
	lefthand_file = 'icons/mob/inhands/misc/food_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/food_righthand.dmi'
	inhand_icon_state = "colocup"
	custom_materials = list(/datum/material/plastic = 1000)
	possible_transfer_amounts = list(5, 10, 15, 20)
	volume = 20
	amount_per_transfer_from_this = 5
	isGlass = FALSE
	/// Allows the lean sprite to display upon crafting
	var/random_sprite = TRUE

/obj/item/reagent_containers/food/drinks/colocup/Initialize()
	. = ..()
	pixel_x = rand(-4,4)
	pixel_y = rand(-4,4)
	if (random_sprite)
		icon_state = "colocup[rand(0, 6)]"

//////////////////////////drinkingglass and shaker//
//Note by Darem: This code handles the mixing of drinks. New drinks go in three places: In Chemistry-Reagents.dm (for the drink
//	itself), in Chemistry-Recipes.dm (for the reaction that changes the components into the drink), and here (for the drinking glass
//	icon states.

/obj/item/reagent_containers/food/drinks/shaker
	name = "шейкер"
	desc = "A metal shaker to mix drinks in."
	icon_state = "shaker"
	custom_materials = list(/datum/material/iron=1500)
	amount_per_transfer_from_this = 10
	volume = 100
	isGlass = FALSE

/obj/item/reagent_containers/food/drinks/flask
	name = "фляжка"
	desc = "Every good spaceman knows it's a good idea to bring along a couple of pints of whiskey wherever they go."
	custom_price = PAYCHECK_HARD * 2
	icon_state = "flask"
	custom_materials = list(/datum/material/iron=250)
	volume = 60
	isGlass = FALSE

/obj/item/reagent_containers/food/drinks/flask/gold
	name = "фляжка капитана"
	desc = "A gold flask belonging to the captain."
	icon_state = "flask_gold"
	custom_materials = list(/datum/material/gold=500)

/obj/item/reagent_containers/food/drinks/flask/det
	name = "фляжка детектива"
	desc = "The detective's only true friend."
	icon_state = "detflask"
	list_reagents = list(/datum/reagent/consumable/ethanol/whiskey = 30)

/obj/item/reagent_containers/food/drinks/britcup
	name = "cup"
	desc = "A cup with the british flag emblazoned on it."
	icon_state = "britcup"
	volume = 30
	spillable = TRUE

//////////////////////////soda_cans//
//These are in their own group to be used as IED's in /obj/item/grenade/ghettobomb.dm

/obj/item/reagent_containers/food/drinks/soda_cans
	name = "soda can"
	lefthand_file = 'icons/mob/inhands/misc/food_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/food_righthand.dmi'
	reagent_flags = NONE
	spillable = FALSE
	isGlass = FALSE
	custom_price = PAYCHECK_ASSISTANT * 0.9
	obj_flags = CAN_BE_HIT

/obj/item/reagent_containers/food/drinks/soda_cans/random/Initialize()
	..()
	var/T = pick(subtypesof(/obj/item/reagent_containers/food/drinks/soda_cans) - /obj/item/reagent_containers/food/drinks/soda_cans/random)
	new T(loc)
	return INITIALIZE_HINT_QDEL

/obj/item/reagent_containers/food/drinks/soda_cans/suicide_act(mob/living/carbon/human/H)
	if(!reagents.total_volume)
		H.visible_message(span_warning("[H] пытается take a big sip from [src]... The can is empty!"))
		return SHAME
	if(!is_drainable())
		open_soda()
		sleep(10)
	H.visible_message(span_suicide("[H] takes a big sip from [src]! It looks like [H.p_theyre()] trying to commit suicide!"))
	playsound(H,'sound/items/drink.ogg', 80, TRUE)
	reagents.trans_to(H, src.reagents.total_volume, transfered_by = H) //a big sip
	sleep(5)
	H.say(pick("Now, Outbomb Cuban Pete, THAT was a game.", "All these new fangled arcade games are too slow. I prefer the classics.", "They don't make 'em like Orion Trail anymore.", "You know what they say. Worst day of spess carp fishing is better than the best day at work.", "They don't make 'em like good old-fashioned singularity engines anymore."))
	if(H.age >= 30)
		H.Stun(50)
		sleep(50)
		playsound(H,'sound/items/drink.ogg', 80, TRUE)
		H.say(pick("Another day, another dollar.", "I wonder if I should hold?", "Diversifying is for young'ns.", "Yeap, times were good back then."))
		return MANUAL_SUICIDE_NONLETHAL
	sleep(20) //dramatic pause
	return TOXLOSS

/obj/item/reagent_containers/food/drinks/soda_cans/attack(mob/M, mob/user)
	if(istype(M, /mob/living/carbon) && !reagents.total_volume && user.a_intent == INTENT_HARM && user.zone_selected == BODY_ZONE_HEAD)
		if(M == user)
			user.visible_message(span_warning("[user] crushes the can of [src] on [user.ru_ego()] forehead!") , span_notice("You crush the can of [src] on your forehead."))
		else
			user.visible_message(span_warning("[user] crushes the can of [src] on [M] forehead!") , span_notice("You crush the can of [src] on [M] forehead."))
		playsound(M,'sound/weapons/pierce.ogg', rand(10,50), TRUE)
		var/obj/item/trash/can/crushed_can = new /obj/item/trash/can(M.loc)
		crushed_can.icon_state = icon_state
		qdel(src)
		return TRUE
	. = ..()

/obj/item/reagent_containers/food/drinks/soda_cans/bullet_act(obj/projectile/P)
	. = ..()
	if(!(P.nodamage) && P.damage_type == BRUTE && !QDELETED(src))
		var/obj/item/trash/can/crushed_can = new /obj/item/trash/can(src.loc)
		crushed_can.icon_state = icon_state
		var/atom/throw_target = get_edge_target_turf(crushed_can, pick(GLOB.alldirs))
		crushed_can.throw_at(throw_target, rand(1,2), 7)
		qdel(src)
		return

/obj/item/reagent_containers/food/drinks/soda_cans/proc/open_soda(mob/user)
	to_chat(user, "You pull back the tab of <b>[src.name]</b> with a satisfying pop.") //Ahhhhhhhh
	reagents.flags |= OPENCONTAINER
	playsound(src, "can_open", 50, TRUE)
	spillable = TRUE

/obj/item/reagent_containers/food/drinks/soda_cans/attack_self(mob/user)
	if(!is_drainable())
		open_soda(user)
	return ..()

/obj/item/reagent_containers/food/drinks/soda_cans/cola
	name = "Space Cola"
	desc = "Cola. in space."
	icon_state = "cola"
	list_reagents = list(/datum/reagent/consumable/space_cola = 30)
	foodtype = SUGAR

/obj/item/reagent_containers/food/drinks/soda_cans/tonic
	name = "T-Borg's tonic water"
	desc = "Quinine tastes funny, but at least it'll keep that Space Malaria away."
	icon_state = "tonic"
	list_reagents = list(/datum/reagent/consumable/tonic = 50)
	foodtype = ALCOHOL

/obj/item/reagent_containers/food/drinks/soda_cans/sodawater
	name = "soda water"
	desc = "A can of soda water. Why not make a scotch and soda?"
	icon_state = "sodawater"
	list_reagents = list(/datum/reagent/consumable/sodawater = 50)

/obj/item/reagent_containers/food/drinks/soda_cans/lemon_lime
	name = "апельсиновая газировка"
	desc = "Вы хотели АПЕЛЬСИНОВУЮ. А вместо этого Лимон с Лаймом."
	icon_state = "lemon-lime"
	list_reagents = list(/datum/reagent/consumable/lemon_lime = 30)
	foodtype = FRUIT

/obj/item/reagent_containers/food/drinks/soda_cans/lemon_lime/Initialize()
	. = ..()
	name = "lemon-lime soda"

/obj/item/reagent_containers/food/drinks/soda_cans/sol_dry
	name = "Sol Dry"
	desc = "Maybe this will help your tummy feel better. Maybe not."
	icon_state = "sol_dry"
	list_reagents = list(/datum/reagent/consumable/sol_dry = 30)
	foodtype = SUGAR

/obj/item/reagent_containers/food/drinks/soda_cans/space_up
	name = "Space-Up!"
	desc = "Tastes like a hull breach in your mouth."
	icon_state = "space-up"
	list_reagents = list(/datum/reagent/consumable/space_up = 30)
	foodtype = SUGAR | JUNKFOOD

/obj/item/reagent_containers/food/drinks/soda_cans/starkist
	name = "Star-kist"
	desc = "The taste of a star in liquid form. And, a bit of tuna...?"
	icon_state = "starkist"
	list_reagents = list(/datum/reagent/consumable/space_cola = 15, /datum/reagent/consumable/orangejuice = 15)
	foodtype = SUGAR | FRUIT | JUNKFOOD

/obj/item/reagent_containers/food/drinks/soda_cans/space_mountain_wind
	name = "Space Mountain Wind"
	desc = "Blows right through you like a space wind."
	icon_state = "space_mountain_wind"
	list_reagents = list(/datum/reagent/consumable/spacemountainwind = 30)
	foodtype = SUGAR | JUNKFOOD

/obj/item/reagent_containers/food/drinks/soda_cans/thirteenloko
	name = "Thirteen Loko"
	desc = "The CMO has advised crew members that consumption of Thirteen Loko may result in seizures, blindness, drunkenness, or even death. Please Drink Responsibly."
	icon_state = "thirteen_loko"
	list_reagents = list(/datum/reagent/consumable/ethanol/thirteenloko = 30)
	foodtype = SUGAR | JUNKFOOD

/obj/item/reagent_containers/food/drinks/soda_cans/dr_gibb
	name = "Dr. Gibb"
	desc = "A delicious mixture of 42 different flavors."
	icon_state = "dr_gibb"
	list_reagents = list(/datum/reagent/consumable/dr_gibb = 30)
	foodtype = SUGAR | JUNKFOOD

/obj/item/reagent_containers/food/drinks/soda_cans/pwr_game
	name = "Pwr Game"
	desc = "The only drink with the PWR that true gamers crave. When a gamer talks about gamerfuel, this is what they're literally referring to."
	icon_state = "purple_can"
	list_reagents = list(/datum/reagent/consumable/pwr_game = 30)

/obj/item/reagent_containers/food/drinks/soda_cans/shamblers
	name = "Shambler's juice"
	desc = "~Shake me up some of that Shambler's Juice!~"
	icon_state = "shamblers"
	list_reagents = list(/datum/reagent/consumable/shamblers = 30)
	foodtype = SUGAR | JUNKFOOD

/obj/item/reagent_containers/food/drinks/soda_cans/grey_bull
	name = "Grey Bull"
	desc = "Grey Bull, it gives you gloves!"
	icon_state = "energy_drink"
	list_reagents = list(/datum/reagent/consumable/grey_bull = 20)
	foodtype = SUGAR | JUNKFOOD

/obj/item/reagent_containers/food/drinks/soda_cans/monkey_energy
	name = "Monkey Energy"
	desc = "Unleash the ape!"
	icon_state = "monkey_energy"
	inhand_icon_state = "monkey_energy"
	list_reagents = list(/datum/reagent/consumable/monkey_energy = 50)
	foodtype = SUGAR | JUNKFOOD

/obj/item/reagent_containers/food/drinks/soda_cans/air
	name = "canned air"
	desc = "There is no air shortage. Do not drink."
	icon_state = "air"
	list_reagents = list(/datum/reagent/nitrogen = 24, /datum/reagent/oxygen = 6)
