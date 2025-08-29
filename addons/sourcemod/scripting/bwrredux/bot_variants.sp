// pootis robots here

// defines
#define MAX_TEMPLATE_TYPE 2
#define MAX_ROBOTS_TEMPLATE 40
#define MAX_ROBOTS_WEAPONS 6
#define CONST_ROBOT_CLASSES 9
#define MAXLEN_CONFIG_STRING 128

// Globals
char g_strClassKey[CONST_ROBOT_CLASSES][16] = {"scout", "sniper", "soldier", "demoman", "medic", "heavy", "pyro", "spy", "engineer"};
char g_strWeaponsKey[MAX_ROBOTS_WEAPONS][32] = {"primaryweapon", "secondaryweapon", "meleeweapon", "pda1weapon", "pda2weapon", "pda3weapon"};
char g_strValidAttribs[BOTATTRIB_MAX][32] = {"alwayscrits", "fullcharge", "infinitecloak", "autodisguise", "alwaysminicrits", "teleporttohint", "nobomb", "noteleexit", "holdfirefullreload", "alwaysfire", "igniteonhit", "stunonhit", "bulletimmune", "blastimmune", "fireimmune", "bonknerf", "destroybuildings"};
int g_AttribValue[BOTATTRIB_MAX] = {(1 << 0),(1 << 1),(1 << 2),(1 << 3),(1 << 4),(1 << 5),(1 << 6),(1 << 7),(1 << 8),(1 << 9),(1 << 10),(1 << 11),(1 << 12),(1 << 13),(1 << 14),(1 << 15),(1 << 16)};

// Big list of arrays
/**
* Prefixes
* g_BN - Bot Stock Normal
* g_BG - Bot Stock Giant
**/
// == STOCK NORMAL ROBOTS ==
char g_BNTemplateName[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAXLEN_CONFIG_STRING];
char g_BNRobotAttribs[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAXLEN_CONFIG_STRING];
char g_BNDescription[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAXLEN_CONFIG_STRING];
int g_BNWeaponIndex[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAX_ROBOTS_WEAPONS];
int g_BNBitsAttribs[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES];
int g_BNHealth[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES];
int g_BNType[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES];
int g_BNCritChance[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES];
int g_BNCurrency[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES];
float g_BNScale[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES];
float g_BNCooldown[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES];
ArrayList g_BNWeaponClass[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES];
ArrayList g_BNCharAttrib[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES];
ArrayList g_BNCharAttribValue[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES];
ArrayList g_BNWeapAttrib[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAX_ROBOTS_WEAPONS];
ArrayList g_BNWeapAttribValue[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAX_ROBOTS_WEAPONS];
int g_BNWeapChance[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAX_ROBOTS_WEAPONS]; // Change for weapon to spawn
// == STOCK GIANT ROBOTS ==
char g_BGTemplateName[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAXLEN_CONFIG_STRING];
char g_BGRobotAttribs[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAXLEN_CONFIG_STRING];
char g_BGDescription[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAXLEN_CONFIG_STRING];
int g_BGWeaponIndex[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAX_ROBOTS_WEAPONS];
int g_BGBitsAttribs[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES];
int g_BGHealth[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES];
//int g_BGType[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES];
int g_BGCritChance[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES];
int g_BGCurrency[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES];
float g_BGScale[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES];
float g_BGCooldown[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES];
ArrayList g_BGWeaponClass[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES];
ArrayList g_BGCharAttrib[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES];
ArrayList g_BGCharAttribValue[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES];
ArrayList g_BGWeapAttrib[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAX_ROBOTS_WEAPONS];
ArrayList g_BGWeapAttribValue[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAX_ROBOTS_WEAPONS];
int g_BGWeapChance[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAX_ROBOTS_WEAPONS]; // Change for weapon to spawn

// enum structs for config files
enum struct eRobotsGlobal
{
	int numtemplates[CONST_ROBOT_CLASSES];
}
eRobotsGlobal g_nBotTemplate[MAX_TEMPLATE_TYPE];

enum
{
	TemplateType_Normal = 0,
	TemplateType_Giant = 1,
};

// remove items from the player
void StripItems(int client, bool RemoveWeapons = true, bool isOwnLoadout = false)
{	
	if(!IsClientInGame(client) || IsFakeClient(client) || !IsPlayerAlive(client))
		return;
		
	int iEntity;
	int iOwner;
	
	if(RemoveWeapons)
	{
		iEntity = -1;
		while((iEntity = FindEntityByClassname(iEntity, "tf_wearable_demoshield")) > MaxClients)
		{
			iOwner = GetEntPropEnt( iEntity, Prop_Send, "m_hOwnerEntity" );
			if( iOwner == client )
			{
				TF2_RemoveWearable( client, iEntity );
				RemoveEntity(iEntity);
			}
		}
		
		iEntity = -1;
		while((iEntity = FindEntityByClassname(iEntity, "tf_wearable_razorback")) > MaxClients)
		{
			iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
			if(iOwner == client)
			{
				TF2_RemoveWearable(client, iEntity);
				RemoveEntity(iEntity);
			}
		}
		
		RemoveAllWeapons(client);
	}

	bool shouldremovewearables = true;

	if (g_iCosmeticRestrictionMode == CM_Allow_All) // Always allow cosmetics
	{
		shouldremovewearables = false
	}
	else if(g_iCosmeticRestrictionMode == CM_Allow_For_Own_Robots && isOwnLoadout) // Always allow for 'Own Loadout'
	{
		shouldremovewearables = false;
	}
	else if(OR_IsHalloweenMission() && p_iBotType[client] != Bot_Buster)
	{
		shouldremovewearables = false;
	}
	
	if(shouldremovewearables)
	{
		iEntity = -1;
		while((iEntity = FindEntityByClassname(iEntity, "tf_wearable")) > MaxClients)
		{
			iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
			if(iOwner == client)
			{
				int index = GetEntProp(iEntity, Prop_Send, "m_iItemDefinitionIndex");
				if(!IsWearableAWeapon(index)) {
					TF2_RemoveWearable(client, iEntity);
					RemoveEntity(iEntity);
				}
			}
		}
	}
	
	iEntity = -1;
	while((iEntity = FindEntityByClassname(iEntity, "tf_powerup_bottle")) > MaxClients)
	{
		iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
		if(iOwner == client) {
			RemoveEntity(iEntity);
		}
	}
	iEntity = -1;
	while((iEntity = FindEntityByClassname(iEntity, "tf_usableitem")) > MaxClients)
	{
		iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
		if(iOwner == client) {
			RemoveEntity(iEntity);
		}
	}
}

// remove items from the player
void StripWeapons(int client)
{	
	if(!IsClientInGame(client) || IsFakeClient(client) || !IsPlayerAlive(client))
		return;
		
	int iEntity;
	int iOwner;
	
	iEntity = -1;
	while((iEntity = FindEntityByClassname(iEntity, "tf_wearable_demoshield")) > MaxClients)
	{
		iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
		if(iOwner == client)
		{
			TF2_RemoveWearable( client, iEntity );
			RemoveEntity(iEntity);
		}
	}
	
	iEntity = -1;
	while((iEntity = FindEntityByClassname(iEntity, "tf_wearable_razorback")) > MaxClients)
	{
		iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
		if(iOwner == client)
		{
			TF2_RemoveWearable(client, iEntity);
			RemoveEntity(iEntity);
		}
	}
	
	RemoveAllWeapons(client);
}

bool IsWeaponWearable(char[] classname)
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

void RemoveAllWeapons(int client)
{
	int weapon;
	for(int i = 0; i <= TFWeaponSlot_Item2; i++)
	{
		weapon = TF2Util_GetPlayerLoadoutEntity(client, i, true);
		if(weapon != -1) {
			if(TF2Util_IsEntityWearable(weapon)) {
				TF2_RemoveWearable(client, weapon);
			}
			else {
				TF2_RemoveWeaponSlot(client, i);
			}

			RemoveEntity(weapon);
		}
	}
}

// Some weapons uses the tf_wearable class, which is removed.
// This is used to filter some items so they don't get removed (for example: Gunboats)
bool IsWearableAWeapon(int index)
{
	switch(index)
	{
		case 133, 444, 405, 608, 231, 642:
		{
			return true;
		}
		default: return false;
	}
}

// Returns the class base health
int GetClassBaseHealth(TFClassType Class)
{
	switch(Class)
	{
		case TFClass_Scout: return 125;
		case TFClass_Sniper: return 125;
		case TFClass_Soldier: return 200;
		case TFClass_DemoMan: return 175;
		case TFClass_Heavy: return 300;
		case TFClass_Pyro: return 175;
		case TFClass_Engineer: return 125;
		case TFClass_Medic: return 150;
		case TFClass_Spy: return 125;
	}
	
	return 300;
}

// Health for own loadout giants
int GetOwnGiantHealth(TFClassType Class)
{
	switch( Class )
	{
		case TFClass_Scout: return 1200;
		case TFClass_Sniper: return 1200;
		case TFClass_Soldier: return 3800;
		case TFClass_DemoMan: return 3300;
		case TFClass_Heavy: return 5000;
		case TFClass_Pyro: return 3300;
		case TFClass_Engineer: return 1200;
		case TFClass_Medic: return 4500;
		case TFClass_Spy: return 1200;
	}
	
	return 300;
}

// use TF2Items for giving weapons
int SpawnWeapon(int client,char[] name,int index,int level,int qual,bool bWearable = false)
{
	if( IsFakeClient(client) )
		return -1;

	Handle hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION|PRESERVE_ATTRIBUTES);
	TF2Items_SetClassname(hWeapon, name);
	TF2Items_SetItemIndex(hWeapon, index);
	TF2Items_SetLevel(hWeapon, level);
	TF2Items_SetQuality(hWeapon, qual);
	
	if (hWeapon==null)
		return -1;
		
	int entity = TF2Items_GiveNamedItem(client, hWeapon);
	CloseHandle(hWeapon);
	if (IsValidEdict(entity))
	{
		if (bWearable)
		{
			TF2Util_EquipPlayerWearable(client, entity);
		}
		else
			EquipPlayerWeapon(client, entity);

#if defined VISIBLE_WEAPONS
		SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", 1);
#endif
	}
	
	return entity;
}

// Modified version of SpawnWeapon exclusive for gatebot hats.
void SpawnGatebotHat(int client,char[] name,int index, bool light = true)
{
	if(IsFakeClient(client)) {
		return;
	}

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
#if defined VISIBLE_WEAPONS
		SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", 1);
#endif
	}
}

bool IsGateBotHat(int index)
{
	switch(index)
	{
		case 1057, 1063, 1058, 1061, 1060, 1065, 1059, 1062, 1064: return true;
		default: return false;
	}
}

// gives the gatebot hat to the client
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

void RemoveGateBotHat(int client)
{
	int entity = -1;
	while((entity = FindEntityByClassname(entity, "tf_wearable")) > MaxClients)
	{
		int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		if(owner == client)
		{
			int index = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
			if(IsGateBotHat(index)) {
				TF2_RemoveWearable(client, entity);
				RemoveEntity(entity);
			}
		}
	}	
}

void EnableBombPickup(int client)
{
	TF2Attrib_RemoveByName(client, "cannot pick up intelligence");
}

// Give weapons to the player
// type: 0 - normal, 1 - giant
void RT_GiveInventory(int client, int type = 0, int templateindex)
{
	if( IsFakeClient(client) )
		return;

	TFClassType TFClass = TF2_GetPlayerClass(client);
	int iClass = view_as<int>(TFClass) - 1; // - 1 because array starts at 0
	int iWeapon;
	char buffer[255];
	char sValue[128];
	
	TF2Attrib_RemoveAll(client);
	
	if(type == 0) // Normal
	{
		if(templateindex <= g_nBotTemplate[TemplateType_Normal].numtemplates[iClass]) // This is a stock robot
		{
			// Set Player Attributes
			if(g_BNCharAttrib[templateindex][iClass].Length > 0)
			{
				for(int i = 0;i < g_BNCharAttrib[templateindex][iClass].Length;i++)
				{
					g_BNCharAttrib[templateindex][iClass].GetString(i, buffer, sizeof(buffer));
					g_BNCharAttribValue[templateindex][iClass].GetString(i, sValue, sizeof(sValue));
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
			
			TF2Attrib_ClearCache(client);

			// Spawn Weapons
			for(int i = 0;i < MAX_ROBOTS_WEAPONS;i++)
			{
				g_BNWeaponClass[templateindex][iClass].GetString(i, buffer, sizeof(buffer));
				if(strlen(buffer) > 3) // check if a weapon exists
				{
					if(Math_RandomChance(g_BNWeapChance[templateindex][iClass][i])) // Check weapon spawn chance
					{
						iWeapon = SpawnWeapon(client, buffer, g_BNWeaponIndex[templateindex][iClass][i], 1, 6, IsWeaponWearable(buffer));
						if(g_BNWeapAttrib[templateindex][iClass][i].Length > 0) // Does this weapon have custom attributes?
						{
							for(int y = 0;y < g_BNWeapAttrib[templateindex][iClass][i].Length;y++)
							{
								g_BNWeapAttrib[templateindex][iClass][i].GetString(y, buffer, sizeof(buffer));
								g_BNWeapAttribValue[templateindex][iClass][i].GetString(y, sValue, sizeof(sValue));
#if defined __tf_custom_attributes_included
								if (TF2Attrib_IsValidAttributeName(buffer))
								{
									TF2Attrib_SetFromStringValue(iWeapon, buffer, sValue);
								}
								else
								{
									TF2CustAttr_SetString(iWeapon, buffer, sValue);
								}
#else
								TF2Attrib_SetFromStringValue(iWeapon, buffer, sValue);
#endif
							}
						}
					}
				}
			}
		}
	}
	else // Giants
	{
		if(templateindex <= g_nBotTemplate[TemplateType_Giant].numtemplates[iClass]) // This is a stock robot
		{	
			// Set Player Attributes
			if(g_BGCharAttrib[templateindex][iClass].Length > 0)
			{
				for(int i = 0;i < g_BGCharAttrib[templateindex][iClass].Length;i++)
				{
					g_BGCharAttrib[templateindex][iClass].GetString(i, buffer, sizeof(buffer));
					g_BGCharAttribValue[templateindex][iClass].GetString(i, sValue, sizeof(sValue));
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

			// Spawn Weapons
			for(int i = 0;i < MAX_ROBOTS_WEAPONS;i++)
			{
				g_BGWeaponClass[templateindex][iClass].GetString(i, buffer, sizeof(buffer));
				if(strlen(buffer) > 3) // check if a weapon exists
				{
					if(Math_RandomChance(g_BGWeapChance[templateindex][iClass][i]))
					{
						iWeapon = SpawnWeapon(client, buffer, g_BGWeaponIndex[templateindex][iClass][i], 1, 6, IsWeaponWearable(buffer));
						if(g_BGWeapAttrib[templateindex][iClass][i].Length > 0) // Does this weapon have custom attributes?
						{
							for(int y = 0;y < g_BGWeapAttrib[templateindex][iClass][i].Length;y++)
							{
								g_BGWeapAttrib[templateindex][iClass][i].GetString(y, buffer, sizeof(buffer));
								g_BGWeapAttribValue[templateindex][iClass][i].GetString(y, sValue, sizeof(sValue));
#if defined __tf_custom_attributes_included
								if (TF2Attrib_IsValidAttributeName(buffer))
								{
									TF2Attrib_SetFromStringValue(iWeapon, buffer, sValue);
								}
								else
								{
									TF2CustAttr_SetString(iWeapon, buffer, sValue);
								}
#else
								TF2Attrib_SetFromStringValue(iWeapon, buffer, sValue);
#endif
							}
						}
					}
				}
			}
		}
	}
	
	switch(TFClass) // Generic Weapons
	{
		case TFClass_Engineer:
		{
			SpawnWeapon(client, "tf_weapon_pda_engineer_destroy", 26, 1, 0, false); // Destruction PDA
			SpawnWeapon(client, "tf_weapon_builder", 28, 1, 0, false); // Toolbox
		}
		case TFClass_Spy:
		{
			SpawnWeapon(client, "tf_weapon_pda_spy", 27, 1, 0, false); // Disguise Kit
		}
	}
}

// Sets the robot health
void RT_SetHealth(int client, TFClassType TFClass, int templateindex, int type = 0)
{
	int iClass = view_as<int>(TFClass) - 1;
	int iHealth;
	float flHealth;
	
	if( templateindex < 0 )
	{
		switch( type )
		{
			case 0: // Normal
			{
				if( TFClass == TFClass_Engineer ) // hack
				{
					SetEntProp(client, Prop_Send, "m_iHealth", 500);
					SetEntProp(client, Prop_Data, "m_iHealth", 500);						
				}
				else
				{
					SetEntProp(client, Prop_Send, "m_iHealth", GetClassBaseHealth(TFClass));
					SetEntProp(client, Prop_Data, "m_iHealth", GetClassBaseHealth(TFClass));						
				}
			}
			case 1: // Giant
			{
				SetEntProp(client, Prop_Send, "m_iHealth", GetOwnGiantHealth(TFClass));
				SetEntProp(client, Prop_Data, "m_iHealth", GetOwnGiantHealth(TFClass));					
			}
		}
		
		return; 
	}
	
	switch( type )
	{
		case 0: // Normal
		{
			if(g_BNHealth[templateindex][iClass] > 0)
			{
				iHealth = (g_BNHealth[templateindex][iClass] - GetClassBaseHealth(TFClass));
				flHealth = float(iHealth);
				TF2Attrib_SetByName(client, "hidden maxhealth non buffed", flHealth);
				SetEntProp(client, Prop_Send, "m_iHealth", g_BNHealth[templateindex][iClass]);
				SetEntProp(client, Prop_Data, "m_iHealth", g_BNHealth[templateindex][iClass]);
#if defined DEBUG_PLAYER
				PrintToConsole(client, "Setting Robot Health: %i (%i)", g_BNHealth[templateindex][iClass], iHealth);
#endif
			}
			else
			{
				SetEntProp(client, Prop_Send, "m_iHealth", GetClassBaseHealth(TFClass));
				SetEntProp(client, Prop_Data, "m_iHealth", GetClassBaseHealth(TFClass));					
			}
		}
		case 1: // Giant
		{
			if(g_BGHealth[templateindex][iClass] > 0)
			{
				iHealth = (g_BGHealth[templateindex][iClass] - GetClassBaseHealth(TFClass));
				flHealth = float(iHealth);
				TF2Attrib_SetByName(client, "hidden maxhealth non buffed", flHealth);
				SetEntProp(client, Prop_Send, "m_iHealth", g_BGHealth[templateindex][iClass]);
				SetEntProp(client, Prop_Data, "m_iHealth", g_BGHealth[templateindex][iClass]);
#if defined DEBUG_PLAYER
				PrintToConsole(client, "Setting Robot Health: %i (%i)", g_BGHealth[templateindex][iClass], iHealth);
#endif
			}
			else
			{
				SetEntProp(client, Prop_Send, "m_iHealth", GetClassBaseHealth(TFClass));
				SetEntProp(client, Prop_Data, "m_iHealth", GetClassBaseHealth(TFClass));					
			}
		}
	}	
}

int RT_GetFullCritsChance(TFClassType TFClass, int templateindex, int type = 0)
{
	if(templateindex < 0)
		return 0;

	int iClass = view_as<int>(TFClass) - 1;
	switch(type)
	{
		case 0: // Normal
			return g_BNCritChance[templateindex][iClass];
		case 1: // Giant
			return g_BGCritChance[templateindex][iClass];
		default:
			return 0;
	}
}

int RT_GetCurrency(TFClassType TFClass, int templateindex, int type = 0)
{
	if(templateindex < 0)
		return 0;

	int iClass = view_as<int>(TFClass) - 1;
	switch(type)
	{
		case 0: // Normal
			return g_BNCurrency[templateindex][iClass];
		case 1: // Giant
			return g_BGCurrency[templateindex][iClass];
		default:
			return 0;
	}
}

// Returns the robot name
void RT_GetTemplateName(char[] tpltname, int size, TFClassType TFClass, int templateindex, int type = 0)
{
	char buffer[255];
	int iClass = view_as<int>(TFClass) - 1;
	
	if(templateindex < 0)
	{
		switch( TFClass )
		{
			case TFClass_Scout:
			{
				strcopy(buffer, sizeof(buffer), "Your Own Scout");
			}
			case TFClass_Soldier:
			{
				strcopy(buffer, sizeof(buffer), "Your Own Soldier");
			}
			case TFClass_Pyro:
			{
				strcopy(buffer, sizeof(buffer), "Your Own Pyro");
			}
			case TFClass_DemoMan:
			{
				strcopy(buffer, sizeof(buffer), "Your Own Demoman");
			}
			case TFClass_Heavy:
			{
				strcopy(buffer, sizeof(buffer), "Your Own Heavy");
			}
			case TFClass_Engineer:
			{
				strcopy(buffer, sizeof(buffer), "Your Own Engineer");
			}
			case TFClass_Medic:
			{
				strcopy(buffer, sizeof(buffer), "Your Own Medic");
			}
			case TFClass_Sniper:
			{
				strcopy(buffer, sizeof(buffer), "Your Own Sniper");
			}
			case TFClass_Spy:
			{
				strcopy(buffer, sizeof(buffer), "Your Own Spy");
			}
			default:
			{
				strcopy(buffer, sizeof(buffer), "Your Own Loadout");
			}
		}
		strcopy(tpltname, size, buffer);
		return;
	}
	
	switch( type )
	{
		case 0: // Normal
		{
			if(templateindex <= g_nBotTemplate[TemplateType_Normal].numtemplates[iClass]) // stock
			{
				strcopy(buffer, 255, g_BNTemplateName[templateindex][iClass]);
			}
		}
		case 1: // Giant
		{
			if(templateindex <= g_nBotTemplate[TemplateType_Giant].numtemplates[iClass]) // stock
			{
				strcopy(buffer, 255, g_BGTemplateName[templateindex][iClass]);
			}	
		}
		default:
		{
			LogError("RT_GetTemplateName received invalid type!");
		}
	}
	
	strcopy(tpltname, size, buffer);
	return;
}

// Returns the robot description
void RT_GetDescription(char[] desc, int size, TFClassType TFClass, int templateindex, int type = 0)
{
	char buffer[255];
	int iClass = view_as<int>(TFClass) - 1;
	
	if(templateindex < 0) { return; }
	
	switch( type )
	{
		case 0: // Normal
		{
			if(templateindex <= g_nBotTemplate[TemplateType_Normal].numtemplates[iClass]) // stock
			{
				strcopy(buffer, 255, g_BNDescription[templateindex][iClass]);
			}
		}
		case 1: // Giant
		{
			if(templateindex <= g_nBotTemplate[TemplateType_Giant].numtemplates[iClass]) // stock
			{
				strcopy(buffer, 255, g_BGDescription[templateindex][iClass]);
			}	
		}
	}
	
	strcopy(desc, size, buffer);
}

// Returns the robot attributes
int RT_GetAttributesBits(TFClassType TFClass, int templateindex, int type = 0)
{
	int iBits = 0;
	int iClass = view_as<int>(TFClass) - 1;
	
	switch( type )
	{
		case 0: // Normal
		{
			if(templateindex <= g_nBotTemplate[TemplateType_Normal].numtemplates[iClass]) // stock
			{
				iBits = g_BNBitsAttribs[templateindex][iClass];
			}
		}
		case 1: // Giant
		{
			if(templateindex <= g_nBotTemplate[TemplateType_Giant].numtemplates[iClass]) // stock
			{
				iBits = g_BGBitsAttribs[templateindex][iClass];
			}			
		}
	}
	
	return iBits;
}

// Returns the robot type
int RT_GetType(TFClassType TFClass, int templateindex, int type = 0)
{
	int iRobotType = 0;
	int iClass = view_as<int>(TFClass) - 1;
	
	switch( type )
	{
		case 0: // Normal
		{
			if(templateindex <= g_nBotTemplate[TemplateType_Normal].numtemplates[iClass]) // stock
			{
				iRobotType = g_BNType[templateindex][iClass];
			}
		}
		case 1: // Giant
		{
			if(templateindex <= g_nBotTemplate[TemplateType_Giant].numtemplates[iClass]) // stock
			{
				iRobotType = Bot_Giant; // g_BGType[templateindex][iClass];
			}			
		}
	}
	
	return iRobotType;
}

// returns the robot scale
float RT_GetScale(TFClassType TFClass, int templateindex, int type = 0)
{
	if( templateindex < 0 ) { return 1.0; }
	
	int iClass = view_as<int>(TFClass) - 1;
	
	switch( type )
	{
		case 0: // Normal
		{
			if(templateindex <= g_nBotTemplate[TemplateType_Normal].numtemplates[iClass]) // stock
			{
				return g_BNScale[templateindex][iClass];
			}
		}
		case 1: // Giant
		{
			if(templateindex <= g_nBotTemplate[TemplateType_Giant].numtemplates[iClass]) // stock
			{
				return g_BGScale[templateindex][iClass];
			}			
		}
	}
	
	return 1.0;
}

// returns the robot cooldown for the sm_robotmenu command
float RT_GetCooldown(TFClassType TFClass, int templateindex, int type = 0)
{
	if( templateindex < 0 ) { return 30.0; } // fixed 30 seconds cooldown for own loadouts
	
	int iClass = view_as<int>(TFClass) - 1;
	
	switch( type )
	{
		case 0: // Normal
		{
			if(templateindex <= g_nBotTemplate[TemplateType_Normal].numtemplates[iClass]) // stock
			{
				return g_BNCooldown[templateindex][iClass];
			}
		}
		case 1: // Giant
		{
			if(templateindex <= g_nBotTemplate[TemplateType_Giant].numtemplates[iClass]) // stock
			{
				return g_BGCooldown[templateindex][iClass];
			}			
		}
	}
	
	return 1.0;
}

// add attributes to own variants
void SetOwnAttributes(int client , bool bGiant)
{
	if(IsFakeClient(client))
		return;
		
	TF2Attrib_RemoveAll(client); // bug fix
	RequestFrame(FrameShouldBlockBombPickUp, GetClientUserId(client));

	TFClassType TFClass = TF2_GetPlayerClass(client);
	int iWeapon;
	
	if(bGiant)
	{
		switch(TFClass)
		{
			case TFClass_Scout:
			{
				TF2Attrib_SetByName(client, "hidden maxhealth non buffed", 1475.0);
				TF2Attrib_SetByName(client, "damage force reduction", 0.7);
				TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.7);
				TF2Attrib_SetByName(client, "override footstep sound set", 5.0);
				return;
			}
			case TFClass_Soldier:
			{
				TF2Attrib_SetByName(client, "hidden maxhealth non buffed", 3600.0);
				TF2Attrib_SetByName(client, "move speed bonus", 0.5);
				TF2Attrib_SetByName(client, "damage force reduction", 0.4);
				TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.4);
				TF2Attrib_SetByName(client, "override footstep sound set", 3.0);
				return;
			}
			case TFClass_Pyro:
			{
				TF2Attrib_SetByName(client, "hidden maxhealth non buffed", 2825.0);
				TF2Attrib_SetByName(client, "move speed bonus", 0.5);
				TF2Attrib_SetByName(client, "damage force reduction", 0.6);
				TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.6);
				TF2Attrib_SetByName(client, "override footstep sound set", 6.0);
				return;
			}
			case TFClass_DemoMan:
			{
				TF2Attrib_SetByName(client, "hidden maxhealth non buffed", 3125.0);
				TF2Attrib_SetByName(client, "move speed bonus", 0.5);
				TF2Attrib_SetByName(client, "damage force reduction", 0.5);
				TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.5);
				TF2Attrib_SetByName(client, "override footstep sound set", 4.0);
				return;
			}
			case TFClass_Heavy:
			{
				TF2Attrib_SetByName(client, "hidden maxhealth non buffed", 4700.0);
				TF2Attrib_SetByName(client, "move speed bonus", 0.5);
				TF2Attrib_SetByName(client, "damage force reduction", 0.3);
				TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.3);
				TF2Attrib_SetByName(client, "override footstep sound set", 2.0);
				return;
			}
			case TFClass_Engineer:
			{
				TF2Attrib_SetByName(client, "hidden maxhealth non buffed", 1775.0);
				TF2Attrib_SetByName(client, "move speed bonus", 0.5);
				TF2Attrib_SetByName(client, "damage force reduction", 0.4);
				TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.4);
				TF2Attrib_SetByName(client, "override footstep sound set", 4.0);
				TF2Attrib_SetByName(client, "cannot pick up buildings", 1.0);
				return;
			}
			case TFClass_Medic:
			{
				TF2Attrib_SetByName(client, "hidden maxhealth non buffed", 4350.0);
				TF2Attrib_SetByName(client, "move speed bonus", 0.5);
				TF2Attrib_SetByName(client, "damage force reduction", 0.6);
				TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.6);
				return;
			}
			case TFClass_Sniper:
			{
				TF2Attrib_SetByName(client, "hidden maxhealth non buffed", 1275.0);
				TF2Attrib_SetByName(client, "move speed bonus", 0.5);
				TF2Attrib_SetByName(client, "damage force reduction", 0.4);
				TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.4);
				TF2Attrib_SetByName(client, "override footstep sound set", 4.0);
				return;
			}
			case TFClass_Spy:
			{
				TF2Attrib_SetByName(client, "hidden maxhealth non buffed", 1175.0);
				TF2Attrib_SetByName(client, "move speed bonus", 0.5);
				TF2Attrib_SetByName(client, "damage force reduction", 0.4);
				TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.4);
				TF2Attrib_SetByName(client, "override footstep sound set", 4.0);
				return;
			}
		}
	}
	else
	{
		switch(TFClass)
		{
/* 			case TFClass_Scout:
			{
			}
			case TFClass_Soldier:
			{
						
			}
			case TFClass_Pyro:
			{
			
			}
			case TFClass_DemoMan:
			{

			}
			case TFClass_Heavy:
			{
		
			} */
			case TFClass_Engineer:
			{
				TF2Attrib_SetByName(client, "hidden maxhealth non buffed", 375.0);
				TF2Attrib_SetByName(client, "cannot pick up buildings", 1.0);
				return;
			}
/* 			case TFClass_Medic:
			{

			}
			case TFClass_Sniper:
			{

			} */
			case TFClass_Spy:
			{
				iWeapon = GetPlayerWeaponSlot(client, 4); // spy invis watch
				if(iWeapon != -1) {
					TF2Attrib_SetByName(iWeapon, "mult cloak meter regen rate", 4.0); // own spy doesn't have inf cloak
				}
			}
		}
	}
}

// ==== ROBOT TEMPLATE CONFIG FILES ====
void RT_InitArrays()
{
	for(int i = 0;i < MAX_ROBOTS_TEMPLATE;i++)
	{
		for(int y = 0;y < CONST_ROBOT_CLASSES;y++)
		{
			g_BNWeaponClass[i][y] = new ArrayList(ByteCountToCells(MAXLEN_CONFIG_STRING));
			g_BNCharAttrib[i][y] = new ArrayList(ByteCountToCells(MAXLEN_CONFIG_STRING));
			g_BNCharAttribValue[i][y] = new ArrayList(ByteCountToCells(MAXLEN_CONFIG_STRING));
			g_BGWeaponClass[i][y] = new ArrayList(ByteCountToCells(MAXLEN_CONFIG_STRING));
			g_BGCharAttrib[i][y] = new ArrayList(ByteCountToCells(MAXLEN_CONFIG_STRING));
			g_BGCharAttribValue[i][y] = new ArrayList(ByteCountToCells(MAXLEN_CONFIG_STRING));
			for(int x = 0;x < MAX_ROBOTS_WEAPONS;x++)
			{
				g_BNWeapAttrib[i][y][x] = new ArrayList(ByteCountToCells(MAXLEN_CONFIG_STRING));
				g_BNWeapAttribValue[i][y][x] = new ArrayList(ByteCountToCells(MAXLEN_CONFIG_STRING));
				g_BGWeapAttrib[i][y][x] = new ArrayList(ByteCountToCells(MAXLEN_CONFIG_STRING));
				g_BGWeapAttribValue[i][y][x] = new ArrayList(ByteCountToCells(MAXLEN_CONFIG_STRING));
			}
		}
	}
}

// Clear old robot template data
void RT_ClearArrays()
{
	for(int i = 0;i < MAX_ROBOTS_TEMPLATE;i++)
	{
		for(int y = 0;y < CONST_ROBOT_CLASSES;y++)
		{
			// Normal
			g_BNWeaponClass[i][y].Clear();
			g_BNCharAttrib[i][y].Clear();
			g_BNCharAttribValue[i][y].Clear();
			// Giant
			g_BGWeaponClass[i][y].Clear();
			g_BGCharAttrib[i][y].Clear();
			g_BGCharAttribValue[i][y].Clear();
			for(int x = 0;x < MAX_ROBOTS_WEAPONS;x++)
			{
				// Normal
				g_BNWeapAttrib[i][y][x].Clear();
				g_BNWeapAttribValue[i][y][x].Clear();
				g_BNWeaponClass[i][y].PushString("");
				// Giant
				g_BGWeapAttrib[i][y][x].Clear();
				g_BGWeapAttribValue[i][y][x].Clear();
				g_BGWeaponClass[i][y].PushString("");
			}
		}
	}
	
	// Reset the number of robots template available
	for(int i = 0;i < MAX_TEMPLATE_TYPE;i++)
	{
		for(int y = 0;y < CONST_ROBOT_CLASSES;y++)
		{
			g_nBotTemplate[i].numtemplates[y] = 0;
		}
	}
}

// Parse data after reading the config files.
void RT_PostLoad()
{
	char strBits[12][MAXLEN_CONFIG_STRING];
	int iNum, iBits;

	for(int i = 0;i < MAX_ROBOTS_TEMPLATE;i++)
	{
		for(int y = 0;y < CONST_ROBOT_CLASSES;y++)
		{
			g_BNBitsAttribs[i][y] = 0; // Unlike other variables, this one doesn't get a default value when reading the config file.
			if(strlen(g_BNRobotAttribs[i][y]) > 0)
			{
				iBits = 0;
				iNum = ExplodeString(g_BNRobotAttribs[i][y], ",", strBits, sizeof(strBits), sizeof(strBits[]));
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
				g_BNBitsAttribs[i][y] = iBits;
			}
		}
	}
	
	for(int i = 0;i < MAX_ROBOTS_TEMPLATE;i++)
	{
		for(int y = 0;y < CONST_ROBOT_CLASSES;y++)
		{
			g_BGBitsAttribs[i][y] = 0; // Unlike other variables, this one doesn't get a default value when reading the config file.
			if(strlen(g_BGRobotAttribs[i][y]) > 0)
			{
				iBits = 0;
				iNum = ExplodeString(g_BGRobotAttribs[i][y], ",", strBits, sizeof(strBits), sizeof(strBits[]));
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
				g_BGBitsAttribs[i][y] = iBits;
			}
		}
	}
}

// Stock Normal Robots
void RT_LoadCfgNormal()
{
	char filename[32], configfile[PLATFORM_MAX_PATH];
	
	GetNormalBotTFile(filename, sizeof(filename));

	BuildPath(Path_SM, configfile, sizeof(configfile), "configs/bwrr/");
	
	Format(configfile, sizeof(configfile), "%s%s", configfile, filename);
	
	if(!FileExists(configfile))
	{
		SetFailState("Failed to load config file %s", configfile);
	}
	
	
	KeyValues kv = new KeyValues("RobotTemplate");
	kv.ImportFromFile(configfile);
	int iCounter = 0;
	
	// Jump into the first subsection
	if (!kv.GotoFirstSubKey())
	{
		delete kv;
		return;
	}
	kv.GoBack();
	
    // Iterate over subsections at the same nesting level
	// iCounter is the robot ID/index
	// j is the Class ID. !!! J MUST match TFClassType
	char buffer[255];
	do
	{
		for(int j = 0;j < sizeof(g_strClassKey);j++)
		{
			kv.GetSectionName(buffer, sizeof(buffer));
			if(kv.JumpToKey(g_strClassKey[j]))
			{
				kv.GetSectionName(buffer, sizeof(buffer));
				if(kv.GotoFirstSubKey(true))
				{
					iCounter = 0;
					do
					{
						KvGetString(kv, "name", g_BNTemplateName[iCounter][j], MAXLEN_CONFIG_STRING);
						KvGetString(kv, "robotattributes", g_BNRobotAttribs[iCounter][j], MAXLEN_CONFIG_STRING);
						g_BNHealth[iCounter][j] = kv.GetNum("health", 0);
						g_BNType[iCounter][j] = kv.GetNum("type", 0);
						g_BNScale[iCounter][j] = kv.GetFloat("scale", 0.0);
						g_BNCooldown[iCounter][j] = kv.GetFloat("cooldown", 0.0);
						g_BNCritChance[iCounter][j] = kv.GetNum("fullcritchance", 0);
						g_BNCurrency[iCounter][j] = kv.GetNum("currency", 0);
						KvGetString(kv, "description", g_BNDescription[iCounter][j], MAXLEN_CONFIG_STRING);
						
						if(kv.JumpToKey("playerattributes"))
						{
							kv.GetSectionName(buffer, sizeof(buffer));
							if(kv.GotoFirstSubKey(false))
							{
								do
								{ // Store Player Attributes

#if defined __tf_custom_attributes_included
									kv.GetSectionName(buffer, sizeof(buffer)); // Get Attribute Name
									g_BNCharAttrib[iCounter][j].PushString(buffer); // Attribute Name
									kv.GetString(NULL_STRING, buffer, sizeof(buffer)); // Retreive Attribute Name
									g_BNCharAttribValue[iCounter][j].PushString(buffer); // Store Attribute Value

#else 
									kv.GetSectionName(buffer, sizeof(buffer)); // Get Attribute Name
									if(TF2Attrib_IsValidAttributeName(buffer))
									{
										g_BNCharAttrib[iCounter][j].PushString(buffer); // Attribute Name
										kv.GetString(NULL_STRING, buffer, sizeof(buffer)); // Retreive Attribute Name
										g_BNCharAttribValue[iCounter][j].PushString(buffer); // Store Attribute Value
									}
									else
									{
										LogError("ERROR: Invalid player attribute \"%s\" in robot \"%s\"", buffer, g_BNTemplateName[iCounter][j]);
									}
#endif
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

								if (strncmp(buffer, "saxxy", 5, false) == 0)
								{
									ThrowError("\"saxxy\" is not a valid weapon entity classname! You must manually translate the \"saxxy\" classname into a real entity classname.");
								}

								g_BNWeaponClass[iCounter][j].SetString(i, buffer); // Store Weapon Classname
								g_BNWeaponIndex[iCounter][j][i] = kv.GetNum("index"); // Store Weapon Definition Index
								g_BNWeapChance[iCounter][j][i] = kv.GetNum("spawnchance", 100); // Store Weapon Spawn Chance
								
								if(kv.GotoFirstSubKey())
								{
									if(kv.GotoFirstSubKey(false)) // Read Weapon's Attributes
									{
										do
										{
#if defined __tf_custom_attributes_included
											kv.GetSectionName(buffer, sizeof(buffer));
											g_BNWeapAttrib[iCounter][j][i].PushString(buffer); // Store Attribute Name
											kv.GetString(NULL_STRING, buffer, sizeof(buffer)); // Retreive Attribute Name
											g_BNWeapAttribValue[iCounter][j][i].PushString(buffer); // Store Attribute Value
#else
											kv.GetSectionName(buffer, sizeof(buffer));
											if(TF2Attrib_IsValidAttributeName(buffer))
											{
												g_BNWeapAttrib[iCounter][j][i].PushString(buffer); // Store Attribute Name
												kv.GetString(NULL_STRING, buffer, sizeof(buffer)); // Retreive Attribute Name
												g_BNWeapAttribValue[iCounter][j][i].PushString(buffer); // Store Attribute Value
											}
											else
											{
												LogError("ERROR: Invalid weapon attribute \"%s\" in robot \"%s\" weapon \"%s\"", buffer, g_BNTemplateName[iCounter][j], g_strWeaponsKey[i]);
											}
#endif
										} while(kv.GotoNextKey(false));
										kv.GoBack();
									}
									kv.GoBack();
								}
								kv.GoBack();
							}			
						}
						iCounter++;
						// Limit check
						if(iCounter >= MAX_ROBOTS_TEMPLATE)
						{
							LogError("FATAL ERROR: Template limit (%i) reached for normal %s robot. The last valid robot is: %s", MAX_ROBOTS_TEMPLATE, g_strClassKey[j], g_BNTemplateName[MAX_ROBOTS_TEMPLATE-1][j]);
							break;
						}
					} while(kv.GotoNextKey());
					g_nBotTemplate[TemplateType_Normal].numtemplates[j] = iCounter;
					kv.GoBack();
				}
				kv.GoBack();
			}		
		}
	} while (kv.GotoNextKey());
	
	delete kv;
}

// Stock Giant Robots
void RT_LoadCfgGiant()
{
	char filename[32], configfile[PLATFORM_MAX_PATH];
	
	GetGiantBotTFile(filename, sizeof(filename));

	BuildPath(Path_SM, configfile, sizeof(configfile), "configs/bwrr/");
	
	Format(configfile, sizeof(configfile), "%s%s", configfile, filename);
	
	if(!FileExists(configfile))
	{
		SetFailState("Failed to load config file %s", configfile);
	}
	
	
	KeyValues kv = new KeyValues("RobotTemplate");
	kv.ImportFromFile(configfile);
	int iCounter = 0;
	
	// Jump into the first subsection
	if (!kv.GotoFirstSubKey())
	{
		delete kv;
		return;
	}
	kv.GoBack();
	
    // Iterate over subsections at the same nesting level
	// iCounter is the robot ID/index
	// j is the Class ID. !!! J MUST match TFClassType
	char buffer[255];
	do
	{
		for(int j = 0;j < sizeof(g_strClassKey);j++)
		{
			kv.GetSectionName(buffer, sizeof(buffer));
			if(kv.JumpToKey(g_strClassKey[j]))
			{
				kv.GetSectionName(buffer, sizeof(buffer));
				if(kv.GotoFirstSubKey(true))
				{
					iCounter = 0;
					do
					{
						KvGetString(kv, "name", g_BGTemplateName[iCounter][j], MAXLEN_CONFIG_STRING);
						KvGetString(kv, "robotattributes", g_BGRobotAttribs[iCounter][j], MAXLEN_CONFIG_STRING);
						g_BGHealth[iCounter][j] = kv.GetNum("health", 0);
						//g_BGType[iCounter][j] = kv.GetNum("type", 0); // Not used by giant robots
						g_BGScale[iCounter][j] = kv.GetFloat("scale", 0.0);
						g_BGCooldown[iCounter][j] = kv.GetFloat("cooldown", 0.0);
						g_BGCritChance[iCounter][j] = kv.GetNum("fullcritchance", 0);
						g_BGCurrency[iCounter][j] = kv.GetNum("currency", 0);
						KvGetString(kv, "description", g_BGDescription[iCounter][j], MAXLEN_CONFIG_STRING);
						
						if(kv.JumpToKey("playerattributes"))
						{
							kv.GetSectionName(buffer, sizeof(buffer));
							if(kv.GotoFirstSubKey(false))
							{
								do
								{ // Store Player Attributes
#if defined __tf_custom_attributes_included
									kv.GetSectionName(buffer, sizeof(buffer)); // Get Attribute Name
									g_BGCharAttrib[iCounter][j].PushString(buffer); // Attribute Name
									kv.GetString(NULL_STRING, buffer, sizeof(buffer)); // Retreive Attribute Name
									g_BGCharAttribValue[iCounter][j].PushString(buffer); // Store Attribute Value

#else
									kv.GetSectionName(buffer, sizeof(buffer)); // Get Attribute Name
									if(TF2Attrib_IsValidAttributeName(buffer))
									{
										g_BGCharAttrib[iCounter][j].PushString(buffer); // Attribute Name
										kv.GetString(NULL_STRING, buffer, sizeof(buffer)); // Retreive Attribute Name
										g_BGCharAttribValue[iCounter][j].PushString(buffer); // Store Attribute Value
									}
									else
									{
										LogError("ERROR: Invalid player attribute \"%s\" in robot \"%s\"", buffer, g_BGTemplateName[iCounter][j]);
									}
#endif
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

								if (strncmp(buffer, "saxxy", 5, false) == 0)
								{
									ThrowError("\"saxxy\" is not a valid weapon entity classname! You must manually translate the \"saxxy\" classname into a real entity classname.");
								}

								g_BGWeaponClass[iCounter][j].SetString(i, buffer); // Store Weapon Classname
								g_BGWeaponIndex[iCounter][j][i] = kv.GetNum("index"); // Store Weapon Definition Index
								g_BGWeapChance[iCounter][j][i] = kv.GetNum("spawnchance", 100); // Store Weapon Spawn Chance
								
								if(kv.GotoFirstSubKey())
								{
									if(kv.GotoFirstSubKey(false)) // Read Weapon's Attributes
									{
										do
										{
#if defined __tf_custom_attributes_included
											kv.GetSectionName(buffer, sizeof(buffer));
											g_BGWeapAttrib[iCounter][j][i].PushString(buffer); // Store Attribute Name
											kv.GetString(NULL_STRING, buffer, sizeof(buffer)); // Retreive Attribute Name
											g_BGWeapAttribValue[iCounter][j][i].PushString(buffer); // Store Attribute Value
#else
											kv.GetSectionName(buffer, sizeof(buffer));
											if(TF2Attrib_IsValidAttributeName(buffer))
											{
												g_BGWeapAttrib[iCounter][j][i].PushString(buffer); // Store Attribute Name
												kv.GetString(NULL_STRING, buffer, sizeof(buffer)); // Retreive Attribute Name
												g_BGWeapAttribValue[iCounter][j][i].PushString(buffer); // Store Attribute Value
											}
											else
											{
												LogError("ERROR: Invalid weapon attribute \"%s\" in robot \"%s\" weapon \"%s\"", buffer, g_BGTemplateName[iCounter][j], g_strWeaponsKey[i]);
											}
#endif
										} while(kv.GotoNextKey(false));
										kv.GoBack();
									}
									kv.GoBack();
								}
								kv.GoBack();
							}			
						}
						iCounter++;
						// Limit check
						if(iCounter >= MAX_ROBOTS_TEMPLATE)
						{
							LogError("FATAL ERROR: Template limit (%i) reached for normal %s robot. The last valid robot is: %s", MAX_ROBOTS_TEMPLATE, g_strClassKey[j], g_BGTemplateName[MAX_ROBOTS_TEMPLATE-1][j]);
							break;
						}
					} while(kv.GotoNextKey());
					g_nBotTemplate[TemplateType_Giant].numtemplates[j] = iCounter;
					kv.GoBack();
				}
				kv.GoBack();
			}		
		}
	} while (kv.GotoNextKey());
	
	delete kv;
}

// Support Functions
// returns the number of templates available for the given class
// Remember that the first 
int RT_NumTemplates(bool bGiant = false,TFClassType Class)
{
	int iClass =  view_as<int>(Class) - 1;
	if(bGiant)
	{
		switch(Class)
		{
			case TFClass_Scout: return g_nBotTemplate[TemplateType_Giant].numtemplates[iClass];
			case TFClass_Sniper: return g_nBotTemplate[TemplateType_Giant].numtemplates[iClass];
			case TFClass_Soldier: return g_nBotTemplate[TemplateType_Giant].numtemplates[iClass];
			case TFClass_DemoMan: return g_nBotTemplate[TemplateType_Giant].numtemplates[iClass];
			case TFClass_Heavy: return g_nBotTemplate[TemplateType_Giant].numtemplates[iClass];
			case TFClass_Pyro: return g_nBotTemplate[TemplateType_Giant].numtemplates[iClass];
			case TFClass_Engineer: return g_nBotTemplate[TemplateType_Giant].numtemplates[iClass];
			case TFClass_Medic: return g_nBotTemplate[TemplateType_Giant].numtemplates[iClass];
			case TFClass_Spy: return g_nBotTemplate[TemplateType_Giant].numtemplates[iClass];
		}
	}
	else
	{
		switch(Class)
		{
			case TFClass_Scout: return g_nBotTemplate[TemplateType_Normal].numtemplates[iClass];
			case TFClass_Sniper: return g_nBotTemplate[TemplateType_Normal].numtemplates[iClass];
			case TFClass_Soldier: return g_nBotTemplate[TemplateType_Normal].numtemplates[iClass];
			case TFClass_DemoMan: return g_nBotTemplate[TemplateType_Normal].numtemplates[iClass];
			case TFClass_Heavy: return g_nBotTemplate[TemplateType_Normal].numtemplates[iClass];
			case TFClass_Pyro: return g_nBotTemplate[TemplateType_Normal].numtemplates[iClass];
			case TFClass_Engineer: return g_nBotTemplate[TemplateType_Normal].numtemplates[iClass];
			case TFClass_Medic: return g_nBotTemplate[TemplateType_Normal].numtemplates[iClass];
			case TFClass_Spy: return g_nBotTemplate[TemplateType_Normal].numtemplates[iClass];
		}		
	}
	
	return 0;
}