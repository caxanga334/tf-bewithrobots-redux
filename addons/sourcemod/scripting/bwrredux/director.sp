// AI Director

enum Strategy
{
	Strategy_None = 0, // No strategy
	Strategy_WaitForRED, // RED team is having a hard time defending, wait a bit
	Strategy_Attack, // Attack robots
	Strategy_Support, // Support robots
	Strategy_Gatebot, // Dispatch gatebots
	Strategy_Boss, // Dispatch bosses
	Strategy_Mission // Send a mission
};

char g_sStrategyNames[][] = {
	"None",
	"Wait for RED",
	"Attack",
	"Support",
	"Gatebot",
	"Boss",
	"Mission"
}

enum MissionType
{
	Mission_None = 0,
	Mission_Engineer,
	Mission_Sniper,
	Mission_Spy,
	Mission_SentryBuster
};

enum struct MissionManager
{
	MissionType last;
	MissionType next;
	float engineer;
	float sniper;
	float spy;
	float sentrybuster;
}

enum struct GiantManager
{
	float cooldown;
}

enum struct BossManager
{
	float cooldown;
}

enum struct SpawnPointManager
{
	int lastspawnpoint;
	int lastclient;
	float lastspawntime;
	bool shared;
}

enum struct PlayerDataRecorder
{
	int damage;
	int kills;
	float timer;
}
PlayerDataRecorder g_PlayerData[MAXPLAYERS + 1];

enum struct edirector
{
	int resources;
	int nextrobotindex;
	Handle timer;
	Strategy currentstrategy;
	Strategy idealstrategy;
	Strategy laststrategy;
	Strategy failedstrategy;
	float nextstrategychange;
	float spawncooldown;
	float gatebotcooldown;
	MissionManager mm;
	GiantManager gm;
	BossManager bm;
	SpawnPointManager spm;
	ArrayList queue;
}
edirector g_eDirector;

// Add resources to the director resource pool
void Director_AddResources(int amount)
{
	g_eDirector.resources += amount;
}

// Subtracts resources to the director resource pool
void Director_SubtractResources(int amount)
{
	g_eDirector.resources -= amount;
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
 * Checks if there are ANY robot players waiting to be spawned
 * 
 * @return     Number of players waiting to be spawned
 */
int Director_PlayersInQueue()
{
	int counter = 0;
	for(int i = 1;i < MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;

		RobotPlayer rp = RobotPlayer(i);

		if(rp.isrobot)
		{
			if(TF2_GetClientTeam(i) == TFTeam_Spectator)
			{
				counter++;
			}
		}
	}

	return counter;
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

// Checks if the AI director is allowed to spawn players
bool Director_CanSpawnPlayers()
{
	int numbots = 0;

	for(int i = 1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;

		if(IsFakeClient(i) && TF2_GetClientTeam(i) == TFTeam_Blue)
		{
			numbots++;
		}
	}

	if(c_director_wait_for_bots.BoolValue)
	{
		return numbots > 0;
	}

	return true;
}

void Director_ComputeDistances(float &hatchdist, float &spawndist)
{
	ArrayList bombs = new ArrayList();
	ArrayList spawns = new ArrayList();

	CollectBombs(bombs, view_as<int>(TFTeam_Blue));
	CollectSpawnPoints(spawns, view_as<int>(TFTeam_Blue));

	int targetbomb = GetBombClosestToHatch(bombs, hatchdist);
	float bombpos[3];

	if(targetbomb == INVALID_ENT_REFERENCE)
	{
		hatchdist = -1.0;
		spawndist = -1.0;
		delete bombs;
		delete spawns;
		return;
	}

	TF2_GetFlagPosition(targetbomb, bombpos);

	int spawnpoint = EntRefToEntIndex(spawns.Get(Math_GetRandomInt(0, spawns.Length - 1)));

	delete bombs;
	delete spawns;

	if(spawnpoint != INVALID_ENT_REFERENCE)
	{
		CBaseEntity spawn = CBaseEntity(spawnpoint);
		float spawnpos[3];
		spawn.GetAbsOrigin(spawnpos);
		spawndist = GetVectorDistance(bombpos, spawnpos);
	}
}

void Director_SpawnPlayers(int quantity, const bool shared = false, const bool gatebot = false)
{
#if defined _bwrr_debug_
	PrintToChatAll("[AI Direction] Starting spawn process for %i players.", quantity);
#endif

	float min = c_director_spawn_cooldown_min.FloatValue;
	float max = c_director_spawn_cooldown_max.FloatValue;
	float percent = TF2MvM_GetWavePercent();
	float delay = Math_Range(min, max, percent, true);
	g_eDirector.spawncooldown = GetGameTime() + delay;

	for(int i = 0;i < quantity;i++)
	{
		if(Director_PlayersInQueue() == 0)
			break;

		int client = Director_GetRandomPlayerInQueue();
		RobotPlayer rp = RobotPlayer(client);
		rp.lastspawntime = GetGameTime();
		rp.gatebot = gatebot;

		// Shared spawn point by spawning players
		if(shared && !g_eDirector.spm.shared)
		{
			g_eDirector.spm.shared = shared;
			ArrayList spawns = new ArrayList();
			CollectSpawnPoints(spawns, view_as<int>(TFTeam_Blue));
			FilterSpawnPointByHull(spawns, client);
			FilterSpawnPointsByNavMesh(spawns);
			int spawnpoint = SelectSpawnPointRandomly(spawns);

			if(spawnpoint != INVALID_ENT_REFERENCE)
			{
				g_eDirector.spm.lastclient = GetClientSerial(client);
				g_eDirector.spm.lastspawnpoint = spawnpoint;
				g_eDirector.spm.lastspawntime = GetGameTime();
			}

			delete spawns;

			#if defined _bwrr_debug_
			PrintToChat(client, "[AI Director] Using shared spawn point.");
			#endif
		}
		else if(!shared)
		{
			g_eDirector.spm.shared = shared;
		}

#if defined _bwrr_debug_
		PrintToChat(client, "[AI Direction] Spawning %L", client);
#endif

		TF2MvM_ChangeClientTeam(client, TFTeam_Blue);
		Director_SelectRobot(client, g_eDirector.nextrobotindex);
	}
}

/**
 * Gets the best threat player
 * 
 * @return     Threat client index
 */
int Director_GetThreat()
{
	int threat = 0;
	int score, bestscore = 0;

	for(int i = 1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;

		if(!IsPlayerAlive(i))
			continue;

		if(TF2_GetClientTeam(i) != TFTeam_Red)
			continue;

		score = g_PlayerData[i].damage + (g_PlayerData[i].kills * 1000);

		if(score > bestscore)
		{
			bestscore = score;
			threat = i;
		}
	}

	return threat;
}

// Checks if giant are allowed to spawn
bool Director_CanSpawnGiants()
{
	int humans = 0, bots = 0;
	GetGiantCount(humans, bots);

	if(humans >= c_giant_limit.IntValue) return false;

	return true;
}

/**
 * Checks if the given mission can be sent
 * 
 * @param mission     Mission to send
 * @return            TRUE if the given mission can be sent
 */
bool Director_CanSendMission(MissionType mission)
{
	switch(mission)
	{
		case Mission_Engineer: return g_eDirector.mm.engineer <= GetGameTime();
		case Mission_Sniper: return g_eDirector.mm.sniper <= GetGameTime();
		case Mission_Spy: return g_eDirector.mm.spy <= GetGameTime();
		case Mission_SentryBuster: return g_eDirector.mm.sentrybuster <= GetGameTime();
		default: return false;
	}
}

void Director_DispatchMission(MissionType mission, int quantity = 1, const bool shared = false)
{
	float min = c_director_mm_cooldown_min.FloatValue;
	float max = c_director_mm_cooldown_max.FloatValue;
	float percent = TF2MvM_GetWavePercent();
	float delay = Math_Range(min, max, percent, true);
	ArrayList robots = new ArrayList();

	g_eDirector.mm.last = mission;

	switch(mission)
	{
		case Mission_Engineer:
		{
			g_eDirector.mm.engineer = GetGameTime() + delay;
			Robots_CollectTemplates(robots, g_eDirector.resources, _, BWRR_RobotType_Normal, BWRR_Role_Engineer);
			if(Director_CanSpawnGiants()) { Robots_CollectTemplates(robots, g_eDirector.resources, _, BWRR_RobotType_Giant, BWRR_Role_Engineer); }
		}
		case Mission_Sniper:
		{
			g_eDirector.mm.sniper = GetGameTime() + delay;
			Robots_CollectTemplates(robots, g_eDirector.resources, _, BWRR_RobotType_Normal, BWRR_Role_Sniper);
			if(Director_CanSpawnGiants()) { Robots_CollectTemplates(robots, g_eDirector.resources, _, BWRR_RobotType_Giant, BWRR_Role_Sniper); }
		}
		case Mission_Spy: 
		{
			Robots_CollectTemplates(robots, g_eDirector.resources, _, BWRR_RobotType_Normal, BWRR_Role_Spy);
			if(Director_CanSpawnGiants()) { Robots_CollectTemplates(robots, g_eDirector.resources, _, BWRR_RobotType_Giant, BWRR_Role_Spy); }
			g_eDirector.mm.spy = GetGameTime() + delay;
		}
		case Mission_SentryBuster:
		{
			Robots_CollectTemplates(robots, g_eDirector.resources, _, BWRR_RobotType_Buster);
			g_eDirector.mm.sentrybuster = GetGameTime() + delay;
		}
	}

	Robots_FilterByCanAfford(robots, g_eDirector.resources, quantity);

	// Abort, no robots to spawn
	if(robots.Length == 0)
	{
		delete robots;
		return;
	}

	g_eDirector.nextrobotindex = Robots_SelectByHighestCost(robots);
	delete robots;
	Director_SpawnPlayers(quantity, shared);
}

void Director_DispatchAttack(int quantity = 1, const bool shared = false)
{
	ArrayList robots = new ArrayList();
	Robots_CollectTemplates(robots, g_eDirector.resources, _, BWRR_RobotType_Normal, BWRR_Role_Attack);
	if(Director_CanSpawnGiants()) { Robots_CollectTemplates(robots, g_eDirector.resources, _, BWRR_RobotType_Giant, BWRR_Role_Attack); }
	Robots_FilterByCanAfford(robots, g_eDirector.resources, quantity);

	// Abort, no robots to spawn
	if(robots.Length == 0)
	{
		delete robots;
		return;
	}

	g_eDirector.nextrobotindex = Robots_SelectByHighestCost(robots);
	delete robots;
	Director_SpawnPlayers(quantity, shared);
}

void Director_DispatchGatebot(int quantity = 1, const bool shared = false)
{
	ArrayList robots = new ArrayList();
	Robots_CollectTemplates(robots, g_eDirector.resources, _, BWRR_RobotType_Normal, BWRR_Role_Attack);
	Robots_CollectTemplates(robots, g_eDirector.resources, _, BWRR_RobotType_Normal, BWRR_Role_AttackSupport);
	Robots_CollectTemplates(robots, g_eDirector.resources, _, BWRR_RobotType_Normal, BWRR_Role_Support);
	Robots_CollectTemplates(robots, g_eDirector.resources, _, BWRR_RobotType_Normal, BWRR_Role_Healer);
	if(Director_CanSpawnGiants())
	{
		Robots_CollectTemplates(robots, g_eDirector.resources, _, BWRR_RobotType_Giant, BWRR_Role_Attack);
		Robots_CollectTemplates(robots, g_eDirector.resources, _, BWRR_RobotType_Giant, BWRR_Role_AttackSupport);
		Robots_CollectTemplates(robots, g_eDirector.resources, _, BWRR_RobotType_Giant, BWRR_Role_Support);
		Robots_CollectTemplates(robots, g_eDirector.resources, _, BWRR_RobotType_Giant, BWRR_Role_Healer);		
	}
	Robots_FilterByCanAfford(robots, g_eDirector.resources, quantity);

	// Abort, no robots to spawn
	if(robots.Length == 0)
	{
		delete robots;
		return;
	}

	g_eDirector.nextrobotindex = Robots_SelectByHighestCost(robots);
	delete robots;
	Director_SpawnPlayers(quantity, shared, true);
}

// Director think function
public Action Director_Think(Handle timer)
{
	if(!IsMvMWaveRunning())
	{
		g_eDirector.timer = null;
		return Plugin_Stop;
	}

	Director_AddResources(RoundToFloor(Math_Range(c_director_rpt_min.FloatValue, c_director_rpt_max.FloatValue, TF2MvM_GetWavePercent())));

	DirectorBehavior_DecideIdealStrategy();

	if(g_eDirector.nextstrategychange <= GetGameTime() && g_eDirector.idealstrategy != g_eDirector.currentstrategy)
	{
		#if defined _bwrr_debug_
		PrintToChatAll("[AI Director] Strategy changed from \"%s\" to \"%s\"", g_sStrategyNames[g_eDirector.currentstrategy], g_sStrategyNames[g_eDirector.idealstrategy]);
		#endif
		g_eDirector.laststrategy = g_eDirector.currentstrategy;
		g_eDirector.currentstrategy = g_eDirector.idealstrategy;
		g_eDirector.nextstrategychange = GetGameTime() + Math_Range(5.0, 22.0, TF2MvM_GetWavePercent(), true); // delay between 5 to 22 seconds, based on wave percentage
	}
	else if(g_eDirector.failedstrategy > Strategy_None && g_eDirector.failedstrategy == g_eDirector.currentstrategy)
	{
		if(g_eDirector.laststrategy > Strategy_None)
		{
			#if defined _bwrr_debug_
			PrintToChatAll("[AI Director] Strategy \"%s\" failed. Reverting to \"%s\".", g_sStrategyNames[g_eDirector.failedstrategy], g_sStrategyNames[g_eDirector.laststrategy]);
			#endif
			g_eDirector.currentstrategy = g_eDirector.laststrategy;
		}
	}

	// No strategy selected or waiting for RED, skip
	if(g_eDirector.currentstrategy <= Strategy_WaitForRED)
		return Plugin_Continue;

	// Spawn in cooldown, skip
	if(g_eDirector.spawncooldown > GetGameTime())
		return Plugin_Continue;

	int inqueue = Director_PlayersInQueue();

	// No players to spawn, skip
	if(inqueue == 0)
		return Plugin_Continue;

	if(!Director_CanSpawnPlayers())
		return Plugin_Continue;

	// Handle player spawns here
	switch(g_eDirector.currentstrategy)
	{
		case Strategy_Mission:
		{
			if(g_eDirector.mm.next == Mission_Sniper || g_eDirector.mm.next == Mission_Spy)
			{
				if(Director_GetNumberofBLUPlayers() >= 3)
				{
					if(inqueue >= 2) // When there are 3 or more players in BLU team, wait for at least 2 dead human players to spawn snipers or spies
					{
						Director_DispatchMission(g_eDirector.mm.next, inqueue, true);
						return Plugin_Continue;
					}
				}
				else
				{
					Director_DispatchMission(g_eDirector.mm.next);
					return Plugin_Continue;
				}
			}
			else if(g_eDirector.mm.next == Mission_Engineer)
			{
				if(TF2_GetNumPlayersAsClass(TFClass_Engineer, TFTeam_Blue, true, true) < c_engineer_limit.IntValue)
				{
					Director_DispatchMission(Mission_Engineer, Math_Clamp(inqueue, 1, c_engineer_limit.IntValue));
					return Plugin_Continue;
				}
				else
				{
					g_eDirector.failedstrategy = g_eDirector.currentstrategy;
				}
			}
		}
		case Strategy_Attack:
		{
			Director_DispatchAttack();
			return Plugin_Continue;
		}
		case Strategy_Gatebot:
		{
			Director_DispatchGatebot();
			return Plugin_Continue;
		}
		case Strategy_Support, Strategy_Boss:
		{
			Director_DispatchAttack();
			return Plugin_Continue;			
		}
	}

	return Plugin_Continue;
}

/**
 * Part of the AI Director Behavior System
 * Decides the best strategy for the current senario
 */
void DirectorBehavior_DecideIdealStrategy()
{
	int alivered = 0;

	for(int i = 1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;

		switch(TF2_GetClientTeam(i))
		{
			case TFTeam_Red:
			{
				if(IsPlayerAlive(i))
				{
					alivered++;
				}
			}
		}
	}

#if defined _bwrr_debug_
	alivered = 99;
#endif

	if(alivered == 0)
	{
		g_eDirector.idealstrategy = Strategy_WaitForRED;
		return;
	}

	if(g_eGateManager.available)
	{
		if(g_eDirector.gatebotcooldown <= GetGameTime() && g_eDirector.laststrategy != Strategy_Gatebot)
		{
			g_eDirector.gatebotcooldown = GetGameTime() + Math_Range(1.0, 30.0, TF2MvM_GetWavePercent(), true) + Math_GetRandomFloat(5.0, 20.0);
			g_eDirector.idealstrategy = Strategy_Gatebot;
			return;
		}
	}

	int threat = Director_GetThreat();

	if(threat > 0)
	{
		TFClassType threatclass = TF2_GetPlayerClass(threat);

		switch(threatclass)
		{
			case TFClass_Sniper:
			{
				if(Director_CanSendMission(Mission_Spy))
				{
					g_eDirector.idealstrategy = Strategy_Mission;
					g_eDirector.mm.next = Mission_Spy;
					return;
				}
			}
			case TFClass_Soldier, TFClass_DemoMan, TFClass_Pyro, TFClass_Heavy:
			{
				if(Director_CanSendMission(Mission_Sniper))
				{
					g_eDirector.idealstrategy = Strategy_Mission;
					g_eDirector.mm.next = Mission_Sniper;
					return;
				}
			}
			default: g_eDirector.idealstrategy = Strategy_Attack;
		}
	}


	// hatchdist = distance between the bomb closest to the bomb hatch and the hatch itself
	// spawndist = distance between the bomb closest to the bomb hatch and a random BLU team spawn point
	float hatchdist, spawndist;
	Director_ComputeDistances(hatchdist, spawndist);

	if(hatchdist > 3000.0)
	{
		g_eDirector.idealstrategy = Strategy_Attack;
	}

	if(spawndist > 1000.0 && Director_CanSendMission(Mission_Engineer))
	{
		g_eDirector.idealstrategy = Strategy_Mission;
		g_eDirector.mm.next = Mission_Engineer;
	}

	return;
}

void Director_OnWaveStart()
{
	Director_SetResources(c_director_initial_resources.IntValue);
	TF2_GetBombHatchPosition(true);

	delete g_eDirector.timer;
	g_eDirector.timer = CreateTimer(1.0, Director_Think, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

	Director_ResetData();
}

void Director_OnWaveEnd()
{
	delete g_eDirector.timer;
}

void Director_OnWaveFailed()
{
	delete g_eDirector.timer;
	CreateTimer(0.3, DirectorTimer_ClearPlayers, _, TIMER_FLAG_NO_MAPCHANGE);
}

/**
 * Resets per wave data
 */
void Director_ResetData()
{
	float min = c_director_mm_cooldown_min.FloatValue;
	float max = c_director_mm_cooldown_max.FloatValue;
	float percent = TF2MvM_GetWavePercent();
	float delay = Math_Range(min, max, percent, true);

	g_eDirector.currentstrategy = Strategy_None;
	g_eDirector.idealstrategy = Strategy_None;
	g_eDirector.laststrategy = Strategy_None;
	g_eDirector.failedstrategy = Strategy_None;
	g_eDirector.spawncooldown = GetGameTime() + 5.0;
	g_eDirector.nextstrategychange = GetGameTime() + 1.0;
	g_eDirector.mm.next = Mission_None;
	g_eDirector.mm.last = Mission_None;
	g_eDirector.mm.engineer = GetGameTime() + delay;
	g_eDirector.mm.sniper = GetGameTime() + delay;
	g_eDirector.mm.spy = GetGameTime() + delay;
	g_eDirector.mm.sentrybuster = GetGameTime() + delay;
	g_eDirector.gm.cooldown = GetGameTime();
	g_eDirector.bm.cooldown = GetGameTime();
	g_eDirector.spm.lastclient = 0;
	g_eDirector.spm.lastspawnpoint = INVALID_ENT_REFERENCE;
	g_eDirector.spm.lastspawntime = GetGameTime();

	for(int i = 0;i < sizeof(g_PlayerData);i++)
	{
		g_PlayerData[i].damage = 0;
		g_PlayerData[i].kills = 0;
		g_PlayerData[i].timer = 0.0;
	}	
}

void Director_TeleportPlayer(int client)
{
	int entity = INVALID_ENT_REFERENCE;

	// Shared spawn point? (And calculated at maximum 5 seconds ago)
	if(g_eDirector.spm.shared && (g_eDirector.spm.lastspawntime + 5.0) >= GetGameTime() && IsValidEntity(g_eDirector.spm.lastspawnpoint))
	{
		entity = g_eDirector.spm.lastspawnpoint;
	}
	else
	{
		ArrayList spawns = new ArrayList();
		CollectSpawnPoints(spawns, view_as<int>(TFTeam_Blue));
		FilterSpawnPointByHull(spawns, client);
		FilterSpawnPointsByNavMesh(spawns);
		entity = SelectSpawnPointRandomly(spawns);
		delete spawns;
	}

	char targetname[64];
	float destination[3], angles[3];
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
	FilterNavAreasBySpawnRoom(areas);

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

bool Director_TeleportEngineer(int client, float origin[3], float angles[3])
{
	ArrayList bombs = new ArrayList();
	if(CollectBombs(bombs, view_as<int>(TFTeam_Blue)) == 0)
	{
		delete bombs;
		return false;
	}

	float distance = 0.0;
	int target_bomb = GetBombClosestToHatch(bombs, distance);

	if(target_bomb == INVALID_ENT_REFERENCE)
	{
		delete bombs;
		return false;
	}

	delete bombs;
	float bomb_pos[3];
	TF2_GetFlagPosition(target_bomb, bomb_pos);

	ArrayList areas = new ArrayList();

	if(!CollectNavAreas(areas, bomb_pos, c_engineer_distance.FloatValue * 3.0, 750.0, 1000.0))
	{
		delete areas;
		return false;
	}

	FilterNavAreasBySpawnRoom(areas);
	FilterNavAreasByDistance(areas, bomb_pos, c_engineer_distance.FloatValue, c_engineer_distance.FloatValue * 3.25);
	FilterNavAreasByTrace(areas, client);
	FilterNavAreasByLOS(areas, TFTeam_Red);

	if(areas.Length == 0)
	{
		delete areas;
		return false;
	}

	CNavArea final = TheNavMesh.GetNavAreaByID(areas.Get(Math_GetRandomInt(0, areas.Length - 1)));
	delete areas;

	final.GetCenter(origin);
	origin[2] += 15.0;
	GetAngleTorwardsPoint(origin, bomb_pos, angles);
	angles[0] = 0.0;
	angles[2] = 0.0;

	return true;
}

void Director_OnPlayerDeath(int victim, int killer)
{
	if(!IsValidClient(victim))
		return;
	
	RobotPlayer rp1 = RobotPlayer(victim);

	TFTeam team1 = TF2_GetClientTeam(victim);
	if(team1 == TFTeam_Blue)
	{
		if(!IsFakeClient(victim)) // human BLU was killed
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
			CreateTimer(0.250, DirectorTimer_OnRobotDeath, GetClientSerial(victim), TIMER_FLAG_NO_MAPCHANGE);
		}

		if(!IsValidClient(killer))
			return;

		if(TF2_GetClientTeam(killer) == TFTeam_Red)
		{
			if(g_PlayerData[killer].timer <= GetGameTime())
			{
				g_PlayerData[killer].kills = 1;
				g_PlayerData[killer].timer = GetGameTime() + 90.0;
			}
			else
			{
				g_PlayerData[killer].kills++;
				g_PlayerData[killer].timer = GetGameTime() + 90.0;				
			}			
		}
	}

	if(!IsValidClient(killer))
		return;
	
	TFTeam team2 = TF2_GetClientTeam(killer);

	// BLU player killed a RED player
	if(team1 == TFTeam_Red && team2 == TFTeam_Blue)
	{
		Director_SubtractResources(500); // Subtract resources from the director
	}
}

void Director_GiveInventory(int client)
{
	if(client && TF2_GetClientTeam(client) == TFTeam_Blue)
	{
		RobotPlayer rp = RobotPlayer(client);
		if(rp.templateindex >= 0)
		{
			TF2_ClearClient(client, true, true); // Clear player first

			Call_StartForward(g_OnInventoryRequest);
			Call_PushCell(client);
			Call_PushCell(g_eTemplates[rp.templateindex].pluginID);
			Call_PushCell(TF2_GetPlayerClass(client));
			Call_PushCell(g_eTemplates[rp.templateindex].index);
			Call_PushCell(g_eTemplates[rp.templateindex].type);
			Call_Finish();

			if(rp.gatebot)
			{
				GiveGatebotHat(client, TF2_GetPlayerClass(client), true);
				TF2Attrib_SetByName(client, "cannot pick up intelligence", 1.0);
			}
		}
		else
		{
			TF2_ClearClient(client, false, true); // Own loadout
		}
	}
}

// Called on player death
Action DirectorTimer_OnRobotDeath(Handle timer, any data)
{
	int client =  GetClientFromSerial(data);

	if(client)
	{
		RobotPlayer rp = RobotPlayer(client);

		if(rp.hasloopsound)
		{
			rp.StopLoopSound();
		}

		Director_RemoveClientFromBLU(client);
	}

	return Plugin_Stop;
}

// Called on player death
Action DirectorTimer_ClearPlayers(Handle timer)
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

	return Plugin_Stop;
}

// Called 500 ms after player spawn
Action DirectorTimer_OnRobotSpawnLate(Handle timer, any data)
{
	int client =  GetClientFromSerial(data);

	if(client && TF2_GetClientTeam(client) == TFTeam_Blue)
	{
		Robots_SetLoopSound(client);
		RobotPlayer rp = RobotPlayer(client);

		if(rp.gatebot)
		{
			PrintToChat(client, "You are a gatebot.");
		}
	}

	return Plugin_Stop;
}

void DirectorFrame_OnRobotDeath(int serial)
{
	int client = GetClientFromSerial(serial);

	if(client)
	{
		switch(TF2_GetPlayerClass(client))
		{
			case TFClass_Engineer: DecoupleAllObjectsFromClient(client);
		}
	}	
}

// Called to select a robot for the player
void Director_SelectRobot(int client, int template)
{
	RobotPlayer rp = RobotPlayer(client);
	RequestFrame(DirectorFrame_PreSpawn, GetClientSerial(client));

	if(template >= 0)
	{
		Robots_OnRobotSpawn(template);
		Director_SubtractResources(Robots_GetCost(template));
		rp.SetRobot(g_eTemplates[template].type, template);

#if defined _bwrr_debug_
		PrintToChat(client, "[AI Director] Your robot cost me %i resources. I now have %i resources.", Robots_GetCost(template), g_eDirector.resources);
#endif
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

		if(flag != INVALID_ENT_REFERENCE && attribute == Address_Null && rp.templateindex >= 0 && !rp.gatebot)
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
		float origin[3], angles[3];

		if(Director_TeleportEngineer(client, origin, angles))
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
				TE_SetupTFParticleEffect("teleported_blue", origin);
				TE_SendToAll(0.125);
				TE_SetupTFParticleEffect("teleported_mvm_bot", origin);
				TE_SendToAll(0.125);
				TF2_PushAllPlayers(origin, 400.0, 500.0, view_as<int>(TFTeam_Red)); // Push players
				rp.inspawn = false;
			}
		}
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
			float pos[3], angles[3] = {0.0, ...}, origin[3];
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
				GetClientAbsOrigin(client, origin);
				GetAngleTorwardsPoint(origin, pos, angles);
	
				if(result == Plugin_Continue || result == Plugin_Changed)
				{
					TeleportEntity(client, pos, angles, {0.0, 0.0, 0.0});
					rp.inspawn = false;
				}					
			}
		}
	}
}

