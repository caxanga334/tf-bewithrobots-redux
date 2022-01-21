// API

GlobalForward g_OnJoinRobotForward;
GlobalForward g_OnRobotDeath;
GlobalForward g_OnRobotSpawn;
GlobalForward g_OnInventoryRequest;
GlobalForward g_OnApplyModel;
GlobalForward g_OnApplyScale;
GlobalForward g_OnApplyLoopSound;
GlobalForward g_OnGiveFlag;
GlobalForward g_OnEnterSpawn;
GlobalForward g_OnLeaveSpawn;
GlobalForward g_OnBombUpgrade;
GlobalForward g_OnSetSpawnPoint;
GlobalForward g_OnTeleport;
GlobalForward g_OnGetRobotName;
GlobalForward g_FilterGateBot;
GlobalForward g_OnSentryBusterBeginToDetonate;
GlobalForward g_OnSentryBusterDetonate;
GlobalForward g_OnObjectSpawn;

void SetupForwards()
{
	g_OnJoinRobotForward = new GlobalForward("BWRR_OnClientJoinRobots", ET_Event, Param_Cell);
	g_OnRobotDeath = new GlobalForward("BWRR_OnRobotDeath", ET_Ignore, Param_Cell, Param_Cell, Param_Any, Param_Cell, Param_Cell);
	g_OnRobotSpawn = new GlobalForward("BWRR_OnRobotSpawn", ET_Ignore, Param_Cell, Param_Cell, Param_Any, Param_Cell, Param_Cell);
	g_OnInventoryRequest = new GlobalForward("BWRR_OnInventoryRequest", ET_Ignore, Param_Cell, Param_Cell, Param_Any, Param_Cell, Param_Cell);
	g_OnApplyModel = new GlobalForward("BWRR_OnApplyModel", ET_Event, Param_Cell, Param_Cell, Param_Any, Param_Cell, Param_Cell, Param_String);
	g_OnApplyScale = new GlobalForward("BWRR_OnApplyScale", ET_Event, Param_Cell, Param_Cell, Param_Any, Param_Cell, Param_Cell, Param_FloatByRef);
	g_OnApplyLoopSound = new GlobalForward("BWRR_OnApplyLoopSound", ET_Event, Param_Cell, Param_Cell, Param_Any, Param_Cell, Param_Cell, Param_String, Param_CellByRef);
	g_OnGiveFlag = new GlobalForward("BWRR_OnGiveFlag", ET_Event, Param_Cell, Param_Cell, Param_Any, Param_Cell, Param_Cell);
	g_OnEnterSpawn = new GlobalForward("BWRR_OnEnterSpawn", ET_Ignore, Param_Cell, Param_Cell, Param_Any, Param_Cell, Param_Cell);
	g_OnLeaveSpawn = new GlobalForward("BWRR_OnLeaveSpawn", ET_Ignore, Param_Cell, Param_Cell, Param_Any, Param_Cell, Param_Cell);
	g_OnBombUpgrade = new GlobalForward("BWRR_OnBombUpgrade", ET_Ignore, Param_Cell, Param_Cell, Param_Any, Param_Cell, Param_Cell, Param_Cell);
	g_OnSetSpawnPoint = new GlobalForward("BWRR_OnSetSpawnPoint", ET_Event, Param_Cell, Param_Cell, Param_Any, Param_Cell, Param_Cell, Param_String, Param_Array, Param_Array);
	g_OnTeleport = new GlobalForward("BWRR_OnTeleport", ET_Event, Param_Cell, Param_Cell, Param_Any, Param_Cell, Param_Cell, Param_Array, Param_Array);
	g_OnGetRobotName = new GlobalForward("BWRR_OnGetRobotName", ET_Event, Param_Cell, Param_Cell, Param_Any, Param_Cell, Param_Cell, Param_String, Param_Cell);
	g_FilterGateBot = new GlobalForward("BWRR_FilterGatebot", ET_Event, Param_Cell, Param_Any, Param_Cell, Param_Cell);
	g_OnSentryBusterBeginToDetonate = new GlobalForward("BWRR_OnSentryBusterBeginToDetonate", ET_Event, Param_Cell, Param_Cell, Param_Any, Param_Cell, Param_Cell, Param_FloatByRef);
	g_OnSentryBusterDetonate = new GlobalForward("BWRR_OnSentryBusterDetonate", ET_Event, Param_Cell, Param_Cell, Param_Any, Param_Cell, Param_Cell, Param_FloatByRef);
	g_OnObjectSpawn = new GlobalForward("BWRR_OnObjectSpawn", ET_Event, Param_Cell, Param_Cell, Param_Any, Param_Cell, Param_Cell, Param_Cell, Param_Any);
}

void SetupNatives()
{
	CreateNative("BWRR_RegisterRobotPlugin", Native_RegisterRobotPlugin);
	CreateNative("BWRR_RegisterRobotTemplate", Native_RegisterRobotTemplate);
	CreateNative("BWRR_ChangeClientTeam", Native_ChangeClientTeam);
	CreateNative("BWRR_IsClientRobot", Native_IsRobot);
}

public any Native_RegisterRobotPlugin(Handle plugin, int numParams)
{
	char pluginname[64];
	GetNativeString(1, pluginname, sizeof(pluginname));

	if(g_subplugins_robots.FindString(pluginname) != -1)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Plugin \"%s\" is already registered!", pluginname);
		return -1;
	}

	int index = g_subplugins_robots.PushString(pluginname);
	g_subplugins_ID[index] = index; // Sequential ID

	LogMessage("[BWRR] Successfully registered sub plugin \"%s\" ID = %i", pluginname, g_subplugins_ID[index]);

	return g_subplugins_ID[index];
}

public any Native_RegisterRobotTemplate(Handle plugin, int numParams)
{
	RegisterRobotTemplate(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3), GetNativeCell(4), GetNativeCell(5), GetNativeCell(6), GetNativeCell(7), GetNativeCell(8));
	return 0;
}

public any Native_ChangeClientTeam(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	TFTeam team = GetNativeCell(2);

	TF2BWR_ChangeClientTeam(client, team);
	return 0;
}

public any Native_IsRobot(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	RobotPlayer rp = RobotPlayer(client);

	return rp.isrobot;
}