// boss system

// boss wave data
enum BossState
{
	BossState_Unavailable = 0, // Boss is not available for the current wave
	BossState_Available, // Boss is available for the current wave
	BossState_InPlay, // Boss is currently in play
	BossState_Defeated, // Boss was defeated
};

BossState g_BossState; // Current Boss State
char g_strBossList[512]; // List of bosses to use
int g_BossClient; // Client index of the current boss
int g_BossHealthCap; // Base boss health
int g_BossMinRed; // Minimum players on RED team to allow boss spawning
int g_BossHPCapMinRed; // Minimum players on RED to bypass health cap
float g_BossTimer; // Timer
float g_BossRespawnDelay; // Respawn delay for boss

// boss data
// Prefix - g_TBoss
bool g_TBossGatebot; // Is this boss a gatebot?
char g_TBossName[MAXLEN_CONFIG_STRING];
int g_TBossWeaponIndex[MAX_ROBOTS_WEAPONS];
int g_TBossBitsAttribs;
int g_TBossBaseHealth;
int g_TBossPlrHealth;
float g_TBossScale;
float g_TBossHPRegen; // HP regen per player
TFClassType g_TBossClass;
ArrayList g_TBossWeaponClass;
ArrayList g_TBossCharAttrib;
ArrayList g_TBossCharAttribValue;
ArrayList g_TBossWeapAttrib[MAX_ROBOTS_WEAPONS];
ArrayList g_TBossWeapAttribValue[MAX_ROBOTS_WEAPONS];

int Boss_ComputeHealth()
{
	int iInRed = GetTeamClientCount(2);
	int iHealth = g_TBossBaseHealth + (g_TBossPlrHealth * iInRed);
	
	if( iInRed < g_BossHPCapMinRed ) // Not enough players in RED to bypass health cap
	{
		if( iHealth > g_BossHealthCap ) // Check if the boss health is greater than the cap
		{
			iHealth = g_BossHealthCap;
		}
	}
	
	return iHealth;
}

// Sets the robot health
void Boss_SetHealth(int client)
{
	int iHealth = Boss_ComputeHealth();
	float flHealth, flregen;
	int iClassHealth = GetClassBaseHealth(g_TBossClass);
	
	
	flHealth = float(iHealth - iClassHealth);
	flregen = g_TBossHPRegen * GetTeamClientCount(2);
	TF2Attrib_SetByName(client, "hidden maxhealth non buffed", flHealth);
	
	if( flregen > 0.5 )
		TF2Attrib_SetByName(client, "health regen", flregen);
	
	SetEntProp(client, Prop_Send, "m_iHealth", iHealth);
	SetEntProp(client, Prop_Data, "m_iHealth", iHealth);
}

void Boss_GetName(char[] name, int size)
{
	strcopy(name, size, g_TBossName);
}

int Boss_GetClient()
{
	return g_BossClient;
}

float Boss_GetScale()
{
	return g_TBossScale;
}

bool Boss_IsGatebot()
{
	return g_TBossGatebot;
}

void Boss_Death()
{
	g_BossClient = -1;
	g_BossState = BossState_Defeated;
}

void Boss_SetupPlayer(int client)
{
	RoboPlayer rp = RoboPlayer(client);
	
	rp.Type = Bot_Boss;
	rp.Variant = 0;
	rp.Attributes = g_TBossBitsAttribs;
	rp.Class = g_TBossClass;
	rp.Gatebot = g_TBossGatebot;
	
	if(!IsGatebotAvailable()) {
		rp.Gatebot = false;
		g_TBossGatebot = false;
	}
	
	g_BossClient = client;
	g_BossState = BossState_InPlay;
}

void Boss_GiveInventory(int client)
{
	if( IsFakeClient(client) )
		return;

	int iWeapon;
	char buffer[255];
	
	TF2Attrib_RemoveAll(client);
	
	// Set Player Attributes
	if(g_TBossCharAttrib.Length > 0)
	{
		for(int i = 0;i < g_TBossCharAttrib.Length;i++)
		{
			g_TBossCharAttrib.GetString(i, buffer, sizeof(buffer));
			TF2Attrib_SetByName(client, buffer, g_TBossCharAttribValue.Get(i));
		}
	}

	// Spawn Weapons
	for(int i = 0;i < MAX_ROBOTS_WEAPONS;i++)
	{
		g_TBossWeaponClass.GetString(i, buffer, sizeof(buffer));
		if(strlen(buffer) > 3) // check if a weapon exists
		{
			iWeapon = SpawnWeapon(client, buffer, g_TBossWeaponIndex[i], 1, 6, IsWeaponWearable(buffer));
			if(g_TBossWeapAttrib[i].Length > 0) // Does this weapon have custom attributes?
			{
				for(int y = 0;y < g_TBossWeapAttrib[i].Length;y++)
				{
					g_TBossWeapAttrib[i].GetString(y, buffer, sizeof(buffer));
					TF2Attrib_SetByName(iWeapon, buffer, g_TBossWeapAttribValue[i].Get(y));
				}
			}
		}
	}
}

void Boss_Think()
{
	if( g_BossRespawnDelay < 1.0 ) { return; }

	switch( g_BossState )
	{
		case BossState_Defeated:
		{
			Boss_SelectRandom(g_BossRespawnDelay);
			g_BossState = BossState_Available;
		}
	}
}

bool Boss_CanSpawn()
{
	switch( g_BossState )
	{
		case BossState_Unavailable, BossState_InPlay, BossState_Defeated:
		{
			return false;
		}
		case BossState_Available:
		{
			if( GetTeamClientCount(2) >= g_BossMinRed ) // Enough players on RED;
			{
				if( GetGameTime() > g_BossTimer ) // Delay check
				{
					return true;
				}
			}
		}
	}
	
	return false;
}

void Boss_SelectRandom(float flDelay = 0.0)
{
	char strSelectedBoss[64];
	char splitBossProfile[32][64];
	int iBossCount;
	
	iBossCount = ExplodeString(g_strBossList, ",", splitBossProfile, sizeof(splitBossProfile), sizeof(splitBossProfile[]));
	g_BossTimer = GetGameTime() + flDelay;
	
	strcopy(strSelectedBoss, sizeof(strSelectedBoss), splitBossProfile[Math_GetRandomInt(0, iBossCount - 1)]);
	Boss_LoadProfile(strSelectedBoss);
}

void Boss_InitArrays()
{
	g_TBossWeaponClass = new ArrayList(ByteCountToCells(MAXLEN_CONFIG_STRING));
	g_TBossCharAttrib = new ArrayList(ByteCountToCells(MAXLEN_CONFIG_STRING));
	g_TBossCharAttribValue = new ArrayList();
	for(int x = 0;x < MAX_ROBOTS_WEAPONS;x++)
	{
		g_TBossWeapAttrib[x] = new ArrayList(ByteCountToCells(MAXLEN_CONFIG_STRING));
		g_TBossWeapAttribValue[x] = new ArrayList();
	}
}

void Boss_ClearArrays()
{
	g_BossClient = -1;

	g_TBossWeaponClass.Clear();
	g_TBossCharAttrib.Clear();
	g_TBossCharAttribValue.Clear();
	for(int x = 0;x < MAX_ROBOTS_WEAPONS;x++)
	{
		g_TBossWeapAttrib[x].Clear();
		g_TBossWeapAttribValue[x].Clear();
		g_TBossWeaponClass.PushString("");
	}	
}

void Boss_LoadWaveConfig()
{
	char mapname[64], buffer[256], wavenum[16], configfile[PLATFORM_MAX_PATH];
	float flDelay;
	
	g_BossState = BossState_Unavailable;
	Boss_ClearArrays();
	
	GetCurrentMap(buffer, sizeof(buffer));
	
	// Some servers might use workshop
	if( !GetMapDisplayName(buffer, mapname, sizeof(mapname)) )
	{
		strcopy(mapname, sizeof(mapname), buffer); // use the result from GetCurrentMap if this fails.
	}

	BuildPath(Path_SM, configfile, sizeof(configfile), "configs/bwrr/bosswaves/");
	Format(configfile, sizeof(configfile), "%s%s_server.cfg", configfile, mapname);
	
	if(!FileExists(configfile))
	{
		BuildPath(Path_SM, configfile, sizeof(configfile), "configs/bwrr/bosswaves/");
		Format(configfile, sizeof(configfile), "%s%s.cfg", configfile, mapname);
	}

	if(!FileExists(configfile))
	{
		LogMessage("Boss Wave Config file not found for map %s ( %s )", mapname, configfile);
		return;
	}
	
#if defined DEBUG_GENERAL
	LogMessage("Loading Boss Wave Config file: \"%s\".", configfile);
#endif
	
	KeyValues kv = new KeyValues("BossWaveConfig");
	kv.ImportFromFile(configfile);
	
	// Jump into the first subsection
	if (!kv.GotoFirstSubKey())
	{
		delete kv;
		return;
	}
	kv.GoBack();
	
	int iWave = OR_GetCurrentWave();
	int iWaveMax = OR_GetMaxWave();

	OR_GetMissionName(buffer, sizeof(buffer));
	if( kv.JumpToKey(buffer, false) ) // go to mission specific settings
	{
		
		FormatEx(wavenum, sizeof(wavenum), "wave%i", iWave);
		if( kv.JumpToKey(wavenum, false) )
		{
			g_BossState = BossState_Available;
			g_BossHealthCap = kv.GetNum("health_cap", 25000);
			g_BossHPCapMinRed = kv.GetNum("minred_nocap", 6);
			g_BossMinRed = kv.GetNum("minred", 4);
			flDelay = kv.GetFloat("delay", 60.0);
			g_BossRespawnDelay = kv.GetFloat("respawn_delay", 0.0);
			kv.GetString("bosses", g_strBossList, sizeof(g_strBossList));
#if defined DEBUG_GENERAL
			LogMessage("Found config for wave %i. Mission: %s", iWave, buffer);
#endif
		}
		else
		{
#if defined DEBUG_GENERAL
			LogMessage("Couldn't find config for wave %i. Mission: %s", iWave, buffer);
#endif
			delete kv;
			return;
		}
	}
	else if( kv.JumpToKey("default", false) )
	{
		if( iWave == iWaveMax ) // If using 'default', only enable bosses on the last wave
		{
			g_BossState = BossState_Available;
			g_BossHealthCap = kv.GetNum("health_cap", 25000);
			g_BossHPCapMinRed = kv.GetNum("minred_nocap", 6);
			g_BossMinRed = kv.GetNum("minred", 4);
			flDelay = kv.GetFloat("delay", 60.0);
			g_BossRespawnDelay = kv.GetFloat("respawn_delay", 0.0);
			kv.GetString("bosses", g_strBossList, sizeof(g_strBossList));
#if defined DEBUG_GENERAL
			LogMessage("Using default config. Wave: %i Mission: %s", iWave, buffer);
#endif
		}
		else
		{
			delete kv;
			return;
		}
	}
	
	delete kv;
	
	Boss_SelectRandom(flDelay);
}

// Load the selected boss profile
// Returns false on error.
bool Boss_LoadProfile(char[] bossfile)
{
	char filename[64], configfile[PLATFORM_MAX_PATH];
	char strBits[12][MAXLEN_CONFIG_STRING];
	int iNum, iBits = 0;
	
	FormatEx(filename, sizeof(filename), "%s.cfg", bossfile);

	BuildPath(Path_SM, configfile, sizeof(configfile), "configs/bwrr/bosses/");
	
	Format(configfile, sizeof(configfile), "%s%s", configfile, filename);
	
	if(!FileExists(configfile))
	{
		char mission[64];
		OR_GetMissionName(mission, sizeof(mission));
		LogError("File for boss \"%s\" at wave %i for mission \"%s\" could not be found. ( %s )", bossfile, OR_GetCurrentWave(), mission, configfile);
		g_BossState = BossState_Unavailable;
		return false;
	}
	
	Boss_ClearArrays(); // Need to clear arrays due to the new force boss command.
	
	KeyValues kv = new KeyValues("BossTemplate");
	kv.ImportFromFile(configfile);
	
	// Jump into the first subsection
	if (!kv.GotoFirstSubKey())
	{
		delete kv;
		return false;
	}
	kv.GoBack();
	
	char buffer[255];
	kv.GetString("name", g_TBossName, sizeof(g_TBossName), "undefined");
	kv.GetString("class", buffer, sizeof(buffer));
	g_TBossBaseHealth = kv.GetNum("health_base", 3000);
	g_TBossPlrHealth = kv.GetNum("health_player", 3500);
	g_TBossHPRegen = kv.GetFloat("health_regen", 10.0);
	g_TBossClass = TF2_GetClass(buffer);
	g_TBossScale = kv.GetFloat("scale", 1.9);
	g_TBossGatebot = !!kv.GetNum("gatebot", 0);
	kv.GetString("robotattributes", buffer, sizeof(buffer));
	
	iNum = ExplodeString(buffer, ",", strBits, sizeof(strBits), sizeof(strBits[]));
	for(int x = 0;x < iNum;x++)
	{
		for(int z = 0;z < sizeof(g_strValidAttribs);z++)
		{
			if(strcmp(strBits[x], g_strValidAttribs[z], false) == 0)
			{
				iBits += g_AttribValue[z];
				break;
			}
		}
	}
	g_TBossBitsAttribs = iBits;
	
	if(kv.JumpToKey("playerattributes"))
	{
		kv.GetSectionName(buffer, sizeof(buffer));
		if(kv.GotoFirstSubKey(false))
		{
			do
			{ // Store Player Attributes
				kv.GetSectionName(buffer, sizeof(buffer)); // Get Attribute Name
				g_TBossCharAttrib.PushString(buffer); // Attribute Name
				g_TBossCharAttribValue.Push(kv.GetFloat("")); // Attribute Value
			} while(kv.GotoNextKey(false));
			kv.GoBack();
		}
		kv.GoBack();
	}
	
	for(int i = 0;i < sizeof(g_strWeaponsKey);i++) // Read Weapons
	{
		if(kv.JumpToKey(g_strWeaponsKey[i]))
		{
			kv.GetString("classname", buffer, sizeof(buffer), "");
			g_TBossWeaponClass.SetString(i, buffer); // Store Weapon Classname
			g_TBossWeaponIndex[i] = kv.GetNum("index"); // Store Weapon Definition Index
			
			if(kv.GotoFirstSubKey())
			{
				if(kv.GotoFirstSubKey(false)) // Read Weapon's Attributes
				{
					do
					{
						kv.GetSectionName(buffer, sizeof(buffer));
						g_TBossWeapAttrib[i].PushString(buffer); // Store Attribute Name
						g_TBossWeapAttribValue[i].Push(kv.GetFloat("")); // Store Attribute Value
					} while(kv.GotoNextKey(false));
					kv.GoBack();
				}
				kv.GoBack();
			}
			kv.GoBack();
		}			
	}
	
	delete kv;
	return true;
}