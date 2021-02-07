/datum/disease/flu
	name = "The Flu"
	max_stages = 3
	spread_text = "Airborne"
	cure_text = "Spaceacillin"
	cures = list(/datum/reagent/medicine/spaceacillin)
	cure_chance = 10
	agent = "H13N1 flu virion"
	viable_mobtypes = list(/mob/living/carbon/human)
	permeability_mod = 0.75
	desc = "If left untreated the subject will feel quite unwell."
	severity = DISEASE_SEVERITY_MINOR


/datum/disease/flu/stage_act()
	. = ..()
	if(!.)
		return

	switch(stage)
		if(2)
			if(affected_mob.body_position == LYING_DOWN && prob(20))
				to_chat(affected_mob, "<span class='notice'>Я чувствую себя лучше.</span>")
				stage--
				return
			if(prob(1))
				affected_mob.emote("sneeze")
			if(prob(1))
				affected_mob.emote("cough")
			if(prob(1))
				to_chat(affected_mob, "<span class='danger'>У меня болят мышцы.</span>")
				if(prob(20))
					affected_mob.take_bodypart_damage(1, updating_health = FALSE)
			if(prob(1))
				to_chat(affected_mob, "<span class='danger'>У меня болит живот.</span>")
				if(prob(20))
					affected_mob.adjustToxLoss(1, FALSE)

		if(3)
			if(affected_mob.body_position == LYING_DOWN && prob(15))
				to_chat(affected_mob, "<span class='notice'>Я чувствую себя лучше.</span>")
				stage--
				return
			if(prob(1))
				affected_mob.emote("sneeze")
			if(prob(1))
				affected_mob.emote("cough")
			if(prob(1))
				to_chat(affected_mob, "<span class='danger'>У меня болят мышцы.</span>")
				if(prob(20))
					affected_mob.take_bodypart_damage(1, updating_health = FALSE)
			if(prob(1))
				to_chat(affected_mob, "<span class='danger'>У меня болит живот.</span>")
				if(prob(20))
					affected_mob.adjustToxLoss(1, FALSE)
