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
#define INSIGHT_SOURCE_HEART_DEMON "heart_demon"
#define INSIGHT_SOURCE_ALCHEMY "alchemy"
#define INSIGHT_SOURCE_MUSIC "music"
#define INSIGHT_SOURCE_REFINING "refining"
#define INSIGHT_SOURCE_DUEL "duel"

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

/// Trait source for Spiritual Sense's see-through-walls, which also lets Void Step pass walls
#define SPIRITUAL_SENSE_TRAIT "spiritual_sense"

// Demonic path levels, see forbidden.dm
/// Has never touched the demonic path
#define DEMONIC_NONE 0
/// Was taught the arts by a demonic master, can't teach them on
#define DEMONIC_DISCIPLE 1
/// An antagonist who comprehended the scripture themselves, can transmit it
#define DEMONIC_MASTER 2

// Sect missions, see wuxia/sect_missions.dm
#define SECT_MISSION_PILLS "pills"
#define SECT_MISSION_DUEL "duel"
#define SECT_MISSION_HARVEST "harvest"
#define SECT_MISSION_MEDITATE "meditate"
#define SECT_MISSION_RECRUIT "recruit"
#define SECT_MISSION_HEART_DEMON "heart_demon"

/// Highest refinement grade a bound artifact can reach (Dao-grade)
#define MAX_ARTIFACT_REFINEMENT 5

/// Insight consolidated past the peak of Nascent Soul before Ascension can be attempted
#define CULTIVATION_ASCENSION_PROGRESS 400

// Body Molding Art, see body/
/// Is this mob a body cultivator? Returns the datum or null.
#define IS_BODY_CULTIVATOR(mob) (mob?.mind?.has_antag_datum(/datum/antagonist/body_cultivator))
/// Highest body stage (Primordial Chaos Body)
#define BODY_STAGE_MAX 9
/// Mortals who haven't committed to the Body Molding Art stop here (Copper Skin)
#define BODY_STAGE_MORTAL_CAP 1
/// Pending tempering caps here until you Forge the Body
#define BODY_TEMPERING_CAP 120
// Body training sources, each with its own cooldown
#define BODY_TRAINING_GYM "gym"
#define BODY_TRAINING_FIGHT "fight"
#define BODY_TRAINING_STRIKE "strike"
#define BODY_TRAINING_BEATEN "beaten"
#define BODY_TRAINING_MINING "mining"

// Cauldron pill grades
#define PILL_GRADE_LOW "low"
#define PILL_GRADE_MID "mid"
#define PILL_GRADE_HIGH "high"
#define PILL_GRADE_SPIRIT "spirit"
/// Body arts can't push exhaustion past this
#define BODY_EXHAUSTION_MAX 100
