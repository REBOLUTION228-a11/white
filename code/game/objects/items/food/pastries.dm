//Pastry is a food that is made from dough which is made from wheat or rye flour.
//This file contains pastries that don't fit any existing categories.
////////////////////////////////////////////DONUTS////////////////////////////////////////////

#define DONUT_SPRINKLE_CHANCE 30

/obj/item/food/donut
	name = "пончик"
	desc = "Goes great with robust coffee."
	icon = 'icons/obj/food/donuts.dmi'
	icon_state = "donut"
	bite_consumption = 5
	food_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/sugar = 3)
	tastes = list("пончик" = 1)
	foodtypes = JUNKFOOD | GRAIN | FRIED | SUGAR | BREAKFAST
	food_flags = FOOD_FINGER_FOOD
	w_class = WEIGHT_CLASS_SMALL
	var/decorated_icon = "donut_homer"
	var/is_decorated = FALSE
	var/extra_reagent = null
	var/decorated_adjective = "sprinkled"

/obj/item/food/donut/Initialize()
	. = ..()
	AddElement(/datum/element/dunkable, amount_per_dunk = 10)
	if(prob(DONUT_SPRINKLE_CHANCE))
		decorate_donut()

///Override for checkliked callback
/obj/item/food/donut/MakeEdible()
	AddComponent(/datum/component/edible,\
				initial_reagents = food_reagents,\
				food_flags = food_flags,\
				foodtypes = foodtypes,\
				volume = max_volume,\
				eat_time = eat_time,\
				tastes = tastes,\
				eatverbs = eatverbs,\
				bite_consumption = bite_consumption,\
				microwaved_type = microwaved_type,\
				junkiness = junkiness,\
				check_liked = CALLBACK(src, PROC_REF(check_liked)))

/obj/item/food/donut/proc/decorate_donut()
	if(is_decorated || !decorated_icon)
		return
	is_decorated = TRUE
	name = "[decorated_adjective] [name]"
	icon_state = decorated_icon //delish~!
	reagents.add_reagent(/datum/reagent/consumable/sprinkles, 1)
	return TRUE

/// Returns the sprite of the donut while in a donut box
/obj/item/food/donut/proc/in_box_sprite()
	return "[icon_state]_inbox"

///Override for checkliked in edible component, because all cops LOVE donuts
/obj/item/food/donut/proc/check_liked(fraction, mob/living/carbon/human/H)
	if(!HAS_TRAIT(H, TRAIT_AGEUSIA) && H.mind && HAS_TRAIT(H.mind, TRAIT_DONUT_LOVER))
		return FOOD_LIKED

//Use this donut ingame
/obj/item/food/donut/plain

/obj/item/food/donut/chaos
	name = "chaos donut"
	desc = "Like life, it never quite tastes the same."
	icon_state = "donut_chaos"
	bite_consumption = 10
	tastes = list("пончик" = 3, "хаос" = 1)
	is_decorated = TRUE

/obj/item/food/donut/chaos/Initialize()
	. = ..()
	extra_reagent = pick(/datum/reagent/consumable/nutriment, /datum/reagent/consumable/capsaicin, /datum/reagent/consumable/frostoil, /datum/reagent/drug/krokodil, /datum/reagent/toxin/plasma, /datum/reagent/consumable/coco, /datum/reagent/toxin/slimejelly, /datum/reagent/consumable/banana, /datum/reagent/consumable/berryjuice, /datum/reagent/medicine/omnizine)
	reagents.add_reagent(extra_reagent, 3)

/obj/item/food/donut/meat
	name = "Meat Donut"
	desc = "Tastes as gross as it looks."
	icon_state = "donut_meat"
	food_reagents = list(/datum/reagent/consumable/nutriment = 2, /datum/reagent/consumable/nutriment/protein = 3, /datum/reagent/consumable/ketchup = 3)
	tastes = list("мясо" = 1)
	foodtypes = JUNKFOOD | MEAT | GROSS | FRIED | BREAKFAST
	is_decorated = TRUE

/obj/item/food/donut/berry
	name = "pink donut"
	desc = "Goes great with a soy latte."
	icon_state = "donut_pink"
	food_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/sugar = 3, /datum/reagent/consumable/berryjuice = 3, /datum/reagent/consumable/sprinkles = 1) //Extra sprinkles to reward frosting
	decorated_icon = "donut_homer"

/obj/item/food/donut/trumpet
	name = "spaceman's donut"
	desc = "Goes great with a cold beaker of malk."
	icon_state = "donut_purple"
	food_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/sugar = 3, /datum/reagent/medicine/polypyr = 3, /datum/reagent/consumable/sprinkles = 1)
	tastes = list("пончик" = 3, "фиалки" = 1)
	is_decorated = TRUE

/obj/item/food/donut/apple
	name = "apple donut"
	desc = "Goes great with a shot of cinnamon schnapps."
	icon_state = "donut_green"
	food_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/sugar = 3, /datum/reagent/consumable/applejuice = 3, /datum/reagent/consumable/sprinkles = 1)
	tastes = list("пончик" = 3, "зелёные яблоки" = 1)
	is_decorated = TRUE

/obj/item/food/donut/caramel
	name = "caramel donut"
	desc = "Goes great with a mug of hot coco."
	icon_state = "donut_beige"
	food_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/sugar = 3, /datum/reagent/consumable/caramel = 3, /datum/reagent/consumable/sprinkles = 1)
	tastes = list("пончик" = 3, "маслянистая сладость" = 1)
	is_decorated = TRUE

/obj/item/food/donut/choco
	name = "chocolate donut"
	desc = "Goes great with a glass of warm milk."
	icon_state = "donut_choc"
	food_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/sugar = 3, /datum/reagent/consumable/hot_coco = 3, /datum/reagent/consumable/sprinkles = 1) //the coco reagent is just bitter.
	tastes = list("пончик" = 4, "горечь" = 1)
	decorated_icon = "donut_choc_sprinkles"

/obj/item/food/donut/blumpkin
	name = "blumpkin donut"
	desc = "Goes great with a mug of soothing drunken blumpkin."
	icon_state = "donut_blue"
	food_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/sugar = 3, /datum/reagent/consumable/blumpkinjuice = 3, /datum/reagent/consumable/sprinkles = 1)
	tastes = list("пончик" = 2, "blumpkin" = 1)
	is_decorated = TRUE

/obj/item/food/donut/bungo
	name = "bungo donut"
	desc = "Goes great with a mason jar of hippie's delight."
	icon_state = "donut_yellow"
	food_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/sugar = 3, /datum/reagent/consumable/bungojuice = 3, /datum/reagent/consumable/sprinkles = 1)
	tastes = list("пончик" = 3, "тропическая сладость" = 1)
	is_decorated = TRUE

/obj/item/food/donut/matcha
	name = "matcha donut"
	desc = "Goes great with a cup of tea."
	icon_state = "donut_olive"
	food_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/sugar = 3, /datum/reagent/toxin/teapowder = 3, /datum/reagent/consumable/sprinkles = 1)
	tastes = list("пончик" = 3, "matcha" = 1)
	is_decorated = TRUE

/obj/item/food/donut/laugh
	name = "sweet pea donut"
	desc = "Goes great with a bottle of Bastion Burbon!"
	icon_state = "donut_laugh"
	food_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/sugar = 3, /datum/reagent/consumable/laughter = 3)
	tastes = list("пончик" = 3, "fizzy tutti frutti" = 1,)
	is_decorated = TRUE

//////////////////////JELLY DONUTS/////////////////////////

/obj/item/food/donut/jelly
	name = "jelly donut"
	desc = "You jelly?"
	icon_state = "jelly"
	decorated_icon = "jelly_homer"
	food_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/sugar = 3, /datum/reagent/consumable/sugar = 1, /datum/reagent/consumable/nutriment/vitamin = 1)
	extra_reagent = /datum/reagent/consumable/berryjuice
	tastes = list("желе" = 1, "пончик" = 3)
	foodtypes = JUNKFOOD | GRAIN | FRIED | FRUIT | SUGAR | BREAKFAST

// Jelly donuts don't have holes, but look the same on the outside
/obj/item/food/donut/jelly/in_box_sprite()
	return "[replacetext(icon_state, "jelly", "donut")]_inbox"

/obj/item/food/donut/jelly/Initialize()
	. = ..()
	if(extra_reagent)
		reagents.add_reagent(extra_reagent, 3)

/obj/item/food/donut/jelly/plain //use this ingame to avoid inheritance related crafting issues.

/obj/item/food/donut/jelly/berry
	name = "pink jelly donut"
	desc = "Goes great with a soy latte."
	icon_state = "jelly_pink"
	food_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/sugar = 3, /datum/reagent/consumable/berryjuice = 3, /datum/reagent/consumable/sprinkles = 1, /datum/reagent/consumable/nutriment/vitamin = 1) //Extra sprinkles to reward frosting.
	decorated_icon = "jelly_homer"

/obj/item/food/donut/jelly/trumpet
	name = "spaceman's jelly donut"
	desc = "Goes great with a cold beaker of malk."
	icon_state = "jelly_purple"
	food_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/sugar = 3, /datum/reagent/medicine/polypyr = 3, /datum/reagent/consumable/sprinkles = 1, /datum/reagent/consumable/nutriment/vitamin = 1)
	tastes = list("желе" = 1, "пончик" = 3, "фиалки" = 1)
	is_decorated = TRUE

/obj/item/food/donut/jelly/apple
	name = "apple jelly donut"
	desc = "Goes great with a shot of cinnamon schnapps."
	icon_state = "jelly_green"
	food_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/sugar = 3, /datum/reagent/consumable/applejuice = 3, /datum/reagent/consumable/sprinkles = 1, /datum/reagent/consumable/nutriment/vitamin = 1)
	tastes = list("желе" = 1, "пончик" = 3, "зелёные яблоки" = 1)
	is_decorated = TRUE

/obj/item/food/donut/jelly/caramel
	name = "caramel jelly donut"
	desc = "Goes great with a mug of hot coco."
	icon_state = "jelly_beige"
	food_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/sugar = 3, /datum/reagent/consumable/caramel = 3, /datum/reagent/consumable/sprinkles = 1, /datum/reagent/consumable/nutriment/vitamin = 1)
	tastes = list("желе" = 1, "пончик" = 3, "маслянистая сладость" = 1)
	is_decorated = TRUE

/obj/item/food/donut/jelly/choco
	name = "chocolate jelly donut"
	desc = "Goes great with a glass of warm milk."
	icon_state = "jelly_choc"
	food_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/sugar = 3, /datum/reagent/consumable/hot_coco = 3, /datum/reagent/consumable/sprinkles = 1, /datum/reagent/consumable/nutriment/vitamin = 1) //the coco reagent is just bitter.
	tastes = list("желе" = 1, "пончик" = 4, "горечь" = 1)
	decorated_icon = "jelly_choc_sprinkles"

/obj/item/food/donut/jelly/blumpkin
	name = "blumpkin jelly donut"
	desc = "Goes great with a mug of soothing drunken blumpkin."
	icon_state = "jelly_blue"
	food_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/sugar = 3, /datum/reagent/consumable/blumpkinjuice = 3, /datum/reagent/consumable/sprinkles = 1, /datum/reagent/consumable/nutriment/vitamin = 1)
	tastes = list("желе" = 1, "пончик" = 2, "blumpkin" = 1)
	is_decorated = TRUE

/obj/item/food/donut/jelly/bungo
	name = "bungo jelly donut"
	desc = "Goes great with a mason jar of hippie's delight."
	icon_state = "jelly_yellow"
	food_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/sugar = 3, /datum/reagent/consumable/bungojuice = 3, /datum/reagent/consumable/sprinkles = 1, /datum/reagent/consumable/nutriment/vitamin = 1)
	tastes = list("желе" = 1, "пончик" = 3, "тропическая сладость" = 1)
	is_decorated = TRUE

/obj/item/food/donut/jelly/matcha
	name = "matcha jelly donut"
	desc = "Goes great with a cup of tea."
	icon_state = "jelly_olive"
	food_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/sugar = 3, /datum/reagent/toxin/teapowder = 3, /datum/reagent/consumable/sprinkles = 1, /datum/reagent/consumable/nutriment/vitamin = 1)
	tastes = list("желе" = 1, "пончик" = 3, "matcha" = 1)
	is_decorated = TRUE

/obj/item/food/donut/jelly/laugh
	name = "sweet pea jelly donut"
	desc = "Goes great with a bottle of Bastion Burbon!"
	icon_state = "jelly_laugh"
	food_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/sugar = 3, /datum/reagent/consumable/laughter = 3)
	tastes = list("желе" = 3, "пончик" = 1, "fizzy tutti frutti" = 1)
	is_decorated = TRUE

//////////////////////////SLIME DONUTS/////////////////////////

/obj/item/food/donut/jelly/slimejelly
	name = "jelly donut"
	desc = "You jelly?"
	icon_state = "jelly"
	extra_reagent = /datum/reagent/toxin/slimejelly
	foodtypes = JUNKFOOD | GRAIN | FRIED | TOXIC | SUGAR | BREAKFAST

/obj/item/food/donut/jelly/slimejelly/plain

/obj/item/food/donut/jelly/slimejelly/berry
	name = "pink jelly donut"
	desc = "Goes great with a soy latte."
	icon_state = "jelly_pink"
	food_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/sugar = 3, /datum/reagent/consumable/berryjuice = 3, /datum/reagent/consumable/sprinkles = 1, /datum/reagent/consumable/nutriment/vitamin = 1) //Extra sprinkles to reward frosting

/obj/item/food/donut/jelly/slimejelly/trumpet
	name = "spaceman's jelly donut"
	desc = "Goes great with a cold beaker of malk."
	icon_state = "jelly_purple"
	food_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/sugar = 3, /datum/reagent/medicine/polypyr = 3, /datum/reagent/consumable/sprinkles = 1, /datum/reagent/consumable/nutriment/vitamin = 1)
	tastes = list("желе" = 1, "пончик" = 3, "фиалки" = 1)
	is_decorated = TRUE

/obj/item/food/donut/jelly/slimejelly/apple
	name = "apple jelly donut"
	desc = "Goes great with a shot of cinnamon schnapps."
	icon_state = "jelly_green"
	food_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/sugar = 3, /datum/reagent/consumable/applejuice = 3, /datum/reagent/consumable/sprinkles = 1, /datum/reagent/consumable/nutriment/vitamin = 1)
	tastes = list("желе" = 1, "пончик" = 3, "зелёные яблоки" = 1)
	is_decorated = TRUE

/obj/item/food/donut/jelly/slimejelly/caramel
	name = "caramel jelly donut"
	desc = "Goes great with a mug of hot coco."
	icon_state = "jelly_beige"
	food_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/sugar = 3, /datum/reagent/consumable/caramel = 3, /datum/reagent/consumable/sprinkles = 1, /datum/reagent/consumable/nutriment/vitamin = 1)
	tastes = list("желе" = 1, "пончик" = 3, "маслянистая сладость" = 1)
	is_decorated = TRUE

/obj/item/food/donut/jelly/slimejelly/choco
	name = "chocolate jelly donut"
	desc = "Goes great with a glass of warm milk."
	icon_state = "jelly_choc"
	food_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/sugar = 3, /datum/reagent/consumable/hot_coco = 3, /datum/reagent/consumable/sprinkles = 1, /datum/reagent/consumable/nutriment/vitamin = 1) //the coco reagent is just bitter.
	tastes = list("желе" = 1, "пончик" = 4, "горечь" = 1)
	decorated_icon = "jelly_choc_sprinkles"

/obj/item/food/donut/jelly/slimejelly/blumpkin
	name = "blumpkin jelly donut"
	desc = "Goes great with a mug of soothing drunken blumpkin."
	icon_state = "jelly_blue"
	food_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/sugar = 3, /datum/reagent/consumable/blumpkinjuice = 3, /datum/reagent/consumable/sprinkles = 1, /datum/reagent/consumable/nutriment/vitamin = 1)
	tastes = list("желе" = 1, "пончик" = 2, "blumpkin" = 1)
	is_decorated = TRUE

/obj/item/food/donut/jelly/slimejelly/bungo
	name = "bungo jelly donut"
	desc = "Goes great with a mason jar of hippie's delight."
	icon_state = "jelly_yellow"
	food_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/sugar = 3, /datum/reagent/consumable/bungojuice = 3, /datum/reagent/consumable/sprinkles = 1, /datum/reagent/consumable/nutriment/vitamin = 1)
	tastes = list("желе" = 1, "пончик" = 3, "тропическая сладость" = 1)
	is_decorated = TRUE

/obj/item/food/donut/jelly/slimejelly/matcha
	name = "matcha jelly donut"
	desc = "Goes great with a cup of tea."
	icon_state = "jelly_olive"
	food_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/sugar = 3, /datum/reagent/toxin/teapowder = 3, /datum/reagent/consumable/sprinkles = 1, /datum/reagent/consumable/nutriment/vitamin = 1)
	tastes = list("желе" = 1, "пончик" = 3, "matcha" = 1)
	is_decorated = TRUE

/obj/item/food/donut/jelly/slimejelly/laugh
	name = "sweet pea jelly donut"
	desc = "Goes great with a bottle of Bastion Burbon!"
	icon_state = "jelly_laugh"
	food_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/sugar = 3, /datum/reagent/consumable/laughter = 3)
	tastes = list("желе" = 3, "пончик" = 1, "fizzy tutti frutti" = 1)
	is_decorated = TRUE

////////////////////////////////////////////MUFFINS////////////////////////////////////////////

/obj/item/food/muffin
	name = "маффин"
	desc = "Сладкое и мягкое пирожное."
	icon_state = "muffin"
	food_reagents = list(/datum/reagent/consumable/nutriment = 6, /datum/reagent/consumable/nutriment/vitamin = 1)
	tastes = list("оладья" = 1)
	foodtypes = GRAIN | SUGAR | BREAKFAST
	food_flags = FOOD_FINGER_FOOD
	w_class = WEIGHT_CLASS_SMALL

/obj/item/food/muffin/berry
	name = "ягодный маффин"
	icon_state = "berrymuffin"
	desc = "Сладкое и мягкое пирожное с ягодами"
	tastes = list("оладья" = 3, "ягода" = 1)
	foodtypes = GRAIN | FRUIT | SUGAR | BREAKFAST
	venue_value = FOOD_PRICE_NORMAL

/obj/item/food/muffin/booberry
	name = "маффин из мрачных ягод"
	icon_state = "berrymuffin"
	alpha = 125
	desc = "Мой желудок словно кладбище! Ничто не сможет утолить мою жажду крови!"
	tastes = list("оладья" = 3, "страх" = 1)
	foodtypes = GRAIN | FRUIT | SUGAR | BREAKFAST

/obj/item/food/chawanmushi
	name = "тяван-муси"
	desc = "Легендарный заварной крем из яйца, делающий друзей из врагов."
	icon_state = "chawanmushi"
	food_reagents = list(/datum/reagent/consumable/nutriment = 4, /datum/reagent/consumable/nutriment/protein = 3, /datum/reagent/consumable/nutriment/vitamin = 1)
	tastes = list("заварной крем" = 1)
	foodtypes = GRAIN | MEAT | VEGETABLES
	venue_value = FOOD_PRICE_NORMAL

/obj/item/food/muffin/moffin
	name = "моффин"
	icon_state = "moffin"
	desc = "Сладкое и мягкое пирожное."
	tastes = list("muffin" = 3, "dust" = 1, "lint" = 1)
	foodtypes = CLOTH | GRAIN | SUGAR | BREAKFAST

/obj/item/food/muffin/moffin/Initialize(mapload)
	. = ..()
	icon_state = "[icon_state]_[rand(1,3)]"

/obj/item/food/muffin/moffin/examine(mob/user)
	. = ..()
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/moffin_observer = user
	if(moffin_observer.dna.species.liked_food & CLOTH)
		. += span_nicegreen("М-м-м! На нем даже есть кусочки ткани! Вкуснятина!")
	else
		. += span_warning("Я не думаю, что на поверхности этого маффина находится что-то съедобное...")

////////////////////////////////////////////WAFFLES////////////////////////////////////////////

/obj/item/food/waffles
	name = "waffles"
	desc = "Mmm, waffles."
	icon_state = "waffles"
	trash_type = /obj/item/trash/waffles
	food_reagents = list(/datum/reagent/consumable/nutriment = 8, /datum/reagent/consumable/nutriment/vitamin = 2)
	tastes = list("вафли" = 1)
	foodtypes = GRAIN | SUGAR | BREAKFAST
	w_class = WEIGHT_CLASS_SMALL

/obj/item/food/soylentgreen
	name = "\improper Soylent Green"
	desc = "Not made of people. Honest." //Totally people.
	icon_state = "soylent_green"
	trash_type = /obj/item/trash/waffles
	food_reagents = list(/datum/reagent/consumable/nutriment = 10, /datum/reagent/consumable/nutriment/vitamin = 2, /datum/reagent/consumable/nutriment/protein = 4)
	tastes = list("вафли" = 7, "люди" = 1)
	foodtypes = GRAIN | MEAT
	w_class = WEIGHT_CLASS_SMALL

/obj/item/food/soylenviridians
	name = "\improper Soylent Virdians"
	desc = "Not made of people. Honest." //Actually honest for once.
	icon_state = "soylent_yellow"
	trash_type = /obj/item/trash/waffles
	food_reagents = list(/datum/reagent/consumable/nutriment = 10, /datum/reagent/consumable/nutriment/vitamin = 2, /datum/reagent/consumable/nutriment/protein = 2)
	tastes = list("вафли" = 7, "зелёный цвет" = 1)
	foodtypes = GRAIN
	w_class = WEIGHT_CLASS_SMALL

/obj/item/food/rofflewaffles
	name = "roffle waffles"
	desc = "Waffles from Roffle. Co."
	icon_state = "rofflewaffles"
	trash_type = /obj/item/trash/waffles
	bite_consumption = 4
	food_reagents = list(/datum/reagent/consumable/nutriment = 8, /datum/reagent/drug/mushroomhallucinogen = 2, /datum/reagent/consumable/nutriment/vitamin = 4)
	tastes = list("вафля" = 1, "грибы" = 1)
	foodtypes = GRAIN | VEGETABLES | SUGAR | BREAKFAST
	w_class = WEIGHT_CLASS_SMALL

////////////////////////////////////////////DONK POCKETS////////////////////////////////////////////

/obj/item/food/donkpocket
	name = "\improper Donk-pocket"
	desc = "The food of choice for the seasoned traitor."
	icon_state = "donkpocket"
	food_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/nutriment/protein = 2)
	microwaved_type = /obj/item/food/donkpocket/warm
	tastes = list("мясо" = 2, "тесто" = 2, "лень" = 1)
	foodtypes = GRAIN
	food_flags = FOOD_FINGER_FOOD
	w_class = WEIGHT_CLASS_SMALL

//donk pockets cook quick... try not to burn them for using an unoptimal tool
/obj/item/food/donkpocket/MakeBakeable()
	AddComponent(/datum/component/bakeable, microwaved_type, rand(25 SECONDS, 30 SECONDS), TRUE, TRUE)

/obj/item/food/donkpocket/warm
	name = "warm Donk-pocket"
	desc = "The heated food of choice for the seasoned traitor."
	food_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/nutriment/protein = 2, /datum/reagent/medicine/omnizine = 6)
	microwaved_type = null
	tastes = list("мясо" = 2, "тесто" = 2, "лень" = 1)
	foodtypes = GRAIN

///Override for fast-burning food
/obj/item/food/donkpocket/warm/MakeBakeable()
	AddComponent(/datum/component/bakeable, /obj/item/food/badrecipe, rand(10 SECONDS, 15 SECONDS), FALSE)

/obj/item/food/dankpocket
	name = "\improper Dank-pocket"
	desc = "The food of choice for the seasoned botanist."
	icon_state = "dankpocket"
	food_reagents = list(/datum/reagent/toxin/lipolicide = 3, /datum/reagent/drug/space_drugs = 3, /datum/reagent/consumable/nutriment = 4)
	tastes = list("мясо" = 2, "тесто" = 2)
	foodtypes = GRAIN | VEGETABLES

/obj/item/food/donkpocket/spicy
	name = "\improper Spicy-pocket"
	desc = "The classic snack food, now with a heat-activated spicy flair."
	icon_state = "donkpocketspicy"
	food_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/nutriment/protein = 2, /datum/reagent/consumable/capsaicin = 2)
	microwaved_type = /obj/item/food/donkpocket/warm/spicy
	tastes = list("мясо" = 2, "тесто" = 2, "пряность" = 1)
	foodtypes = GRAIN

/obj/item/food/donkpocket/warm/spicy
	name = "warm Spicy-pocket"
	desc = "The classic snack food, now maybe a bit too spicy."
	icon_state = "donkpocketspicy"
	food_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/nutriment/protein = 2, /datum/reagent/medicine/omnizine = 2, /datum/reagent/consumable/capsaicin = 5)
	tastes = list("мясо" = 2, "тесто" = 2, "странные специи" = 2)
	foodtypes = GRAIN

/obj/item/food/donkpocket/teriyaki
	name = "\improper Teriyaki-pocket"
	desc = "An east-asian take on the classic stationside snack."
	icon_state = "donkpocketteriyaki"
	food_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/nutriment/protein = 2, /datum/reagent/consumable/soysauce = 2)
	microwaved_type = /obj/item/food/donkpocket/warm/teriyaki
	tastes = list("мясо" = 2, "тесто" = 2, "соевый соус" = 2)
	foodtypes = GRAIN

/obj/item/food/donkpocket/warm/teriyaki
	name = "warm Teriyaki-pocket"
	desc = "An east-asian take on the classic stationside snack, now steamy and warm."
	icon_state = "donkpocketteriyaki"
	food_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/nutriment/protein = 3, /datum/reagent/medicine/omnizine = 2, /datum/reagent/consumable/soysauce = 2)
	tastes = list("мясо" = 2, "тесто" = 2, "соевый соус" = 2)
	foodtypes = GRAIN

/obj/item/food/donkpocket/pizza
	name = "\improper Pizza-pocket"
	desc = "Delicious, cheesy and surprisingly filling."
	icon_state = "donkpocketpizza"
	food_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/nutriment/protein = 2, /datum/reagent/consumable/tomatojuice = 2)
	microwaved_type = /obj/item/food/donkpocket/warm/pizza
	tastes = list("мясо" = 2, "тесто" = 2, "сыр"= 2)
	foodtypes = GRAIN

/obj/item/food/donkpocket/warm/pizza
	name = "warm Pizza-pocket"
	desc = "Delicious, cheesy, and even better when hot."
	icon_state = "donkpocketpizza"
	food_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/nutriment/protein = 2, /datum/reagent/medicine/omnizine = 2, /datum/reagent/consumable/tomatojuice = 2)
	tastes = list("мясо" = 2, "тесто" = 2, "плавленый сыр"= 2)
	foodtypes = GRAIN

/obj/item/food/donkpocket/honk
	name = "\improper Honk-pocket"
	desc = "The award-winning donk-pocket that won the hearts of clowns and humans alike."
	icon_state = "donkpocketbanana"
	food_reagents = list(/datum/reagent/consumable/nutriment = 4, /datum/reagent/consumable/banana = 4)
	microwaved_type = /obj/item/food/donkpocket/warm/honk
	tastes = list("банан" = 2, "тесто" = 2, "детские антибиотики" = 1)
	foodtypes = GRAIN

/obj/item/food/donkpocket/warm/honk
	name = "warm Honk-pocket"
	desc = "The award-winning donk-pocket, now warm and toasty."
	icon_state = "donkpocketbanana"
	food_reagents = list(/datum/reagent/consumable/nutriment = 4, /datum/reagent/medicine/omnizine = 2, /datum/reagent/consumable/banana = 4, /datum/reagent/consumable/laughter = 6)
	tastes = list("тесто" = 2, "детские антибиотики" = 1)
	foodtypes = GRAIN

/obj/item/food/donkpocket/berry
	name = "\improper Berry-pocket"
	desc = "A relentlessly sweet donk-pocket first created for use in Operation Dessert Storm."
	icon_state = "donkpocketberry"
	food_reagents = list(/datum/reagent/consumable/nutriment = 4, /datum/reagent/consumable/berryjuice = 3)
	microwaved_type = /obj/item/food/donkpocket/warm/berry
	tastes = list("тесто" = 2, "джем" = 2)
	foodtypes = GRAIN

/obj/item/food/donkpocket/warm/berry
	name = "warm Berry-pocket"
	desc = "A relentlessly sweet donk-pocket, now warm and delicious."
	icon_state = "donkpocketberry"
	food_reagents = list(/datum/reagent/consumable/nutriment = 4, /datum/reagent/medicine/omnizine = 2, /datum/reagent/consumable/berryjuice = 3)
	tastes = list("тесто" = 2, "тёплый джем" = 2)
	foodtypes = GRAIN

/obj/item/food/donkpocket/gondola
	name = "\improper Gondola-pocket"
	desc = "The choice to use real gondola meat in the recipe is controversial, to say the least." //Only a monster would craft this.
	icon_state = "donkpocketgondola"
	food_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/nutriment/protein = 2, /datum/reagent/tranquility = 5)
	microwaved_type = /obj/item/food/donkpocket/warm/gondola
	tastes = list("мясо" = 2, "тесто" = 2, "внутренний мир" = 1)
	foodtypes = GRAIN

/obj/item/food/donkpocket/warm/gondola
	name = "warm Gondola-pocket"
	desc = "The choice to use real gondola meat in the recipe is controversial, to say the least."
	icon_state = "donkpocketgondola"
	food_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/nutriment/protein = 2, /datum/reagent/medicine/omnizine = 2, /datum/reagent/tranquility = 10)
	tastes = list("мясо" = 2, "тесто" = 2, "внутренний мир" = 1)
	foodtypes = GRAIN

////////////////////////////////////////////OTHER////////////////////////////////////////////

/obj/item/food/cookie
	name = "cookie"
	desc = "COOKIE!!!"
	icon_state = "COOKIE!!!"
	bite_consumption = 1
	food_reagents = list(/datum/reagent/consumable/nutriment = 2)
	tastes = list("печенька" = 1)
	foodtypes = GRAIN | SUGAR
	food_flags = FOOD_FINGER_FOOD
	w_class = WEIGHT_CLASS_SMALL

/obj/item/food/cookie/Initialize()
	. = ..()
	AddElement(/datum/element/dunkable, 10)

/obj/item/food/cookie/sleepy
	food_reagents = list(/datum/reagent/consumable/nutriment = 1, /datum/reagent/toxin/chloralhydrate = 10)

/obj/item/food/fortunecookie
	name = "fortune cookie"
	desc = "A true prophecy in each cookie!"
	icon_state = "fortune_cookie"
	food_reagents = list(/datum/reagent/consumable/nutriment = 5)
	tastes = list("печенька" = 1)
	foodtypes = GRAIN | SUGAR
	food_flags = FOOD_FINGER_FOOD
	w_class = WEIGHT_CLASS_SMALL

/obj/item/food/poppypretzel
	name = "poppy pretzel"
	desc = "It's all twisted up!"
	icon_state = "poppypretzel"
	food_reagents = list(/datum/reagent/consumable/nutriment = 6, /datum/reagent/consumable/nutriment/vitamin = 2)
	tastes = list("крендель" = 1)
	foodtypes = GRAIN | SUGAR
	food_flags = FOOD_FINGER_FOOD
	w_class = WEIGHT_CLASS_SMALL

/obj/item/food/plumphelmetbiscuit
	name = "plump helmet biscuit"
	desc = "This is a finely-prepared plump helmet biscuit. The ingredients are exceptionally minced plump helmet, and well-minced dwarven wheat flour."
	icon_state = "phelmbiscuit"
	food_reagents = list(/datum/reagent/consumable/nutriment = 6, /datum/reagent/consumable/nutriment/vitamin = 1)
	tastes = list("грибы" = 1, "бисквит" = 1)
	foodtypes = GRAIN | VEGETABLES
	food_flags = FOOD_FINGER_FOOD
	w_class = WEIGHT_CLASS_SMALL

/obj/item/food/plumphelmetbiscuit/Initialize()
	var/fey = prob(10)
	if(fey)
		name = "exceptional plump helmet biscuit"
		desc = "Microwave is taken by a fey mood! It has cooked an exceptional plump helmet biscuit!"
		food_reagents = list(/datum/reagent/medicine/omnizine = 5, /datum/reagent/consumable/nutriment = 1, /datum/reagent/consumable/nutriment/vitamin = 1)
	. = ..()
	if(fey)
		reagents.add_reagent(/datum/reagent/medicine/omnizine, 5)

/obj/item/food/cracker
	name = "cracker"
	desc = "It's a salted cracker."
	icon_state = "cracker"
	bite_consumption = 1
	food_reagents = list(/datum/reagent/consumable/nutriment = 2)
	tastes = list("крэкер" = 1)
	foodtypes = GRAIN
	food_flags = FOOD_FINGER_FOOD
	w_class = WEIGHT_CLASS_TINY

/obj/item/food/hotdog
	name = "hotdog"
	desc = "Fresh footlong ready to go down on."
	icon_state = "hotdog"
	bite_consumption = 3
	food_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/nutriment/protein = 1, /datum/reagent/consumable/ketchup = 3, /datum/reagent/consumable/nutriment/vitamin = 6)
	tastes = list("булка" = 3, "мясо" = 2)
	foodtypes = GRAIN | MEAT | VEGETABLES
	w_class = WEIGHT_CLASS_SMALL
	venue_value = FOOD_PRICE_CHEAP

/obj/item/food/hotdog/debug
	eat_time = 0

/obj/item/food/meatbun
	name = "meat bun"
	desc = "Has the potential to not be Dog."
	icon_state = "meatbun"
	food_reagents = list(/datum/reagent/consumable/nutriment = 7, /datum/reagent/consumable/nutriment/vitamin = 4)
	tastes = list("булка" = 3, "мясо" = 2)
	foodtypes = GRAIN | MEAT | VEGETABLES
	w_class = WEIGHT_CLASS_SMALL
	venue_value = FOOD_PRICE_CHEAP

/obj/item/food/khachapuri
	name = "khachapuri"
	desc = "Bread with egg and cheese?"
	icon_state = "khachapuri"
	food_reagents = list(/datum/reagent/consumable/nutriment = 11, /datum/reagent/consumable/nutriment/protein = 3, /datum/reagent/consumable/nutriment/vitamin = 2)
	tastes = list("хлеб" = 1, "яйцо" = 1, "сыр" = 1)
	foodtypes = GRAIN | MEAT | DAIRY
	w_class = WEIGHT_CLASS_SMALL

/obj/item/food/cookie/sugar
	name = "sugar cookie"
	desc = "Just like your little sister used to make."
	icon_state = "sugarcookie"
	food_reagents = list(/datum/reagent/consumable/nutriment = 4, /datum/reagent/consumable/sugar = 6)
	tastes = list("сладость" = 1)
	foodtypes = GRAIN | JUNKFOOD | SUGAR

/obj/item/food/cookie/sugar/Initialize()
	. = ..()
	if(SSevents.holidays && SSevents.holidays[FESTIVE_SEASON])
		var/shape = pick("tree", "bear", "santa", "stocking", "present", "cane")
		desc = "A sugar cookie in the shape of a [shape]. I hope Santa likes it!"
		icon_state = "sugarcookie_[shape]"

/obj/item/food/chococornet
	name = "chocolate cornet"
	desc = "Which side's the head, the fat end or the thin end?"
	icon_state = "chococornet"
	food_reagents = list(/datum/reagent/consumable/nutriment = 6, /datum/reagent/consumable/nutriment/vitamin = 2)
	tastes = list("бисквит" = 3, "шоколад" = 1)
	foodtypes = GRAIN | JUNKFOOD
	w_class = WEIGHT_CLASS_SMALL

/obj/item/food/cookie/oatmeal
	name = "oatmeal cookie"
	desc = "The best of both cookie and oat."
	icon_state = "oatmealcookie"
	food_reagents = list(/datum/reagent/consumable/nutriment = 6, /datum/reagent/consumable/nutriment/vitamin = 2)
	tastes = list("печенька" = 2, "овсянка" = 1)
	foodtypes = GRAIN

/obj/item/food/cookie/raisin
	name = "raisin cookie"
	desc = "Why would you put raisins on a cookie?"
	icon_state = "raisincookie"
	food_reagents = list(/datum/reagent/consumable/nutriment = 6, /datum/reagent/consumable/nutriment/vitamin = 2)
	tastes = list("печенька" = 1, "причины" = 1)
	foodtypes = GRAIN | FRUIT

/obj/item/food/cherrycupcake
	name = "cherry cupcake"
	desc = "A sweet cupcake with cherry bits."
	icon_state = "cherrycupcake"
	food_reagents = list(/datum/reagent/consumable/nutriment = 6, /datum/reagent/consumable/nutriment/vitamin = 2)
	tastes = list("торт" = 3, "вишня" = 1)
	foodtypes = GRAIN | FRUIT | SUGAR
	food_flags = FOOD_FINGER_FOOD
	w_class = WEIGHT_CLASS_SMALL

/obj/item/food/cherrycupcake/blue
	name = "blue cherry cupcake"
	desc = "Blue cherries inside a delicious cupcake."
	icon_state = "bluecherrycupcake"
	food_reagents = list(/datum/reagent/consumable/nutriment = 6, /datum/reagent/consumable/nutriment/vitamin = 4)
	tastes = list("торт" = 3, "синяя вишня" = 1)

/obj/item/food/honeybun
	name = "honey bun"
	desc = "A sticky pastry bun glazed with honey."
	icon_state = "honeybun"
	food_reagents = list(/datum/reagent/consumable/nutriment = 6, /datum/reagent/consumable/honey = 6)
	tastes = list("кондитерские изделия" = 1, "сладость" = 1)
	foodtypes = GRAIN | SUGAR
	w_class = WEIGHT_CLASS_SMALL

#define PANCAKE_MAX_STACK 10

/obj/item/food/pancakes
	name = "pancake"
	desc = "A fluffy pancake. The softer, superior relative of the waffle."
	icon_state = "pancakes_1"
	inhand_icon_state = "pancakes"
	food_reagents = list(/datum/reagent/consumable/nutriment = 4, /datum/reagent/consumable/nutriment/vitamin = 2)
	tastes = list("блинчики" = 1)
	foodtypes = GRAIN | SUGAR | BREAKFAST
	w_class = WEIGHT_CLASS_SMALL
	burns_on_grill = TRUE
	venue_value = FOOD_PRICE_CHEAP

/obj/item/food/pancakes/raw
	name = "goopy pancake"
	desc = "A barely cooked mess that some may mistake for a pancake. It longs for the griddle."
	icon_state = "rawpancakes_1"
	inhand_icon_state = "rawpancakes"
	food_reagents = list(/datum/reagent/consumable/nutriment = 1, /datum/reagent/consumable/nutriment/vitamin = 1)
	tastes = list("milky batter" = 1)
	burns_on_grill = FALSE

/obj/item/food/pancakes/raw/MakeGrillable()
	AddComponent(/datum/component/grillable,\
				cook_result = /obj/item/food/pancakes,\
				required_cook_time = rand(30 SECONDS, 40 SECONDS),\
				positive_result = TRUE,\
				use_large_steam_sprite = TRUE)

/obj/item/food/pancakes/raw/attackby(obj/item/garnish, mob/living/user, params)
	var/newresult
	if(istype(garnish, /obj/item/food/grown/berries))
		newresult = /obj/item/food/pancakes/blueberry
		name = "raw blueberry pancake"
		icon_state = "rawbbpancakes_1"
		inhand_icon_state = "rawbbpancakes"
	else if(istype(garnish, /obj/item/food/chocolatebar))
		newresult = /obj/item/food/pancakes/chocolatechip
		name = "raw chocolate chip pancake"
		icon_state = "rawccpancakes_1"
		inhand_icon_state = "rawccpancakes"
	else
		return ..()
	if(newresult)
		qdel(garnish)
		to_chat(user, span_notice("You add [garnish] to [src]."))
		AddComponent(/datum/component/grillable, cook_result = newresult)

/obj/item/food/pancakes/raw/examine(mob/user)
	. = ..()
	if(name == initial(name))
		. += "<span class='notice'>\nYou can modify the pancake by adding <b>blueberries</b> or <b>chocolate</b> before finishing the griddle."

/obj/item/food/pancakes/blueberry
	name = "blueberry pancake"
	desc = "A fluffy and delicious blueberry pancake."
	icon_state = "bbpancakes_1"
	inhand_icon_state = "bbpancakes"
	food_reagents = list(/datum/reagent/consumable/nutriment = 6, /datum/reagent/consumable/nutriment/vitamin = 5)
	tastes = list("блинчики" = 1, "черника" = 1)

/obj/item/food/pancakes/chocolatechip
	name = "chocolate chip pancake"
	desc = "A fluffy and delicious chocolate chip pancake."
	icon_state = "ccpancakes_1"
	inhand_icon_state = "ccpancakes"
	food_reagents = list(/datum/reagent/consumable/nutriment = 6, /datum/reagent/consumable/nutriment/vitamin = 5)
	tastes = list("блинчики" = 1, "шоколад" = 1)

/obj/item/food/pancakes/Initialize()
	. = ..()
	update_icon()

/obj/item/food/pancakes/update_icon()
	if(contents.len)
		name = "stack of pancakes"
	else
		name = initial(name)
	if(contents.len < LAZYLEN(overlays))
		overlays-=overlays[overlays.len]

/obj/item/food/pancakes/examine(mob/user)
	var/ingredients_listed = ""
	var/pancakeCount = contents.len
	switch(pancakeCount)
		if(0)
			desc = initial(desc)
		if(1 to 2)
			desc = "A stack of fluffy pancakes."
		if(3 to 6)
			desc = "A fat stack of fluffy pancakes!"
		if(7 to 9)
			desc = "A grand tower of fluffy, delicious pancakes!"
		if(PANCAKE_MAX_STACK to INFINITY)
			desc = "A massive towering spire of fluffy, delicious pancakes. It looks like it could tumble over!"
	. = ..()
	if (pancakeCount)
		for(var/obj/item/food/pancakes/ING in contents)
			ingredients_listed += "[ING.name], "
		. += "It contains [contents.len?"[ingredients_listed]":"no ingredient, "]on top of a [initial(name)]."

/obj/item/food/pancakes/attackby(obj/item/item, mob/living/user, params)
	if(istype(item, /obj/item/food/pancakes))
		var/obj/item/food/pancakes/pancake = item
		if((contents.len >= PANCAKE_MAX_STACK) || ((pancake.contents.len + contents.len) > PANCAKE_MAX_STACK))
			to_chat(user, span_warning("You can't add that many pancakes to [src]!"))
		else
			if(!user.transferItemToLoc(pancake, src))
				return
			to_chat(user, span_notice("You add the [pancake] to the [src]."))
			pancake.name = initial(pancake.name)
			contents += pancake
			update_snack_overlays(pancake)
			if (pancake.contents.len)
				for(var/pancake_content in pancake.contents)
					pancake = pancake_content
					pancake.name = initial(pancake.name)
					contents += pancake
					update_snack_overlays(pancake)
			pancake = item
			pancake.contents.Cut()
		return
	else if(contents.len)
		var/obj/O = contents[contents.len]
		return O.attackby(item, user, params)
	..()

/obj/item/food/pancakes/proc/update_snack_overlays(obj/item/pancake)
	var/mutable_appearance/pancake_visual = mutable_appearance(icon, "[pancake.inhand_icon_state]_[rand(1,3)]")
	pancake_visual.pixel_x = rand(-1,1)
	pancake_visual.pixel_y = 3 * contents.len - 1
	add_overlay(pancake_visual)
	update_icon()

/obj/item/food/pancakes/attack(mob/M, mob/user, def_zone, stacked = TRUE)
	if(user.a_intent == INTENT_HARM || !contents.len || !stacked)
		return ..()
	var/obj/item/O = contents[contents.len]
	. = O.attack(M, user, def_zone, FALSE)
	update_icon()

#undef PANCAKE_MAX_STACK

/obj/item/food/cannoli
	name = "cannoli"
	desc = "A sicilian treat that makes you into a wise guy."
	icon_state = "cannoli"
	food_reagents = list(/datum/reagent/consumable/nutriment = 6, /datum/reagent/consumable/nutriment/vitamin = 2)
	tastes = list("кондитерские изделия" = 1)
	foodtypes = GRAIN | DAIRY | SUGAR
	w_class = WEIGHT_CLASS_TINY


#undef DONUT_SPRINKLE_CHANCE
