// sentry buster

char g_TBusterName[MAXLEN_CONFIG_STRING];
int g_TBusterHealth;
int g_TBusterAttribBits;
float g_TBusterScale;
float g_TBusterExploRadius;
ArrayList g_TBusterCharAttrib;
ArrayList g_TBusterCharAttribValue;

void Buster_InitArrays()
{
	g_TBusterCharAttrib = new ArrayList(ByteCountToCells(MAXLEN_CONFIG_STRING));
	g_TBusterCharAttribValue = new ArrayList(ByteCountToCells(MAXLEN_CONFIG_STRING));
}

void Buster_ClearArrays()
{
	g_TBusterCharAttrib.Clear();
	g_TBusterCharAttribValue.Clear();
}

/****************************************************
					SENTRY BUSTER
*****************************************************/

void SentryBuster_Explode(int client)
{
	if( !IsPlayerAlive(client) )
		return;
		
	RoboPlayer rp = RoboPlayer(client);
	
	if(rp.Detonating) // Buster is already detonating
		return;
	
	rp.Detonating = true;
	rp.BusterTime = GetGameTime() + 1.98000;
	FakeClientCommand(client, "taunt"); // Force taunt in case the detonation was called by pressing mouse 1
	float BusterPosVec[3];
	GetClientAbsOrigin(client, BusterPosVec);
	EmitGameSoundToAll("MVM.SentryBusterSpin", client, SND_NOFLAGS, client, BusterPosVec);
	SetEntProp( client, Prop_Data, "m_takedamage", 0, 1 );
}

void SentryBuster_CreateExplosion(int client)
{
	float flExplosionPos[3];
	float radius = Buster_GetExplosionRadius();
	GetClientAbsOrigin(client, flExplosionPos );
	int iWeapon = GetFirstAvailableWeapon(client);
	
	if(GameRules_GetRoundState() == RoundState_RoundRunning)
	{
		int i;
		for( i = 1; i <= MaxClients; i++ ) {
			if( i != client && IsValidClient(i) && IsPlayerAlive(i) ) {
				if(CanSeeTarget(client, i, radius)) {
					DealDamage(i, client, client, 10000.0, DMG_BLAST, iWeapon);
				}
			}
		}

		static const char strObjects[3][] = {"obj_sentrygun", "obj_dispenser", "obj_teleporter"};
		for(int o = 0; o < sizeof(strObjects); o++)
		{
			i = -1;
			while((i = FindEntityByClassname(i, strObjects[o])) != -1) {
				if(GetEntProp( i, Prop_Send, "m_iTeamNum" ) != view_as<int>(TFTeam_Blue) && !GetEntProp(i, Prop_Send, "m_bCarried") && !GetEntProp(i, Prop_Send, "m_bPlacing")) {
					if(CanSeeTarget(client, i, radius)) {
						DealDamage(i, client, client, 10000.0, DMG_BLAST, iWeapon);
					}
				}
			}
		}
	}
	
	CreateParticle(flExplosionPos, "fluidSmokeExpl_ring_mvm", 6.5);
	CreateParticle(flExplosionPos, "explosionTrail_seeds_mvm", 5.5);	//fluidSmokeExpl_ring_mvm  explosionTrail_seeds_mvm
	
	ForcePlayerSuicide( client );
	EmitGameSoundToAll("MVM.SentryBusterExplode", client, SND_NOFLAGS, client, flExplosionPos);
	CreateTimer(0.05, Timer_RemoveBody, client, TIMER_FLAG_NO_MAPCHANGE);
	TF2_SpeakConcept(MP_CONCEPT_MVM_SENTRY_BUSTER_DOWN, view_as<int>(TFTeam_Red), "");
}

bool CanSeeTarget(int iEntity,int iOther, float flMaxDistance = 0.0)
{
	if( iEntity <= 0 || iOther <= 0 || !IsValidEntity(iEntity) || !IsValidEntity(iOther) )
		return false;
	
	float vecStart[3], vecStartMaxs[3], vecTarget[3], vecTargetMaxs[3], vecEnd[3];
	
	GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", vecStart);
	GetEntPropVector(iEntity, Prop_Send, "m_vecMaxs", vecStartMaxs);
	GetEntPropVector(iOther, Prop_Data, "m_vecOrigin", vecTarget);
	GetEntPropVector(iOther, Prop_Send, "m_vecMaxs", vecTargetMaxs);
	
	vecStart[2] += vecStartMaxs[2] / 2.0;
	vecTarget[2] += vecTargetMaxs[2] / 2.0;
	
	if( flMaxDistance > 0.0 )
	{
		float flDistance = GetVectorDistance( vecStart, vecTarget );
		if( flDistance > flMaxDistance )
		{
			return false;
		}
	}
	
	Handle hTrace = TR_TraceRayFilterEx(vecStart, vecTarget, MASK_VISIBLE, RayType_EndPoint, TraceFilterSentryBuster, iOther);
	if(!TR_DidHit(hTrace))
	{
		delete hTrace;
		return false;
	}
	
	int iHitEnt = TR_GetEntityIndex( hTrace );
	TR_GetEndPosition( vecEnd, hTrace );
	delete hTrace;
	
	if( iHitEnt == iOther || GetVectorDistanceMeter( vecEnd, vecTarget ) <= 1.0 )
	{
		return true;
	}
	
	return false;
}

float GetVectorDistanceMeter( const float vec1[3], const float vec2[3], bool squared = false )
{
	return ( GetVectorDistance( vec1, vec2, squared ) / 50.00 );
}

bool TraceFilterSentryBuster(int iEntity,int iContentsMask, any iOther )
{
	if( iEntity < 0 || !IsValidEntity(iEntity) )
		return false;
		
	if( iEntity == iOther )
		return true;
		
	if( IsValidClient(iEntity) )
	{
		if( IsClientInGame(iEntity) && IsPlayerAlive(iEntity) && TF2_GetClientTeam(iEntity) == TFTeam_Red )
		{
			return true;
		}
	}
	
	char strClassName[64];
	GetEntityClassname(iEntity, strClassName, sizeof(strClassName));
	
	if( StrContains(strClassName, "obj_", false ) )
	{
		if( GetEntProp( iEntity, Prop_Send, "m_iTeamNum" ) != view_as<int>(TFTeam_Blue) )
		{
			return true;
		}
		else
			return false;
	}
	
	return false;
}

void DealDamage(int ent, int inflictor, int attacker, float damage, int damageType, int weapon=-1, const float damageForce[3]=NULL_VECTOR, const float damagePosition[3]=NULL_VECTOR)
{
	if( ent > 0 && IsValidEntity(ent) && ( ent > MaxClients || IsClientInGame(ent) && IsPlayerAlive(ent) ) && damage > 0 )
	{
		SDKHooks_TakeDamage(ent, inflictor, attacker, damage, damageType, weapon, damageForce, damagePosition);
	}
}

// searches for red sentry guns
// also checks for kill num
bool ShouldDispatchSentryBuster()
{
	int i = -1;
	int iKills;
	while ((i = FindEntityByClassname(i, "obj_sentrygun")) != -1)
	{
		if( IsValidEntity(i) )
		{
			if( GetEntProp( i, Prop_Send, "m_iTeamNum" ) == view_as<int>(TFTeam_Red) )
			{
				iKills = GetEntProp(i, Prop_Send, "SentrygunLocalData", _, 0);
				if( iKills >= c_iBusterMinKills.IntValue ) // found threat
					return true;
			}
		}
	}
	
	return false;
}

// gives wallhacks to sentry busters
void BusterWallhack(int client)
{
	int i = -1;
	int mostkills = 0, bestsentry = -1, currentkills;
	float origin[3];
	float start[3];
	GetClientEyePosition(client, start);
	
	while ((i = FindEntityByClassname(i, "obj_sentrygun")) != -1)
	{
		if( IsValidEntity(i) )
		{
			if( GetEntProp( i, Prop_Send, "m_iTeamNum" ) == view_as<int>(TFTeam_Red) )
			{
				currentkills = GetEntProp(i, Prop_Send, "SentrygunLocalData", _, 0);
				if( currentkills >= c_iBusterMinKills.IntValue ) // found threat
				{
					if( currentkills > mostkills ) // find the sentry with the most kills
					{
						bestsentry = i;
						mostkills = currentkills;
					}
				}
			}
		}
	}
	
	if(bestsentry != -1)
	{
		if(GetEntProp(bestsentry, Prop_Send, "m_bCarried") == 1) // sentry gun is being carried
		{
			int owner = GetEntPropEnt(bestsentry, Prop_Send, "m_hBuilder");
			if(owner > 0 && owner <= MaxClients && IsClientInGame(owner))
			{
				CreateAnnotation(NULL_VECTOR, client, "Target Sentry", 0, 5.0, owner);
			}
		}
		else
		{
			GetEntPropVector(bestsentry, Prop_Data, "m_vecOrigin", origin);
			origin[2] += 15.0;
			CreateAnnotation(origin, client, "Target Sentry", 0, 5.0);			
		}
	}
}

void Buster_GetName(char[] name, int size)
{
	strcopy(name, size, g_TBusterName);
}

float Buster_GetScale()
{
	return g_TBusterScale;
}

float Buster_GetExplosionRadius()
{
	if(g_TBusterExploRadius < 1.0)
	{
		g_TBusterExploRadius = FindConVar("tf_bot_suicide_bomb_range").FloatValue;
	}

	return g_TBusterExploRadius;
}

void Buster_SetHealth(int client)
{
	int health = g_TBusterHealth;
	float flhealth;
	
	flhealth = float(health - GetClassBaseHealth(TFClass_DemoMan));
	TF2Attrib_SetByName(client, "hidden maxhealth non buffed", flhealth);
	SetEntProp(client, Prop_Send, "m_iHealth", health);
	SetEntProp(client, Prop_Data, "m_iHealth", health);
}

void Buster_SetupClient(int client)
{
	Buster_ClearArrays(); // Clear previous buster profile
	Buster_SelectRandomProfile(); // Select and load a new profile
	RoboPlayer rp = RoboPlayer(client);
	rp.Class = TFClass_DemoMan;
	rp.Variant = 0;
	rp.Type = Bot_Buster;
	rp.Attributes = g_TBusterAttribBits;
	rp.Gatebot = false;
	g_flNextBusterTime = GetGameTime() + c_flBusterDelay.FloatValue;
	CreateTimer(0.1, Timer_SetRobotClass, client);
	return;
}

void Buster_SelectRandomProfile()
{
	char busters[256];
	char selection[64];
	char split[32][64];
	c_strBusterProfiles.GetString(busters, sizeof(busters));
	int count = ExplodeString(busters, ",", split, sizeof(split), sizeof(split[]));
	strcopy(selection, sizeof(selection), split[Math_GetRandomInt(0, count - 1)]);
	Buster_LoadProfile(selection);
#if defined DEBUG_PLAYER
	CPrintToChatAll("{green}[DEBUG] {cyan}Sentry Buster profile {orange}\"%s\"{cyan} loaded successfully.", selection);
#endif
}

void Buster_GiveInventory(int client)
{
	if(IsFakeClient(client))
		return;
	
	char buffer[128], sValue[128];
	TF2Attrib_RemoveAll(client);
	// Set Player Attributes
	if(g_TBusterCharAttrib.Length > 0)
	{
		for(int i = 0;i < g_TBusterCharAttrib.Length;i++)
		{
			g_TBusterCharAttrib.GetString(i, buffer, sizeof(buffer));
			g_TBusterCharAttribValue.GetString(i, sValue, sizeof(sValue));
#if defined __tf_custom_attributes_included
					if (TF2Attrib_IsValidAttributeName(buffer))
					{
						TF2Attrib_SetFromStringValue(client, buffer, sValue);
					}
					else
					{
						TF2CustAttr_SetString(client, buffer, sValue);
					}
#else
					TF2Attrib_SetFromStringValue(client, buffer, sValue);
#endif
		}
	}
	SpawnWeapon(client, "tf_weapon_stickbomb", 307, 1, 6, false);
}

// Load the selected uster profile
// Returns false on error.
bool Buster_LoadProfile(const char[] busterprofile)
{
	char filename[64], configfile[PLATFORM_MAX_PATH];
	char strBits[12][MAXLEN_CONFIG_STRING];
	int iNum, iBits = 0;
	
	FormatEx(filename, sizeof(filename), "%s.cfg", busterprofile);
	BuildPath(Path_SM, configfile, sizeof(configfile), "configs/bwrr/buster/");
	Format(configfile, sizeof(configfile), "%s%s", configfile, filename);
	
	if(!FileExists(configfile))
	{
		LogError("Failed to load sentry buster profile. File \"%s\" was not found.", configfile);
		return false;
	}
	
	Boss_ClearArrays(); // Need to clear arrays due to the new force boss command.
	
	KeyValues kv = new KeyValues("BusterTemplate");
	kv.ImportFromFile(configfile);
	
	// Jump into the first subsection
	if (!kv.GotoFirstSubKey())
	{
		delete kv;
		return false;
	}
	kv.GoBack();
	
	char buffer[255];
	kv.GetString("name", g_TBusterName, sizeof(g_TBusterName), "Sentry Buster");
	g_TBusterHealth = kv.GetNum("health", 2500);
	g_TBusterScale = kv.GetFloat("scale", 1.75);
	kv.GetString("robotattributes", buffer, sizeof(buffer));
	g_TBusterExploRadius = kv.GetFloat("explosion_radius", 0.0);
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
	g_TBusterAttribBits = iBits;
	
	if(kv.JumpToKey("playerattributes"))
	{
		kv.GetSectionName(buffer, sizeof(buffer));
		if(kv.GotoFirstSubKey(false))
		{
			do
			{ // Store Player Attributes
				kv.GetSectionName(buffer, sizeof(buffer)); // Get Attribute Name
#if defined __tf_custom_attributes_included
				g_TBusterCharAttrib.PushString(buffer); // Attribute Name
				kv.GetString(NULL_STRING, buffer, sizeof(buffer));
				g_TBusterCharAttribValue.PushString(buffer); // Attribute Value
#else
				if(TF2Attrib_IsValidAttributeName(buffer))
				{
					g_TBusterCharAttrib.PushString(buffer); // Attribute Name
					kv.GetString(NULL_STRING, buffer, sizeof(buffer));
					g_TBusterCharAttribValue.PushString(buffer); // Attribute Value
				}
				else
				{
					LogError("ERROR: Invalid player attribute \"%s\" in boss \"%s\"", buffer, g_TBossName);
				}
#endif
			} while(kv.GotoNextKey(false));
			kv.GoBack();
		}
		kv.GoBack();
	}
	
	delete kv;
	return true;
}