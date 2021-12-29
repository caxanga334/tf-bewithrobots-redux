// API

GlobalForward g_OnJoinRobotForward;
GlobalForward g_OnRobotDeath;
GlobalForward g_OnRobotSpawn;
GlobalForward g_OnInventoryRequest;
GlobalForward g_OnApplyModel;
GlobalForward g_OnApplyScale;

void SetupForwards()
{
	g_OnJoinRobotForward = new GlobalForward("BWRR_OnClientJoinRobots", ET_Event, Param_Cell);
	g_OnRobotDeath = new GlobalForward("BWRR_OnRobotDeath", ET_Ignore, Param_Cell, Param_String, Param_Any, Param_Cell, Param_Cell);
	g_OnRobotSpawn = new GlobalForward("BWRR_OnRobotSpawn", ET_Ignore, Param_Cell, Param_String, Param_Any, Param_Cell, Param_Cell);
	g_OnInventoryRequest = new GlobalForward("BWRR_OnInventoryRequest", ET_Ignore, Param_Cell, Param_String, Param_Any, Param_Cell, Param_Cell);
	g_OnApplyModel = new GlobalForward("BWRR_OnApplyModel", ET_Event, Param_Cell, Param_String, Param_Any, Param_Cell, Param_Cell, Param_String);
	g_OnApplyScale = new GlobalForward("BWRR_OnApplyScale", ET_Event, Param_Cell, Param_String, Param_Any, Param_Cell, Param_Cell, Param_FloatByRef);
}

void SetupNatives()
{
	CreateNative("BWRR_RegisterRobotPlugin", Native_RegisterRobotPlugin);
	CreateNative("BWRR_RegisterRobotTemplate", Native_RegisterRobotTemplate);
	CreateNative("BWRR_ChangeClientTeam", Native_ChangeClientTeam);
}

public any Native_RegisterRobotPlugin(Handle plugin, int numParams)
{
	char pluginname[64];
	GetNativeString(1, pluginname, sizeof(pluginname));

	if(g_subplugins_robots.FindString(pluginname) != -1)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Plugin \"%s\" is already registered!", pluginname);
		return;
	}

	g_subplugins_robots.PushString(pluginname);
	return;
}

public any Native_RegisterRobotTemplate(Handle plugin, int numParams)
{
	char pluginname[64];
	GetNativeString(1, pluginname, sizeof(pluginname));

	RegisterRobotTemplate(pluginname, GetNativeCell(2), GetNativeCell(3), GetNativeCell(4), GetNativeCell(5), GetNativeCell(6), GetNativeCell(7));
}

public any Native_ChangeClientTeam(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	TFTeam team = GetNativeCell(2);

	TF2BWR_ChangeClientTeam(client, team);
}