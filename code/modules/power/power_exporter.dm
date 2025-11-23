/obj/machinery/power/exporter
	name = "power exporter"
	desc = "It exports surplus electrical power over vast distances using highly secretive experimental technology. Exporting electrical energy this way is a decent method to earn a living."
	icon = 'icons/obj/machines/dominator.dmi'
	icon_state = "dominator"
	circuit = /obj/item/circuitboard/machine/power_exporter
	density = 1
	anchored = FALSE
	verb_say = "states"
	var/drain_rate = 0 // amount of power to drain per tick
	var/power_drained = 0 // has drained this much power
	var/active = FALSE
	var/checkForPay = 0
	var/creditMult = 0.25

	var/obj/structure/cable/attached

/obj/machinery/power/exporter/examine(mob/user)
	. = ..()
	if(!anchored)
		. += "<span class='notice'>[src] isn't anchored.</span>"
	else
		. += "<span class='notice'>[src] IS anchored.</span>"
	if(!active)
		. += "<span class='notice'>[src] seems to be offline.</span>"
	else
		. += "<span class='notice'>[src] is exporting [drain_rate] watts of power, it has consumed [power_drained] watts so far.</span>"
	if(!isnull(attached))
		var/datum/powernet/powernet = attached.powernet
		var/total_excess_power = (powernet.netexcess * 0.001)
		if(powernet)
			. += "<span class='notice'>The powernet currently has approximately [total_excess_power] kilowatts to pull from.</span>"
		else
			. += "<span class='notice'>[src] has to first be anchored onto exposed power lines to detect the powernet.</span>"

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
					to_chat(user, span_warning("[src] will not function without being anchored atop exposed power lines!"))
			if(!anchored && !isinspace())
				connect_to_network()
				to_chat(user, span_notice("You secure the [src] to the floor."))
				anchored = TRUE
			else if(anchored)
				disconnect_from_network()
				attached = null
				to_chat(user, span_notice("You unsecure and disconnect the [src]."))
				anchored = FALSE
			playsound(loc, 'sound/items/Deconstruct.ogg', 50, 1)
			return
	return ..()

/obj/machinery/power/exporter/attack_hand(mob/user)
	if(!anchored)
		to_chat(user, span_warning("This device must be anchored by a wrench!"))
		return
	..()

/obj/machinery/power/exporter/interact(mob/user)
	if(!anchored)
		to_chat(user, span_warning("This device must be anchored by a wrench!"))
		return
	if(!Adjacent(user) && (!isAI(user)))
		return
	if(active)
		src.say("Manual shutdown engaged.")
		active = FALSE
		drain_rate = 0
		icon_state = "dominator"
	else
		if(isnull(attached))
			return

		var/datum/powernet/powernet = attached.powernet
		if(isnull(powernet))
			if(active)
				src.say("Cannot detect the power net, shutting down.")
				return
			return

		var/power_drain_amt = tgui_input_number(user, "How much power would you like to siphon? (In Kilowatts)", "Power Exporter", default = 1, max_value = 10000, min_value = 1)

		if(isnull(power_drain_amt) || power_drain_amt <= 0)
			to_chat(user, span_notice("But you refrained from inputing any power draw..."))
			return

		if(!Adjacent(user))
			return

		var/power_in_watts = power_drain_amt * 1000

		if((powernet.netexcess -= power_in_watts) >= power_in_watts) // Get the excess, and deduct how much we'd draw from the powernet. If the powernet can currently support our constant draw, then it's go time.
			drain_rate = power_in_watts
			active = TRUE
			icon_state = "dominator-Yellow"
		else
			src.say("The power drain amount requested exceeds the available energy surplus.")
			return

/obj/machinery/power/exporter/process()
	if(isnull(attached)) // prevent constant runtimes
		if(active)
			src.say("Cannot detect any power cables, shutting down.")
			active = FALSE
			drain_rate = 0
			icon_state = "dominator"
			return
		return
	var/datum/powernet/powernet = attached.powernet
	if(isnull(powernet))
		if(active)
			src.say("Cannot detect the power net, shutting down.")
			active = FALSE
			drain_rate = 0
			icon_state = "dominator"
			return
		return
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

	src.say("Exported [power_drained] watts of power! Cargo budget has recieved [cargo_money] cr. Engineering budget has recieved [engi_money] cr.")

	var/datum/bank_account/cargo_bank = SSeconomy.get_dep_account(ACCOUNT_CAR)
	cargo_bank.adjust_money(cargo_money)

	var/datum/bank_account/engi_bank = SSeconomy.get_dep_account(ACCOUNT_ENG)
	engi_bank.adjust_money(engi_money)

	power_drained = 0 // reset the power drained to avoid exponental inf money gen
