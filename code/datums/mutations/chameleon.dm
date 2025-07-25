//Chameleon causes the owner to slowly become transparent when not moving.
/datum/mutation/human/chameleon
	name = "Хамелеон"
	desc = "Геном изменяющий эпидермис носителя, позволяя ему сливаться окружающим пространством с течением времени."
	quality = POSITIVE
	difficulty = 16
	text_gain_indication = span_notice("Я как будто могу смотреть сквозь свою руку...")
	text_lose_indication = span_notice("Я более не прозрачен...")
	time_coeff = 5
	instability = 25

/datum/mutation/human/chameleon/on_acquiring(mob/living/carbon/human/owner)
	if(..())
		return
	owner.alpha = CHAMELEON_MUTATION_DEFAULT_TRANSPARENCY
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(on_move))
	RegisterSignal(owner, COMSIG_HUMAN_EARLY_UNARMED_ATTACK, PROC_REF(on_attack_hand))

/datum/mutation/human/chameleon/on_life(delta_time, times_fired)
	owner.alpha = max(owner.alpha - (12.5 * delta_time), 0)

/datum/mutation/human/chameleon/proc/on_move()
	SIGNAL_HANDLER

	owner.alpha = CHAMELEON_MUTATION_DEFAULT_TRANSPARENCY

/datum/mutation/human/chameleon/proc/on_attack_hand(atom/target, proximity)
	SIGNAL_HANDLER

	if(!proximity) //stops tk from breaking chameleon
		return
	owner.alpha = CHAMELEON_MUTATION_DEFAULT_TRANSPARENCY

/datum/mutation/human/chameleon/on_losing(mob/living/carbon/human/owner)
	if(..())
		return
	owner.alpha = 255
	UnregisterSignal(owner, COMSIG_MOVABLE_MOVED)
