// Console commands

void SetupPluginCommands()
{
	RegAdminCmd("sm_joinred", Cmd_JoinDefenders, 0, "Joins the queue to the RED/Defenders team.");
	RegAdminCmd("sm_joinblue", Cmd_JoinRobots, 0, "Joins the queue to the BLU/Robot team.");
	RegAdminCmd("sm_joinblu", Cmd_JoinRobots, 0, "Joins the queue to the BLU/Robot team.");
	RegAdminCmd("sm_bwr", Cmd_JoinRobots, 0, "Joins the queue to the BLU/Robot team.");
	RegAdminCmd("sm_bwrr", Cmd_JoinRobots, 0, "Joins the queue to the BLU/Robot team.");
	RegAdminCmd("sm_bwrr_debug_player", Cmd_DebugPlayer, ADMFLAG_ROOT, "Player debug command.");
}

void SetupCommandListeners()
{
	AddCommandListener(Listener_JoinTeam, "jointeam");
}

public Action Cmd_JoinDefenders(int client, int args)
{
	if(!client)
		return Plugin_Handled;

	BWRR_ChangeClientTeam(client, TFTeam_Red);
	return Plugin_Handled;
}

public Action Cmd_JoinRobots(int client, int args)
{
	if(!client)
		return Plugin_Handled;

	Action result;
	Call_StartForward(g_OnJoinRobotForward);
	Call_PushCell(client);
	Call_Finish(result);

	if(result >= Plugin_Handled) // Deny joining BLU via API
	{
		return Plugin_Handled;
	}

	RobotPlayer rp = RobotPlayer(client);

	if(rp.isrobot) // Client is already in BLU queue
	{
		ReplyToCommand(client, "%t", "Error_Already_BLU");
		return Plugin_Handled;
	}

	if(BWRR_GetNumberofBLUPlayers() >= c_maxblu.IntValue)
	{
		ReplyToCommand(client, "%t", "Error_BLU_Full");
		return Plugin_Handled;		
	}

	if(GetTeamClientCount(view_as<int>(TFTeam_Red)) < c_minred.IntValue)
	{
		ReplyToCommand(client ,"%t", "Error_MinRed");
		return Plugin_Handled;
	}

	BWRR_ChangeClientTeam(client, TFTeam_Blue);
	return Plugin_Handled;
}

public Action Cmd_DebugPlayer(int client, int args)
{
	if(!client)
		return Plugin_Handled;

	RobotPlayer rp = RobotPlayer(client);

	ReplyToCommand(client, "Robot: %i, Carrier: %i, Deploying: %i, Gatebot: %i", rp.isrobot, rp.carrier, rp.deploying, rp.gatebot);
	ReplyToCommand(client, "Template Index: %i, Type: %i, Bomb Level: %i", rp.templateindex, rp.type, rp.bomblevel);

	return Plugin_Handled;
}

public Action Listener_JoinTeam(int client, const char[] command, int argc)
{
	if(!IsValidClient(client)) {
		return Plugin_Handled;
	}
		
	if(IsFakeClient(client)) {
		return Plugin_Continue;
	}
		
	char strTeam[16];
	GetCmdArg(1, strTeam, sizeof(strTeam));
	if(strcmp(strTeam, "red", false ) == 0)
	{
		Cmd_JoinDefenders(client, 0);
		return Plugin_Handled;
	}
	else if(strcmp(strTeam, "blue", false ) == 0)
	{
		Cmd_JoinRobots(client, 0);
		return Plugin_Handled;
	}
	else if(strcmp(strTeam, "spectate", false) == 0 || strcmp(strTeam, "spectator", false) == 0)
	{
		BWRR_ChangeClientTeam(client, TFTeam_Spectator);
		return Plugin_Handled;
	}
	
	Cmd_JoinDefenders(client, 0); // Default to RED team.
	return Plugin_Handled;
}