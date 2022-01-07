// AI Director

enum struct edirector
{
	int resources; // how many resources the director has
	Handle timer; // Think timer
}
edirector g_eDirector;

// Add resources to the director resource pool
void Director_AddResources(int amount)
{
	g_eDirector.resources += amount;
}

/**
 * Sets how many resources the AI director has
 *
 * @param amount		Amount of resources to set
 */
void Director_SetResources(int amount)
{
	g_eDirector.resources = amount;
}

/**
 * Gets the number of players on the BLU team queue
 * They may be on BLU or spectator.
 *
 * @return          Number of players
 */
int Director_GetNumberofBLUPlayers()
{
	int count = 0;

	for(int i = 1;i < MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;

		if(TF2_GetClientTeam(i) == TFTeam_Red)
			continue;

		RobotPlayer rp = RobotPlayer(i);

		if(rp.isrobot)
			count++;
	}

	return count;
}

/**
 * Gets a random player sitting in the queue waiting to be spawned
 *
 * @return          Client index
 */
int Director_GetRandomPlayerInQueue()
{
	int count = 0;
	int[] players = new int[MaxClients+1];

	for(int i = 1;i < MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;

		if(TF2_GetClientTeam(i) == TFTeam_Red)
			continue;

		RobotPlayer rp = RobotPlayer(i);

		if(rp.isrobot && TF2_GetClientTeam(i) == TFTeam_Spectator)
		{
			players[count] = i;
			count++;
		}
	}

	if(count > 0)
	{
		return players[Math_GetRandomInt(0, count-1)];
	}
	else
	{
		return 0;
	}
}

// Adds a client to the BLU spawn queue
void Director_AddClientToQueue(int client)
{
	RobotPlayer rp = RobotPlayer(client);
	rp.isrobot = true;
	TF2MvM_ChangeClientTeam(client, TFTeam_Spectator);
	PrintToChat(client, "%t", "Director_Added");
}

// Resets client data and places them in the spectator team
void Director_RemoveClientFromBLU(int client)
{
	RobotPlayer rp = RobotPlayer(client);
	rp.OnDeathReset();
	TF2MvM_ChangeClientTeam(client, TFTeam_Spectator);	
}

// Removes a client from the BLU team and moves them to RED team.
void Director_MoveClientToRED(int client)
{
	TF2BWR_ChangeClientTeam(client, TFTeam_Red);
}

// Spawns a player that is sitting in spectator in BLU team
void Director_SpawnPlayer(int client)
{
	RobotPlayer rp = RobotPlayer(client);

	rp.lastspawntime = GetGameTime();

	TF2MvM_ChangeClientTeam(client, TFTeam_Blue);
	RequestFrame(DirectorFrame_SelectRobot, GetClientSerial(client));
}

// Director think function
public Action Director_Think(Handle timer)
{
	Director_AddResources(c_director_rpt.IntValue);
	PrintToConsoleAll("Director Think: %i", GetGameTickCount());

	int randomplayer = Director_GetRandomPlayerInQueue();

	if(randomplayer)
	{
		PrintToChatAll("[AI Director] Spawning player %N", randomplayer);
		Director_SpawnPlayer(randomplayer);
	}

	return Plugin_Continue;
}

void Director_OnWaveStart()
{
	Director_SetResources(1000); // To-do: Add cvar

	if(g_eDirector.timer == null)
	{
		g_eDirector.timer = CreateTimer(1.0, Director_Think, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

void Director_OnWaveEnd()
{
	delete g_eDirector.timer;
}

void Director_OnWaveFailed()
{
	delete g_eDirector.timer;
	RequestFrame(DirectorFrame_ClearPlayers);
}

void Director_TeleportPlayer(int client)
{
	ArrayList spawns = new ArrayList();
	CollectValidSpawnPoints(client, spawns);
	float destination[3], angles[3];

	if(spawns.Length == 0)
	{
		delete spawns;
		ThrowError("[AI Director] No valid spawn found!");
	}

	int entity = spawns.Get(Math_GetRandomInt(0, spawns.Length - 1));
	delete spawns;
	char targetname[64];
	GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", destination);
	GetEntPropVector(entity, Prop_Send, "m_angRotation", angles);

	RobotPlayer rp = RobotPlayer(client);
	Action result;
	Call_StartForward(g_OnSetSpawnPoint);
	Call_PushCell(client);
	Call_PushCell(g_eTemplates[rp.templateindex].pluginID);
	Call_PushCell(TF2_GetPlayerClass(client));
	Call_PushCell(g_eTemplates[rp.templateindex].index);
	Call_PushCell(g_eTemplates[rp.templateindex].type);
	Call_PushString(targetname);
	Call_PushArrayEx(destination, sizeof(destination), SM_PARAM_COPYBACK);
	Call_PushArrayEx(angles, sizeof(angles), SM_PARAM_COPYBACK);
	Call_Finish(result);

	if(result == Plugin_Continue || result == Plugin_Changed)
	{
		TeleportEntity(client, destination, angles, NULL_VECTOR);
	}
}

bool Director_TeleportSpy(int client, int target, float pos[3])
{
	float target_pos[3];
	GetClientAbsOrigin(target, target_pos);

	ArrayList areas = new ArrayList();
	CollectNavAreas(areas, target_pos, c_spman_spy_maxdist.FloatValue, 300.0, 450.0);
	FilterNavAreasByTrace(areas, client);
	FilterNavAreasByLOS(areas, TFTeam_Red);

	if(areas.Length == 0)
	{
		delete areas;
		return false;
	}

	CNavArea final = TheNavMesh.GetNavAreaByID(areas.Get(Math_GetRandomInt(0, areas.Length - 1)));
	delete areas;

	ArrayList spots = new ArrayList();
	if(final.GetHidingSpots(spots) > 0)
	{
		HidingSpot hs = spots.Get(Math_GetRandomInt(0, spots.Length - 1));
		if(hs != NULL_HIDING_SPOT)
		{
			hs.GetPosition(pos);
			pos[2] += 8.0;

			if(IsSafeAreaToTeleport(client, pos))
			{
				delete spots;
				return true;
			}
		}
	}

	final.GetCenter(pos);
	pos[2] += 15.0;

	delete spots;
	return true;
}

void Director_OnPlayerDeath(int victim, int killer)
{
	if(!IsValidClient(victim))
		return;
	
	RobotPlayer rp1 = RobotPlayer(victim);

	TFTeam team1 = TF2_GetClientTeam(victim);
	if(team1 == TFTeam_Blue && !IsFakeClient(victim)) // human BLU was killed
	{
		if(rp1.templateindex >= 0) // template index will be -1 for 'Own Loadout' robots
		{
			Call_StartForward(g_OnRobotDeath);
			Call_PushCell(victim);
			Call_PushCell(g_eTemplates[rp1.templateindex].pluginID);
			Call_PushCell(TF2_GetPlayerClass(victim));
			Call_PushCell(g_eTemplates[rp1.templateindex].index);
			Call_PushCell(g_eTemplates[rp1.templateindex].type);
			Call_Finish();
		}

		RequestFrame(DirectorFrame_OnRobotDeath, GetClientSerial(victim));
	}

	if(!IsValidClient(killer))
		return;
	
	TFTeam team2 = TF2_GetClientTeam(killer);

	// BLU player killed a RED player
	if(team1 == TFTeam_Red && team2 == TFTeam_Blue)
	{
		Director_AddResources(-500); // Subtract resources from the director
	}
}

// Called 1 frame later after a human BLU player is killed
void DirectorFrame_OnRobotDeath(int serial)
{
	int client =  GetClientFromSerial(serial);

	if(client)
	{
		Director_RemoveClientFromBLU(client);
	}
}

// Called to select a robot for the player
void DirectorFrame_SelectRobot(int serial)
{
	int client = GetClientFromSerial(serial);
	int robots = Robots_GetMax();
	int template = -1;

	if(robots >= 0)
	{
		template = Math_GetRandomInt(0, robots); // temp selection for testing
	}

	if(client)
	{
		RobotPlayer rp = RobotPlayer(client);
		rp.SetRobot(g_eTemplates[template].type, template);
		RequestFrame(DirectorFrame_PreSpawn, serial);
	}
}

// Called by DirectorFrame_SelectRobot
void DirectorFrame_PreSpawn(int serial)
{
	int client = GetClientFromSerial(serial);

	if(client)
	{
		RobotPlayer rp = RobotPlayer(client);
		TF2_SetPlayerClass(client, Robots_GetClass(rp.templateindex), _, true);
		TF2_RespawnPlayer(client);
	}
}

// Called when the player spawn event is fired
void DirectorFrame_PostSpawn(int serial)
{
	int client = GetClientFromSerial(serial);

	if(client && TF2_GetClientTeam(client) == TFTeam_Blue)
	{
		RobotPlayer rp = RobotPlayer(client);

		if(rp.templateindex >= 0)
		{
			Call_StartForward(g_OnRobotSpawn);
			Call_PushCell(client);
			Call_PushCell(g_eTemplates[rp.templateindex].pluginID);
			Call_PushCell(TF2_GetPlayerClass(client));
			Call_PushCell(g_eTemplates[rp.templateindex].index);
			Call_PushCell(g_eTemplates[rp.templateindex].type);
			Call_Finish();
		}

		Robots_SetModel(client, TF2_GetPlayerClass(client));
		Robots_SetScale(client, Robots_GetScaleSize(client));
		RequestFrame(DirectorFrame_PreTeleport, serial);
	}
}

// Called after post_inventory_application event
void DirectorFrame_ApplyInventory(int serial)
{
	int client = GetClientFromSerial(serial);

	if(client && TF2_GetClientTeam(client) == TFTeam_Blue)
	{
		RobotPlayer rp = RobotPlayer(client);
		if(rp.templateindex >= 0)
		{
			TF2_ClearClient(client, true, true); // Clear player first
		}
		else
		{
			TF2_ClearClient(client, false, true); // Own loadout
		}

		RequestFrame(DirectorFrame_RequestInventory, serial);
	}	
}

// Requests the inventory from sub plugins
void DirectorFrame_RequestInventory(int serial)
{
	int client = GetClientFromSerial(serial);
	RobotPlayer rp = RobotPlayer(client);

	if(client)
	{
		if(rp.templateindex >= 0)
		{
			// Request inventory via API
			Call_StartForward(g_OnInventoryRequest);
			Call_PushCell(client);
			Call_PushCell(g_eTemplates[rp.templateindex].pluginID);
			Call_PushCell(TF2_GetPlayerClass(client));
			Call_PushCell(g_eTemplates[rp.templateindex].index);
			Call_PushCell(g_eTemplates[rp.templateindex].type);
			Call_Finish();
		}		
	}
}

// Used to move players to RED team
void DirectorFrame_ClearPlayers()
{
	for(int i = 1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;

		if(IsFakeClient(i) || IsClientSourceTV(i) || IsClientReplay(i))
			continue;

		RobotPlayer rp = RobotPlayer(i);

		if(rp.isrobot)
		{
			Director_MoveClientToRED(i);
		}
	}
}

// Called after DirectorFrame_PostSpawn. Teleports client into a proper spawn.
void DirectorFrame_PreTeleport(int serial)
{
	int client = GetClientFromSerial(serial);

	if(client)
	{
		Director_TeleportPlayer(client);
		RequestFrame(DirectorFrame_GiveBomb, serial);		
	}
}

// Called by DirectorFrame_PreTeleport. Gives the player the bomb
void DirectorFrame_GiveBomb(int serial)
{
	int client = GetClientFromSerial(serial);

	if(client)
	{
		int flag = TF2_GetRandomFlagAtHome(view_as<int>(TFTeam_Blue));
		Address attribute = TF2Attrib_GetByName(client, "cannot pick up intelligence");
		RobotPlayer rp = RobotPlayer(client);

		if(flag != INVALID_ENT_REFERENCE && attribute == Address_Null && rp.templateindex >= 0)
		{
			Action result;
			Call_StartForward(g_OnGiveFlag);
			Call_PushCell(client);
			Call_PushCell(g_eTemplates[rp.templateindex].pluginID);
			Call_PushCell(TF2_GetPlayerClass(client));
			Call_PushCell(g_eTemplates[rp.templateindex].index);
			Call_PushCell(g_eTemplates[rp.templateindex].type);
			Call_Finish(result);

			if(result == Plugin_Continue)
			{
				TF2_PickUpFlag(client, flag);
				RequestFrame(Frame_UpdateBombHUD, GetClientSerial(client));
			}
		}

		switch(TF2_GetPlayerClass(client))
		{
			case TFClass_Engineer: RequestFrame(DirectorFrame_TeleportEngineer, serial);
			case TFClass_Spy: RequestFrame(DirectorFrame_TeleportSpy, serial);
		}
	}
}

// Called by DirectorFrame_GiveBomb, teleports engineer robots
void DirectorFrame_TeleportEngineer(int serial)
{
	int client = GetClientFromSerial(serial);

	if(client)
	{
		RobotPlayer rp = RobotPlayer(client);
		ArrayList hints = new ArrayList();
		CollectEngineerHints(client, hints);

		if(hints.Length > 0)
		{
			int hint = hints.Get(Math_GetRandomInt(0, hints.Length - 1));

			float origin[3], angles[3];
			GetEntPropVector(hint, Prop_Send, "m_vecOrigin", origin);
			GetEntPropVector(hint, Prop_Send, "m_angRotation", angles);

			Action result;
			Call_StartForward(g_OnTeleport);
			Call_PushCell(client);
			Call_PushCell(g_eTemplates[rp.templateindex].pluginID);
			Call_PushCell(TF2_GetPlayerClass(client));
			Call_PushCell(g_eTemplates[rp.templateindex].index);
			Call_PushCell(g_eTemplates[rp.templateindex].type);
			Call_PushArrayEx(origin, sizeof(origin), SM_PARAM_COPYBACK);
			Call_PushArrayEx(angles, sizeof(angles), SM_PARAM_COPYBACK);
			Call_Finish(result);

			if(result == Plugin_Continue || result == Plugin_Changed)
			{
				TeleportEntity(client, origin, angles, {0.0, 0.0, 0.0});
			}
		}
		else
		{
			int target = GetRandomClientFromTeam(view_as<int>(TFTeam_Blue), true, true);
			
			if(target)
			{
				float origin[3], angles[3];
				GetClientAbsOrigin(target, origin);
				GetClientAbsAngles(target, angles);

				if(IsSafeAreaToTeleport(client, origin))
				{
					Action result;
					Call_StartForward(g_OnTeleport);
					Call_PushCell(client);
					Call_PushCell(g_eTemplates[rp.templateindex].pluginID);
					Call_PushCell(TF2_GetPlayerClass(client));
					Call_PushCell(g_eTemplates[rp.templateindex].index);
					Call_PushCell(g_eTemplates[rp.templateindex].type);
					Call_PushArrayEx(origin, sizeof(origin), SM_PARAM_COPYBACK);
					Call_PushArrayEx(angles, sizeof(angles), SM_PARAM_COPYBACK);
					Call_Finish(result);
		
					if(result == Plugin_Continue || result == Plugin_Changed)
					{
						TeleportEntity(client, origin, angles, {0.0, 0.0, 0.0});
						rp.inspawn = false;
					}					
				}
			}
		}

		delete hints;
	}
}

// Called by DirectorFrame_GiveBomb, teleports spy robots
void DirectorFrame_TeleportSpy(int serial)
{
	int client = GetClientFromSerial(serial);

	if(client)
	{
		RobotPlayer rp = RobotPlayer(client);
		int target = GetRandomClientFromTeam(view_as<int>(TFTeam_Red), true, true, false);

		if(target)
		{
			float pos[3], angles[3] = {0.0, ...};
			if(Director_TeleportSpy(client, target, pos))
			{
				Action result;
				Call_StartForward(g_OnTeleport);
				Call_PushCell(client);
				Call_PushCell(g_eTemplates[rp.templateindex].pluginID);
				Call_PushCell(TF2_GetPlayerClass(client));
				Call_PushCell(g_eTemplates[rp.templateindex].index);
				Call_PushCell(g_eTemplates[rp.templateindex].type);
				Call_PushArrayEx(pos, sizeof(pos), SM_PARAM_COPYBACK);
				Call_PushArrayEx(angles, sizeof(angles), SM_PARAM_COPYBACK);
				Call_Finish(result);
	
				if(result == Plugin_Continue || result == Plugin_Changed)
				{
					TeleportEntity(client, pos, angles, {0.0, 0.0, 0.0});
					rp.inspawn = false;
				}					
			}
		}
	}
}