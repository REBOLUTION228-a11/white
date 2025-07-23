/atom/var/CanAtmosPass = ATMOS_PASS_YES

/atom/proc/CanAtmosPass(turf/T)
	switch (CanAtmosPass)
		if (ATMOS_PASS_PROC)
			return ATMOS_PASS_YES
		if (ATMOS_PASS_DENSITY)
			return !density
		else
			return CanAtmosPass

/turf/CanAtmosPass = ATMOS_PASS_NO

/turf/open/CanAtmosPass = ATMOS_PASS_PROC

/turf/open/CanAtmosPass(turf/T, vertical = FALSE)
	var/can_pass = TRUE
	var/direction = vertical ? get_dir_multiz(src, T) : get_dir(src, T)
	var/opposite_direction = REVERSE_DIR(direction)
	if(vertical && !(zAirOut(direction, T) && T.zAirIn(direction, src)))
		can_pass = FALSE
	if(blocks_air || T.blocks_air)
		can_pass = FALSE
	//This path is a bit weird, if we're just checking with ourselves no sense asking objects on the turf
	if (T == src)
		return can_pass

	//Can't just return if canpass is false here, we need to set superconductivity
	for(var/obj/checked_object in contents + T.contents)
		var/turf/other = (checked_object.loc == src ? T : src)
		if(CANATMOSPASS(checked_object, other, vertical))
			continue
		can_pass = FALSE
		//the direction and open/closed are already checked on can_atmos_pass() so there are no arguments
		if(checked_object.BlockThermalConductivity())
			conductivity_blocked_directions |= direction
			T.conductivity_blocked_directions |= opposite_direction
			return FALSE //no need to keep going, we got all we asked (Is this even faster? fuck you it's soul)

	//Superconductivity is a bitfield of directions we can't conduct with
	//Yes this is really weird. Fuck you
	conductivity_blocked_directions &= ~direction
	T.conductivity_blocked_directions &= ~opposite_direction

	return can_pass

/turf/proc/update_conductivity(turf/T)
	var/dir = get_dir_multiz(src, T)
	var/opp = REVERSE_DIR(dir)

	if(T == src)
		return

	//all these must be above zero for auxmos to even consider them
	if(!thermal_conductivity || !heat_capacity || !T.thermal_conductivity || !T.heat_capacity)
		conductivity_blocked_directions |= dir
		T.conductivity_blocked_directions |= opp
		return

	for(var/obj/O in contents+T.contents)
		if(O.BlockThermalConductivity(opp)) 	//the direction and open/closed are already checked on CanAtmosPass() so there are no arguments
			conductivity_blocked_directions |= dir
			T.conductivity_blocked_directions |= opp

/turf/proc/block_all_conductivity()
	conductivity_blocked_directions |= NORTH | SOUTH | EAST | WEST | UP | DOWN

/atom/movable/proc/BlockThermalConductivity(dir) // Objects that don't let heat through.
	return FALSE

/turf/proc/ImmediateCalculateAdjacentTurfs()
	LAZYINITLIST(src.atmos_adjacent_turfs)
	var/list/atmos_adjacent_turfs = src.atmos_adjacent_turfs
	var/canpass = CANATMOSPASS(src, src, FALSE)

	conductivity_blocked_directions = 0

	var/src_contains_firelock = 1
	if(locate(/obj/machinery/door/firedoor) in src)
		src_contains_firelock |= 2

	for(var/direction in GLOB.cardinals_multiz)
		var/turf/T = get_step_multiz(src, direction)
		if(!istype(T))
			conductivity_blocked_directions |= direction
			continue

		var/other_contains_firelock = 1
		if(locate(/obj/machinery/door/firedoor) in T)
			other_contains_firelock |= 2

		update_conductivity(T)

		if(canpass && CANATMOSPASS(T, src, (direction & (UP|DOWN))) && !(blocks_air || T.blocks_air))
			LAZYINITLIST(T.atmos_adjacent_turfs)
			atmos_adjacent_turfs[T] = other_contains_firelock | src_contains_firelock
			T.atmos_adjacent_turfs[src] = src_contains_firelock
		else
			atmos_adjacent_turfs -= T
			if (T.atmos_adjacent_turfs)
				T.atmos_adjacent_turfs -= src
			UNSETEMPTY(T.atmos_adjacent_turfs)
		SEND_SIGNAL(T, COMSIG_TURF_CALCULATED_ADJACENT_ATMOS)

		T.__update_auxtools_turf_adjacency_info()
	UNSETEMPTY(atmos_adjacent_turfs)
	src.atmos_adjacent_turfs = atmos_adjacent_turfs
	SEND_SIGNAL(src, COMSIG_TURF_CALCULATED_ADJACENT_ATMOS)
	__update_auxtools_turf_adjacency_info()

/turf/proc/clear_adjacencies()
	block_all_conductivity()
	for(var/turf/current_turf as anything in atmos_adjacent_turfs)
		LAZYREMOVE(current_turf.atmos_adjacent_turfs, src)
		current_turf.__update_auxtools_turf_adjacency_info()

	LAZYNULL(atmos_adjacent_turfs)
	__update_auxtools_turf_adjacency_info()

//Only gets a list of adjacencies, does NOT update
/turf/proc/get_atmos_adjacent_turfs(alldir = 0)
	var/adjacent_turfs
	if (atmos_adjacent_turfs)
		adjacent_turfs = atmos_adjacent_turfs.Copy()
	else
		adjacent_turfs = list()

	if (!alldir)
		return adjacent_turfs

	var/turf/current_location = src

	for (var/direction in GLOB.diagonals_multiz)
		var/matching_directions = 0
		var/turf/checked_turf = get_step_multiz(current_location, direction)
		if(!checked_turf)
			continue

		for (var/check_direction in GLOB.cardinals_multiz)
			var/turf/secondary_turf = get_step(checked_turf, check_direction)
			if(!checked_turf.atmos_adjacent_turfs || !checked_turf.atmos_adjacent_turfs[secondary_turf])
				continue

			if (adjacent_turfs[secondary_turf])
				matching_directions++

			if (matching_directions >= 2)
				adjacent_turfs += checked_turf
				break

	return adjacent_turfs

/turf/proc/ImmediateDisableAdjacency(disable_adjacent = TRUE)
	if(disable_adjacent)
		for(var/direction in GLOB.cardinals_multiz)
			var/turf/T = get_step_multiz(src, direction)
			if(!istype(T))
				continue
			if (T.atmos_adjacent_turfs)
				T.atmos_adjacent_turfs -= src
			UNSETEMPTY(T.atmos_adjacent_turfs)
			T.__update_auxtools_turf_adjacency_info(isspaceturf(T.get_z_base_turf()), -1)
	LAZYCLEARLIST(atmos_adjacent_turfs)
	__update_auxtools_turf_adjacency_info(isspaceturf(get_z_base_turf()))

/turf/proc/set_sleeping(should_sleep)

//returns a list of adjacent turfs that can share air with this one.
//alldir includes adjacent diagonal tiles that can share
//	air with both of the related adjacent cardinal tiles
/turf/proc/GetAtmosAdjacentTurfs(alldir = 0)
	var/adjacent_turfs
	if (atmos_adjacent_turfs)
		adjacent_turfs = atmos_adjacent_turfs.Copy()
	else
		adjacent_turfs = list()

	if (!alldir)
		return adjacent_turfs

	var/turf/curloc = src

	for (var/direction in GLOB.diagonals_multiz)
		var/matchingDirections = 0
		var/turf/S = get_step_multiz(curloc, direction)
		if(!S)
			continue

		for (var/checkDirection in GLOB.cardinals_multiz)
			var/turf/checkTurf = get_step(S, checkDirection)
			if(!S.atmos_adjacent_turfs || !S.atmos_adjacent_turfs[checkTurf])
				continue

			if (adjacent_turfs[checkTurf])
				matchingDirections++

			if (matchingDirections >= 2)
				adjacent_turfs += S
				break

	return adjacent_turfs

/atom/proc/air_update_turf()
	var/turf/T = get_turf(loc)
	if(!T)
		return
	T.air_update_turf()

/turf/air_update_turf()
	ImmediateCalculateAdjacentTurfs()

/atom/movable/proc/move_update_air(turf/T)
    if(isturf(T))
        T.air_update_turf()
    air_update_turf()

/atom/proc/atmos_spawn_air(text) //because a lot of people loves to copy paste awful code lets just make an easy proc to spawn your plasma fires
	var/turf/open/T = get_turf(src)
	if(!istype(T))
		return
	T.atmos_spawn_air(text)

/turf/open/atmos_spawn_air(text)
	if(!text || !air)
		return

	var/datum/gas_mixture/G = new
	G.parse_gas_string(text)
	assume_air(G)
