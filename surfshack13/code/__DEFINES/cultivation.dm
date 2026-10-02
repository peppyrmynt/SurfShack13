// Cultivation (xianxia) defines. See surfshack13/code/modules/cultivation

// Realms. Each realm unlocks the next tier of every law you hold and one more law slot.
#define REALM_MORTAL 0
#define REALM_QI_CONDENSATION 1
#define REALM_FOUNDATION 2
#define REALM_GOLDEN_CORE 3
#define REALM_NASCENT_SOUL 4
#define REALM_MAX REALM_NASCENT_SOUL

// Elements (wu xing)
#define ELEMENT_METAL "metal"
#define ELEMENT_WATER "water"
#define ELEMENT_WOOD "wood"
#define ELEMENT_FIRE "fire"
#define ELEMENT_EARTH "earth"

/// Generating cycle: key element feeds value element
GLOBAL_LIST_INIT(cultivation_generates, list(
	ELEMENT_METAL = ELEMENT_WATER,
	ELEMENT_WATER = ELEMENT_WOOD,
	ELEMENT_WOOD = ELEMENT_FIRE,
	ELEMENT_FIRE = ELEMENT_EARTH,
	ELEMENT_EARTH = ELEMENT_METAL,
))

/// Overcoming cycle: key element overcomes value element
GLOBAL_LIST_INIT(cultivation_overcomes, list(
	ELEMENT_METAL = ELEMENT_WOOD,
	ELEMENT_WOOD = ELEMENT_EARTH,
	ELEMENT_EARTH = ELEMENT_WATER,
	ELEMENT_WATER = ELEMENT_FIRE,
	ELEMENT_FIRE = ELEMENT_METAL,
))

// ORGAN_SLOT_DANTIAN lives in code/__DEFINES/DNA.dm so it can sit in organ_process_order

/// Is this mob a cultivator? Returns the datum or null.
#define IS_CULTIVATOR(mob) (mob?.mind?.has_antag_datum(/datum/antagonist/cultivator))

// Insight sources. Each source has its own cooldown so grinding one action stops paying.
#define INSIGHT_SOURCE_CRAFT "craft"
#define INSIGHT_SOURCE_COOK "cook"
#define INSIGHT_SOURCE_TOOL "tool"
#define INSIGHT_SOURCE_WELD "weld"
#define INSIGHT_SOURCE_MINING "mining"
#define INSIGHT_SOURCE_CLEANING "cleaning"
#define INSIGHT_SOURCE_FISHING "fishing"
#define INSIGHT_SOURCE_ATHLETICS "athletics"
#define INSIGHT_SOURCE_HARVEST "harvest"
#define INSIGHT_SOURCE_SURGERY "surgery"
#define INSIGHT_SOURCE_TECHNIQUE "technique"
#define INSIGHT_SOURCE_TALISMAN "talisman"
#define INSIGHT_SOURCE_TEACHING "teaching"
#define INSIGHT_SOURCE_EPIPHANY "epiphany"
#define INSIGHT_SOURCE_PASSIVE "passive"
#define INSIGHT_SOURCE_EXPLORE "explore"
#define INSIGHT_SOURCE_COMBAT "combat"
#define INSIGHT_SOURCE_READING "reading"
#define INSIGHT_SOURCE_TEA "tea"
#define INSIGHT_SOURCE_DRINK_WATER "drink_water"
#define INSIGHT_SOURCE_WITNESS "witness"

/// Seconds between passive insight ticks
#define CULTIVATION_PASSIVE_INTERVAL 40

/// Pending (unconsolidated) insight caps here until you meditate
#define CULTIVATION_MAX_PENDING_INSIGHT 60

// Signals, sent to the mob doing the thing
/// From personal crafting: (datum/crafting_recipe/recipe, atom/result)
#define COMSIG_MOB_CULTIVATION_CRAFTED "mob_cultivation_crafted"
/// From atom tool_act success: (atom/target, obj/item/tool)
#define COMSIG_MOB_CULTIVATION_TOOL_USED "mob_cultivation_tool_used"
/// From mind adjust_experience: (skill, amount)
#define COMSIG_MOB_CULTIVATION_SKILL_EXP "mob_cultivation_skill_exp"
/// From hydroponics harvest: (obj/machinery/hydroponics/tray)
#define COMSIG_MOB_CULTIVATION_HARVESTED "mob_cultivation_harvested"
/// Sent to the cultivator's body when they change realm: (datum/antagonist/cultivator/cultivator)
#define COMSIG_MOB_CULTIVATION_REALM_CHANGED "mob_cultivation_realm_changed"
