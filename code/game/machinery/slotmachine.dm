/*******************************\
|		  Slot Machines		  	|
|	  Original code by Glloyd	|
|	  Tgstation port by Miauw	|
\*******************************/

#define SPIN_PRICE 5
#define SMALL_PRIZE 400
#define BIG_PRIZE 1000
#define JACKPOT 10000
#define SPIN_TIME 65 //As always, deciseconds.
#define REEL_DEACTIVATE_DELAY 7
#define SEVEN span_red("7")
#define HOLOCHIP 1
#define COIN 2

/obj/machinery/computer/slot_machine
	name = "однорукий бандит"
	desc = "Для самых смелых."
	icon = 'icons/obj/computer.dmi'
	icon_state = "slots"
	icon_keyboard = "no_keyboard"
	icon_screen = "slots_screen"
	density = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = 50
	circuit = /obj/item/circuitboard/computer/slot_machine
	light_color = LIGHT_COLOR_BROWN
	var/money = 3000 //How much money it has CONSUMED
	var/plays = 0
	var/working = FALSE
	var/balance = 0 //How much money is in the machine, ready to be CONSUMED.
	var/jackpots = 0
	var/paymode = HOLOCHIP //toggles between HOLOCHIP/COIN, defined above
	var/cointype = /obj/item/coin/iron //default cointype
	var/list/coinvalues = list()
	var/list/reels = list(list("", "", "") = 0, list("", "", "") = 0, list("", "", "") = 0, list("", "", "") = 0, list("", "", "") = 0)
	var/list/symbols = list(SEVEN = 1, "<font color='orange'>&</font>" = 2, "<font color='yellow'>@</font>" = 2, "<font color='green'>$</font>" = 2, "<font color='blue'>?</font>" = 2, "<font color='grey'>#</font>" = 2, "<font color='white'>!</font>" = 2, "<font color='fuchsia'>%</font>" = 2) //if people are winning too much, multiply every number in this list by 2 and see if they are still winning too much.


/obj/machinery/computer/slot_machine/Initialize()
	. = ..()
	jackpots = rand(1, 4) //false hope
	plays = rand(75, 200)

	INVOKE_ASYNC(src, PROC_REF(toggle_reel_spin), TRUE)//The reels won't spin unless we activate them

	var/list/reel = reels[1]
	for(var/i = 0, i < reel.len, i++) //Populate the reels.
		randomize_reels()

	INVOKE_ASYNC(src, PROC_REF(toggle_reel_spin), FALSE)

	for(cointype in typesof(/obj/item/coin))
		var/obj/item/coin/C = new cointype
		coinvalues["[cointype]"] = C.get_item_credit_value()
		qdel(C) //Sigh

/obj/machinery/computer/slot_machine/Destroy()
	if(balance)
		give_payout(balance)
	return ..()

/obj/machinery/computer/slot_machine/process(delta_time)
	. = ..() //Sanity checks.
	if(!.)
		return .

	money += round(delta_time / 2) //SPESSH MAJICKS

/obj/machinery/computer/slot_machine/update_icon_state()
	if(machine_stat & BROKEN)
		icon_state = "slots_broken"
	else
		icon_state = "slots"
	return ..()

/obj/machinery/computer/slot_machine/update_overlays()
	if(working)
		icon_screen = "slots_screen_working"
	else
		icon_screen = "slots_screen"
	return ..()

/obj/machinery/computer/slot_machine/attackby(obj/item/I, mob/living/user, params)
	if(istype(I, /obj/item/coin))
		var/obj/item/coin/C = I
		if(paymode == COIN)
			if(prob(2))
				if(!user.transferItemToLoc(C, drop_location(), silent = FALSE))
					return
				C.throw_at(user, 3, 10)
				if(prob(10))
					balance = max(balance - SPIN_PRICE, 0)
				to_chat(user, span_warning("[capitalize(src.name)] spits your coin back out!"))

			else
				if(!user.temporarilyRemoveItemFromInventory(C))
					return
				to_chat(user, span_notice("You insert [C] into [src] slot!"))
				balance += C.value
				qdel(C)
		else
			to_chat(user, span_warning("This machine is only accepting holochips!"))
	else if(istype(I, /obj/item/holochip))
		if(paymode == HOLOCHIP)
			var/obj/item/holochip/H = I
			if(!user.temporarilyRemoveItemFromInventory(H))
				return
			to_chat(user, span_notice("You insert [H.credits] holocredits into [src] slot!"))
			balance += H.credits
			qdel(H)
		else
			to_chat(user, span_warning("This machine is only accepting coins!"))
	else if(I.tool_behaviour == TOOL_MULTITOOL)
		if(balance > 0)
			visible_message("<b>[capitalize(src.name)]</b> says, 'ERROR! Please empty the machine balance before altering paymode'") //Prevents converting coins into holocredits and vice versa
		else
			if(paymode == HOLOCHIP)
				paymode = COIN
				visible_message("<b>[capitalize(src.name)]</b> says, 'This machine now works with COINS!'")
			else
				paymode = HOLOCHIP
				visible_message("<b>[capitalize(src.name)]</b> says, 'This machine now works with HOLOCHIPS!'")
	else
		return ..()

/obj/machinery/computer/slot_machine/emag_act()
	if(obj_flags & EMAGGED)
		return
	obj_flags |= EMAGGED
	var/datum/effect_system/spark_spread/spark_system = new /datum/effect_system/spark_spread()
	spark_system.set_up(4, 0, src.loc)
	spark_system.start()
	playsound(src, "sparks", 50, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)

/obj/machinery/computer/slot_machine/ui_interact(mob/living/user)
	. = ..()
	var/reeltext = {"<center><font face=\"courier new\">
	/*****^*****^*****^*****^*****\\<BR>
	| \[[reels[1][1]]\] | \[[reels[2][1]]\] | \[[reels[3][1]]\] | \[[reels[4][1]]\] | \[[reels[5][1]]\] |<BR>
	| \[[reels[1][2]]\] | \[[reels[2][2]]\] | \[[reels[3][2]]\] | \[[reels[4][2]]\] | \[[reels[5][2]]\] |<BR>
	| \[[reels[1][3]]\] | \[[reels[2][3]]\] | \[[reels[3][3]]\] | \[[reels[4][3]]\] | \[[reels[5][3]]\] |<BR>
	\\*****v*****v*****v*****v*****/<BR>
	</center></font>"}

	var/dat
	if(working)
		dat = reeltext

	else
		dat = {"Five credits to play!<BR>
		<B>Prize Money Available:</B> [money] (jackpot payout is ALWAYS 100%!)<BR>
		<B>Credit Remaining:</B> [balance]<BR>
		[plays] players have tried their luck today, and [jackpots] have won a jackpot!<BR>
		<HR><BR>
		<A href='?src=[REF(src)];spin=1'>Play!</A><BR>
		<BR>
		[reeltext]
		<BR>"}
		if(balance > 0)
			dat+="<font size='1'><A href='?src=[REF(src)];refund=1'>Refund balance</A><BR>"

	var/datum/browser/popup = new(user, "slotmachine", "Slot Machine")
	popup.set_content(dat)
	popup.open()

/obj/machinery/computer/slot_machine/Topic(href, href_list)
	. = ..() //Sanity checks.
	if(.)
		return .

	if(href_list["spin"])
		spin(usr)

	else if(href_list["refund"])
		if(balance > 0)
			give_payout(balance)
			balance = 0

/obj/machinery/computer/slot_machine/emp_act(severity)
	. = ..()
	if(machine_stat & (NOPOWER|BROKEN) || . & EMP_PROTECT_SELF)
		return
	if(prob(15 * severity))
		return
	if(prob(1)) // :^)
		obj_flags |= EMAGGED
	var/severity_ascending = 4 - severity
	money = max(rand(money - (200 * severity_ascending), money + (200 * severity_ascending)), 0)
	balance = max(rand(balance - (50 * severity_ascending), balance + (50 * severity_ascending)), 0)
	money -= max(0, give_payout(min(rand(-50, 100 * severity_ascending)), money)) //This starts at -50 because it shouldn't always dispense coins yo
	spin()

/obj/machinery/computer/slot_machine/proc/spin(mob/user)
	if(!can_spin(user))
		return

	var/the_name
	if(user)
		the_name = user.real_name
		visible_message(span_notice("[user] pulls the lever and the slot machine starts spinning!"))
	else
		the_name = "Exaybachay"

	balance -= SPIN_PRICE
	money += SPIN_PRICE
	plays += 1
	working = TRUE

	toggle_reel_spin(1)
	update_icon()
	updateDialog()

	var/spin_loop = addtimer(CALLBACK(src, PROC_REF(do_spin)), 2, TIMER_LOOP|TIMER_STOPPABLE)

	addtimer(CALLBACK(src, PROC_REF(finish_spinning), spin_loop, user, the_name), SPIN_TIME - (REEL_DEACTIVATE_DELAY * reels.len))
	//WARNING: no sanity checking for user since it's not needed and would complicate things (machine should still spin even if user is gone), be wary of this if you're changing this code.

/obj/machinery/computer/slot_machine/proc/do_spin()
	randomize_reels()
	updateDialog()

/obj/machinery/computer/slot_machine/proc/finish_spinning(spin_loop, mob/user, the_name)
	toggle_reel_spin(0, REEL_DEACTIVATE_DELAY)
	working = FALSE
	deltimer(spin_loop)
	give_prizes(the_name, user)
	update_icon()
	updateDialog()

/obj/machinery/computer/slot_machine/proc/can_spin(mob/user)
	if(machine_stat & NOPOWER)
		to_chat(user, span_warning("The slot machine has no power!"))
		return FALSE
	if(machine_stat & BROKEN)
		to_chat(user, span_warning("The slot machine is broken!"))
		return FALSE
	if(working)
		to_chat(user, span_warning("You need to wait until the machine stops spinning before you can play again!"))
		return FALSE
	if(balance < SPIN_PRICE)
		to_chat(user, span_warning("Insufficient money to play!"))
		return FALSE
	return TRUE

/obj/machinery/computer/slot_machine/proc/toggle_reel_spin(value, delay = 0) //value is 1 or 0 aka on or off
	for(var/list/reel in reels)
		reels[reel] = value
		sleep(delay)

/obj/machinery/computer/slot_machine/proc/randomize_reels()

	for(var/reel in reels)
		if(reels[reel])
			reel[3] = reel[2]
			reel[2] = reel[1]
			reel[1] = pick(symbols)

/obj/machinery/computer/slot_machine/proc/give_prizes(usrname, mob/user)
	var/linelength = get_lines()

	if(reels[1][2] + reels[2][2] + reels[3][2] + reels[4][2] + reels[5][2] == "[SEVEN][SEVEN][SEVEN][SEVEN][SEVEN]")
		visible_message("<b>[capitalize(src.name)]</b> says, 'JACKPOT! You win [money] credits!'")
		priority_announce("Поздравляем [user ? user.real_name : usrname] за выигрыш джекпота на игровом автомате в [get_area(src)]!")
		jackpots += 1
		balance += money - give_payout(JACKPOT)
		money = 0
		if(paymode == HOLOCHIP)
			new /obj/item/holochip(loc,JACKPOT)
		else
			for(var/i = 0, i < 5, i++)
				cointype = pick(subtypesof(/obj/item/coin))
				var/obj/item/coin/C = new cointype(loc)
				random_step(C, 2, 50)

	else if(linelength == 5)
		visible_message("<b>[capitalize(src.name)]</b> says, 'Big Winner! You win a thousand credits!'")
		give_money(BIG_PRIZE)

	else if(linelength == 4)
		visible_message("<b>[capitalize(src.name)]</b> says, 'Winner! You win four hundred credits!'")
		give_money(SMALL_PRIZE)

	else if(linelength == 3)
		to_chat(user, span_notice("You win three free games!"))
		balance += SPIN_PRICE * 4
		money = max(money - SPIN_PRICE * 4, money)

	else
		to_chat(user, span_warning("No luck!"))

/obj/machinery/computer/slot_machine/proc/get_lines()
	var/amountthesame

	for(var/i = 1, i <= 3, i++)
		var/inputtext = reels[1][i] + reels[2][i] + reels[3][i] + reels[4][i] + reels[5][i]
		for(var/symbol in symbols)
			var/j = 3 //The lowest value we have to check for.
			var/symboltext = symbol + symbol + symbol
			while(j <= 5)
				if(findtext(inputtext, symboltext))
					amountthesame = max(j, amountthesame)
				j++
				symboltext += symbol

			if(amountthesame)
				break

	return amountthesame

/obj/machinery/computer/slot_machine/proc/give_money(amount)
	var/amount_to_give = money >= amount ? amount : money
	var/surplus = amount_to_give - give_payout(amount_to_give)
	money = max(0, money - amount)
	balance += surplus

/obj/machinery/computer/slot_machine/proc/give_payout(amount)
	if(paymode == HOLOCHIP)
		cointype = /obj/item/holochip
	else
		cointype = obj_flags & EMAGGED ? /obj/item/coin/iron : /obj/item/coin/silver

	if(!(obj_flags & EMAGGED))
		amount = dispense(amount, cointype, null, 0)

	else
		var/mob/living/target = locate() in range(2, src)

		amount = dispense(amount, cointype, target, 1)

	return amount

/obj/machinery/computer/slot_machine/proc/dispense(amount = 0, cointype = /obj/item/coin/silver, mob/living/target, throwit = 0)
	if(paymode == HOLOCHIP)
		var/obj/item/holochip/H = new /obj/item/holochip(loc,amount)

		if(throwit && target)
			H.throw_at(target, 3, 10)
	else
		var/value = coinvalues["[cointype]"]
		if(value <= 0)
			CRASH("Coin value of zero, refusing to payout in dispenser")
		while(amount >= value)
			var/obj/item/coin/C = new cointype(loc) //DOUBLE THE PAIN
			amount -= value
			if(throwit && target)
				C.throw_at(target, 3, 10)
			else
				random_step(C, 2, 40)

	return amount

#undef SEVEN
#undef SPIN_TIME
#undef JACKPOT
#undef BIG_PRIZE
#undef SMALL_PRIZE
#undef SPIN_PRICE
#undef HOLOCHIP
#undef COIN
