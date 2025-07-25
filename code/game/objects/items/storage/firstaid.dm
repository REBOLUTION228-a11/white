/* First aid storage
 * Contains:
 *		First Aid Kits
 * 		Pill Bottles
 *		Dice Pack (in a pill bottle)
 */

/*
 * First Aid Kits
 */
/obj/item/storage/firstaid
	name = "аптечка первой помощи"
	desc = "It's an emergency medical kit for those serious boo-boos."
	icon_state = "firstaid"
	icon = 'white/valtos/icons/items.dmi'
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	throw_speed = 3
	throw_range = 7
	var/empty = FALSE
	var/damagetype_healed //defines damage type of the medkit. General ones stay null. Used for medibot healing bonuses

/obj/item/storage/firstaid/regular
	icon_state = "firstaid"
	desc = "Содержит шовный и перевязочный материал для лечения легких травм."

/obj/item/storage/firstaid/regular/suicide_act(mob/living/carbon/user)
	user.visible_message(span_suicide("[user] begins giving [user.ru_na()]self aids with <b>[src.name]</b>! It looks like [user.p_theyre()] trying to commit suicide!"))
	return BRUTELOSS

/obj/item/storage/firstaid/regular/PopulateContents()
	if(empty)
		return
	var/static/items_inside = list(
		/obj/item/stack/medical/gauze = 1,
		/obj/item/stack/medical/suture = 2,
		/obj/item/stack/medical/mesh = 2,
		/obj/item/reagent_containers/hypospray/medipen = 1)
	generate_items_inside(items_inside,src)

/obj/item/storage/firstaid/emergency
	icon_state = "medbriefcase"
	name = "аварийная аптечка первой помощи"
	desc = "Максимально простой набор медикаментов для стабилизации пациента и последующей транспортировки в мед блок."

/obj/item/storage/firstaid/emergency/PopulateContents()
	if(empty)
		return
	var/static/items_inside = list(
		/obj/item/healthanalyzer/wound = 1,
		/obj/item/stack/medical/gauze = 1,
		/obj/item/stack/medical/suture/emergency = 1,
		/obj/item/stack/medical/ointment = 1,
		/obj/item/reagent_containers/hypospray/medipen/ekit = 2,
		/obj/item/storage/pill_bottle/iron = 1)
	generate_items_inside(items_inside,src)

/obj/item/storage/firstaid/medical
	name = "аптечка хирурга"
	icon_state = "firstaid_surgery"
	inhand_icon_state = "firstaid"
	desc = "Укладка с малым хирургическим набором и шовным материалом. Обладает гораздо большей вместительностью по сравнению с стандартной аптечкой."

/obj/item/storage/firstaid/medical/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_w_class = WEIGHT_CLASS_NORMAL //holds the same equipment as a medibelt
	STR.max_items = 14
	STR.max_combined_w_class = 24
	STR.set_holdable(list(
		/obj/item/healthanalyzer,
		/obj/item/dnainjector,
		/obj/item/reagent_containers/dropper,
		/obj/item/reagent_containers/glass/beaker,
		/obj/item/reagent_containers/glass/bottle,
		/obj/item/reagent_containers/pill,
		/obj/item/reagent_containers/syringe,
		/obj/item/reagent_containers/medigel,
		/obj/item/reagent_containers/spray,
		/obj/item/lighter,
		/obj/item/storage/fancy/cigarettes,
		/obj/item/storage/pill_bottle,
		/obj/item/stack/medical,
		/obj/item/flashlight/pen,
		/obj/item/extinguisher/mini,
		/obj/item/reagent_containers/hypospray,
		/obj/item/sensor_device,
		/obj/item/radio,
		/obj/item/clothing/gloves/,
		/obj/item/lazarus_injector,
		/obj/item/bikehorn/rubberducky,
		/obj/item/clothing/mask/surgical,
		/obj/item/clothing/mask/breath,
		/obj/item/clothing/mask/breath/medical,
		/obj/item/surgical_drapes, //for true paramedics
		/obj/item/scalpel,
		/obj/item/circular_saw,
		/obj/item/bonesetter,
		/obj/item/surgicaldrill,
		/obj/item/retractor,
		/obj/item/cautery,
		/obj/item/hemostat,
		/obj/item/blood_filter,
		/obj/item/shears,
		/obj/item/geiger_counter,
		/obj/item/clothing/neck/stethoscope,
		/obj/item/stamp,
		/obj/item/clothing/glasses,
		/obj/item/wrench/medical,
		/obj/item/clothing/mask/muzzle,
		/obj/item/reagent_containers/blood,
		/obj/item/tank/internals/emergency_oxygen,
		/obj/item/gun/syringe/syndicate,
		/obj/item/implantcase,
		/obj/item/implant,
		/obj/item/implanter,
		/obj/item/pinpointer/crew,
		/obj/item/holosign_creator/medical,
		/obj/item/stack/sticky_tape, //surgical tape
		/obj/item/pamk, //	Для йохеев медиков, они спавнятся с такой аптечкой а убрать туда 4 своих ПАМКа не могут
		/obj/item/storage/belt/medipenal	//	Медипенал
		))

/obj/item/storage/firstaid/medical/PopulateContents()
	if(empty)
		return
	var/static/items_inside = list(
		/obj/item/healthanalyzer = 1,
		/obj/item/stack/medical/gauze/twelve = 1,
		/obj/item/stack/medical/suture = 2,
		/obj/item/stack/medical/mesh = 2,
		/obj/item/reagent_containers/hypospray/medipen = 1,
		/obj/item/surgical_drapes = 1,
		/obj/item/scalpel = 1,
		/obj/item/hemostat = 1,
		/obj/item/cautery = 1)
	generate_items_inside(items_inside,src)

/obj/item/storage/firstaid/ancient
	icon_state = "oldfirstaid"
	desc = "Содержит медикаменты для лечения достаточно серьезных ран."

/obj/item/storage/firstaid/ancient/PopulateContents()
	if(empty)
		return
	var/static/items_inside = list(
		/obj/item/stack/medical/gauze = 1,
		/obj/item/stack/medical/bruise_pack = 3,
		/obj/item/stack/medical/ointment= 3)
	generate_items_inside(items_inside,src)

/obj/item/storage/firstaid/ancient/heirloom
	desc = "Содержит медикаменты для лечения достаточно серьезных ран. Глядя на нее вы с ностальгией вспоминаете старые-добрые времена. И свет был ярче, и снабжение лучше ..."
	empty = TRUE // long since been ransacked by hungry powergaming assistants breaking into med storage

/obj/item/storage/firstaid/fire
	name = "противоожоговая аптечка"
	desc = "Пригодится в тех случаях когда лаборатория взрывотехники <i>-случайно-</i> сгорела."
	icon_state = "ointment"
	inhand_icon_state = "firstaid-ointment"
	damagetype_healed = BURN

/obj/item/storage/firstaid/fire/suicide_act(mob/living/carbon/user)
	user.visible_message(span_suicide("[user] begins rubbing <b>[src.name]</b> against [user.ru_na()]self! It looks like [user.p_theyre()] trying to start a fire!"))
	return FIRELOSS
/*
/obj/item/storage/firstaid/fire/Initialize(mapload)
	. = ..()
	icon_state = pick("ointment","firefirstaid")
*/
/obj/item/storage/firstaid/fire/PopulateContents()
	if(empty)
		return
	var/static/items_inside = list(
		/obj/item/reagent_containers/pill/patch/aiuri = 3,
		/obj/item/reagent_containers/spray/hercuri = 1,
		/obj/item/reagent_containers/hypospray/medipen/oxandrolone = 1,
		/obj/item/reagent_containers/hypospray/medipen = 1)
	generate_items_inside(items_inside,src)

/obj/item/storage/firstaid/toxin
	name = "аптечка для вывода токсинов"
	desc = "Используется для очищения организма от токсичного и радиоактивного загрязнения, а так же промывки кровотока от химических соединений."
	icon_state = "antitoxin"
	inhand_icon_state = "firstaid-toxin"
	damagetype_healed = TOX

/obj/item/storage/firstaid/toxin/suicide_act(mob/living/carbon/user)
	user.visible_message(span_suicide("[user] begins licking the lead paint off <b>[src.name]</b>! It looks like [user.p_theyre()] trying to commit suicide!"))
	return TOXLOSS
/*
/obj/item/storage/firstaid/toxin/Initialize(mapload)
	. = ..()
	icon_state = pick("antitoxin","antitoxfirstaid","antitoxfirstaid2")
*/
/obj/item/storage/firstaid/toxin/PopulateContents()
	if(empty)
		return
	var/static/items_inside = list(
	    /obj/item/storage/pill_bottle/multiver/less = 1,
		/obj/item/reagent_containers/syringe/syriniver = 3,
		/obj/item/storage/pill_bottle/potassiodide = 1,
		/obj/item/reagent_containers/hypospray/medipen/penacid = 1)
	generate_items_inside(items_inside,src)

/obj/item/storage/firstaid/o2
	name = "аптечка для стабилизации"
	desc = "Содержит препараты для предотвращения асфиксии."
	icon_state = "o2"
	inhand_icon_state = "firstaid-o2"
	damagetype_healed = OXY

/obj/item/storage/firstaid/o2/suicide_act(mob/living/carbon/user)
	user.visible_message(span_suicide("[user] begins hitting [user.ru_ego()] neck with <b>[src.name]</b>! It looks like [user.p_theyre()] trying to commit suicide!"))
	return OXYLOSS
/*
/obj/item/storage/firstaid/o2/Initialize(mapload)
	. = ..()
	icon_state = pick("o2","o2second")
*/
/obj/item/storage/firstaid/o2/PopulateContents()
	if(empty)
		return
	var/static/items_inside = list(
		/obj/item/reagent_containers/syringe/convermol = 3,
		/obj/item/reagent_containers/hypospray/medipen/salbutamol = 1,
		/obj/item/reagent_containers/hypospray/medipen = 1,
		/obj/item/storage/pill_bottle/iron = 1)
	generate_items_inside(items_inside,src)

/obj/item/storage/firstaid/brute
	name = "аптечка для физических ран"
	desc = "Содержит медикаменты для излечения резаных, колотых ран и травм вызванных ударами тупым предметом различной степени тяжести."
	icon_state = "brute"
	inhand_icon_state = "firstaid-brute"
	damagetype_healed = BRUTE

/obj/item/storage/firstaid/brute/suicide_act(mob/living/carbon/user)
	user.visible_message(span_suicide("[user] begins beating [user.ru_na()]self over the head with <b>[src.name]</b>! It looks like [user.p_theyre()] trying to commit suicide!"))
	return BRUTELOSS
/*
/obj/item/storage/firstaid/brute/Initialize(mapload)
	. = ..()
	icon_state = pick("brute","brute2")
*/
/obj/item/storage/firstaid/brute/PopulateContents()
	if(empty)
		return
	var/static/items_inside = list(
		/obj/item/reagent_containers/pill/patch/libital = 3,
		/obj/item/stack/medical/gauze = 1,
		/obj/item/storage/pill_bottle/probital = 1,
		/obj/item/reagent_containers/hypospray/medipen/salacid = 1)
	generate_items_inside(items_inside,src)

/obj/item/storage/firstaid/advanced
	name = "универсальная аптечка"
	desc = "Продвинутая аптечка первой помощи, содержащая препараты для лечения большинства повреждений."
	icon_state = "firstaid_advanced"
	inhand_icon_state = "firstaid-rad"
	custom_premium_price = PAYCHECK_HARD * 6
	damagetype_healed = "all"

/obj/item/storage/firstaid/advanced/PopulateContents()
	if(empty)
		return
	var/static/items_inside = list(
		/obj/item/reagent_containers/pill/patch/synthflesh = 3,
		/obj/item/reagent_containers/hypospray/medipen/atropine = 2,
		/obj/item/stack/medical/gauze = 1,
		/obj/item/storage/pill_bottle/penacid = 1)
	generate_items_inside(items_inside,src)

/obj/item/storage/firstaid/tactical
	name = "боевая аптечка"
	desc = "Набор снаряжения и медикаментов первой помощи для полевых агентов."
	icon_state = "bezerk"
	damagetype_healed = "all"

/obj/item/storage/firstaid/tactical/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_w_class = WEIGHT_CLASS_NORMAL

/obj/item/storage/firstaid/tactical/PopulateContents()
	if(empty)
		return
	new /obj/item/stack/medical/gauze(src)
	new /obj/item/defibrillator/compact/combat/loaded(src)
	new /obj/item/reagent_containers/hypospray/combat(src)
	new /obj/item/reagent_containers/pill/patch/libital(src)
	new /obj/item/reagent_containers/pill/patch/libital(src)
	new /obj/item/reagent_containers/pill/patch/aiuri(src)
	new /obj/item/reagent_containers/pill/patch/aiuri(src)
	new /obj/item/clothing/glasses/hud/health/night(src)

//medibot assembly
/obj/item/storage/firstaid/attackby(obj/item/bodypart/S, mob/user, params)
	if((!istype(S, /obj/item/bodypart/l_arm/robot)) && (!istype(S, /obj/item/bodypart/r_arm/robot)))
		return ..()

	//Making a medibot!
	if(contents.len >= 1)
		to_chat(user, span_warning("Перед сборкой сначала необходимо опорожнить [src]!"))
		return

	var/obj/item/bot_assembly/medbot/A = new
	if (istype(src, /obj/item/storage/firstaid))
		A.set_skin("brute")
	if (istype(src, /obj/item/storage/firstaid/fire))
		A.set_skin("ointment")
	else if (istype(src, /obj/item/storage/firstaid/toxin))
		A.set_skin("tox")
	else if (istype(src, /obj/item/storage/firstaid/o2))
		A.set_skin("o2")
	else if (istype(src, /obj/item/storage/firstaid/brute))
		A.set_skin("brute")
	else if (istype(src, /obj/item/storage/firstaid/regular))
		A.set_skin("brute")
	else if (istype(src, /obj/item/storage/firstaid/advanced))
		A.set_skin("advanced")
	else if (istype(src, /obj/item/storage/firstaid/tactical))
		A.set_skin("advanced")
	user.put_in_hands(A)
	to_chat(user, span_notice("You add [S] to [src]."))
	A.robot_arm = S.type
	A.firstaid = type
	qdel(S)
	qdel(src)

/*
 * Pill Bottles
 */

/obj/item/storage/pill_bottle
	name = "баночка для таблеток"
	desc = "Хранит в себе разноцветные пилюльки и таблетки."
	icon = 'white/Feline/icons/med_items.dmi'
	icon_state = "pill_bottle"
	inhand_icon_state = "contsolid"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	w_class = WEIGHT_CLASS_SMALL

/obj/item/storage/pill_bottle/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.allow_quick_gather = TRUE
	STR.click_gather = TRUE
	STR.display_numerical_stacking = TRUE
	STR.max_items = 10
	STR.max_combined_w_class = 20
	STR.set_holdable(list(/obj/item/reagent_containers/pill, /obj/item/dice))

/obj/item/storage/pill_bottle/suicide_act(mob/user)
	user.visible_message(span_suicide("[user] пытается get the cap off [src]! It looks like [user.p_theyre()] trying to commit suicide!"))
	return (TOXLOSS)

/obj/item/storage/pill_bottle/multiver
	name = "bottle of multiver pills"
	desc = "Contains pills used to counter toxins."

/obj/item/storage/pill_bottle/multiver/PopulateContents()
	for(var/i in 1 to 10)
		new /obj/item/reagent_containers/pill/multiver(src)

/obj/item/storage/pill_bottle/multiver/less

/obj/item/storage/pill_bottle/multiver/less/PopulateContents()
	for(var/i in 1 to 6)
		new /obj/item/reagent_containers/pill/multiver(src)

/obj/item/storage/pill_bottle/epinephrine
	name = "bottle of epinephrine pills"
	desc = "Contains pills used to stabilize patients."

/obj/item/storage/pill_bottle/epinephrine/PopulateContents()
	for(var/i in 1 to 10)
		new /obj/item/reagent_containers/pill/epinephrine(src)

/obj/item/storage/pill_bottle/mutadone
	name = "bottle of mutadone pills"
	desc = "Contains pills used to treat genetic abnormalities."

/obj/item/storage/pill_bottle/mutadone/PopulateContents()
	for(var/i in 1 to 10)
		new /obj/item/reagent_containers/pill/mutadone(src)

/obj/item/storage/pill_bottle/potassiodide
	name = "bottle of potassium iodide pills"
	desc = "Contains pills used to reduce radiation damage."

/obj/item/storage/pill_bottle/potassiodide/PopulateContents()
	for(var/i in 1 to 6)
		new /obj/item/reagent_containers/pill/potassiodide(src)

/obj/item/storage/pill_bottle/probital
	name = "bottle of probital pills"
	desc = "Contains pills used to treat brute damage.The tag in the bottle states 'Eat before ingesting, may cause fatigue'."

/obj/item/storage/pill_bottle/probital/PopulateContents()
	for(var/i in 1 to 8)
		new /obj/item/reagent_containers/pill/probital(src)

/obj/item/storage/pill_bottle/iron
	name = "bottle of iron pills"
	desc = "Contains pills used to reduce blood loss slowly.The tag in the bottle states 'Only take one each five minutes'."

/obj/item/storage/pill_bottle/iron/PopulateContents()
	for(var/i in 1 to 8)
		new /obj/item/reagent_containers/pill/iron(src)

/obj/item/storage/pill_bottle/mannitol
	name = "bottle of mannitol pills"
	desc = "Contains pills used to treat brain damage."

/obj/item/storage/pill_bottle/mannitol/PopulateContents()
	for(var/i in 1 to 10)
		new /obj/item/reagent_containers/pill/mannitol(src)

//Contains 4 pills instead of 7, and 5u pills instead of 50u (50u pills heal 250 brain damage, 5u pills heal 25)
/obj/item/storage/pill_bottle/mannitol/braintumor
	desc = "Contains diluted pills used to treat brain tumor symptoms. Take one when feeling lightheaded."

/obj/item/storage/pill_bottle/mannitol/braintumor/PopulateContents()
	for(var/i in 1 to 8)
		new /obj/item/reagent_containers/pill/mannitol/braintumor(src)

/obj/item/storage/pill_bottle/stimulant
	name = "bottle of stimulant pills"
	desc = "Guaranteed to give you that extra burst of energy during a long shift!"

/obj/item/storage/pill_bottle/stimulant/PopulateContents()
	for(var/i in 1 to 10)
		new /obj/item/reagent_containers/pill/stimulant(src)

/obj/item/storage/pill_bottle/mining
	name = "bottle of patches"
	desc = "Contains patches used to treat brute and burn damage."

/obj/item/storage/pill_bottle/mining/PopulateContents()
	new /obj/item/reagent_containers/pill/patch/aiuri(src)
	for(var/i in 1 to 6)
		new /obj/item/reagent_containers/pill/patch/libital(src)

/obj/item/storage/pill_bottle/zoom
	name = "suspicious pill bottle"
	desc = "The label is pretty old and almost unreadable, you recognize some chemical compounds."

/obj/item/storage/pill_bottle/zoom/PopulateContents()
	for(var/i in 1 to 10)
		new /obj/item/reagent_containers/pill/zoom(src)

/obj/item/storage/pill_bottle/happy
	name = "suspicious pill bottle"
	desc = "There is a smiley on the top."

/obj/item/storage/pill_bottle/happy/PopulateContents()
	for(var/i in 1 to 10)
		new /obj/item/reagent_containers/pill/happy(src)

/obj/item/storage/pill_bottle/lsd
	name = "suspicious pill bottle"
	desc = "There is a crude drawing which could be either a mushroom, or a deformed moon."

/obj/item/storage/pill_bottle/lsd/PopulateContents()
	for(var/i in 1 to 10)
		new /obj/item/reagent_containers/pill/lsd(src)

/obj/item/storage/pill_bottle/aranesp
	name = "suspicious pill bottle"
	desc = "The label has 'fuck disablers' hastily scrawled in black marker."

/obj/item/storage/pill_bottle/aranesp/PopulateContents()
	for(var/i in 1 to 10)
		new /obj/item/reagent_containers/pill/aranesp(src)

/obj/item/storage/pill_bottle/psicodine
	name = "Баночка с таблетками Псикодина"
	desc = "Содержит таблетки которые восстанавливают ясность сознания, подавляют фобии и панические атаки."

/obj/item/storage/pill_bottle/psicodine/PopulateContents()
	for(var/i in 1 to 10)
		new /obj/item/reagent_containers/pill/psicodine(src)

/obj/item/storage/pill_bottle/penacid
	name = "bottle of pentetic acid pills"
	desc = "Contains pills to expunge radiation and toxins."

/obj/item/storage/pill_bottle/penacid/PopulateContents()
	for(var/i in 1 to 6)
		new /obj/item/reagent_containers/pill/penacid(src)


/obj/item/storage/pill_bottle/neurine
	name = "bottle of neurine pills"
	desc = "Contains pills to treat non-severe mental traumas."

/obj/item/storage/pill_bottle/neurine/PopulateContents()
	for(var/i in 1 to 10)
		new /obj/item/reagent_containers/pill/neurine(src)

/obj/item/storage/pill_bottle/maintenance_pill
	name = "bottle of maintenance pills"
	desc = "An old pill bottle. It smells musty."

/obj/item/storage/pill_bottle/maintenance_pill/Initialize()
	. = ..()
	var/obj/item/reagent_containers/pill/P = locate() in src
	name = "bottle of [P.name]s"

/obj/item/storage/pill_bottle/maintenance_pill/PopulateContents()
	for(var/i in 1 to rand(1,7))
		new /obj/item/reagent_containers/pill/maintenance(src)

/obj/item/storage/pill_bottle/maintenance_pill/full/PopulateContents()
	for(var/i in 1 to 7)
		new /obj/item/reagent_containers/pill/maintenance(src)

///////////////////////////////////////// Psychologist inventory pillbottles
/obj/item/storage/pill_bottle/happinesspsych
	name = "happiness pills"
	desc = "Contains pills used as a last resort means to temporarily stabilize depression and anxiety. WARNING: side effects may include slurred speech, drooling, and severe addiction."

/obj/item/storage/pill_bottle/happinesspsych/PopulateContents()
	for(var/i in 1 to 5)
		new /obj/item/reagent_containers/pill/happinesspsych(src)

/obj/item/storage/pill_bottle/lsdpsych
	name = "mindbreaker toxin pills"
	desc = "!FOR THERAPEUTIC USE ONLY! Contains pills used to alleviate the symptoms of Reality Dissociation Syndrome."

/obj/item/storage/pill_bottle/lsdpsych/PopulateContents()
	for(var/i in 1 to 5)
		new /obj/item/reagent_containers/pill/lsdpsych(src)

/obj/item/storage/pill_bottle/paxpsych
	name = "pax pills"
	desc = "Contains pills used to temporarily pacify patients that are deemed a harm to themselves or others."

/obj/item/storage/pill_bottle/paxpsych/PopulateContents()
	for(var/i in 1 to 5)
		new /obj/item/reagent_containers/pill/paxpsych(src)

/obj/item/storage/organbox
	name = "organ transport box"
	desc = "An advanced box with an cooling mechanism that uses cryostylane or other cold reagents to keep the organs or bodyparts inside preserved."
	icon_state = "organbox"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	throw_speed = 3
	throw_range = 7
	custom_premium_price = PAYCHECK_MEDIUM * 4
	/// var to prevent it freezing the same things over and over
	var/cooling = FALSE

/obj/item/storage/organbox/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_w_class = WEIGHT_CLASS_BULKY /// you have to remove it from your bag before opening it but I think that's fine
	STR.max_combined_w_class = 21
	STR.set_holdable(list(
		/obj/item/organ,
		/obj/item/bodypart,
		/obj/item/food/icecream
		))

/obj/item/storage/organbox/Initialize()
	. = ..()
	create_reagents(100, TRANSPARENT)
	RegisterSignal(src, COMSIG_ATOM_ENTERED, PROC_REF(freeze))
	RegisterSignal(src, COMSIG_TRY_STORAGE_TAKE, PROC_REF(unfreeze))
	START_PROCESSING(SSobj, src)

/obj/item/storage/organbox/process(delta_time)
	///if there is enough coolant var
	var/cool = FALSE
	var/amount = min(reagents.get_reagent_amount(/datum/reagent/cryostylane), 0.05 * delta_time)
	if(amount > 0)
		reagents.remove_reagent(/datum/reagent/cryostylane, amount)
		cool = TRUE
	else
		amount = min(reagents.get_reagent_amount(/datum/reagent/consumable/ice), 0.1 * delta_time)
		if(amount > 0)
			reagents.remove_reagent(/datum/reagent/consumable/ice, amount)
			cool = TRUE
	if(!cooling && cool)
		cooling = TRUE
		update_icon()
		for(var/C in contents)
			freeze(C)
		return
	if(cooling && !cool)
		cooling = FALSE
		update_icon()
		for(var/C in contents)
			unfreeze(C)

/obj/item/storage/organbox/update_icon()
	. = ..()
	if(cooling)
		icon_state = "organbox-working"
	else
		icon_state = "organbox"

///freezes the organ and loops bodyparts like heads
/obj/item/storage/organbox/proc/freeze(datum/source, obj/item/I)
	if(isorgan(I))
		var/obj/item/organ/organ = I
		organ.organ_flags |= ORGAN_FROZEN
		return
	if(istype(I, /obj/item/bodypart))
		var/obj/item/bodypart/B = I
		for(var/O in B.contents)
			if(isorgan(O))
				var/obj/item/organ/organ = O
				organ.organ_flags |= ORGAN_FROZEN

///unfreezes the organ and loops bodyparts like heads
/obj/item/storage/organbox/proc/unfreeze(datum/source, obj/item/I)
	if(isorgan(I))
		var/obj/item/organ/organ = I
		organ.organ_flags  &= ~ORGAN_FROZEN
		return
	if(istype(I, /obj/item/bodypart))
		var/obj/item/bodypart/B = I
		for(var/O in B.contents)
			if(isorgan(O))
				var/obj/item/organ/organ = O
				organ.organ_flags  &= ~ORGAN_FROZEN

/obj/item/storage/organbox/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/reagent_containers) && I.is_open_container())
		var/obj/item/reagent_containers/RC = I
		var/units = RC.reagents.trans_to(src, RC.amount_per_transfer_from_this, transfered_by = user)
		if(units)
			to_chat(user, span_notice("You transfer [units] units of the solution to [src]."))
			return
	if(istype(I, /obj/item/plunger))
		to_chat(user, span_notice("You start furiously plunging [name]."))
		if(do_after(user, 10, target = src))
			to_chat(user, span_notice("You finish plunging the [name]."))
			reagents.clear_reagents()
		return
	return ..()

/obj/item/storage/organbox/suicide_act(mob/living/carbon/user)
	user.visible_message(span_suicide("[user] is putting [user.p_theyre()] head inside the [src], it looks like [user.p_theyre()] trying to commit suicide!"))
	user.adjust_bodytemperature(-300)
	user.apply_status_effect(/datum/status_effect/freon)
	return (OXYLOSS)
