/// The minimum delay value that the delay component can have.
#define COMP_DELAY_MIN_VALUE 0.1

/**
 * # Delay Component
 *
 * Delays a signal by a specified duration.
 */
/obj/item/circuit_component/delay
	display_name = "Задержка"
	desc = "Компонент, который задерживает сигнал на заданную продолжительность."

	/// Amount to delay by
	var/datum/port/input/delay_amount
	/// Input signal to fire the delay
	var/datum/port/input/trigger
	/// Interrupts the delay before it fires
	var/datum/port/input/interrupt

	var/timer_id = TIMER_ID_NULL

	/// The output of the signal
	var/datum/port/output/output

/obj/item/circuit_component/delay/populate_ports()
	delay_amount = add_input_port("Задержка", PORT_TYPE_NUMBER, trigger = null)
	trigger = add_input_port("Активация", PORT_TYPE_SIGNAL, trigger = PROC_REF(trigger_delay))
	interrupt = add_input_port("Результат", PORT_TYPE_SIGNAL, trigger = PROC_REF(interrupt_timer))


/obj/item/circuit_component/delay/proc/trigger_delay(datum/port/input/port)
	CIRCUIT_TRIGGER
	var/delay = delay_amount.value
	if(delay > COMP_DELAY_MIN_VALUE)
		// Convert delay into deciseconds
		timer_id = addtimer(CALLBACK(output, TYPE_PROC_REF(/datum/port/output, set_output), trigger.value), delay*10, TIMER_UNIQUE|TIMER_STOPPABLE|TIMER_OVERRIDE)
	else
		if(timer_id != TIMER_ID_NULL)
			deltimer(timer_id)
			timer_id = TIMER_ID_NULL
		output.set_output(trigger.value)

/obj/item/circuit_component/delay/proc/interrupt_timer(datum/port/input/port)
	CIRCUIT_TRIGGER
	if(timer_id != TIMER_ID_NULL)
		deltimer(timer_id)
		timer_id = TIMER_ID_NULL

#undef COMP_DELAY_MIN_VALUE
