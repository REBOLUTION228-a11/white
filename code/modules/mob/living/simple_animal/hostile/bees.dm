
#define BEE_IDLE_ROAMING		70 //The value of idle at which a bee in a beebox will try to wander
#define BEE_IDLE_GOHOME			0  //The value of idle at which a bee will try to go home
#define BEE_PROB_GOHOME			35 //Probability to go home when idle is below BEE_IDLE_GOHOME
#define BEE_PROB_GOROAM			5 //Probability to go roaming when idle is above BEE_IDLE_ROAMING
#define BEE_TRAY_RECENT_VISIT	200	//How long in deciseconds until a tray can be visited by a bee again
#define BEE_DEFAULT_COLOUR		"#e5e500" //the colour we make the stripes of the bee if our reagent has no colour (or we have no reagent)

#define BEE_POLLINATE_YIELD_CHANCE		33
#define BEE_POLLINATE_PEST_CHANCE		33
#define BEE_POLLINATE_POTENCY_CHANCE	50

/mob/living/simple_animal/hostile/poison/bees
	name = "bee"
	desc = "Buzzy buzzy bee, stingy sti- Ouch!"
	icon_state = ""
	icon_living = ""
	icon = 'icons/mob/bees.dmi'
	gender = FEMALE
	speak_emote = list("жужжит")
	emote_hear = list("жужжит")
	turns_per_move = 0
	melee_damage_lower = 1
	melee_damage_upper = 1
	attack_verb_continuous = "жалит"
	attack_verb_simple = "жалит"
	response_help_continuous = "shoos"
	response_help_simple = "shoo"
	response_disarm_continuous = "swats away"
	response_disarm_simple = "swat away"
	response_harm_continuous = "squashes"
	response_harm_simple = "squash"
	maxHealth = 10
	health = 10
	faction = list("hostile")
	move_to_delay = 0
	obj_damage = 0
	ventcrawler = VENTCRAWLER_ALWAYS
	environment_smash = ENVIRONMENT_SMASH_NONE
	mouse_opacity = MOUSE_OPACITY_OPAQUE
	pass_flags = PASSTABLE | PASSGRILLE | PASSMOB
	density = FALSE
	mob_size = MOB_SIZE_TINY
	mob_biotypes = MOB_ORGANIC|MOB_BUG
	gold_core_spawnable = FRIENDLY_SPAWN
	search_objects = 1 //have to find those plant trays!
	can_be_held = TRUE

	//Spaceborn beings don't get hurt by space
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	del_on_death = 1

	var/datum/reagent/beegent = null //hehe, beegent
	var/obj/structure/beebox/beehome = null
	var/idle = 0
	var/isqueen = FALSE
	var/icon_base = "bee"
	var/static/beehometypecache = typecacheof(/obj/structure/beebox)
	var/static/hydroponicstypecache = typecacheof(/obj/machinery/hydroponics)

/mob/living/simple_animal/hostile/poison/bees/Initialize()
	. = ..()
	ADD_TRAIT(src, TRAIT_SPACEWALK, INNATE_TRAIT)
	generate_bee_visuals()
	AddElement(/datum/element/simple_flying)
	AddComponent(/datum/component/swarming)

/mob/living/simple_animal/hostile/poison/bees/mob_pickup(mob/living/L)
	var/obj/item/clothing/head/mob_holder/destructible/holder = new(get_turf(src), src, held_state, head_icon, held_lh, held_rh, worn_slot_flags)
	var/list/reee = list(/datum/reagent/consumable/nutriment/vitamin = 5)
	if(beegent)
		reee[beegent.type] = 5
	holder.AddComponent(/datum/component/edible, reee, null, RAW | MEAT | GROSS, 10, 0, list("bee"), null, 10)
	L.visible_message(span_warning("[L] scoops up [src]!"))
	L.put_in_hands(holder)

/mob/living/simple_animal/hostile/poison/bees/Destroy()
	if(beehome)
		beehome.bees -= src
		beehome = null
	beegent = null
	return ..()


/mob/living/simple_animal/hostile/poison/bees/death(gibbed)
	if(beehome)
		beehome.bees -= src
		beehome = null
	var/obj/item/trash/bee/bee_to_eat = new(loc)
	bee_to_eat.pixel_x = pixel_x
	bee_to_eat.pixel_y = pixel_y
	if(beegent)
		bee_to_eat.beegent = beegent
		bee_to_eat.reagents.add_reagent(beegent.type, 5)
	bee_to_eat.update_icon()
	beegent = null
	..()


/mob/living/simple_animal/hostile/poison/bees/examine(mob/user)
	. = ..()

	if(!beehome)
		. += "<hr><span class='warning'>This bee is homeless!</span>"

/mob/living/simple_animal/hostile/poison/bees/ListTargets() // Bee processing is expessive, so we override them finding targets here.
	if(!search_objects) //In case we want to have purely hostile bees
		return ..()
	else
		. = list() // The following code is only very slightly slower than just returning oview(vision_range, targets_from), but it saves us much more work down the line
		var/atom/target_from = GET_TARGETS_FROM(src)
		var/list/searched_for = oview(vision_range, target_from)
		for(var/obj/A in searched_for)
			. += A
		for(var/mob/A in searched_for)
			. += A

/mob/living/simple_animal/hostile/poison/bees/proc/generate_bee_visuals()
	cut_overlays()

	var/col = BEE_DEFAULT_COLOUR
	if(beegent?.color)
		col = beegent.color

	icon_state = "[icon_base]_base"
	add_overlay("[icon_base]_base")

	var/static/mutable_appearance/greyscale_overlay
	greyscale_overlay = greyscale_overlay || mutable_appearance('icons/mob/bees.dmi')
	greyscale_overlay.icon_state = "[icon_base]_grey"
	greyscale_overlay.color = col
	add_overlay(greyscale_overlay)

	add_overlay("[icon_base]_wings")


//We don't attack beekeepers/people dressed as bees//Todo: bee costume
/mob/living/simple_animal/hostile/poison/bees/CanAttack(atom/the_target)
	. = ..()
	if(!.)
		return FALSE
	if(isliving(the_target))
		var/mob/living/H = the_target
		return !H.bee_friendly()


/mob/living/simple_animal/hostile/poison/bees/Found(atom/A)
	if(isliving(A))
		var/mob/living/H = A
		return !H.bee_friendly()
	if(istype(A, /obj/machinery/hydroponics))
		var/obj/machinery/hydroponics/Hydro = A
		if(Hydro.myseed && !Hydro.dead && !Hydro.recent_bee_visit)
			wanted_objects |= hydroponicstypecache //so we only hunt them while they're alive/seeded/not visisted
			return TRUE
	return FALSE


/mob/living/simple_animal/hostile/poison/bees/AttackingTarget()
	//Pollinate
	if(istype(target, /obj/machinery/hydroponics))
		var/obj/machinery/hydroponics/Hydro = target
		pollinate(Hydro)
	else if(istype(target, /obj/structure/beebox))
		if(target == beehome)
			var/obj/structure/beebox/BB = target
			forceMove(BB)
			toggle_ai(AI_IDLE)
			target = null
			wanted_objects -= beehometypecache //so we don't attack beeboxes when not going home
		return //no don't attack the goddamm box
	else
		. = ..()
		if(. && beegent && isliving(target))
			var/mob/living/L = target
			if(L.reagents)
				beegent.expose_mob(L, INJECT)
				L.reagents.add_reagent(beegent.type, rand(1,5))

/mob/living/simple_animal/hostile/poison/bees/inject_poison(mob/living/L)
	if(beegent && istype(L) && L.reagents)
		beegent.expose_mob(L, INJECT)
		L.reagents.add_reagent(beegent.type, rand(1,5))

/mob/living/simple_animal/hostile/poison/bees/proc/assign_reagent(datum/reagent/R)
	if(istype(R))
		beegent = R
		name = "[initial(name)] ([R.name])"
		real_name = name
		poison_type = null
		generate_bee_visuals()


/mob/living/simple_animal/hostile/poison/bees/proc/pollinate(obj/machinery/hydroponics/Hydro)
	if(!istype(Hydro) || !Hydro.myseed || Hydro.dead || Hydro.recent_bee_visit)
		target = null
		return

	target = null //so we pick a new hydro tray next FindTarget(), instead of loving the same plant for eternity
	wanted_objects -= hydroponicstypecache //so we only hunt them while they're alive/seeded/not visisted
	Hydro.recent_bee_visit = TRUE
	addtimer(VARSET_CALLBACK(Hydro, recent_bee_visit, FALSE), BEE_TRAY_RECENT_VISIT)

	var/growth = health //Health also means how many bees are in the swarm, roughly.
	//better healthier plants!
	Hydro.adjustHealth(growth*0.5)
	if(prob(BEE_POLLINATE_PEST_CHANCE))
		Hydro.adjustPests(-10)
	if(prob(BEE_POLLINATE_YIELD_CHANCE))
		Hydro.myseed.adjust_yield(1)
		Hydro.yieldmod = 2
	if(prob(BEE_POLLINATE_POTENCY_CHANCE))
		Hydro.myseed.adjust_potency(1)

	if(beehome)
		beehome.bee_resources = min(beehome.bee_resources + growth, 100)


/mob/living/simple_animal/hostile/poison/bees/handle_automated_action()
	. = ..()
	if(!.)
		return

	if(!isqueen)
		if(loc == beehome)
			idle = min(100, ++idle)
			if(idle >= BEE_IDLE_ROAMING && prob(BEE_PROB_GOROAM))
				toggle_ai(AI_ON)
				forceMove(beehome.drop_location())
		else
			idle = max(0, --idle)
			if(idle <= BEE_IDLE_GOHOME && prob(BEE_PROB_GOHOME))
				if(!FindTarget())
					wanted_objects |= beehometypecache //so we don't attack beeboxes when not going home
					target = beehome
	if(!beehome) //add outselves to a beebox (of the same reagent) if we have no home
		for(var/obj/structure/beebox/BB in view(vision_range, src))
			if(reagent_incompatible(BB.queen_bee) || BB.bees.len >= BB.get_max_bees())
				continue
			BB.bees |= src
			beehome = BB
			break // End loop after the first compatible find.

/mob/living/simple_animal/hostile/poison/bees/will_escape_storage()
	return TRUE

/mob/living/simple_animal/hostile/poison/bees/toxin/Initialize()
	. = ..()
	var/datum/reagent/R = pick(typesof(/datum/reagent/toxin))
	assign_reagent(GLOB.chemical_reagents_list[R])

/mob/living/simple_animal/hostile/poison/bees/queen
	name = "queen bee"
	desc = "She's the queen of bees, BZZ BZZ!"
	icon_base = "queen"
	isqueen = TRUE


//the Queen doesn't leave the box on her own, and she CERTAINLY doesn't pollinate by herself
/mob/living/simple_animal/hostile/poison/bees/queen/Found(atom/A)
	return FALSE


//leave pollination for the peasent bees
/mob/living/simple_animal/hostile/poison/bees/queen/AttackingTarget()
	. = ..()
	if(. && beegent && isliving(target))
		var/mob/living/L = target
		beegent.expose_mob(L, TOUCH)
		L.reagents.add_reagent(beegent.type, rand(1,5))


//PEASENT BEES
/mob/living/simple_animal/hostile/poison/bees/queen/pollinate()
	return

/mob/living/simple_animal/hostile/poison/bees/queen/will_escape_storage()
	return FALSE

/mob/living/simple_animal/hostile/poison/bees/proc/reagent_incompatible(mob/living/simple_animal/hostile/poison/bees/B)
	if(!B)
		return FALSE
	if(B.beegent && beegent && B.beegent.type != beegent.type || B.beegent && !beegent || !B.beegent && beegent)
		return TRUE
	return FALSE


/obj/item/queen_bee
	name = "queen bee"
	desc = "She's the queen of bees, BZZ BZZ!"
	icon_state = "queen_item"
	inhand_icon_state = ""
	icon = 'icons/mob/bees.dmi'
	var/mob/living/simple_animal/hostile/poison/bees/queen/queen


/obj/item/queen_bee/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/reagent_containers/syringe))
		var/obj/item/reagent_containers/syringe/S = I
		if(S.reagents.has_reagent(/datum/reagent/royal_bee_jelly)) //checked twice, because I really don't want royal bee jelly to be duped
			if(S.reagents.has_reagent(/datum/reagent/royal_bee_jelly,5))
				S.reagents.remove_reagent(/datum/reagent/royal_bee_jelly, 5)
				var/obj/item/queen_bee/qb = new(user.drop_location())
				qb.queen = new(qb)
				if(queen?.beegent)
					qb.queen.assign_reagent(queen.beegent) //Bees use the global singleton instances of reagents, so we don't need to worry about one bee being deleted and her copies losing their reagents.
				user.put_in_active_hand(qb)
				user.visible_message(span_notice("[user] injects [src] with royal bee jelly, causing it to split into two bees, MORE BEES!") ,span_warning("You inject [src] with royal bee jelly, causing it to split into two bees, MORE BEES!"))
			else
				to_chat(user, span_warning("You don't have enough royal bee jelly to split a bee in two!"))
		else
			var/datum/reagent/R = GLOB.chemical_reagents_list[S.reagents.get_master_reagent_id()]
			if(R && S.reagents.has_reagent(R.type, 5))
				S.reagents.remove_reagent(R.type,5)
				queen.assign_reagent(R)
				user.visible_message(span_warning("[user] injects [src] genome with [R.name], mutating its DNA!") ,span_warning("You inject [src] genome with [R.name], mutating its DNA!"))
				name = queen.name
			else
				to_chat(user, span_warning("You don't have enough units of that chemical to modify the bee's DNA!"))
	..()


/obj/item/queen_bee/bought/Initialize()
	. = ..()
	queen = new(src)


/obj/item/queen_bee/Destroy()
	QDEL_NULL(queen)
	return ..()

/mob/living/simple_animal/hostile/poison/bees/consider_wakeup()
	if (beehome && loc == beehome) // If bees are chilling in their nest, they're not actively looking for targets
		idle = min(100, ++idle)
		if(idle >= BEE_IDLE_ROAMING && prob(BEE_PROB_GOROAM))
			toggle_ai(AI_ON)
			forceMove(beehome.drop_location())
	else
		..()

/mob/living/simple_animal/hostile/poison/bees/short
	desc = "These bees seem unstable and won't survive for long."

/mob/living/simple_animal/hostile/poison/bees/short/Initialize(mapload, timetolive=50 SECONDS)
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(death)), timetolive)

/obj/item/trash/bee
	name = "bee"
	desc = "No wonder the bees are dying out, you monster."
	icon = 'icons/mob/bees.dmi'
	icon_state = "bee_item"
	var/datum/reagent/beegent

/obj/item/trash/bee/Initialize()
	. = ..()
	AddComponent(/datum/component/edible, list(/datum/reagent/consumable/nutriment/vitamin = 5), null, RAW | MEAT | GROSS, 10, 0, list("bee"), null, 10)

/obj/item/trash/bee/update_icon()
	. = ..()
	cut_overlays()
	var/mutable_appearance/body_overlay = mutable_appearance(icon = icon, icon_state = "bee_item_overlay")
	body_overlay.color = beegent ? beegent.color : BEE_DEFAULT_COLOUR
	add_overlay(body_overlay)

