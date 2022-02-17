
//не блядь в пизду эту хуйню нахуй я нихуя не понимаю блядь аааааааааааааааааааааааааааааа
/obj/item/integrated_circuit_old/input/yoheidetector
	complexity = 1
	name = "Плата для перегрузки близжайших генераторов маскировки"
	desc = "Так уж получилось, что технология маскировки попала в общество. Теперь любой может дистанционно взорвать батарейку генератора маскировки."
	extended_desc = "Подрывает невидимых пидоров. Что ещё надо для жизни?"
	activators = list("locate" = IC_PINTYPE_PULSE_IN,"found" = IC_PINTYPE_PULSE_OUT, "not found" = IC_PINTYPE_PULSE_OUT)
	power_draw_per_use = 1

/obj/item/integrated_circuit_old/input/yoheidetector/do_work()
	var/turf/A = locate(/obj/item/shadowcloak/yohei) in range(8, get_turf(src))
	var/turf/T = get_turf(assembly)
	if(!assembly)
		activate_pin(2)
		return
	if(!A || !(A in view(T)))
		activate_pin(2)
		return
	else
		activate_pin(1)
		explosion(A, 1, 1, 1, 1, TRUE, TRUE)

