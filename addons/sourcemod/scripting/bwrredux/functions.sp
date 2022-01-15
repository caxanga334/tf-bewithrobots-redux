// Extras functions

enum struct GateManager
{
	bool available;
	int numgates;
	int gates[6];
}

GateManager g_eGateManager;

/**
 * Returns either true or false based on random chance.
 *
 * @param chance        The chance to return true
 * @return				Boolean value
 */
stock bool Math_RandomChance(int chance)
{
	return Math_GetRandomInt(1, 100) <= chance;
}

/**
 * Gets a value based on the min, max range and the percentage
 * 
 * @param min         Minimum value
 * @param max         Maximum value
 * @param percent     Percentage value in range `0.0 - 1.0`
 * @param inverse     If inverse is `true` then the minimum value will be returned when the percentage is at 1.0
 * @return            Value at percentage
 */
float Math_Range(const float min, const float max, const float percent, bool inverse = false)
{
	if(inverse)
	{
		return ((min - max) * percent) + max;
	}

	return ((max - min) * percent) + min;
}

/**
 * Gets the angle towards the given target
 * 
 * @param source     Source position
 * @param target     Target position
 * @param angles     Angles vector
 */
void GetAngleTorwardsPoint(const float source[3], const float target[3], float angles[3])
{
	float vec[3];
	SubtractVectors(target, source, vec);
	NormalizeVector(vec, vec);
	GetVectorAngles(vec, angles);
}

// Checks if the client is a valid client index
bool IsValidClient(int client)
{
	if(client < 1 || client > MaxClients) { return false; }
	return IsClientInGame(client);
}

// Checks if the current gamemode is MvM
bool IsPlayingMannVsMachine()
{
	return !!GameRules_GetProp("m_bPlayingMannVsMachine");
}

// Checks if the wave is in progress
bool IsMvMWaveRunning()
{
	return GameRules_GetRoundState() == RoundState_RoundRunning;
}

/**
 * Changes the client team and clears them of BWRR related stuff
 *
 * @param client			The client to be moved
 * @param team				The team to move the client to
 */
void TF2BWR_ChangeClientTeam(int client, TFTeam team)
{
	int flag = TF2_GetClientFlag(client);
	
	if(IsValidEntity(flag))
	{
		TF2_ResetFlag(flag);
	}

	RobotPlayer rp = RobotPlayer(client);
	rp.ResetData();
	TF2_ClearClient(client);

	if(team == TFTeam_Blue)
	{
		Director_AddClientToQueue(client);
	}
	else
	{
		Robots_ClearModel(client);
		Robots_ClearScale(client);
		TF2MvM_ChangeClientTeam(client, team);
	}
}

// Changes the client team and bypasses game restrictions.
void TF2MvM_ChangeClientTeam(int client, TFTeam team)
{
	int entityflags = GetEntityFlags(client);
	SetEntityFlags(client, entityflags | FL_FAKECLIENT); // Fake client flag is needed to bypass restrictions
	TF2_ChangeClientTeam(client, team);
	SetEntityFlags(client, entityflags);
}

/**
 * Removes all weapons and attributes from a client
 *
 * @param client			The client to clear weapons and attributes
 * @param removeweapons		Remove weapons?
 * @param removewearables	Remove wearables (cosmetics)?
 */
void TF2_ClearClient(int client, bool removeweapons = true, bool removewearables = true)
{
	if(!IsClientInGame(client) || IsFakeClient(client) || !IsPlayerAlive(client))
		return;

	int entity, owner;

	if(removeweapons)
	{
		entity = -1;
		while((entity = FindEntityByClassname(entity, "tf_wearable_demoshield")) > MaxClients)
		{
			owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
			if(owner == client)
			{
				TF2_RemoveWearable( client, entity );
				RemoveEntity(entity);
			}
		}
		
		entity = -1;
		while((entity = FindEntityByClassname(entity, "tf_wearable_razorback")) > MaxClients)
		{
			owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
			if(owner == client)
			{
				TF2_RemoveWearable(client, entity);
				RemoveEntity(entity);
			}
		}

		RemoveAllWeapons(client);
	}

	if(removewearables)
	{
		entity = -1;
		while((entity = FindEntityByClassname(entity, "tf_wearable")) > MaxClients)
		{
			owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
			if(owner == client)
			{
				TF2_RemoveWearable(client, entity);
				RemoveEntity(entity);
			}
		}

		entity = -1;
		while((entity = FindEntityByClassname(entity, "tf_powerup_bottle")) > MaxClients)
		{
			owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
			if(owner == client) 
			{
				RemoveEntity(entity);
			}
		}
		
		entity = -1;
		while((entity = FindEntityByClassname(entity, "tf_usableitem")) > MaxClients)
		{
			owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
			if(owner == client) 
			{
				RemoveEntity(entity);
			}
		}
	}

	TF2Attrib_RemoveAll(client);
	TF2Attrib_ClearCache(client);
}

void RemoveAllWeapons(int client)
{
	int entity;
	for(int i = 0; i <= TFWeaponSlot_Item2; i++)
	{
		entity = TF2Util_GetPlayerLoadoutEntity(client, i, true);
		if(entity != -1) 
		{
			if(TF2Util_IsEntityWearable(entity)) 
			{
				TF2_RemoveWearable(client, entity);
			}
			else 
			{
				RemovePlayerItem(client, entity);
			}

			RemoveEntity(entity);
		}
	}
}

/**
 * Forces a client to pick up a flag
 *
 * @param client	The client to give the flag to
 * @param flag		The flag entity to give to the client
 * @return     no return
 */
void TF2_PickUpFlag(int client, int flag)
{
	SDKCall(g_hSDKPickupFlag, flag, client, true);
}

/**
 * Forces a flag to reset
 *
 * @param flag		The flag entity index to reset
 * @return     no return
 */
void TF2_ResetFlag(int flag)
{
	if(IsValidEntity(flag))
	{
		AcceptEntityInput(flag, "ForceReset");
	}
}

/**
 * Gets the MvM bomb hatch world position
 *
 * @param update	Send true to update the cached value.
 * @return     origin vector
 */
stock float[] TF2_GetBombHatchPosition(bool update = false)
{
	static float origin[3];
	
	if(update)
	{
		int i = -1;
		while ((i = FindEntityByClassname(i, "func_capturezone")) != -1)
		{
			GetEntityWorldCenter(i, origin);
		}
		
		return origin;
	}
	else
	{
		return origin;
	}
}

// checks if a player is giant
bool TF2_IsGiant(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_bIsMiniBoss"));
}

/**
 * Counts the number of active giants
 * 
 * @param humangiants     Variable to store human giant count
 * @param botgiants       Variable to store bot giant count
 */
void GetGiantCount(int &humangiants, int &botgiants)
{
	for(int i = 1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i) || TF2_GetClientTeam(i) != TFTeam_Blue)
			continue;

		if(IsFakeClient(i) && TF2_IsGiant(i)) botgiants++;
		if(!IsFakeClient(i) && TF2_IsGiant(i)) humangiants++;
	}
}

/**
 * Collects spawnpoints and add them to a list
 * 
 * @param spawns     ArrayList to store the spawnpoints entity references
 * @param team       The spawn point team
 */
void CollectSpawnPoints(ArrayList spawns, const int team)
{
	int entity;
	while((entity = FindEntityByClassname(entity, "info_player_teamspawn")) != INVALID_ENT_REFERENCE)
	{
		if(GetEntProp(entity, Prop_Send, "m_iTeamNum") == team && GetEntProp(entity, Prop_Data, "m_bDisabled") == 0)
		{
			spawns.Push(EntIndexToEntRef(entity));
		}
	}
}

/**
 * Filters spawn points by `trace hull`
 * 
 * @param spawns     ArrayList containing spawn points entity references
 * @param client     Client to test
 */
void FilterSpawnPointByHull(ArrayList spawns, int client)
{
	int entity = INVALID_ENT_REFERENCE;
	float origin[3];
	for(int i = 0;i < spawns.Length;i++)
	{
		entity = EntRefToEntIndex(spawns.Get(i));

		if(!IsValidEntity(entity))
		{
			spawns.Erase(i);
			continue;
		}

		CBaseEntity cbase = CBaseEntity(entity);
		cbase.GetAbsOrigin(origin);

		if(!IsSafeAreaToTeleport(client, origin))
		{
			spawns.Erase(i);
		}
	}
}

/**
 * Filters spawn points by checking if there is a nav area near them
 * 
 * @param spawns       ArrayList containing spawn points entity references
 * @param distance     Maximum distance between the nav area and the spawn point
 */
void FilterSpawnPointsByNavMesh(ArrayList spawns, const float distance = 256.0)
{
	int entity = INVALID_ENT_REFERENCE;
	float origin[3];
	for(int i = 0;i < spawns.Length;i++)
	{
		entity = EntRefToEntIndex(spawns.Get(i));

		if(!IsValidEntity(entity))
		{
			spawns.Erase(i);
			continue;
		}

		CBaseEntity cbase = CBaseEntity(entity);
		cbase.GetAbsOrigin(origin);

		if(TheNavMesh.GetNearestNavArea(origin, _, distance) == NULL_AREA)
		{
			#if defined _bwrr_debug_
			char targetname[64];
			GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));
			PrintToChatAll("[%i] Spawn Point \"%s\" at %.2f %.2f %.2f filtered by Nav Mesh.", entity, targetname, origin[0], origin[1], origin[2]);
			#endif
			spawns.Erase(i);
		}
	}	
}

int SelectSpawnPointRandomly(ArrayList spawns)
{
	return EntRefToEntIndex(spawns.Get(Math_GetRandomInt(0, spawns.Length - 1)));
}

/**
 * Performs a trace hull to check if it's safe to teleport (client won't get stuck)
 *
 * @param client			The client to get the bounds from
 * @param origin			The origin to test
 * @return					TRUE if the area is safe
 */
bool IsSafeAreaToTeleport(int client, float origin[3])
{
	Handle trace = null;
	float mins[3], maxs[3];
	GetEntPropVector(client, Prop_Send, "m_vecMins", mins);
	GetEntPropVector(client, Prop_Send, "m_vecMaxs", maxs);
	trace = TR_TraceHullFilterEx(origin, origin, mins, maxs, MASK_PLAYERSOLID, TraceFilter_IgnorePlayers);
	bool result = TR_DidHit(trace);
	delete trace;
	return !result;
}

// code from Pelipoika's bot control
// executes a fake command with a delay between executions
bool FakeClientCommandThrottled(int client, const char[] command)
{
	if(g_flNextCommand[client] > GetGameTime())
		return false;
	
	FakeClientCommand(client, command);
	
	g_flNextCommand[client] = GetGameTime() + 0.4;
	
	return true;
}

void TF2BWR_DeployBomb(int client)
{
	RobotPlayer rp = RobotPlayer(client);
	float time = FindConVar("tf_deploying_bomb_time").FloatValue + 0.5;
	float origin[3], hatch[3], result[3], angles[3];

	GetClientAbsOrigin(client, origin);
	hatch = TF2_GetBombHatchPosition(true);
	SubtractVectors(hatch, origin, result);
	NormalizeVector(result, result);
	GetVectorAngles(result, angles);
	angles[0] = 0.0;
	angles[2] = 0.0;
	TeleportEntity(client, NULL_VECTOR, angles, {0.0, 0.0, 0.0});
	TF2_AddCondition(client, TFCond_FreezeInput, time);
	TF2_PlaySequence(client, "primary_deploybomb");
	SetVariantInt(1);
	AcceptEntityInput(client, "SetForcedTauntCam");	
	RequestFrame(Frame_DisableAnimation, GetClientSerial(client));

	switch(rp.type)
	{
		case BWRR_RobotType_Boss, BWRR_RobotType_Giant:
		{
			EmitGameSoundToAll("MVM.DeployBombGiant", client, SND_NOFLAGS, _, origin);
		}
		default:
		{
			EmitGameSoundToAll("MVM.DeployBombSmall", client, SND_NOFLAGS, _, origin);
		}
	}
}

void TF2BWR_CancelDeployBomb(int client)
{
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
	TF2_RemoveCondition(client, TFCond_FreezeInput);
}

void TF2BWR_TriggerBombHatch(int client)
{
	int entity = FindEntityByClassname(-1, "func_capturezone");
	LogAction(client, -1, "\"%L\" deployed the bomb.", client);
	PrintToChatAll("%N deployed the bomb!", client);
	if(entity != -1)
	{
		FireEntityOutput(entity, "OnCapture", entity);
		FireEntityOutput(entity, "OnCapTeam2", entity);
	}
	else
	{
		ThrowError("Could not find func_capturezone");
	}
}

/*void CollectEngineerHints(int client, ArrayList hints)
{
	int entity;
	float origin[3];

	while((entity = FindEntityByClassname(entity, "bot_hint_engineer_nest")) != INVALID_ENT_REFERENCE)
	{
		if(GetEntProp(entity, Prop_Send, "m_iTeamNum") == view_as<int>(TFTeam_Blue))
		{
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
			if(IsSafeAreaToTeleport(client, origin))
			{
				hints.Push(entity);
			}
		}
	}	
}*/

/**
 * Gets a random client from the given team
 * 
 * @param team      The client team
 * @param alive     Exclude dead players
 * @param bots      Should bots be included
 * @param inspawn   Exlude players inside spawn
 * @return          Client index or 0 if not found
 */
int GetRandomClientFromTeam(int team, bool alive = false, bool bots = false, bool inspawn = false)
{
	int counter;
	int[] players = new int[MaxClients + 1];

	for(int i = 1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;

		if(GetClientTeam(i) != team)
			continue;

		if(!bots && IsFakeClient(i))
			continue;

		if(alive && !IsPlayerAlive(i))
			continue;

		if(inspawn)
		{
			float origin[3];
			GetClientAbsOrigin(i, origin);
			if(TF2Util_IsPointInRespawnRoom(origin, i, true)) {
				continue;
			}
				
		}
		
		players[counter] = i;
		counter++;
	}

	if(counter == 0) { return 0; }
	return players[Math_GetRandomInt(0, counter - 1)];
}

/**
 * Performs a simple Trace Ray between start and end positions
 * 
 * @param start     The start position
 * @param end       The end position
 * @return          TRUE if there is an obstruction between the start and end positions
 */
bool CheckLOSSimpleTrace(float start[3], float end[3])
{
	Handle trace = null;
	trace = TR_TraceRayFilterEx(start, end, MASK_SHOT, RayType_EndPoint, TraceFilter_LOS);
	bool hit = TR_DidHit(trace);
	delete trace;

	return hit;
}

/**
 * Collects nearby nav areas and place them by ID in an ArrayList
 * 
 * @param areas       ArrayList to store the NAV areas IDs
 * @param origin      The point to get the starting area
 * @param maxdist     Maximum distance to collect
 * @param maxup       Maximum step height
 * @param maxdown     Maximum drop down height limit
 * @return            TRUE if successfully collected
 */
bool CollectNavAreas(ArrayList areas, const float origin[3], float maxdist, float maxup, float maxdown)
{
	CNavArea start = TheNavMesh.GetNearestNavArea(origin, false, 512.0);

	if(start == NULL_AREA)
	{
		return false;
	}

	SurroundingAreasCollector collector = TheNavMesh.CollectSurroundingAreas(start, maxdist, maxup, maxdown);

	for(int i = 0;i < collector.Count(); i++)
	{
		CNavArea navarea = collector.Get(i);
		areas.Push(navarea.GetID());
	}

	delete collector;
	return true;
}

/**
 * Filters the NAV areas from the ArrayList using Trace Hull to check if the given client won't get stuck.
 * 
 * @param areas      ArrayList containing NAV areas ID
 * @param client     Client index
 */
void FilterNavAreasByTrace(ArrayList areas, int client)
{
	CNavArea navarea;
	float center[3];

	for(int i = 0;i < areas.Length;i++)
	{
		navarea = TheNavMesh.GetNavAreaByID(areas.Get(i));
		navarea.GetCenter(center);
		center[2] += 15.0; // add a bit of height

		if(!IsSafeAreaToTeleport(client, center))
		{
			areas.Erase(i);
		}
	}
}

void FilterNavAreasByLOS(ArrayList areas, TFTeam team)
{
	CNavArea navarea;
	float center[3], angles[3], origin[3], fwd[3], eyes[3];

	for(int i = 0;i < areas.Length;i++)
	{
		navarea = TheNavMesh.GetNavAreaByID(areas.Get(i));
		navarea.GetCenter(center);
		center[2] += 15.0; // add a bit of height

		for(int client = 1;client <= MaxClients;client++)
		{
			if(!IsClientInGame(client))
				continue;

			if(!IsPlayerAlive(client))
				continue;

			if(TF2_GetClientTeam(client) != team)
				continue;

			GetClientAbsOrigin(client, origin);
			GetClientEyeAngles(client, angles);
			GetClientEyePosition(client, eyes);
			GetAngleVectors(angles, fwd, NULL_VECTOR, NULL_VECTOR);

			if(PointWithinViewAngle(origin, center, fwd, GetFOVDotProduct(140.0))) // Check if within view angles
			{
				if(!CheckLOSSimpleTrace(eyes, center)) // Check for obstruction
				{
					areas.Erase(i);
				}
			}
		}
	}
}

/**
 * Filters NAV area by distance
 * 
 * @param areas      ArrayList containing NAV areas ID
 * @param source     Position vector to compare distance
 * @param min        Minimum distance
 * @param max        Maximum distance
 */
void FilterNavAreasByDistance(ArrayList areas, const float source[3], const float min, const float max)
{
	CNavArea navarea;
	float center[3], distance;

	for(int i = 0;i < areas.Length;i++)
	{
		navarea = TheNavMesh.GetNavAreaByID(areas.Get(i));
		navarea.GetCenter(center);
		center[2] += 15.0; // add a bit of height

		distance = GetVectorDistance(center, source);

		if(distance < min)
		{
			areas.Erase(i);
		}
		else if(distance > max)
		{
			areas.Erase(i);
		}
	}
}

/**
 * Filters NAV areas inside spawn rooms
 * 
 * @param areas                   ArrayList containing NAV areas
 * @param entity                  An optional entity to check.
 * @param bRestrictToSameTeam     Whether or not the respawn room must either match the entity's
 *                                team, or not be assigned to a team.  Always treated as true if
 *                                the position is in an active spawn room.  Has no effect if no
 *                                entity is provided.
 */
void FilterNavAreasBySpawnRoom(ArrayList areas, const int entity = INVALID_ENT_REFERENCE, const bool bRestrictToSameTeam = false)
{
	CNavArea navarea;
	float center[3];
	float points[4][3];

	for(int i = 0;i < areas.Length;i++)
	{
		navarea = TheNavMesh.GetNavAreaByID(areas.Get(i));
		navarea.GetCenter(center);
		center[2] += 15.0; // add a bit of height

		navarea.GetCorner(NORTH_WEST, points[0]);
		navarea.GetCorner(NORTH_EAST, points[1]);
		navarea.GetCorner(SOUTH_WEST, points[2]);
		navarea.GetCorner(SOUTH_EAST, points[3]);

		for(int y = 0;y < sizeof(points);y++)
		{
			points[y][2] += 15.0; // add a bit of height
		}

		if(TF2Util_IsPointInRespawnRoom(center, entity, bRestrictToSameTeam))
		{
			areas.Erase(i);
			continue;
		}

		for(int y = 0;y < sizeof(points);y++)
		{
			if(TF2Util_IsPointInRespawnRoom(points[y], entity, bRestrictToSameTeam))
			{
				areas.Erase(i);
				break;
			}
		}
	}
}

int CollectBombs(ArrayList bombs, const int team)
{
	int entity = INVALID_ENT_REFERENCE;
	int counter = 0;

	while((entity = FindEntityByClassname(entity, "item_teamflag")) != INVALID_ENT_REFERENCE)
	{
		if(GetEntProp(entity, Prop_Send, "m_iTeamNum") == team && GetEntProp(entity, Prop_Send, "m_bDisabled") == 0)
		{
			bombs.Push(EntIndexToEntRef(entity));
			counter++;
		}
	}

	return counter;
}

/**
 * Gets the bomb by distance to the bomb hatch
 * 
 * @param bombs        ArrayList containg a bomb list as entity references
 * @param distance     Distance between the closest bomb and the bomb hatch
 * @return             The closest bomb entity index
 */
int GetBombClosestToHatch(ArrayList bombs, float &distance)
{
	int entity = INVALID_ENT_REFERENCE, best = INVALID_ENT_REFERENCE;
	float short = 999999.0, search;
	float hatch[3], origin[3];
	hatch = TF2_GetBombHatchPosition(true);

	for(int i = 0; i < bombs.Length;i++)
	{
		entity = EntRefToEntIndex(bombs.Get(i));

		if(entity == INVALID_ENT_REFERENCE)
			continue;

		TF2_GetFlagPosition(entity, origin);

		search = GetVectorDistance(origin, hatch);

		if(search < short)
		{
			short = search;
			distance = search;
			best = entity;
		}
	}

	return best;
}

/**
 * Gets the average distance between the bombs and the target position
 * 
 * @param bombs      ArrayList containing the bombs ent refs
 * @param target     Target position
 * @return           Average distance
 */
float GetAverageBombDistance(ArrayList bombs, const float target[3])
{
	float distance = 0.0;
	float origin[3];
	int divider = 0, entity = INVALID_ENT_REFERENCE;

	for(int i = 0; i < bombs.Length;i++)
	{
		entity = EntRefToEntIndex(bombs.Get(i));

		if(entity == INVALID_ENT_REFERENCE)
			continue;

		TF2_GetFlagPosition(entity, origin);

		distance += GetVectorDistance(origin, target);
		divider++;
	}

	if(divider == 0)
	{
		return -1.0;
	}

	return distance/divider;
}

/**
 * Checks if there are RED owned control points in the map.
 * 
 * @return     TRUE if there are RED owned control points
 */
bool CheckForREDOwnedControlPoints()
{
	int ent = -1;

	while((ent = FindEntityByClassname(ent, "team_control_point")) != -1)
	{
		if(IsValidEntity(ent))
		{
			if(GetEntProp(ent, Prop_Send, "m_iTeamNum") == view_as<int>(TFTeam_Red))
			{
				return true;
			}
		}
	}

	return false;
}

void GateManager_Clear()
{
	g_eGateManager.available = false;
	g_eGateManager.numgates = 0;

	for(int i = 0; i < sizeof(g_eGateManager.gates);i++)
	{
		g_eGateManager.gates[i] = INVALID_ENT_REFERENCE;
	}
}

void GateManager_Update()
{
	g_eGateManager.available = CheckForREDOwnedControlPoints();

	int ent = INVALID_ENT_REFERENCE;

	while((ent = FindEntityByClassname(ent, "team_control_point")) != INVALID_ENT_REFERENCE)
	{
		g_eGateManager.gates[g_eGateManager.numgates] = EntIndexToEntRef(ent);
		g_eGateManager.numgates++;

		if(g_eGateManager.numgates == sizeof(g_eGateManager.gates))
			break;
	}
}

Action Timer_CheckGates(Handle timer)
{
	GateManager_Clear();
	GateManager_Update();
	return Plugin_Stop;
}

Action Timer_UpdateGatebotStatus(Handle timer)
{
	for(int i = 1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;

		if(IsFakeClient(i))
			continue;

		if(TF2_GetClientTeam(i) != TFTeam_Blue)
			continue;

		RobotPlayer rp = RobotPlayer(i);

		if(rp.gatebot)
		{
			if(!g_eGateManager.available) // All gates were captured
			{
				RemoveGateBotHat(i); // Remove hat
				GiveGatebotHat(i, TF2_GetPlayerClass(i), false); // Give hat with light off
				TF2Attrib_RemoveByName(i, "cannot pick up intelligence");
			}
		}
	}

	return Plugin_Stop;
}

/**
 * Decouples all objects (buildings) from the given client.
 * Prevents buildings from getting destroyed when the engineers change classes/teams
 * 
 * @param client     Client index of the builder
 */
void DecoupleAllObjectsFromClient(int client)
{
	int entity = INVALID_ENT_REFERENCE;
	while((entity = FindEntityByClassname(entity, "obj_sentrygun")) != INVALID_ENT_REFERENCE)
	{
		if(GetEntPropEnt(entity, Prop_Send, "m_hBuilder") == client)
		{
			DecoupleObjectFromClient(client, entity);
		}
	}

	entity = INVALID_ENT_REFERENCE;
	while((entity = FindEntityByClassname(entity, "obj_dispenser")) != INVALID_ENT_REFERENCE)
	{
		if(GetEntPropEnt(entity, Prop_Send, "m_hBuilder") == client)
		{
			DecoupleObjectFromClient(client, entity);
		}
	}

	entity = INVALID_ENT_REFERENCE;
	while((entity = FindEntityByClassname(entity, "obj_teleporter")) != INVALID_ENT_REFERENCE)
	{
		if(GetEntPropEnt(entity, Prop_Send, "m_hBuilder") == client)
		{
			DecoupleObjectFromClient(client, entity);
		}
	}
}

/**
 * Decouples a single object from a client
 * 
 * @param client     Client index of the builder
 * @param obj        Object entity index
 */
void DecoupleObjectFromClient(int client, int obj)
{
	SetEntityOwner(obj, INVALID_ENT_REFERENCE);
	TF2_SetBuilder(obj, INVALID_ENT_REFERENCE);
	TF2_RemoveObject(client, obj);
}

/**
 * Modifier SpawnWeapon function exclusive for gatebot hats
 * 
 * @param client     Client index to give the hat to
 * @param name       classname
 * @param index      Item definition index
 * @param light      true if the hat's light should be on
 */
void SpawnGatebotHat(int client, char[] name, int index, bool light = true)
{
	Handle hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION|PRESERVE_ATTRIBUTES);
	TF2Items_SetClassname(hWeapon, name);
	TF2Items_SetItemIndex(hWeapon, index);
	TF2Items_SetLevel(hWeapon, 1);
	TF2Items_SetQuality(hWeapon, 6);
	
	// If light is false, the gatebot hat is turned off.
	if(!light) {
		TF2Items_SetAttribute(hWeapon, 0, 542, 1.0); // item style override
		TF2Items_SetNumAttributes(hWeapon, 1);
	}
	
	if(hWeapon==null)
		return;
		
	int entity = TF2Items_GiveNamedItem(client, hWeapon);
	CloseHandle(hWeapon);

	if(IsValidEdict(entity))
	{
		TF2Util_EquipPlayerWearable(client, entity);
	}
}

/**
 * Checks if the given item definition index is a gatebot hat
 * 
 * @param index     Item definition index
 * @return          TRUE if the given item is a gatebot hat
 */
bool IsGateBotHat(int index)
{
	switch(index)
	{
		case 1057, 1063, 1058, 1061, 1060, 1065, 1059, 1062, 1064: return true;
		default: return false;
	}
}

/**
 * Gives a gatebot hat to the client
 * 
 * @param client     The client index to give to
 * @param class      The client class
 * @param light      TRUE if the hat should have the 'on' skin
 */
void GiveGatebotHat(int client, TFClassType class, bool light = true)
{
	int index;
	
	switch(class) // item definition index for gatebot hats "MvM GateBot Light" --> https://wiki.alliedmods.net/Team_Fortress_2_Item_Definition_Indexes 
	{
		case TFClass_Scout: index = 1057;
		case TFClass_Soldier: index = 1063;
		case TFClass_Pyro: index = 1058;
		case TFClass_DemoMan: index = 1061;
		case TFClass_Heavy: index = 1060;
		case TFClass_Engineer: index = 1065;
		case TFClass_Medic: index = 1059;
		case TFClass_Sniper: index = 1062;
		case TFClass_Spy: index = 1064;
		default: return;
	}
	
	SpawnGatebotHat(client,"tf_wearable",index, light);
}

/**
 * Removes the gatebot hat from the client
 * 
 * @param client     Client index to remove the hat from
 */
void RemoveGateBotHat(int client)
{
	int entity = -1;
	while((entity = FindEntityByClassname(entity, "tf_wearable")) > MaxClients)
	{
		int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		if(owner == client)
		{
			int index = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
			if(IsGateBotHat(index))
			{
				TF2_RemoveWearable(client, entity);
				RemoveEntity(entity);
			}
		}
	}	
}


/*----------------------------------------------
-----------------TRACE FILTERS------------------
----------------------------------------------*/

// Trace filter that ignores all clients/players
bool TraceFilter_IgnorePlayers(int entity, int contentsMask)
{
	if(entity > 0 && entity <= MaxClients)
	{
		return false;
	}

	return true;
}

bool TraceFilter_LOS(int entity, int contentsMask)
{
	if(entity > 0 && entity <= MaxClients)
	{
		return false;
	}

	char classname[64];
	GetEntityClassname(entity, classname, sizeof(classname));

	if(StrContains("obj_", classname, false) != -1) { return false; }
	if(strcmp("tank_boss", classname, false) == 0) { return false; }

	return true;	
}

/*----------------------------------------------
------------REQUESTFRAME CALLBACKS--------------
----------------------------------------------*/

// code from Pelipoika's bot control
// Updates the bomb level show on the HUD
void Frame_UpdateBombHUD(int serial)
{
	int client = GetClientFromSerial(serial);

	if(client)
	{
		RobotPlayer rp = RobotPlayer(client);
		int entity = FindEntityByClassname(-1, "tf_objective_resource");
		SetEntProp(entity, Prop_Send, "m_nFlagCarrierUpgradeLevel", rp.bomblevel);
		SetEntPropFloat(entity, Prop_Send, "m_flMvMBaseBombUpgradeTime", rp.inspawn ? -1.0 : GetGameTime());
		SetEntPropFloat(entity, Prop_Send, "m_flMvMNextBombUpgradeTime", rp.inspawn ? -1.0 : rp.nextbombupgradetime);
	}
}

void Frame_RemoveReviveMaker(int entref)
{
	int ent = EntRefToEntIndex(entref);
	if(ent == INVALID_ENT_REFERENCE)
		return;
		
	int team = GetEntProp(ent, Prop_Send, "m_iTeamNum");
	if(team != 3)
		return;
		
	RemoveEntity(ent);
}

void Frame_RemoveAmmoPack(int entref)
{
	int ent = EntRefToEntIndex(entref);
	if(ent == INVALID_ENT_REFERENCE)
		return;
		
	int owner = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
	
	if(IsValidClient(owner) && GetClientTeam(owner) == 3)
	{
		RemoveEntity(ent);
	}	
}

// code from Pelipoika's bot control
void Frame_DisableAnimation(int serial)
{
	static int count = 0;

	int client = GetClientFromSerial(serial);

	if(client > 0)
	{
		if(count > 6)
		{
			float vecClientPos[3], vecTargetPos[3];
			GetClientAbsOrigin(client, vecClientPos);
			vecTargetPos = TF2_GetBombHatchPosition();
			float v[3], ang[3];
			SubtractVectors(vecTargetPos, vecClientPos, v);
			NormalizeVector(v, v);
			GetVectorAngles(v, ang);
			ang[0] = 0.0;
			SetVariantString("1");
			AcceptEntityInput(client, "SetCustomModelRotates");
			SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 0);
			char strVec[16];
			Format(strVec, sizeof(strVec), "0 %f 0", ang[1]);
			SetVariantString(strVec);
			AcceptEntityInput(client, "SetCustomModelRotation");
			count = 0;
		}
		else
		{
			TF2_PlaySequence(client, "primary_deploybomb");
			RequestFrame(Frame_DisableAnimation, serial);
			count++;
		}
	}
	else
	{
		count = 0;
	}
}