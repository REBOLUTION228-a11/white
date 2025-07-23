#define AIR_CONTENTS	((25*ONE_ATMOSPHERE)*(air_contents.return_volume())/(R_IDEAL_GAS_EQUATION*air_contents.return_temperature()))
/obj/machinery/atmospherics/components/unary/tank
	icon = 'icons/obj/atmospherics/pipes/pressure_tank.dmi'
	icon_state = "generic"

	name = "канистра"
	desc = "Огромная канистра, которая содержит газ под большим давлением."

	max_integrity = 800
	density = TRUE
	layer = ABOVE_WINDOW_LAYER
	pipe_flags = PIPING_ONE_PER_TURF

	var/volume = 10000 //in liters
	/// The typepath of the gas this tank should be filled with.
	var/gas_type = null

/obj/machinery/atmospherics/components/unary/tank/Initialize()
	. = ..()
	var/datum/gas_mixture/air_contents = airs[1]
	air_contents.set_volume(volume)
	air_contents.set_temperature(T20C)
	if(gas_type)
		air_contents.set_moles(gas_type, AIR_CONTENTS)
		name = "[name] ([GLOB.gas_data.names[gas_type]])"
	set_piping_layer(piping_layer)


/obj/machinery/atmospherics/components/unary/tank/air
	icon_state = "grey"
	name = "канистра (Воздух)"

/obj/machinery/atmospherics/components/unary/tank/air/Initialize()
	. = ..()
	var/datum/gas_mixture/air_contents = airs[1]
	air_contents.set_moles(GAS_O2, AIR_CONTENTS * 0.2)
	air_contents.set_moles(GAS_N2, AIR_CONTENTS * 0.8)

/obj/machinery/atmospherics/components/unary/tank/carbon_dioxide
	gas_type = GAS_CO2

/obj/machinery/atmospherics/components/unary/tank/carbon_dioxide/Initialize(mapload)
	. = ..()
	var/datum/gas_mixture/air_contents = airs[1]
	air_contents.set_moles(GAS_CO2, AIR_CONTENTS)

/obj/machinery/atmospherics/components/unary/tank/toxins
	icon_state = "orange"
	gas_type = GAS_PLASMA

/obj/machinery/atmospherics/components/unary/tank/toxins/Initialize(mapload)
	. = ..()
	var/datum/gas_mixture/air_contents = airs[1]
	air_contents.set_moles(GAS_PLASMA, AIR_CONTENTS)

/obj/machinery/atmospherics/components/unary/tank/nitrogen
	icon_state = "red"
	gas_type = GAS_N2

/obj/machinery/atmospherics/components/unary/tank/nitrogen/Initialize(mapload)
	. = ..()
	var/datum/gas_mixture/air_contents = airs[1]
	air_contents.set_moles(GAS_N2, AIR_CONTENTS)

/obj/machinery/atmospherics/components/unary/tank/oxygen
	icon_state = "blue"
	gas_type = GAS_O2

/obj/machinery/atmospherics/components/unary/tank/oxygen/Initialize(mapload)
	. = ..()
	var/datum/gas_mixture/air_contents = airs[1]
	air_contents.set_moles(GAS_O2, AIR_CONTENTS)

/obj/machinery/atmospherics/components/unary/tank/nitrous
	icon_state = "red_white"
	gas_type = GAS_NITROUS

/obj/machinery/atmospherics/components/unary/tank/nitrous/Initialize(mapload)
	. = ..()
	var/datum/gas_mixture/air_contents = airs[1]
	air_contents.set_moles(GAS_NITROUS, AIR_CONTENTS)

/obj/machinery/atmospherics/components/unary/tank/bz
	gas_type = GAS_BZ

/obj/machinery/atmospherics/components/unary/tank/bz/Initialize(mapload)
	. = ..()
	var/datum/gas_mixture/air_contents = airs[1]
	air_contents.set_moles(GAS_BZ, AIR_CONTENTS)

/obj/machinery/atmospherics/components/unary/tank/hypernoblium
	icon_state = "blue"
	gas_type = GAS_HYPERNOB

/obj/machinery/atmospherics/components/unary/tank/hypernoblium/Initialize(mapload)
	. = ..()
	var/datum/gas_mixture/air_contents = airs[1]
	air_contents.set_moles(GAS_HYPERNOB, AIR_CONTENTS)

/obj/machinery/atmospherics/components/unary/tank/miasma
	gas_type = GAS_MIASMA

/obj/machinery/atmospherics/components/unary/tank/miasma/Initialize(mapload)
	. = ..()
	var/datum/gas_mixture/air_contents = airs[1]
	air_contents.set_moles(GAS_MIASMA, AIR_CONTENTS)

/obj/machinery/atmospherics/components/unary/tank/nitryl
	gas_type = GAS_NITRYL

/obj/machinery/atmospherics/components/unary/tank/nitryl/Initialize(mapload)
	. = ..()
	var/datum/gas_mixture/air_contents = airs[1]
	air_contents.set_moles(GAS_NITRYL, AIR_CONTENTS)

/obj/machinery/atmospherics/components/unary/tank/pluoxium
	icon_state = "blue"
	gas_type = GAS_PLUOXIUM

/obj/machinery/atmospherics/components/unary/tank/pluoxium/Initialize(mapload)
	. = ..()
	var/datum/gas_mixture/air_contents = airs[1]
	air_contents.set_moles(GAS_PLUOXIUM, AIR_CONTENTS)

/obj/machinery/atmospherics/components/unary/tank/stimulum
	icon_state = "red"
	gas_type = GAS_STIMULUM

/obj/machinery/atmospherics/components/unary/tank/stimulum/Initialize(mapload)
	. = ..()
	var/datum/gas_mixture/air_contents = airs[1]
	air_contents.set_moles(GAS_STIMULUM, AIR_CONTENTS)

/obj/machinery/atmospherics/components/unary/tank/tritium
	gas_type = GAS_TRITIUM

/obj/machinery/atmospherics/components/unary/tank/tritium/Initialize(mapload)
	. = ..()
	var/datum/gas_mixture/air_contents = airs[1]
	air_contents.set_moles(GAS_TRITIUM, AIR_CONTENTS)

/obj/machinery/atmospherics/components/unary/tank/water_vapor
	icon_state = "grey"
	gas_type = GAS_H2O

/obj/machinery/atmospherics/components/unary/tank/water_vapor/Initialize(mapload)
	. = ..()
	var/datum/gas_mixture/air_contents = airs[1]
	air_contents.set_moles(GAS_H2O, AIR_CONTENTS)
