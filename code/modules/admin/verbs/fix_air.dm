// Proc taken from yogstation, credit to nichlas0010 for the original
/client/proc/fix_air(turf/open/T in world)
	set name = "Fix Air"
	set category = "Адм.Игра"
	set desc = "Fixes air in specified radius."

	if(!holder)
		to_chat(src, "Only administrators may use this command.")
		return
	if(check_rights(R_ADMIN,1))
		var/range=input("Enter range:","Num",2) as num
		message_admins("[key_name_admin(usr)] fixed air with range [range] in area [T.loc.name]")
		log_game("[key_name_admin(usr)] fixed air with range [range] in area [T.loc.name]")
		var/datum/gas_mixture/GM = new
		for(var/turf/open/F in range(range,T))
			if(F.blocks_air)
			//skip walls
				continue
			GM.parse_gas_string(F.initial_gas_mix)
			F.copy_air(GM)
			F.update_visuals()

/client/proc/clear_all_pipenets()
	set name = "Empties all gases from pipenets"
	set category = "Адм.Игра"
	set desc = "Empties all gases from pipenets, temporarily disables atmos"

	if(!holder)
		to_chat(src, "Only administrators may use this command.")
		return
	if(!check_rights(R_ADMIN, 1))
		return

	if(Master.current_runlevel < log(2, RUNLEVEL_GAME) + 1)
		to_chat(src, "This command may not be used before the game has started!")
		message_admins("[src] has attempted to clear pipenets before the game has started.")
		return

	if(alert("Do you want to clear ALL pipenets?", "Clear all pipenets", "No", "Yes") != "Yes")
		return

	message_admins("[key_name_admin(usr)] cleared all pipenets")
	log_game("[key_name_admin(usr)] cleared all pipenets")

	SSair.can_fire = 0
	for(var/datum/pipeline/pipenetwork in SSair.networks)
		pipenetwork.empty()
	SSair.can_fire = 1
