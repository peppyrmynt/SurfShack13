/*
Once listening and speaking rooms are seperate and set up,
this will be replaced by logic in  code/modules/language/_language_holder.dm
*/
/// for drones that shouldnt speak common
#define ROOM_DRONE "room_drone"
/// for ghost and dead mobs
#define ROOM_GHOST "room_ghost"
/// default room
#define ROOM_GALACTIC_COMMON "room_common"
/// lavaland mobs and ashwalkers
#define ROOM_LAVALAND "room_lavaland"
/// monkeys and gorillaz
#define ROOM_MONKEY "room_monkey"
/// slimes and lightgues, doenst work for slime people yet.
#define ROOM_SLIME "room_slime "
/// for spiders but not fly people as they speak common
#define ROOM_SPIDER "room_spider"
/// for swarmers
#define ROOM_SWARMER "room_swarmer"
/// for aliens but not abductors
#define ROOM_XENO "room_xeno"

/// prevent mob from connecting to voice chat'
#define ROOM_NONE "room_none"
/// crash or warn if voicechat mob is in this room
#define ROOM_INVALID "room_invalid"


GLOBAL_LIST_INIT(rooms_proximity, list(
	ROOM_DRONE,
	ROOM_GHOST,
	ROOM_GALACTIC_COMMON,
	ROOM_LAVALAND,
	ROOM_MONKEY,
	ROOM_SLIME,
	ROOM_SPIDER,
	ROOM_SWARMER,
	ROOM_XENO,
	))

#define ROOM_GLOBAL_ABDUCTOR "room_abductor"
#define ROOM_GLOBAL_LOBBY "room_lobby"

GLOBAL_LIST_INIT(rooms_global, list(
	ROOM_GLOBAL_ABDUCTOR,
	ROOM_GLOBAL_LOBBY,
	))
