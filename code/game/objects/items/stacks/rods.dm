GLOBAL_LIST_INIT(rod_recipes, list ( \
	new/datum/stack_recipe("решётка", /obj/structure/grille, 2, time = 10, one_per_turf = TRUE, on_floor = FALSE), \
	new/datum/stack_recipe("рама стола", /obj/structure/table_frame, 2, time = 10, one_per_turf = TRUE, on_floor = TRUE), \
	new/datum/stack_recipe("рама самоката", /obj/item/scooter_frame, 10, time = 25, one_per_turf = FALSE), \
	new/datum/stack_recipe("lкорзина для белья", /obj/structure/bedsheetbin/empty, 2, time = 5, one_per_turf = FALSE), \
	new/datum/stack_recipe("перила", /obj/structure/railing, 3, time = 18, window_checks = TRUE), \
	new/datum/stack_recipe("держатель баков", /obj/structure/tank_holder, 2, time = 5, one_per_turf = TRUE, on_floor = FALSE), \
	new/datum/stack_recipe("лестница", /obj/structure/ladder/crafted, 15, time = 150, one_per_turf = TRUE, on_floor = FALSE), \
	))

/obj/item/stack/rods
	name = "металлические стержни"
	desc = "Могут быть использованы для строительства или укрепления чего-то."
	singular_name = "металлический стержень"
	icon_state = "rods"
	inhand_icon_state = "rods"
	flags_1 = CONDUCT_1
	w_class = WEIGHT_CLASS_NORMAL
	force = 9
	throwforce = 10
	throw_speed = 3
	throw_range = 7
	mats_per_unit = list(/datum/material/iron=1000)
	max_amount = 50
	attack_verb_continuous = list("бьёт", "протыкает", "шлёпает")
	attack_verb_simple = list("бьёт", "протыкает", "шлёпает")
	hitsound = 'sound/weapons/gun/general/grenade_launch.ogg'
	embedding = list()
	novariants = TRUE
	matter_amount = 2
	cost = 250
	source = /datum/robot_energy_storage/metal
	merge_type = /obj/item/stack/rods

/obj/item/stack/rods/suicide_act(mob/living/carbon/user)
	user.visible_message("<span class='suicide'>[user] begins to stuff \the [src] down [user.p_their()] throat! It looks like [user.p_theyre()] trying to commit suicide!</span>")//it looks like theyre ur mum
	return BRUTELOSS

/obj/item/stack/rods/Initialize(mapload, new_amount, merge = TRUE)
	. = ..()
	update_icon()

/obj/item/stack/rods/get_main_recipes()
	. = ..()
	. += GLOB.rod_recipes

/obj/item/stack/rods/update_icon_state()
	var/amount = get_amount()
	if(amount <= 5)
		icon_state = "rods-[amount]"
	else
		icon_state = "rods"

/obj/item/stack/rods/attackby(obj/item/W, mob/user, params)
	if(W.tool_behaviour == TOOL_WELDER)
		if(get_amount() < 2)
			to_chat(user, "<span class='warning'>Мне потребуется как минимум два стержня для этого!</span>")
			return

		if(W.use_tool(src, user, 0, volume=40))
			var/obj/item/stack/sheet/metal/new_item = new(usr.loc)
			user.visible_message("<span class='notice'><b>[user.name]</b> плавит [src] в металлический лист используя [W].</span>", \
				"<span class='notice'>Плавлю [src] в металлический лист используя [W].</span>", \
				"<span class='hear'>Слышу сварку.</span>")
			var/obj/item/stack/rods/R = src
			src = null
			var/replace = (user.get_inactive_held_item()==R)
			R.use(2)
			if (!R && replace)
				user.put_in_hands(new_item)
	else
		return ..()

/obj/item/stack/rods/cyborg/ComponentInitialize()
	. = ..()
	AddElement(/datum/element/update_icon_blocker)

/obj/item/stack/rods/ten
	amount = 10

/obj/item/stack/rods/twentyfive
	amount = 25

/obj/item/stack/rods/fifty
	amount = 50

/obj/item/stack/rods/lava
	name = "жаропрочные стержни"
	desc = "Обработанные, специализированные металлические стержни. При воздействии космического вакуума их покрытие разрушается, но они могут противостоять сильной жаре активной лавы."
	singular_name = "жаропрочный стержень"
	icon_state = "rods"
	inhand_icon_state = "rods"
	color = "#5286b9ff"
	flags_1 = CONDUCT_1
	w_class = WEIGHT_CLASS_NORMAL
	mats_per_unit = list(/datum/material/iron=1000, /datum/material/plasma=500, /datum/material/titanium=2000)
	max_amount = 30
	resistance_flags = FIRE_PROOF | LAVA_PROOF
	merge_type = /obj/item/stack/rods/lava

/obj/item/stack/rods/lava/thirty
	amount = 30
