GLOBAL_VAR_INIT(hhStorageTurf, null)
GLOBAL_VAR_INIT(hhMysteryRoomNumber, rand(1, 999999))

/obj/item/hilbertshotel
	name = "Hilbert's Hotel"
	desc = "A sphere of what appears to be an intricate network of bluespace. Observing it in detail seems to give you a headache as you try to comprehend the infinite amount of infinitesimally distinct points on its surface."
	icon_state = "hilbertshotel"
	w_class = WEIGHT_CLASS_SMALL
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	var/datum/map_template/hilbertshotel/hotelRoomTemp
	var/datum/map_template/hilbertshotel/empty/hotelRoomTempEmpty
	var/datum/map_template/hilbertshotel/lore/hotelRoomTempLore
	var/list/activeRooms = list()
	var/list/storedRooms = list()
	var/storageTurf
	//Lore Stuff
	var/ruinSpawned = FALSE

/obj/item/hilbertshotel/Initialize()
	. = ..()
	//Load templates
	INVOKE_ASYNC(src, PROC_REF(prepare_rooms))

/obj/item/hilbertshotel/proc/prepare_rooms()
	hotelRoomTemp = new()
	hotelRoomTempEmpty = new()
	hotelRoomTempLore = new()
	var/area/currentArea = get_area(src)
	if(currentArea.type == /area/ruin/space/has_grav/hilbertresearchfacility)
		ruinSpawned = TRUE

/obj/item/hilbertshotel/Destroy()
	ejectRooms()
	return ..()

/obj/item/hilbertshotel/attack(mob/living/M, mob/living/user)
	if(M.mind)
		to_chat(user, span_notice("You invite [M] to the hotel."))
		promptAndCheckIn(user, M)
	else
		to_chat(user, span_warning("[M] is not intelligent enough to understand how to use this device!"))

/obj/item/hilbertshotel/attack_self(mob/user)
	. = ..()
	promptAndCheckIn(user, user)

/obj/item/hilbertshotel/attack_tk(mob/user)
	to_chat(user, span_notice("<b>[src.name]</b> actively rejects your mind as the bluespace energies surrounding it disrupt your telekinesis."))
	return COMPONENT_CANCEL_ATTACK_CHAIN

/obj/item/hilbertshotel/proc/promptAndCheckIn(mob/user, mob/target)
	var/chosenRoomNumber

	// Input text changes depending on if you're using this in yourself or someone else.
	if(user == target)
		chosenRoomNumber = input(target, "What number room will you be checking into?", "Room Number") as null|num
	else
		chosenRoomNumber = input(target, "[user] is inviting you to enter <b>[src.name]</b>. What number room will you be checking into?", "Room Number") as null|num

	if(!chosenRoomNumber)
		return
	if(chosenRoomNumber > SHORT_REAL_LIMIT)
		to_chat(target, span_warning("You have to check out the first [SHORT_REAL_LIMIT] rooms before you can go to a higher numbered one!"))
		return
	if((chosenRoomNumber < 1) || (chosenRoomNumber != round(chosenRoomNumber)))
		to_chat(target, span_warning("That is not a valid room number!"))
		return

	// Orb is not adjacent to the target. No teleporties.
	if(!src.Adjacent(target))
		to_chat(target, span_warning("You too far away from <b>[src.name]</b> to enter it!"))

	// If the target is incapacitated after selecting a room, they're not allowed to teleport.
	if(target.incapacitated())
		to_chat(target, span_warning("You aren't able to activate <b>[src.name]</b> anymore!"))

	// Has the user thrown it away or otherwise disposed of it such that it's no longer in their hands or in some storage connected to them?
	if(!(get_atom_on_turf(src, /mob) == user))
		if(user == target)
			to_chat(user, span_warning("<b>[src.name]</b> is no longer in your possession!"))
		else
			to_chat(target, span_warning("<b>[src.name]</b> is no longer in the possession of [user]!"))
		return

	// If the player is using it on themselves, we've got some logic to deal with.
	// The user should drop the item before teleporting, but we're not going to force the item to be dropped if it can't be done normally...
	if(user == target)
		// The item should be on the user or in the user's inventory somewhere.
		// However, if they're not holding it, it may be in a pocket? In a backpack? Who knows! Still, they can't just drop it to the floor anymore...
		if(!user.get_held_index_of_item(src))
			to_chat(user, span_warning("Пытаюсь drop <b>[src.name]</b>, but it's too late! It's no longer in your hands! Prepare for unforeseen consequences..."))
		// Okay, so they HAVE to be holding it here, because it's in their hand from the above check. Try to drop the item and if it fails, oh dear...
		else if(!user.dropItemToGround(src))
			to_chat(user, span_warning("You can't seem to drop <b>[src.name]</b>! It must be stuck to your hand somehow! Prepare for unforeseen consequences..."))

	if(!storageTurf) //Blame subsystems for not allowing this to be in Initialize
		if(!GLOB.hhStorageTurf)
			var/datum/map_template/hilbertshotelstorage/storageTemp = new()
			var/datum/turf_reservation/storageReservation = SSmapping.RequestBlockReservation(3, 3)
			storageTemp.load(locate(storageReservation.bottom_left_coords[1], storageReservation.bottom_left_coords[2], storageReservation.bottom_left_coords[3]))
			GLOB.hhStorageTurf = locate(storageReservation.bottom_left_coords[1]+1, storageReservation.bottom_left_coords[2]+1, storageReservation.bottom_left_coords[3])
		else
			storageTurf = GLOB.hhStorageTurf
	if(tryActiveRoom(chosenRoomNumber, target))
		return
	if(tryStoredRoom(chosenRoomNumber, target))
		return
	sendToNewRoom(chosenRoomNumber, target)

/obj/item/hilbertshotel/proc/tryActiveRoom(roomNumber, mob/user)
	if(activeRooms["[roomNumber]"])
		var/datum/turf_reservation/roomReservation = activeRooms["[roomNumber]"]
		do_sparks(3, FALSE, get_turf(user))
		user.forceMove(locate(roomReservation.bottom_left_coords[1] + hotelRoomTemp.landingZoneRelativeX, roomReservation.bottom_left_coords[2] + hotelRoomTemp.landingZoneRelativeY, roomReservation.bottom_left_coords[3]))
		return TRUE
	return FALSE

/obj/item/hilbertshotel/proc/tryStoredRoom(roomNumber, mob/user)
	if(storedRooms["[roomNumber]"])
		var/datum/turf_reservation/roomReservation = SSmapping.RequestBlockReservation(hotelRoomTemp.width, hotelRoomTemp.height)
		hotelRoomTempEmpty.load(locate(roomReservation.bottom_left_coords[1], roomReservation.bottom_left_coords[2], roomReservation.bottom_left_coords[3]))
		var/turfNumber = 1
		for(var/i=0, i<hotelRoomTemp.width, i++)
			for(var/j=0, j<hotelRoomTemp.height, j++)
				for(var/atom/movable/A in storedRooms["[roomNumber]"][turfNumber])
					if(istype(A.loc, /obj/item/abstracthotelstorage))//Don't want to recall something thats been moved
						A.forceMove(locate(roomReservation.bottom_left_coords[1] + i, roomReservation.bottom_left_coords[2] + j, roomReservation.bottom_left_coords[3]))
				turfNumber++
		for(var/obj/item/abstracthotelstorage/S in storageTurf)
			if((S.roomNumber == roomNumber) && (S.parentSphere == src))
				qdel(S)
		storedRooms -= "[roomNumber]"
		activeRooms["[roomNumber]"] = roomReservation
		linkTurfs(roomReservation, roomNumber)
		do_sparks(3, FALSE, get_turf(user))
		user.forceMove(locate(roomReservation.bottom_left_coords[1] + hotelRoomTemp.landingZoneRelativeX, roomReservation.bottom_left_coords[2] + hotelRoomTemp.landingZoneRelativeY, roomReservation.bottom_left_coords[3]))
		return TRUE
	return FALSE

/obj/item/hilbertshotel/proc/sendToNewRoom(roomNumber, mob/user)
	var/datum/turf_reservation/roomReservation = SSmapping.RequestBlockReservation(hotelRoomTemp.width, hotelRoomTemp.height)
	if(ruinSpawned && roomNumber == GLOB.hhMysteryRoomNumber)
		hotelRoomTempLore.load(locate(roomReservation.bottom_left_coords[1], roomReservation.bottom_left_coords[2], roomReservation.bottom_left_coords[3]))
	else
		hotelRoomTemp.load(locate(roomReservation.bottom_left_coords[1], roomReservation.bottom_left_coords[2], roomReservation.bottom_left_coords[3]))
	activeRooms["[roomNumber]"] = roomReservation
	linkTurfs(roomReservation, roomNumber)
	do_sparks(3, FALSE, get_turf(user))
	user.forceMove(locate(roomReservation.bottom_left_coords[1] + hotelRoomTemp.landingZoneRelativeX, roomReservation.bottom_left_coords[2] + hotelRoomTemp.landingZoneRelativeY, roomReservation.bottom_left_coords[3]))

/obj/item/hilbertshotel/proc/linkTurfs(datum/turf_reservation/currentReservation, currentRoomnumber)
	var/area/hilbertshotel/currentArea = get_area(locate(currentReservation.bottom_left_coords[1], currentReservation.bottom_left_coords[2], currentReservation.bottom_left_coords[3]))
	currentArea.name = "Hilbert's Hotel Room [currentRoomnumber]"
	currentArea.parentSphere = src
	currentArea.storageTurf = storageTurf
	currentArea.roomnumber = currentRoomnumber
	currentArea.reservation = currentReservation
	for(var/turf/closed/indestructible/hoteldoor/door in currentArea)
		door.parentSphere = src
		door.desc = "The door to this hotel room. The placard reads 'Room [currentRoomnumber]'. Strangely, this door doesn't even seem openable. The doorknob, however, seems to buzz with unusual energy...<br /><span class='info'>ПКМ to look through the peephole.</span>"
	for(var/turf/open/space/bluespace/BSturf in currentArea)
		BSturf.parentSphere = src

/obj/item/hilbertshotel/proc/ejectRooms()
	if(activeRooms.len)
		for(var/x in activeRooms)
			var/datum/turf_reservation/room = activeRooms[x]
			for(var/i=0, i<hotelRoomTemp.width, i++)
				for(var/j=0, j<hotelRoomTemp.height, j++)
					for(var/atom/movable/A in locate(room.bottom_left_coords[1] + i, room.bottom_left_coords[2] + j, room.bottom_left_coords[3]))
						if(ismob(A))
							var/mob/M = A
							if(M.mind)
								to_chat(M, span_warning("As the sphere breaks apart, you're suddenly ejected into the depths of space!"))
						var/max = world.maxx-TRANSITIONEDGE
						var/min = 1+TRANSITIONEDGE
						var/list/possible_transtitons = list()
						for(var/AZ in SSmapping.z_list)
							var/datum/space_level/D = AZ
							if (D.linkage == CROSSLINKED)
								possible_transtitons += D.z_value
						var/_z = pick(possible_transtitons)
						var/_x = rand(min,max)
						var/_y = rand(min,max)
						var/turf/T = locate(_x, _y, _z)
						A.forceMove(T)
			qdel(room)

	if(storedRooms.len)
		for(var/x in storedRooms)
			var/list/atomList = storedRooms[x]
			for(var/atom/movable/A in atomList)
				var/max = world.maxx-TRANSITIONEDGE
				var/min = 1+TRANSITIONEDGE
				var/list/possible_transtitons = list()
				for(var/AZ in SSmapping.z_list)
					var/datum/space_level/D = AZ
					if (D.linkage == CROSSLINKED)
						possible_transtitons += D.z_value
				var/_z = pick(possible_transtitons)
				var/_x = rand(min,max)
				var/_y = rand(min,max)
				var/turf/T = locate(_x, _y, _z)
				A.forceMove(T)

//Template Stuff
/datum/map_template/hilbertshotel
	name = "Hilbert's Hotel Room"
	mappath = "_maps/templates/hilbertshotel.dmm"
	var/landingZoneRelativeX = 2
	var/landingZoneRelativeY = 8

/datum/map_template/hilbertshotel/empty
	name = "Empty Hilbert's Hotel Room"
	mappath = "_maps/templates/hilbertshotelempty.dmm"

/datum/map_template/hilbertshotel/lore
	name = "Doctor Hilbert's Deathbed"
	mappath = "_maps/templates/hilbertshotellore.dmm"

/datum/map_template/hilbertshotelstorage
	name = "Hilbert's Hotel Storage"
	mappath = "_maps/templates/hilbertshotelstorage.dmm"


//Turfs and Areas
/turf/closed/indestructible/hotelwall
	name = "hotel wall"
	desc = "A wall designed to protect the security of the hotel's guests."
	icon_state = "hotelwall"
	smoothing_groups = list(SMOOTH_GROUP_CLOSED_TURFS, SMOOTH_GROUP_HOTEL_WALLS)
	canSmoothWith = list(SMOOTH_GROUP_HOTEL_WALLS)
	explosion_block = INFINITY

/turf/open/indestructible/hotelwood
	desc = "Stylish dark wood with extra reinforcement. Secured firmly to the floor to prevent tampering."
	icon_state = "wood"
	footstep = FOOTSTEP_WOOD
	tiled_dirt = FALSE

/turf/open/indestructible/hoteltile
	desc = "Smooth tile with extra reinforcement. Secured firmly to the floor to prevent tampering."
	icon_state = "showroomfloor"
	footstep = FOOTSTEP_FLOOR
	tiled_dirt = FALSE

/turf/open/space/bluespace
	name = "\proper bluespace hyperzone"
	icon_state = "bluespace"
	baseturfs = /turf/open/space/bluespace
	turf_flags = NOJAUNT
	explosion_block = INFINITY
	var/obj/item/hilbertshotel/parentSphere

/turf/open/space/bluespace/Initialize()
	. = ..()
	update_icon_state()

/turf/open/space/bluespace/update_icon_state()
	icon_state = "bluespace"

/turf/open/space/bluespace/Entered(atom/movable/A)
	. = ..()
	if(parentSphere && A.forceMove(get_turf(parentSphere)))
		do_sparks(3, FALSE, get_turf(A))

/turf/closed/indestructible/hoteldoor
	name = "Hotel Door"
	icon_state = "hoteldoor"
	explosion_block = INFINITY
	var/obj/item/hilbertshotel/parentSphere

/turf/closed/indestructible/hoteldoor/proc/promptExit(mob/living/user)
	if(!isliving(user))
		return
	if(!user.mind)
		return
	if(!parentSphere)
		to_chat(user, span_warning("The door seems to be malfunctioning and refuses to operate!"))
		return
	if(tgui_alert(user, "Hilbert's Hotel would like to remind you that while we will do everything we can to protect the belongings you leave behind, we make no guarantees of their safety while you're gone, especially that of the health of any living creatures. With that in mind, are you ready to leave?", "Exit", list("Leave", "Stay")) == "Leave")
		if(HAS_TRAIT(user, TRAIT_IMMOBILIZED) || (get_dist(get_turf(src), get_turf(user)) > 1)) //no teleporting around if they're dead or moved away during the prompt.
			return
		user.forceMove(get_turf(parentSphere))
		do_sparks(3, FALSE, get_turf(user))

/turf/closed/indestructible/hoteldoor/attack_ghost(mob/dead/observer/user)
	if(!isobserver(user) || !parentSphere)
		return ..()
	user.forceMove(get_turf(parentSphere))

//If only this could be simplified...
/turf/closed/indestructible/hoteldoor/attack_tk(mob/user)
	return //need to be close.

/turf/closed/indestructible/hoteldoor/attack_hand(mob/user)
	promptExit(user)

/turf/closed/indestructible/hoteldoor/attack_animal(mob/user)
	promptExit(user)

/turf/closed/indestructible/hoteldoor/attack_paw(mob/user)
	promptExit(user)

/turf/closed/indestructible/hoteldoor/attack_hulk(mob/living/carbon/human/user)
	promptExit(user)

/turf/closed/indestructible/hoteldoor/attack_larva(mob/user)
	promptExit(user)

/turf/closed/indestructible/hoteldoor/attack_slime(mob/user)
	promptExit(user)

/turf/closed/indestructible/hoteldoor/attack_robot(mob/user)
	if(get_dist(get_turf(src), get_turf(user)) <= 1)
		promptExit(user)

/turf/closed/indestructible/hoteldoor/AltClick(mob/user)
	. = ..()
	if(get_dist(get_turf(src), get_turf(user)) <= 1)
		to_chat(user, span_notice("You peak through the door's bluespace peephole..."))
		user.reset_perspective(parentSphere)
		var/datum/action/peephole_cancel/PHC = new
		user.overlay_fullscreen("remote_view", /atom/movable/screen/fullscreen/impaired, 1)
		PHC.Grant(user)
		RegisterSignal(user, COMSIG_MOVABLE_MOVED, TYPE_PROC_REF(/atom, check_eye), user)

/turf/closed/indestructible/hoteldoor/check_eye(mob/user)
	if(get_dist(get_turf(src), get_turf(user)) >= 2)
		for(var/datum/action/peephole_cancel/PHC in user.actions)
			INVOKE_ASYNC(PHC, TYPE_PROC_REF(/datum/action/peephole_cancel, Trigger))

/datum/action/peephole_cancel
	name = "Cancel View"
	desc = "Stop looking through the bluespace peephole."
	button_icon_state = "cancel_peephole"

/datum/action/peephole_cancel/Trigger()
	. = ..()
	to_chat(owner, span_warning("You move away from the peephole."))
	owner.reset_perspective()
	owner.clear_fullscreen("remote_view", 0)
	UnregisterSignal(owner, COMSIG_MOVABLE_MOVED)
	qdel(src)

/area/hilbertshotel
	name = "Hilbert's Hotel Room"
	icon_state = "hilbertshotel"
	requires_power = FALSE
	has_gravity = TRUE
	area_flags = NOTELEPORT | HIDDEN_AREA
	static_lighting = TRUE
	ambientsounds = list('sound/ambience/servicebell.ogg')
	var/roomnumber = 0
	var/obj/item/hilbertshotel/parentSphere
	var/datum/turf_reservation/reservation
	var/turf/storageTurf

/area/hilbertshotel/Entered(atom/movable/AM)
	. = ..()
	if(istype(AM, /obj/item/hilbertshotel))
		relocate(AM)
	var/list/obj/item/hilbertshotel/hotels = AM.get_all_contents_type(/obj/item/hilbertshotel)
	for(var/obj/item/hilbertshotel/H in hotels)
		if(parentSphere == H)
			relocate(H)

/area/hilbertshotel/proc/relocate(obj/item/hilbertshotel/H)
	if(prob(0.135685)) //Because screw you
		qdel(H)
		return

	// Prepare for...
	var/mob/living/unforeseen_consequences = get_atom_on_turf(H, /mob/living)

	// Turns out giving anyone who grabs a Hilbert's Hotel a free, complementary warp whistle is probably bad.
	// Let's gib the last person to have selected a room number in it.
	if(unforeseen_consequences)
		to_chat(unforeseen_consequences, span_warning("\The [H] starts to resonate. Forcing it to enter itself induces a bluespace paradox, violently tearing your body apart."))
		unforeseen_consequences.gib()

	var/turf/targetturf = find_safe_turf()
	if(!targetturf)
		if(GLOB.blobstart.len > 0)
			targetturf = get_turf(pick(GLOB.blobstart))
		else
			CRASH("Unable to find a blobstart landmark")
	var/turf/T = get_turf(H)
	var/area/A = T.loc
	log_game("[H] entered itself. Moving it to [loc_name(targetturf)].")
	message_admins("[H] entered itself. Moving it to [ADMIN_VERBOSEJMP(targetturf)].")
	for(var/mob/M in A)
		to_chat(M, span_danger("[H] almost implodes in upon itself, but quickly rebounds, shooting off into a random point in space!"))
	H.forceMove(targetturf)

/area/hilbertshotel/Exited(atom/movable/AM)
	. = ..()
	if(ismob(AM))
		var/mob/M = AM
		if(M.mind)
			var/stillPopulated = FALSE
			var/list/currentLivingMobs = get_all_contents_type(/mob/living) //Got to catch anyone hiding in anything
			for(var/mob/living/L in currentLivingMobs) //Check to see if theres any sentient mobs left.
				if(L.mind)
					stillPopulated = TRUE
					break
			if(!stillPopulated)
				storeRoom()

/area/hilbertshotel/proc/storeRoom()
	var/roomSize = (reservation.top_right_coords[1]-reservation.bottom_left_coords[1]+1)*(reservation.top_right_coords[2]-reservation.bottom_left_coords[2]+1)
	var/storage[roomSize]
	var/turfNumber = 1
	var/obj/item/abstracthotelstorage/storageObj = new(storageTurf)
	storageObj.roomNumber = roomnumber
	storageObj.parentSphere = parentSphere
	storageObj.name = "Room [roomnumber] Storage"
	for(var/i=0, i<parentSphere.hotelRoomTemp.width, i++)
		for(var/j=0, j<parentSphere.hotelRoomTemp.height, j++)
			var/list/turfContents = list()
			for(var/atom/movable/A in locate(reservation.bottom_left_coords[1] + i, reservation.bottom_left_coords[2] + j, reservation.bottom_left_coords[3]))
				if(ismob(A) && !isliving(A))
					continue //Don't want to store ghosts
				turfContents += A
				A.forceMove(storageObj)
			storage[turfNumber] = turfContents
			turfNumber++
	parentSphere.storedRooms["[roomnumber]"] = storage
	parentSphere.activeRooms -= "[roomnumber]"
	qdel(reservation)

/area/hilbertshotelstorage
	name = "Hilbert's Hotel Storage Room"
	icon_state = "hilbertshotel"
	requires_power = FALSE
	area_flags = HIDDEN_AREA | NOTELEPORT | UNIQUE_AREA
	has_gravity = TRUE

/obj/item/abstracthotelstorage
	anchored = TRUE
	invisibility = INVISIBILITY_ABSTRACT
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	item_flags = ABSTRACT
	var/roomNumber
	var/obj/item/hilbertshotel/parentSphere

/obj/item/abstracthotelstorage/Entered(atom/movable/AM, atom/oldLoc)
	. = ..()
	if(ismob(AM))
		var/mob/M = AM
		M.notransform = TRUE

/obj/item/abstracthotelstorage/Exited(atom/movable/AM, atom/newLoc)
	. = ..()
	if(ismob(AM))
		var/mob/M = AM
		M.notransform = FALSE

//Space Ruin stuff
/area/ruin/space/has_grav/hilbertresearchfacility
	name = "Hilbert Research Facility"

/obj/item/analyzer/hilbertsanalyzer
	name = "custom rigged analyzer"
	desc = "A hand-held environmental scanner which reports current gas levels. This one seems custom rigged to additionally be able to analyze some sort of bluespace device."
	icon_state = "hilbertsanalyzer"
	worn_icon_state = "analyzer"

/obj/item/analyzer/hilbertsanalyzer/afterattack(atom/target, mob/user, proximity)
	. = ..()
	if(istype(target, /obj/item/hilbertshotel))
		if(!proximity)
			to_chat(user, span_warning("It's to far away to scan!"))
			return
		var/obj/item/hilbertshotel/sphere = target
		if(sphere.activeRooms.len)
			to_chat(user, "Currently Occupied Rooms:")
			for(var/roomnumber in sphere.activeRooms)
				to_chat(user, roomnumber)
		else
			to_chat(user, "No currenty occupied rooms.")
		if(sphere.storedRooms.len)
			to_chat(user, "Vacated Rooms:")
			for(var/roomnumber in sphere.storedRooms)
				to_chat(user, roomnumber)
		else
			to_chat(user, "No vacated rooms.")

/obj/effect/mob_spawn/human/doctorhilbert
	name = "Doctor Hilbert"
	mob_name = "Doctor Hilbert"
	mob_gender = "male"
	assignedrole = null
	ghost_usable = FALSE
	oxy_damage = 500
	mob_species = /datum/species/skeleton
	instant = TRUE
	outfit = /datum/outfit/doctorhilbert

/datum/outfit/doctorhilbert
	id = /obj/item/card/id/advanced/silver
	uniform = /obj/item/clothing/under/rank/rnd/research_director/doctor_hilbert
	shoes = /obj/item/clothing/shoes/sneakers/brown
	back = /obj/item/storage/backpack/satchel/leather
	suit = /obj/item/clothing/suit/toggle/labcoat
	id_trim = /datum/id_trim/away/hilbert

/obj/item/paper/crumpled/docslogs
	name = "Research Logs"

/obj/item/paper/crumpled/docslogs/Initialize()
	. = ..()
	info = {"<h4><center>Research Logs</center></h4>
	I might just be onto something here!<br>
	The strange space-warping properties of bluespace have been known about for awhile now, but I might be on the verge of discovering a new way of harnessing it.<br>
	It's too soon to say for sure, but this might be the start of something quite important!<br>
	I'll be sure to log any major future breakthroughs. This might be a lot more than I can manage on my own, perhaps I should hire that secretary after all...<br>
	<h4>Breakthrough!</h4>
	I can't believe it, but I did it! Just when I was certain it couldn't be done, I made the final necessary breakthrough.<br>
	Exploiting the effects of space dilation caused by specific bluespace structures combined with a precise use of geometric calculus, I've discovered a way to correlate an infinite amount of space within a finite area!<br>
	While the potential applications are endless, I utilized it in quite a nifty way so far by designing a system that recursively constructs subspace rooms and spatially links them to any of the infinite infinitesimally distinct points on the spheres surface.<br>
	I call it: Hilbert's Hotel!<br>
	<h4>Goodbye</h4>
	I can't take this anymore. I know what happens next, and the fear of what is coming leaves me unable to continue working.<br>
	Any fool in my field has heard the stories. It's not that I didn't believe them, it's just... I guess I underestimated the importance of my own research...<br>
	Robert has reported a further increase in frequency of the strange, prying visitors who ask questions they have no business asking. I've requested him to keep everything on strict lockdown and have permanently dismissed all other assistants.<br>
	I've also instructed him to use the encryption method we discussed for any important quantitative data. The poor lad... I don't think he truly understands what he's gotten himself into...<br>
	It's clear what happens now. One day they'll show up uninvited, and claim my research as their own, leaving me as nothing more than a bullet ridden corpse floating in space.<br>
	I can't stick around to the let that happen.<br>
	I'm escaping into the very thing that brought all this trouble to my doorstep in the first place - my hotel.<br>
	I'll be in <u>[uppertext(num2hex(GLOB.hhMysteryRoomNumber, 0))]</u> (That will make sense to anyone who should know)<br>
	I'm sorry that I must go like this. Maybe one day things will be different and it will be safe to return... maybe...<br>
	Goodbye<br>
	<br>
	<i>Doctor Hilbert</i>"}

/obj/item/paper/crumpled/robertsworkjournal
	name = "Work Journal"
	info = {"<h4>First Week!</h4>
	First week on the new job. It's a secretarial position, but hey, whatever pays the bills. Plus it seems like some interesting stuff goes on here.<br>
	Doc says its best that I don't openly talk about his research with others, I guess he doesn't want it getting out or something. I've caught myself slipping a few times when talking to others, it's hard not to brag about something this cool!<br>
	I'm not really sure why I'm choosing to journal this. Doc seems to log everything. He says it's incase he discovers anything important.<br>
	I guess that's why I'm doing it too, I've always wanted to be a part of something important.<br>
	Here's to a new job and to becoming a part of something important!<br>
	<h4>Weird times...</h4>
	Things are starting to get a little strange around here. Just weeks after Doc's amazing breakthrough, weird visitors have began showing up unannounced, asking strange things about Doc's work.<br>
	I knew Doc wasn't a big fan of company, but even he seemed strangely unnerved when I told him about the visitors.<br>
	He said it's important that from here on out we keep tight security on everything, even other staff members.<br>
	He also said something about securing data, something about hexes. What's that mean? Some sort of curse? Doc never struck me as the magic type...<br>
	He often uses a lot of big sciencey words that I don't really understand, but I kinda dig it, it makes me feel like I'm witnessing something big.<br>
	I hope things go back to normal soon, but I guess that's the price you pay for being a part of something important.<br>
	<h4>Last day I guess?</h4>
	Things are officially starting to get too strange for me.<br>
	The visitors have been coming a lot more often, and they all seem increasingly aggressive and nosey. I'm starting to see why they made Doc so nervous, they're certainly starting to creep me out too.<br>
	Awhile ago Doc started having me keep the place on strict lockdown and requested I refuse entry to anyone else, including previous staff.<br>
	But the weirdest part?<br>
	I haven't seen Doc in days. It's not unusual for him to work continuously for long periods of time in the lab, but when I took a peak in their yesterday - he was nowhere to be seen! I didn't risk prying much further, Doc had a habit of leaving the defense systems on these last few weeks.<br>
	I'm thinking it might be time to call it quits. Can't work much without a boss, plus things are starting to get kind of shady. I wanted to be a part of something important, but you gotta know when to play it safe.<br>
	As my dad always said, "The smart get famous, but the wise survive..."<br>
	<br>
	<i>Robert P.</i>"}

/obj/item/paper/crumpled/bloody/docsdeathnote
	name = "note"
	info = {"This is it isn't it?<br>
	No one's coming to help, that much has become clear.<br>
	Sure, it's lonely, but do I have much choice? At least I brought the analyzer with me, they shouldn't be able to find me without it.<br>
	Who knows who's waiting for me out there. Its either die out there in their hands, or die a slower, slightly more comfortable death in here.<br>
	Everyday I can feel myself slipping away more and more, both physically and mentally. Who knows what happens now...<br>
	Heh, so it's true then, this must be the inescapable path of all great minds... so be it then.<br>
	<br>
	<br>
	<br>
	<i>Choose a room, and enter the sphere<br>
	Lay your head to rest, it soon becomes clear<br>
	There's always more room around every bend<br>
	Not all that's countable has an end...<i>"}
