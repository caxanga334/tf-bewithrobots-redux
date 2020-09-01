// reads data from tf_objective_resource
// special thanks to Pelipoika

char g_strMissionName[128];
int iCurrentWave; // current wave
int iMaxWave; // total wave
int iPopFileType; // Event popfile?
int iAvailableClasses = 0; // which classes are available for the current wave // bit
//bool bClasses[11]; // temporary solution

enum // class bits
{
	none = 0,
	scout_normal = 1,
	soldier_normal = 2,
	pyro_normal = 4,
	demoman_normal = 8,
	heavy_normal = 16,
	engineer_normal = 32,
	medic_normal = 64,
	sniper_normal = 128,
	spy_normal = 256,
	sentrybuster = 512,
	scout_giant = 1024,
	soldier_giant = 2048,
	pyro_giant = 4096,
	demoman_giant = 8192,
	heavy_giant = 16384,
	engineer_giant = 32768,
	medic_giant = 65536,
	sniper_giant = 131072,
	spy_giant = 262144,
};

enum MvMWaveClassFlags
{
	CLASSFLAG_NORMAL          = (1 << 0), // set for non-support bots and tanks
	CLASSFLAG_SUPPORT         = (1 << 1), // set for "support 1" and "support limited" bots
	CLASSFLAG_MISSION         = (1 << 2), // set for mission support bots and teleporters
	CLASSFLAG_MINIBOSS        = (1 << 3), // set for minibosses and tanks (red background)
	CLASSFLAG_CRITICAL        = (1 << 4), // set for crit bots (blue border)
	CLASSFLAG_SUPPORT_LIMITED = (1 << 5), // set for "support limited" bots
};

// updates data from tf_objective_resource
void OR_Update()
{
	iAvailableClasses = 0;
	
	int iResource = FindEntityByClassname(-1, "tf_objective_resource");
	if(IsValidEntity(iResource))
	{
		//PrintToServer("------------------------ Bot Data ------------------------");
	
		iCurrentWave = GetEntProp( iResource, Prop_Send, "m_nMannVsMachineWaveCount" );
		iMaxWave = GetEntProp( iResource, Prop_Send, "m_nMannVsMachineMaxWaveCount" );
		iPopFileType = GetEntProp( iResource, Prop_Send, "m_nMvMEventPopfileType" );	
		GetEntPropString( iResource, Prop_Send, "m_iszMvMPopfileName", g_strMissionName, sizeof(g_strMissionName) );
		
		ReplaceString(g_strMissionName, sizeof(g_strMissionName), "scripts/population/", "");
		ReplaceString(g_strMissionName, sizeof(g_strMissionName), ".pop", "");
	
		for(int i = 0; i < 24; i++)
		{
			int iClassCount = 0;
			int iClassFlags = 0;
			//bool bClassActive = false;
			
			char strIcon[64]; 
			
			if(i < 12)
			{
				iClassCount = GetEntProp(iResource, Prop_Send, "m_nMannVsMachineWaveClassCounts", _, i); 
				iClassFlags = GetEntProp(iResource, Prop_Send, "m_nMannVsMachineWaveClassFlags", _, i);
				//bClassActive = view_as<bool>(GetEntProp(iResource, Prop_Send, "m_bMannVsMachineWaveClassActive", _, i));
				
				GetEntPropString(iResource, Prop_Data, "m_iszMannVsMachineWaveClassNames", strIcon, sizeof(strIcon), i);
			}
			else if (i < 24)
			{
				iClassCount = GetEntProp(iResource, Prop_Send, "m_nMannVsMachineWaveClassCounts2", _, i - 12); 
				iClassFlags = GetEntProp(iResource, Prop_Send, "m_nMannVsMachineWaveClassFlags2", _, i - 12);
				//bClassActive = view_as<bool>(GetEntProp(iResource, Prop_Send, "m_bMannVsMachineWaveClassActive2", _, i - 12));
				
				GetEntPropString(iResource, Prop_Data, "m_iszMannVsMachineWaveClassNames2", strIcon, sizeof(strIcon), i - 12);
			}
		
			char strFlags[PLATFORM_MAX_PATH];
			if(iClassFlags & view_as<int>(CLASSFLAG_NORMAL))			Format(strFlags, PLATFORM_MAX_PATH, "NORMAL");
			if(iClassFlags & view_as<int>(CLASSFLAG_SUPPORT))			Format(strFlags, PLATFORM_MAX_PATH, "%s %s", strFlags, "SUPPORT");
			if(iClassFlags & view_as<int>(CLASSFLAG_MISSION))			Format(strFlags, PLATFORM_MAX_PATH, "%s %s", strFlags, "MISSION");
			if(iClassFlags & view_as<int>(CLASSFLAG_MINIBOSS))			Format(strFlags, PLATFORM_MAX_PATH, "%s %s", strFlags, "MINIBOSS");
			if(iClassFlags & view_as<int>(CLASSFLAG_CRITICAL))			Format(strFlags, PLATFORM_MAX_PATH, "%s %s", strFlags, "CRITICAL");
			if(iClassFlags & view_as<int>(CLASSFLAG_SUPPORT_LIMITED))	Format(strFlags, PLATFORM_MAX_PATH, "%s %s", strFlags, "SUPPORT LIMITED");
			
			if(iClassCount > 0 || iClassFlags != 0)
			{
				//PrintToServer("[%i] iClassCount %i bActive %i icon \"%s\" flags \"%i\" \"\%s\"", i, iClassCount, bClassActive, strIcon, iClassFlags, strFlags);
				// search for class names in the icon names
				if(StrContains(strIcon, "scout", false) != -1 && (iClassFlags & view_as<int>(CLASSFLAG_MINIBOSS)) == 0 && (iAvailableClasses & scout_normal) == 0)
				{
					iAvailableClasses |= scout_normal;
				}
				if(StrContains(strIcon, "soldier", false) != -1 && (iClassFlags & view_as<int>(CLASSFLAG_MINIBOSS)) == 0 && (iAvailableClasses & soldier_normal) == 0)
				{
					iAvailableClasses |= soldier_normal;
				}
				if(StrContains(strIcon, "pyro", false) != -1 && (iClassFlags & view_as<int>(CLASSFLAG_MINIBOSS)) == 0 && (iAvailableClasses & pyro_normal) == 0)
				{
					iAvailableClasses |= pyro_normal;
				}
				if(StrContains(strIcon, "demo", false) != -1 && (iClassFlags & view_as<int>(CLASSFLAG_MINIBOSS)) == 0 && (iAvailableClasses & demoman_normal) == 0)
				{
					iAvailableClasses |= demoman_normal;
				}
				if(StrContains(strIcon, "heavy", false) != -1 && (iClassFlags & view_as<int>(CLASSFLAG_MINIBOSS)) == 0 && (iAvailableClasses & heavy_normal) == 0)
				{
					iAvailableClasses |= heavy_normal;
				}
				if(StrContains(strIcon, "engineer", false) != -1 && (iClassFlags & view_as<int>(CLASSFLAG_MINIBOSS)) == 0 && (iAvailableClasses & engineer_normal) == 0)
				{
					iAvailableClasses |= engineer_normal;
				}
				if(StrContains(strIcon, "medic", false) != -1 && (iClassFlags & view_as<int>(CLASSFLAG_MINIBOSS)) == 0 && (iAvailableClasses & medic_normal) == 0)
				{
					iAvailableClasses |= medic_normal;
				}
				if(StrContains(strIcon, "sniper", false) != -1 && (iClassFlags & view_as<int>(CLASSFLAG_MINIBOSS)) == 0 && (iAvailableClasses & sniper_normal) == 0)
				{
					iAvailableClasses |= sniper_normal;
				}
				if(StrContains(strIcon, "spy", false) != -1 && (iClassFlags & view_as<int>(CLASSFLAG_MINIBOSS)) == 0 && (iAvailableClasses & spy_normal) == 0)
				{
					iAvailableClasses |= spy_normal;
				}
				if(StrContains(strIcon, "sentry_buster", false) != -1 && (iAvailableClasses & scout_normal) == 0)
				{
					iAvailableClasses |= sentrybuster;
				}
				// giant variants
				if(StrContains(strIcon, "scout", false) != -1 && iClassFlags & view_as<int>(CLASSFLAG_MINIBOSS) && (iAvailableClasses & scout_giant) == 0)
				{
					iAvailableClasses |= scout_giant;
				}
				if(StrContains(strIcon, "soldier", false) != -1 && iClassFlags & view_as<int>(CLASSFLAG_MINIBOSS) && (iAvailableClasses & soldier_giant) == 0)
				{
					iAvailableClasses |= soldier_giant;
				}
				if(StrContains(strIcon, "pyro", false) != -1 && iClassFlags & view_as<int>(CLASSFLAG_MINIBOSS) && (iAvailableClasses & pyro_giant) == 0)
				{
					iAvailableClasses |= pyro_giant;
				}
				if(StrContains(strIcon, "demo", false) != -1 && iClassFlags & view_as<int>(CLASSFLAG_MINIBOSS) && (iAvailableClasses & demoman_giant) == 0)
				{
					iAvailableClasses |= demoman_giant;
				}
				if(StrContains(strIcon, "heavy", false) != -1 && iClassFlags & view_as<int>(CLASSFLAG_MINIBOSS) && (iAvailableClasses & heavy_giant) == 0)
				{
					iAvailableClasses |= heavy_giant;
				}
				if(StrContains(strIcon, "engineer", false) != -1 && iClassFlags & view_as<int>(CLASSFLAG_MINIBOSS) && (iAvailableClasses & engineer_giant) == 0)
				{
					iAvailableClasses |= engineer_giant;
				}
				if(StrContains(strIcon, "medic", false) != -1 && iClassFlags & view_as<int>(CLASSFLAG_MINIBOSS) && (iAvailableClasses & medic_giant) == 0)
				{
					iAvailableClasses |= medic_giant;
				}
				if(StrContains(strIcon, "sniper", false) != -1 && iClassFlags & view_as<int>(CLASSFLAG_MINIBOSS) && (iAvailableClasses & sniper_giant) == 0)
				{
					iAvailableClasses |= sniper_giant;
				}
				if(StrContains(strIcon, "spy", false) != -1 && iClassFlags & view_as<int>(CLASSFLAG_MINIBOSS) && (iAvailableClasses & spy_giant) == 0)
				{
					iAvailableClasses |= spy_giant;
				}
				
/**				if(iClassFlags & view_as<int>(CLASSFLAG_MINIBOSS) && bClasses[10] == false)
				{
					if( StrContains(strIcon, "sentry_buster", false) == -1 && StrContains(strIcon, "tank", false) == -1 )
					{
						iAvailableClasses += 1024;
						bClasses[10] = true;
					}
				} **/
			}
		}
	}
}

int OR_GetAvailableClasses()
{
	return iAvailableClasses;
}

bool OR_IsHalloweenMission()
{
	if(iPopFileType == 1)
		return true;
	else
		return false;
}

int OR_GetCurrentWave()
{
	return iCurrentWave;
}

int OR_GetMaxWave()
{
	return iMaxWave;
}

bool OR_IsGiantAvaiable()
{
	if( iAvailableClasses & scout_giant || iAvailableClasses & soldier_giant || iAvailableClasses & pyro_giant
	|| iAvailableClasses & demoman_giant || iAvailableClasses & heavy_giant || iAvailableClasses & engineer_giant
	|| iAvailableClasses & medic_giant || iAvailableClasses & sniper_giant || iAvailableClasses & spy_giant )
	{
		return true;
	}
	
	return false;
}

bool OR_IsNormalAvaiable()
{
	if( iAvailableClasses & scout_normal || iAvailableClasses & soldier_normal || iAvailableClasses & pyro_normal
	|| iAvailableClasses & demoman_normal || iAvailableClasses & heavy_normal || iAvailableClasses & engineer_normal
	|| iAvailableClasses & medic_normal || iAvailableClasses & sniper_normal || iAvailableClasses & spy_normal )
	{
		return true;
	}
	
	return false;
}

void OR_GetMissionName(char[] name, int size)
{
	strcopy(name, size, g_strMissionName);
}