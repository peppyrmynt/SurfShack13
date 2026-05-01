/obj/structure/bodycontainer/crematorium/creampie
	name = "creampie-torium"
	desc = "It turns humans into creampie."


/obj/structure/bodycontainer/crematorium/creampie/Initialize(mapload)
	. = ..()
	var/static/mutable_appearance/clown_mask
	if(!clown_mask)
		clown_mask = new /mutable_appearance()
		clown_mask.icon = 'icons/obj/clothing/masks.dmi'
		clown_mask.icon_state = "clown"
		clown_mask.plane = src.plane
		clown_mask.dir = dir
	add_overlay(clown_mask)


/obj/structure/bodycontainer/crematorium/examine(mob/user)
	. = ..()
	if(is_clown_job(user.mind?.assigned_role))
		. += "You can turn it into a creampie-torium with bananium."

/obj/structure/bodycontainer/crematorium/attacked_by(obj/item/attacking_item, mob/living/user)
	if(!istype(attacking_item, /obj/item/stack/sheet/mineral/bananium))
		return ..()
	var/obj/item/stack/sheet/banana_sheet = attacking_item
	if(!banana_sheet.use(1))
		return ..()
	var/obj/structure/bodycontainer/crematorium/creampie/creampie = new(loc)
	creampie.dir = dir
	creampie.id = id
	qdel(src)

/obj/structure/bodycontainer/crematorium/creampie/cremate(mob/user)
	AddComponent(/datum/component/tweak, time = 3 SECONDS)
	var/list/pies = list()
	for(var/mob/living/pie as anything in get_all_contents_type(/mob/living))
		pies += new /obj/item/food/pie/cream()
	. = ..()
	for(var/obj/pie in pies)
		pie.forceMove(src)
