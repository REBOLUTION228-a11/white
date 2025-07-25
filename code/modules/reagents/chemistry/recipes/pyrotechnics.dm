/datum/chemical_reaction/reagent_explosion
	var/strengthdiv = 10
	var/modifier = 0
	reaction_flags = REACTION_INSTANT
	reaction_tags = REACTION_TAG_EXPLOSIVE | REACTION_TAG_MODERATE | REACTION_TAG_DANGEROUS
	required_temp = 0 //Prevent impromptu RPGs

/datum/chemical_reaction/reagent_explosion/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	explode(holder, created_volume)

/datum/chemical_reaction/reagent_explosion/proc/explode(datum/reagents/holder, created_volume)
	var/power = modifier + round(created_volume/strengthdiv, 1)
	if(power > 0)
		var/turf/T = get_turf(holder.my_atom)
		var/inside_msg
		if(ismob(holder.my_atom))
			var/mob/M = holder.my_atom
			inside_msg = " inside [ADMIN_LOOKUPFLW(M)]"
		var/lastkey = holder.my_atom?.fingerprintslast //This can runtime (null.fingerprintslast) - due to plumbing?
		var/touch_msg = "N/A"
		if(lastkey)
			var/mob/toucher = get_mob_by_key(lastkey)
			touch_msg = "[ADMIN_LOOKUPFLW(toucher)]"
		if(!istype(holder.my_atom, /obj/machinery/plumbing)) //excludes standard plumbing equipment from spamming admins with this shit
			message_admins("Reagent explosion reaction occurred at [ADMIN_VERBOSEJMP(T)][inside_msg]. Last Fingerprint: [touch_msg].")
		log_game("Reagent explosion reaction occurred at [AREACOORD(T)]. Last Fingerprint: [lastkey ? lastkey : "N/A"]." )
		var/datum/effect_system/reagents_explosion/e = new()
		e.set_up(power , T, 0, 0)
		e.start()
	holder.clear_reagents()

/datum/chemical_reaction/reagent_explosion/nitroglycerin
	results = list(/datum/reagent/nitroglycerin = 2)
	required_reagents = list(/datum/reagent/glycerol = 1, /datum/reagent/toxin/acid/nitracid = 1, /datum/reagent/toxin/acid = 1)
	strengthdiv = 2

/datum/chemical_reaction/reagent_explosion/nitroglycerin/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)

	if(holder.has_reagent(/datum/reagent/exotic_stabilizer,round(created_volume / 25, CHEMICAL_QUANTISATION_LEVEL)))
		return
	holder.remove_reagent(/datum/reagent/nitroglycerin, created_volume*2)
	..()

/datum/chemical_reaction/reagent_explosion/nitroglycerin_explosion
	required_reagents = list(/datum/reagent/nitroglycerin = 1)
	required_temp = 474
	strengthdiv = 2

/datum/chemical_reaction/reagent_explosion/rdx
	results = list(/datum/reagent/rdx= 2)
	required_reagents = list(/datum/reagent/phenol = 2, /datum/reagent/toxin/acid/nitracid = 1, /datum/reagent/acetone_oxide = 1 )
	required_catalysts = list(/datum/reagent/gold) //royal explosive
	required_temp = 404
	strengthdiv = 8

/datum/chemical_reaction/reagent_explosion/rdx/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	if(holder.has_reagent(/datum/reagent/stabilizing_agent))
		return
	holder.remove_reagent(/datum/reagent/rdx, created_volume*2)
	..()

/datum/chemical_reaction/reagent_explosion/rdx_explosion
	required_reagents = list(/datum/reagent/rdx = 1)
	required_temp = 474
	strengthdiv = 7
	modifier = 2

/datum/chemical_reaction/reagent_explosion/rdx_explosion2 //makes rdx unique , on its own it is a good bomb, but when combined with liquid electricity it becomes truly destructive
	required_reagents = list(/datum/reagent/rdx = 1 , /datum/reagent/consumable/liquidelectricity = 1)
	strengthdiv = 3.5 //actually a decrease of 1 becaused of how explosions are calculated. This is due to the fact we require 2 reagents
	modifier = 4

/datum/chemical_reaction/reagent_explosion/rdx_explosion2/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/fire_range = round(created_volume/30)
	var/turf/T = get_turf(holder.my_atom)
	for(var/turf/turf in range(fire_range,T))
		new /obj/effect/hotspot(turf)
	holder.chem_temp = 500
	..()

/datum/chemical_reaction/reagent_explosion/rdx_explosion3
	required_reagents = list(/datum/reagent/rdx = 1 , /datum/reagent/teslium = 1)
	strengthdiv = 3.5 //actually a decrease of 1 becaused of how explosions are calculated. This is due to the fact we require 2 reagents
	modifier = 6


/datum/chemical_reaction/reagent_explosion/rdx_explosion3/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/fire_range = round(created_volume/20)
	var/turf/T = get_turf(holder.my_atom)
	for(var/turf/turf in range(fire_range,T))
		new /obj/effect/hotspot(turf)
	holder.chem_temp = 750
	..()

/datum/chemical_reaction/reagent_explosion/tatp
	results = list(/datum/reagent/tatp= 1)
	required_reagents = list(/datum/reagent/acetone_oxide = 1, /datum/reagent/toxin/acid/nitracid = 1, /datum/reagent/pentaerythritol = 1 )
	required_temp = 450
	strengthdiv = 3

/datum/chemical_reaction/reagent_explosion/tatp/update_info()
	required_temp = 450 + rand(-49,49)  //this gets loaded only on round start

/datum/chemical_reaction/reagent_explosion/tatp/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	if(holder.has_reagent(/datum/reagent/exotic_stabilizer,round(created_volume / 50, CHEMICAL_QUANTISATION_LEVEL))) // we like exotic stabilizer
		return
	holder.remove_reagent(/datum/reagent/tatp, created_volume)
	..()

/datum/chemical_reaction/reagent_explosion/tatp_explosion
	required_reagents = list(/datum/reagent/tatp = 1)
	required_temp = 550 // this makes making tatp before pyro nades, and extreme pain in the ass to make
	strengthdiv = 3

/datum/chemical_reaction/reagent_explosion/tatp_explosion/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/strengthdiv_adjust = created_volume / ( 2100 / initial(strengthdiv))
	strengthdiv = max(initial(strengthdiv) - strengthdiv_adjust + 1.5 ,1.5) //Slightly better than nitroglycerin
	. = ..()
	return

/datum/chemical_reaction/reagent_explosion/tatp_explosion/update_info()
	required_temp = 550 + rand(-49,49)

/datum/chemical_reaction/reagent_explosion/penthrite_explosion_epinephrine
	required_reagents = list(/datum/reagent/medicine/c2/penthrite = 1, /datum/reagent/medicine/epinephrine = 1)
	strengthdiv = 5

/datum/chemical_reaction/reagent_explosion/penthrite_explosion_atropine
	required_reagents = list(/datum/reagent/medicine/c2/penthrite = 1, /datum/reagent/medicine/atropine = 1)
	strengthdiv = 5
	modifier = 5

/datum/chemical_reaction/reagent_explosion/potassium_explosion
	required_reagents = list(/datum/reagent/water = 1, /datum/reagent/potassium = 1)
	strengthdiv = 20

/datum/chemical_reaction/reagent_explosion/holyboom
	required_reagents = list(/datum/reagent/water/holywater = 1, /datum/reagent/potassium = 1)
	strengthdiv = 20

/datum/chemical_reaction/reagent_explosion/holyboom/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	if(created_volume >= 150)
		strengthdiv = 8
		///turf where to play sound
		var/turf/T = get_turf(holder.my_atom)
		///special size for anti cult effect
		var/effective_size = round(created_volume/48)
		playsound(T, 'sound/effects/pray.ogg', 80, FALSE, effective_size)
		for(var/mob/living/simple_animal/revenant/R in get_hearers_in_view(7,T))
			var/deity
			if(GLOB.deity)
				deity = GLOB.deity
			else
				deity = "Christ"
			to_chat(R, span_userdanger("Сила [deity] заставляет меня!"))
			R.stun(20)
			R.reveal(100)
			R.adjustHealth(50)
		for(var/mob/living/carbon/C in get_hearers_in_view(effective_size,T))
			if(iscultist(C))
				to_chat(C, span_userdanger("Божественный взрыв опаляет меня!"))
				C.Paralyze(40)
				C.adjust_fire_stacks(5)
				C.IgniteMob()
	..()

/datum/chemical_reaction/gunpowder
	results = list(/datum/reagent/gunpowder = 3)
	required_reagents = list(/datum/reagent/saltpetre = 1, /datum/reagent/medicine/c2/multiver = 1, /datum/reagent/sulfur = 1)
	reaction_tags = REACTION_TAG_EASY | REACTION_TAG_EXPLOSIVE

/datum/chemical_reaction/reagent_explosion/gunpowder_explosion
	required_reagents = list(/datum/reagent/gunpowder = 1)
	required_temp = 474
	strengthdiv = 10
	modifier = 5
	mix_message = span_boldannounce("Искры начинают кружить вокруг пороха!")

/datum/chemical_reaction/reagent_explosion/gunpowder_explosion/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	addtimer(CALLBACK(src, PROC_REF(explode), holder, created_volume), rand(5,10) SECONDS)

/datum/chemical_reaction/thermite
	results = list(/datum/reagent/thermite = 3)
	required_reagents = list(/datum/reagent/aluminium = 1, /datum/reagent/iron = 1, /datum/reagent/oxygen = 1)
	reaction_tags = REACTION_TAG_EASY | REACTION_TAG_UNIQUE | REACTION_TAG_OTHER

/datum/chemical_reaction/emp_pulse
	required_reagents = list(/datum/reagent/uranium = 1, /datum/reagent/iron = 1) // Yes, laugh, it's the best recipe I could think of that makes a little bit of sense
	reaction_tags = REACTION_TAG_EASY | REACTION_TAG_EXPLOSIVE | REACTION_TAG_DANGEROUS

/datum/chemical_reaction/emp_pulse/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/location = get_turf(holder.my_atom)
	// 100 created volume = 4 heavy range & 7 light range. A few tiles smaller than traitor EMP grandes.
	// 200 created volume = 8 heavy range & 14 light range. 4 tiles larger than traitor EMP grenades.
	empulse(location, round(created_volume / 12), round(created_volume / 7), 1)
	holder.clear_reagents()


/datum/chemical_reaction/beesplosion
	required_reagents = list(/datum/reagent/consumable/honey = 1, /datum/reagent/medicine/strange_reagent = 1, /datum/reagent/uranium/radium = 1)
	reaction_tags = REACTION_TAG_EASY | REACTION_TAG_EXPLOSIVE | REACTION_TAG_DANGEROUS

/datum/chemical_reaction/beesplosion/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/location = holder.my_atom.drop_location()
	if(created_volume < 5)
		playsound(location,'sound/effects/sparks1.ogg', 100, TRUE)
	else
		playsound(location,'sound/creatures/bee.ogg', 100, TRUE)
		var/list/beeagents = list()
		for(var/R in holder.reagent_list)
			if(required_reagents[R])
				continue
			beeagents += R
		var/bee_amount = round(created_volume * 0.2)
		for(var/i in 1 to bee_amount)
			var/mob/living/simple_animal/hostile/poison/bees/short/new_bee = new(location)
			if(LAZYLEN(beeagents))
				new_bee.assign_reagent(pick(beeagents))


/datum/chemical_reaction/stabilizing_agent
	results = list(/datum/reagent/stabilizing_agent = 3)
	required_reagents = list(/datum/reagent/iron = 1, /datum/reagent/oxygen = 1, /datum/reagent/hydrogen = 1)
	reaction_tags = REACTION_TAG_EASY | REACTION_TAG_EXPLOSIVE | REACTION_TAG_CHEMICAL | REACTION_TAG_PLANT

/datum/chemical_reaction/clf3
	results = list(/datum/reagent/clf3 = 4)
	required_reagents = list(/datum/reagent/chlorine = 1, /datum/reagent/fluorine = 3)
	required_temp = 424
	overheat_temp = 1050
	reaction_tags = REACTION_TAG_EASY | REACTION_TAG_CHEMICAL | REACTION_TAG_DANGEROUS | REACTION_TAG_BURN

/datum/chemical_reaction/clf3/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/turf/T = get_turf(holder.my_atom)
	for(var/turf/turf in range(1,T))
		new /obj/effect/hotspot(turf)
	holder.chem_temp = 1000 // hot as shit

/datum/chemical_reaction/reagent_explosion/methsplosion
	required_temp = 380 //slightly above the meth mix time.
	required_reagents = list(/datum/reagent/drug/methamphetamine = 1)
	strengthdiv = 12
	modifier = 5
	mob_react = FALSE

/datum/chemical_reaction/reagent_explosion/methsplosion/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/turf/T = get_turf(holder.my_atom)
	for(var/turf/turf in range(1,T))
		new /obj/effect/hotspot(turf)
	holder.chem_temp = 1000 // hot as shit
	..()

/datum/chemical_reaction/reagent_explosion/methsplosion/methboom2
	required_reagents = list(/datum/reagent/diethylamine = 1, /datum/reagent/iodine = 1, /datum/reagent/phosphorus = 1, /datum/reagent/hydrogen = 1) //diethylamine is often left over from mixing the ephedrine.
	required_temp = 300 //room temperature, chilling it even a little will prevent the explosion

/datum/chemical_reaction/sorium
	results = list(/datum/reagent/sorium = 4)
	required_reagents = list(/datum/reagent/mercury = 1, /datum/reagent/oxygen = 1, /datum/reagent/nitrogen = 1, /datum/reagent/carbon = 1)
	reaction_tags = REACTION_TAG_EASY | REACTION_TAG_EXPLOSIVE | REACTION_TAG_DANGEROUS

/datum/chemical_reaction/sorium/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	if(holder.has_reagent(/datum/reagent/stabilizing_agent))
		return
	holder.remove_reagent(/datum/reagent/sorium, created_volume*4)
	var/turf/T = get_turf(holder.my_atom)
	var/range = clamp(sqrt(created_volume*4), 1, 6)
	goonchem_vortex(T, 1, range)

/datum/chemical_reaction/sorium_vortex
	required_reagents = list(/datum/reagent/sorium = 1)
	required_temp = 474
	reaction_tags = REACTION_TAG_EASY | REACTION_TAG_EXPLOSIVE | REACTION_TAG_DANGEROUS

/datum/chemical_reaction/sorium_vortex/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/turf/T = get_turf(holder.my_atom)
	var/range = clamp(sqrt(created_volume), 1, 6)
	goonchem_vortex(T, 1, range)

/datum/chemical_reaction/liquid_dark_matter
	results = list(/datum/reagent/liquid_dark_matter = 3)
	required_reagents = list(/datum/reagent/stable_plasma = 1, /datum/reagent/uranium/radium = 1, /datum/reagent/carbon = 1)
	reaction_tags = REACTION_TAG_EASY | REACTION_TAG_EXPLOSIVE | REACTION_TAG_DANGEROUS

/datum/chemical_reaction/liquid_dark_matter/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	if(holder.has_reagent(/datum/reagent/stabilizing_agent))
		return
	holder.remove_reagent(/datum/reagent/liquid_dark_matter, created_volume*3)
	var/turf/T = get_turf(holder.my_atom)
	var/range = clamp(sqrt(created_volume*3), 1, 6)
	goonchem_vortex(T, 0, range)

/datum/chemical_reaction/ldm_vortex
	required_reagents = list(/datum/reagent/liquid_dark_matter = 1)
	required_temp = 474
	reaction_tags = REACTION_TAG_EASY | REACTION_TAG_EXPLOSIVE | REACTION_TAG_DANGEROUS

/datum/chemical_reaction/ldm_vortex/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/turf/T = get_turf(holder.my_atom)
	var/range = clamp(sqrt(created_volume/2), 1, 6)
	goonchem_vortex(T, 0, range)

/datum/chemical_reaction/flash_powder
	results = list(/datum/reagent/flash_powder = 3)
	required_reagents = list(/datum/reagent/aluminium = 1, /datum/reagent/potassium = 1, /datum/reagent/sulfur = 1 )
	reaction_flags = REACTION_INSTANT
	reaction_tags = REACTION_TAG_EASY | REACTION_TAG_EXPLOSIVE | REACTION_TAG_DANGEROUS

/datum/chemical_reaction/flash_powder/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	if(holder.has_reagent(/datum/reagent/stabilizing_agent))
		return
	var/location = get_turf(holder.my_atom)
	do_sparks(2, TRUE, location)
	var/range = created_volume/3
	if(isatom(holder.my_atom))
		var/atom/A = holder.my_atom
		A.flash_lighting_fx(_range = (range + 2))
	for(var/mob/living/C in get_hearers_in_view(range, location))
		if(C.flash_act(affect_silicon = TRUE))
			if(get_dist(C, location) < 4)
				C.Paralyze(60)
			else
				C.Stun(100)
	holder.remove_reagent(/datum/reagent/flash_powder, created_volume*3)

/datum/chemical_reaction/flash_powder_flash
	required_reagents = list(/datum/reagent/flash_powder = 1)
	required_temp = 374
	reaction_tags = REACTION_TAG_EASY | REACTION_TAG_EXPLOSIVE | REACTION_TAG_DANGEROUS

/datum/chemical_reaction/flash_powder_flash/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/location = get_turf(holder.my_atom)
	do_sparks(2, TRUE, location)
	var/range = created_volume/10
	if(isatom(holder.my_atom))
		var/atom/A = holder.my_atom
		A.flash_lighting_fx(_range = (range + 2))
	for(var/mob/living/C in get_hearers_in_view(range, location))
		if(C.flash_act(affect_silicon = TRUE))
			if(get_dist(C, location) < 4)
				C.Paralyze(60)
			else
				C.Stun(100)

/datum/chemical_reaction/smoke_powder
	results = list(/datum/reagent/smoke_powder = 3)
	required_reagents = list(/datum/reagent/potassium = 1, /datum/reagent/consumable/sugar = 1, /datum/reagent/phosphorus = 1)
	reaction_flags = REACTION_INSTANT
	reaction_tags = REACTION_TAG_EASY | REACTION_TAG_EXPLOSIVE | REACTION_TAG_DANGEROUS

/datum/chemical_reaction/smoke_powder/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	if(holder.has_reagent(/datum/reagent/stabilizing_agent))
		return
	holder.remove_reagent(/datum/reagent/smoke_powder, created_volume*3)
	var/smoke_radius = round(sqrt(created_volume * 1.5), 1)
	var/location = get_turf(holder.my_atom)
	var/datum/effect_system/smoke_spread/chem/S = new
	S.attach(location)
	playsound(location, 'sound/effects/smoke.ogg', 50, TRUE, -3)
	if(S)
		S.set_up(holder, smoke_radius, location, 0)
		S.start()
	if(holder?.my_atom)
		holder.clear_reagents()

/datum/chemical_reaction/smoke_powder_smoke
	required_reagents = list(/datum/reagent/smoke_powder = 1)
	required_temp = 374
	mob_react = FALSE
	reaction_flags = REACTION_INSTANT
	reaction_tags = REACTION_TAG_EASY | REACTION_TAG_EXPLOSIVE | REACTION_TAG_DANGEROUS

/datum/chemical_reaction/smoke_powder_smoke/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/location = get_turf(holder.my_atom)
	var/smoke_radius = round(sqrt(created_volume / 2), 1)
	var/datum/effect_system/smoke_spread/chem/S = new
	S.attach(location)
	playsound(location, 'sound/effects/smoke.ogg', 50, TRUE, -3)
	if(S)
		S.set_up(holder, smoke_radius, location, 0)
		S.start()
	if(holder?.my_atom)
		holder.clear_reagents()

/datum/chemical_reaction/sonic_powder
	results = list(/datum/reagent/sonic_powder = 3)
	required_reagents = list(/datum/reagent/oxygen = 1, /datum/reagent/consumable/space_cola = 1, /datum/reagent/phosphorus = 1)
	reaction_tags = REACTION_TAG_EASY | REACTION_TAG_EXPLOSIVE | REACTION_TAG_DANGEROUS

/datum/chemical_reaction/sonic_powder/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	if(holder.has_reagent(/datum/reagent/stabilizing_agent))
		return
	holder.remove_reagent(/datum/reagent/sonic_powder, created_volume*3)
	var/location = get_turf(holder.my_atom)
	playsound(location, 'sound/effects/bang.ogg', 25, TRUE)
	for(var/mob/living/carbon/C in get_hearers_in_view(created_volume/3, location))
		C.soundbang_act(1, 100, rand(0, 5))

/datum/chemical_reaction/sonic_powder_deafen
	required_reagents = list(/datum/reagent/sonic_powder = 1)
	required_temp = 374
	reaction_tags = REACTION_TAG_EASY | REACTION_TAG_EXPLOSIVE | REACTION_TAG_DANGEROUS

/datum/chemical_reaction/sonic_powder_deafen/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/location = get_turf(holder.my_atom)
	playsound(location, 'sound/effects/bang.ogg', 25, TRUE)
	for(var/mob/living/carbon/C in get_hearers_in_view(created_volume/10, location))
		C.soundbang_act(1, 100, rand(0, 5))

/datum/chemical_reaction/phlogiston
	results = list(/datum/reagent/phlogiston = 3)
	required_reagents = list(/datum/reagent/phosphorus = 1, /datum/reagent/toxin/acid = 1, /datum/reagent/stable_plasma = 1)
	reaction_tags = REACTION_TAG_EASY | REACTION_TAG_EXPLOSIVE | REACTION_TAG_DANGEROUS

/datum/chemical_reaction/phlogiston/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	if(holder.has_reagent(/datum/reagent/stabilizing_agent))
		return
	var/turf/open/T = get_turf(holder.my_atom)
	if(istype(T))
		T.atmos_spawn_air("plasma=[created_volume];TEMP=1000")
	holder.clear_reagents()
	return

/datum/chemical_reaction/napalm
	results = list(/datum/reagent/napalm = 3)
	required_reagents = list(/datum/reagent/fuel/oil = 1, /datum/reagent/fuel = 1, /datum/reagent/consumable/ethanol = 1 )
	reaction_tags = REACTION_TAG_EASY | REACTION_TAG_EXPLOSIVE | REACTION_TAG_PLANT

#define CRYOSTYLANE_UNDERHEAT_TEMP 50
#define CRYOSTYLANE_IMPURE_TEMPERATURE_RANGE 200

/datum/chemical_reaction/cryostylane
	results = list(/datum/reagent/cryostylane = 3)
	required_reagents = list(/datum/reagent/consumable/ice = 1, /datum/reagent/stable_plasma = 1, /datum/reagent/nitrogen = 1)
	required_temp = -200
	optimal_temp = 300
	overheat_temp = NO_OVERHEAT //There is an overheat - 50 see reaction_step()
	optimal_ph_min = 4
	optimal_ph_max = 10
	determin_ph_range = 6
	temp_exponent_factor = 0.5
	ph_exponent_factor = 1
	thermic_constant = -7.5
	H_ion_release = 0
	rate_up_lim = 10
	purity_min = 0.2
	reaction_flags = REACTION_HEAT_ARBITARY
	reaction_tags = REACTION_TAG_EASY | REACTION_TAG_UNIQUE | REACTION_TAG_ORGAN

//Halve beaker temp on reaction
/datum/chemical_reaction/cryostylane/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/datum/reagent/oxygen = holder.has_reagent(/datum/reagent/oxygen) //If we have oxygen, bring in the old cooling effect
	if(oxygen)
		holder.chem_temp =  max(holder.chem_temp - (10 * oxygen.volume * 2),0)
		holder.remove_reagent(/datum/reagent/oxygen, oxygen.volume) // halves the temperature - tried to bring in some of the old effects at least!
	return

//purity != temp (above 50) - the colder you are the more impure it becomes
/datum/chemical_reaction/cryostylane/reaction_step(datum/reagents/holder, datum/equilibrium/reaction, delta_t, delta_ph, step_reaction_vol)
	. = ..()
	if(holder.chem_temp < CRYOSTYLANE_UNDERHEAT_TEMP)
		overheated(holder, reaction, step_reaction_vol)
	//Modify our purity by holder temperature
	var/step_temp = ((holder.chem_temp-CRYOSTYLANE_UNDERHEAT_TEMP)/CRYOSTYLANE_IMPURE_TEMPERATURE_RANGE)
	if(step_temp >= 1) //We're hotter than 300
		return
	reaction.delta_ph *= step_temp

/datum/chemical_reaction/cryostylane/reaction_finish(datum/reagents/holder, datum/equilibrium/reaction, react_vol)
	. = ..()
	if(holder.chem_temp < CRYOSTYLANE_UNDERHEAT_TEMP)
		overheated(holder, null, react_vol) //replace null with fix win 2.3 is merged

//Freezes the area around you!
/datum/chemical_reaction/cryostylane/overheated(datum/reagents/holder, datum/equilibrium/equilibrium, vol_added)
	var/datum/reagent/cryostylane/cryostylane = holder.has_reagent(/datum/reagent/cryostylane)
	if(!cryostylane)
		return ..()
	var/turf/local_turf = get_turf(holder.my_atom)
	playsound(local_turf, 'sound/magic/ethereal_exit.ogg', 50, 1)
	local_turf.visible_message("The reaction frosts over, releasing it's chilly contents!")
	freeze_radius(holder, null, holder.chem_temp*2, clamp(cryostylane.volume/30, 2, 6), 120 SECONDS, 2)
	clear_reactants(holder, 15)
	holder.chem_temp += 100

//Makes a snowman if you're too impure!
/datum/chemical_reaction/cryostylane/overly_impure(datum/reagents/holder, datum/equilibrium/equilibrium, vol_added)
	var/datum/reagent/cryostylane/cryostylane = holder.has_reagent(/datum/reagent/cryostylane)
	var/turf/local_turf = get_turf(holder.my_atom)
	playsound(local_turf, 'sound/magic/ethereal_exit.ogg', 50, 1)
	local_turf.visible_message("The reaction furiously freezes up as a snowman suddenly rises out of the [holder.my_atom.name]!")
	freeze_radius(holder, equilibrium, holder.chem_temp, clamp(cryostylane.volume/15, 3, 10), 180 SECONDS, 5)
	new /obj/structure/statue/snow/snowman(local_turf)
	clear_reactants(holder)
	clear_products(holder)

#undef CRYOSTYLANE_UNDERHEAT_TEMP
#undef CRYOSTYLANE_IMPURE_TEMPERATURE_RANGE

/datum/chemical_reaction/cryostylane_oxygen
	results = list(/datum/reagent/cryostylane = 1)
	required_reagents = list(/datum/reagent/cryostylane = 1, /datum/reagent/oxygen = 1)
	mob_react = FALSE
	is_cold_recipe = TRUE
	required_temp = 99999
	optimal_temp = 300
	overheat_temp = 0
	optimal_ph_min = 0
	optimal_ph_max = 14
	determin_ph_range = 0
	temp_exponent_factor = 1
	ph_exponent_factor = 1
	thermic_constant = -50 //This is the part that cools things down now
	H_ion_release = 0
	rate_up_lim = 4
	purity_min = 0.15
	reaction_flags = REACTION_HEAT_ARBITARY
	reaction_tags = REACTION_TAG_EASY | REACTION_TAG_UNIQUE

/datum/chemical_reaction/pyrosium_oxygen
	results = list(/datum/reagent/pyrosium = 1)
	required_reagents = list(/datum/reagent/pyrosium = 1, /datum/reagent/oxygen = 1)
	mob_react = FALSE
	reaction_flags = REACTION_INSTANT
	reaction_tags = REACTION_TAG_EASY | REACTION_TAG_UNIQUE

/datum/chemical_reaction/pyrosium_oxygen/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	holder.chem_temp += 10*created_volume

/datum/chemical_reaction/pyrosium
	results = list(/datum/reagent/pyrosium = 3)
	required_reagents = list(/datum/reagent/stable_plasma = 1, /datum/reagent/uranium/radium = 1, /datum/reagent/phosphorus = 1)
	required_temp = 0
	optimal_temp = 20
	overheat_temp = NO_OVERHEAT
	temp_exponent_factor = 10
	thermic_constant = 0
	reaction_tags = REACTION_TAG_EASY | REACTION_TAG_UNIQUE

/datum/chemical_reaction/pyrosium/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	holder.chem_temp = 20 // also cools the fuck down
	return

/datum/chemical_reaction/teslium
	results = list(/datum/reagent/teslium = 3)
	required_reagents = list(/datum/reagent/stable_plasma = 1, /datum/reagent/silver = 1, /datum/reagent/gunpowder = 1)
	mix_message = span_danger("Струйка искр исходит из смеси во время её слияния с мерцающей жидкостью.")
	required_temp = 400
	reaction_tags = REACTION_TAG_EASY | REACTION_TAG_EXPLOSIVE

/datum/chemical_reaction/energized_jelly
	results = list(/datum/reagent/teslium/energized_jelly = 2)
	required_reagents = list(/datum/reagent/toxin/slimejelly = 1, /datum/reagent/teslium = 1)
	mix_message = span_danger("Желе слайма начало мерцать.")
	reaction_tags = REACTION_TAG_EASY | REACTION_TAG_DANGEROUS | REACTION_TAG_HEALING | REACTION_TAG_OTHER

/datum/chemical_reaction/reagent_explosion/teslium_lightning
	required_reagents = list(/datum/reagent/teslium = 1, /datum/reagent/water = 1)
	strengthdiv = 100
	modifier = -100
	mix_message = span_boldannounce("Теслий начал искрить, когда электрическая дуга удалилась от него!")
	mix_sound = 'sound/machines/defib_zap.ogg'
	var/zap_flags = ZAP_MOB_DAMAGE | ZAP_OBJ_DAMAGE | ZAP_MOB_STUN
	reaction_tags = REACTION_TAG_EASY | REACTION_TAG_EXPLOSIVE | REACTION_TAG_DANGEROUS

/datum/chemical_reaction/reagent_explosion/teslium_lightning/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	var/T1 = created_volume * 20		//100 units : Zap 3 times, with powers 2000/5000/12000. Tesla revolvers have a power of 10000 for comparison.
	var/T2 = created_volume * 50
	var/T3 = created_volume * 120
	var/added_delay = 0.5 SECONDS
	if(created_volume >= 75)
		addtimer(CALLBACK(src, PROC_REF(zappy_zappy), holder, T1), added_delay)
		added_delay += 1.5 SECONDS
	if(created_volume >= 40)
		addtimer(CALLBACK(src, PROC_REF(zappy_zappy), holder, T2), added_delay)
		added_delay += 1.5 SECONDS
	if(created_volume >= 10) //10 units minimum for lightning, 40 units for secondary blast, 75 units for tertiary blast.
		addtimer(CALLBACK(src, PROC_REF(zappy_zappy), holder, T3), added_delay)
	addtimer(CALLBACK(src, PROC_REF(explode), holder, created_volume), added_delay)

/datum/chemical_reaction/reagent_explosion/teslium_lightning/proc/zappy_zappy(datum/reagents/holder, power)
	if(QDELETED(holder.my_atom))
		return
	tesla_zap(holder.my_atom, 7, power, zap_flags)
	playsound(holder.my_atom, 'sound/machines/defib_zap.ogg', 50, TRUE)

/datum/chemical_reaction/reagent_explosion/teslium_lightning/heat
	required_temp = 474
	required_reagents = list(/datum/reagent/teslium = 1)

/datum/chemical_reaction/reagent_explosion/nitrous_oxide
	required_reagents = list(/datum/reagent/nitrous_oxide = 1)
	strengthdiv = 9
	required_temp = 575
	modifier = 1

/datum/chemical_reaction/reagent_explosion/nitrous_oxide/on_reaction(datum/reagents/holder, datum/equilibrium/reaction, created_volume)
	holder.remove_reagent(/datum/reagent/sorium, created_volume*2)
	var/turf/turfie = get_turf(holder.my_atom)
	//generally half as strong as sorium.
	var/range = clamp(sqrt(created_volume*2), 1, 6)
	//This first throws people away and then it explodes
	goonchem_vortex(turfie, 1, range)
	turfie.atmos_spawn_air("o2=[created_volume/2];TEMP=[575]")
	turfie.atmos_spawn_air("n2=[created_volume/2];TEMP=[575]")
	return ..()

/datum/chemical_reaction/firefighting_foam
	results = list(/datum/reagent/firefighting_foam = 3)
	required_reagents = list(/datum/reagent/stabilizing_agent = 1,/datum/reagent/fluorosurfactant = 1,/datum/reagent/carbon = 1)
	required_temp = 200
	is_cold_recipe = 1
	optimal_temp = 50
	overheat_temp = 5
	thermic_constant= -1
	H_ion_release = -0.02
	reaction_tags = REACTION_TAG_EASY | REACTION_TAG_UNIQUE
