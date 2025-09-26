/obj/machinery/power/exporter
	name = "power exporter"
	desc = "It exports surplus electrical power over vast distances using highly secretive experimental technology. Exporting electrical energy this way is a decent method to earn a living."
	icon = 'icons/obj/machines/dominator.dmi'
	icon_state = "dominator"
	circuit = /obj/item/circuitboard/machine/power_exporter
	density = 1
	anchored = FALSE
	verb_say = "states"
	var/drain_rate = 0	// amount of power to drain per tick
	var/power_drained = 0 		// has drained this much power
	var/active = FALSE
	var/checkForPay = 0
	var/creditMult = 0.25

	var/obj/structure/cable/attached

/obj/machinery/power/exporter/examine(mob/user)
	. = ..()
	if(!active)
		. += "<span class='notice'>The exporter seems to be offline.</span>"
	else
		. += "<span class='notice'>The [src] is exporting [drain_rate] kilowatts of power, it has consumed [power_drained] kilowatts so far.</span>"

obj/machinery/power/exporter/Initialize()
	..()
	GLOB.power_exporter_list += src

obj/machinery/power/exporter/Destroy()
	GLOB.power_exporter_list -= src
	return ..()

/obj/machinery/power/exporter/RefreshParts()
	SHOULD_CALL_PARENT(FALSE)

	var/power_coefficient = 0
	for(var/datum/stock_part/capacitor/capacitor in component_parts)
		power_coefficient += capacitor.tier
	creditMult = initial(creditMult) * power_coefficient

/obj/machinery/power/exporter/attackby(obj/item/O, mob/user, params)
	if(!active)
		if(istype(O, /obj/item/wrench))
			var/turf/T = src.loc
			if(isturf(T) && T.underfloor_accessibility >= UNDERFLOOR_INTERACTABLE)
				attached = locate(/obj/structure/cable) in T
				if(isnull(attached))
					to_chat(user, span_warning("[src] must be placed over an exposed, powered cable node!"))
			if(!anchored && !isinspace())
				connect_to_network()
				user << "<span class='notice'>You secure the [src] to the floor.</span>"
				anchored = TRUE
			else if(anchored)
				disconnect_from_network()
				attached = null
				user << "<span class='notice'>You unsecure and disconnect the [src].</span>"
				anchored = FALSE
			playsound(loc, 'sound/items/Deconstruct.ogg', 50, 1)
			return
	return ..()

/obj/machinery/power/exporter/attack_hand(mob/user)
	..()
	if(!anchored)
		user << "<span class='warning'>This device must be anchored by a wrench!</span>"
		return

/obj/machinery/power/exporter/interact(mob/user)
	if(!anchored)
		user << "<span class='warning'>This device must be anchored by a wrench!</span>"
		return
	if(!Adjacent(user) && (!isAI(user)))
		return
	if(active)
		src.say("Manual shutdown engaged.")
		active = FALSE
		drain_rate = 0
		icon_state = "dominator"
	else
		var/power_drain_amt = tgui_input_number(user, "How much power would you like to siphon? (In Kilowatts)", "Power Exporter", default = 1, max_value = 10000, min_value = 1)

		if(isnull(power_drain_amt) || power_drain_amt <= 0)
			return

		if(!anchored) // Prevent unanchor usage with the TGUI still open.
			user << "<span class='warning'>This device must be anchored by a wrench!</span>"
			return
		if(!Adjacent(user))
			return

		drain_rate = (power_drain_amt * 1000) // We're operating off KILO JOULES here.
		active = TRUE
		icon_state = "dominator-Yellow"

/obj/machinery/power/exporter/process()
	var/datum/powernet/powernet = attached.powernet
	if(active && anchored && powernet)
		if(powernet.netexcess >= drain_rate) // Make sure we have a surplus, and that we aren't dipping below it.
			attached.add_delayedload(drain_rate)
			power_drained += drain_rate
			checkForPay++
			if(checkForPay >= 10) // Just to avoid constant say proc spam
				processPayment()
				checkForPay = 0
		else
			src.say("Power export levels have exceeded energy surplus, shutting down.")
			active = FALSE
			drain_rate = 0
			icon_state = "dominator"
	else
		active = FALSE
		drain_rate = 0
		icon_state = "dominator"

/obj/machinery/power/exporter/proc/processPayment()
	var/cargo_money = (((power_drained / 1000) * 0.3) * creditMult) // aprox 30% of the money goes straight to cargo.
	var/engi_money = (((power_drained / 1000) * 0.7) * creditMult) // the 70% leftover goes straight to the engi budget.

	src.say("Exported [power_drained] kilowatts of power! Cargo budget has recieved [cargo_money] cr. Engineering budget has recieved [engi_money] cr.")

	var/datum/bank_account/cargo_bank = SSeconomy.get_dep_account(ACCOUNT_CAR)
	cargo_bank.adjust_money(cargo_money)

	var/datum/bank_account/engi_bank = SSeconomy.get_dep_account(ACCOUNT_ENG)
	engi_bank.adjust_money(engi_money)

	power_drained = 0 // reset the power drained to avoid exponental inf money gen
