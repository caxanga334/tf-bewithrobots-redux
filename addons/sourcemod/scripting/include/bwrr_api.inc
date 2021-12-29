#if defined _bwrredux_api_included_
  #endinput
#endif
#define _bwrredux_api_included_

enum
{
	BWRR_RobotType_Invalid = -1, // Invalid/Unknown
	BWRR_RobotType_Normal = 0, // Normal robot
	BWRR_RobotType_Giant, // Giant robot
	BWRR_RobotType_Boss, // Boss Robot
	BWRR_RobotType_Buster // Sentry Buster
}

/**
 * Register a Robot list sub plugin.
 *
 * @param name			The plugin name to be stored (important)
 */
native void BWRR_RegisterRobotPlugin(char[] name);

/**
 * Register a Robot list sub plugin.
 *
 * @param pluginname		The plugin name to be stored (important)
 * @param class				The robot class
 * @param cost				The robot resource cost
 * @param index				The robot index (subplugin)
 * @param type				The robot type
 * @param supply			The maximum number of times this robot will spawn per wave (<= 0 = infinite)
 * @param percent			How many waves (as a percentage, range 0 to 1) must be completed to enable this robot
 */
native void BWRR_RegisterRobotTemplate(char[] pluginname, TFClassType class, int cost, int index, int type, int supply, float percent);

/**
 * Changes the client team
 *
 * @param client			The client to change team
 * @param team				The client's new team
 */
native void BWRR_ChangeClientTeam(int client, TFTeam team);

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
 * @param pluginname	The name of the plugin responside for the client current robot
 * @param class			The client class
 * @param index			The robot internal index
 * @param type			The robot type
 */
forward void BWRR_OnRobotDeath(int client, const char[] pluginname, TFClassType class, int index, int type);

/**
 * Called after a client finished spawning on BLU team.
 *
 * @param client		The client index who spawned
 * @param pluginname	The name of the plugin responside for the client current robot
 * @param class			The client class
 * @param index			The robot internal index
 * @param type			The robot type
 */
forward void BWRR_OnRobotSpawn(int client, const char[] pluginname, TFClassType class, int index, int type);

/**
 * Called when requesting an inventory for a client.
 * Use this to give weapons to players.
 *
 * @param client		The client index
 * @param pluginname	The name of the plugin responside for the client current robot
 * @param class			The client class
 * @param index			The robot internal index
 * @param type			The robot type
 */
forward void BWRR_OnInventoryRequest(int client, const char[] pluginname, TFClassType class, int index, int type);

/**
 * Called when applying a model to a robot client.
 *
 * @param client		The client index
 * @param pluginname	The name of the plugin responside for the client current robot
 * @param class			The client class
 * @param index			The robot internal index
 * @param type			The robot type
 * @param model			The model to use
 * @return				Return Plugin_Changed to change models or Plugin_Handled|Plugin_Stop to NOT apply any model.
 */
forward Action BWRR_OnApplyModel(int client, const char[] pluginname, TFClassType class, int index, int type, char[] model);

/**
 * Called when setting the model scale on a client.
 *
 * @param client		The client index
 * @param pluginname	The name of the plugin responside for the client current robot
 * @param class			The client class
 * @param index			The robot internal index
 * @param type			The robot type
 * @param scale		The robot scale
 * @return				Return Plugin_Changed to override the scale.
 */
forward Action BWRR_OnApplyScale(int client, const char[] pluginname, TFClassType class, int index, int type, float &scale);

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
	MarkNativeAsOptional("BWRR_RegisterRobotTemplat");
}