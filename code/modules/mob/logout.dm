/mob/Logout()
	SEND_SIGNAL(src, COMSIG_MOB_LOGOUT)
	remove_typing_indicator()
	log_message("[key_name(src)] is no longer owning mob [src]([src.type])", LOG_OWNERSHIP)
	SStgui.on_logout(src)
	unset_machine()
	remove_from_player_list()
	clear_client_in_contents()
	..()

	if(loc)
		loc.on_log(FALSE)

	if(client)
		for(var/foo in client.player_details.post_logout_callbacks)
			var/datum/callback/CB = foo
			CB.Invoke()

	return TRUE
