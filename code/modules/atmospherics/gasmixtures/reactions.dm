//All defines used in reactions are located in ..\__DEFINES\reactions.dm

/proc/init_gas_reactions()
	. = list()

	for(var/r in subtypesof(/datum/gas_reaction))
		var/datum/gas_reaction/reaction = r
		if(initial(reaction.exclude))
			continue
		reaction = new r
		. += reaction
	sortTim(., GLOBAL_PROC_REF(cmp_gas_reactions))

/proc/cmp_gas_reactions(list/datum/gas_reaction/a, list/datum/gas_reaction/b) // compares lists of reactions by the maximum priority contained within the list
	if (!length(a) || !length(b))
		return length(b) - length(a)
	var/maxa
	var/maxb
	for (var/datum/gas_reaction/R in a)
		if (R.priority > maxa)
			maxa = R.priority
	for (var/datum/gas_reaction/R in b)
		if (R.priority > maxb)
			maxb = R.priority
	return maxb - maxa

/datum/gas_reaction
	//regarding the requirements lists: the minimum or maximum requirements must be non-zero.
	//when in doubt, use MINIMUM_MOLE_COUNT.
	var/list/min_requirements
	var/list/max_requirements
	var/exclude = FALSE //do it this way to allow for addition/removal of reactions midmatch in the future
	var/priority = 100 //lower numbers are checked/react later than higher numbers. if two reactions have the same priority they may happen in either order
	var/name = "reaction"
	var/id = "r"

/datum/gas_reaction/New()
	init_reqs()

/datum/gas_reaction/proc/init_reqs()

/datum/gas_reaction/proc/react(datum/gas_mixture/air, atom/location)
	return NO_REACTION

/datum/gas_reaction/nobliumsupression
	priority = 1000 //ensure all non-HN reactions are lower than this number.
	name = "Hyper-Noblium Reaction Suppression"
	id = "nobstop"

/datum/gas_reaction/nobliumsupression/init_reqs()
	min_requirements = list(GAS_HYPERNOB = REACTION_OPPRESSION_THRESHOLD)

/datum/gas_reaction/nobliumsupression/react()
	return STOP_REACTIONS

//water vapor: puts out fires?
/datum/gas_reaction/water_vapor
	priority = 1
	name = "Water Vapor"
	id = "vapor"

/datum/gas_reaction/water_vapor/init_reqs()
	min_requirements = list(GAS_H2O = MOLES_GAS_VISIBLE)

/datum/gas_reaction/water_vapor/react(datum/gas_mixture/air, datum/holder)
	var/turf/open/location = isturf(holder) ? holder : null
	. = NO_REACTION
	if (air.return_temperature() <= WATER_VAPOR_FREEZE)
		if(location && location.freon_gas_act())
			. = REACTING
	else if(location && location.water_vapor_gas_act())
		air.adjust_moles(GAS_H2O, -MOLES_GAS_VISIBLE)
		. = REACTING

//tritium combustion: combustion of oxygen and tritium (treated as hydrocarbons). creates hotspots. exothermic
/datum/gas_reaction/nitrous_decomp
	priority = 0
	name = "Nitrous Oxide Decomposition"
	id = "nitrous_decomp"

/datum/gas_reaction/nitrous_decomp/init_reqs()
	min_requirements = list(
		"TEMP" = N2O_DECOMPOSITION_MIN_ENERGY,
		GAS_NITROUS = MINIMUM_MOLE_COUNT
	)

/datum/gas_reaction/nitrous_decomp/react(datum/gas_mixture/air, datum/holder)
	var/energy_released = 0
	var/old_heat_capacity = air.heat_capacity()
	var/temperature = air.return_temperature()
	var/burned_fuel = 0


	burned_fuel = max(0,0.00002*(temperature-(0.00001*(temperature**2))))*air.get_moles(GAS_NITROUS)
	air.set_moles(GAS_NITROUS, air.get_moles(GAS_NITROUS) - burned_fuel)

	if(burned_fuel)
		energy_released += (N2O_DECOMPOSITION_ENERGY_RELEASED * burned_fuel)

		air.set_moles(GAS_O2, air.get_moles(GAS_O2) + burned_fuel/2)
		air.set_moles(GAS_N2, air.get_moles(GAS_N2) + burned_fuel)

		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.set_temperature((temperature*old_heat_capacity + energy_released)/new_heat_capacity)
		return REACTING
	return NO_REACTION

//tritium combustion: combustion of oxygen and tritium (treated as hydrocarbons). creates hotspots. exothermic
/datum/gas_reaction/tritfire
	priority = -2 //fire should ALWAYS be last, but tritium fires happen before plasma fires
	name = "Tritium Combustion"
	id = "tritfire"

/datum/gas_reaction/tritfire/init_reqs()
	min_requirements = list(
		"TEMP" = FIRE_MINIMUM_TEMPERATURE_TO_EXIST,
		GAS_TRITIUM = MINIMUM_MOLE_COUNT,
		GAS_O2 = MINIMUM_MOLE_COUNT
	)

/datum/gas_reaction/tritfire/react(datum/gas_mixture/air, datum/holder)
	var/energy_released = 0
	var/old_heat_capacity = air.heat_capacity()
	var/temperature = air.return_temperature()
	var/list/cached_results = air.reaction_results
	cached_results["fire"] = 0
	var/turf/open/location = isturf(holder) ? holder : null
	var/burned_fuel = 0
	var/initial_trit = air.get_moles(GAS_TRITIUM)// Yogs
	if(air.get_moles(GAS_O2) < initial_trit || MINIMUM_TRIT_OXYBURN_ENERGY > (temperature * old_heat_capacity))// Yogs -- Maybe a tiny performance boost? I'unno
		burned_fuel = air.get_moles(GAS_O2)/TRITIUM_BURN_OXY_FACTOR
		if(burned_fuel > initial_trit) burned_fuel = initial_trit //Yogs -- prevents negative moles of Tritium
		air.adjust_moles(GAS_TRITIUM, -burned_fuel)
	else
		burned_fuel = initial_trit // Yogs -- Conservation of Mass fix
		air.set_moles(GAS_TRITIUM, air.get_moles(GAS_TRITIUM) * (1 - 1/TRITIUM_BURN_TRIT_FACTOR)) // Yogs -- Maybe a tiny performance boost? I'unno
		air.adjust_moles(GAS_O2, -air.get_moles(GAS_TRITIUM))
		energy_released += (FIRE_HYDROGEN_ENERGY_RELEASED * burned_fuel * (TRITIUM_BURN_TRIT_FACTOR - 1)) // Yogs -- Fixes low-energy tritium fires

	if(burned_fuel)
		energy_released += (FIRE_HYDROGEN_ENERGY_RELEASED * burned_fuel)
		if(location && prob(10) && burned_fuel > TRITIUM_MINIMUM_RADIATION_ENERGY) //woah there let's not crash the server
			radiation_pulse(location, energy_released/TRITIUM_BURN_RADIOACTIVITY_FACTOR)

		//oxygen+more-or-less hydrogen=H2O
		air.adjust_moles(GAS_H2O, burned_fuel )// Yogs -- Conservation of Mass

		cached_results["fire"] += burned_fuel

	if(energy_released > 0)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.set_temperature((temperature*old_heat_capacity + energy_released)/new_heat_capacity)

	//let the floor know a fire is happening
	if(istype(location))
		temperature = air.return_temperature()
		if(temperature > FIRE_MINIMUM_TEMPERATURE_TO_EXIST)
			location.hotspot_expose(temperature, CELL_VOLUME)
			for(var/I in location)
				var/atom/movable/item = I
				item.temperature_expose(air, temperature, CELL_VOLUME)
			location.temperature_expose(air, temperature, CELL_VOLUME)

	return cached_results["fire"] ? REACTING : NO_REACTION

//plasma combustion: combustion of oxygen and plasma (treated as hydrocarbons). creates hotspots. exothermic
/datum/gas_reaction/plasmafire
	priority = -4 //fire should ALWAYS be last, but plasma fires happen after tritium fires
	name = "Plasma Combustion"
	id = "plasmafire"

/datum/gas_reaction/plasmafire/init_reqs()
	min_requirements = list(
		"TEMP" = FIRE_MINIMUM_TEMPERATURE_TO_EXIST,
		GAS_PLASMA = MINIMUM_MOLE_COUNT,
		GAS_O2 = MINIMUM_MOLE_COUNT
	)

/datum/gas_reaction/plasmafire/react(datum/gas_mixture/air, datum/holder)
	var/energy_released = 0
	var/old_heat_capacity = air.heat_capacity()
	var/temperature = air.return_temperature()
	var/list/cached_results = air.reaction_results
	cached_results["fire"] = 0
	var/turf/open/location = isturf(holder) ? holder : null

	//Handle plasma burning
	var/plasma_burn_rate = 0
	var/oxygen_burn_rate = 0
	//more plasma released at higher temperatures
	var/temperature_scale = 0
	//to make tritium
	var/super_saturation = FALSE

	if(temperature > PLASMA_UPPER_TEMPERATURE)
		temperature_scale = 1
	else
		temperature_scale = (temperature-PLASMA_MINIMUM_BURN_TEMPERATURE)/(PLASMA_UPPER_TEMPERATURE-PLASMA_MINIMUM_BURN_TEMPERATURE)
	if(temperature_scale > 0)
		oxygen_burn_rate = OXYGEN_BURN_RATIO_BASE - temperature_scale
		if(air.get_moles(GAS_O2) / air.get_moles(GAS_PLASMA) > SUPER_SATURATION_THRESHOLD) //supersaturation. Form Tritium.
			super_saturation = TRUE
		if(air.get_moles(GAS_O2) > air.get_moles(GAS_PLASMA)*PLASMA_OXYGEN_FULLBURN)
			plasma_burn_rate = (air.get_moles(GAS_PLASMA)*temperature_scale)/PLASMA_BURN_RATE_DELTA
		else
			plasma_burn_rate = (temperature_scale*(air.get_moles(GAS_O2)/PLASMA_OXYGEN_FULLBURN))/PLASMA_BURN_RATE_DELTA

		if(plasma_burn_rate > MINIMUM_HEAT_CAPACITY)
			plasma_burn_rate = min(plasma_burn_rate,air.get_moles(GAS_PLASMA),air.get_moles(GAS_O2)/oxygen_burn_rate) //Ensures matter is conserved properly
			air.set_moles(GAS_PLASMA, QUANTIZE(air.get_moles(GAS_PLASMA) - plasma_burn_rate))
			air.set_moles(GAS_O2, QUANTIZE(air.get_moles(GAS_O2) - (plasma_burn_rate * oxygen_burn_rate)))
			if (super_saturation)
				air.adjust_moles(GAS_TRITIUM, plasma_burn_rate)
			else
				air.adjust_moles(GAS_CO2, plasma_burn_rate)

			energy_released += FIRE_PLASMA_ENERGY_RELEASED * (plasma_burn_rate)

			cached_results["fire"] += (plasma_burn_rate)*(1+oxygen_burn_rate)

	if(energy_released > 0)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.set_temperature((temperature*old_heat_capacity + energy_released)/new_heat_capacity)

	//let the floor know a fire is happening
	if(istype(location))
		temperature = air.return_temperature()
		if(temperature > FIRE_MINIMUM_TEMPERATURE_TO_EXIST)
			location.hotspot_expose(temperature, CELL_VOLUME)
			for(var/I in location)
				var/atom/movable/item = I
				item.temperature_expose(air, temperature, CELL_VOLUME)
			location.temperature_expose(air, temperature, CELL_VOLUME)

	return cached_results["fire"] ? REACTING : NO_REACTION

//fusion: a terrible idea that was fun but broken. Now reworked to be less broken and more interesting. Again (and again, and again). Again!
//Fusion Rework Counter: Please increment this if you make a major overhaul to this system again.
//6 reworks and 1 removal

/datum/gas_reaction/fusion
	exclude = FALSE
	priority = 2
	name = "Plasmic Fusion"
	id = "fusion"

/datum/gas_reaction/fusion/init_reqs()
	min_requirements = list(
		"TEMP" = FUSION_TEMPERATURE_THRESHOLD,
		GAS_TRITIUM = FUSION_TRITIUM_MOLES_USED,
		GAS_PLASMA = FUSION_MOLE_THRESHOLD,
		GAS_CO2 = FUSION_MOLE_THRESHOLD)

/datum/gas_reaction/fusion/react(datum/gas_mixture/air, datum/holder)
	var/turf/open/location
	if (istype(holder,/datum/pipeline)) //Find the tile the reaction is occuring on, or a random part of the network if it's a pipenet.
		var/datum/pipeline/fusion_pipenet = holder
		location = get_turf(pick(fusion_pipenet.members))
	else
		location = get_turf(holder)
	if(!air.analyzer_results)
		air.analyzer_results = new
	var/list/cached_scan_results = air.analyzer_results
	var/thermal_energy = air.thermal_energy()
	var/reaction_energy = 0 //Reaction energy can be negative or positive, for both exothermic and endothermic reactions.
	var/initial_plasma = air.get_moles(GAS_PLASMA)
	var/initial_carbon = air.get_moles(GAS_CO2)
	var/scale_factor = max(air.return_volume() / FUSION_SCALE_DIVISOR, FUSION_MINIMAL_SCALE)
	var/temperature_scale = log(10, air.return_temperature())
	//The size of the phase space hypertorus
	var/toroidal_size = 	TOROID_CALCULATED_THRESHOLD \
							+ (temperature_scale <= FUSION_BASE_TEMPSCALE ? \
							(temperature_scale-FUSION_BASE_TEMPSCALE) / FUSION_BUFFER_DIVISOR \
							: 4 ** (temperature_scale-FUSION_BASE_TEMPSCALE) / FUSION_SLOPE_DIVISOR)
	var/gas_power = 0
	for (var/gas_id in air.get_gases())
		gas_power += (GLOB.gas_data.fusion_powers[gas_id]*air.get_moles(gas_id))
	var/instability = MODULUS((gas_power*INSTABILITY_GAS_POWER_FACTOR),toroidal_size) //Instability effects how chaotic the behavior of the reaction is
	cached_scan_results[id] = instability//used for analyzer feedback

	var/plasma = (initial_plasma-FUSION_MOLE_THRESHOLD)/(scale_factor) //We have to scale the amounts of carbon and plasma down a significant amount in order to show the chaotic dynamics we want
	var/carbon = (initial_carbon-FUSION_MOLE_THRESHOLD)/(scale_factor) //We also subtract out the threshold amount to make it harder for fusion to burn itself out.

	//The reaction is a specific form of the Kicked Rotator system, which displays chaotic behavior and can be used to model particle interactions.
	plasma = MODULUS(plasma - (instability*sin(TODEGREES(carbon))), toroidal_size)
	carbon = MODULUS(carbon - plasma, toroidal_size)

	air.set_moles(GAS_PLASMA, plasma*scale_factor + FUSION_MOLE_THRESHOLD )//Scales the gases back up
	air.set_moles(GAS_CO2, carbon*scale_factor + FUSION_MOLE_THRESHOLD)
	var/delta_plasma = min(initial_plasma - air.get_moles(GAS_PLASMA), toroidal_size * scale_factor * 1.5)

	//Energy is gained or lost corresponding to the creation or destruction of mass.
	//Low instability prevents endothermality while higher instability acutally encourages it.
	reaction_energy = 	instability <= FUSION_INSTABILITY_ENDOTHERMALITY || delta_plasma > 0 ? \
						max(delta_plasma*PLASMA_BINDING_ENERGY, 0) \
						: delta_plasma*PLASMA_BINDING_ENERGY * (instability-FUSION_INSTABILITY_ENDOTHERMALITY)**0.5

	//To achieve faster equilibrium. Too bad it is not that good at cooling down.
	if (reaction_energy)
		var/middle_energy = (((TOROID_CALCULATED_THRESHOLD / 2) * scale_factor) + FUSION_MOLE_THRESHOLD) * (200 * FUSION_MIDDLE_ENERGY_REFERENCE)
		thermal_energy = middle_energy * FUSION_ENERGY_TRANSLATION_EXPONENT ** log(10, thermal_energy / middle_energy)

		//This bowdlerization is a double-edged sword. Tread with care!
		var/bowdlerized_reaction_energy = 	clamp(reaction_energy, \
											thermal_energy * ((1 / FUSION_ENERGY_TRANSLATION_EXPONENT ** 2) - 1), \
											thermal_energy * (FUSION_ENERGY_TRANSLATION_EXPONENT ** 2 - 1))
		thermal_energy = middle_energy * 10 ** log(FUSION_ENERGY_TRANSLATION_EXPONENT, (thermal_energy + bowdlerized_reaction_energy) / middle_energy)

	//The reason why you should set up a tritium production line.
	air.adjust_moles(GAS_TRITIUM, -FUSION_TRITIUM_MOLES_USED)

	//The decay of the tritium and the reaction's energy produces waste gases, different ones depending on whether the reaction is endo or exothermic
	var/standard_waste_gas_output = scale_factor * (FUSION_TRITIUM_CONVERSION_COEFFICIENT*FUSION_TRITIUM_MOLES_USED)
	delta_plasma > 0 ? air.adjust_moles(GAS_H2O, standard_waste_gas_output) : air.adjust_moles(GAS_BZ, standard_waste_gas_output)
	air.adjust_moles(GAS_O2, standard_waste_gas_output) //Oxygen is a bit touchy subject

	if(reaction_energy)
		if(location)
			var/standard_energy = 400 * air.get_moles(GAS_PLASMA) * air.return_temperature() //Prevents putting meaningless waste gases to achieve high rads.
			if(prob(PERCENT(((PARTICLE_CHANCE_CONSTANT)/(reaction_energy-PARTICLE_CHANCE_CONSTANT)) + 1))) //Asymptopically approaches 100% as the energy of the reaction goes up.
				location.fire_nuclear_particle(customize = TRUE, custompower = standard_energy)
			radiation_pulse(location, max(2000 * 3 ** (log(10,standard_energy) - FUSION_RAD_MIDPOINT), 0))
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.set_temperature(clamp(thermal_energy/new_heat_capacity, TCMB, INFINITY))
		return REACTING
	else if(reaction_energy == 0 && instability <= FUSION_INSTABILITY_ENDOTHERMALITY)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.set_temperature(clamp(thermal_energy/new_heat_capacity, TCMB, INFINITY)) //THIS SHOULD STAY OR FUSION WILL EAT YOUR FACE
		return REACTING

/datum/gas_reaction/nitrylformation //The formation of nitryl. Endothermic. Requires N2O as a catalyst.
	priority = 3
	name = "Nitryl formation"
	id = "nitrylformation"

/datum/gas_reaction/nitrylformation/init_reqs()
	min_requirements = list(
		GAS_O2 = 20,
		GAS_N2 = 20,
		GAS_NITROUS = 5,
		"TEMP" = FIRE_MINIMUM_TEMPERATURE_TO_EXIST * 30
	)

/datum/gas_reaction/nitrylformation/react(datum/gas_mixture/air)
	var/temperature = air.return_temperature()

	var/old_heat_capacity = air.heat_capacity()
	var/heat_efficency = min(temperature/(FIRE_MINIMUM_TEMPERATURE_TO_EXIST * 60),air.get_moles(GAS_O2),air.get_moles(GAS_N2))
	var/energy_used = heat_efficency * NITRYL_FORMATION_ENERGY
	if ((air.get_moles(GAS_O2) - heat_efficency < 0 ) || (air.get_moles(GAS_N2) - heat_efficency < 0)) //Shouldn't produce gas from nothing.
		return NO_REACTION
	air.adjust_moles(GAS_O2, -heat_efficency)
	air.adjust_moles(GAS_N2, -heat_efficency)
	air.adjust_moles(GAS_NITRYL, heat_efficency)

	if(energy_used > 0)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.set_temperature(max(((temperature*old_heat_capacity - energy_used)/new_heat_capacity),TCMB))
		return REACTING

/datum/gas_reaction/bzformation //Formation of BZ by combining plasma and tritium at low pressures. Exothermic.
	priority = 4
	name = "BZ Gas formation"
	id = "bzformation"

/datum/gas_reaction/bzformation/init_reqs()
	min_requirements = list(
		GAS_NITROUS = 10,
		GAS_PLASMA = 10
	)


/datum/gas_reaction/bzformation/react(datum/gas_mixture/air)
	var/temperature = air.return_temperature()
	var/pressure = air.return_pressure()
	var/old_heat_capacity = air.heat_capacity()
	var/reaction_efficency = min(1/((pressure/(0.5*ONE_ATMOSPHERE))*(max(air.get_moles(GAS_PLASMA)/air.get_moles(GAS_NITROUS),1))),air.get_moles(GAS_NITROUS),air.get_moles(GAS_PLASMA)/2)
	var/energy_released = 2*reaction_efficency*FIRE_CARBON_ENERGY_RELEASED
	if ((air.get_moles(GAS_NITROUS) - reaction_efficency < 0 )|| (air.get_moles(GAS_PLASMA) - (2*reaction_efficency) < 0) || energy_released <= 0) //Shouldn't produce gas from nothing.
		return NO_REACTION
	air.adjust_moles(GAS_BZ, reaction_efficency)
	if(reaction_efficency == air.get_moles(GAS_NITROUS))
		air.adjust_moles(GAS_BZ, -min(pressure,1))
		air.adjust_moles(GAS_O2, min(pressure,1))
	air.adjust_moles(GAS_NITROUS, -reaction_efficency)
	air.adjust_moles(GAS_PLASMA, -2*reaction_efficency)

	SSresearch.science_tech.add_point_type(TECHWEB_POINT_TYPE_DEFAULT, min((reaction_efficency**2)*BZ_RESEARCH_SCALE,BZ_RESEARCH_MAX_AMOUNT))

	if(energy_released > 0)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.set_temperature(max(((temperature*old_heat_capacity + energy_released)/new_heat_capacity),TCMB))
		return REACTING

/datum/gas_reaction/stimformation //Stimulum formation follows a strange pattern of how effective it will be at a given temperature, having some multiple peaks and some large dropoffs. Exo and endo thermic.
	priority = 6
	name = "Stimulum formation"
	id = "stimformation"

/datum/gas_reaction/stimformation/init_reqs()
	min_requirements = list(
		GAS_PLASMA = 10,
		GAS_BZ = 20,
		GAS_NITRYL = 30,
		"TEMP" = STIMULUM_HEAT_SCALE/2)

/datum/gas_reaction/stimformation/react(datum/gas_mixture/air)

	var/old_heat_capacity = air.heat_capacity()
	var/heat_scale = min(air.return_temperature()/STIMULUM_HEAT_SCALE,air.get_moles(GAS_PLASMA),air.get_moles(GAS_NITRYL))
	var/stim_energy_change = heat_scale*STIMULUM_HEAT_SCALE

	if ((air.get_moles(GAS_PLASMA) - heat_scale < 0) || (air.get_moles(GAS_NITRYL) - heat_scale < 0)) //Shouldn't produce gas from nothing.
		return NO_REACTION
	air.adjust_moles(GAS_STIMULUM, heat_scale / 10)
	air.adjust_moles(GAS_PLASMA, -heat_scale)
	air.adjust_moles(GAS_NITRYL, -heat_scale)
	SSresearch.science_tech.add_point_type(TECHWEB_POINT_TYPE_DEFAULT, clamp(STIMULUM_RESEARCH_AMOUNT*heat_scale/10,0.01, 10000*STIMULUM_RESEARCH_AMOUNT))
	if(stim_energy_change)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.set_temperature(max(((air.return_temperature()*old_heat_capacity + stim_energy_change)/new_heat_capacity),TCMB))
		return REACTING

/datum/gas_reaction/nobliumformation //Hyper-Noblium formation is extrememly endothermic, but requires high temperatures to start. Due to its high mass, hyper-nobelium uses large amounts of nitrogen and tritium. BZ can be used as a catalyst to make it less endothermic.
	priority = 1001 //Ensure this value is higher than nobstop
	name = "Hyper-Noblium condensation"
	id = "nobformation"

/datum/gas_reaction/nobliumformation/init_reqs()
	min_requirements = list(
		GAS_N2 = 20,
		GAS_TRITIUM = 10,
		"TEMP" = 5000000
)

/datum/gas_reaction/nobliumformation/react(datum/gas_mixture/air)
	var/nob_formed = min(air.get_moles(GAS_TRITIUM)/10,air.get_moles(GAS_N2)/20)
	var/old_heat_capacity = air.heat_capacity()
	var/energy_taken = nob_formed*(NOBLIUM_FORMATION_ENERGY/(max(air.get_moles(GAS_BZ),1)))
	air.adjust_moles(GAS_TRITIUM, -10*nob_formed)
	air.adjust_moles(GAS_N2, -20*nob_formed)
	air.adjust_moles(GAS_HYPERNOB, nob_formed)
	SSresearch.science_tech.add_point_type(TECHWEB_POINT_TYPE_DEFAULT, clamp(nob_formed*NOBLIUM_RESEARCH_AMOUNT, 0.01, 10000*NOBLIUM_RESEARCH_AMOUNT))
	var/new_heat_capacity = air.heat_capacity()
	if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
		air.set_temperature(max(((air.return_temperature()*old_heat_capacity - energy_taken)/new_heat_capacity),TCMB))
		return REACTING


/datum/gas_reaction/miaster	//dry heat sterilization: clears out pathogens in the air
	priority = -10 //after all the heating from fires etc. is done
	name = "Dry Heat Sterilization"
	id = "sterilization"

/datum/gas_reaction/miaster/init_reqs()
	min_requirements = list(
		"TEMP" = FIRE_MINIMUM_TEMPERATURE_TO_EXIST+70,
		GAS_MIASMA = MINIMUM_MOLE_COUNT
	)

/datum/gas_reaction/miaster/react(datum/gas_mixture/air, datum/holder)
	// As the name says it, it needs to be dry
	if(air.get_moles(GAS_H2O)/air.total_moles() > 0.1)
		return

	//Replace miasma with oxygen
	var/cleaned_air = min(air.get_moles(GAS_MIASMA), 20 + (air.return_temperature() - FIRE_MINIMUM_TEMPERATURE_TO_EXIST - 70) / 20)
	air.adjust_moles(GAS_MIASMA, -cleaned_air)
	air.adjust_moles(GAS_O2, cleaned_air)

	//Possibly burning a bit of organic matter through maillard reaction, so a *tiny* bit more heat would be understandable
	air.set_temperature(air.return_temperature() + cleaned_air * 0.002)
	SSresearch.science_tech.add_point_type(TECHWEB_POINT_TYPE_DEFAULT, cleaned_air*MIASMA_RESEARCH_AMOUNT)//Turns out the burning of miasma is kinda interesting to scientists
	return REACTING

/datum/gas_reaction/stim_ball
	priority = 7
	name ="Stimulum Energy Ball"
	id = "stimball"

/datum/gas_reaction/stim_ball/init_reqs()
	min_requirements = list(
		GAS_PLUOXIUM = 2,
		GAS_STIMULUM = 2,
		GAS_PLASMA = 2,
		"TEMP" = FIRE_MINIMUM_TEMPERATURE_TO_EXIST
	)

/// Reaction that burns stimulum and plouxium into radballs and partial constituent gases, but also catalyzes the combustion of plasma.
/datum/gas_reaction/stim_ball/react(datum/gas_mixture/air, datum/holder)
	var/old_heat_capacity = air.heat_capacity()
	var/reaction_rate = min(36, air.get_moles(GAS_PLUOXIUM), air.get_moles(GAS_STIMULUM), air.get_moles(GAS_PLASMA))
	//A percentage of plasma is burned during the reaction that is converted into energy and radballs, though mostly pure heat.
	var/plasma_burned = QUANTIZE((air.get_moles(GAS_PLASMA) + 5*reaction_rate)*0.2)
	//Stimulum has a lot of stored energy, and breaking it up releases some of it. Plasma is also partially converted into energy in the process.
	var/energy_released = (reaction_rate*STIMULUM_HEAT_SCALE) + (plasma_burned*20000000)
	air.adjust_moles(GAS_STIMULUM, -reaction_rate)
	air.adjust_moles(GAS_PLUOXIUM, -reaction_rate)
	air.adjust_moles(GAS_NITRYL, reaction_rate*5)
	air.adjust_moles(GAS_PLASMA, -plasma_burned)
	if(energy_released)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.set_temperature(clamp((air.return_temperature()*old_heat_capacity + energy_released)/new_heat_capacity,TCMB,INFINITY))
		return REACTING

//freon reaction (is not a fire yet)
/datum/gas_reaction/freonfire
	priority = -5
	name = "Freon combustion"
	id = "freonfire"

/datum/gas_reaction/freonfire/init_reqs()
	min_requirements = list(
		GAS_O2 = MINIMUM_MOLE_COUNT,
		GAS_FREON = MINIMUM_MOLE_COUNT,
		"TEMP" = FREON_LOWER_TEMPERATURE,
		"MAX_TEMP" = FREON_MAXIMUM_BURN_TEMPERATURE
		)

/datum/gas_reaction/freonfire/react(datum/gas_mixture/air, datum/holder)
	var/energy_released = 0
	var/old_heat_capacity = air.heat_capacity()
	var/temperature = air.return_temperature()
	if(!isturf(holder))
		return NO_REACTION
	var/turf/open/location = holder

	//Handle freon burning (only reaction now)
	var/freon_burn_rate = 0
	var/oxygen_burn_rate = 0
	//more freon released at lower temperatures
	var/temperature_scale = 1

	if(temperature < FREON_LOWER_TEMPERATURE) //stop the reaction when too cold
		temperature_scale = 0
	else
		temperature_scale = (FREON_MAXIMUM_BURN_TEMPERATURE - temperature) / (FREON_MAXIMUM_BURN_TEMPERATURE - FREON_LOWER_TEMPERATURE) //calculate the scale based on the temperature
	if(temperature_scale >= 0)
		oxygen_burn_rate = OXYGEN_BURN_RATIO_BASE - temperature_scale
		if(air.get_moles(GAS_O2) > air.get_moles(GAS_FREON) * FREON_OXYGEN_FULLBURN)
			freon_burn_rate = (air.get_moles(GAS_FREON) * temperature_scale)/FREON_BURN_RATE_DELTA
		else
			freon_burn_rate = (temperature_scale * (air.get_moles(GAS_O2) / FREON_OXYGEN_FULLBURN)) / FREON_BURN_RATE_DELTA

		if(freon_burn_rate > MINIMUM_HEAT_CAPACITY)
			freon_burn_rate = min(freon_burn_rate,air.get_moles(GAS_FREON),air.get_moles(GAS_O2) / oxygen_burn_rate) //Ensures matter is conserved properly
			air.set_moles(GAS_FREON, QUANTIZE(air.get_moles(GAS_FREON) - freon_burn_rate))
			air.set_moles(GAS_O2, QUANTIZE(air.get_moles(GAS_O2) - (freon_burn_rate * oxygen_burn_rate)))
			air.adjust_moles(GAS_CO2, freon_burn_rate)

			if(temperature < 160 && temperature > 120 && prob(2))
				new /obj/item/stack/sheet/hot_ice(location)

			energy_released += FIRE_FREON_ENERGY_RELEASED * (freon_burn_rate)

	if(energy_released < 0)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.set_temperature((temperature * old_heat_capacity + energy_released) / new_heat_capacity)

/datum/gas_reaction/h2fire
	priority = -3 //fire should ALWAYS be last, but tritium fires happen before plasma fires
	name = "Hydrogen Combustion"
	id = "h2fire"

/datum/gas_reaction/h2fire/init_reqs()
	min_requirements = list(
		"TEMP" = FIRE_MINIMUM_TEMPERATURE_TO_EXIST,
		GAS_HYDROGEN = MINIMUM_MOLE_COUNT,
		GAS_O2 = MINIMUM_MOLE_COUNT
	)

/datum/gas_reaction/h2fire/react(datum/gas_mixture/air, datum/holder)
	var/energy_released = 0
	var/old_heat_capacity = air.heat_capacity()
	var/temperature = air.return_temperature()
	var/list/cached_results = air.reaction_results
	cached_results["fire"] = 0
	var/turf/open/location = isturf(holder) ? holder : null
	var/burned_fuel = 0
	if(air.get_moles(GAS_O2) < air.get_moles(GAS_HYDROGEN) || MINIMUM_H2_OXYBURN_ENERGY > air.thermal_energy())
		burned_fuel = air.get_moles(GAS_O2)/HYDROGEN_BURN_OXY_FACTOR
		air.adjust_moles(GAS_HYDROGEN, -burned_fuel)
	else
		burned_fuel = air.get_moles(GAS_HYDROGEN)*HYDROGEN_BURN_H2_FACTOR
		air.adjust_moles(GAS_HYDROGEN, -air.get_moles(GAS_HYDROGEN) / HYDROGEN_BURN_H2_FACTOR)
		air.adjust_moles(GAS_O2, -air.get_moles(GAS_HYDROGEN))

	if(burned_fuel)
		energy_released += (FIRE_HYDROGEN_ENERGY_RELEASED * burned_fuel)

		air.adjust_moles(GAS_H2O, burned_fuel / HYDROGEN_BURN_OXY_FACTOR)

		cached_results["fire"] += burned_fuel

	if(energy_released > 0)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.set_temperature((temperature*old_heat_capacity + energy_released) / new_heat_capacity)

	//let the floor know a fire is happening
	if(istype(location))
		temperature = air.return_temperature()
		if(temperature > FIRE_MINIMUM_TEMPERATURE_TO_EXIST)
			location.hotspot_expose(temperature, CELL_VOLUME)
			for(var/I in location)
				var/atom/movable/item = I
				item.temperature_expose(air, temperature, CELL_VOLUME)
			location.temperature_expose(air, temperature, CELL_VOLUME)

	return cached_results["fire"] ? REACTING : NO_REACTION

/datum/gas_reaction/nitrousformation //formationn of n2o, esothermic, requires bz as catalyst
	priority = 3
	name = "Nitrous Oxide formation"
	id = "nitrousformation"

/datum/gas_reaction/nitrousformation/init_reqs()
	min_requirements = list(
		GAS_O2 = 10,
		GAS_N2 = 20,
		GAS_BZ = 5,
		"TEMP" = 200,
		"MAX_TEMP" = 250
	)

/datum/gas_reaction/nitrousformation/react(datum/gas_mixture/air)
	var/temperature = air.return_temperature()
	var/old_heat_capacity = air.heat_capacity()
	var/heat_efficency = min(air.get_moles(GAS_O2), air.get_moles(GAS_N2))
	var/energy_used = heat_efficency * NITROUS_FORMATION_ENERGY
	if ((air.get_moles(GAS_O2) - heat_efficency < 0 ) || (air.get_moles(GAS_N2) - heat_efficency * 2 < 0)) //Shouldn't produce gas from nothing.
		return NO_REACTION
	air.adjust_moles(GAS_O2, -heat_efficency)
	air.adjust_moles(GAS_N2, -heat_efficency * 2)
	air.adjust_moles(GAS_NITROUS, heat_efficency)

	if(energy_used > 0)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.set_temperature(max(((temperature * old_heat_capacity + energy_used) / new_heat_capacity),TCMB)) //the air heats up when reacting
		return REACTING

/datum/gas_reaction/nitryl_decomposition //The decomposition of nitryl. Exothermic. Requires oxygen as catalyst.
	priority = 21
	name = "Nitryl Decomposition"
	id = "nitryl_decomp"

/datum/gas_reaction/nitryl_decomposition/init_reqs()
	min_requirements = list(
		GAS_O2 = MINIMUM_MOLE_COUNT,
		GAS_NITRYL = MINIMUM_MOLE_COUNT,
		"MAX_TEMP" = 600
	)

/datum/gas_reaction/nitryl_decomposition/react(datum/gas_mixture/air)
	var/temperature = air.return_temperature()
	var/old_heat_capacity = air.heat_capacity()
	var/heat_efficency = min(temperature / (FIRE_MINIMUM_TEMPERATURE_TO_EXIST * 8), air.get_moles(GAS_NITRYL))
	var/energy_produced = heat_efficency * NITRYL_DECOMPOSITION_ENERGY
	if ((air.get_moles(GAS_NITRYL) - heat_efficency < 0)) //Shouldn't produce gas from nothing.
		return NO_REACTION
	air.adjust_moles(GAS_NITRYL, -heat_efficency)
	air.adjust_moles(GAS_O2, heat_efficency)
	air.adjust_moles(GAS_N2, heat_efficency)

	if(energy_produced> 0)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.set_temperature(max(((temperature * old_heat_capacity + energy_produced) / new_heat_capacity), TCMB)) //the air heats up when reacting
		return REACTING

/datum/gas_reaction/freonformation
	priority = 5
	name = "Freon formation"
	id = "freonformation"

/datum/gas_reaction/freonformation/init_reqs() //minimum requirements for freon formation
	min_requirements = list(
		GAS_PLASMA = 40,
		GAS_CO2 = 20,
		GAS_BZ = 20,
		"TEMP" = FIRE_MINIMUM_TEMPERATURE_TO_EXIST + 100
		)

/datum/gas_reaction/freonformation/react(datum/gas_mixture/air)
	var/temperature = air.return_temperature()
	var/old_heat_capacity = air.heat_capacity()
	var/heat_efficency = min(temperature/(FIRE_MINIMUM_TEMPERATURE_TO_EXIST * 10), air.get_moles(GAS_PLASMA), air.get_moles(GAS_CO2), air.get_moles(GAS_BZ))
	var/energy_used = heat_efficency * 100
	if ((air.get_moles(GAS_PLASMA) - heat_efficency * 1.5 < 0) || (air.get_moles(GAS_CO2) - heat_efficency * 0.75 < 0) || (air.get_moles(GAS_BZ) - heat_efficency * 0.25 < 0)) //Shouldn't produce gas from nothing.
		return NO_REACTION
	air.adjust_moles(GAS_PLASMA, -heat_efficency * 1.5)
	air.adjust_moles(GAS_CO2, -heat_efficency * 0.75)
	air.adjust_moles(GAS_BZ, -heat_efficency * 0.25)
	air.adjust_moles(GAS_FREON, heat_efficency * 2.5)

	if(energy_used > 0)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.set_temperature(max(((temperature*old_heat_capacity - energy_used)/new_heat_capacity),TCMB))
		return REACTING

/datum/gas_reaction/halon_formation
	priority = 12
	name = "Halon formation"
	id = "halon_formation"

/datum/gas_reaction/halon_formation/init_reqs()
	min_requirements = list(
		GAS_BZ = MINIMUM_MOLE_COUNT,
		GAS_TRITIUM = MINIMUM_MOLE_COUNT,
		"TEMP" = 30,
		"MAX_TEMP" = 55
	)

/datum/gas_reaction/halon_formation/react(datum/gas_mixture/air, datum/holder)
	var/temperature = air.return_temperature()
	var/old_heat_capacity = air.heat_capacity()
	var/heat_efficency = min(temperature * 0.01, air.get_moles(GAS_TRITIUM), air.get_moles(GAS_BZ))
	var/energy_used = heat_efficency * 300
	if ((air.get_moles(GAS_TRITIUM) - heat_efficency * 4 < 0 ) || (air.get_moles(GAS_BZ) - heat_efficency * 0.25 < 0)) //Shouldn't produce gas from nothing.
		return NO_REACTION
	air.adjust_moles(GAS_TRITIUM, -heat_efficency * 4)
	air.adjust_moles(GAS_BZ, -heat_efficency * 0.25)
	air.adjust_moles(GAS_HALON, heat_efficency * 4.25)

	if(energy_used)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.set_temperature(max(((temperature * old_heat_capacity + energy_used) / new_heat_capacity), TCMB))
	return REACTING

/datum/gas_reaction/healium_formation
	priority = 9
	name = "Healium formation"
	id = "healium_formation"

/datum/gas_reaction/healium_formation/init_reqs()
	min_requirements = list(
		GAS_BZ = MINIMUM_MOLE_COUNT,
		GAS_FREON = MINIMUM_MOLE_COUNT,
		"TEMP" = 25,
		"MAX_TEMP" = 300
	)

/datum/gas_reaction/healium_formation/react(datum/gas_mixture/air, datum/holder)
	var/temperature = air.return_temperature()
	var/old_heat_capacity = air.heat_capacity()
	var/heat_efficency = min(temperature * 0.3, air.get_moles(GAS_FREON), air.get_moles(GAS_BZ))
	var/energy_used = heat_efficency * 9000
	if ((air.get_moles(GAS_FREON) - heat_efficency * 2.75 < 0 ) || (air.get_moles(GAS_BZ) - heat_efficency * 0.25 < 0)) //Shouldn't produce gas from nothing.
		return NO_REACTION
	air.adjust_moles(GAS_FREON, -heat_efficency * 2.75)
	air.adjust_moles(GAS_BZ, -heat_efficency * 0.25)
	air.adjust_moles(GAS_HEALIUM, heat_efficency * 3)

	if(energy_used)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.set_temperature(max(((temperature * old_heat_capacity + energy_used) / new_heat_capacity), TCMB))
	return REACTING

/datum/gas_reaction/proto_nitrate_formation
	priority = 10
	name = "Proto Nitrate formation"
	id = "proto_nitrate_formation"

/datum/gas_reaction/proto_nitrate_formation/init_reqs()
	min_requirements = list(
		GAS_PLUOXIUM = MINIMUM_MOLE_COUNT,
		GAS_HYDROGEN = MINIMUM_MOLE_COUNT,
		"TEMP" = 5000,
		"MAX_TEMP" = 10000
	)

/datum/gas_reaction/proto_nitrate_formation/react(datum/gas_mixture/air, datum/holder)
	var/temperature = air.return_temperature()
	var/old_heat_capacity = air.heat_capacity()
	var/heat_efficency = min(temperature * 0.005, air.get_moles(GAS_PLUOXIUM), air.get_moles(GAS_HYDROGEN))
	var/energy_used = heat_efficency * 650
	if ((air.get_moles(GAS_PLUOXIUM) - heat_efficency * 0.2 < 0 ) || (air.get_moles(GAS_HYDROGEN) - heat_efficency * 2 < 0)) //Shouldn't produce gas from nothing.
		return NO_REACTION
	air.adjust_moles(GAS_HYDROGEN, -heat_efficency * 2)
	air.adjust_moles(GAS_PLUOXIUM, -heat_efficency * 0.2)
	air.adjust_moles(GAS_PROTO_NITRATE, heat_efficency * 2.2)

	if(energy_used > 0)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.set_temperature(max(((temperature * old_heat_capacity + energy_used) / new_heat_capacity), TCMB))
	return REACTING

/datum/gas_reaction/zauker_formation
	priority = 11
	name = "Zauker formation"
	id = "zauker_formation"

/datum/gas_reaction/zauker_formation/init_reqs()
	min_requirements = list(
		GAS_HYPERNOB = MINIMUM_MOLE_COUNT,
		GAS_STIMULUM = MINIMUM_MOLE_COUNT,
		"TEMP" = 50000,
		"MAX_TEMP" = 75000
	)

/datum/gas_reaction/zauker_formation/react(datum/gas_mixture/air, datum/holder)
	var/temperature = air.return_temperature()
	var/old_heat_capacity = air.heat_capacity()
	var/heat_efficency = min(temperature * 0.000005, air.get_moles(GAS_HYPERNOB), air.get_moles(GAS_STIMULUM))
	var/energy_used = heat_efficency * 5000
	if ((air.get_moles(GAS_HYPERNOB) - heat_efficency * 0.01 < 0 ) || (air.get_moles(GAS_STIMULUM) - heat_efficency * 0.5 < 0)) //Shouldn't produce gas from nothing.
		return NO_REACTION
	air.adjust_moles(GAS_HYPERNOB, -(heat_efficency * 0.01))
	air.adjust_moles(GAS_STIMULUM, -(heat_efficency * 0.5))
	air.adjust_moles(GAS_ZAUKER, heat_efficency * 0.5)

	if(energy_used)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.set_temperature(max(((temperature * old_heat_capacity - energy_used) / new_heat_capacity), TCMB))
	return REACTING

/datum/gas_reaction/halon_o2removal
	priority = -1
	name = "Halon o2 removal"
	id = "halon_o2removal"

/datum/gas_reaction/halon_o2removal/init_reqs()
	min_requirements = list(
		GAS_HALON = MINIMUM_MOLE_COUNT,
		GAS_O2 = MINIMUM_MOLE_COUNT,
		"TEMP" = FIRE_MINIMUM_TEMPERATURE_TO_EXIST
	)

/datum/gas_reaction/halon_o2removal/react(datum/gas_mixture/air, datum/holder)
	var/temperature = air.return_temperature()
	var/old_heat_capacity = air.heat_capacity()
	var/heat_efficency = min(temperature / ( FIRE_MINIMUM_TEMPERATURE_TO_EXIST * 10), air.get_moles(GAS_HALON), air.get_moles(GAS_O2))
	var/energy_used = heat_efficency * 2500
	if ((air.get_moles(GAS_HALON) - heat_efficency < 0 ) || (air.get_moles(GAS_O2) - heat_efficency * 20 < 0)) //Shouldn't produce gas from nothing.
		return NO_REACTION
	air.adjust_moles(GAS_HALON, -heat_efficency)
	air.adjust_moles(GAS_O2, -heat_efficency * 20)
	air.adjust_moles(GAS_CO2, heat_efficency * 5)

	if(energy_used)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.set_temperature(max(((temperature * old_heat_capacity - energy_used) / new_heat_capacity), TCMB))
	return REACTING

/datum/gas_reaction/zauker_decomp
	priority = 8
	name = "Zauker decomposition"
	id = "zauker_decomp"

/datum/gas_reaction/zauker_decomp/init_reqs()
	min_requirements = list(
		GAS_N2 = MINIMUM_MOLE_COUNT,
		GAS_ZAUKER = MINIMUM_MOLE_COUNT
	)

/datum/gas_reaction/zauker_decomp/react(datum/gas_mixture/air, datum/holder)
	var/energy_released = 0
	var/old_heat_capacity = air.heat_capacity()
	var/temperature = air.return_temperature()
	var/burned_fuel = 0
	burned_fuel = min(20, air.get_moles(GAS_N2), air.get_moles(GAS_ZAUKER))
	if(air.get_moles(GAS_ZAUKER) - burned_fuel < 0)
		return NO_REACTION
	air.adjust_moles(GAS_ZAUKER, -burned_fuel)

	if(burned_fuel)
		energy_released += (460 * burned_fuel)

		air.adjust_moles(GAS_O2, burned_fuel * 0.3)
		air.adjust_moles(GAS_N2, burned_fuel * 0.7)

		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.set_temperature(max((temperature * old_heat_capacity + energy_released) / new_heat_capacity, TCMB))
		return REACTING
	return NO_REACTION

/datum/gas_reaction/proto_nitrate_bz_response
	priority = 13
	name = "Proto Nitrate bz response"
	id = "proto_nitrate_bz_response"

/datum/gas_reaction/proto_nitrate_bz_response/init_reqs()
	min_requirements = list(
		GAS_PROTO_NITRATE = MINIMUM_MOLE_COUNT,
		GAS_BZ = MINIMUM_MOLE_COUNT,
		"TEMP" = 260,
		"MAX_TEMP" = 280
	)

/datum/gas_reaction/proto_nitrate_bz_response/react(datum/gas_mixture/air, datum/holder)
	var/energy_released = 0
	var/old_heat_capacity = air.heat_capacity()
	var/temperature = air.return_temperature()
	var/turf/open/location
	if(istype(holder,/datum/pipeline)) //Find the tile the reaction is occuring on, or a random part of the network if it's a pipenet.
		var/datum/pipeline/pipenet = holder
		location = get_turf(pick(pipenet.members))
	else
		location = get_turf(holder)
	var consumed_amount = min(5, air.get_moles(GAS_BZ), air.get_moles(GAS_PROTO_NITRATE))
	if(air.get_moles(GAS_BZ) - consumed_amount < 0)
		return NO_REACTION
	if(air.get_moles(GAS_BZ) < 30)
		radiation_pulse(location, consumed_amount * 20, 2.5, TRUE, FALSE)
		air.adjust_moles(GAS_BZ, -consumed_amount)
	else
		for(var/mob/living/carbon/L in location)
			L.hallucination += air.get_moles(GAS_BZ) * 0.7
	energy_released += 100
	if(energy_released)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.set_temperature(max((temperature * old_heat_capacity + energy_released) / new_heat_capacity, TCMB))
	return REACTING

/datum/gas_reaction/proto_nitrate_tritium_response
	priority = 16
	name = "Proto Nitrate tritium response"
	id = "proto_nitrate_tritium_response"

/datum/gas_reaction/proto_nitrate_tritium_response/init_reqs()
	min_requirements = list(
		GAS_PROTO_NITRATE = MINIMUM_MOLE_COUNT,
		GAS_TRITIUM = MINIMUM_MOLE_COUNT,
		"TEMP" = 5000,
		"MAX_TEMP" = 10000
	)

/datum/gas_reaction/proto_nitrate_tritium_response/react(datum/gas_mixture/air, datum/holder)
	var/energy_released = 0
	var/old_heat_capacity = air.heat_capacity()
	var/temperature = air.return_temperature()
	var/turf/open/location = isturf(holder) ? holder : null
	if(location == null)
		return NO_REACTION
	var produced_amount = min(5, air.get_moles(GAS_TRITIUM), air.get_moles(GAS_PROTO_NITRATE))
	if(air.get_moles(GAS_TRITIUM) - produced_amount < 0 || air.get_moles(GAS_PROTO_NITRATE) - produced_amount * 0.01 < 0)
		return NO_REACTION
	location.rad_act(produced_amount * 2.4)
	air.adjust_moles(GAS_TRITIUM, -produced_amount)
	air.adjust_moles(GAS_HYDROGEN, produced_amount)
	air.adjust_moles(GAS_PROTO_NITRATE, -produced_amount * 0.01)
	energy_released += 50
	if(energy_released)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.set_temperature(max((temperature * old_heat_capacity + energy_released) / new_heat_capacity, TCMB))
	return REACTING

/datum/gas_reaction/proto_nitrate_hydrogen_response
	priority = 17
	name = "Proto Nitrate hydrogen response"
	id = "proto_nitrate_hydrogen_response"

/datum/gas_reaction/proto_nitrate_hydrogen_response/init_reqs()
	min_requirements = list(
		GAS_PROTO_NITRATE = MINIMUM_MOLE_COUNT,
		GAS_HYDROGEN = 150,
	)

/datum/gas_reaction/proto_nitrate_hydrogen_response/react(datum/gas_mixture/air, datum/holder)
	var/energy_released = 0
	var/old_heat_capacity = air.heat_capacity()
	var/temperature = air.return_temperature()
	var produced_amount = min(5, air.get_moles(GAS_HYDROGEN), air.get_moles(GAS_PROTO_NITRATE))
	if(air.get_moles(GAS_HYDROGEN) - produced_amount < 0)
		return NO_REACTION
	air.adjust_moles(GAS_HYDROGEN, -produced_amount)
	air.adjust_moles(GAS_PROTO_NITRATE, produced_amount * 0.5)
	energy_released = produced_amount * 2500
	if(energy_released)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.set_temperature(max((temperature * old_heat_capacity - energy_released) / new_heat_capacity, TCMB))
	return REACTING

/datum/gas_reaction/pluox_formation
	priority = 2
	name = "Pluoxium formation"
	id = "pluox_formation"

/datum/gas_reaction/pluox_formation/init_reqs()
	min_requirements = list(
		GAS_CO2 = MINIMUM_MOLE_COUNT,
		GAS_O2 = MINIMUM_MOLE_COUNT,
		GAS_TRITIUM = MINIMUM_MOLE_COUNT,
		"TEMP" = 50,
		"MAX_TEMP" = T0C
	)

/datum/gas_reaction/pluox_formation/react(datum/gas_mixture/air, datum/holder)
	var/energy_released = 0
	var/old_heat_capacity = air.heat_capacity()
	var/temperature = air.return_temperature()
	var produced_amount = min(5, air.get_moles(GAS_CO2), air.get_moles(GAS_O2))
	if(air.get_moles(GAS_CO2) - produced_amount < 0 || air.get_moles(GAS_O2) - produced_amount * 0.5 < 0 || air.get_moles(GAS_TRITIUM) - produced_amount * 0.01 < 0)
		return NO_REACTION
	air.adjust_moles(GAS_CO2, -produced_amount)
	air.adjust_moles(GAS_O2, -produced_amount * 0.5)
	air.adjust_moles(GAS_TRITIUM, -produced_amount * 0.01)
	air.adjust_moles(GAS_PLUOXIUM, produced_amount)
	air.adjust_moles(GAS_HYDROGEN, produced_amount * 0.01)
	energy_released += produced_amount * 250
	if(energy_released)
		var/new_heat_capacity = air.heat_capacity()
		if(new_heat_capacity > MINIMUM_HEAT_CAPACITY)
			air.set_temperature(max((temperature * old_heat_capacity + energy_released) / new_heat_capacity, TCMB))
	return REACTING
