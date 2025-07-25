

//////////////////////////////////////////////////////////////////////////////////////////
					// MEDICINE REAGENTS
//////////////////////////////////////////////////////////////////////////////////////

// where all the reagents related to medicine go.

/datum/reagent/medicine

	enname = "Medicine"
	taste_description = "горечь"

/datum/reagent/medicine/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	current_cycle++
	if(length(reagent_removal_skip_list))
		return
	holder.remove_reagent(type, metabolization_rate * delta_time / M.metabolism_efficiency) //medicine reagents stay longer if you have a better metabolism

/datum/reagent/medicine/leporazine
	name = "Лепоразин"
	enname = "Leporazine"
	description = "Leporazine will effectively regulate a patient's body temperature, ensuring it never leaves safe levels."
	ph = 8.4
	color = "#DB90C6"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/medicine/leporazine/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	var/target_temp = M.get_body_temp_normal(apply_change=FALSE)
	if(M.bodytemperature > target_temp)
		M.adjust_bodytemperature(-40 * TEMPERATURE_DAMAGE_COEFFICIENT * REM * delta_time, target_temp)
	else if(M.bodytemperature < (target_temp + 1))
		M.adjust_bodytemperature(40 * TEMPERATURE_DAMAGE_COEFFICIENT * REM * delta_time, 0, target_temp)
	if(ishuman(M))
		var/mob/living/carbon/human/humi = M
		if(humi.coretemperature > target_temp)
			humi.adjust_coretemperature(-40 * TEMPERATURE_DAMAGE_COEFFICIENT * REM * delta_time, target_temp)
		else if(humi.coretemperature < (target_temp + 1))
			humi.adjust_coretemperature(40 * TEMPERATURE_DAMAGE_COEFFICIENT * REM * delta_time, 0, target_temp)
	..()

/datum/reagent/medicine/adminordrazine //An OP chemical for admins
	name = "Админордразин"
	enname = "Adminordrazine"
	description = "Это магия. Не будем объяснять, как."
	color = "#E0BB00" //golden for the gods
	taste_description = "щитспавн"
	chemical_flags = REAGENT_DEAD_PROCESS

// The best stuff there is. For testing/debugging.
/datum/reagent/medicine/adminordrazine/on_hydroponics_apply(obj/item/seeds/myseed, datum/reagents/chems, obj/machinery/hydroponics/mytray, mob/user)
	. = ..()
	if(chems.has_reagent(type, 1))
		mytray.adjustWater(round(chems.get_reagent_amount(type) * 1))
		mytray.adjustHealth(round(chems.get_reagent_amount(type) * 1))
		mytray.adjustPests(-rand(1,5))
		mytray.adjustWeeds(-rand(1,5))
	if(chems.has_reagent(type, 3))
		switch(rand(100))
			if(66  to 100)
				mytray.mutatespecie()
			if(33 to 65)
				mytray.mutateweed()
			if(1   to 32)
				mytray.mutatepest(user)
			else if(prob(20))
				mytray.visible_message(span_warning("Ничего не произошло..."))

/datum/reagent/medicine/adminordrazine/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.heal_bodypart_damage(5 * REM * delta_time, 5 * REM * delta_time)
	M.adjustToxLoss(-5 * REM * delta_time, FALSE, TRUE)
	M.setOxyLoss(0, 0)
	M.setCloneLoss(0, 0)

	M.set_blurriness(0)
	M.set_blindness(0)
	M.SetKnockdown(0)
	M.SetStun(0)
	M.SetUnconscious(0)
	M.SetParalyzed(0)
	M.SetImmobilized(0)
	M.set_confusion(0)
	M.SetSleeping(0)

	M.silent = FALSE
	M.dizziness = 0
	M.disgust = 0
	M.drowsyness = 0
	M.stuttering = 0
	M.slurring = 0
	M.jitteriness = 0
	M.hallucination = 0
	M.radiation = 0
	REMOVE_TRAITS_NOT_IN(M, list(SPECIES_TRAIT, ROUNDSTART_TRAIT, ORGAN_TRAIT))
	M.reagents.remove_all_type(/datum/reagent/toxin, 5 * REM * delta_time, FALSE, TRUE)
	if(M.blood_volume < BLOOD_VOLUME_NORMAL)
		M.blood_volume = BLOOD_VOLUME_NORMAL

	M.cure_all_traumas(TRAUMA_RESILIENCE_MAGIC)
	for(var/organ in M.internal_organs)
		var/obj/item/organ/O = organ
		O.setOrganDamage(0)
	for(var/thing in M.diseases)
		var/datum/disease/D = thing
		if(D.severity == DISEASE_SEVERITY_POSITIVE)
			continue
		D.cure()
	..()
	. = TRUE

/datum/reagent/medicine/adminordrazine/quantum_heal
	name = "Квантовая медицина"
	enname = "Quantum Medicine"
	description = "Rare and experimental particles, that apparently swap the user's body with one from an alternate dimension where it's completely healthy."
	taste_description = "наука"

/datum/reagent/medicine/synaptizine
	name = "Синаптизин"
	enname = "Synaptizine"
	description = "Increases resistance to stuns as well as reducing drowsiness and hallucinations."
	color = "#FF00FF"
	ph = 4
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/medicine/synaptizine/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.drowsyness = max(M.drowsyness - (5 * REM * delta_time), 0)
	M.AdjustStun(-20 * REM * delta_time)
	M.AdjustKnockdown(-20 * REM * delta_time)
	M.AdjustUnconscious(-20 * REM * delta_time)
	M.AdjustImmobilized(-20 * REM * delta_time)
	M.AdjustParalyzed(-20 * REM * delta_time)
	if(holder.has_reagent(/datum/reagent/toxin/mindbreaker))
		holder.remove_reagent(/datum/reagent/toxin/mindbreaker, 5 * REM * delta_time)
	M.hallucination = max(M.hallucination - (10 * REM * delta_time), 0)
	if(DT_PROB(16, delta_time))
		M.adjustToxLoss(1, 0)
		. = TRUE
	..()

/datum/reagent/medicine/synaphydramine
	name = "Дифен-Синаптизин"
	enname = "Diphen-Synaptizine"
	description = "Reduces drowsiness, hallucinations, and Histamine from body."
	color = "#EC536D" // rgb: 236, 83, 109
	ph = 5.2
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/medicine/synaphydramine/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.drowsyness = max(M.drowsyness - (5 * REM * delta_time), 0)
	if(holder.has_reagent(/datum/reagent/toxin/mindbreaker))
		holder.remove_reagent(/datum/reagent/toxin/mindbreaker, 5 * REM * delta_time)
	if(holder.has_reagent(/datum/reagent/toxin/histamine))
		holder.remove_reagent(/datum/reagent/toxin/histamine, 5 * REM * delta_time)
	M.hallucination = max(M.hallucination - (10 * REM * delta_time), 0)
	if(DT_PROB(16, delta_time))
		M.adjustToxLoss(1, 0)
		. = TRUE
	..()

/datum/reagent/medicine/cryoxadone
	name = "Криоксадон"
	enname = "Cryoxadone"
	description = "A chemical mixture with almost magical healing powers. Its main limitation is that the patient's body temperature must be under 270K for it to metabolise correctly."
	color = "#0000C8"
	taste_description = "отстой"
	ph = 11
	burning_temperature = 20 //cold burning
	burning_volume = 0.1
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/medicine/cryoxadone/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	var/power = -0.00003 * (M.bodytemperature ** 2) + 3
	if(M.bodytemperature < T0C)
		M.adjustOxyLoss(-3 * power * REM * delta_time, 0)
		M.adjustBruteLoss(-power * REM * delta_time, 0)
		M.adjustFireLoss(-power * REM * delta_time, 0)
		M.adjustToxLoss(-power * REM * delta_time, 0, TRUE) //heals TOXINLOVERs
		M.adjustCloneLoss(-power * REM * delta_time, 0)
		for(var/i in M.all_wounds)
			var/datum/wound/iter_wound = i
			iter_wound.on_xadone(power * REAGENTS_EFFECT_MULTIPLIER * delta_time)
		REMOVE_TRAIT(M, TRAIT_DISFIGURED, TRAIT_GENERIC) //fixes common causes for disfiguration
		. = TRUE
	metabolization_rate = REAGENTS_METABOLISM * (0.00001 * (M.bodytemperature ** 2) + 0.5)
	..()

// Healing
/datum/reagent/medicine/cryoxadone/on_hydroponics_apply(obj/item/seeds/myseed, datum/reagents/chems, obj/machinery/hydroponics/mytray, mob/user)
	. = ..()
	mytray.adjustHealth(round(chems.get_reagent_amount(type) * 3))
	mytray.adjustToxic(-round(chems.get_reagent_amount(type) * 3))

/datum/reagent/medicine/clonexadone
	name = "Клоноксадон"
	enname = "Clonexadone"
	description = "A chemical that derives from Cryoxadone. It specializes in healing clone damage, but nothing else. Requires very cold temperatures to properly metabolize, and metabolizes quicker than cryoxadone."
	color = "#3D3DC6"
	taste_description = "мускулы"
	ph = 13
	metabolization_rate = 1.5 * REAGENTS_METABOLISM

/datum/reagent/medicine/clonexadone/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(M.bodytemperature < T0C)
		M.adjustCloneLoss((0.00006 * (M.bodytemperature ** 2) - 6) * REM * delta_time, 0)
		REMOVE_TRAIT(M, TRAIT_DISFIGURED, TRAIT_GENERIC)
		. = TRUE
	metabolization_rate = REAGENTS_METABOLISM * (0.000015 * (M.bodytemperature ** 2) + 0.75)
	..()

/datum/reagent/medicine/pyroxadone
	name = "Пироксадон"
	enname = "Pyroxadone"
	description = "A mixture of cryoxadone and slime jelly, that apparently inverses the requirement for its activation."
	color = "#f7832a"
	taste_description = "острое желе"
	ph = 12
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/medicine/pyroxadone/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(M.bodytemperature > BODYTEMP_HEAT_DAMAGE_LIMIT)
		var/power = 0
		switch(M.bodytemperature)
			if(BODYTEMP_HEAT_DAMAGE_LIMIT to 400)
				power = 2
			if(400 to 460)
				power = 3
			else
				power = 5
		if(M.on_fire)
			power *= 2

		M.adjustOxyLoss(-2 * power * REM * delta_time, FALSE)
		M.adjustBruteLoss(-power * REM * delta_time, FALSE)
		M.adjustFireLoss(-1.5 * power * REM * delta_time, FALSE)
		M.adjustToxLoss(-power * REM * delta_time, FALSE, TRUE)
		M.adjustCloneLoss(-power * REM * delta_time, FALSE)
		for(var/i in M.all_wounds)
			var/datum/wound/iter_wound = i
			iter_wound.on_xadone(power * REAGENTS_EFFECT_MULTIPLIER * delta_time)
		REMOVE_TRAIT(M, TRAIT_DISFIGURED, TRAIT_GENERIC)
		. = TRUE
	..()

/datum/reagent/medicine/rezadone
	name = "Резадон"
	enname = "Rezadone"
	description = "A powder derived from fish toxin, Rezadone can effectively treat genetic damage as well as restoring minor wounds and restoring corpses husked by burns. Overdose will cause intense nausea and minor toxin damage."
	reagent_state = SOLID
	color = "#669900" // rgb: 102, 153, 0
	overdose_threshold = 30
	ph = 12.2
	taste_description = "рыба"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/medicine/rezadone/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.setCloneLoss(0) //Rezadone is almost never used in favor of cryoxadone. Hopefully this will change that. // No such luck so far
	M.heal_bodypart_damage(1 * REM * delta_time, 1 * REM * delta_time)
	REMOVE_TRAIT(M, TRAIT_DISFIGURED, TRAIT_GENERIC)
	..()
	. = TRUE

/datum/reagent/medicine/rezadone/overdose_process(mob/living/M, delta_time, times_fired)
	M.adjustToxLoss(1 * REM * delta_time, 0)
	M.Dizzy(5 * REM * delta_time)
	M.Jitter(5 * REM * delta_time)
	..()
	. = TRUE

/datum/reagent/medicine/rezadone/expose_mob(mob/living/exposed_mob, methods=TOUCH, reac_volume)
	. = ..()
	if(!iscarbon(exposed_mob))
		return

	var/mob/living/carbon/patient = exposed_mob
	if(reac_volume >= 5 && HAS_TRAIT_FROM(patient, TRAIT_HUSK, BURN) && patient.getFireLoss() < UNHUSK_DAMAGE_THRESHOLD) //One carp yields 12u rezadone.
		patient.cure_husk(BURN)
		patient.visible_message(span_nicegreen("Тело [patient] быстро впитывает влагу из окружающей среды, принимая более здоровый вид."))

/datum/reagent/medicine/spaceacillin
	name = "Космоацилин"
	enname = "Spaceacillin"
	description = "Spaceacillin will prevent a patient from conventionally spreading any diseases they are currently infected with. Also reduces infection in serious burns."
	color = "#E1F2E6"
	metabolization_rate = 0.1 * REAGENTS_METABOLISM
	ph = 8.1
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

//Goon Chems. Ported mainly from Goonstation. Easily mixable (or not so easily) and provide a variety of effects.

/datum/reagent/medicine/oxandrolone
	name = "Оксандролон"
	enname = "Oxandrolone"
	description = "Stimulates the healing of severe burns. Extremely rapidly heals severe burns and slowly heals minor ones. Overdose will worsen existing burns."
	reagent_state = LIQUID
	color = "#1E8BFF"
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	overdose_threshold = 25
	ph = 10.7
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/medicine/oxandrolone/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(M.getFireLoss() > 25)
		M.adjustFireLoss(-4 * REM * delta_time, 0) //Twice as effective as AIURI for severe burns
	else
		M.adjustFireLoss(-0.5 * REM * delta_time, 0) //But only a quarter as effective for more minor ones
	..()
	. = TRUE

/datum/reagent/medicine/oxandrolone/overdose_process(mob/living/M, delta_time, times_fired)
	if(M.getFireLoss()) //It only makes existing burns worse
		M.adjustFireLoss(4.5 * REM * delta_time, FALSE, FALSE, BODYPART_ORGANIC) // it's going to be healing either 4 or 0.5
		. = TRUE
	..()

/datum/reagent/medicine/salglu_solution
	name = "Физраствор"
	enname = "Saline-Glucose Solution"
	description = "Has a 33% chance per metabolism cycle to heal brute and burn damage. Can be used as a temporary blood substitute, as well as slowly speeding blood regeneration."
	reagent_state = LIQUID
	color = "#DCDCDC"
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	overdose_threshold = 60
	taste_description = "сладость и соль"
	var/last_added = 0
	var/maximum_reachable = BLOOD_VOLUME_NORMAL - 10	//So that normal blood regeneration can continue with salglu active
	var/extra_regen = 0.25 // in addition to acting as temporary blood, also add this much to their actual blood per tick
	ph = 5.5
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/medicine/salglu_solution/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(last_added)
		M.blood_volume -= last_added
		last_added = 0
	if(M.blood_volume < maximum_reachable)	//Can only up to double your effective blood level.
		var/amount_to_add = min(M.blood_volume, volume*5)
		var/new_blood_level = min(M.blood_volume + amount_to_add, maximum_reachable)
		last_added = new_blood_level - M.blood_volume
		M.blood_volume = new_blood_level + (extra_regen * REM * delta_time)
	if(DT_PROB(18, delta_time))
		M.adjustBruteLoss(-0.5, 0)
		M.adjustFireLoss(-0.5, 0)
		. = TRUE
	..()

/datum/reagent/medicine/salglu_solution/overdose_process(mob/living/M, delta_time, times_fired)
	if(DT_PROB(1.5, delta_time))
		to_chat(M, span_warning("Какое соленое чувство."))
		holder.add_reagent(/datum/reagent/consumable/salt, 1)
		holder.remove_reagent(/datum/reagent/medicine/salglu_solution, 0.5)
	else if(DT_PROB(1.5, delta_time))
		to_chat(M, span_warning("Какое сладкое чувство."))
		holder.add_reagent(/datum/reagent/consumable/sugar, 1)
		holder.remove_reagent(/datum/reagent/medicine/salglu_solution, 0.5)
	if(DT_PROB(18, delta_time))
		M.adjustBruteLoss(0.5, FALSE, FALSE, BODYPART_ORGANIC)
		M.adjustFireLoss(0.5, FALSE, FALSE, BODYPART_ORGANIC)
		. = TRUE
	..()

/datum/reagent/medicine/mine_salve
	name = "Шахтерская Мазь"
	enname = "Miner's Salve"
	description = "A powerful painkiller. Restores bruising and burns in addition to making the patient believe they are fully healed. Also great for treating severe burn wounds in a pinch."
	reagent_state = LIQUID
	color = "#6D6374"
	metabolization_rate = 0.4 * REAGENTS_METABOLISM
	ph = 2.6
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/medicine/mine_salve/on_mob_life(mob/living/carbon/C, delta_time, times_fired)
	C.hal_screwyhud = SCREWYHUD_HEALTHY
	C.adjustBruteLoss(-0.25 * REM * delta_time, 0)
	C.adjustFireLoss(-0.25 * REM * delta_time, 0)
	..()
	return TRUE

/datum/reagent/medicine/mine_salve/expose_mob(mob/living/exposed_mob, methods=TOUCH, reac_volume, show_message = TRUE)
	. = ..()
	if(!iscarbon(exposed_mob) || (exposed_mob.stat == DEAD))
		return

	if(methods & (INGEST|VAPOR|INJECT))
		exposed_mob.adjust_nutrition(-5)
		if(show_message)
			to_chat(exposed_mob, span_warning("Ощущаю пустоту в желудке и спазмы!"))

	if(methods & (PATCH|TOUCH))
		var/mob/living/carbon/exposed_carbon = exposed_mob
		for(var/s in exposed_carbon.surgeries)
			var/datum/surgery/surgery = s
			surgery.speed_modifier = max(0.1, surgery.speed_modifier)

		if(show_message)
			to_chat(exposed_carbon, span_danger("Чувствую, что мои раны затягиваются!")  )

/datum/reagent/medicine/mine_salve/on_mob_end_metabolize(mob/living/M)
	if(iscarbon(M))
		var/mob/living/carbon/N = M
		N.hal_screwyhud = SCREWYHUD_NONE
	..()

/datum/reagent/medicine/omnizine
	name = "Омнизин"
	enname = "Omnizine"
	description = "Slowly heals all damage types. Overdose will cause damage in all types instead."
	reagent_state = LIQUID
	color = "#DCDCDC"
	metabolization_rate = 0.25 * REAGENTS_METABOLISM
	overdose_threshold = 60
	var/healing = 0.5
	ph = 2
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/medicine/omnizine/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.adjustToxLoss(-healing * REM * delta_time, 0)
	M.adjustOxyLoss(-healing * REM * delta_time, 0)
	M.adjustBruteLoss(-healing * REM * delta_time, 0)
	M.adjustFireLoss(-healing * REM * delta_time, 0)
	..()
	. = TRUE

/datum/reagent/medicine/omnizine/overdose_process(mob/living/M, delta_time, times_fired)
	M.adjustToxLoss(1.5 * REM * delta_time, FALSE)
	M.adjustOxyLoss(1.5 * REM * delta_time, FALSE)
	M.adjustBruteLoss(1.5 * REM * delta_time, FALSE, FALSE, BODYPART_ORGANIC)
	M.adjustFireLoss(1.5 * REM * delta_time, FALSE, FALSE, BODYPART_ORGANIC)
	..()
	. = TRUE

/datum/reagent/medicine/omnizine/protozine
	name = "Протозин"
	enname = "Protozine"
	description = "A less environmentally friendly and somewhat weaker variant of omnizine."
	color = "#d8c7b7"
	healing = 0.2
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/medicine/calomel
	name = "Каломел"
	enname = "Potassium Iodide"
	description = "Quickly purges the body of all chemicals. Toxin damage is dealt if the patient is in good condition."
	reagent_state = LIQUID
	color = "#19C832"
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	taste_description = "кислота"
	ph = 1.5
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/medicine/calomel/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	for(var/datum/reagent/toxin/R in M.reagents.reagent_list)
		M.reagents.remove_reagent(R.type, 3 * REM * delta_time)
	if(M.health > 20)
		M.adjustToxLoss(1 * REM * delta_time, 0)
		. = TRUE
	..()

/datum/reagent/medicine/potass_iodide
	name = "Йодид Калия"
	enname = "Potassium Iodide"
	description = "Efficiently restores low radiation damage."
	reagent_state = LIQUID
	color = "#BAA15D"
	metabolization_rate = 2 * REAGENTS_METABOLISM
	ph = 12 //It's a reducing agent
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/medicine/potass_iodide/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(M.radiation > 0)
		M.radiation -= min(8 * REM * delta_time, M.radiation)
	..()

/datum/reagent/medicine/pen_acid
	name = "Пентетовая кислота"
	enname = "Pentetic Acid"
	description = "ДТПА, она же диэтилентриаминпентауксусная кислота. Вещество выводящее из тела токсины, радиацию и химикаты."
	reagent_state = LIQUID
	color = "#E6FFF0"
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	ph = 1 //One of the best buffers, NEVERMIND!
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/medicine/pen_acid/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.radiation -= (max(M.radiation - RAD_MOB_SAFE, 0) / 50) * REM * delta_time
	M.adjustToxLoss(-2 * REM * delta_time, 0)
	for(var/datum/reagent/R in M.reagents.reagent_list)
		if(R != src)
			M.reagents.remove_reagent(R.type, 2 * REM * delta_time)
	..()
	. = TRUE

/datum/reagent/medicine/sal_acid
	name = "Салициловая Кислота"
	enname = "Salicylic Acid"
	description = "Stimulates the healing of severe bruises. Extremely rapidly heals severe bruising and slowly heals minor ones. Overdose will worsen existing bruising."
	reagent_state = LIQUID
	color = "#D2D2D2"
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	overdose_threshold = 25
	ph = 2.1
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/medicine/sal_acid/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(M.getBruteLoss() > 25)
		M.adjustBruteLoss(-4 * REM * delta_time, 0)
	else
		M.adjustBruteLoss(-0.5 * REM * delta_time, 0)
	..()
	. = TRUE

/datum/reagent/medicine/sal_acid/overdose_process(mob/living/M, delta_time, times_fired)
	if(M.getBruteLoss()) //It only makes existing bruises worse
		M.adjustBruteLoss(4.5 * REM * delta_time, FALSE, FALSE, BODYPART_ORGANIC) // it's going to be healing either 4 or 0.5
		. = TRUE
	..()

/datum/reagent/medicine/salbutamol
	name = "Сальбутамол"
	enname = "Salbutamol"
	description = "Rapidly restores oxygen deprivation as well as preventing more of it to an extent."
	reagent_state = LIQUID
	color = "#00FFFF"
	metabolization_rate = 0.25 * REAGENTS_METABOLISM
	ph = 2
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/medicine/salbutamol/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.adjustOxyLoss(-3 * REM * delta_time, 0)
	if(M.losebreath >= 4)
		M.losebreath -= 2 * REM * delta_time
	..()
	. = TRUE

/datum/reagent/medicine/ephedrine
	name = "Эфедрин"
	enname = "Ephedrine"
	description = "Increases stun resistance and movement speed, giving you hand cramps. Overdose deals toxin damage and inhibits breathing."
	reagent_state = LIQUID
	color = "#D2FFFA"
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	overdose_threshold = 30
	ph = 12
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	addiction_types = list(/datum/addiction/stimulants = 4) //1.6 per 2 seconds

/datum/reagent/medicine/ephedrine/on_mob_metabolize(mob/living/L)
	..()
	L.add_movespeed_modifier(/datum/movespeed_modifier/reagent/ephedrine)
	ADD_TRAIT(L, TRAIT_STUNRESISTANCE, type)

/datum/reagent/medicine/ephedrine/on_mob_end_metabolize(mob/living/L)
	L.remove_movespeed_modifier(/datum/movespeed_modifier/reagent/ephedrine)
	REMOVE_TRAIT(L, TRAIT_STUNRESISTANCE, type)
	..()

/datum/reagent/medicine/ephedrine/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(DT_PROB(10, delta_time) && iscarbon(M))
		var/obj/item/I = M.get_active_held_item()
		if(I && M.dropItemToGround(I))
			to_chat(M, span_notice("Мои руки дернулись и я выронил то, что держал в них!"))
			M.Jitter(10)

	M.AdjustAllImmobility(-20 * REM * delta_time)
	M.adjustStaminaLoss(-1 * REM * delta_time, FALSE)
	..()
	return TRUE

/datum/reagent/medicine/ephedrine/overdose_process(mob/living/M, delta_time, times_fired)
	if(DT_PROB(1, delta_time) && iscarbon(M))
		var/datum/disease/D = new /datum/disease/heart_failure
		M.ForceContractDisease(D)
		to_chat(M, span_userdanger("Уверен что ощутил как мое сердце пропустило удар.."))
		M.playsound_local(M, 'sound/effects/singlebeat.ogg', 100, 0)

	if(DT_PROB(3.5, delta_time))
		to_chat(M, span_notice("[pick("У меня очень сильно болит голова.", "Глазам больно.", "Мне сложно ровно стоять.", "По ощущениям мое сердце буквально вырывается из груди.")]"))

	if(DT_PROB(18, delta_time))
		M.adjustToxLoss(1, 0)
		M.losebreath++
		. = TRUE
	return TRUE


/datum/reagent/medicine/diphenhydramine
	name = "Дифенгидрамин"
	enname = "Diphenhydramine"
	description = "Rapidly purges the body of Histamine and reduces jitteriness. Slight chance of causing drowsiness."
	reagent_state = LIQUID
	color = "#64FFE6"
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	ph = 11.5
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/medicine/diphenhydramine/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(DT_PROB(5, delta_time))
		M.drowsyness++
	M.jitteriness -= 1 * REM * delta_time
	holder.remove_reagent(/datum/reagent/toxin/histamine, 3 * REM * delta_time)
	..()

/datum/reagent/medicine/morphine
	name = "Морфий"
	enname = "Morphine"
	description = "A painkiller that allows the patient to move at full speed even when injured. Causes drowsiness and eventually unconsciousness in high doses. Overdose will cause a variety of effects, ranging from minor to lethal."
	reagent_state = LIQUID
	color = "#A9FBFB"
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	overdose_threshold = 30
	ph = 8.96
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	addiction_types = list(/datum/addiction/opiods = 10)

/datum/reagent/medicine/morphine/on_mob_metabolize(mob/living/L)
	..()
	L.add_movespeed_mod_immunities(type, /datum/movespeed_modifier/damage_slowdown)

/datum/reagent/medicine/morphine/on_mob_end_metabolize(mob/living/L)
	L.remove_movespeed_mod_immunities(type, /datum/movespeed_modifier/damage_slowdown)
	..()

/datum/reagent/medicine/morphine/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(current_cycle >= 5)
		SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "numb", /datum/mood_event/narcotic_medium, name)
	switch(current_cycle)
		if(11)
			to_chat(M, span_warning("Начал ощущать усталость...")  )
		if(12 to 24)
			M.drowsyness += 1 * REM * delta_time
		if(24 to INFINITY)
			M.Sleeping(40 * REM * delta_time)
			. = TRUE
	..()

/datum/reagent/medicine/morphine/overdose_process(mob/living/M, delta_time, times_fired)
	if(DT_PROB(18, delta_time))
		M.drop_all_held_items()
		M.Dizzy(2)
		M.Jitter(2)
	..()


/datum/reagent/medicine/oculine
	name = "Окулин"
	enname = "Oculine"
	description = "Quickly restores eye damage, cures nearsightedness, and has a chance to restore vision to the blind."
	reagent_state = LIQUID
	color = "#404040" //oculine is dark grey, inacusiate is light grey
	metabolization_rate = 0.25 * REAGENTS_METABOLISM
	taste_description = "тусклый токсин"
	ph = 10
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/medicine/oculine/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	var/obj/item/organ/eyes/eyes = M.getorganslot(ORGAN_SLOT_EYES)
	M.adjust_blindness(-2 * REM * delta_time)
	M.adjust_blurriness(-2 * REM * delta_time)
	if (!eyes)
		return
	eyes.applyOrganDamage(-2 * REM * delta_time)
	if(HAS_TRAIT_FROM(M, TRAIT_BLIND, EYE_DAMAGE))
		if(DT_PROB(10, delta_time))
			to_chat(M, span_warning("Ко мне постепенно возвращается зрение..."))
			M.cure_blind(EYE_DAMAGE)
			M.cure_nearsighted(EYE_DAMAGE)
			M.blur_eyes(35)
	else if(HAS_TRAIT_FROM(M, TRAIT_NEARSIGHT, EYE_DAMAGE))
		to_chat(M, span_warning("В моем периферийном зрении рассеивается темнота."))
		M.cure_nearsighted(EYE_DAMAGE)
		M.blur_eyes(10)
	..()

/datum/reagent/medicine/inacusiate
	name = "Инакусиат"
	enname = "Inacusiate"
	description = "Rapidly repairs damage to the patient's ears to cure deafness, assuming the source of said deafness isn't from genetic mutations, chronic deafness, or a total defecit of ears." //by "chronic" deafness, we mean people with the "deaf" quirk
	color = "#606060" // ditto
	ph = 2
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/medicine/inacusiate/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	var/obj/item/organ/ears/ears = M.getorganslot(ORGAN_SLOT_EARS)
	ears.adjustEarDamage(-4 * REM * delta_time, -4 * REM * delta_time)
	..()

/datum/reagent/medicine/atropine
	name = "Атропин"
	enname = "Atropine"
	description = "If a patient is in critical condition, rapidly heals all damage types as well as regulating oxygen in the body. Excellent for stabilizing wounded patients."
	reagent_state = LIQUID
	color = "#1D3535" //slightly more blue, like epinephrine
	metabolization_rate = 0.25 * REAGENTS_METABOLISM
	overdose_threshold = 35
	ph = 12
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/medicine/atropine/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(M.health <= M.crit_threshold)
		M.adjustToxLoss(-2 * REM * delta_time, 0)
		M.adjustBruteLoss(-2* REM * delta_time, 0)
		M.adjustFireLoss(-2 * REM * delta_time, 0)
		M.adjustOxyLoss(-5 * REM * delta_time, 0)
		. = TRUE
	M.losebreath = 0
	if(DT_PROB(10, delta_time))
		M.Dizzy(5)
		M.Jitter(5)
	..()

/datum/reagent/medicine/atropine/overdose_process(mob/living/M, delta_time, times_fired)
	M.adjustToxLoss(0.5 * REM * delta_time, 0)
	. = TRUE
	M.Dizzy(1 * REM * delta_time)
	M.Jitter(1 * REM * delta_time)
	..()

/datum/reagent/medicine/epinephrine
	name = "Адреналин"
	enname = "Epinephrine"
	description = "Very minor boost to stun resistance. Slowly heals damage if a patient is in critical condition, as well as regulating oxygen loss. Overdose causes weakness and toxin damage."
	reagent_state = LIQUID
	color = "#D2FFFA"
	metabolization_rate = 0.25 * REAGENTS_METABOLISM
	overdose_threshold = 30
	ph = 10.2
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/medicine/epinephrine/on_mob_metabolize(mob/living/carbon/M)
	..()
	ADD_TRAIT(M, TRAIT_NOCRITDAMAGE, type)

/datum/reagent/medicine/epinephrine/on_mob_end_metabolize(mob/living/carbon/M)
	REMOVE_TRAIT(M, TRAIT_NOCRITDAMAGE, type)
	..()

/datum/reagent/medicine/epinephrine/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	. = TRUE
	if(holder.has_reagent(/datum/reagent/toxin/lexorin))
		holder.remove_reagent(/datum/reagent/toxin/lexorin, 2 * REM * delta_time)
		holder.remove_reagent(/datum/reagent/medicine/epinephrine, 1 * REM * delta_time)
		if(DT_PROB(10, delta_time))
			holder.add_reagent(/datum/reagent/toxin/histamine, 4)
		..()
		return
	if(M.health <= M.crit_threshold)
		M.adjustToxLoss(-0.5 * REM * delta_time, 0)
		M.adjustBruteLoss(-0.5 * REM * delta_time, 0)
		M.adjustFireLoss(-0.5 * REM * delta_time, 0)
		M.adjustOxyLoss(-0.5 * REM * delta_time, 0)
	if(M.losebreath >= 4)
		M.losebreath -= 2 * REM * delta_time
	if(M.losebreath < 0)
		M.losebreath = 0
	M.adjustStaminaLoss(-0.5 * REM * delta_time, 0)
	if(DT_PROB(10, delta_time))
		M.AdjustAllImmobility(-20)
	..()

/datum/reagent/medicine/epinephrine/overdose_process(mob/living/M, delta_time, times_fired)
	if(DT_PROB(18, REM * delta_time))
		M.adjustStaminaLoss(2.5, 0)
		M.adjustToxLoss(1, 0)
		M.losebreath++
		. = TRUE
	..()

/datum/reagent/medicine/strange_reagent
	name = "Странный Реагент"
	enname = "Strange Reagent"
	description = "A miracle drug capable of bringing the dead back to life. Works topically unless anotamically complex, in which case works orally. Only works if the target has less than 200 total brute and burn damage and hasn't been husked and requires more reagent depending on damage inflicted. Causes damage to the living."
	reagent_state = LIQUID
	color = "#A0E85E"
	metabolization_rate = 1.25 * REAGENTS_METABOLISM
	taste_description = "магниты"
	harmful = TRUE
	ph = 0.5
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED


// FEED ME SEYMOUR
/datum/reagent/medicine/strange_reagent/on_hydroponics_apply(obj/item/seeds/myseed, datum/reagents/chems, obj/machinery/hydroponics/mytray, mob/user)
	. = ..()
	if(chems.has_reagent(type, 1))
		mytray.spawnplant()

/datum/reagent/medicine/strange_reagent/expose_mob(mob/living/exposed_mob, methods=TOUCH, reac_volume)
	if(exposed_mob.stat != DEAD)
		return ..()
	if(exposed_mob.suiciding || exposed_mob.hellbound) //they are never coming back
		exposed_mob.visible_message(span_warning("Тело [exposed_mob] не реагирует..."))
		return
	if(iscarbon(exposed_mob) && !(methods & INGEST)) //simplemobs can still be splashed
		return ..()
	var/amount_to_revive = round((exposed_mob.getBruteLoss()+exposed_mob.getFireLoss())/20)
	if(exposed_mob.getBruteLoss()+exposed_mob.getFireLoss() >= 200 || HAS_TRAIT(exposed_mob, TRAIT_HUSK) || reac_volume < amount_to_revive) //body will die from brute+burn on revive or you haven't provided enough to revive.
		exposed_mob.visible_message(span_warning("Тело [exposed_mob] недолго бьется в конвульсиях, а затем вновь замирает."))
		exposed_mob.do_jitter_animation(10)
		return
	exposed_mob.visible_message(span_warning("Тело [exposed_mob] начинает биться в конвульсиях!"))
	exposed_mob.notify_ghost_cloning("Your body is being revived with Strange Reagent!")
	exposed_mob.do_jitter_animation(10)
	var/excess_healing = 5*(reac_volume-amount_to_revive) //excess reagent will heal blood and organs across the board
	addtimer(CALLBACK(exposed_mob, TYPE_PROC_REF(/mob/living/carbon, do_jitter_animation), 10), 40) //jitter immediately, then again after 4 and 8 seconds
	addtimer(CALLBACK(exposed_mob, TYPE_PROC_REF(/mob/living/carbon, do_jitter_animation), 10), 80)
	addtimer(CALLBACK(exposed_mob, TYPE_PROC_REF(/mob/living, revive), FALSE, FALSE, excess_healing), 79)
	..()

/datum/reagent/medicine/strange_reagent/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	var/damage_at_random = rand(0, 250)/100 //0 to 2.5
	M.adjustBruteLoss(damage_at_random * REM * delta_time, FALSE)
	M.adjustFireLoss(damage_at_random * REM * delta_time, FALSE)
	..()
	. = TRUE

/datum/reagent/medicine/mannitol
	name = "Маннитол"
	enname = "Mannitol"
	description = "Efficiently restores brain damage."
	taste_description = "приятная сладость"
	color = "#A0A0A0" //mannitol is light grey, neurine is lighter grey
	ph = 10.4
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/medicine/mannitol/on_mob_life(mob/living/carbon/C, delta_time, times_fired)
	C.adjustOrganLoss(ORGAN_SLOT_BRAIN, -2 * REM * delta_time)
	..()

//Having mannitol in you will pause the brain damage from brain tumor (so it heals an even 2 brain damage instead of 1.8)
/datum/reagent/medicine/mannitol/on_mob_metabolize(mob/living/carbon/C)
	. = ..()
	ADD_TRAIT(C, TRAIT_TUMOR_SUPPRESSED, TRAIT_GENERIC)

/datum/reagent/medicine/mannitol/on_mob_end_metabolize(mob/living/carbon/C)
	REMOVE_TRAIT(C, TRAIT_TUMOR_SUPPRESSED, TRAIT_GENERIC)
	. = ..()

/datum/reagent/medicine/neurine
	name = "Нейрин"
	enname = "Neurine"
	description = "Reacts with neural tissue, helping reform damaged connections. Can cure minor traumas."
	color = "#C0C0C0" //ditto
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED


/datum/reagent/medicine/neurine/on_mob_add(mob/living/L, amount)
	. = ..()
	ADD_TRAIT(L, TRAIT_ANTICONVULSANT, name)

/datum/reagent/medicine/neurine/on_mob_delete(mob/living/L)
	. = ..()
	REMOVE_TRAIT(L, TRAIT_ANTICONVULSANT, name)

/datum/reagent/medicine/neurine/on_mob_life(mob/living/carbon/C, delta_time, times_fired)
	if(holder.has_reagent(/datum/reagent/consumable/ethanol/neurotoxin))
		holder.remove_reagent(/datum/reagent/consumable/ethanol/neurotoxin, 5 * REM * delta_time)
	if(DT_PROB(8, delta_time))
		C.cure_trauma_type(resilience = TRAUMA_RESILIENCE_BASIC)
	..()

/datum/reagent/medicine/mutadone
	name = "Мутадон"
	enname = "Mutadone"
	description = "Removes jitteriness and restores genetic defects."
	color = "#5096C8"
	taste_description = "кислота"
	ph = 2
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/medicine/mutadone/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.jitteriness = 0
	if(M.has_dna())
		M.dna.remove_all_mutations(list(MUT_NORMAL, MUT_EXTRA), TRUE)
	if(!QDELETED(M)) //We were a monkey, now a human
		..()

/datum/reagent/medicine/antihol
	name = "Антиголь"
	enname = "Antihol"
	description = "Purges alcoholic substance from the patient's body and eliminates its side effects."
	color = "#00B4C8"
	taste_description = "сырые яйца"
	ph = 4
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/medicine/antihol/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.dizziness = 0
	M.drowsyness = 0
	M.slurring = 0
	M.set_confusion(0)
	M.reagents.remove_all_type(/datum/reagent/consumable/ethanol, 3 * REM * delta_time, FALSE, TRUE)
	M.adjustToxLoss(-0.2 * REM * delta_time, 0)
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		H.drunkenness = max(H.drunkenness - (10 * REM * delta_time), 0)
	..()
	. = TRUE

/datum/reagent/medicine/stimulants
	name = "Стимуляторы"
	enname = "Stimulants"
	description = "Increases stun resistance and movement speed in addition to restoring minor damage and weakness. Overdose causes weakness and toxin damage."
	color = "#78008C"
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	overdose_threshold = 60
	ph = 8.7
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	addiction_types = list(/datum/addiction/stimulants = 4) //0.8 per 2 seconds

/datum/reagent/medicine/stimulants/on_mob_metabolize(mob/living/L)
	..()
	L.add_movespeed_modifier(/datum/movespeed_modifier/reagent/stimulants)
	ADD_TRAIT(L, TRAIT_STUNRESISTANCE, type)

/datum/reagent/medicine/stimulants/on_mob_end_metabolize(mob/living/L)
	L.remove_movespeed_modifier(/datum/movespeed_modifier/reagent/stimulants)
	REMOVE_TRAIT(L, TRAIT_STUNRESISTANCE, type)
	..()

/datum/reagent/medicine/stimulants/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(M.health < 50 && M.health > 0)
		M.adjustOxyLoss(-1 * REM * delta_time, 0)
		M.adjustToxLoss(-1 * REM * delta_time, 0)
		M.adjustBruteLoss(-1 * REM * delta_time, 0)
		M.adjustFireLoss(-1 * REM * delta_time, 0)
	M.AdjustAllImmobility(-60  * REM * delta_time)
	M.adjustStaminaLoss(-5 * REM * delta_time, 0)
	..()
	. = TRUE

/datum/reagent/medicine/stimulants/overdose_process(mob/living/M, delta_time, times_fired)
	if(DT_PROB(18, delta_time))
		M.adjustStaminaLoss(2.5, 0)
		M.adjustToxLoss(1, 0)
		M.losebreath++
		. = TRUE
	..()

/datum/reagent/medicine/insulin
	name = "Инсулин"
	enname = "Insulin"
	description = "Increases sugar depletion rates."
	reagent_state = LIQUID
	color = "#FFFFF0"
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	ph = 6.7
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/medicine/insulin/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(M.AdjustSleeping(-20 * REM * delta_time))
		. = TRUE
	holder.remove_reagent(/datum/reagent/consumable/sugar, 3 * REM * delta_time)
	..()

//Trek Chems, used primarily by medibots. Only heals a specific damage type, but is very efficient.

/datum/reagent/medicine/inaprovaline //is this used anywhere?
	name = "Инапровалин"
	enname = "Inaprovaline"
	description = "Stabilizes the breathing of patients. Good for those in critical condition."
	reagent_state = LIQUID
	color = "#A4D8D8"
	ph = 8.5
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/medicine/inaprovaline/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(M.losebreath >= 5)
		M.losebreath -= 5 * REM * delta_time
	..()

/datum/reagent/medicine/regen_jelly
	name = "Регенеративное Желе"
	enname = "Regenerative Jelly"
	description = "Gradually regenerates all types of damage, without harming slime anatomy."
	reagent_state = LIQUID
	color = "#CC23FF"
	taste_description = "желе"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/medicine/regen_jelly/expose_mob(mob/living/exposed_mob, reac_volume)
	. = ..()
	if(!ishuman(exposed_mob) || (reac_volume < 0.5))
		return

	var/mob/living/carbon/human/exposed_human = exposed_mob
	exposed_human.hair_color = "C2F"
	exposed_human.facial_hair_color = "C2F"
	exposed_human.update_hair()

/datum/reagent/medicine/regen_jelly/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.adjustBruteLoss(-1.5 * REM * delta_time, 0)
	M.adjustFireLoss(-1.5 * REM * delta_time, 0)
	M.adjustOxyLoss(-1.5 * REM * delta_time, 0)
	M.adjustToxLoss(-1.5 * REM * delta_time, 0, TRUE) //heals TOXINLOVERs
	..()
	. = TRUE

/datum/reagent/medicine/syndicate_nanites //Used exclusively by Syndicate medical cyborgs
	name = "Восстанавливающие Наниты"
	enname = "Restorative Nanites"
	description = "Miniature medical robots that swiftly restore bodily damage."
	reagent_state = SOLID
	color = "#555555"
	overdose_threshold = 30
	ph = 11
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/medicine/syndicate_nanites/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.adjustBruteLoss(-5 * REM * delta_time, 0) //A ton of healing - this is a 50 telecrystal investment.
	M.adjustFireLoss(-5 * REM * delta_time, 0)
	M.adjustOxyLoss(-15 * REM * delta_time, 0)
	M.adjustToxLoss(-5 * REM * delta_time, 0)
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, -15 * REM * delta_time)
	M.adjustCloneLoss(-3 * REM * delta_time, 0)
	..()
	. = TRUE

/datum/reagent/medicine/syndicate_nanites/overdose_process(mob/living/carbon/M, delta_time, times_fired) //wtb flavortext messages that hint that you're vomitting up robots
	if(DT_PROB(13, delta_time))
		M.reagents.remove_reagent(type, metabolization_rate*15) // ~5 units at a rate of 0.4 but i wanted a nice number in code
		M.vomit(20) // nanite safety protocols make your body expel them to prevent harmies
	..()
	. = TRUE

/datum/reagent/medicine/earthsblood //Created by ambrosia gaia plants
	name = "Кровь Земли"
	enname = "Earthsblood"
	description = "Ichor from an extremely powerful plant. Great for restoring wounds, but it's a little heavy on the brain. For some strange reason, it also induces temporary pacifism in those who imbibe it and semi-permanent pacifism in those who overdose on it."
	color = "#FFAF00"
	metabolization_rate = REAGENTS_METABOLISM //Math is based on specific metab rate so we want this to be static AKA if define or medicine metab rate changes, we want this to stay until we can rework calculations.
	overdose_threshold = 25
	ph = 11
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	addiction_types = list(/datum/addiction/hallucinogens = 14)

/datum/reagent/medicine/earthsblood/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(current_cycle <= 25) //10u has to be processed before u get into THE FUN ZONE
		M.adjustBruteLoss(-1 * REM * delta_time, 0)
		M.adjustFireLoss(-1 * REM * delta_time, 0)
		M.adjustOxyLoss(-0.5 * REM * delta_time, 0)
		M.adjustToxLoss(-0.5 * REM * delta_time, 0)
		M.adjustCloneLoss(-0.1 * REM * delta_time, 0)
		M.adjustStaminaLoss(-0.5 * REM * delta_time, 0)
		M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 1 * REM * delta_time, 150) //This does, after all, come from ambrosia, and the most powerful ambrosia in existence, at that!
	else
		M.adjustBruteLoss(-5 * REM * delta_time, 0) //slow to start, but very quick healing once it gets going
		M.adjustFireLoss(-5 * REM * delta_time, 0)
		M.adjustOxyLoss(-3 * REM * delta_time, 0)
		M.adjustToxLoss(-3 * REM * delta_time, 0)
		M.adjustCloneLoss(-1 * REM * delta_time, 0)
		M.adjustStaminaLoss(-3 * REM * delta_time, 0)
		M.jitteriness = clamp(M.jitteriness + (3 * REM * delta_time), 0, 30)
		M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 2 * REM * delta_time, 150)
		if(DT_PROB(5, delta_time))
			M.say(pick("Yeah, well, you know, that's just, like, uh, your opinion, man.", "Am I glad he's frozen in there and that we're out here, and that he's the sheriff and that we're frozen out here, and that we're in there, and I just remembered, we're out here. What I wanna know is: Where's the caveman?", "It ain't me, it ain't me...", "Make love, not war!", "Stop, hey, what's that sound? Everybody look what's going down...", "Do you believe in magic in a young girl's heart?"), forced = /datum/reagent/medicine/earthsblood)
	M.druggy = clamp(M.druggy + (10 * REM * delta_time), 0, 15 * REM * delta_time) //See above
	..()
	. = TRUE

/datum/reagent/medicine/earthsblood/on_mob_metabolize(mob/living/L)
	..()
	ADD_TRAIT(L, TRAIT_PACIFISM, type)

/datum/reagent/medicine/earthsblood/on_mob_end_metabolize(mob/living/L)
	REMOVE_TRAIT(L, TRAIT_PACIFISM, type)
	..()

/datum/reagent/medicine/earthsblood/overdose_process(mob/living/M, delta_time, times_fired)
	M.hallucination = clamp(M.hallucination + (5 * REM * delta_time), 0, 60)
	if(current_cycle > 25)
		M.adjustToxLoss(4 * REM * delta_time, 0)
		if(current_cycle > 100) //podpeople get out reeeeeeeeeeeeeeeeeeeee
			M.adjustToxLoss(6 * REM * delta_time, 0)
	if(iscarbon(M))
		var/mob/living/carbon/hippie = M
		hippie.gain_trauma(/datum/brain_trauma/severe/pacifism)
	..()
	. = TRUE

/datum/reagent/medicine/haloperidol
	name = "Галоперидол"
	enname = "Haloperidol"
	description = "Increases depletion rates for most stimulating/hallucinogenic drugs. Reduces druggy effects and jitteriness. Severe stamina regeneration penalty, causes drowsiness. Small chance of brain damage."
	reagent_state = LIQUID
	color = "#27870a"
	metabolization_rate = 0.4 * REAGENTS_METABOLISM
	ph = 4.3
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/medicine/haloperidol/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	for(var/datum/reagent/drug/R in M.reagents.reagent_list)
		M.reagents.remove_reagent(R.type, 5 * REM * delta_time)
	M.drowsyness += 2 * REM * delta_time
	if(M.jitteriness >= 3)
		M.jitteriness -= 3 * REM * delta_time
	if (M.hallucination >= 5)
		M.hallucination -= 5 * REM * delta_time
	if(DT_PROB(10, delta_time))
		M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 1, 50)
	M.adjustStaminaLoss(2.5 * REM * delta_time, 0)
	..()
	return TRUE

//used for changeling's adrenaline power
/datum/reagent/medicine/changelingadrenaline
	name = "Адреналин Генокрада"
	enname = "Changeling Adrenaline"
	description = "Reduces the duration of unconciousness, knockdown and stuns. Restores stamina, but deals toxin damage when overdosed."
	color = "#C1151D"
	overdose_threshold = 30
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/medicine/changelingadrenaline/on_mob_life(mob/living/carbon/metabolizer, delta_time, times_fired)
	..()
	metabolizer.AdjustAllImmobility(-20 * REM * delta_time)
	metabolizer.adjustStaminaLoss(-10 * REM * delta_time, 0)
	metabolizer.Jitter(10 * REM * delta_time)
	metabolizer.Dizzy(10 * REM * delta_time)
	return TRUE

/datum/reagent/medicine/changelingadrenaline/on_mob_metabolize(mob/living/L)
	..()
	ADD_TRAIT(L, TRAIT_SLEEPIMMUNE, type)
	ADD_TRAIT(L, TRAIT_STUNRESISTANCE, type)
	L.add_movespeed_mod_immunities(type, /datum/movespeed_modifier/damage_slowdown)

/datum/reagent/medicine/changelingadrenaline/on_mob_end_metabolize(mob/living/L)
	..()
	REMOVE_TRAIT(L, TRAIT_SLEEPIMMUNE, type)
	REMOVE_TRAIT(L, TRAIT_STUNRESISTANCE, type)
	L.remove_movespeed_mod_immunities(type, /datum/movespeed_modifier/damage_slowdown)
	L.Dizzy(0)
	L.Jitter(0)

/datum/reagent/medicine/changelingadrenaline/overdose_process(mob/living/metabolizer, delta_time, times_fired)
	metabolizer.adjustToxLoss(1 * REM * delta_time, 0)
	..()
	return TRUE

/datum/reagent/medicine/changelinghaste
	name = "Стимулятор Генокрада"
	enname = "Changeling Haste"
	description = "Drastically increases movement speed, but deals toxin damage."
	color = "#AE151D"
	metabolization_rate = 2.5 * REAGENTS_METABOLISM
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/medicine/changelinghaste/on_mob_metabolize(mob/living/L)
	..()
	L.add_movespeed_modifier(/datum/movespeed_modifier/reagent/changelinghaste)

/datum/reagent/medicine/changelinghaste/on_mob_end_metabolize(mob/living/L)
	L.remove_movespeed_modifier(/datum/movespeed_modifier/reagent/changelinghaste)
	..()

/datum/reagent/medicine/changelinghaste/on_mob_life(mob/living/carbon/metabolizer, delta_time, times_fired)
	metabolizer.adjustToxLoss(2 * REM * delta_time, 0)
	..()
	return TRUE

/datum/reagent/medicine/higadrite
	name = "Хигадрит"
	enname = "Higadrite"
	description = "A medication utilized to treat ailing livers."
	color = "#FF3542"
	self_consuming = TRUE
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/medicine/higadrite/on_mob_metabolize(mob/living/M)
	. = ..()
	ADD_TRAIT(M, TRAIT_STABLELIVER, type)

/datum/reagent/medicine/higadrite/on_mob_end_metabolize(mob/living/M)
	..()
	REMOVE_TRAIT(M, TRAIT_STABLELIVER, type)

/datum/reagent/medicine/cordiolis_hepatico
	name = "Печеночный Кориолис"
	enname = "Cordiolis Hepatico"
	description = "A strange, pitch-black reagent that seems to absorb all light. Effects unknown."
	color = "#000000"
	self_consuming = TRUE
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/medicine/cordiolis_hepatico/on_mob_add(mob/living/M)
	..()
	ADD_TRAIT(M, TRAIT_STABLELIVER, type)
	ADD_TRAIT(M, TRAIT_STABLEHEART, type)

/datum/reagent/medicine/cordiolis_hepatico/on_mob_end_metabolize(mob/living/M)
	..()
	REMOVE_TRAIT(M, TRAIT_STABLEHEART, type)
	REMOVE_TRAIT(M, TRAIT_STABLELIVER, type)

/datum/reagent/medicine/muscle_stimulant
	name = "Мышечный Стимулятор"
	enname = "Muscle Stimulant"
	description = "A potent chemical that allows someone under its influence to be at full physical ability even when under massive amounts of pain."
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/medicine/muscle_stimulant/on_mob_metabolize(mob/living/L)
	. = ..()
	L.add_movespeed_mod_immunities(type, /datum/movespeed_modifier/damage_slowdown)

/datum/reagent/medicine/muscle_stimulant/on_mob_end_metabolize(mob/living/L)
	. = ..()
	L.remove_movespeed_mod_immunities(type, /datum/movespeed_modifier/damage_slowdown)

/datum/reagent/medicine/modafinil
	name = "Модафинил"
	enname = "Modafinil"
	description = "Long-lasting sleep suppressant that very slightly reduces stun and knockdown times. Overdosing has horrendous side effects and deals lethal oxygen damage, will knock you unconscious if not dealt with."
	reagent_state = LIQUID
	color = "#BEF7D8" // palish blue white
	metabolization_rate = 0.1 * REAGENTS_METABOLISM
	overdose_threshold = 20 // with the random effects this might be awesome or might kill you at less than 10u (extensively tested)
	taste_description = "соль" // it actually does taste salty
	var/overdose_progress = 0 // to track overdose progress
	ph = 7.89
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/medicine/modafinil/on_mob_metabolize(mob/living/M)
	ADD_TRAIT(M, TRAIT_SLEEPIMMUNE, type)
	..()

/datum/reagent/medicine/modafinil/on_mob_end_metabolize(mob/living/M)
	REMOVE_TRAIT(M, TRAIT_SLEEPIMMUNE, type)
	..()

/datum/reagent/medicine/modafinil/on_mob_life(mob/living/carbon/metabolizer, delta_time, times_fired)
	if(!overdosed) // We do not want any effects on OD
		overdose_threshold = overdose_threshold + ((rand(-10, 10) / 10) * REM * delta_time) // for extra fun
		metabolizer.AdjustAllImmobility(-5 * REM * delta_time)
		metabolizer.adjustStaminaLoss(-0.5 * REM * delta_time, 0)
		metabolizer.Jitter(1)
		metabolization_rate = 0.005 * REAGENTS_METABOLISM * rand(5, 20) // randomizes metabolism between 0.02 and 0.08 per second
		. = TRUE
	..()

/datum/reagent/medicine/modafinil/overdose_start(mob/living/M)
	to_chat(M, span_userdanger("Ощущаю ужасную отдышку и нахлынувшую панику!"))
	metabolization_rate = 0.025 * REAGENTS_METABOLISM // sets metabolism to 0.01 per tick on overdose

/datum/reagent/medicine/modafinil/overdose_process(mob/living/M, delta_time, times_fired)
	overdose_progress++
	switch(overdose_progress)
		if(1 to 40)
			M.jitteriness = min(M.jitteriness + (1 * REM * delta_time), 10)
			M.stuttering = min(M.stuttering + (1 * REM * delta_time), 10)
			M.Dizzy(5 * REM * delta_time)
			if(DT_PROB(30, delta_time))
				M.losebreath++
		if(41 to 80)
			M.adjustOxyLoss(0.1 * REM * delta_time, 0)
			M.adjustStaminaLoss(0.1 * REM * delta_time, 0)
			M.jitteriness = min(M.jitteriness + (1 * REM * delta_time), 20)
			M.stuttering = min(M.stuttering + (1 * REM * delta_time), 20)
			M.Dizzy(10 * REM * delta_time)
			if(DT_PROB(30, delta_time))
				M.losebreath++
			if(DT_PROB(10, delta_time))
				to_chat(M, span_userdanger("Внезапно случился припадок!"))
				M.emote("moan")
				M.Paralyze(20) // you should be in a bad spot at this point unless epipen has been used
		if(81)
			to_chat(M, span_userdanger("Слишком устал, не могу так дальше!")) // at this point you will eventually die unless you get charcoal
			M.adjustOxyLoss(0.1*REM * delta_time, 0)
			M.adjustStaminaLoss(0.1*REM * delta_time, 0)
		if(82 to INFINITY)
			M.Sleeping(100 * REM * delta_time)
			M.adjustOxyLoss(1.5 * REM * delta_time, 0)
			M.adjustStaminaLoss(1.5 * REM * delta_time, 0)
	..()
	return TRUE

/datum/reagent/medicine/psicodine
	name = "Псикодин"
	enname = "Psicodine"
	description = "Suppresses anxiety and other various forms of mental distress. Overdose causes hallucinations and minor toxin damage."
	reagent_state = LIQUID
	color = "#07E79E"
	metabolization_rate = 0.25 * REAGENTS_METABOLISM
	overdose_threshold = 30
	ph = 9.12
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/medicine/psicodine/on_mob_metabolize(mob/living/L)
	..()
	ADD_TRAIT(L, TRAIT_FEARLESS, type)

/datum/reagent/medicine/psicodine/on_mob_end_metabolize(mob/living/L)
	REMOVE_TRAIT(L, TRAIT_FEARLESS, type)
	..()

/datum/reagent/medicine/psicodine/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.jitteriness = max(M.jitteriness - (6 * REM * delta_time), 0)
	M.dizziness = max(M.dizziness - (6 * REM * delta_time), 0)
	M.set_confusion(max(M.get_confusion() - (6 * REM * delta_time), 0))
	M.disgust = max(M.disgust - (6 * REM * delta_time), 0)
	var/datum/component/mood/mood = M.GetComponent(/datum/component/mood)
	if(mood != null && mood.sanity <= SANITY_NEUTRAL) // only take effect if in negative sanity and then...
		mood.setSanity(min(mood.sanity + (5 * REM * delta_time), SANITY_NEUTRAL)) // set minimum to prevent unwanted spiking over neutral
	..()
	. = TRUE

/datum/reagent/medicine/psicodine/overdose_process(mob/living/M, delta_time, times_fired)
	M.hallucination = clamp(M.hallucination + (5 * REM * delta_time), 0, 60)
	M.adjustToxLoss(1 * REM * delta_time, 0)
	..()
	. = TRUE

/datum/reagent/medicine/metafactor
	name = "Фактор Метаболизма Митогенов"
	enname = "Mitogen Metabolism Factor"
	description = "This enzyme catalyzes the conversion of nutricious food into healing peptides."
	metabolization_rate = 0.0625  * REAGENTS_METABOLISM //slow metabolism rate so the patient can self heal with food even after the troph has metabolized away for amazing reagent efficency.
	reagent_state = SOLID
	color = "#FFBE00"
	overdose_threshold = 10
	inverse_chem_val = 0.1 //Shouldn't happen - but this is so looking up the chem will point to the failed type
	inverse_chem = /datum/reagent/impurity/probital_failed
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/medicine/metafactor/overdose_start(mob/living/carbon/M)
	metabolization_rate = 2  * REAGENTS_METABOLISM

/datum/reagent/medicine/metafactor/overdose_process(mob/living/carbon/M, delta_time, times_fired)
	if(DT_PROB(13, delta_time))
		M.vomit()
	..()

/datum/reagent/medicine/silibinin
	name = "Силбинин"
	enname = "Silibinin"
	description = "A thistle derrived hepatoprotective flavolignan mixture that help reverse damage to the liver."
	reagent_state = SOLID
	color = "#FFFFD0"
	metabolization_rate = 1.5 * REAGENTS_METABOLISM
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/medicine/silibinin/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.adjustOrganLoss(ORGAN_SLOT_LIVER, -2 * REM * delta_time)//Add a chance to cure liver trauma once implemented.
	..()
	. = TRUE

/datum/reagent/medicine/polypyr  //This is intended to be an ingredient in advanced chems.
	name = "Полипирилиевые олигомеры"
	enname = "Polypyrylium Oligomers"
	description = "A purple mixture of short polyelectrolyte chains not easily synthesized in the laboratory. It is valued as an intermediate in the synthesis of the cutting edge pharmaceuticals."
	reagent_state = SOLID
	color = "#9423FF"
	metabolization_rate = 0.25 * REAGENTS_METABOLISM
	overdose_threshold = 50
	taste_description = "онемение горечи"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/medicine/polypyr/on_mob_life(mob/living/carbon/M, delta_time, times_fired) //I wanted a collection of small positive effects, this is as hard to obtain as coniine after all.
	. = ..()
	M.adjustOrganLoss(ORGAN_SLOT_LUNGS, -0.25 * REM * delta_time)
	M.adjustBruteLoss(-0.35 * REM * delta_time, 0)
	return TRUE

/datum/reagent/medicine/polypyr/expose_mob(mob/living/carbon/human/exposed_human, methods=TOUCH, reac_volume)
	. = ..()
	if(!(methods & (TOUCH|VAPOR)) || !ishuman(exposed_human) || (reac_volume < 0.5))
		return
	exposed_human.hair_color = "92f"
	exposed_human.facial_hair_color = "92f"
	exposed_human.update_hair()

/datum/reagent/medicine/polypyr/overdose_process(mob/living/M, delta_time, times_fired)
	M.adjustOrganLoss(ORGAN_SLOT_LUNGS, 0.5 * REM * delta_time)
	..()
	. = TRUE

/datum/reagent/medicine/granibitaluri
	name = "Гранибитарал" //achieve "GRANular" amounts of C2
	enname = "Granibitaluri"
	description = "A mild painkiller useful as an additive alongside more potent medicines. Speeds up the healing of small wounds and burns, but is ineffective at treating severe injuries. Extremely large doses are toxic, and may eventually cause liver failure."
	color = "#E0E0E0"
	reagent_state = LIQUID
	overdose_threshold = 50
	metabolization_rate = 0.5 * REAGENTS_METABOLISM //same as C2s
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/medicine/granibitaluri/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	var/healamount = max(0.5 - round(0.01 * (M.getBruteLoss() + M.getFireLoss()), 0.1), 0) //base of 0.5 healing per cycle and loses 0.1 healing for every 10 combined brute/burn damage you have
	M.adjustBruteLoss(-healamount * REM * delta_time, 0)
	M.adjustFireLoss(-healamount * REM * delta_time, 0)
	..()
	. = TRUE

/datum/reagent/medicine/granibitaluri/overdose_process(mob/living/M, delta_time, times_fired)
	. = TRUE
	M.adjustOrganLoss(ORGAN_SLOT_LIVER, 0.2 * REM * delta_time)
	M.adjustToxLoss(0.2 * REM * delta_time, FALSE) //Only really deadly if you eat over 100u
	..()

/datum/reagent/medicine/badstims  //These are bad for combat on purpose. Used in adrenal implant.
	name = "Экспериментальные Стимуляторы"
	enname = "bad stimulant"
	description = "Experimental Stimulants designed to get you away from trouble."
	reagent_state = LIQUID
	color = "#F5F5F5"

/datum/reagent/medicine/badstims/on_mob_life(mob/living/carbon/M)
	..()
	if(prob(30) && iscarbon(M))
		var/obj/item/I = M.get_active_held_item()
		if(I && M.dropItemToGround(I))
			to_chat(M, span_notice("Мои руки дернулись и я выронил то, что держал в них!"))
	M.adjustStaminaLoss(-10, 0)
	M.Jitter(10)
	M.Dizzy(15)

/datum/reagent/medicine/badstims/on_mob_metabolize(mob/living/L)
	..()
	ADD_TRAIT(L, TRAIT_SLEEPIMMUNE, type)
	ADD_TRAIT(L, TRAIT_STUNRESISTANCE, type)
	L.add_movespeed_modifier(/datum/movespeed_modifier/reagent/badstims)
	L.add_movespeed_mod_immunities(type, /datum/movespeed_modifier/damage_slowdown)

/datum/reagent/medicine/badstims/on_mob_end_metabolize(mob/living/L)
	..()
	REMOVE_TRAIT(L, TRAIT_SLEEPIMMUNE, type)
	REMOVE_TRAIT(L, TRAIT_STUNRESISTANCE, type)
	L.remove_movespeed_modifier(/datum/movespeed_modifier/reagent/badstims)
	L.remove_movespeed_mod_immunities(type, /datum/movespeed_modifier/damage_slowdown)
	L.Dizzy(0)
	L.Jitter(0)

// helps bleeding wounds clot faster
/datum/reagent/medicine/coagulant
	name = "Сангурит"
	enname = "Sanguirite"
	description = "A proprietary coagulant used to help bleeding wounds clot faster."
	reagent_state = LIQUID
	color = "#bb2424"
	metabolization_rate = 0.25 * REAGENTS_METABOLISM
	overdose_threshold = 20
	/// The bloodiest wound that the patient has will have its blood_flow reduced by about half this much each second
	var/clot_rate = 0.3
	/// While this reagent is in our bloodstream, we reduce all bleeding by this factor
	var/passive_bleed_modifier = 0.7
	/// For tracking when we tell the person we're no longer bleeding
	var/was_working
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/medicine/coagulant/on_mob_metabolize(mob/living/M)
	ADD_TRAIT(M, TRAIT_COAGULATING, /datum/reagent/medicine/coagulant)
	return ..()

/datum/reagent/medicine/coagulant/on_mob_end_metabolize(mob/living/M)
	REMOVE_TRAIT(M, TRAIT_COAGULATING, /datum/reagent/medicine/coagulant)
	return ..()

/datum/reagent/medicine/coagulant/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	. = ..()
	if(!M.blood_volume || !M.all_wounds)
		return

	var/datum/wound/bloodiest_wound

	for(var/i in M.all_wounds)
		var/datum/wound/iter_wound = i
		if(iter_wound.blood_flow)
			if(iter_wound.blood_flow > bloodiest_wound?.blood_flow)
				bloodiest_wound = iter_wound

	if(bloodiest_wound)
		if(!was_working)
			to_chat(M, span_green("Моя льющаяся кровь начинает сгущаться!"))
			was_working = TRUE
		bloodiest_wound.blood_flow = max(0, bloodiest_wound.blood_flow - (clot_rate * REM * delta_time))
	else if(was_working)
		was_working = FALSE

/datum/reagent/medicine/coagulant/overdose_process(mob/living/M, delta_time, times_fired)
	. = ..()
	if(!M.blood_volume)
		return

	if(DT_PROB(7.5, delta_time))
		M.losebreath += rand(2, 4)
		M.adjustOxyLoss(rand(1, 3))
		if(prob(30))
			to_chat(M, span_danger("Чувствую как кровь сворачивается в венах!"))
		else if(prob(10))
			to_chat(M, span_userdanger("Ощущение, будто бы моя кровь перестала течь!"))
			M.adjustOxyLoss(rand(3, 4))

		if(prob(50))
			var/obj/item/organ/lungs/our_lungs = M.getorganslot(ORGAN_SLOT_LUNGS)
			our_lungs.applyOrganDamage(1)
		else
			var/obj/item/organ/heart/our_heart = M.getorganslot(ORGAN_SLOT_HEART)
			our_heart.applyOrganDamage(1)

/datum/reagent/medicine/coagulant/on_mob_metabolize(mob/living/M)
	if(!ishuman(M))
		return

	var/mob/living/carbon/human/blood_boy = M
	blood_boy.physiology?.bleed_mod *= passive_bleed_modifier

/datum/reagent/medicine/coagulant/on_mob_end_metabolize(mob/living/M)
	if(was_working)
		to_chat(M, span_warning("Медикамент, сгущающий мою кровь, перестал действовать!"))
	if(!ishuman(M))
		return

	var/mob/living/carbon/human/blood_boy = M
	blood_boy.physiology?.bleed_mod /= passive_bleed_modifier

// i googled "natural coagulant" and a couple of results came up for banana peels, so after precisely 30 more seconds of research, i now dub grinding banana peels good for your blood
/datum/reagent/medicine/coagulant/banana_peel
	name = "Очищенная Банановая Кожура"
	enname = "Pulped Banana Peel"
	description = "Ancient Clown Lore says that pulped banana peels are good for your blood, but are you really going to take medical advice from a clown about bananas?"
	color = "#50531a" // rgb: 175, 175, 0
	taste_description = "horribly stringy, bitter pulp"
	glass_name = "glass of banana peel pulp"
	glass_desc = "Ancient Clown Lore says that pulped banana peels are good for your blood, but are you really going to take medical advice from a clown about bananas?"
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	clot_rate = 0.2
	passive_bleed_modifier = 0.8
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
