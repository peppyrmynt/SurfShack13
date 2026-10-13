// Defines for the HippieStation Gang War port (surfshack13/code/modules/hippie/gangs)

/// A gang's domination_time when no takeover is running
#define GANG_NOT_DOMINATING -1
/// Bosses + lieutenants a gang can have
#define GANG_MAX_LEADERS 3
/// How many times a gang can start a dominator
#define GANG_INITIAL_DOM_ATTEMPTS 3
/// Open turfs within 3 tiles a dominator needs to broadcast
#define GANG_DOM_REQUIRED_TURFS 30
/// How many blocked ticks before the dominator complains again
#define GANG_DOM_BLOCKED_SPAM_CAP 6

// Which shops a /datum/gang_item shows up in
/// Normal Gang War gangtools (gang-wide influence)
#define GANG_MODE_GANGS (1<<0)
/// Gangmageddon personal gangtools (per-gangster points)
#define GANG_MODE_GANGMAGEDDON (1<<1)
/// Gangmageddon vigilante uplinks
#define GANG_MODE_VIGILANTE (1<<2)
