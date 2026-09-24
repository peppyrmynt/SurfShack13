from pathlib import Path
import re

normal = Path('code/modules/mob/living/basic/guardian/stands/stand_normal_powers.dme')
s = normal.read_text()

for line in (
    '\tADD_TRAIT(owner, TRAIT_PACIFISM, STAND_TIME_ERASURE_TRAIT)\n',
    '\tREMOVE_TRAIT(owner, TRAIT_PACIFISM, STAND_TIME_ERASURE_TRAIT)\n',
):
    count = s.count(line)
    if count != 1:
        raise SystemExit(f'Expected exactly one Time Erasure pacifism line {line!r}, found {count}')
    s = s.replace(line, '', 1)

old_text = 'Erase yourself, your summoner, and allied Stands from normal interaction for a Potential-scaled duration. You cannot attack while erased.'
new_text = 'Erase yourself, your summoner, and allied Stands from normal interaction for a Potential-scaled duration.'
if s.count(old_text) != 1:
    raise SystemExit(f'Expected one Time Erasure playstyle line, found {s.count(old_text)}')
s = s.replace(old_text, new_text, 1)
normal.write_text(s)

req = Path('code/modules/mob/living/basic/guardian/stands/stand_requiem.dme')
r = req.read_text()

old_vars = '''\tvar/pocket_trait
\tvar/pocket_z
\tvar/datum/weakref/pocket_return
'''
new_vars = '''\tvar/pocket_trait
\tvar/pocket_z
\tvar/datum/weakref/pocket_center
\tvar/datum/weakref/pocket_return
'''
if r.count(old_vars) != 1:
    raise SystemExit(f'Expected one pocket var block, found {r.count(old_vars)}')
r = r.replace(old_vars, new_vars, 1)

old_minors = '''/datum/component/arrow_stand/proc/grant_requiem_minors()
\tgrant_power_action(/datum/action/cooldown/mob_cooldown/guardian_alarm_snare)
\tgrant_power_action(/datum/action/cooldown/mob_cooldown/guardian_bluespace_beacon)
\tvar/mob/living/basic/guardian/guardian = parent
\tguardian.playstyle_string += "<br><b>Requiem minors:</b> Surveillance Snares and Teleportation Pad."
'''
new_minors = '''/// Requiem receives both historical minor powers, but they must not lock each other out.
/datum/action/cooldown/mob_cooldown/stand_requiem_alarm_snare
\tparent_type = /datum/action/cooldown/mob_cooldown/guardian_alarm_snare
\tshared_cooldown = NONE

/datum/action/cooldown/mob_cooldown/stand_requiem_bluespace_beacon
\tparent_type = /datum/action/cooldown/mob_cooldown/guardian_bluespace_beacon
\tshared_cooldown = NONE

/datum/component/arrow_stand/proc/grant_requiem_minors()
\tgrant_power_action(/datum/action/cooldown/mob_cooldown/stand_requiem_alarm_snare)
\tgrant_power_action(/datum/action/cooldown/mob_cooldown/stand_requiem_bluespace_beacon)
\tvar/mob/living/basic/guardian/guardian = parent
\tguardian.playstyle_string += "<br><b>Requiem minors:</b> Surveillance Snares and Teleportation Pad."
'''
if r.count(old_minors) != 1:
    raise SystemExit(f'Expected one Requiem minors block, found {r.count(old_minors)}')
r = r.replace(old_minors, new_minors, 1)

pattern = re.compile(
    r'/datum/component/arrow_stand/proc/ensure_pocket_dimension\(\)\n.*?(?=\n/obj/effect/timestop/magic/stand_requiem)',
    re.S,
)
if len(pattern.findall(r)) != 1:
    raise SystemExit(f'Expected one ensure_pocket_dimension block, found {len(pattern.findall(r))}')
new_pocket = '''/datum/component/arrow_stand/proc/ensure_pocket_dimension()
\tvar/turf/existing_center = pocket_center?.resolve()
\tif(pocket_z && existing_center)
\t\treturn TRUE
\tpocket_z = null
\tpocket_center = null
\tpocket_trait = "Stand Pocket Dimension [GLOB.stand_pocket_counter++]"

\t// This room is a map template. LoadGroup() is for full map files and previously
\t// created the z-level without placing the 9x9 Stand room at the destination.
\tvar/datum/map_template/pocket_template = new("_maps/templates/stand_pocket_dimension.dmm", pocket_trait, TRUE)
\tif(!pocket_template.width || !pocket_template.height)
\t\tmessage_admins("A Requiem Stand pocket dimension template failed to parse.")
\t\tlog_game("A Requiem Stand pocket dimension template failed to parse.")
\t\tqdel(pocket_template)
\t\treturn FALSE

\tvar/template_x = round((world.maxx - pocket_template.width) * 0.5) + 1
\tvar/template_y = round((world.maxy - pocket_template.height) * 0.5) + 1
\tvar/center_x = template_x + round((pocket_template.width - 1) * 0.5)
\tvar/center_y = template_y + round((pocket_template.height - 1) * 0.5)
\tvar/datum/space_level/pocket_level = pocket_template.load_new_z(TRUE)
\tif(!pocket_level)
\t\tmessage_admins("A Requiem Stand pocket dimension failed to load.")
\t\tlog_game("A Requiem Stand pocket dimension failed to load.")
\t\tqdel(pocket_template)
\t\treturn FALSE

\tpocket_z = pocket_level.z_value
\tpocket_level.traits[pocket_trait] = TRUE
\tpocket_level.traits[ZTRAIT_BOMBCAP_MULTIPLIER] = 0
\tpocket_level.traits[ZTRAIT_GRAVITY] = STANDARD_GRAVITY
\tSSmapping.calculate_z_level_gravity(pocket_z)

\tvar/turf/loaded_center = locate(center_x, center_y, pocket_z)
\tqdel(pocket_template)
\tif(!loaded_center || !istype(loaded_center, /turf/open/indestructible))
\t\tmessage_admins("A Requiem Stand pocket dimension loaded without its expected center floor.")
\t\tlog_game("A Requiem Stand pocket dimension loaded without its expected center floor.")
\t\tpocket_z = null
\t\treturn FALSE
\tpocket_center = WEAKREF(loaded_center)
\treturn TRUE
'''
r = pattern.sub(new_pocket, r, count=1)

old_center = '''\t\tvar/turf/pocket_center = locate(5, 5, stand_component.pocket_z)
\t\tif(!pocket_center)
\t\t\tguardian.balloon_alert(guardian, "pocket dimension failed to resolve!")
\t\t\treturn FALSE
\t\tstand_component.pocket_return = WEAKREF(current)
\t\tfor(var/mob/living/member as anything in group)
\t\t\tif(QDELETED(member))
\t\t\t\tcontinue
\t\t\tmember.forceMove(pocket_center)
'''
new_center = '''\t\tvar/turf/pocket_destination = stand_component.pocket_center?.resolve()
\t\tif(!pocket_destination)
\t\t\tguardian.balloon_alert(guardian, "pocket dimension failed to resolve!")
\t\t\treturn FALSE
\t\tstand_component.pocket_return = WEAKREF(current)
\t\tfor(var/mob/living/member as anything in group)
\t\t\tif(QDELETED(member))
\t\t\t\tcontinue
\t\t\tmember.forceMove(pocket_destination)
'''
if r.count(old_center) != 1:
    raise SystemExit(f'Expected one pocket destination block, found {r.count(old_center)}')
r = r.replace(old_center, new_center, 1)
req.write_text(r)
