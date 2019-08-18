// reads data from tf_objective_resource
// special thanks to Pelipoika

int iCurrentWave; // current wave
int iMaxWave; // total wave
int iPopFileType; // Event popfile?
int iAvailableClasses; // which classes are available for the current wave
bool bClasses[11]; // temporary solution
// 0 - none (how?)
// 1 - scout
// 2 - soldier
// 4 - pyro
// 8 - demoman
// 16 - heavy
// 32 - engineer
// 64 - medic
// 128 - sniper
// 256 - spy
// 512 - sentrybuster

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
	
	for(int i = 0; i < 10; i++)
	{
		bClasses[i] = false;
	}
	
	int iResource = FindEntityByClassname(-1, "tf_objective_resource");
	if(IsValidEntity(iResource))
	{
		//PrintToServer("------------------------ Bot Data ------------------------");
	
		iCurrentWave = GetEntProp( iResource, Prop_Send, "m_nMannVsMachineWaveCount" );
		iMaxWave = GetEntProp( iResource, Prop_Send, "m_nMannVsMachineMaxWaveCount" );
		iPopFileType = GetEntProp( iResource, Prop_Send, "m_nMvMEventPopfileType" );	
	
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
				if(StrContains(strIcon, "scout", false) != -1 && bClasses[0] == false)
				{
					iAvailableClasses += 1;
					bClasses[0] = true;
				}
				if(StrContains(strIcon, "soldier", false) != -1 && bClasses[1] == false)
				{
					iAvailableClasses += 2;
					bClasses[1] = true;
				}
				if(StrContains(strIcon, "pyro", false) != -1 && bClasses[2] == false)
				{
					iAvailableClasses += 4;
					bClasses[2] = true;
				}
				if(StrContains(strIcon, "demo", false) != -1 && bClasses[3] == false)
				{
					iAvailableClasses += 8;
					bClasses[3] = true;
				}
				if(StrContains(strIcon, "heavy", false) != -1 && bClasses[4] == false)
				{
					iAvailableClasses += 16;
					bClasses[4] = true;
				}
				if(StrContains(strIcon, "engineer", false) != -1 && bClasses[5] == false)
				{
					iAvailableClasses += 32;
					bClasses[5] = true;
				}
				if(StrContains(strIcon, "medic", false) != -1 && bClasses[6] == false)
				{
					iAvailableClasses += 64;
					bClasses[6] = true;
				}
				if(StrContains(strIcon, "sniper", false) != -1 && bClasses[7] == false)
				{
					iAvailableClasses += 128;
					bClasses[7] = true;
				}
				if(StrContains(strIcon, "spy", false) != -1 && bClasses[8] == false)
				{
					iAvailableClasses += 256;
					bClasses[8] = true;
				}
				if(StrContains(strIcon, "sentry_buster", false) != -1 && bClasses[9] == false)
				{
					iAvailableClasses += 512;
					bClasses[9] = true;
				}
				if(StrContains(strIcon, "_giant", false) != -1 && bClasses[10] == false)
				{
					iAvailableClasses += 1024;
					bClasses[10] = true;
				}
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
	{
		return true;
	}
	else
	{
		return false;
	}
}

int OR_GetCurrentWave()
{
	return iCurrentWave;
}

int OR_GetMaxWave()
{
	return iMaxWave;
}