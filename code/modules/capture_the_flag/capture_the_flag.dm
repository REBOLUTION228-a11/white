#define WHITE_TEAM "White"
#define RED_TEAM "Red"
#define BLUE_TEAM "Blue"
#define GREEN_TEAM "Green"
#define YELLOW_TEAM "Yellow"
#define FLAG_RETURN_TIME 200 // 20 seconds
#define INSTAGIB_RESPAWN 50 //5 seconds
#define DEFAULT_RESPAWN 150 //15 seconds
#define AMMO_DROP_LIFETIME 300

/obj/item/ctf
	name = "Баннер"
	icon = 'icons/obj/banner.dmi'
	icon_state = "banner"
	inhand_icon_state = "banner"
	lefthand_file = 'icons/mob/inhands/equipment/banners_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/banners_righthand.dmi'
	desc = "Баннер с логотипом NanoTrasen."
	slowdown = 2
	throw_speed = 0
	throw_range = 1
	force = 200
	armour_penetration = 1000
	resistance_flags = INDESTRUCTIBLE
	anchored = TRUE
	item_flags = SLOWS_WHILE_IN_HAND
	var/team = WHITE_TEAM
	var/reset_cooldown = 0
	var/anyonecanpickup = TRUE
	var/obj/effect/ctf/flag_reset/reset
	var/reset_path = /obj/effect/ctf/flag_reset
	/// Which area we announce updates on the flag to. Should just generally be the area of the arena.
	var/game_area = /area/ctf

/obj/item/ctf/Destroy()
	QDEL_NULL(reset)
	return ..()

/obj/item/ctf/Initialize()
	. = ..()
	if(!reset)
		reset = new reset_path(get_turf(src))
		reset.flag = src
	RegisterSignal(src, COMSIG_PARENT_PREQDELETED, PROC_REF(reset_flag)) //just in case CTF has some map hazards (read: chasms).

/obj/item/ctf/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/two_handed, require_twohands = TRUE)

/obj/item/ctf/process()
	if(is_ctf_target(loc)) //pickup code calls temporary drops to test things out, we need to make sure the flag doesn't reset from
		return PROCESS_KILL
	if(world.time > reset_cooldown)
		reset_flag()

/obj/item/ctf/proc/reset_flag(capture = FALSE)
	SIGNAL_HANDLER

	var/turf/our_turf = get_turf(src.reset)
	if(!our_turf)
		return TRUE
	forceMove(our_turf)
	for(var/mob/M in GLOB.player_list)
		var/area/mob_area = get_area(M)
		if(istype(mob_area, game_area))
			if(!capture)
				to_chat(M, span_userdanger("[src] возвращен на базу!"))
	STOP_PROCESSING(SSobj, src)
	return TRUE //so if called by a signal, it doesn't delete

//working with attack hand feels like taking my brain and putting it through an industrial pill press so i'm gonna be a bit liberal with the comments
/obj/item/ctf/attack_hand(mob/living/user)
	//pre normal check item stuff, this is for our special flag checks
	if(!is_ctf_target(user) && !anyonecanpickup)
		to_chat(user, span_warning("Флаг могут двигать только игроки!"))
		return
	if(team in user.faction)
		to_chat(user, span_warning("Не могу двигать свой флаг!"))
		return
	if(loc == user)
		if(!user.dropItemToGround(src))
			return
	for(var/mob/M in GLOB.player_list)
		var/area/mob_area = get_area(M)
		if(istype(mob_area, game_area))
			to_chat(M, span_userdanger("[initial(src.name)] взят!"))
	STOP_PROCESSING(SSobj, src)
	anchored = FALSE //normal checks need this to be FALSE to pass
	. = ..() //this is the actual normal item checks
	if(.) //only apply these flag passives
		anchored = TRUE
		return
	//passing means the user picked up the flag so we can now apply this
	user.set_anchored(TRUE)
	user.status_flags &= ~CANPUSH

/obj/item/ctf/dropped(mob/user)
	..()
	user.set_anchored(FALSE)
	user.status_flags |= CANPUSH
	reset_cooldown = world.time + 20 SECONDS
	START_PROCESSING(SSobj, src)
	for(var/mob/M in GLOB.player_list)
		var/area/mob_area = get_area(M)
		if(istype(mob_area, game_area))
			to_chat(M, span_userdanger("\The [initial(name)] упал!"))
	anchored = TRUE


/obj/item/ctf/red
	name = "Красный флаг"
	icon_state = "banner-red"
	inhand_icon_state = "banner-red"
	desc = "Красное знамя, используемое в \"Захвате Флага\"."
	team = RED_TEAM
	reset_path = /obj/effect/ctf/flag_reset/red


/obj/item/ctf/blue
	name = "Синий флаг"
	icon_state = "banner-blue"
	inhand_icon_state = "banner-blue"
	desc = "Синее знамя, используемое в \"Захвате Флага\"."
	team = BLUE_TEAM
	reset_path = /obj/effect/ctf/flag_reset/blue

/obj/item/ctf/green
	name = "Зелёный флаг"
	icon_state = "banner-green"
	inhand_icon_state = "banner-green"
	desc = "A green banner used to play capture the flag."
	team = GREEN_TEAM
	reset_path = /obj/effect/ctf/flag_reset/green


/obj/item/ctf/yellow
	name = "Желтый флаг"
	icon_state = "banner-yellow"
	inhand_icon_state = "banner-yellow"
	desc = "A yellow banner used to play capture the flag."
	team = YELLOW_TEAM
	reset_path = /obj/effect/ctf/flag_reset/yellow

/obj/effect/ctf/flag_reset
	name = "Точка знамени"
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "banner"
	desc = "Сюда вставляется знамя NanoTrasen."
	layer = LOW_ITEM_LAYER
	var/obj/item/ctf/flag

/obj/effect/ctf/flag_reset/Destroy()
	if(flag)
		flag.reset = null
		flag = null
	return ..()

/obj/effect/ctf/flag_reset/red
	name = "Точка красного флага"
	icon_state = "banner-red"
	desc = "Сюда вставляется красный флаг."

/obj/effect/ctf/flag_reset/blue
	name = "Точка синего флага"
	icon_state = "banner-blue"
	desc = "Сюда вставляется синий флаг."

/obj/effect/ctf/flag_reset/green
	name = "Точка зелёного флага"
	icon_state = "banner"
	desc = "Сюда вставляется зелёный флаг."

/obj/effect/ctf/flag_reset/yellow
	name = "Точка жёлтого флага"
	icon_state = "banner"
	desc = "Сюда вставляется жёлтый флаг."

/proc/toggle_id_ctf(user, activated_id, automated = FALSE)
	var/ctf_enabled = FALSE
	var/area/A
	for(var/obj/machinery/capture_the_flag/CTF in GLOB.machines)
		if(activated_id != CTF.game_id)
			continue
		ctf_enabled = CTF.toggle_ctf()
		A = get_area(CTF)
	for(var/obj/machinery/power/emitter/E in A)
		E.active = ctf_enabled
	if(user)
		message_admins("[key_name_admin(user)] has [ctf_enabled ? "enabled" : "disabled"] CTF!")
	else if(automated)
		message_admins("CTF has finished a round and automatically restarted.")
		notify_ghosts("CTF has automatically restarted after a round finished in [A]!",'sound/effects/ghost2.ogg')
	else
		message_admins("The players have spoken! Voting has enabled CTF!")
	if(!automated)
		notify_ghosts("CTF has been [ctf_enabled? "enabled" : "disabled"] in [A]!",'sound/effects/ghost2.ogg')

/obj/machinery/capture_the_flag
	name = "Контроллер \"Захвата Флага\""
	desc = "Используется для \"Захвата Флага\"."
	icon = 'icons/obj/device.dmi'
	icon_state = "syndbeacon"
	resistance_flags = INDESTRUCTIBLE
	var/game_id = "centcom"

	var/victory_rejoin_text = span_userdanger("Игра окончена. Кликните на контроллеры чтобы проголосовать за новый раунд \"Захвата Флага\"")
	var/team = WHITE_TEAM
	var/team_span = ""
	//Capture the Flag scoring
	var/points = 0
	var/points_to_win = 3
	var/respawn_cooldown = DEFAULT_RESPAWN
	//Capture Point/King of the Hill scoring
	var/control_points = 0
	var/control_points_to_win = 180
	var/list/team_members = list()
	///assoc list: mob = outfit datum (class)
	var/list/spawned_mobs = list()
	var/list/recently_dead_ckeys = list()
	var/ctf_enabled = FALSE
	///assoc list for classes. If there's only one, it'll just equip. Otherwise, it lets you pick which outfit!
	var/list/ctf_gear = list("white" = /datum/outfit/ctf)
	var/instagib_gear = /datum/outfit/ctf/instagib
	var/ammo_type = /obj/effect/ctf/ammo

	// Fast paced gameplay, no real time for burn infections.
	var/player_traits = list(TRAIT_NEVER_WOUNDED)

	var/list/dead_barricades = list()

	var/static/arena_reset = FALSE
	var/static/list/people_who_want_to_play = list()
	var/game_area = /area/ctf

/obj/machinery/capture_the_flag/Initialize()
	. = ..()
	AddElement(/datum/element/point_of_interest)

/obj/machinery/capture_the_flag/process(delta_time)
	for(var/i in spawned_mobs)
		if(!i)
			spawned_mobs -= i
			continue
		// Anyone in crit, automatically reap
		var/mob/living/living_participant = i
		if(HAS_TRAIT(living_participant, TRAIT_CRITICAL_CONDITION) || living_participant.stat == DEAD)
			ctf_dust_old(living_participant)
		else
			// The changes that you've been hit with no shield but not
			// instantly critted are low, but have some healing.
			living_participant.adjustBruteLoss(-2.5 * delta_time)
			living_participant.adjustFireLoss(-2.5 * delta_time)

/obj/machinery/capture_the_flag/red
	name = "Красный контроллер \"Захвата Флага\""
	icon_state = "syndbeacon"
	team = RED_TEAM
	team_span = "redteamradio"
	ctf_gear = list("red" = /datum/outfit/ctf/red)
	instagib_gear = /datum/outfit/ctf/red/instagib

/obj/machinery/capture_the_flag/blue
	name = "Синий контроллер \"Захвата Флага\""
	icon_state = "bluebeacon"
	team = BLUE_TEAM
	team_span = "blueteamradio"
	ctf_gear = list("blue" = /datum/outfit/ctf/blue)
	instagib_gear = /datum/outfit/ctf/blue/instagib

/obj/machinery/capture_the_flag/blue/warfare
	player_traits = list()
	ctf_gear = list("blue" = /datum/outfit/ctf/blue/warfare)

/obj/machinery/capture_the_flag/green
	name = "Зелёный контроллер \"Захвата Флага\""
	icon_state = "greenbeacon"
	team = GREEN_TEAM
	team_span = "greenteamradio"
	ctf_gear = list("green" = /datum/outfit/ctf/green)
	instagib_gear = /datum/outfit/ctf/green/instagib

/obj/machinery/capture_the_flag/yellow
	name = "Жёлтый контроллер \"Захвата Флага\""
	icon_state = "yellowbeacon"
	team = YELLOW_TEAM
	team_span = "yellowteamradio"
	ctf_gear = list("yellow" = /datum/outfit/ctf/yellow)
	instagib_gear = /datum/outfit/ctf/yellow/instagib

/obj/machinery/capture_the_flag/yellow/warfare
	player_traits = list()
	ctf_gear = list("yellow" = /datum/outfit/ctf/yellow/warfare)

//ATTACK GHOST IGNORING PARENT RETURN VALUE
/obj/machinery/capture_the_flag/attack_ghost(mob/user)
	if(ctf_enabled == FALSE)
		if(user.client && user.client.holder)
			var/response = tgui_alert(usr,"Enable this CTF game?", "CTF", list("Yes", "No"))
			if(response == "Yes")
				toggle_id_ctf(user, game_id)
			return


		if(!(GLOB.ghost_role_flags & GHOSTROLE_MINIGAME))
			to_chat(user, span_warning("\"Захват Флага\" был отключен администрацией."))
			return
		for(var/obj/machinery/capture_the_flag/CTF in GLOB.machines)
			if(CTF.game_id != game_id && CTF.ctf_enabled)
				to_chat(user, span_warning("На [get_area(CTF)] уже проводится игра!"))
				return
		people_who_want_to_play |= user.ckey
		var/num = people_who_want_to_play.len
		var/remaining = CTF_REQUIRED_PLAYERS - num
		if(remaining <= 0)
			people_who_want_to_play.Cut()
			toggle_id_ctf(null, game_id)
		else
			to_chat(user, span_notice("Запрос на запуск \"Захвата Флага\". [num]/[CTF_REQUIRED_PLAYERS] игроков готово."))

		return

	if(!SSticker.HasRoundStarted())
		return
	if(user.ckey in team_members)
		if(user.ckey in recently_dead_ckeys)
			to_chat(user, span_warning("Нужно подождать еще [DisplayTimeText(respawn_cooldown)] с моей смерти!"))
			return
		var/client/new_team_member = user.client
		if(user.mind && user.mind.current)
			ctf_dust_old(user.mind.current)
		spawn_team_member(new_team_member)
		return

	for(var/obj/machinery/capture_the_flag/CTF in GLOB.machines)
		if(CTF.game_id != game_id || CTF == src || CTF.ctf_enabled == FALSE)
			continue
		if(user.ckey in CTF.team_members)
			to_chat(user, span_warning("Нельзя менять команду во время раунда!"))
			return
		if(CTF.team_members.len < src.team_members.len)
			to_chat(user, span_warning("В [src.team] больше игроков чем в [CTF.team]! Попробуй присоединиться к [CTF.team] команде чтобы все было честно."))
			return
	var/client/new_team_member = user.client
	if(user.mind && user.mind.current)
		ctf_dust_old(user.mind.current)
	spawn_team_member(new_team_member)

//does not add to recently dead, because it dusts and that triggers ctf_qdelled_player
/obj/machinery/capture_the_flag/proc/ctf_dust_old(mob/living/body)
	if(isliving(body) && (team in body.faction))
		var/turf/T = get_turf(body)
		if(ammo_type)
			new ammo_type(T)
		body.dust()

/obj/machinery/capture_the_flag/proc/ctf_qdelled_player(mob/living/body)
	SIGNAL_HANDLER

	recently_dead_ckeys += body.ckey
	addtimer(CALLBACK(src, PROC_REF(clear_cooldown), body.ckey), respawn_cooldown, TIMER_UNIQUE)

/obj/machinery/capture_the_flag/proc/clear_cooldown(ckey)
	recently_dead_ckeys -= ckey

/obj/machinery/capture_the_flag/proc/spawn_team_member(client/new_team_member)
	var/datum/outfit/chosen_class
	if(ctf_gear.len == 1) //no choices to make
		for(var/key in ctf_gear)
			chosen_class = ctf_gear[key]
	else if(ctf_gear.len > 3) //a lot of choices, so much that we can't use a basic alert
		var/result = input(new_team_member, "Select a class.", "CTF") as null|anything in sort_list(ctf_gear)
		if(!result || !(GLOB.ghost_role_flags & GHOSTROLE_MINIGAME) || (new_team_member.ckey in recently_dead_ckeys) || !isobserver(new_team_member.mob))
			return //picked nothing, admin disabled it, cheating to respawn faster, cheating to respawn... while in game?
		chosen_class = ctf_gear[result]
	else //2-3 choices
		var/list/names_only = assoc_list_strip_value(ctf_gear)
		names_only.len += 1 //create a new null entry so if it's a 2-sized list, names_only[3] is null instead of out of bounds
		var/result = tgui_alert(new_team_member, "Select a class.", "CTF", list(names_only[1], names_only[2], names_only[3]))
		if(!result || !(GLOB.ghost_role_flags & GHOSTROLE_MINIGAME) || (new_team_member.ckey in recently_dead_ckeys) || !isobserver(new_team_member.mob))
			return //picked nothing, admin disabled it, cheating to respawn faster, cheating to respawn... while in game?
		chosen_class = ctf_gear[result]
	var/mob/living/carbon/human/M = new /mob/living/carbon/human(get_turf(src))
	new_team_member.prefs.copy_to(M)
	M.set_species(/datum/species/synth)
	M.key = new_team_member.key
	M.faction += team
	M.equipOutfit(chosen_class)
	RegisterSignal(M, COMSIG_PARENT_QDELETING, PROC_REF(ctf_qdelled_player)) //just in case CTF has some map hazards (read: chasms). bit shorter than dust
	for(var/trait in player_traits)
		ADD_TRAIT(M, trait, CAPTURE_THE_FLAG_TRAIT)
	spawned_mobs[M] = chosen_class
	team_members |= new_team_member.ckey
	return M //used in medisim.dm

/obj/machinery/capture_the_flag/Topic(href, href_list)
	if(href_list["join"])
		var/mob/dead/observer/ghost = usr
		if(istype(ghost))
			attack_ghost(ghost)

/obj/machinery/capture_the_flag/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/ctf))
		var/obj/item/ctf/flag = I
		if(flag.team != src.team)
			points++
			flag.reset_flag(capture = TRUE)
			for(var/mob/ctf_player in GLOB.player_list)
				var/area/mob_area = get_area(ctf_player)
				if(istype(mob_area, game_area))
					to_chat(ctf_player, "<span class='userdanger [team_span]'>[user.real_name] захватил \ [flag] и заработал очко для [team] команды! Теперь у них [points]/[points_to_win] очков!</span>")
			if(points >= points_to_win)
				victory()

/obj/machinery/capture_the_flag/proc/victory()
	for(var/mob/_competitor in GLOB.mob_living_list)
		var/mob/living/competitor = _competitor
		var/area/mob_area = get_area(competitor)
		if(istype(mob_area, game_area))
			to_chat(competitor, "<span class='narsie [team_span]'>[team] команда победила!</span>")
			to_chat(competitor, victory_rejoin_text)
			for(var/obj/item/ctf/W in competitor)
				competitor.dropItemToGround(W)
			competitor.dust()
	for(var/obj/machinery/control_point/control in GLOB.machines)
		control.icon_state = "dominator"
		control.controlling = null
	for(var/obj/machinery/capture_the_flag/CTF in GLOB.machines)
		if(CTF.game_id != game_id)
			continue
		if(CTF.ctf_enabled == TRUE)
			CTF.points = 0
			CTF.control_points = 0
			CTF.ctf_enabled = FALSE
			CTF.team_members = list()
			CTF.arena_reset = FALSE

/obj/machinery/capture_the_flag/proc/toggle_ctf()
	if(!ctf_enabled)
		start_ctf()
		. = TRUE
	else
		stop_ctf()
		. = FALSE

/obj/machinery/capture_the_flag/proc/start_ctf()
	ctf_enabled = TRUE
	for(var/d in dead_barricades)
		var/obj/effect/ctf/dead_barricade/D = d
		D.respawn()

	dead_barricades.Cut()

	notify_ghosts("[name] активирован!", enter_link="<a href=?src=[REF(src)];join=1>(Нажми чтобы присоединиться к [team] команде!)</a> или нажми прямо на контроллер!", source = src, action=NOTIFY_ATTACK, header = "\"Захват флага\" активирован")

	if(!arena_reset)
		reset_the_arena()
		arena_reset = TRUE

/obj/machinery/capture_the_flag/proc/reset_the_arena()
	var/area/A = get_area(src)
	var/list/ctf_object_typecache = typecacheof(list(
				/obj/machinery,
				/obj/effect/ctf,
				/obj/item/ctf
			))
	for(var/atm in A)
		if (isturf(A) || ismob(A) || isarea(A))
			continue
		if(isstructure(atm))
			var/obj/structure/S = atm
			S.obj_integrity = S.max_integrity
		else if(!is_type_in_typecache(atm, ctf_object_typecache))
			qdel(atm)


/obj/machinery/capture_the_flag/proc/stop_ctf()
	ctf_enabled = FALSE
	arena_reset = FALSE
	var/area/A = get_area(src)
	for(var/_competitor in GLOB.mob_living_list)
		var/mob/living/competitor = _competitor
		if((get_area(A) == A) && (competitor.ckey in team_members))
			competitor.dust()
	team_members.Cut()
	spawned_mobs.Cut()
	recently_dead_ckeys.Cut()

/obj/machinery/capture_the_flag/proc/instagib_mode()
	for(var/obj/machinery/capture_the_flag/CTF in GLOB.machines)
		if(CTF.game_id != game_id)
			continue
		if(CTF.ctf_enabled == TRUE)
			CTF.ctf_gear = CTF.instagib_gear
			CTF.respawn_cooldown = INSTAGIB_RESPAWN

/obj/machinery/capture_the_flag/proc/normal_mode()
	for(var/obj/machinery/capture_the_flag/CTF in GLOB.machines)
		if(CTF.game_id != game_id)
			continue
		if(CTF.ctf_enabled == TRUE)
			CTF.ctf_gear = initial(ctf_gear)
			CTF.respawn_cooldown = DEFAULT_RESPAWN

/obj/item/gun/ballistic/automatic/pistol/deagle/ctf
	desc = "Неплохо в ближнем бою."
	force = 75
	mag_type = /obj/item/ammo_box/magazine/m50/ctf

/obj/item/gun/ballistic/automatic/pistol/deagle/ctf/dropped()
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(floor_vanish)), 1)

/obj/item/gun/ballistic/automatic/pistol/deagle/ctf/proc/floor_vanish()
	if(isturf(loc))
		qdel(src)

/obj/item/ammo_box/magazine/m50/ctf
	ammo_type = /obj/item/ammo_casing/a50/ctf

/obj/item/ammo_casing/a50/ctf
	projectile_type = /obj/projectile/bullet/ctf

/obj/projectile/bullet/ctf
	damage = 0

/obj/projectile/bullet/ctf/prehit_pierce(atom/target)
	if(is_ctf_target(target))
		damage = 60
		return PROJECTILE_PIERCE_NONE	/// hey uhh don't hit anyone behind them
	. = ..()

/obj/item/gun/ballistic/automatic/laser/ctf
	mag_type = /obj/item/ammo_box/magazine/recharge/ctf
	desc = "Неплохо в ближнем бою."
	force = 50

/obj/item/gun/ballistic/automatic/laser/ctf/dropped()
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(floor_vanish)), 1)

/obj/item/gun/ballistic/automatic/laser/ctf/proc/floor_vanish()
	if(isturf(loc))
		qdel(src)

/obj/item/ammo_box/magazine/recharge/ctf
	ammo_type = /obj/item/ammo_casing/caseless/laser/ctf

/obj/item/ammo_box/magazine/recharge/ctf/dropped()
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(floor_vanish)), 1)

/obj/item/ammo_box/magazine/recharge/ctf/proc/floor_vanish()
	if(isturf(loc))
		qdel(src)

/obj/item/ammo_casing/caseless/laser/ctf
	projectile_type = /obj/projectile/beam/ctf

/obj/projectile/beam/ctf
	damage = 0
	icon_state = "omnilaser"

/obj/projectile/beam/ctf/prehit_pierce(atom/target)
	if(is_ctf_target(target))
		damage = 150
		return PROJECTILE_PIERCE_NONE		/// hey uhhh don't hit anyone behind them
	. = ..()

/proc/is_ctf_target(atom/target)
	. = FALSE
	if(istype(target, /obj/structure/barricade/security/ctf))
		. = TRUE
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		for(var/obj/machinery/capture_the_flag/CTF in GLOB.machines)
			if(H in CTF.spawned_mobs)
				. = TRUE
				break

// RED TEAM GUNS

/obj/item/gun/ballistic/automatic/laser/ctf/red
	mag_type = /obj/item/ammo_box/magazine/recharge/ctf/red

/obj/item/ammo_box/magazine/recharge/ctf/red
	ammo_type = /obj/item/ammo_casing/caseless/laser/ctf/red

/obj/item/ammo_casing/caseless/laser/ctf/red
	projectile_type = /obj/projectile/beam/ctf/red

/obj/projectile/beam/ctf/red
	icon_state = "laser"
	impact_effect_type = /obj/effect/temp_visual/impact_effect/red_laser

// BLUE TEAM GUNS

/obj/item/gun/ballistic/automatic/laser/ctf/blue
	mag_type = /obj/item/ammo_box/magazine/recharge/ctf/blue

/obj/item/ammo_box/magazine/recharge/ctf/blue
	ammo_type = /obj/item/ammo_casing/caseless/laser/ctf/blue

/obj/item/ammo_casing/caseless/laser/ctf/blue
	projectile_type = /obj/projectile/beam/ctf/blue

/obj/projectile/beam/ctf/blue
	icon_state = "bluelaser"
	impact_effect_type = /obj/effect/temp_visual/impact_effect/blue_laser

// GREEN TEAM GUNS

/obj/item/gun/ballistic/automatic/laser/ctf/green
	mag_type = /obj/item/ammo_box/magazine/recharge/ctf/green

/obj/item/ammo_box/magazine/recharge/ctf/green
	ammo_type = /obj/item/ammo_casing/caseless/laser/ctf/green

/obj/item/ammo_casing/caseless/laser/ctf/green
	projectile_type = /obj/projectile/beam/ctf/green

/obj/projectile/beam/ctf/green
	icon_state = "xray"
	impact_effect_type = /obj/effect/temp_visual/impact_effect/green_laser

// YELLOW TEAM GUNS

/obj/item/gun/ballistic/automatic/laser/ctf/yellow
	mag_type = /obj/item/ammo_box/magazine/recharge/ctf/yellow

/obj/item/ammo_box/magazine/recharge/ctf/yellow
	ammo_type = /obj/item/ammo_casing/caseless/laser/ctf/yellow

/obj/item/ammo_casing/caseless/laser/ctf/yellow
	projectile_type = /obj/projectile/beam/ctf/yellow

/obj/projectile/beam/ctf/yellow
	icon_state = "gaussstrong"
	impact_effect_type = /obj/effect/temp_visual/impact_effect/yellow_laser

/datum/outfit/ctf
	name = "CTF"
	ears = /obj/item/radio/headset
	uniform = /obj/item/clothing/under/syndicate
	suit = /obj/item/clothing/suit/space/hardsuit/shielded/ctf
	toggle_helmet = FALSE // see the whites of their eyes
	shoes = /obj/item/clothing/shoes/combat
	gloves = /obj/item/clothing/gloves/combat
	id = /obj/item/card/id/away
	belt = /obj/item/gun/ballistic/automatic/pistol/deagle/ctf
	l_pocket = /obj/item/ammo_box/magazine/recharge/ctf
	r_pocket = /obj/item/ammo_box/magazine/recharge/ctf
	r_hand = /obj/item/gun/ballistic/automatic/laser/ctf

/datum/outfit/ctf/post_equip(mob/living/carbon/human/H, visualsOnly=FALSE)
	if(visualsOnly)
		return
	var/list/no_drops = list()
	var/obj/item/card/id/W = H.wear_id
	no_drops += W
	W.registered_name = H.real_name
	W.update_label()
	W.update_icon()

	no_drops += H.get_item_by_slot(ITEM_SLOT_OCLOTHING)
	no_drops += H.get_item_by_slot(ITEM_SLOT_GLOVES)
	no_drops += H.get_item_by_slot(ITEM_SLOT_FEET)
	no_drops += H.get_item_by_slot(ITEM_SLOT_ICLOTHING)
	no_drops += H.get_item_by_slot(ITEM_SLOT_EARS)
	for(var/i in no_drops)
		var/obj/item/I = i
		ADD_TRAIT(I, TRAIT_NODROP, CAPTURE_THE_FLAG_TRAIT)
	spawn(1 SECONDS)
		H.mind?.adjust_experience(/datum/skill/ranged, SKILL_EXP_EXPERT)

/datum/outfit/ctf/instagib
	r_hand = /obj/item/gun/energy/laser/instakill
	shoes = /obj/item/clothing/shoes/jackboots/fast

/datum/outfit/ctf/red
	suit = /obj/item/clothing/suit/space/hardsuit/shielded/ctf/red
	r_hand = /obj/item/gun/ballistic/automatic/laser/ctf/red
	l_pocket = /obj/item/ammo_box/magazine/recharge/ctf/red
	r_pocket = /obj/item/ammo_box/magazine/recharge/ctf/red
	id = /obj/item/card/id/red //it's red

/datum/outfit/ctf/red/instagib
	r_hand = /obj/item/gun/energy/laser/instakill/red
	shoes = /obj/item/clothing/shoes/jackboots/fast

/datum/outfit/ctf/blue
	suit = /obj/item/clothing/suit/space/hardsuit/shielded/ctf/blue
	r_hand = /obj/item/gun/ballistic/automatic/laser/ctf/blue
	l_pocket = /obj/item/ammo_box/magazine/recharge/ctf/blue
	r_pocket = /obj/item/ammo_box/magazine/recharge/ctf/blue
	id = /obj/item/card/id/blue //it's blue

/datum/outfit/ctf/blue/warfare
	head = /obj/item/clothing/head/helmet/elite/blue
	mask = /obj/item/clothing/mask/gas/german
	uniform = /obj/item/clothing/under/victorian/vest
	shoes = /obj/item/clothing/shoes/jackboots
	gloves = /obj/item/clothing/gloves/fingerless
	belt = /obj/item/melee/sabre/marineofficer
	suit = /obj/item/clothing/suit/armor/opvest
	r_hand = /obj/item/gun/ballistic/rifle/boltaction/kar98k
	l_pocket = /obj/item/ammo_box/magazine/a792x57
	r_pocket = /obj/item/ammo_box/magazine/a792x57

/datum/outfit/ctf/blue/warfare/post_equip(mob/living/carbon/human/H)
	. = ..()
	H.add_client_colour(/datum/client_colour/warfare)
	H.overlay_fullscreen("noisewwi", /atom/movable/screen/fullscreen/noisescreen/warfare)

/datum/outfit/ctf/blue/instagib
	r_hand = /obj/item/gun/energy/laser/instakill/blue
	shoes = /obj/item/clothing/shoes/jackboots/fast

/datum/outfit/ctf/green
	suit = /obj/item/clothing/suit/space/hardsuit/shielded/ctf/green
	r_hand = /obj/item/gun/ballistic/automatic/laser/ctf/green
	l_pocket = /obj/item/ammo_box/magazine/recharge/ctf/green
	r_pocket = /obj/item/ammo_box/magazine/recharge/ctf/green
	id = /obj/item/card/id/green //it's green

/datum/outfit/ctf/green/instagib
	r_hand = /obj/item/gun/energy/laser/instakill/green
	shoes = /obj/item/clothing/shoes/jackboots/fast

/datum/outfit/ctf/yellow
	suit = /obj/item/clothing/suit/space/hardsuit/shielded/ctf/yellow
	r_hand = /obj/item/gun/ballistic/automatic/laser/ctf/yellow
	l_pocket = /obj/item/ammo_box/magazine/recharge/ctf/yellow
	r_pocket = /obj/item/ammo_box/magazine/recharge/ctf/yellow
	id = /obj/item/card/id/yellow //it's yellow

/datum/outfit/ctf/yellow/warfare
	head = /obj/item/clothing/head/helmet/elite/yellow
	mask = /obj/item/clothing/mask/gas/german
	uniform = /obj/item/clothing/under/victorian/vest
	shoes = /obj/item/clothing/shoes/jackboots
	gloves = /obj/item/clothing/gloves/fingerless
	belt = /obj/item/melee/sabre/marineofficer
	suit = /obj/item/clothing/suit/armor/opvest
	r_hand = /obj/item/gun/ballistic/rifle/boltaction/kar98k
	l_pocket = /obj/item/ammo_box/magazine/a792x57
	r_pocket = /obj/item/ammo_box/magazine/a792x57

/datum/outfit/ctf/yellow/warfare/post_equip(mob/living/carbon/human/H)
	. = ..()
	H.add_client_colour(/datum/client_colour/warfare)
	H.overlay_fullscreen("noisewwi", /atom/movable/screen/fullscreen/noisescreen/warfare)

/datum/outfit/ctf/yellow/instagib
	r_hand = /obj/item/gun/energy/laser/instakill/yellow
	shoes = /obj/item/clothing/shoes/jackboots/fast

/datum/outfit/ctf/red/post_equip(mob/living/carbon/human/H)
	..()
	var/obj/item/radio/R = H.ears
	R.set_frequency(FREQ_CTF_RED)
	R.freqlock = TRUE
	R.independent = TRUE
	H.dna.species.stunmod = 0

/datum/outfit/ctf/blue/post_equip(mob/living/carbon/human/H)
	..()
	var/obj/item/radio/R = H.ears
	R.set_frequency(FREQ_CTF_BLUE)
	R.freqlock = TRUE
	R.independent = TRUE
	H.dna.species.stunmod = 0

/datum/outfit/ctf/green/post_equip(mob/living/carbon/human/H)
	..()
	var/obj/item/radio/R = H.ears
	R.set_frequency(FREQ_CTF_GREEN)
	R.freqlock = TRUE
	R.independent = TRUE
	H.dna.species.stunmod = 0

/datum/outfit/ctf/yellow/post_equip(mob/living/carbon/human/H)
	..()
	var/obj/item/radio/R = H.ears
	R.set_frequency(FREQ_CTF_YELLOW)
	R.freqlock = TRUE
	R.independent = TRUE
	H.dna.species.stunmod = 0


/obj/structure/trap/ctf
	name = "Защита базы"
	desc = "Держись подальше от базы противника!"
	icon_state = "trap"
	resistance_flags = INDESTRUCTIBLE
	var/team = WHITE_TEAM
	time_between_triggers = 1
	anchored = TRUE
	alpha = 255

/obj/structure/trap/ctf/examine(mob/user)
	return

/obj/structure/trap/ctf/trap_effect(mob/living/L)
	if(!is_ctf_target(L))
		return
	if(!(src.team in L.faction))
		to_chat(L, span_danger("<B>Держись подальше от базы противника!</B>"))
		L.death()

/obj/structure/trap/ctf/red
	team = RED_TEAM
	icon_state = "trap-fire"

/obj/structure/trap/ctf/blue
	team = BLUE_TEAM
	icon_state = "trap-frost"

/obj/structure/trap/ctf/green
	team = GREEN_TEAM
	icon_state = "trap-earth"

/obj/structure/trap/ctf/yellow
	team = YELLOW_TEAM
	icon_state = "trap-shock"

/obj/structure/barricade/security/ctf
	name = "Барьер"
	desc = "Барьер. За ним можно укрыться."
	deploy_time = 0
	deploy_message = 0

/obj/structure/barricade/security/ctf/make_debris()
	new /obj/effect/ctf/dead_barricade(get_turf(src))

/obj/structure/table/reinforced/ctf
	resistance_flags = INDESTRUCTIBLE
	flags_1 = NODECONSTRUCT_1

/obj/effect/ctf
	density = FALSE
	anchored = TRUE
	invisibility = INVISIBILITY_OBSERVER
	alpha = 100
	resistance_flags = INDESTRUCTIBLE

/obj/effect/ctf/ammo
	name = "Пополнение боезапаса"
	desc = "Хочешь отомстить? Иди \
		и отомсти!"
	//icon = 'icons/effects/effects.dmi' потом какнить впилю
	icon_state = "at_shield1"
	layer = ABOVE_MOB_LAYER
	alpha = 255
	invisibility = 0

/obj/effect/ctf/ammo/Initialize(mapload)
	..()
	QDEL_IN(src, AMMO_DROP_LIFETIME)
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
	)
	AddElement(/datum/element/connect_loc, loc_connections)

/obj/effect/ctf/ammo/proc/on_entered(datum/source, atom/movable/movable_atom)
	SIGNAL_HANDLER
	reload(movable_atom)

/obj/effect/ctf/ammo/Bump(atom/A)
	reload(A)

/obj/effect/ctf/ammo/Bumped(atom/movable/AM)
	reload(AM)

/obj/effect/ctf/ammo/proc/reload(mob/living/M)
	if(!ishuman(M))
		return
	for(var/obj/machinery/capture_the_flag/CTF in GLOB.machines)
		if(M in CTF.spawned_mobs)
			var/outfit = CTF.spawned_mobs[M]
			var/datum/outfit/O = new outfit
			for(var/obj/item/gun/G in M)
				qdel(G)
			O.equip(M)
			to_chat(M, span_notice("Оружие снова заряжено!"))
			playsound(get_turf(M), 'sound/weapons/gun/shotgun/rack.ogg', 50, TRUE, -1)
			qdel(src)
			break

/obj/effect/ctf/dead_barricade
	name = "Уничтоженный барьер"
	desc = "За ним можно было укрыться. Теперь он разрушен."
	icon = 'icons/obj/objects.dmi'
	icon_state = "barrier0"
	var/game_id = "centcom"

/obj/effect/ctf/dead_barricade/Initialize(mapload)
	. = ..()
	for(var/obj/machinery/capture_the_flag/CTF in GLOB.machines)
		if(CTF.game_id != game_id)
			continue
		CTF.dead_barricades += src

/obj/effect/ctf/dead_barricade/Destroy()
	for(var/obj/machinery/capture_the_flag/CTF in GLOB.machines)
		if(CTF.game_id != game_id)
			continue
		CTF.dead_barricades -= src
	return ..()

/obj/effect/ctf/dead_barricade/proc/respawn()
	if(!QDELETED(src))
		new /obj/structure/barricade/security/ctf(get_turf(src))
		qdel(src)

//Control Point

/obj/machinery/control_point
	name = "Точка контроля"
	desc = "Вот это надо захватить."
	icon = 'icons/obj/machines/dominator.dmi'
	icon_state = "dominator"
	resistance_flags = INDESTRUCTIBLE
	var/obj/machinery/capture_the_flag/controlling
	var/team = "none"
	var/point_rate = 0.5
	var/game_area = /area/ctf

/obj/machinery/control_point/process(delta_time)
	if(controlling)
		controlling.control_points += point_rate * delta_time
		if(controlling.control_points >= controlling.control_points_to_win)
			controlling.victory()

/obj/machinery/control_point/attackby(mob/user, params)
	capture(user)

/obj/machinery/control_point/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	capture(user)

/obj/machinery/control_point/proc/capture(mob/user)
	if(do_after(user, 30, target = src))
		for(var/obj/machinery/capture_the_flag/CTF in GLOB.machines)
			if(CTF.ctf_enabled && (user.ckey in CTF.team_members))
				controlling = CTF
				icon_state = "dominator-[CTF.team]"
				for(var/mob/M in GLOB.player_list)
					var/area/mob_area = get_area(M)
					if(istype(mob_area, game_area))
						to_chat(M, span_userdanger("[user.real_name] захватил [src] для [CTF.team]! Иди и забери обратно!"))
				break

#undef WHITE_TEAM
#undef RED_TEAM
#undef BLUE_TEAM
#undef GREEN_TEAM
#undef YELLOW_TEAM
#undef FLAG_RETURN_TIME
#undef INSTAGIB_RESPAWN
#undef DEFAULT_RESPAWN
#undef AMMO_DROP_LIFETIME
