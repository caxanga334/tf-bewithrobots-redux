// Robots Templates

#define MAX_ROBOTS (1<<10)

int g_cbindex = 0; // Current robot index
int g_maxrobots = 0; // Number of robots that was registered

/**
	int pluginID; // the plugin that will handle this robot
	TFClassType class; // the robot class
	int cost; // resource cost
	int index; // robot list internal index
	int type; // robot type
	int supply; // available count
	int role; // robot role
	float percent; // wave percentage
	int spawns; // How many times this robot has spawned in the current wave
	float lastspawn; // The last time this robot spawned in the current wave
*/
enum struct etemplates
{
	int pluginID;
	TFClassType class;
	int cost;
	int index;
	int type;
	int supply;
	int role;
	float percent;
	int spawns;
	float lastspawn;
}
etemplates g_eTemplates[MAX_ROBOTS];

void RegisterRobotTemplate(int pluginID, TFClassType class, int cost, int index, int type, int supply, int role, float percent)
{
	if(g_cbindex >= MAX_ROBOTS)
	{
		ThrowError("Maximum number of robots reached!");
	}

	if(class == TFClass_Unknown)
	{
		ThrowError("Invalid robot class! Plugin ID \"%i\", Robot Index \"%i\"", pluginID, index);
	}

	g_eTemplates[g_cbindex].pluginID = pluginID;
	g_eTemplates[g_cbindex].class = class;
	g_eTemplates[g_cbindex].cost = cost;
	g_eTemplates[g_cbindex].index = index;
	g_eTemplates[g_cbindex].type = type;
	g_eTemplates[g_cbindex].supply = supply;
	g_eTemplates[g_cbindex].percent = percent;
	g_eTemplates[g_cbindex].role = role;

	g_cbindex++;
	g_maxrobots++;

#if defined _bwrr_debug_
	LogMessage("Robot Registered: %i %i %i %i %i %i %i %.2f", pluginID, class, cost, index, type, supply, role, percent);
#endif
}

/**
 * Resets spawn and lastspawn values for each template
 */
void Robots_ResetWaveData()
{
	for(int i = 0;i < g_maxrobots;i++)
	{
		g_eTemplates[i].spawns = 0;
		g_eTemplates[i].lastspawn = -1.0;
	}
}

/**
 * Gets the amount of robots registered.
 * 1 is subtracted from the total amount of robots due to arrays.
 * If you need the true amount of robots either add 1 or use `g_maxrobots` global variable.
 *
 * @return          The number of robots registered. -1 if no robot was registered.
 */
stock int Robots_GetMax()
{
	return g_maxrobots - 1;
}

// Gets the template class
TFClassType Robots_GetClass(int template)
{
	return g_eTemplates[template].class;
}

/**
 * Gets the robot cost
 * 
 * @param template     Template index
 * @return             The robot template cost
 */
int Robots_GetCost(int template, const float multiplier = 1.0)
{
	return RoundToCeil(g_eTemplates[template].cost * multiplier);
}

void Robots_SetModel(int client, TFClassType class)
{
	if(IsFakeClient(client)) 
		return;

	char playermodel[PLATFORM_MAX_PATH];
	
	switch(class)
	{
		case TFClass_Scout: strcopy(playermodel, sizeof(playermodel), "scout");
		case TFClass_Sniper: strcopy(playermodel, sizeof(playermodel), "sniper");
		case TFClass_Soldier: strcopy(playermodel, sizeof(playermodel), "soldier");
		case TFClass_DemoMan: strcopy(playermodel, sizeof(playermodel), "demo");
		case TFClass_Medic: strcopy(playermodel, sizeof(playermodel), "medic");
		case TFClass_Heavy: strcopy(playermodel, sizeof(playermodel), "heavy");
		case TFClass_Pyro: strcopy(playermodel, sizeof(playermodel), "pyro");
		case TFClass_Spy: strcopy(playermodel, sizeof(playermodel), "spy");
		case TFClass_Engineer: strcopy(playermodel, sizeof(playermodel), "engineer");
		default: ThrowError("Set Model called for invalid class! %i", view_as<int>(class));
	}

	RobotPlayer rp = RobotPlayer(client);

	switch(rp.type)
	{
		case BWRR_RobotType_Giant, BWRR_RobotType_Boss:
		{
			switch(class)
			{
				case TFClass_Scout, TFClass_Soldier, TFClass_DemoMan, TFClass_Heavy, TFClass_Pyro:
				{
					Format(playermodel, sizeof(playermodel), "models/bots/%s_boss/bot_%s_boss.mdl", playermodel, playermodel);
				}
				default:
				{
					Format(playermodel, sizeof(playermodel), "models/bots/%s/bot_%s.mdl", playermodel, playermodel);
				}
			}
		}
		case BWRR_RobotType_Buster:
		{
			FormatEx(playermodel, sizeof(playermodel), "models/bots/demo/bot_sentry_buster.mdl");
		}
		default:
		{
			Format(playermodel, sizeof(playermodel), "models/bots/%s/bot_%s.mdl", playermodel, playermodel);
		}
	}

	Action result;

	Call_StartForward(g_OnApplyModel);
	Call_PushCell(client);
	Call_PushCell(g_eTemplates[rp.templateindex].pluginID);
	Call_PushCell(TF2_GetPlayerClass(client));
	Call_PushCell(g_eTemplates[rp.templateindex].index);
	Call_PushCell(g_eTemplates[rp.templateindex].type);
	Call_PushStringEx(playermodel, PLATFORM_MAX_PATH, SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_Finish(result);

	if(result == Plugin_Handled || result == Plugin_Stop)
	{
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
		return;
	}

	SetVariantString(playermodel);
	AcceptEntityInput(client, "SetCustomModel");
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
}

void Robots_ClearModel(int client)
{
	SetVariantString("");
	AcceptEntityInput(client, "SetCustomModel");
}

float Robots_GetScaleSize(int client)
{
	RobotPlayer rp = RobotPlayer(client);
	float scale = 1.0;

	switch(rp.type)
	{
		case BWRR_RobotType_Boss: scale = 1.9;
		case BWRR_RobotType_Buster, BWRR_RobotType_Giant: scale = 1.75;
		default: scale = 1.0;
	}

	Call_StartForward(g_OnApplyScale);
	Call_PushCell(client);
	Call_PushCell(g_eTemplates[rp.templateindex].pluginID);
	Call_PushCell(TF2_GetPlayerClass(client));
	Call_PushCell(g_eTemplates[rp.templateindex].index);
	Call_PushCell(g_eTemplates[rp.templateindex].type);
	Call_PushFloatRef(scale);
	Call_Finish();

	Math_Clamp(scale, c_robots_min_size.FloatValue, c_robots_max_size.FloatValue);

	return scale;
}

void Robots_SetScale(int client, const float scale)
{
	float mins[3],maxs[3];
	TF2_GetPlayerHullSize(mins, maxs);
	ScaleVector(mins, scale);
	ScaleVector(maxs, scale);

	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMins", mins);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMaxs", maxs);
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", scale);
}

void Robots_ClearScale(int client)
{
	float mins[3],maxs[3];
	TF2_GetPlayerHullSize(mins, maxs);

	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMins", mins);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMaxs", maxs);
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.0);
}

void Robots_DefaultLoopSound(RobotPlayer rp, char[] sound, int size)
{
	switch(rp.type)
	{
		case BWRR_RobotType_Boss, BWRR_RobotType_Giant:
		{
			switch(TF2_GetPlayerClass(rp.index))
			{
				case TFClass_Scout: strcopy(sound, size, "mvm/giant_scout/giant_scout_loop.wav");
				case TFClass_Soldier: strcopy(sound, size, "mvm/giant_soldier/giant_soldier_loop.wav");
				case TFClass_Pyro: strcopy(sound, size, "mvm/giant_pyro/giant_pyro_loop.wav");
				case TFClass_DemoMan: strcopy(sound, size, "mvm/giant_demoman/giant_demoman_loop.wav");
				case TFClass_Heavy: strcopy(sound, size, "mvm/giant_heavy/giant_heavy_loop.wav");
			}
		}
		case BWRR_RobotType_Buster: strcopy(sound, size, "mvm/sentrybuster/mvm_sentrybuster_loop.wav");
	}
}

void Robots_SetLoopSound(int client)
{
	char sound[PLATFORM_MAX_PATH];
	int level = SNDLEVEL_TRAIN;
	RobotPlayer rp = RobotPlayer(client);
	Robots_DefaultLoopSound(rp, sound, sizeof(sound));

	if(rp.templateindex >= 0)
	{
		Action result;
		Call_StartForward(g_OnApplyLoopSound);
		Call_PushCell(client);
		Call_PushCell(g_eTemplates[rp.templateindex].pluginID);
		Call_PushCell(TF2_GetPlayerClass(client));
		Call_PushCell(g_eTemplates[rp.templateindex].index);
		Call_PushCell(g_eTemplates[rp.templateindex].type);
		Call_PushStringEx(sound, PLATFORM_MAX_PATH, SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
		Call_PushCellRef(level);
		Call_Finish(result);
	
		if(result == Plugin_Handled || result == Plugin_Stop)
		{
			return;
		}
	}

	if(strlen(sound) > 2)
	{
		rp.SetLoopSound(sound);
		EmitSoundToAll(sound, client, SNDCHAN_STATIC, level, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL);
	}
}

void Robots_OnRobotSpawn(int template)
{
	g_eTemplates[template].spawns++;
	g_eTemplates[template].lastspawn = GetGameTime();
}

/**
 * Collects robots template indexes based on the given filters
 * 
 * @param robots        ArrayList to store collected robots indexes
 * @param resources     Director resource amount
 * @param class         Optional class filter
 * @param type          Optional type filter
 * @param role          Optional role filter
 * @return              Number of templates collected
 */
int Robots_CollectTemplates(ArrayList robots, int resources, TFClassType class = TFClass_Unknown, int type = BWRR_RobotType_Invalid, int role = BWRR_Role_Invalid)
{
	int collected = 0;

	for(int i = 0;i < g_maxrobots;i++)
	{
		if(g_eTemplates[i].cost > resources) // can't afford
			continue;

		if(g_eTemplates[i].supply > 0 && g_eTemplates[i].spawns > g_eTemplates[i].supply) // No longer available for the current wave
			continue;

		if(g_eTemplates[i].percent > TF2MvM_GetCompletedWavePercent()) // Not available for the current wave percentage
			continue;

		if(class != TFClass_Unknown && g_eTemplates[i].class != class) // Class filter
			continue;

		if(type != BWRR_RobotType_Invalid && g_eTemplates[i].type != type) // Type filter
			continue;

		if(role != BWRR_Role_Invalid && g_eTemplates[i].role != role) // Role filter
			continue;

		robots.Push(i);
		collected++;
	}

	return collected;
}

/**
 * Checks if there are any robot available
 * 
 * @param resources     Director resource amount
 * @param class         Optional class filter
 * @param type          Optional type filter
 * @param role          Optional role filter
 * @return              TRUE if at least 1 robot is available
 */
bool Robots_AnyAvailable(int resources, TFClassType class = TFClass_Unknown, int type = BWRR_RobotType_Invalid, int role = BWRR_Role_Invalid)
{
	for(int i = 0;i < g_maxrobots;i++)
	{
		if(g_eTemplates[i].cost > resources) // can't afford
			continue;

		if(g_eTemplates[i].supply > 0 && g_eTemplates[i].spawns > g_eTemplates[i].supply) // No longer available for the current wave
			continue;

		if(g_eTemplates[i].percent > TF2MvM_GetCompletedWavePercent()) // Not available for the current wave percentage
			continue;

		if(class != TFClass_Unknown && g_eTemplates[i].class != class) // Class filter
			continue;

		if(type != BWRR_RobotType_Invalid && g_eTemplates[i].type != type) // Type filter
			continue;

		if(role != BWRR_Role_Invalid && g_eTemplates[i].role != role) // Role filter
			continue;

		return true;
	}

	return false;
}

/**
 * Filters the robot list by cost
 * 
 * @param robots        ArrayList containing robots indexes
 * @param resources     Amount of resources the director has
 * @param spawns        Number of players to be spawned simultaneously
 * @param multiplier    Cost multiplier
 */
void Robots_FilterByCanAfford(ArrayList robots, int resources, int spawns = 1, float multiplier = 1.0)
{
	int cost, index;
	for(int i = 0;i < robots.Length;i++)
	{
		index = robots.Get(i);
		cost = RoundToCeil((g_eTemplates[index].cost * multiplier) * spawns);

		if(cost > resources)
		{
			#if defined _bwrr_debug_
			PrintToChatAll("[Cost Filter] Filtered template %i, cost: %i, resources: %i", index, cost, resources);
			#endif
			robots.Erase(i);
		}
	}
}

/**
 * Filters the robot list by supply limit
 * Checks if there are enough robots remaining to spawn all players
 * 
 * @param robots        ArrayList containing robots indexes
 * @param spawns        Number of players to be spawned simultaneously
 */
void Robots_FilterBySupply(ArrayList robots, int spawns = 1)
{
	int index;
	for(int i = 0;i < robots.Length;i++)
	{
		index = robots.Get(i);
		
		if(g_eTemplates[index].supply < 0)
			continue;

		if(g_eTemplates[index].spawns + spawns > g_eTemplates[index].supply)
		{
			robots.Erase(i);
		}
	}
}

/**
 * Filters the robot list by cost
 * 
 * @param robots        ArrayList containing robots indexes
 */
void Robots_FilterByCanBeGatebot(ArrayList robots)
{
	int index;
	for(int i = 0;i < robots.Length;i++)
	{
		index = robots.Get(i);
		
		Action result;
		Call_StartForward(g_FilterGateBot);
		Call_PushCell(g_eTemplates[index].pluginID);
		Call_PushCell(g_eTemplates[index].class);
		Call_PushCell(g_eTemplates[index].index);
		Call_PushCell(g_eTemplates[index].type);
		Call_Finish(result);

		if(result == Plugin_Stop || result == Plugin_Handled)
		{
			robots.Erase(i);
		}
	}
}

/**
 * Selects the robots by highest cost
 * 
 * @param robots     ArrayList containing robots indexes
 * @return           The template index of the most expensive robot
 */
int Robots_SelectByHighestCost(ArrayList robots)
{
	int cost, last = 0, index, best;
	for(int i = 0;i < robots.Length;i++)
	{
		index = robots.Get(i);
		cost = g_eTemplates[index].cost;

		if(cost > last)
		{
			last = cost;
			best = index;
		}
	}

	return best;
}

/**
 * Selects a robot by Random Number Generator
 * 
 * @param robots     ArrayList containing robots indexes
 * @return           The template index of the selected robot
 */
int Robots_SelectByRNG(ArrayList robots)
{
	return robots.Get(Math_GetRandomInt(0, robots.Length - 1));	
}

int Robots_SelectBySpawnTime(ArrayList robots)
{
	int selected, index;
	float last, best = 9999999.0;

	for(int i = 0;i < robots.Length;i++)
	{
		index = robots.Get(i);
		last = g_eTemplates[index].lastspawn;

		if(last < 0.0) { return index; } // lastspawn is set to -1.0 on every wave starts, smaller than 0 means this robot never spawned! Priorize it.

		if(last < best)
		{
			best = last;
			selected = index;
		}
 	}

	return selected;	
}

/**
 * Called when the sentry buster starts to detonate
 * 
 * @param client     Param description
 * @return           Return description
 */
void Robots_OnBeginSentryBusterDetonation(int client)
{
	RobotPlayer rp = RobotPlayer(client);

	if(rp.isdetonating)
		return;

	float delay = 1.980;

	Action result;
	Call_StartForward(g_OnSentryBusterBeginToDetonate);
	Call_PushCell(client);
	Call_PushCell(g_eTemplates[rp.templateindex].pluginID);
	Call_PushCell(TF2_GetPlayerClass(client));
	Call_PushCell(g_eTemplates[rp.templateindex].index);
	Call_PushCell(g_eTemplates[rp.templateindex].type);
	Call_PushFloatRef(delay);
	Call_Finish(result);

	if(result == Plugin_Continue || result == Plugin_Changed)
	{
		rp.BeginToDetonate(delay);
		FakeClientCommandThrottled(client, "taunt");
		EmitGameSoundToAll("MVM.SentryBusterSpin", client);
		SetEntProp(client, Prop_Data, "m_takedamage", DAMAGE_NO);
	}
}

void Robots_OnSentryBusterExplode(int client)
{
	float range = c_sentrybuster_default_range.FloatValue;
	RobotPlayer rp = RobotPlayer(client);

	Action result;
	Call_StartForward(g_OnSentryBusterDetonate);
	Call_PushCell(client);
	Call_PushCell(g_eTemplates[rp.templateindex].pluginID);
	Call_PushCell(TF2_GetPlayerClass(client));
	Call_PushCell(g_eTemplates[rp.templateindex].index);
	Call_PushCell(g_eTemplates[rp.templateindex].type);
	Call_PushFloatRef(range);
	Call_Finish(result);

	if(result == Plugin_Continue || result == Plugin_Changed)
	{
		rp.OnBusterExplode();
		EmitGameSoundToAll("MVM.SentryBusterExplode", client);
		float origin[3];
		GetClientAbsOrigin(client, origin);
		CreateTemporaryParticleSystem(origin, "fluidSmokeExpl_ring_mvm", 6.5);
		CreateTemporaryParticleSystem(origin, "explosionTrail_seeds_mvm", 5.5);
		Buster_ApplyDamageToClients(client, range);
		Buster_ApplyDamageToObjects(client, range);
	}
}

/**
 * Performs a simple Trace Ray between start and end positions
 * 
 * @param start     The start position
 * @param end       The end position
 * @param buster    Sentry buster index
 * @param target	Sentry buster target entity
 * @return          TRUE if the trace hit the target entity
 */
bool Buster_Trace(float start[3], float end[3], int buster, int target)
{
	Handle trace = null;
	trace = TR_TraceRayFilterEx(start, end, MASK_SHOT, RayType_EndPoint, TraceFilter_SentryBuster, target);
	bool hit = TR_DidHit(trace);

#if defined _bwrr_debug_
	PrintToChat(buster, "[BUSTER] Tracing to (%.2f,%.2f,%.2f). Did Hit: %s", end[0], end[1], end[2], hit ? "Yes" : "No");
	TE_SendBeam(start, end, {255,0,0,255}, buster, 30.0);
	if(hit)
	{
		int ent = TR_GetEntityIndex(trace);
		if(IsValidEntity(ent))
		{
			char classname[64];
			GetEntityClassname(ent, classname, sizeof(classname));
			PrintToChat(buster, "[BUSTER] Hit entity \"%s #%i\"", classname, ent);
		}
	}
#endif

	delete trace;
	return hit;
}

void Buster_ApplyDamageToClients(int buster, const float maxrange)
{
	float origin[3], target[3];
	TFTeam team;
	GetClientEyePosition(buster, origin);


	for(int i = 1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;

		if(i == buster)
		{
			SetEntProp(buster, Prop_Data, "m_takedamage", DAMAGE_YES);
			SDKHooks_TakeDamage(buster, 0, 0, float(4 * TF2Util_GetPlayerMaxHealthBoost(i)), DMG_BLAST);
			continue;
		}

		team = TF2_GetClientTeam(i);
		GetClientEyePosition(i, target);
		
		switch(team)
		{
			case TFTeam_Red:
			{
				if(GetVectorDistance(origin, target) <= maxrange && Buster_Trace(origin, target, buster, i)) // No obstruction
				{
					SDKHooks_TakeDamage(i, buster, buster, float(4 * TF2Util_GetPlayerMaxHealthBoost(i)), DMG_BLAST, TF2Util_GetPlayerLoadoutEntity(buster, TFWeaponSlot_Melee, true));
				}
			}
			case TFTeam_Blue:
			{
				if(GetVectorDistance(origin, target) <= maxrange && Buster_Trace(origin, target, buster, i)) // No obstruction
				{
					SDKHooks_TakeDamage(i, 0, 0, float(4 * TF2Util_GetPlayerMaxHealthBoost(i)), DMG_BLAST);
				}
			}
		}
	}
}

void Buster_ApplyDamageToObjects(int buster, const float maxrange)
{
	char szobjects[][] = { "obj_sentrygun", "obj_dispenser", "obj_teleporter" };
	float origin[3], target[3];
	GetClientEyePosition(buster, origin);

	int entity;

	for(int i = 0;i < sizeof(szobjects);i++)
	{
		entity = INVALID_ENT_REFERENCE;
		while((entity = FindEntityByClassname(entity, szobjects[i])) != INVALID_ENT_REFERENCE)
		{
			if(GetEntProp(entity, Prop_Send, "m_iTeamNum") == view_as<int>(TFTeam_Red))
			{
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", target);
				target[2] += 24.0;

				if(GetVectorDistance(origin, target) <= maxrange && Buster_Trace(origin, target, buster, entity))
				{
					SDKHooks_TakeDamage(entity, buster, buster, 10000.0, DMG_BLAST, TF2Util_GetPlayerLoadoutEntity(buster, TFWeaponSlot_Melee, true));
				}
			}			
		}
	}
}