/obj/item/storage/box/syndie_kit/bowling
	name = "Right-Up-Your-Alley bowling kit"
	desc = "Bowling is definitely a real sport. Anyone who says otherwise is stupid.\
			Suit up with the latest in bowling fashion, and prepare to show off your skills.\
			Syndicate nanites embedded in the bowling jersey will make you a real Mister 300,\
			with no training required."

/obj/item/storage/box/syndie_kit/bowling/PopulateContents()
	new /obj/item/clothing/shoes/bowling(src)
	new /obj/item/clothing/under/bowling_jersey(src)
	new /obj/item/bowling_ball(src)
	new /obj/item/bowling_ball(src)
	new /obj/item/bowling_ball(src)
	new /obj/item/bowling_ball(src)
	new /obj/item/bowling_pins(src)
	new /obj/item/bowling_pins(src)
	new /obj/item/bowling_pins(src)
	new /obj/item/bowling_pins(src)

/datum/uplink_item/dangerous/bowling
	name = "Bowling Kit"
	desc = "A cardboard box containing a full set of bowler-style clothing and FIVE whole bowling balls! \
			The packaged shoes allow for increased mobility and the jersey enhances your bowling skills, allowing you \
			to make your thrown bowling balls turn ANYONE into your bowling pins. Need to blend in instead? Four standard bowling pins are also included. Hey, Agent, let's go bowling!"
	item = /obj/item/storage/box/syndie_kit/bowling
	cost = 11
	surplus = 20
