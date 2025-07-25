SUBSYSTEM_DEF(pathfinder)
	name = "Pathfinder"
	init_order = INIT_ORDER_PATH
	flags = SS_NO_FIRE
	var/datum/flowcache/mobs
	var/datum/flowcache/circuits
	var/static/space_type_cache
	var/static/openspace_type_cache

/datum/controller/subsystem/pathfinder/Initialize()
	space_type_cache = typecacheof(/turf/open/space)
	openspace_type_cache = typecacheof(/turf/open/openspace)
	mobs = new(10)
	circuits = new(3)
	return ..()

/datum/flowcache
	var/lcount
	var/run
	var/free
	var/list/flow

/datum/flowcache/New(n)
	. = ..()
	lcount = n
	run = 0
	free = 1
	flow = new/list(lcount)

/datum/flowcache/proc/getfree(atom/M)
	if(run < lcount)
		run += 1
		while(flow[free])
			CHECK_TICK
			free = (free % lcount) + 1
		var/t = addtimer(CALLBACK(src, TYPE_PROC_REF(/datum/flowcache, toolong), free), 150, TIMER_STOPPABLE)
		flow[free] = t
		flow[t] = M
		return free
	else
		return 0

/datum/flowcache/proc/toolong(l)
	log_game("Pathfinder route took longer than 150 ticks, src bot [flow[flow[l]]]")
	found(l)

/datum/flowcache/proc/found(l)
	deltimer(flow[l])
	flow[l] = null
	run -= 1
