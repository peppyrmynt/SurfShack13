/obj/machinery/rnd/production/circuit_imprinter
	name = "circuit imprinter"
	desc = "Manufactures circuit boards for the construction of machines."
	icon_state = "circuit_imprinter"
	production_animation = "circuit_imprinter_ani"
	circuit = /obj/item/circuitboard/machine/circuit_imprinter
	allowed_buildtypes = IMPRINTER

/obj/machinery/rnd/production/circuit_imprinter/compute_efficiency()
	var/rating = 0
	for(var/datum/stock_part/servo/servo in component_parts)
		rating += servo.tier

	return 0.5 ** max(rating - 1, 0) // One sheet, half sheet, quarter sheet, eighth sheet.

/obj/machinery/rnd/production/circuit_imprinter/flick_animation(datum/material/mat)
	return //we presently have no animation

/obj/machinery/rnd/production/circuit_imprinter/offstation
	name = "ancient circuit imprinter"
	desc = "Manufactures circuit boards for the construction of machines. Its ancient construction may limit its ability to print all known technology."
	allowed_buildtypes = AWAY_IMPRINTER
	circuit = /obj/item/circuitboard/machine/circuit_imprinter/offstation

/*
 * SURFSHACK RESTORATION: tgstation/tgstation#55663
 *
 * The historical recipes cost 4,000 iron when one sheet represented 2,000
 * material units, making each shell cost two sheets. Keep the modern recipes
 * available to every supported lathe while preserving that low unit cost.
 * Bulk boxes contain seven shells and therefore cost fourteen sheets.
 *
 * These overrides intentionally compile after the autolathe design files.
 */
/datum/design/shotgun_slug
	build_type = AUTOLATHE | PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 2)

/datum/design/buckshot_shell
	build_type = AUTOLATHE | PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 2)

/datum/design/buckshot_box
	build_type = AUTOLATHE | PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 14)

/datum/design/slug_box
	build_type = AUTOLATHE | PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 14)
