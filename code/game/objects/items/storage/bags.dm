/*
 *	These absorb the functionality of the plant bag, ore satchel, etc.
 *	They use the use_to_pickup, quick_gather, and quick_empty functions
 *	that were already defined in weapon/storage, but which had been
 *	re-implemented in other classes.
 *
 *	Contains:
 *		Trash Bag
 *		Mining Satchel
 *		Plant Bag
 *		Sheet Snatcher
 *		Book Bag
 *      Biowaste Bag
 *
 *	-Sayu
 */

//  Generic non-item
/obj/item/storage/bag
	slot_flags = ITEM_SLOT_BELT
	w_class = WEIGHT_CLASS_BULKY

/obj/item/storage/bag/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.allow_quick_gather = TRUE
	STR.allow_quick_empty = TRUE
	STR.display_numerical_stacking = TRUE
	STR.click_gather = TRUE

// -----------------------------
//          Trash bag
// -----------------------------
/obj/item/storage/bag/trash
	name = "мешок для мусора"
	desc = "Сверхпрочный черный полимерный материал. Пора выносить мусор!"
	icon = 'icons/obj/janitor.dmi'
	icon_state = "trashbag"
	inhand_icon_state = "trashbag"
	lefthand_file = 'icons/mob/inhands/equipment/custodial_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/custodial_righthand.dmi'
	slot_flags = null
	var/insertable = TRUE

/obj/item/storage/bag/trash/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_w_class = WEIGHT_CLASS_SMALL
	STR.max_combined_w_class = 30
	STR.max_items = 30
	STR.set_holdable(null, list(/obj/item/disk/nuclear))

/obj/item/storage/bag/trash/suicide_act(mob/user)
	user.visible_message(span_suicide("[user] puts [src] over [user.ru_ego()] head and starts chomping at the insides! Disgusting!"))
	playsound(loc, 'sound/items/eatfood.ogg', 50, TRUE, -1)
	return (TOXLOSS)

/obj/item/storage/bag/trash/update_icon_state()
	switch(contents.len)
		if(20 to INFINITY)
			icon_state = "[initial(icon_state)]3"
		if(11 to 20)
			icon_state = "[initial(icon_state)]2"
		if(1 to 11)
			icon_state = "[initial(icon_state)]1"
		else
			icon_state = "[initial(icon_state)]"

/obj/item/storage/bag/trash/cyborg
	insertable = FALSE

/obj/item/storage/bag/trash/proc/janicart_insert(mob/user, obj/structure/janitorialcart/J)
	if(insertable)
		J.put_in_cart(src, user)
		J.mybag=src
		J.update_icon()
	else
		to_chat(user, span_warning("You are unable to fit your [name] into the [J.name]."))
		return

/obj/item/storage/bag/trash/filled

/obj/item/storage/bag/trash/filled/PopulateContents()
	. = ..()
	for(var/i in 1 to rand(1, 7))
		new /obj/effect/spawner/lootdrop/garbage_spawner(src)
	update_icon_state()

/obj/item/storage/bag/trash/bluespace
	name = "бездонный мешок для мусора"
	desc = "Новейший и самый удобный при хранении мешок для мусора, способный вместить огромное количество мусора."
	icon_state = "bluetrashbag"
	inhand_icon_state = "bluetrashbag"
	item_flags = NO_MAT_REDEMPTION

/obj/item/storage/bag/trash/bluespace/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_combined_w_class = 60
	STR.max_items = 60

/obj/item/storage/bag/trash/bluespace/cyborg
	insertable = FALSE

// -----------------------------
//        Mining Satchel
// -----------------------------

/obj/item/storage/bag/ore
	name = "сумка для руды"
	desc = "Эту сумку можно использовать для хранения и транспортировки руды."
	gender = FEMALE
	icon = 'icons/obj/mining.dmi'
	icon_state = "satchel"
	worn_icon_state = "satchel"
	slot_flags = ITEM_SLOT_BELT | ITEM_SLOT_POCKETS
	w_class = WEIGHT_CLASS_NORMAL
	component_type = /datum/component/storage/concrete/stack
	var/spam_protection = FALSE //If this is TRUE, the holder won't receive any messages when they fail to pick up ore through crossing it
	var/mob/listeningTo

/obj/item/storage/bag/ore/ComponentInitialize()
	. = ..()
	AddElement(/datum/element/rad_insulation, 0.01) //please datum mats no more cancer
	var/datum/component/storage/concrete/stack/STR = GetComponent(/datum/component/storage/concrete/stack)
	STR.allow_quick_empty = TRUE
	STR.set_holdable(list(/obj/item/stack/ore))
	STR.max_w_class = WEIGHT_CLASS_HUGE
	STR.max_combined_stack_amount = 50

/obj/item/storage/bag/ore/equipped(mob/user)
	. = ..()
	if(listeningTo == user)
		return
	if(listeningTo)
		UnregisterSignal(listeningTo, COMSIG_MOVABLE_MOVED)
	RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(Pickup_ores))
	listeningTo = user

/obj/item/storage/bag/ore/dropped()
	. = ..()
	if(listeningTo)
		UnregisterSignal(listeningTo, COMSIG_MOVABLE_MOVED)
		listeningTo = null

/obj/item/storage/bag/ore/proc/Pickup_ores(mob/living/user)
	var/show_message = FALSE
	var/obj/structure/ore_box/box
	var/turf/tile = user.loc
	if (!isturf(tile))
		return
	if (istype(user.pulling, /obj/structure/ore_box))
		box = user.pulling
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	if(STR)
		for(var/A in tile)
			if (!is_type_in_typecache(A, STR.can_hold))
				continue
			if (box)
				user.transferItemToLoc(A, box)
				show_message = TRUE
			else if(SEND_SIGNAL(src, COMSIG_TRY_STORAGE_INSERT, A, user, TRUE))
				show_message = TRUE
			else
				if(!spam_protection)
					to_chat(user, span_warning("Видимо, [name] полна и не может вмещать больше!"))
					spam_protection = TRUE
					continue
	if(show_message)
		playsound(user, "rustle", 50, TRUE)
		if (box)
			user.visible_message(span_notice("[user] выгружает руду под собой[user.ru_na()] в [box].") , \
			span_notice("Загружаю руду под собой в [box]."))
		else
			user.visible_message(span_notice("[user] собирает руду под [user.ru_na()].") , \
				span_notice("Собираю руду под собой в [skloname(name, VINITELNI, MALE)]."))
	spam_protection = FALSE

/obj/item/storage/bag/ore/cyborg
	name = "сумка для руды киборга"

/obj/item/storage/bag/ore/holding //miners, your messiah has arrived
	name = "бездонная сумка для руды"
	desc = "Революция в удобстве: этот рюкзак позволяет хранить огромное количество руды. Он оборудован мерами безопасности от сбоев."
	icon_state = "satchel_bspace"

/obj/item/storage/bag/ore/holding/ComponentInitialize()
	. = ..()
	var/datum/component/storage/concrete/stack/STR = GetComponent(/datum/component/storage/concrete/stack)
	STR.max_items = INFINITY
	STR.max_combined_w_class = INFINITY
	STR.max_combined_stack_amount = INFINITY

// -----------------------------
//          Plant bag
// -----------------------------

/obj/item/storage/bag/plants
	name = "сумка для растений"
	icon = 'icons/obj/hydroponics/equipment.dmi'
	icon_state = "plantbag"
	worn_icon_state = "plantbag"
	resistance_flags = FLAMMABLE

/obj/item/storage/bag/plants/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_w_class = WEIGHT_CLASS_NORMAL
	STR.max_combined_w_class = 100
	STR.max_items = 100
	STR.set_holdable(list(
		/obj/item/food/grown,
		/obj/item/seeds,
		/obj/item/grown,
		/obj/item/reagent_containers/honeycomb,
		/obj/item/graft,
		/obj/item/disk/plantgene,
		))
////////

/obj/item/storage/bag/plants/portaseeder
	name = "портативный экстрактор семян"
	desc = "Для предприимчивого ботаника в движении. Менее эффективен, чем стационарная модель, он дает одно семя на растение."
	icon_state = "portaseeder"

/obj/item/storage/bag/plants/portaseeder/verb/dissolve_contents()
	set name = "Активировать экстракцию семян"
	set category = "Объект"
	set desc = "Активируйте, чтобы превратить растения в семена для посадки."
	if(usr.incapacitated())
		return
	for(var/obj/item/O in contents)
		seedify(O, 1)

// -----------------------------
//        Sheet Snatcher
// -----------------------------
// Because it stacks stacks, this doesn't operate normally.
// However, making it a storage/bag allows us to reuse existing code in some places. -Sayu

/obj/item/storage/bag/sheetsnatcher
	name = "сумка для материалов"
	desc = "Сумка разработанная для шахтеров и строителей, способная хранить до 500 листов различных материалов."
	icon = 'icons/obj/mining.dmi'
	icon_state = "sheetsnatcher"
	worn_icon_state = "satchel"

	var/capacity = 500; //the number of sheets it can carry.
	component_type = /datum/component/storage/concrete/stack

/obj/item/storage/bag/sheetsnatcher/ComponentInitialize()
	. = ..()
	AddElement(/datum/element/rad_insulation, 0.01)
	var/datum/component/storage/concrete/stack/STR = GetComponent(/datum/component/storage/concrete/stack)
	STR.allow_quick_empty = TRUE
	STR.max_combined_w_class = 500
	STR.max_items = 14
	STR.set_holdable(list(
			/obj/item/stack/sheet,
			/obj/item/stack/tile/bronze
			),
		list(
			/obj/item/stack/sheet/mineral/sandstone,
			/obj/item/stack/sheet/mineral/wood
			))
	STR.max_combined_stack_amount = 500

// -----------------------------
//    Sheet Snatcher (Cyborg)
// -----------------------------

/obj/item/storage/bag/sheetsnatcher/borg
	name = "сумка для материалов киборга"
	desc = "Сумка разработанная для шахтеров и строителей, способная хранить до 1000 листов различных материалов."
	capacity = 1000//Borgs get more because >specialization

/obj/item/storage/bag/sheetsnatcher/borg/ComponentInitialize()
	. = ..()
	var/datum/component/storage/concrete/stack/STR = GetComponent(/datum/component/storage/concrete/stack)
	STR.max_combined_stack_amount = 1000

// -----------------------------
//           Book bag
// -----------------------------

/obj/item/storage/bag/books
	name = "Сумка для книг"
	desc = "Сумка для книг."
	icon = 'icons/obj/library.dmi'
	icon_state = "bookbag"
	worn_icon_state = "bookbag"
	resistance_flags = FLAMMABLE

/obj/item/storage/bag/books/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_w_class = WEIGHT_CLASS_NORMAL
	STR.max_combined_w_class = 21
	STR.max_items = 7
	STR.display_numerical_stacking = FALSE
	STR.set_holdable(list(
		/obj/item/book,
		/obj/item/storage/book,
		/obj/item/spellbook
		))

/*
 * Trays - Agouri
 */
/obj/item/storage/bag/tray
	name = "поднос"
	icon = 'icons/obj/food/containers.dmi'
	icon_state = "tray"
	worn_icon_state = "tray"
	desc = "Металлический поднос для укладки еды."
	force = 5
	throwforce = 10
	throw_speed = 3
	throw_range = 5
	flags_1 = CONDUCT_1
	slot_flags = ITEM_SLOT_BELT
	custom_materials = list(/datum/material/iron=3000)
	custom_price = PAYCHECK_ASSISTANT * 0.6

/obj/item/storage/bag/tray/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_w_class = WEIGHT_CLASS_BULKY //Plates are required bulky to keep them out of backpacks
	STR.set_holdable(list(
		/obj/item/plate,
		/obj/item/reagent_containers/food,
		/obj/item/reagent_containers/glass,
		/obj/item/food,
		/obj/item/kitchen/knife,
		/obj/item/kitchen/rollingpin,
		/obj/item/kitchen/fork,
		)) //Should cover: Bottles, Beakers, Bowls, Booze, Glasses, Food, and Kitchen Tools.
	STR.insert_preposition = "на"
	STR.max_items = 7

/obj/item/storage/bag/tray/attack(mob/living/M, mob/living/user)
	. = ..()
	// Drop all the things. All of them.
	var/list/obj/item/oldContents = contents.Copy()
	SEND_SIGNAL(src, COMSIG_TRY_STORAGE_QUICK_EMPTY)
	// Make each item scatter a bit
	for(var/obj/item/tray_item in oldContents)
		do_scatter(tray_item)

	if(prob(50))
		playsound(M, 'sound/items/trayhit1.ogg', 50, TRUE)
	else
		playsound(M, 'sound/items/trayhit2.ogg', 50, TRUE)

	if(ishuman(M))
		if(prob(10))
			M.Paralyze(40)
	update_icon()

/obj/item/storage/bag/tray/proc/do_scatter(obj/item/tray_item)
	var/delay = rand(2,4)
	var/datum/move_loop/loop = SSmove_manager.move_rand(tray_item, list(NORTH,SOUTH,EAST,WEST), delay, timeout = rand(1, 2) * delay, flags = MOVEMENT_LOOP_START_FAST)
	//This does mean scattering is tied to the tray. Not sure how better to handle it
	RegisterSignal(loop, COMSIG_MOVELOOP_POSTPROCESS, PROC_REF(change_speed))

/obj/item/storage/bag/tray/proc/change_speed(datum/move_loop/source)
	SIGNAL_HANDLER
	var/new_delay = rand(2, 4)
	var/count = source.lifetime / source.delay
	source.lifetime = count * new_delay
	source.delay = new_delay

/obj/item/storage/bag/tray/update_overlays()
	. = ..()
	for(var/obj/item/I in contents)
		var/mutable_appearance/I_copy = new(I)
		I_copy.plane = FLOAT_PLANE
		I_copy.layer = FLOAT_LAYER
		. += I_copy

/obj/item/storage/bag/tray/Entered()
	. = ..()
	update_icon()

/obj/item/storage/bag/tray/Exited()
	. = ..()
	update_icon()

/obj/item/storage/bag/tray/cafeteria
	name = "поднос кафетерия"
	icon = 'icons/obj/food/containers.dmi'
	icon_state = "foodtray"
	desc = "Дешевый металлический поднос, на котором можно сложить сегодняшнюю еду."

/*
 *	Chemistry bag
 */

/obj/item/storage/bag/chemistry
	name = "сумка для химии"
	icon = 'white/Feline/icons/med_items.dmi'
	icon_state = "bag_chem"
	worn_icon_state = "chembag"
	desc = "Сумка для хранения таблеток, пластырей и бутылочек."
	resistance_flags = FIRE_PROOF

/obj/item/storage/bag/chemistry/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_combined_w_class = 200
	STR.max_items = 100
	STR.insert_preposition = "в"
	STR.set_holdable(list(
		/obj/item/reagent_containers/pill,
		/obj/item/reagent_containers/glass/beaker,
		/obj/item/reagent_containers/glass/bottle,
		/obj/item/reagent_containers/food/drinks/waterbottle,
		/obj/item/reagent_containers/medigel,
		/obj/item/reagent_containers/syringe,
		/obj/item/reagent_containers/hypospray/medipen,
		/obj/item/reagent_containers/dropper,
		/obj/item/reagent_containers/chem_pack
		))

/*
 *  Biowaste bag (mostly for xenobiologists)
 */

/obj/item/storage/bag/bio
	name = "био сумка"
	icon = 'white/Feline/icons/med_items.dmi'
	icon_state = "bag_bio"
	worn_icon_state = "biobag"
	desc = "Сумка для безопасной транспортировки и утилизации биоотходов и других биологических материалов."
	resistance_flags = FLAMMABLE

/obj/item/storage/bag/bio/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_combined_w_class = 200
	STR.max_items = 60
	STR.insert_preposition = "в"
	STR.set_holdable(list(
		/obj/item/slime_extract,
		/obj/item/reagent_containers/syringe,
		/obj/item/reagent_containers/dropper,
		/obj/item/reagent_containers/glass/beaker,
		/obj/item/reagent_containers/glass/bottle,
		/obj/item/reagent_containers/blood,
		/obj/item/reagent_containers/hypospray/medipen,
		/obj/item/food/deadmouse,
		/obj/item/food/monkeycube,
		/obj/item/organ,
		/obj/item/bodypart,
		/obj/item/petri_dish,
		/obj/item/swab
		))

/*
 *  Construction bag (for engineering, holds stock parts and electronics)
 */

/obj/item/storage/bag/construction
	name = "строительная сумка"
	icon = 'icons/obj/tools.dmi'
	icon_state = "construction_bag"
	worn_icon_state = "construction_bag"
	desc = "Сумка для хранения мелких строительных деталей."
	resistance_flags = FLAMMABLE

/obj/item/storage/bag/construction/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_combined_w_class = 100
	STR.max_items = 50
	STR.max_w_class = WEIGHT_CLASS_SMALL
	STR.insert_preposition = "в"
	STR.set_holdable(list(
		/obj/item/stack/ore/bluespace_crystal,
		/obj/item/assembly,
		/obj/item/stock_parts,
		/obj/item/reagent_containers/glass/beaker,
		/obj/item/stack/cable_coil,
		/obj/item/circuitboard,
		/obj/item/electronics,
		/obj/item/wallframe/camera
		))

/obj/item/storage/bag/harpoon_quiver
	name = "harpoon quiver"
	desc = "A quiver for holding harpoons."
	icon_state = "quiver"
	inhand_icon_state = "quiver"
	worn_icon_state = "harpoon_quiver"

/obj/item/storage/bag/harpoon_quiver/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_w_class = WEIGHT_CLASS_TINY
	STR.max_items = 40
	STR.max_combined_w_class = 100
	STR.set_holdable(list(
		/obj/item/ammo_casing/caseless/harpoon
		))

/obj/item/storage/bag/harpoon_quiver/PopulateContents()
	for(var/i in 1 to 40)
		new /obj/item/ammo_casing/caseless/harpoon(src)

/obj/item/storage/bag/pissbox
	name = "Коробка стансфер"
	desc = "Сделано в NanoTrasen."
	icon = 'icons/obj/ammo.dmi'
	icon_state = "pissbox"
	w_class = WEIGHT_CLASS_SMALL

/obj/item/storage/bag/pissbox/Initialize()
	. = ..()
	update_icon()

/obj/item/storage/bag/pissbox/update_icon_state()
	switch(contents.len)
		if(1 to INFINITY)
			icon_state = "[initial(icon_state)]1"
		else
			icon_state = "[initial(icon_state)]"

/obj/item/storage/bag/pissbox/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_w_class = WEIGHT_CLASS_BULKY
	STR.max_items = 33
	STR.max_combined_w_class = 100
	STR.set_holdable(list(
		/obj/item/ammo_casing/caseless/pissball
		))

/obj/item/storage/bag/pissbox/PopulateContents()
	for(var/i in 1 to 9)
		new /obj/item/ammo_casing/caseless/pissball(src)

/obj/item/storage/bag/pissbox/emptyStorage()
	. = ..()
	update_icon()
