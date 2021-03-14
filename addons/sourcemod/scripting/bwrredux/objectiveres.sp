// reads data from tf_objective_resource
// special thanks to Pelipoika

char g_strMissionName[128];
int g_iCurrentWave; // current wave
int g_iMaxWave; // total wave
int g_iPopFileType; // Event popfile?
int g_iAvailableClasses = 0; // which classes are available for the current wave // bit
//bool bClasses[11]; // temporary solution

enum // class bits
{
	none = 0,
	scout_normal = (1 << 0),
	soldier_normal = (1 << 1),
	pyro_normal = (1 << 2),
	demoman_normal = (1 << 3),
	heavy_normal = (1 << 4),
	engineer_normal = (1 << 5),
	medic_normal = (1 << 6),
	sniper_normal = (1 << 7),
	spy_normal = (1 << 8),
	sentrybuster = (1 << 9),
	scout_giant = (1 << 10),
	soldier_giant = (1 << 11),
	pyro_giant = (1 << 12),
	demoman_giant = (1 << 13),
	heavy_giant = (1 << 14),
	engineer_giant = (1 << 15),
	medic_giant = (1 << 16),
	sniper_giant = (1 << 17),
	spy_giant = (1 << 18),
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
	g_iAvailableClasses = 0;
	
	int iResource = FindEntityByClassname(-1, "tf_objective_resource");
	if(IsValidEntity(iResource))
	{
		//PrintToServer("------------------------ Bot Data ------------------------");
	
		g_iCurrentWave = GetEntProp( iResource, Prop_Send, "m_nMannVsMachineWaveCount" );
		g_iMaxWave = GetEntProp( iResource, Prop_Send, "m_nMannVsMachineMaxWaveCount" );
		g_iPopFileType = GetEntProp( iResource, Prop_Send, "m_nMvMEventPopfileType" );	
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
				if(StrContains(strIcon, "scout", false) != -1 && (iClassFlags & view_as<int>(CLASSFLAG_MINIBOSS)) == 0 && (g_iAvailableClasses & scout_normal) == 0)
				{
					g_iAvailableClasses |= scout_normal;
				}
				if(StrContains(strIcon, "soldier", false) != -1 && (iClassFlags & view_as<int>(CLASSFLAG_MINIBOSS)) == 0 && (g_iAvailableClasses & soldier_normal) == 0)
				{
					g_iAvailableClasses |= soldier_normal;
				}
				if(StrContains(strIcon, "pyro", false) != -1 && (iClassFlags & view_as<int>(CLASSFLAG_MINIBOSS)) == 0 && (g_iAvailableClasses & pyro_normal) == 0)
				{
					g_iAvailableClasses |= pyro_normal;
				}
				if(StrContains(strIcon, "demo", false) != -1 && (iClassFlags & view_as<int>(CLASSFLAG_MINIBOSS)) == 0 && (g_iAvailableClasses & demoman_normal) == 0)
				{
					g_iAvailableClasses |= demoman_normal;
				}
				if(StrContains(strIcon, "heavy", false) != -1 && (iClassFlags & view_as<int>(CLASSFLAG_MINIBOSS)) == 0 && (g_iAvailableClasses & heavy_normal) == 0)
				{
					g_iAvailableClasses |= heavy_normal;
				}
				if(StrContains(strIcon, "engineer", false) != -1 && (iClassFlags & view_as<int>(CLASSFLAG_MINIBOSS)) == 0 && (g_iAvailableClasses & engineer_normal) == 0)
				{
					g_iAvailableClasses |= engineer_normal;
				}
				if(StrContains(strIcon, "medic", false) != -1 && (iClassFlags & view_as<int>(CLASSFLAG_MINIBOSS)) == 0 && (g_iAvailableClasses & medic_normal) == 0)
				{
					g_iAvailableClasses |= medic_normal;
				}
				if(StrContains(strIcon, "sniper", false) != -1 && (iClassFlags & view_as<int>(CLASSFLAG_MINIBOSS)) == 0 && (g_iAvailableClasses & sniper_normal) == 0)
				{
					g_iAvailableClasses |= sniper_normal;
				}
				if(StrContains(strIcon, "spy", false) != -1 && (iClassFlags & view_as<int>(CLASSFLAG_MINIBOSS)) == 0 && (g_iAvailableClasses & spy_normal) == 0)
				{
					g_iAvailableClasses |= spy_normal;
				}
				if(StrContains(strIcon, "sentry_buster", false) != -1 && (g_iAvailableClasses & scout_normal) == 0)
				{
					g_iAvailableClasses |= sentrybuster;
				}
				// giant variants
				if(StrContains(strIcon, "scout", false) != -1 && iClassFlags & view_as<int>(CLASSFLAG_MINIBOSS) && (g_iAvailableClasses & scout_giant) == 0)
				{
					g_iAvailableClasses |= scout_giant;
				}
				if(StrContains(strIcon, "soldier", false) != -1 && iClassFlags & view_as<int>(CLASSFLAG_MINIBOSS) && (g_iAvailableClasses & soldier_giant) == 0)
				{
					g_iAvailableClasses |= soldier_giant;
				}
				if(StrContains(strIcon, "pyro", false) != -1 && iClassFlags & view_as<int>(CLASSFLAG_MINIBOSS) && (g_iAvailableClasses & pyro_giant) == 0)
				{
					g_iAvailableClasses |= pyro_giant;
				}
				if(StrContains(strIcon, "demo", false) != -1 && iClassFlags & view_as<int>(CLASSFLAG_MINIBOSS) && (g_iAvailableClasses & demoman_giant) == 0)
				{
					g_iAvailableClasses |= demoman_giant;
				}
				if(StrContains(strIcon, "heavy", false) != -1 && iClassFlags & view_as<int>(CLASSFLAG_MINIBOSS) && (g_iAvailableClasses & heavy_giant) == 0)
				{
					g_iAvailableClasses |= heavy_giant;
				}
				if(StrContains(strIcon, "engineer", false) != -1 && iClassFlags & view_as<int>(CLASSFLAG_MINIBOSS) && (g_iAvailableClasses & engineer_giant) == 0)
				{
					g_iAvailableClasses |= engineer_giant;
				}
				if(StrContains(strIcon, "medic", false) != -1 && iClassFlags & view_as<int>(CLASSFLAG_MINIBOSS) && (g_iAvailableClasses & medic_giant) == 0)
				{
					g_iAvailableClasses |= medic_giant;
				}
				if(StrContains(strIcon, "sniper", false) != -1 && iClassFlags & view_as<int>(CLASSFLAG_MINIBOSS) && (g_iAvailableClasses & sniper_giant) == 0)
				{
					g_iAvailableClasses |= sniper_giant;
				}
				if(StrContains(strIcon, "spy", false) != -1 && iClassFlags & view_as<int>(CLASSFLAG_MINIBOSS) && (g_iAvailableClasses & spy_giant) == 0)
				{
					g_iAvailableClasses |= spy_giant;
				}
				
/**				if(iClassFlags & view_as<int>(CLASSFLAG_MINIBOSS) && bClasses[10] == false)
				{
					if( StrContains(strIcon, "sentry_buster", false) == -1 && StrContains(strIcon, "tank", false) == -1 )
					{
						g_iAvailableClasses += 1024;
						bClasses[10] = true;
					}
				} **/
			}
		}
	}
}

int OR_GetAvailableClasses()
{
	return g_iAvailableClasses;
}

bool OR_IsHalloweenMission()
{
	return g_iPopFileType == 1;
}

int OR_GetCurrentWave()
{
	return g_iCurrentWave;
}

int OR_GetMaxWave()
{
	return g_iMaxWave;
}

bool OR_IsGiantAvaiable()
{
	if( g_iAvailableClasses & scout_giant || g_iAvailableClasses & soldier_giant || g_iAvailableClasses & pyro_giant
	|| g_iAvailableClasses & demoman_giant || g_iAvailableClasses & heavy_giant || g_iAvailableClasses & engineer_giant
	|| g_iAvailableClasses & medic_giant || g_iAvailableClasses & sniper_giant || g_iAvailableClasses & spy_giant )
	{
		return true;
	}
	
	return false;
}

bool OR_IsNormalAvaiable()
{
	if( g_iAvailableClasses & scout_normal || g_iAvailableClasses & soldier_normal || g_iAvailableClasses & pyro_normal
	|| g_iAvailableClasses & demoman_normal || g_iAvailableClasses & heavy_normal || g_iAvailableClasses & engineer_normal
	|| g_iAvailableClasses & medic_normal || g_iAvailableClasses & sniper_normal || g_iAvailableClasses & spy_normal )
	{
		return true;
	}
	
	return false;
}

void OR_GetMissionName(char[] name, int size)
{
	strcopy(name, size, g_strMissionName);
}