// Ways a head can be destroyed by /mob/living/carbon/proc/gore_destroy_head()
/// Blunt force: stomps, bats, floor slams.
#define GORE_HEAD_CRUSHED "crushed"
/// Gunshots and explosive force.
#define GORE_HEAD_BLASTED "blasted"
/// Frenzied knife work.
#define GORE_HEAD_STABBED "stabbed"

/// Lets an ultraviolent mob execute anyone prone, stunned, unconscious or dead, instead of only people in crit.
#define TRAIT_RAMPAGE_EXECUTIONER "rampage_executioner"
/// Sent to the attacker when an ultraviolence execution finishes: (mob/living/carbon/victim, was_alive)
#define COMSIG_MOB_ULTRAVIOLENCE_EXECUTION "mob_ultraviolence_execution"
