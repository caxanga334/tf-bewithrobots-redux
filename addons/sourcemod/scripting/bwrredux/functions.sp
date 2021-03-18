// functions that can be removed from the main file

#define SIZE_OF_INT         2147483647 // without 0

// Globals
ArrayList g_aSpyTeleport;
ArrayList g_aEngyTeleport;
ArrayList g_aSpawnRooms; // arraylist containing func_respawnroom that already exists in the map

char g_strHatchTrigger[64];
char g_strExploTrigger[64];
char g_strNormalSplit[16][64];
char g_strGiantSplit[16][64];
char g_strSniperSplit[16][64];
char g_strSpySplit[16][64];
int g_iSplitSize[4];

float g_flGateStunDuration;
bool g_bDisableGateBots; // Force gatebots to be unavailable
bool g_bLimitRobotScale;
bool g_bSkipSpawnRoom; // Should we skip creating additional spawn rooms?

/**
 * Checks if the given client index is valid.
 *
 * @param client         The client index.  
 * @return              True if the client is valid
 *                      False if the client is invalid.
 */
stock bool IsValidClient(int client)
{
	if( client < 1 || client > MaxClients ) return false;
	if( !IsValidEntity(client) ) return false;
	return IsClientInGame(client);
}

/**
 * Gets a random player in game from a specific team.
 * Do not call this if the server is empty.
 *
 * @param iTeam         Team Index
 * @param bBots         Include bots?
 * @return              The client index
 */
stock int GetRandomClientFromTeam(const int iTeam, bool bBots = false)
{
	int players_available[MAXPLAYERS+1];
	int counter = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		if(!bBots && IsFakeClient(i))
			continue;
			
		if(GetClientTeam(i) != iTeam)
			continue;
			
		players_available[counter] = i;
		counter++;
	}
	
	if(counter == 0)
		return -1;
	
	return players_available[Math_GetRandomInt(0,(counter-1))];
}

/**
 * Returns a random, uniform Integer number in the specified (inclusive) range.
 * This is safe to use multiple times in a function.
 * The seed is set automatically for each plugin.
 * Rewritten by MatthiasVance, thanks.
 *
 * @param min			Min value used as lower border
 * @param max			Max value used as upper border
 * @return				Random Integer number between min and max
 */
stock int Math_GetRandomInt(int min, int max)
{
	int random = GetURandomInt();

	if (random == 0) {
		random++;
	}

	return RoundToCeil(float(random) / (float(SIZE_OF_INT) / float(max - min + 1))) + min - 1;
}

// Random Chance
stock bool Math_RandomChance(int chance)
{
	return Math_GetRandomInt(1, 100) <= chance;
}

// IsMvM code by FlaminSarge
bool IsMvM(bool forceRecalc = false)
{
	static bool found = false;
	static bool ismvm = false;
	if (forceRecalc)
	{
		found = false;
		ismvm = false;
	}
	if (!found)
	{
		int i = FindEntityByClassname(-1, "tf_logic_mann_vs_machine");
		if (i > MaxClients && IsValidEntity(i)) ismvm = true;
		found = true;
	}
	return ismvm;
}

/****************************************************
					ROBOT SPY
*****************************************************/

// Teleports a spy near a RED player
void TeleportSpyRobot(int client)
{
	if(GetTeamClientCount(view_as<int>(TFTeam_Red)) == 0)
		return; // No players in RED team.
	
	int target = GetRandomClientFromTeam(view_as<int>(TFTeam_Red), false);
	float TelePos[3];
	
	if(!IsValidClient(target))
	{
		if(GetSpyTeleportFromConfig(TelePos))
		{
			BWRR_RemoveSpawnProtection(client);
			TeleportEntity(client, TelePos, NULL_VECTOR, NULL_VECTOR);
		}
	}
	else
	{
		if(GetSpyTeleportFromConfig(TelePos, target))
		{
			BWRR_RemoveSpawnProtection(client);
			TeleportEntity(client, TelePos, NULL_VECTOR, NULL_VECTOR);
			char name[MAX_NAME_LENGTH];
			GetClientName(target, name, sizeof(name));
			CPrintToChat(client, "%t", "Spy_Teleported", name);
		}
	}
}

/****************************************************
					ROBOT ENGINEER
*****************************************************/

// searches for an engineer nest close to the bomb
bool FindEngineerNestNearBomb(int client)
{
	float nVec[3], bVec[3], tVec[3]; // nest pos, bomb pos, tele pos
	float hatchpos[3];
	float current_dist;
	float min_dist = GetConVarFloat(FindConVar("tf_bot_engineer_mvm_hint_min_distance_from_bomb"));
	float max_back_dist = GetConVarFloat(FindConVar("tf_bot_engineer_mvm_sentry_hint_bomb_backward_range"));
	float max_forw_dist = GetConVarFloat(FindConVar("tf_bot_engineer_mvm_sentry_hint_bomb_forward_range"));
	float smallest_dist = 999999.0;
	int iTargetNest = -1; // the closest nest found.
	int iBomb = FindBestBomb();
	int iBombOwner;
	
	if( iBomb == -1 )
		return false; // no bomb found
	
	hatchpos = TF2_GetBombHatchPosition();
	iBombOwner = GetEntPropEnt(iBomb, Prop_Send, "m_hOwnerEntity");
	if( iBombOwner == -1 || iBombOwner > MaxClients)
	{
		GetEntPropVector(iBomb, Prop_Send, "m_vecOrigin", bVec); // bomb
	}
	else // if the bomb is carried by a player, use the eye position of the carrier instead
	{
		GetClientEyePosition(iBombOwner, bVec);
	}
	
	// search for bot hints
	int i = -1;
	ArrayList anests;
	anests = new ArrayList();
	while((i = FindEntityByClassname(i, "bot_hint_engineer_nest" )) != -1)
	{
		if(IsValidEntity(i))
		{
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", nVec); // nest
			
			current_dist = GetVectorDistance(bVec, nVec);
			
			// if the nest is closer to the hatch than the bomb itself, it's a forward nest
			if(GetVectorDistance(nVec, hatchpos) < GetVectorDistance(bVec, hatchpos)) // forward
			{
				if( current_dist < smallest_dist && current_dist > min_dist && current_dist < max_forw_dist )
				{
					anests.Push(i);
					smallest_dist = current_dist;
				}				
			}
			else // backward
			{
				if( current_dist < smallest_dist && current_dist > min_dist && current_dist < max_back_dist )
				{
					anests.Push(i);
					smallest_dist = current_dist;
				}
			}
		}
	}
	
	if(anests.Length > 0)
	{
		iTargetNest = anests.Get(Math_GetRandomInt(0,anests.Length - 1));
		delete anests;
	}
	
	if( iTargetNest == -1 ) // no bot_hint_engineer_nest found
	{
		if( GetEngyTeleportFromConfig(tVec, bVec) )
		{
			TeleportEngineerToPosition(tVec, client);
		}
		else // No nest was found to teleport an engineer
		{
			return false;
		}
	}
	else
	{
		GetEntPropVector(iTargetNest, Prop_Send, "m_vecOrigin", tVec);
		TeleportEngineerToPosition(tVec, client);
	}
	
	return true;
}

// returns an entity index of the best bomb
int FindBestBomb()
{
	int index = -1, owner;
	float bombpos[3], hatchpos[3];
	float bestdist = 999999.0;
	float searchdist;
	
	hatchpos = TF2_GetBombHatchPosition();
	
	int i = -1;
	while((i = FindEntityByClassname(i, "item_teamflag" )) != -1)
	{
		if(IsValidEntity(i) && GetEntProp( i, Prop_Send, "m_bDisabled" ) == 0 && !TF2_IsFlagHome(i)) // ignore disabled bombs
		{
			owner = GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity");
			if(owner > 0 && owner < MaxClients)
			{
				GetClientAbsOrigin(owner, bombpos);
			}
			else
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", bombpos);
			}
			
			searchdist = GetVectorDistance(bombpos, hatchpos);
			if(searchdist < bestdist)
			{
				bestdist = searchdist;
				index = i;
			}
		}
	}
	
	return index;
}

// teleports a client to the ent origin.
// also adds engineer spawn particle
void TeleportEngineerToPosition(float origin[3], int client, float OffsetVec[3] = {0.0,0.0,0.0})
{
	float FinalVec[3];
	
	BWRR_RemoveSpawnProtection(client);
	AddVectors(origin, OffsetVec, FinalVec);
	TeleportEntity(client, FinalVec, NULL_VECTOR, NULL_VECTOR);
	CreateTEParticle("teleported_blue",FinalVec, _, _,3.0,-1,-1,-1);
	CreateTEParticle("teleported_mvm_bot",FinalVec, _, _,3.0,-1,-1,-1);
}

// searches for a teleporter exit 
int FindBestBluTeleporter()
{
	float nVec[3]; // nest pos
	float bVec[3]; // bomb pos
	float current_dist;
	float smallest_dist = 15000.0;
	int iTargetTele = -1; // the closest nest found.
	int i = -1;
	int iBomb = -1; // the bomb we're going to use to check distance.
	int iBombOwner = -1;
	
	while( (i = FindEntityByClassname(i, "item_teamflag" )) != -1 )
	{
		if( IsValidEntity(i) && GetEntProp( i, Prop_Send, "m_bDisabled" ) == 0 ) // ignore disabled bombs
		{
			iBomb = i; // use the first bomb found.
			iBombOwner = GetEntPropEnt( i, Prop_Send, "m_hOwnerEntity" );
			break;
		}
	}
	
	if( iBomb == -1 )
		return -1; // no bomb found
	
	i = -1;
	while( (i = FindEntityByClassname(i, "obj_teleporter" )) != -1 )
	{
		if( IsValidEntity(i) )
		{
			if( GetEntProp( i, Prop_Send, "m_bHasSapper" ) == 0 && GetEntProp( i, Prop_Send, "m_iTeamNum" ) == view_as<int>(TFTeam_Blue) && GetEntPropFloat(i, Prop_Send, "m_flPercentageConstructed") >= 0.99 )
			{
				if( iBombOwner == -1 || iBombOwner > MaxClients)
				{
					GetEntPropVector(iBomb, Prop_Send, "m_vecOrigin", bVec); // bomb
				}
				else // if the bomb is carried by a player, use the eye position of the carrier instead
				{
					GetClientEyePosition(iBombOwner, bVec);
				}
				
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", nVec); // nest
				
				current_dist = GetVectorDistance(bVec, nVec);
				
				if( current_dist < smallest_dist )
				{
					iTargetTele = i;
					smallest_dist = current_dist;
				}
			}
		}
	}
	
	return iTargetTele;
}

// announces when a robot engineer is killed.
void AnnounceEngineerDeath(int client)
{
	bool bFoundTele = false;
	int i = -1;
	int iOwner = -1;
	
	if( IsClientInGame(client) && !IsFakeClient(client) )
	{
		while( (i = FindEntityByClassname(i, "obj_teleporter" )) != -1 )
		{
			if( IsValidEntity(i) )
			{
				if( GetEntProp( i, Prop_Send, "m_iTeamNum" ) == view_as<int>(TFTeam_Blue) )
				{				
					iOwner = GetEntPropEnt( i, Prop_Send, "m_hBuilder" );
					if( iOwner == client )
					{
						bFoundTele = true;
						break;
					}
				}
			}
		}
		if( bFoundTele ) // found a teleporter
		{
			EmitGSToRed("Announcer.MVM_An_Engineer_Bot_Is_Dead_But_Not_Teleporter");
		}
		else if( GameRules_GetRoundState() == RoundState_RoundRunning )
		{
			EmitGSToRed("Announcer.MVM_An_Engineer_Bot_Is_Dead");
		}
	}
}

// TeleportPlayerToEntity but for teleporters
void SpawnOnTeleporter(int teleporter,int client)
{
	float OriginVec[3];
	float Scale = GetEntPropFloat(client, Prop_Send, "m_flModelScale");
	if( IsValidEntity(teleporter) )
	{
		GetEntPropVector(teleporter, Prop_Send, "m_vecOrigin", OriginVec);
		
		if( Scale <= 1.0 )
		{
			OriginVec[2] += 16;
		}
		else if( Scale >= 1.1 && Scale <= 1.4 )
		{
			OriginVec[2] += 20;
		}
		else if( Scale >= 1.5 && Scale <= 1.6 )
		{
			OriginVec[2] += 23;
		}		
		else if( Scale >= 1.7 && Scale <= 1.8 )
		{
			OriginVec[2] += 26;
		}
		else if( Scale >= 1.9 )
		{
			OriginVec[2] += 50;
		}
		
		TF2_AddCondition(client, TFCond_UberchargedCanteen, 5.1); // 0.1 sec to compensate for a small delay
		TeleportEntity(client, OriginVec, NULL_VECTOR, NULL_VECTOR);
		EmitGameSoundToAll("MVM.Robot_Teleporter_Deliver", teleporter, SND_NOFLAGS, teleporter, OriginVec);
		BWRR_RemoveSpawnProtection(client);
	}
}

// add particle to the robot engineer teleporter
void AddParticleToTeleporter(int ent)
{
	int particle = CreateEntityByName("info_particle_system");

	char targetname[64];
	float VecOrigin[3];
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", VecOrigin);
	VecOrigin[2] -= 500;
	TeleportEntity(particle, VecOrigin, NULL_VECTOR, NULL_VECTOR);

	FormatEx(targetname, sizeof(targetname), "tele_target_%i", ent);
	DispatchKeyValue(ent, "targetname", targetname);

	DispatchKeyValue(particle, "targetname", "bwrr_tele_particle");
	DispatchKeyValue(particle, "parentname", targetname);
	DispatchKeyValue(particle, "effect_name", "teleporter_mvm_bot_persist");
	DispatchSpawn(particle);
	SetVariantString(targetname);
	AcceptEntityInput(particle, "SetParent", particle, particle);
	SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", ent);
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");
}

public void OnDestroyedTeleporter(const char[] output, int caller, int activator, float delay)
{
	AcceptEntityInput(caller,"KillHierarchy");
}

// V2: Uses trace hull.
// The player size can be found here: https://developer.valvesoftware.com/wiki/TF2/Team_Fortress_2_Mapper's_Reference
// Remember that giant's size is multiplied by 1.75 (some bosses uses 1.9).
// Returns true if a teleporter CANNOT be built
bool CheckTeleportClamping(int teleporter, int client)
{
	float telepos[3];
	GetEntPropVector(teleporter, Prop_Send, "m_vecOrigin", telepos);
	telepos[2] += 12.0;
	bool smallmap = IsSmallMap();
	Handle trace = null;
	float mins_normal[3] = { -48.0, -48.0, 0.0 }; // Normal map
	float maxs_normal[3] = { 48.0, 48.0, 164.0 };
	float mins_small[3] = { -29.0, -29.0, 0.0 }; // Small map
	float maxs_small[3] = { 29.0, 29.0, 99.0 };	
	
	if(smallmap)
		trace = TR_TraceHullFilterEx(telepos, telepos, mins_small, maxs_small, MASK_PLAYERSOLID, TraceFilterTeleporter, teleporter);
	else
		trace = TR_TraceHullFilterEx(telepos, telepos, mins_normal, maxs_normal, MASK_PLAYERSOLID, TraceFilterTeleporter, teleporter);
		
	if(TR_DidHit(trace))
	{
		if(smallmap)
			DrawBox(client, telepos, mins_small, maxs_small);
		else
			DrawBox(client, telepos, mins_normal, maxs_normal);
			
		delete trace;
		return true;
	}

	delete trace;
	return false;
}

bool TraceFilterTeleporter(int entity, int contentsMask, any data)
{
	if(entity >= 1 && entity <= MaxClients)
		return false;
		
	if(entity == data)
		return false;
		
	return true;
}

bool TraceFilterSpy(int entity, int contentsMask, any data)
{
	if(entity >= 1 && entity <= MaxClients)
		return false;
		
	if(entity == data)
		return false;
		
	if(entity != 0)
		return false;
		
	return true;
}

void TE_SendBeam(const float vMins[3], const float vMaxs[3], const int colors[4] = { 255, 255, 255, 255 }, int client = -1)
{
	TE_SetupBeamPoints(vMins, vMaxs, g_iLaserSprite, g_iHaloSprite, 0, 0, 5.0, 1.0, 1.0, 1, 0.0, colors, 0);
	
	if(client > 0 && client <= MaxClients)
		TE_SendToClient(client);
	else
		TE_SendToAll();
}

// Code from Silver's dev cmd plugin
void DrawBox(int client, float vPos[3], float vMins[3], float vMaxs[3])
{
	if( vMins[0] == vMaxs[0] && vMins[1] == vMaxs[1] && vMins[2] == vMaxs[2] )
	{
		vMins = view_as<float>({ -15.0, -15.0, -15.0 });
		vMaxs = view_as<float>({ 15.0, 15.0, 15.0 });
	}
	else
	{
		AddVectors(vPos, vMaxs, vMaxs);
		AddVectors(vPos, vMins, vMins);
	}
	
	int colors[4] = { 0, 255, 0, 255 };
	float vPos1[3], vPos2[3], vPos3[3], vPos4[3], vPos5[3], vPos6[3];
	vPos1 = vMaxs;
	vPos1[0] = vMins[0];
	vPos2 = vMaxs;
	vPos2[1] = vMins[1];
	vPos3 = vMaxs;
	vPos3[2] = vMins[2];
	vPos4 = vMins;
	vPos4[0] = vMaxs[0];
	vPos5 = vMins;
	vPos5[1] = vMaxs[1];
	vPos6 = vMins;
	vPos6[2] = vMaxs[2];

	TE_SendBeam(vMaxs, vPos1, colors, client);
	TE_SendBeam(vMaxs, vPos2, colors, client);
	TE_SendBeam(vMaxs, vPos3, colors, client);
	TE_SendBeam(vPos6, vPos1, colors, client);
	TE_SendBeam(vPos6, vPos2, colors, client);
	TE_SendBeam(vPos6, vMins, colors, client);
	TE_SendBeam(vPos4, vMins, colors, client);
	TE_SendBeam(vPos5, vMins, colors, client);
	TE_SendBeam(vPos5, vPos1, colors, client);
	TE_SendBeam(vPos5, vPos3, colors, client);
	TE_SendBeam(vPos4, vPos3, colors, client);
	TE_SendBeam(vPos4, vPos2, colors, client);
}

/****************************************************
					EMIT SOUND
*****************************************************/

// emits game sound to all players in RED
void EmitGSToRed(const char[] gamesound)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if( IsClientInGame(i) && !IsFakeClient(i) )
		{
			if( TF2_GetClientTeam(i) == TFTeam_Red )
			{
				EmitGameSoundToClient(i, gamesound);
			}
		}
	}
}

// emits sound to all players in RED
/* void EmitSoundToRed(const char[] soundpath)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if( IsClientInGame(i) && !IsFakeClient(i) )
		{
			if( TF2_GetClientTeam(i) == TFTeam_Red )
			{
				EmitSoundToClient(i, soundpath);
			}
		}
	}
} */

/****************************************************
					UTILITY
*****************************************************/

// returns the number of classes in a team.
int GetClassCount(TFClassType TFClass, TFTeam Team, bool bIncludeBots = false, bool bIncludeDead = true)
{
	int counter = 0;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		if(!bIncludeBots && IsFakeClient(i))
			continue;
			
		if(!bIncludeDead && !IsPlayerAlive(i))
			continue;
			
		if(TF2_GetClientTeam(i) != Team)
			continue;
			
		if(TF2_GetPlayerClass(i) != TFClass)
			continue;
			
		counter++;
	}
	
	return counter;
}

// returns the ent index of the first available weapon
int GetFirstAvailableWeapon(int client)
{
	int iWeapon = -1;
	int iSlot = 0;
	
	while( iSlot <= 5 )
	{
		iWeapon = GetPlayerWeaponSlot(client, iSlot);
		iSlot++;
		if( iWeapon != -1 )
		{
			break;
		}
	}
	
	return iWeapon;
}

// Prevents the client from picking up the bomb/flag
void BlockBombPickup(int client)
{
	if( IsFakeClient(client) )
		return;
	
	// This attribute works when added to a client
	TF2Attrib_SetByName(client, "cannot pick up intelligence", 1.0);
}

void CreateTEParticle(	char strParticle[64],
						float OriginVec[3]=NULL_VECTOR,
						float StartVec[3]=NULL_VECTOR,
						float AnglesVec[3]=NULL_VECTOR,
						float flDelay=0.0,
						int iEntity=-1,
						int iAttachType=-1,
						int iAttachPoint=-1 )
{
	int ParticleTable = FindStringTable("ParticleEffectNames");
	if( ParticleTable == INVALID_STRING_TABLE )
	{
		LogError("Could not find String Table \"ParticleEffectNames\"");
		return;
	}
	int iCounter = GetStringTableNumStrings(ParticleTable);
	int iParticleIndex = INVALID_STRING_INDEX;
	char Temp[128];
	
	for(int i = 0;i < iCounter; i++)
	{
		ReadStringTable(ParticleTable, i, Temp, sizeof(Temp));
		if( strcmp(Temp, strParticle, false) == 0 )
		{
			iParticleIndex = i;
			break;
		}
	}
	if( iParticleIndex == INVALID_STRING_INDEX )
	{
		LogError("Could not find particle named \"%s\"", strParticle);
		return;
	}
	
	TE_Start("TFParticleEffect");
	TE_WriteFloat("m_vecOrigin[0]", OriginVec[0]);
	TE_WriteFloat("m_vecOrigin[1]", OriginVec[1]);
	TE_WriteFloat("m_vecOrigin[2]", OriginVec[2]);
	TE_WriteFloat("m_vecStart[0]", StartVec[0]);
	TE_WriteFloat("m_vecStart[1]", StartVec[1]);
	TE_WriteFloat("m_vecStart[2]", StartVec[2]);
	TE_WriteVector("m_vecAngles", AnglesVec);
	TE_WriteNum("m_iParticleSystemIndex", iParticleIndex);
	
	if( iEntity != -1 )
	{
		TE_WriteNum("entindex", iEntity);
	}
	if( iAttachType != -1 )
	{
		TE_WriteNum("m_iAttachType", iAttachType);
	}
	if( iAttachPoint != -1 )
	{
		TE_WriteNum("m_iAttachmentPointIndex", iAttachPoint);
	}
	
	TE_SendToAll(flDelay);
}

int CreateParticle( float flOrigin[3], const char[] strParticle, float flDuration = -1.0 )
{
	int iParticle = CreateEntityByName( "info_particle_system" );
	if( IsValidEntity( iParticle ) )
	{
		DispatchKeyValue( iParticle, "effect_name", strParticle );
		DispatchKeyValue( iParticle, "targetname", "bwrr_particle_effect" );
		TeleportEntity( iParticle, flOrigin, NULL_VECTOR, NULL_VECTOR );
		DispatchSpawn( iParticle );
		ActivateEntity( iParticle );
		AcceptEntityInput( iParticle, "Start" );
		if( flDuration >= 0.0 )
			CreateTimer( flDuration, Timer_DeleteParticle, EntIndexToEntRef(iParticle) );
	}
	return iParticle;
}

// Creates a particle system and sets a client as it's owner.
int CreateGateStunParticle(const char[] strParticle, float flDuration = -1.0, int client)
{
	int iParticle = CreateEntityByName( "info_particle_system" );
	if( IsValidEntity( iParticle ) )
	{
		DispatchKeyValue( iParticle, "effect_name", strParticle );
		DispatchKeyValue( iParticle, "targetname", "bwrr_player_particle" );
		SetVariantString("!activator");
		AcceptEntityInput(iParticle, "SetParent", client, iParticle, 0);
		SetVariantString("head");
		AcceptEntityInput(iParticle, "SetParentAttachment", iParticle , iParticle, 0);
		//TeleportEntity( iParticle, flOrigin, NULL_VECTOR, NULL_VECTOR );
		DispatchSpawn( iParticle );
		ActivateEntity( iParticle );
		AcceptEntityInput( iParticle, "Start" );
		SetEntPropEnt(iParticle, Prop_Send, "m_hOwnerEntity", client);
		if( flDuration >= 0.0 )
			CreateTimer( flDuration, Timer_DeleteParticle, EntIndexToEntRef(iParticle) );
	}
	return iParticle;
}

// removes particle attached to a player
void DeleteParticleOnPlayerDeath(int client)
{
	int ent = -1;
	int owner;
	char targetname[32];
	
	while ((ent = FindEntityByClassname(ent, "info_particle_system")) != -1)
	{
		if(IsValidEntity(ent))
		{
			GetEntPropString( ent, Prop_Data, "m_iName", targetname, sizeof(targetname) );
			if(strcmp(targetname, "bwrr_player_particle", false) == 0) // check targetname
			{
				owner = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
				if(owner == client)
				{
					RemoveEntity(ent);
					return;
				}
			}
		}
	}
}

// checks if a player is giant
bool TF2_IsGiant(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_bIsMiniBoss"));
}

// checks if the given origin is withing a trigger boundaries
bool SDKIsPointWithIn(int trigger, float origin[3])
{
	return view_as<bool>(SDKCall(g_hSDKPointIsWithin, trigger, origin));
}

// remove objects from the given player
void SDKTFPlayerRemoveObject(int client, int obj)
{
	SDKCall(g_hSDKRemoveObject, client, obj);
}

void Robot_GibGiant(int client, float OriginVec[3])
{
	if( IsFakeClient(client) )
		return;

	int Ent;

	//Initialize:
	Ent = CreateEntityByName("tf_ragdoll");

	//Write:
	SetEntPropVector(Ent, Prop_Send, "m_vecRagdollOrigin", OriginVec); 
	SetEntProp(Ent, Prop_Send, "m_iPlayerIndex", client); 
	SetEntPropVector(Ent, Prop_Send, "m_vecForce", NULL_VECTOR);
	SetEntPropVector(Ent, Prop_Send, "m_vecRagdollVelocity", NULL_VECTOR);
	SetEntProp(Ent, Prop_Send, "m_bGib", 1);

	//Send:
	DispatchSpawn(Ent);

	//Remove Body:
	CreateTimer(0.05, Timer_RemoveBody, client, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(8.0, Timer_RemoveGibs, Ent, TIMER_FLAG_NO_MAPCHANGE);
}

/****************************************************
					MAP RELATED
*****************************************************/

// explodes the bomb hatch using the tank's logic_relay
void TriggerHatchExplosion()
{
	int i = -1;
	
	// Method 1: Trigger round win by exploding the hatch using the tank relay.
	// At least on official MVM maps, the tank relay will also trigger game_round_win
	if(strlen(g_strHatchTrigger) > 3)
	{
		while ((i = FindEntityByClassname(i, "logic_relay")) != -1)
		{
			if(IsValidEntity(i))
			{
				char strName[50];
				GetEntPropString(i, Prop_Data, "m_iName", strName, sizeof(strName));
				if(strcmp(strName, g_strHatchTrigger, false) == 0)
				{
					AcceptEntityInput(i, "Trigger");
					return;
				}
			} 
		}
	}
	
	// Method 2: Tank trigger could not be found or can not be used ( eg: doesn't trigger game_round_win for some reason )
	// So this time the plugin will search for the game_round_win itself and trigger it manually.
	i = -1;
	while ((i = FindEntityByClassname(i, "game_round_win")) != -1)
	{
		if(IsValidEntity(i))
		{
			char strName[50];
			GetEntPropString(i, Prop_Data, "m_iName", strName, sizeof(strName));
			if( GetEntProp(i, Prop_Send, "m_iTeamNum") == view_as<int>(TFTeam_Blue) )
			{
				AcceptEntityInput(i, "RoundWin");
			}
		} 
	}
	
	// Finally we check if we have a relay to trigger the cinematic explosion of the bomb hatch
	// Make sure the relay used here doesn't trigger game_round_win again.
	i = -1;
	if(strlen(g_strExploTrigger) > 3)
	{
		while ((i = FindEntityByClassname(i, "logic_relay")) != -1)
		{
			if(IsValidEntity(i))
			{
				char strName[50];
				GetEntPropString(i, Prop_Data, "m_iName", strName, sizeof(strName));
				if(strcmp(strName, g_strExploTrigger, false) == 0)
				{
					AcceptEntityInput(i, "Trigger"); // 
					return;
				}
			} 
		}
	}
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
	GetClientAbsOrigin(client, flExplosionPos );
	int iWeapon = GetFirstAvailableWeapon(client);
	
	if( GameRules_GetRoundState() == RoundState_RoundRunning )
	{
		int i;
		for( i = 1; i <= MaxClients; i++ ) {
			if( i != client && IsValidClient(i) && IsPlayerAlive(i) ) {
				if( CanSeeTarget( client, i, 320.0 ) ) {
					DealDamage(i, client, client, 10000.0, DMG_BLAST, iWeapon);
				}
			}
		}
		
		static const char strObjects[3][] = { "obj_sentrygun", "obj_dispenser", "obj_teleporter" };
		for( int o = 0; o < sizeof(strObjects); o++ )
		{
			i = -1;
			while( ( i = FindEntityByClassname( i, strObjects[o] ) ) != -1 ) {
				if( GetEntProp( i, Prop_Send, "m_iTeamNum" ) != view_as<int>(TFTeam_Blue) && !GetEntProp( i, Prop_Send, "m_bCarried" ) && !GetEntProp( i, Prop_Send, "m_bPlacing" ) ) {
					if( CanSeeTarget( client, i, 320.0 ) ) {
						DealDamage(i, client, client, 10000.0, DMG_BLAST, iWeapon);
					}
				}
			}
		}
	}
	
	CreateParticle( flExplosionPos, "fluidSmokeExpl_ring_mvm", 6.5 );
	CreateParticle( flExplosionPos, "explosionTrail_seeds_mvm", 5.5 );	//fluidSmokeExpl_ring_mvm  explosionTrail_seeds_mvm
	
	ForcePlayerSuicide( client );
	EmitGameSoundToAll("MVM.SentryBusterExplode", client, SND_NOFLAGS, client, flExplosionPos);
	CreateTimer(0.05, Timer_RemoveBody, client, TIMER_FLAG_NO_MAPCHANGE);
}

bool CanSeeTarget(int iEntity,int iOther, float flMaxDistance = 0.0 )
{
	if( iEntity <= 0 || iOther <= 0 || !IsValidEntity(iEntity) || !IsValidEntity(iOther) )
		return false;
	
	float vecStart[3], vecStartMaxs[3], vecTarget[3], vecTargetMaxs[3], vecEnd[3];
	
	GetEntPropVector( iEntity, Prop_Data, "m_vecOrigin", vecStart );
	GetEntPropVector( iEntity, Prop_Send, "m_vecMaxs", vecStartMaxs );
	GetEntPropVector( iOther, Prop_Data, "m_vecOrigin", vecTarget );
	GetEntPropVector( iOther, Prop_Send, "m_vecMaxs", vecTargetMaxs );
	
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
	
	Handle hTrace = TR_TraceRayFilterEx( vecStart, vecTarget, MASK_VISIBLE, RayType_EndPoint, TraceFilterSentryBuster, iOther );
	if( !TR_DidHit( hTrace ) )
	{
		CloseHandle( hTrace );
		return false;
	}
	
	int iHitEnt = TR_GetEntityIndex( hTrace );
	TR_GetEndPosition( vecEnd, hTrace );
	CloseHandle( hTrace );
	
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

/****************************************************
					CONFIG FILES
*****************************************************/

// Initialze config
void Config_Init()
{
	g_aSpyTeleport = new ArrayList(3);
	g_aEngyTeleport = new ArrayList(3);
	g_aSpawnRooms = new ArrayList();
}

// Gets an origin to teleport a spy
// If target_player is set, try to find one near the target
// returns true if a spot is found
bool GetSpyTeleportFromConfig(float origin[3], int target_player = -1)
{
	float tVec[3], rVec[3]; // target_player's vector, return vector
	int iBestCell = -1;
	float distance;
	static const float max_dist = 2048.0;
	static const float min_dist = 256.0;
	
	if( g_aSpyTeleport.Length < 1 )
		return false;
		
	ArrayList aPos;
	aPos = new ArrayList();
	
	if(IsValidClient(target_player))
	{
		GetClientAbsOrigin(target_player, tVec);
		for(int i = 0;i < g_aSpyTeleport.Length;i++)
		{
			g_aSpyTeleport.GetArray(i, rVec);
			
			if(!SpyTeleport_RayCheck(i, rVec)) // Trace didn't hit anything
				continue;
			
			distance = GetVectorDistance(rVec, tVec);
			if( distance > min_dist && distance < max_dist ) // include all teleport points inside min and max distance
			{
				aPos.Push(i);
			}
		}
		
		if(aPos.Length > 0)
		{
			iBestCell = aPos.Get(Math_GetRandomInt(0,aPos.Length - 1));
			delete aPos;
		}
		
		if( iBestCell != -1 )
		{
			g_aSpyTeleport.GetArray(iBestCell, origin);
			return true;
		}
		else
			return false;
	}
	else
	{
		g_aSpyTeleport.GetArray(Math_GetRandomInt(0, (g_aSpyTeleport.Length - 1)), origin);
		return true;
	}
}

// returns true if the trace hit something
bool SpyTeleport_RayCheck(const int id, float pos1[3], int iDebug = 0)
{
	Handle trace;
	pos1[2] += 45;
	float pos2[3];
	bool valid = true;
	for(int i = 1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i)) // must be in game
			continue;
			
		if(IsFakeClient(i)) // not a bot
			continue;
			
		if(TF2_GetClientTeam(i) != TFTeam_Red) // must be on RED team
			continue;
			
		trace = null;
		GetClientEyePosition(i, pos2);
		trace = TR_TraceRayFilterEx(pos1, pos2, MASK_VISIBLE_AND_NPCS, RayType_EndPoint, TraceFilterSpy, i);
		
		if(!TR_DidHit(trace))
		{
			if(iDebug) {
			PrintToConsoleAll("[SPY TELEPORT - %i] Trace Ray LOS check failed! Player \"%N\".", id, i);
			TE_SetupBeamPoints(pos1, pos2, g_iLaserSprite, g_iHaloSprite, 0, 0, 10.0, 1.0, 1.0, 1, 1.0, {255, 0, 0, 255}, 0);
			TE_SendToAll();
			}
			valid = false;
			break;
		}
	}
	
	delete trace;
	return valid;
}

// Gets an origin to teleport an engineer
// returns true if a spot is found
bool GetEngyTeleportFromConfig(float origin[3], float bombpos[3])
{
	float rVec[3], hatchpos[3];
	int iBestCell = -1;
	float current_dist, smallest_dist = 999999.0;
	float min_dist = GetConVarFloat(FindConVar("tf_bot_engineer_mvm_hint_min_distance_from_bomb"));
	float max_back_dist = GetConVarFloat(FindConVar("tf_bot_engineer_mvm_sentry_hint_bomb_backward_range"));
	float max_forw_dist = GetConVarFloat(FindConVar("tf_bot_engineer_mvm_sentry_hint_bomb_forward_range"));
	
	if( g_aEngyTeleport.Length < 1 )
		return false;
		
	ArrayList aPos;
	aPos = new ArrayList();
	hatchpos = TF2_GetBombHatchPosition();
	
	for(int i = 0;i < g_aEngyTeleport.Length;i++)
	{
	
		g_aEngyTeleport.GetArray(i, rVec);
		
		current_dist = GetVectorDistance(rVec, bombpos);
		
		// if the nest is closer to the hatch than the bomb itself, it's a forward nest
		if(GetVectorDistance(rVec, hatchpos) < GetVectorDistance(bombpos, hatchpos)) // forward
		{
			if( current_dist < smallest_dist && current_dist > min_dist && current_dist < max_forw_dist )
			{
				aPos.Push(i);
				smallest_dist = current_dist;
			}				
		}
		else // backward
		{
			if( current_dist < smallest_dist && current_dist > min_dist && current_dist < max_back_dist )
			{
				aPos.Push(i);
				smallest_dist = current_dist;
			}
		}
	}
	
	if(aPos.Length > 0)
	{
		iBestCell = aPos.Get(Math_GetRandomInt(0,aPos.Length - 1));
		delete aPos;
	}
	
	if( iBestCell != -1 )
	{
		g_aEngyTeleport.GetArray(iBestCell, origin);
		return true;
	}
	else
		return false;
}

// map specific config
void Config_LoadMap()
{
	char mapname[64], buffer[256], strNormalSpawns[512], strGiantSpawns[512], strSniperSpawns[512], strSpySpawns[512], configfile[PLATFORM_MAX_PATH];
	float origin[3];
	
	g_aSpyTeleport.Clear();
	g_aEngyTeleport.Clear();
	
	GetCurrentMap(buffer, sizeof(buffer));
	
	// Some servers might use workshop
	if( !GetMapDisplayName(buffer, mapname, sizeof(mapname)) )
	{
		strcopy(mapname, sizeof(mapname), buffer); // use the result from GetCurrentMap if this fails.
	}

	BuildPath(Path_SM, configfile, sizeof(configfile), "configs/bwrr/map/");
	Format(configfile, sizeof(configfile), "%s%s_server.cfg", configfile, mapname);
	
	if(!FileExists(configfile))
	{
		BuildPath(Path_SM, configfile, sizeof(configfile), "configs/bwrr/map/");
		Format(configfile, sizeof(configfile), "%s%s.cfg", configfile, mapname);		
	}

	if(!FileExists(configfile))
	{
		g_bPluginError = true;
		LogError("Map \"%s\" configuration not found. \"%s\"", mapname, configfile);
		return;
	}
	
#if defined DEBUG_GENERAL
	LogMessage("Loading Map Config file: \"%s\".", configfile);
#endif
	
	// reset some globals
	g_flGateStunDuration = 0.0;
	g_bDisableGateBots = false;
	g_bLimitRobotScale = false;
	
	KeyValues kv = new KeyValues("MapConfig");
	kv.ImportFromFile(configfile);
	
	// Jump into the first subsection
	if (!kv.GotoFirstSubKey())
	{
		delete kv;
		return;
	}
	
	do
	{
		kv.GetSectionName(buffer, sizeof(buffer));
		if( strcmp(buffer, "SpawnPoints", false) == 0 )
		{
			kv.GetString("normal", strNormalSpawns, sizeof(strNormalSpawns));
			kv.GetString("giant", strGiantSpawns, sizeof(strGiantSpawns));
			kv.GetString("sniper", strSniperSpawns, sizeof(strSniperSpawns));
			kv.GetString("spy", strSpySpawns, sizeof(strSpySpawns));
		}
		else if( strcmp(buffer, "HatchTrigger", false) == 0 )
		{
			kv.GetString("tank_relay", g_strHatchTrigger, sizeof(g_strHatchTrigger), "boss_deploy_relay");
			kv.GetString("cap_relay", g_strExploTrigger, sizeof(g_strExploTrigger), "cap_destroy_relay");
		}
		else if( strcmp(buffer, "Gatebot", false) == 0 )
		{
			g_flGateStunDuration = kv.GetFloat("stun_duration", 22.0);
			g_bDisableGateBots = !!kv.GetNum("force_disabled", 0);
		}
		else if( strcmp(buffer, "RobotScaling", false) == 0 )
		{
			g_bLimitRobotScale = !!kv.GetNum("limited_size", 0);
		}
		else if( strcmp(buffer, "SpyTeleport", false) == 0 )
		{
			kv.GotoFirstSubKey();
			
			do
			{
				kv.GetVector("origin", origin, NULL_VECTOR);
				g_aSpyTeleport.PushArray(origin);
			} while (kv.GotoNextKey());
			
			kv.GoBack();
		}
		else if( strcmp(buffer, "EngineerTeleport", false) == 0 )
		{
			kv.GotoFirstSubKey();
			
			do
			{
				kv.GetVector("origin", origin, NULL_VECTOR);
				g_aEngyTeleport.PushArray(origin);
			} while (kv.GotoNextKey());
			
			kv.GoBack();
		}
	} while (kv.GotoNextKey());
	
	delete kv;
	
	g_iSplitSize[0] = ExplodeString(strNormalSpawns, ",", g_strNormalSplit, sizeof(g_strNormalSplit), sizeof(g_strNormalSplit[]));
	g_iSplitSize[1] = ExplodeString(strGiantSpawns, ",", g_strGiantSplit, sizeof(g_strGiantSplit), sizeof(g_strGiantSplit[]));
	g_iSplitSize[2] = ExplodeString(strSniperSpawns, ",", g_strSniperSplit, sizeof(g_strSniperSplit), sizeof(g_strSniperSplit[]));
	g_iSplitSize[3] = ExplodeString(strSpySpawns, ",", g_strSpySplit, sizeof(g_strSpySplit), sizeof(g_strSpySplit[]));
	
#if defined DEBUG_GENERAL
	LogMessage("Finished parsing map config file. Found %i spy teleport points and %i engineer teleport points.", g_aSpyTeleport.Length, g_aEngyTeleport.Length);
#endif
}

// map specific config
void Config_AddTeleportPoint(int client,const int type)
{
	char mapname[64], buffer[256], configfile[PLATFORM_MAX_PATH];
	
	GetCurrentMap(buffer, sizeof(buffer));
	
	// Some servers might use workshop
	if( !GetMapDisplayName(buffer, mapname, sizeof(mapname)) )
	{
		strcopy(mapname, sizeof(mapname), buffer); // use the result from GetCurrentMap if this fails.
	}

	BuildPath(Path_SM, configfile, sizeof(configfile), "configs/bwrr/map/");
	Format(configfile, sizeof(configfile), "%s%s_server.cfg", configfile, mapname);
	
	if(!FileExists(configfile))
	{
		BuildPath(Path_SM, configfile, sizeof(configfile), "configs/bwrr/map/");
		Format(configfile, sizeof(configfile), "%s%s.cfg", configfile, mapname);		
	}

	if(!FileExists(configfile))
	{
		PrintToChat(client, "Map \"%s\" configuration not found. \"%s\"", mapname, configfile);
		return;
	}
	
	KeyValues kv = new KeyValues("MapConfig");
	kv.ImportFromFile(configfile);
	
	// Jump into the first subsection
	if (!kv.GotoFirstSubKey())
	{
		delete kv;
		return;
	}
	kv.GoBack();
	
	int counter;
	char key[8];
	float origin[3];
	GetClientAbsOrigin(client, origin);
	origin[2] += 10.0;
	
	switch(type)
	{
		case 0: // Spy
		{
			counter = g_aSpyTeleport.Length + 1;
			if(kv.JumpToKey("SpyTeleport", true))
			{
				FormatEx(key, sizeof(key), "%i", counter);
				if(kv.JumpToKey(key, true)) {
					FormatEx(buffer, sizeof(buffer), "%.1f %.1f %.1f", origin[0], origin[1], origin[2]);
					kv.SetString("origin", buffer);
					g_aSpyTeleport.PushArray(origin);
					CPrintToChat(client, "{green}[BWRR] {cyan}Added spy teleport point to origin \"%.1f %.1f %.1f\".", origin[0], origin[1], origin[2]);
				}
			}
		}
		case 1: // Engineer
		{
			counter = g_aEngyTeleport.Length + 1;
			if(kv.JumpToKey("EngineerTeleport", true))
			{
				FormatEx(key, sizeof(key), "%i", counter);
				if(kv.JumpToKey(key, true)) {
					FormatEx(buffer, sizeof(buffer), "%.1f %.1f %.1f", origin[0], origin[1], origin[2]);
					kv.SetString("origin", buffer);
					g_aEngyTeleport.PushArray(origin);
					CPrintToChat(client, "{green}[BWRR] {cyan}Added engineer teleport point to origin \"%.1f %.1f %.1f\".", origin[0], origin[1], origin[2]);
				}
			}			
		}
	}
	
	do {}
	while(kv.GoBack());
	
	kv.ExportToFile(configfile);
	delete kv;
}

bool IsSmallMap() { return g_bLimitRobotScale; }

void TF2_PlaySequence(int client, const char[] sequence)
{
	SDKCall(g_hSDKPlaySpecificSequence, client, sequence);
}

// code from Pelipoika's bot control
void DisableAnim(int userid)
{
	static int iCount = 0;

	int client = GetClientOfUserId(userid);
	if(client > 0)
	{
		if(iCount > 6)
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
			
			iCount = 0;
		}
		else
		{
			TF2_PlaySequence(client, "primary_deploybomb");			
			RequestFrame(DisableAnim, userid);
			iCount++;
		}
	}
}

void GetEntityWorldCenter(int ent, float[] origin)
{
	if( !IsValidEntity(ent) )
	{
		ThrowError("void GetEntityWorldCenter(int ent, float[] origin) received invalid ent!");
		return;
	}
	
	SDKCall(g_hSDKWorldSpaceCenter, ent, origin);
}

float[] TF2_GetBombHatchPosition(bool update = false)
{
	static float origin[3];
	
	if( update )
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

void HookRespawnRoom(int room)
{
	SDKUnhook(room, SDKHook_StartTouch, OnStartTouchRespawn);
	SDKUnhook(room, SDKHook_Touch, OnTouchRespawn);
	SDKUnhook(room, SDKHook_EndTouch, OnEndTouchRespawn);
	SDKHook(room, SDKHook_StartTouch, OnStartTouchRespawn);
	SDKHook(room, SDKHook_Touch, OnTouchRespawn);
	SDKHook(room, SDKHook_EndTouch, OnEndTouchRespawn);
}

/****************************************************
					SPAWN ROOMS
*****************************************************/

// Searches for spawnroom entities that already exists in the map
void FindSpawnRoomsInTheMap()
{
	g_aSpawnRooms.Clear();
	
	int i = -1;
	while((i = FindEntityByClassname(i, "func_respawnroom")) != -1)
	{
		if(IsValidEntity(i))
		{
			if(GetEntProp(i, Prop_Send, "m_iTeamNum") == 3) // for now we only care about BLU respawn rooms.
			{
				g_aSpawnRooms.Push(EntIndexToEntRef(i));
			}
		}
	}	
}

void AddAdditionalSpawnRooms()
{
	if(g_bSkipSpawnRoom) // all info_player_teamspawn in this map are inside a func_respawnroom, skip
		return;

	int i = -1, trigger;
	float origin[3];
	bool created;
	
	FindSpawnRoomsInTheMap();
	
	while((i = FindEntityByClassname(i, "func_respawnroom")) != -1)
	{
		if(IsValidEntity(i))
		{
			char targetname[50];
			GetEntPropString(i, Prop_Data, "m_iName", targetname, sizeof(targetname));
			if(strcmp(targetname, "bwrr_respawnroom") == 0)
			{
#if defined DEBUG_GENERAL
				LogMessage("Skipping AddAdditionalSpawnRooms() because we've already created additional spawn rooms.");
#endif
				return; // we've already created extras spawnrooms.
			}
		}
	}
	
	i = -1;
	while((i = FindEntityByClassname(i, "info_player_teamspawn")) != -1)
	{
		if(IsValidEntity(i))
		{
			if( GetEntProp( i, Prop_Send, "m_iTeamNum" ) == view_as<int>(TFTeam_Blue) )
			{
				bool canskip;
				for(int y = 0;y < g_aSpawnRooms.Length;y++) // search existing spawnrooms
				{
					trigger = EntRefToEntIndex(g_aSpawnRooms.Get(y));
					if(trigger != INVALID_ENT_REFERENCE)
					{
						GetEntPropVector(i, Prop_Send, "m_vecOrigin", origin);
						if(SDKIsPointWithIn(trigger, origin)) { canskip = true; } // check if info_player_teamspawn is already inside a func_respawnroom
					}
				}
				
				if(!canskip)
				{
					CreateSpawnRoom(i);
					FindSpawnRoomsInTheMap(); // update list so we don't create unnecessary spawnrooms
					created = true;
				}
#if defined DEBUG_GENERAL
				else
				{
					LogMessage("Skipping info_player_teamspawn %i at %.1f %.1f %.1f because it's already inside the boundaries of a func_respawnroom", i, origin[0], origin[1], origin[2]);
				}
#endif
			}
		}
	}
	
	g_bSkipSpawnRoom = !created;
}

void CreateSpawnRoom(int spawnpoint)
{
	int ent = CreateEntityByName("func_respawnroom");
	
	if( ent == -1 )
	{
		ThrowError("Failed to create func_respawnroom.");
		return;
	}
		
	DispatchKeyValue(ent, "StartDisabled", "0");
	DispatchKeyValue(ent, "TeamNum", "3");
	DispatchKeyValue(ent, "targetname", "bwrr_respawnroom");
	DispatchSpawn(ent); // spawn ent
	ActivateEntity(ent);
	
	PrecacheModel("models/player/items/pyro/drg_pyro_fueltank.mdl");
	SetEntityModel(ent, "models/player/items/pyro/drg_pyro_fueltank.mdl");
	
	static float mins[3] = {-150.0,-150.0,-200.0};
	static float maxs[3] = {150.0,150.0,200.0};
	
	SetEntPropVector(ent, Prop_Send, "m_vecMins", mins);
	SetEntPropVector(ent, Prop_Send, "m_vecMaxs", maxs);
	
	SetEntProp(ent, Prop_Send, "m_nSolidType", 2);
	
	int enteffects = GetEntProp(ent, Prop_Send, "m_fEffects");
	enteffects |= 32;
	SetEntProp(ent, Prop_Send, "m_fEffects", enteffects);
	
	float pos[3];
	GetEntPropVector(spawnpoint, Prop_Send, "m_vecOrigin", pos);
	TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
	HookRespawnRoom(ent);
#if defined DEBUG_GENERAL	
	LogMessage("Creating func_respawnroom at (%.1f %.1f %.1f) index %i", pos[0], pos[1], pos[2], ent);
#endif
}

// code from Pelipoika's bot control
// executes a delayed command on the client
bool FakeClientCommandThrottled(int client, const char[] command)
{
	if(g_flNextCommand[client] > GetGameTime())
		return false;
	
	FakeClientCommand(client, command);
	
	g_flNextCommand[client] = GetGameTime() + 0.4;
	
	return true;
}

void SetBLURespawnWaveTime(float time)
{
	int ent = FindEntityByClassname(-1, "tf_gamerules");
	if(IsValidEntity(ent))
	{
		SetVariantFloat(time);
		AcceptEntityInput(ent, "SetBlueTeamRespawnWaveTime");
	}
}

/****************************************************
					GATEBOTS
*****************************************************/

// checks for RED owned team_control_point
bool IsGatebotAvailable(bool update = false)
{
	static bool isavailable;
	
	if(g_bDisableGateBots)
	{
#if defined DEBUG_GENERAL
		CPrintToChatAll("{green}IsGatebotAvailable::{cyan} Gatebot disabled by config file.");
#endif
		return false;
	}
	
	if(update)
	{
		int ent = -1;
		while((ent = FindEntityByClassname(ent, "team_control_point")) != -1)
		{
			if(IsValidEntity(ent))
			{
				if(GetEntProp(ent, Prop_Send, "m_iTeamNum") == view_as<int>(TFTeam_Red))
				{
#if defined DEBUG_GENERAL
					CPrintToChatAll("{green}IsGatebotAvailable::{cyan} Found {red}RED{cyan} owned {orange}team_control_point{cyan}.");
#endif
					isavailable = true;
					return isavailable;
				}
			}
		}
#if defined DEBUG_GENERAL
		CPrintToChatAll("{green}IsGatebotAvailable::{cyan} Did not found any {orange}team_control_point{cyan} owned by {red}RED{cyan} team.");
#endif
		isavailable = false;
	}
	
	return isavailable;
}

// a gate has been taken by the robots
void GateCapturedByRobots()
{
	if(g_bDisableGateBots)
		return; // Do nothing on gate capture if gatebots are disabled via config

	g_flGateStunTime = GetGameTime() + g_flGateStunDuration;
	for(int i = 1;i <= MaxClients;i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 3 && !IsFakeClient(i) && IsPlayerAlive(i) && !TF2_IsGiant(i))
		{
			TF2_AddCondition(i, TFCond_MVMBotRadiowave, g_flGateStunDuration);
			TF2_StunPlayer(i, g_flGateStunDuration, 0.0, TF_STUNFLAG_LIMITMOVEMENT|TF_STUNFLAG_BONKSTUCK|TF_STUNFLAG_THIRDPERSON|TF_STUNFLAG_NOSOUNDOREFFECT);
			CreateGateStunParticle("bot_radio_waves", g_flGateStunDuration, i);
#if defined DEBUG_PLAYER
			CPrintToChat(i, "{green}[DEBUG] {cyan}GateCapturedByRobots() applying stun to client %N, stun time: %f", i, g_flGateStunDuration);
#endif
		}
	}
}

// applies gate stun to a client, stun duration depends on stun time left
void ApplyGateStunToClient(int client)
{
	float stuntime = g_flGateStunTime - GetGameTime();
	TF2_AddCondition(client, TFCond_MVMBotRadiowave, stuntime);
	TF2_StunPlayer(client, stuntime, 0.0, TF_STUNFLAG_LIMITMOVEMENT|TF_STUNFLAG_BONKSTUCK|TF_STUNFLAG_THIRDPERSON|TF_STUNFLAG_NOSOUNDOREFFECT);
#if defined DEBUG_PLAYER
	CPrintToChat(client, "{green}[DEBUG] {cyan}ApplyGateStunToClient(%i) stuntime: %f", client, stuntime);
#endif
}

// checks if the gate stun is active
bool IsGateStunActive()
{
	if(g_flGateStunTime > GetGameTime())
	{
		return true;
	}
	
	return false;
}

/****************************************************
					LATE LOAD
*****************************************************/

// Add hook to entities on plugin late load
// Some entities are only hooked on OnEntityCreated which is not fired when you late load a plugin
void HookEntitiesOnLateLoad()
{
	int ent = -1;
	while((ent = FindEntityByClassname(ent, "func_capturezone")) != -1)
	{
		if(IsValidEntity(ent))
		{
			SDKUnhook(ent, SDKHook_StartTouch, OnTouchCaptureZone); // propably not needed but added just for safety
			SDKUnhook(ent, SDKHook_EndTouch, OnEndTouchCaptureZone);
			SDKHook(ent, SDKHook_StartTouch, OnTouchCaptureZone);
			SDKHook(ent, SDKHook_EndTouch, OnEndTouchCaptureZone);			
		}
	}
	ent = -1;
	while((ent = FindEntityByClassname(ent, "func_respawnroom")) != -1)
	{
		if(IsValidEntity(ent))
		{
			HookRespawnRoom(ent);		
		}
	}
}

/****************************************************
					CONVARS VALUES
*****************************************************/

int BotNoticeBackstabChance(bool update = false)
{
	static int chance;
	
	if(update)
	{
		chance = GetConVarInt(FindConVar("tf_bot_notice_backstab_chance"));
	}
	
	return chance;
}

int BotNoticeBackstabMaxRange(bool update = false)
{
	static int range;
	
	if(update)
	{
		range = GetConVarInt(FindConVar("tf_bot_notice_backstab_max_range"));
	}
	
	return range;
}

/****************************************************
					CREATE EVENTS
*****************************************************/

void CreateAnnotation(float pos[3], int client, char[] message, int offset, float lifetime = 8.0, int followentity = -1)
{
	Event event = CreateEvent("show_annotation");
	if(event != null)
	{
		event.SetFloat("worldPosX", pos[0]);
		event.SetFloat("worldPosY", pos[1]);
		event.SetFloat("worldPosZ", pos[2]);
		event.SetFloat("lifetime", lifetime);
		event.SetInt("id", client + offset + GetRandomInt(0,5000));
		if (followentity != -1) { event.SetInt("follow_entindex", followentity); }
		event.SetString("text", message);
		event.SetString("play_sound", "ui/hint.wav");
		event.SetString("show_effect", "1");
		event.SetString("show_distance", "1");
		event.SetInt("visibilityBitfield", 1 << client);
		event.Fire();		
	}
}

/****************************************************
					SPY DISGUISE OVERRIDE
*****************************************************/

void SpyDisguiseClear(int client)
{
	for(int i=0; i<4; i++)
	{
		SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", 0, _, i);
	}

	g_nDisguised[client].g_iDisguisedClass = 0;
	g_nDisguised[client].g_iDisguisedTeam = 0;
}

void SpyDisguiseThink(int client, int disguiseclass, int disguiseteam)
{
	int team = GetClientTeam(client);
	
	// m_nModelIndexOverrides works differently on MvM
	// it seems index 0 is used for both RED and BLU teams.
	
	switch(team)
	{
		case 2: // RED
		{
			if(disguiseteam == view_as<int>(TFTeam_Red))
			{
				// RED spy disguised as a RED team member, should look like a RED human
				SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", g_iModelIndexHumans[disguiseclass], _, 0);
			}
			else if(OR_IsHalloweenMission())
			{
				// RED spy disguised as a BLU team member, should look like a BLU human on wave 666
				SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", g_iModelIndexHumans[disguiseclass], _, 0);
			}
			else
			{
				// RED spy disguised as a BLU team member, should look like a BLU robot
				SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", g_iModelIndexRobots[disguiseclass], _, 0);					
			}
		}
		case 3: // BLU
		{
			if(disguiseteam == view_as<int>(TFTeam_Red))
			{
				// BLU spy disguised as a RED team member, should look like a RED human
				SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", g_iModelIndexHumans[disguiseclass], _, 0);
			}
			else if(OR_IsHalloweenMission())
			{
				// BLU spy disguised as a BLU team member, should look like a BLU human on wave 666
				SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", g_iModelIndexHumans[disguiseclass], _, 0);				
			}
			else
			{
				// BLU spy disguised as a BLU team member, should look like a BLU robot
				SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", g_iModelIndexRobots[disguiseclass], _, 0);
			}			
		}
	}
}

/****************************************************
					REQUEST FRAME FUNCTIONS
*****************************************************/

// called when an engineer robot is killed
void FrameEngineerDeath(int userid)
{
	int client = GetClientOfUserId(userid);
	if(client <= 0)
		return;
		
	static const char strobjects[3][16] = { "obj_sentrygun", "obj_dispenser", "obj_teleporter" };
	
	int i;
	for(int x = 0;x < sizeof(strobjects);x++)
	{
		i = -1;
		while((i = FindEntityByClassname(i, strobjects[x])) != -1)
		{
			if(IsValidEntity(i))
			{
				if(client == GetEntPropEnt(i, Prop_Send, "m_hBuilder"))
				{
					SDKTFPlayerRemoveObject(client, i);
					SetEntPropEnt(i, Prop_Send, "m_hBuilder", -1);
				}
			}
		}
	}
}

// called when a BLU client ( bot or human ) is killed by backstab
void FrameBLUBackstabbed(DataPack pack)
{
	pack.Reset();
	int victim = GetClientOfUserId(pack.ReadCell());
	int attacker = GetClientOfUserId(pack.ReadCell());
	
	float victimpos[3], attackerpos[3], testpos[3];
	float distance;
	
	GetClientAbsOrigin(victim, victimpos);
	GetClientAbsOrigin(attacker, attackerpos);
	
	for(int i = 1;i <= MaxClients;i++)
	{
		if(i == victim || i == attacker) // skip victim & attacker
			continue;
			
		if(!IsClientInGame(i)) // must be in game
			continue;
			
		if(IsFakeClient(i)) // no need to alert bots
			continue;
			
		if(GetClientTeam(i) != 3) // must be BLU
			continue;
			
			
		if(Math_GetRandomInt(0,100) > BotNoticeBackstabChance()) // chance of detecting
			continue;
			
		GetClientAbsOrigin(i, testpos);
		distance = GetVectorDistance(victimpos, testpos);
		
		if(RoundToNearest(distance) > BotNoticeBackstabMaxRange()) // out of range
			continue;
			
		CreateAnnotation(attackerpos, i, "Enemy Spy!", 9, 5.0);
		g_flinstructiontime[i] = GetGameTime() + 7.0;
	}
	
	delete pack;
}

// checks if we can teleport a flag to the player upon spawning
void FrameCheckFlagForPickUp(int userid)
{
	int client = GetClientOfUserId(userid);
	if(client <= 0)
		return;
	
	RoboPlayer rp = RoboPlayer(client);
	
	if(rp.Attributes & BotAttrib_CannotCarryBomb)
		return;
	
	int i = -1;
	while((i = FindEntityByClassname(i, "item_teamflag")) != -1)
	{
		if(IsValidEntity(i) && GetEntProp(i, Prop_Send, "m_iTeamNum") == view_as<int>(TFTeam_Blue) && GetEntProp( i, Prop_Send, "m_bDisabled" ) == 0) // valid BLU team flag
		{
			if(TF2_IsFlagHome(i))
			{
				TF2_PickUpFlag(client, i);
				rp.Carrier = true;
				RequestFrame(UpdateBombHud, userid);
			}
		}
	}
}

// checks if this client should be blocked from picking up the bomb
void FrameShouldBlockBombPickUp(int userid)
{
	int client = GetClientOfUserId(userid);
	if(client <= 0)
		return;
	
	RoboPlayer rp = RoboPlayer(client);
	
	if(rp.Attributes & BotAttrib_CannotCarryBomb)
	{
		BlockBombPickup(client);
	}
}

void FramePickNewRobot(int userid)
{
	int client = GetClientOfUserId(userid);
	if(client <= 0)
		return;

	if(IsFakeClient(client))
		return;
	
	PickRandomRobot(client);
}

// code from Pelipoika's bot control
// Updates the bomb level show on the HUD
void UpdateBombHud(int userid)
{
	int client = GetClientOfUserId(userid);
	if(client <= 0)
		return;
		
	RoboPlayer rp = RoboPlayer(client);
		
	int iResource = FindEntityByClassname(-1, "tf_objective_resource");
	SetEntProp(iResource,      Prop_Send, "m_nFlagCarrierUpgradeLevel", rp.BombLevel);
	SetEntPropFloat(iResource, Prop_Send, "m_flMvMBaseBombUpgradeTime", (TF2_IsPlayerInCondition(client, TFCond_UberchargedHidden)) ? -1.0 : GetGameTime());
	SetEntPropFloat(iResource, Prop_Send, "m_flMvMNextBombUpgradeTime", (TF2_IsPlayerInCondition(client, TFCond_UberchargedHidden)) ? -1.0 : rp.UpgradeTime);	
}

void KillReviveMaker(int entref)
{
	int ent = EntRefToEntIndex(entref);
	if(ent == INVALID_ENT_REFERENCE)
		return;
		
	int iTeam = GetEntProp(ent, Prop_Send, "m_iTeamNum");
	if(iTeam != 3)
		return;
		
	RemoveEntity(ent);
}

void KillAmmoPack(int entref)
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

void FrameCheckForUnbalance(int client)
{
	// Balanced: BLU is empty
	if( GetHumanRobotCount() == 0 )
		return;
		
	int minred = c_iMinRed.IntValue - 1;
	int inred = GetTeamClientCount(view_as<int>(TFTeam_Red));

	// Unbalanced: There are less players on RED than the minimum amount
	if( inred < minred )
	{
		CPrintToChatAll("%t", "Unbalance_Warning");
		LogMessage("Unbalance detected! Players in RED Team: %i || Players in BLU Team: %i || Min RED Players: %i", inred, GetHumanRobotCount(), minred);
	}
}

/****************************************************
					TEAM CHANGE
*****************************************************/

void PreChangeTeam(int client, const int team)
{
	int flag = TF2_GetClientFlag(client);
	if(IsValidEntity(flag)) { TF2_ResetFlag(flag); }

	switch(team)
	{
		case 1: // SPECTATOR
		{
			if(FindConVar("mp_allowspectators").BoolValue)
			{
				DataPack pack = new DataPack();
				pack.WriteCell(client);
				pack.WriteCell(team);
				RequestFrame(FrameChangeClientTeam, pack);
			}
		}
		case 2: // RED
		{
			DataPack pack = new DataPack();
			pack.WriteCell(client);
			pack.WriteCell(team);
			RequestFrame(FrameChangeClientTeam, pack);
		}
		case 3: // BLU
		{
			DataPack pack = new DataPack();
			pack.WriteCell(client);
			pack.WriteCell(team);
			RequestFrame(FrameChangeClientTeam, pack);
		}
	}
}

void FrameChangeClientTeam(DataPack pack)
{
	pack.Reset();
	int client = pack.ReadCell();
	int team = pack.ReadCell();
	switch(team)
	{
		case 1: // SPECTATOR
		{
			MovePlayerToSpec(client);
		}
		case 2: // RED
		{
			MovePlayerToRED(client);
		}
		case 3: // BLU
		{
			MovePlayerToBLU(client);
		}
	}
	delete pack;
}

// moves player to RED
void MovePlayerToRED(int client)
{
	StopRobotLoopSound(client);
	ScalePlayerModel(client, 1.0);
	ResetRobotData(client, true);
	SetVariantString( "" );
	AcceptEntityInput( client, "SetCustomModel" );
	LogMessage("Player \"%L\" joined RED team.", client);
	int iEntFlags = GetEntityFlags( client );
	SetEntityFlags( client, iEntFlags | FL_FAKECLIENT );
	TF2_ChangeClientTeam( client, TFTeam_Red );
	SetEntityFlags( client, iEntFlags );
	SetEntProp( client, Prop_Send, "m_bIsMiniBoss", 0 );
	TF2Attrib_RemoveAll(client);
	TF2Attrib_ClearCache(client);
	
	if( TF2_GetPlayerClass(client) == TFClass_Unknown )
		ShowVGUIPanel(client, "class_red");
}

// moves players to spectator
void MovePlayerToSpec(int client)
{
	if(IsFakeClient(client))
		return;

	StopRobotLoopSound(client);
	ScalePlayerModel(client, 1.0);
	ResetRobotData(client, true);
	SetVariantString( "" );
	AcceptEntityInput( client, "SetCustomModel" );
	SetEntProp( client, Prop_Send, "m_nBotSkill", BotSkill_Easy );
	SetEntProp( client, Prop_Send, "m_bIsMiniBoss", 0 );
	LogMessage("Player \"%L\" joined SPECTATOR team.", client);
	TF2_ChangeClientTeam(client, TFTeam_Spectator);
}

// moves player to BLU team.
void MovePlayerToBLU(int client)
{
	if(IsFakeClient(client))
		return;

	StopRobotLoopSound(client);
	ForcePlayerSuicide(client);
	SetEntProp( client, Prop_Send, "m_nBotSkill", BotSkill_Easy );
	SetEntProp( client, Prop_Send, "m_bIsMiniBoss", 0 );
	
	int iEntFlags = GetEntityFlags( client );
	SetEntityFlags( client, iEntFlags | FL_FAKECLIENT );
	TF2_ChangeClientTeam(client, TFTeam_Blue);
	SetEntityFlags( client, iEntFlags );
	LogMessage("Player \"%L\" joined BLU team.", client);
	
	ScalePlayerModel(client, 1.0);
	PickRandomRobot(client);
}

/****************************************************
					WEAPONS
*****************************************************/

int GetWeaponMaxClip(int weapon)
{
	return SDKCall(g_hSDKGetMaxClip, weapon);
}

int GetWeaponClip(int weapon)
{
	return SDKCall(g_hSDKGetClip, weapon);
}

void SetWeaponClip(int weapon, int clip)
{
	int offset = FindSendPropInfo("CTFWeaponBase", "m_iClip1");
	SetEntData(weapon, offset, clip, 4, true);
}

// List of weapon indexes that can be used while inside spawn
bool CanWeaponBeUsedInsideSpawn(int index)
{
	switch( index )
	{
		case 46,163,1145,129,226,354,1001,42,159,311,433,863,1002,1190:
		{
			return true;
		}
		default: return false;
	}
}

/****************************************************
					BOMB/FLAG
*****************************************************/

bool TF2_HasFlag(int client)
{
	int iFlag = GetEntPropEnt(client, Prop_Send, "m_hItem");
	
	if(iFlag != INVALID_ENT_REFERENCE && GetEntPropEnt(iFlag, Prop_Send, "moveparent") == client)
	{
		return true;
	}
	
	return false;
}

int TF2_GetClientFlag(int client)
{
	int iFlag = GetEntPropEnt(client, Prop_Send, "m_hItem");
	
	if(iFlag != INVALID_ENT_REFERENCE && GetEntPropEnt(iFlag, Prop_Send, "moveparent") == client)
	{
		return iFlag;
	}
	
	return -1;	
}

void TF2_PickUpFlag(int client, int flag)
{
	SDKCall(g_hSDKPickupFlag, flag, client, true);
}

bool TF2_IsFlagHome(int flag)
{
	return SDKCall(g_hSDKIsFlagHome, flag);
}

void TF2_ResetFlag(int flag)
{
	if(IsValidEntity(flag))
	{
		AcceptEntityInput(flag, "ForceReset");
	}
}

/****************************************************
					INSTRUCTIONS
*****************************************************/

void BWRR_InstructPlayer(int client)
{
	if(g_flinstructiontime[client] > GetGameTime()) { return; }

	RoboPlayer rp = RoboPlayer(client);
	float pos[3];
	
	if(rp.Type == Bot_Buster) { return; } // Ignore sentry busters
	
	g_flinstructiontime[client] = GetGameTime() + 30.0;
	
	if(rp.Carrier) // prove instructions to deploy the bomb
	{
		pos = TF2_GetBombHatchPosition();
		CreateAnnotation(pos, client, "Deploy the bomb!", 1, 10.0);
		return;
	}
	
	if(rp.Gatebot)
	{
		int trigger = -1;
		while ((trigger = FindEntityByClassname(trigger, "trigger_timer_door")) != -1)
		{
			bool bFound;
			bool bDisabled = !!GetEntProp(trigger, Prop_Data, "m_bDisabled");
			if(bDisabled)
				continue;
				
			char cpname[32]; // some community maps doesn't disable trigger_timer_door when it's capped
			GetEntPropString(trigger, Prop_Data, "m_iszCapPointName", cpname, sizeof(cpname));
			
			if(strlen(cpname) < 3) // trigger_timer_door without associated control point
				continue;
			
			int controlpoint = -1;
			while((controlpoint = FindEntityByClassname(controlpoint, "team_control_point")) != -1) // search for matching team_control_point
			{
				char targetname[32];
				GetEntPropString(controlpoint, Prop_Data, "m_iName", targetname, sizeof(targetname));
				if(strcmp(targetname, cpname, false) == 0)
				{
					if(GetEntProp(controlpoint, Prop_Send, "m_iTeamNum") == view_as<int>(TFTeam_Red)) // RED owned control point
					{
						bFound = true;
						break;
					}
				}
			}
			
			if(bFound)
			{
				GetEntityWorldCenter(trigger, pos);
				CreateAnnotation(pos, client, "Capture!", 2, 10.0);
				return;
			}
		}
	}
	
	Address Addr = TF2Attrib_GetByName(client, "cannot pick up intelligence");
	if(Addr == Address_Null) // player can pick up the bomb
	{
		int bomb = -1;
		while ((bomb = FindEntityByClassname(bomb, "item_teamflag")) != -1)
		{
			// Ignore bomb if it is at home
			if(TF2_IsFlagHome(bomb))
				continue;
			
			// Ignore bombs from other teams
			if(GetEntProp(bomb, Prop_Send, "m_iTeamNum") != view_as<int>(TFTeam_Blue))
				continue;
			
			// Ignore disabled bombs
			if(GetEntProp(bomb, Prop_Send, "m_bDisabled") == 1)
				continue;
				
			int moveparent = GetEntPropEnt(bomb, Prop_Send, "moveparent");
			if(moveparent != -1 && moveparent <= MaxClients)
			{
				CreateAnnotation(NULL_VECTOR, client, "Escort the bomb carrier!", 2, 10.0, moveparent);
				return;
			}
			else
			{
				CreateAnnotation(NULL_VECTOR, client, "Pick up the bomb!", 2, 10.0, bomb);
				return;				
			}
		}
	}
	
	if(TF2_GetPlayerClass(client) == TFClass_Spy)
	{
		int bestplayer = -1;
		float smallest_dist = 999999.0, distance;
		float mypos[3], targetpos[3];
		GetClientAbsOrigin(client, mypos);
		for(int i = 1;i <= MaxClients;i++)
		{
			if(i == client) // skip self
				continue;
				
			if(!IsClientInGame(i)) // skip if clients are not in game
				continue;
				
			if(GetClientTeam(i) != 2) // skip if player is NOT RED
				continue;
				
			if(!IsPlayerAlive(i)) // skip dead players
				continue;
				
			GetClientAbsOrigin(i, targetpos);
			distance = GetVectorDistance(mypos, targetpos);
			
			if(distance < smallest_dist)
			{
				smallest_dist = distance;
				bestplayer = i;
			}
		}
		
		if(bestplayer != -1)
		{
			char msg[64];
			FormatEx(msg, sizeof(msg), "Kill %N", bestplayer);
			CreateAnnotation(NULL_VECTOR, client, msg, 4, 10.0, bestplayer);
			return;
		}
	}
	
	int tankboss = -1;
	while ((tankboss = FindEntityByClassname(tankboss, "tank_boss")) != -1)
	{
		if(GetEntProp(tankboss, Prop_Send, "m_iTeamNum") != 3)
			continue;
			
		CreateAnnotation(NULL_VECTOR, client, "Protect the tank!", 2, 10.0, tankboss);
		return;
	}
}

void BWRR_RemoveSpawnProtection(int client)
{
	RoboPlayer rp = RoboPlayer(client);
	rp.ProtectionTime = -1.0;
	rp.InSpawn = false;
	TF2_RemoveCondition(client, TFCond_UberchargedHidden);
}