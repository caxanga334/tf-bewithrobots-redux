#if defined _bwrredux_api_included_
  #endinput
#endif
#define _bwrredux_api_included_

#define BWRR_SUBPLUGIN_INVALID_ID -1 // Invalid Sub Plugin ID

enum
{
	BWRR_RobotType_Invalid = -1, // Invalid/Unknown
	BWRR_RobotType_Normal = 0, // Normal robot
	BWRR_RobotType_Giant, // Giant robot
	BWRR_RobotType_Boss, // Boss Robot
	BWRR_RobotType_Buster // Sentry Buster
};

enum
{
	BWRR_Role_Generic = 0, // Generic role
	BWRR_Role_BombCarrier, // Robot designed for carrying the bomb
	BWRR_Role_Attack, // Generic attack robot
	BWRR_Role_Support, // Generic support robot
	BWRR_Role_AttackSupport, // Generic attack robot with minor support role
	BWRR_Role_Healer, // Robot designed for healing other robots
	BWRR_Role_Engineer, // Generic engineer role
	BWRR_Role_Sniper, // Generic sniper role
	BWRR_Role_Spy // Generic spy role
};

/**
 * Register a Robot list sub plugin.
 *
 * @param name			The plugin name to be stored
 * @return				The plugin ID used to identify it (STORE THIS)
 * @error				Plugin already registered
 */
native int BWRR_RegisterRobotPlugin(char[] name);

/**
 * Register a Robot list sub plugin.
 *
 * @param pluginID			The plugin ID
 * @param class				The robot class
 * @param cost				The robot resource cost
 * @param index				The robot index (subplugin)
 * @param type				The robot type
 * @param supply			The maximum number of times this robot will spawn per wave (<= 0 = infinite)
 * @param role				The robot role
 * @param percent			How many waves (as a percentage, range 0 to 1) must be completed to enable this robot
 */
native void BWRR_RegisterRobotTemplate(int pluginID, TFClassType class, int cost, int index, int type, int supply, int role, float percent);

/**
 * Changes the client team
 *
 * @param client			The client to change team
 * @param team				The client's new team
 */
native void BWRR_ChangeClientTeam(int client, TFTeam team);

/**
 * Checks if a client is playing as a robot
 * 
 * @param client     The client index
 * @return           TRUE if the client is a robot
 */
native bool BWRR_IsClientRobot(int client);

/**
 * Called when a client requests to join robot team.
 *
 * @param client		The client index who requested
 * @return              Plugin_Handled or Plugin_Stop to prevent joining
 */
forward Action BWRR_OnClientJoinRobots(int client);

/**
 * Called when a client playing on BLU team dies.
 *
 * @param client		The client index who died
 * @param pluginID		The The plugin ID responside for the client current robot
 * @param class			The client class
 * @param index			The robot internal index
 * @param type			The robot type
 */
forward void BWRR_OnRobotDeath(int client, const int pluginID, TFClassType class, int index, int type);

/**
 * Called after a client finished spawning on BLU team.
 *
 * @param client		The client index who spawned
 * @param pluginID		The The plugin ID responside for the client current robot
 * @param class			The client class
 * @param index			The robot internal index
 * @param type			The robot type
 */
forward void BWRR_OnRobotSpawn(int client, const int pluginID, TFClassType class, int index, int type);

/**
 * Called when requesting an inventory for a client.
 * Use this to give weapons to players.
 *
 * @param client		The client index
 * @param pluginID		The The plugin ID responside for the client current robot
 * @param class			The client class
 * @param index			The robot internal index
 * @param type			The robot type
 */
forward void BWRR_OnInventoryRequest(int client, const int pluginID, TFClassType class, int index, int type);

/**
 * Called when applying a model to a robot client.
 *
 * @param client		The client index
 * @param pluginID		The The plugin ID responside for the client current robot
 * @param class			The client class
 * @param index			The robot internal index
 * @param type			The robot type
 * @param model			The model to use
 * @return				Return Plugin_Changed to change models or Plugin_Handled|Plugin_Stop to NOT apply any model.
 */
forward Action BWRR_OnApplyModel(int client, const int pluginID, TFClassType class, int index, int type, char[] model);

/**
 * Called when setting the model scale on a client.
 *
 * @param client		The client index
 * @param pluginID		The The plugin ID responside for the client current robot
 * @param class			The client class
 * @param index			The robot internal index
 * @param type			The robot type
 * @param scale			The robot scale
 * @return				Return Plugin_Changed to override the scale.
 */
forward Action BWRR_OnApplyScale(int client, const int pluginID, TFClassType class, int index, int type, float &scale);

/**
 * Called when applying a loop sound on a client
 *
 * @param client		The client index
 * @param pluginID		The The plugin ID responside for the client current robot
 * @param class			The client class
 * @param index			The robot internal index
 * @param type			The robot type
 * @param sound         The sound path
 * @param level         The sound level
 * @return				Return Plugin_Changed to override the scale.
 */
 forward Action BWRR_OnApplyLoopSound(int client, const int pluginID, TFClassType class, int index, int type, char[] sound, int &level);

/**
 * Called when giving a flag (bomb) to the player.
 * Returning Plugin_Handled or Plugin_Stop will prevent giving the flag.
 *
 * @param client		The client index
 * @param pluginID		The The plugin ID responside for the client current robot
 * @param class			The client class
 * @param index			The robot internal index
 * @param type			The robot type
 */
forward Action BWRR_OnGiveFlag(int client, const int pluginID, TFClassType class, int index, int type);

/**
 * Called when a client enters the spawnroom
 *
 * @param client		The client index
 * @param pluginID		The The plugin ID responside for the client current robot
 * @param class			The client class
 * @param index			The robot internal index
 * @param type			The robot type
 */
forward void BWRR_OnEnterSpawn(int client, const int pluginID, TFClassType class, int index, int type);

/**
 * Called when a client leaves the spawnroom
 *
 * @param client		The client index
 * @param pluginID		The The plugin ID responside for the client current robot
 * @param class			The client class
 * @param index			The robot internal index
 * @param type			The robot type
 */
forward void BWRR_OnLeaveSpawn(int client, const int pluginID, TFClassType class, int index, int type);

/**
 * Called when a bomb is upgraded for a client
 * 
 * @param client         	The client index
 * @param pluginID			The The plugin ID responside for the client current robot
 * @param class          	The client class
 * @param index          	The robot internal index
 * @param type           	The robot type
 * @param level          	The new bomb level
 */
forward void BWRR_OnBombUpgrade(int client, const int pluginID, TFClassType class, int index, int type, int level);

/**
 * Called when teleporting a robot client to a spawn point
 * 
 * @param client         The client index
 * @param pluginID       The The plugin ID responside for the client current robot
 * @param class          The client class
 * @param index          The robot internal index
 * @param type           The robot type
 * @param targetname     The spawn point targetname
 * @param origin         The origin vector of where the client will be teleported
 * @param angles         The angle vector of where the client will be teleported
 * @return               Plugin_Changed to change the spawn point origin and angle, Plugin_Handled or Plugin_Stop to cancel the teleportation
 */
forward Action BWRR_OnSetSpawnPoint(int client, const int pluginID, TFClassType class, int index, int type, const char[] targetname, float origin[3], float angles[3]);

/**
 * Called when teleporting an engineer or spy robot
 * 
 * @param client       The client index
 * @param pluginID     The The plugin ID responside for the client current robot
 * @param class        The client class
 * @param index        The robot internal index
 * @param type         The robot type
 * @param origin       The position where the client will be teleported
 * @param angles       The new client angles
 * @return             Return Plugin_Handled or Plugin_Stop to block the teleportation. Plugin_Changed to change origin and/or angles
 */
forward Action BWRR_OnTeleport(int client, const int pluginID, TFClassType class, int index, int type, float origin[3], float angles[3]);

public SharedPlugin __pl_tf_bwr_redux =
{
	name = "tf_bwr_redux",
	file = "tf_bwr_redux.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN

public __pl_tf_bwr_redux_SetNTVOptional()
{
	MarkNativeAsOptional("BWRR_RegisterRobotPlugin");
	MarkNativeAsOptional("BWRR_RegisterRobotTemplate");
	MarkNativeAsOptional("BWRR_ChangeClientTeam");
	MarkNativeAsOptional("BWRR_IsClientRobot");
}