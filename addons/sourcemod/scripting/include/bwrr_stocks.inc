#if defined _bwrr_stocks_included
 #endinput
#endif
#define _bwrr_stocks_included

#include <tf2_stocks>

enum
{
	TF_FLAGINFO_HOME = 0, // Flag is at home
	TF_FLAGINFO_STOLEN = (1<<0), // Flag is stolen
	TF_FLAGINFO_DROPPED = (1<<1) // Flag is dropped
};

/**
 * Gets a TF2 flag (item_teamflag) status.
 *
 * @param flag          Flag entity index.
 * @return              Flag current status.
 * @error               Invalid entity or entity is not a flag.
 */
stock int TF2_GetFlagStatus(int flag)
{
	if(!IsValidEntity(flag)) 
	{ 
		ThrowError("Invalid flag entity %i!", flag); 
	}

	if(!HasEntProp(flag, Prop_Send, "m_nFlagStatus"))
	{
		ThrowError("Entity %i does not have \"m_nFlagStatus\"!", flag);
	}

	return GetEntProp(flag, Prop_Send, "m_nFlagStatus");
}

/**
 * Checks if a TF2 flag (item_teamflag) is home.
 *
 * @param flag          Flag entity index.
 * @return              TRUE if the flag is home.
 * @error               Invalid entity or entity is not a flag.
 */
stock bool TF2_IsFlagHome(int flag)
{
	return TF2_GetFlagStatus(flag) == TF_FLAGINFO_HOME;
}

/**
 * Checks if a TF2 flag (item_teamflag) is stolen.
 *
 * @param flag          Flag entity index.
 * @return              TRUE if the flag is stolen.
 * @error               Invalid entity or entity is not a flag.
 */
stock bool TF2_IsFlagStolen(int flag)
{
	return TF2_GetFlagStatus(flag) == TF_FLAGINFO_STOLEN;
}

/**
 * Checks if a TF2 flag (item_teamflag) is dropped.
 *
 * @param flag          Flag entity index.
 * @return              TRUE if the flag is dropped.
 * @error               Invalid entity or entity is not a flag.
 */
stock bool TF2_IsFlagDropped(int flag)
{
	return TF2_GetFlagStatus(flag) == TF_FLAGINFO_DROPPED;
}

/**
 * Gets a random flag for the given team that is sitting at home
 * 
 * @param team     The flag's team
 * @return         Entity index if found or -1 if not found
 */
stock int TF2_GetRandomFlagAtHome(int team)
{
	int entity = INVALID_ENT_REFERENCE;
	while((entity = FindEntityByClassname(entity, "item_teamflag")) != INVALID_ENT_REFERENCE)
	{
		if(GetEntProp(entity, Prop_Send, "m_iTeamNum") == team && GetEntProp(entity, Prop_Send, "m_bDisabled") == 0)
		{
			if(TF2_IsFlagHome(entity))
			{
				return entity;
			}
		}
	}

	return INVALID_ENT_REFERENCE;
}

/**
 * Checks if the given client is carrying a flag
 *
 * @param client	The client to check
 * @return     True if carrying a flag
 */
stock bool TF2_HasFlag(int client)
{
	int iFlag = GetEntPropEnt(client, Prop_Send, "m_hItem");
	
	if(iFlag != INVALID_ENT_REFERENCE && GetEntPropEnt(iFlag, Prop_Send, "moveparent") == client)
	{
		return true;
	}
	
	return false;
}

/**
 * Gets the entity index of the flag being carried by the client
 *
 * @param client	The client to get the flag from
 * @return     Flag entity index or -1 if no flag was found
 */
stock int TF2_GetClientFlag(int client)
{
	int iFlag = GetEntPropEnt(client, Prop_Send, "m_hItem");
	
	if(iFlag != INVALID_ENT_REFERENCE && GetEntPropEnt(iFlag, Prop_Send, "moveparent") == client)
	{
		return iFlag;
	}
	
	return -1;	
}

/**
 * Checks if the given weapon classname is a wearable
 *
 * @param classname        	The weapon's classname
 * @return					TRUE if the given weapon is a wearable
 */
stock bool TF2_IsWeaponAWearable(char[] classname)
{
	char strWearables[3][] = {"tf_wearable_demoshield", "tf_wearable_razorback", "tf_wearable"};
	
	for(int i = 0;i < sizeof(strWearables);i++)
	{
		if(strcmp(classname, strWearables[i], false) == 0) {
			return true;
		}
	}
	
	return false;
}

/**
 * Gets the Objective Resource entity index.
 *
 * @return					entity index if found or -1 if not found
 */
stock int TF2_GetObjectiveResourceEntity()
{
	int entity = FindEntityByClassname(-1, "tf_objective_resource");

	if(IsValidEntity(entity)) // Validate here so we don't to validade it later
	{
		return entity;
	}

	return -1;
}

/**
 * Gets the current MvM mission name
 *
 * @param name			Buffer to store the mission name
 * @param size			Buffer size
 */
stock void TF2MvM_GetMissionName(char[] name, int size)
{
	int entity = TF2_GetObjectiveResourceEntity();
	GetEntPropString(entity, Prop_Send, "m_iszMvMPopfileName", name, size);
	ReplaceString(name, size, "scripts/population/", "");
	ReplaceString(name, size, ".pop", "");
}

/**
 * Gets the current wave number in MvM
 *
 * @return			Current wave number
 */
stock int TF2MvM_GetCurrentWave()
{
	int entity = TF2_GetObjectiveResourceEntity();
	return GetEntProp(entity, Prop_Send, "m_nMannVsMachineWaveCount");
}

/**
 * Gets how many waves the current mission has
 *
 * @return			Current wave number
 */
stock int TF2MvM_GetMaxWave()
{
	int entity = TF2_GetObjectiveResourceEntity();
	return GetEntProp(entity, Prop_Send, "m_nMannVsMachineMaxWaveCount");
}

/**
 * Gets the wave percentage.
 * Note: This is in relation to the total number of waves, NOT the current wave.
 *
 * @return			The wave percentage ranging from 0 to 1
 */
stock float TF2MvM_GetWavePercent()
{
	int current = TF2MvM_GetCurrentWave();
	int max = TF2MvM_GetMaxWave();
	float percent = current/float(max);
	return percent;
}

/**
 * Gets the completed wave percentage.
 * Note: This is in relation to the total number of waves, NOT the current wave.
 *
 * @return			The completed wave percentage ranging from 0 to 1
 */
stock float TF2MvM_GetCompletedWavePercent()
{
	int current = TF2MvM_GetCurrentWave() - 1;
	int max = TF2MvM_GetMaxWave();
	float percent = current/float(max);
	return percent;
}

/**
 * Checks if the current mission only has one wave
 *
 * @return			TRUE if the current mission only has one wave
 */
stock bool TF2MvM_IsSingleWave()
{
	return TF2MvM_GetMaxWave() == 1;
}

/**
 * Checks if the current mission is a halloween event mission (wave 666)
 *
 * @return			TRUE if the current mission is a halloween event
 */
stock bool TF2MvM_IsHalloweenMission()
{
	int entity = TF2_GetObjectiveResourceEntity();
	return GetEntProp(entity, Prop_Send, "m_nMvMEventPopfileType") == 1;
}

/**
 * Checks if the current mission is a halloween event mission (wave 666)
 *
 * @param mins			Vector to store Mins
 * @param maxs			Vector to store Maxs
 */
stock void TF2_GetPlayerHullSize(float mins[3], float maxs[3])
{
	mins[0] = -24.0; 
	mins[1] = -24.0;
	mins[2] = 0.0;
	maxs[0] = 24.0;
	maxs[1] = 24.0;
	maxs[2] = 82.0;
}