// pootis robots here

// defines
#define MAX_TEMPLATE_TYPE 2
#define MAX_ROBOTS_TEMPLATE 50
#define MAX_ROBOTS_WEAPONS 6
#define CONST_ROBOT_CLASSES 10
#define MAXLEN_CONFIG_STRING 128

// Globals
char g_strConfigFile[PLATFORM_MAX_PATH];

// Big list of arrays
/**
* Prefixes
* g_BN - Bot Stock Normal
* g_BG - Bot Stock Giant
**/
// == STOCK NORMAL ROBOTS ==
char g_BNTemplateName[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAXLEN_CONFIG_STRING];
char g_BNRobotAttribs[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAXLEN_CONFIG_STRING];
int g_BNWeaponIndex[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAX_ROBOTS_WEAPONS];
int g_BNBitsAttribs[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES];
int g_BNHealth[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES];
int g_BNType[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES];
ArrayList g_BNWeaponClass[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES];
ArrayList g_BNCharAttrib[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES];
ArrayList g_BNCharAttribValue[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES];
ArrayList g_BNWeapAttrib[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAX_ROBOTS_WEAPONS];
ArrayList g_BNWeapAttribValue[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAX_ROBOTS_WEAPONS];
// == STOCK GIANT ROBOTS ==
char g_BGTemplateName[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAXLEN_CONFIG_STRING];
char g_BGRobotAttribs[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAXLEN_CONFIG_STRING];
int g_BGWeaponIndex[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAX_ROBOTS_WEAPONS];
int g_BGBitsAttribs[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES];
int g_BGHealth[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES];
int g_BGType[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES];
ArrayList g_BGWeaponClass[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES];
ArrayList g_BGCharAttrib[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES];
ArrayList g_BGCharAttribValue[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES];
ArrayList g_BGWeapAttrib[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAX_ROBOTS_WEAPONS];
ArrayList g_BGWeapAttribValue[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAX_ROBOTS_WEAPONS];

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
void StripItems( int client, bool RemoveWeapons = true )
{	
	if( !IsClientInGame(client) || IsFakeClient( client ) || !IsPlayerAlive( client ) )
		return;
		
	int iEntity;
	int iOwner;
	
	if(RemoveWeapons)
	{
		iEntity = -1;
		while( ( iEntity = FindEntityByClassname( iEntity, "tf_wearable_demoshield" ) ) > MaxClients )
		{
			iOwner = GetEntPropEnt( iEntity, Prop_Send, "m_hOwnerEntity" );
			if( iOwner == client )
			{
				TF2_RemoveWearable( client, iEntity );
				AcceptEntityInput( iEntity, "Kill" );
			}
		}
		
		iEntity = -1;
		while( ( iEntity = FindEntityByClassname( iEntity, "tf_wearable_razorback" ) ) > MaxClients )
		{
			iOwner = GetEntPropEnt( iEntity, Prop_Send, "m_hOwnerEntity" );
			if( iOwner == client )
			{
				TF2_RemoveWearable( client, iEntity );
				AcceptEntityInput( iEntity, "Kill" );
			}
		}
		
		TF2_RemoveAllWeapons(client);
		// bug: sappers and toolboxes aren't removed however this shouldn't be a problem.
	}
	
	if( !OR_IsHalloweenMission() ) // Allow players to have wearables on wave 666
	{
		iEntity = -1;
		while( ( iEntity = FindEntityByClassname( iEntity, "tf_wearable" ) ) > MaxClients )
		{
			iOwner = GetEntPropEnt( iEntity, Prop_Send, "m_hOwnerEntity" );
			if( iOwner == client )
			{
				TF2_RemoveWearable( client, iEntity );
				AcceptEntityInput( iEntity, "Kill" );
			}
		}
	}
	
	iEntity = -1;
	while( ( iEntity = FindEntityByClassname( iEntity, "tf_powerup_bottle" ) ) > MaxClients )
	{
		iOwner = GetEntPropEnt( iEntity, Prop_Send, "m_hOwnerEntity" );
		if( iOwner == client )
			AcceptEntityInput( iEntity, "Kill" );
	}
	iEntity = -1;
	while( ( iEntity = FindEntityByClassname( iEntity, "tf_usableitem" ) ) > MaxClients )
	{
		iOwner = GetEntPropEnt( iEntity, Prop_Send, "m_hOwnerEntity" );
		if( iOwner == client )
			AcceptEntityInput( iEntity, "Kill" );
	}
}

// remove items from the player
void StripWeapons( int client )
{	
	if( !IsClientInGame(client) || IsFakeClient( client ) || !IsPlayerAlive( client ) )
		return;
		
	int iEntity;
	int iOwner;
	
	iEntity = -1;
	while( ( iEntity = FindEntityByClassname( iEntity, "tf_wearable_demoshield" ) ) > MaxClients )
	{
		iOwner = GetEntPropEnt( iEntity, Prop_Send, "m_hOwnerEntity" );
		if( iOwner == client )
		{
			TF2_RemoveWearable( client, iEntity );
			AcceptEntityInput( iEntity, "Kill" );
		}
	}
	
	iEntity = -1;
	while( ( iEntity = FindEntityByClassname( iEntity, "tf_wearable_razorback" ) ) > MaxClients )
	{
		iOwner = GetEntPropEnt( iEntity, Prop_Send, "m_hOwnerEntity" );
		if( iOwner == client )
		{
			TF2_RemoveWearable( client, iEntity );
			AcceptEntityInput( iEntity, "Kill" );
		}
	}
	
	TF2_RemoveAllWeapons(client);
	// bug: sappers and toolboxes aren't removed however this shouldn't be a problem.
}

bool IsWeaponWearable(char[] classname)
{
	char strWearables[3][] = {"tf_wearable_demoshield", "tf_wearable_razorback", "tf_wearable"};
	
	for(int i = 0;i < sizeof(strWearables);i++)
	{
		if(StrEqual(classname, strWearables[i], false))
			return true;
	}
	
	return false;
}
int GetClassBaseHealth(TFClassType Class)
{
	switch( Class )
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
	if( IsValidEdict( entity ) )
	{
		if( bWearable )
		{
			TF2_EquipPlayerWearable(client, entity);
		}
		else
			EquipPlayerWeapon( client, entity );
	}
	return entity;
}

// Give weapons to the player
// type: 0 - normal, 1 - giant
void RT_GiveInventory(int client, int type = 0, int templateindex)
{
	if( IsFakeClient(client) )
		return;

	TFClassType TFClass = TF2_GetPlayerClass(client);
	int iClass = view_as<int>(TFClass);
	int iWeapon;
	char buffer[255];
	
	if(type == 0) // Normal
	{
		if(templateindex <= g_nBotTemplate[TemplateType_Normal].numtemplates[iClass]) // This is a stock robot
		{
			// Set Health
			int iHealth = (g_BNHealth[templateindex][iClass] - GetClassBaseHealth(TFClass));
			if(iHealth <= 0)
			{
				iHealth = GetClassBaseHealth(TFClass);
				if(iHealth < 0)
					LogError("Error: Robot \"%s\" with negative health!", g_BNTemplateName[templateindex][iClass]);
			}
			TF2Attrib_SetByName(client, "hidden maxhealth non buffed", view_as<float>(iHealth));
			
			// Set Player Attributes
			if(g_BNCharAttrib[templateindex][iClass].Length > 0)
			{
				for(int i = 0;i < g_BNCharAttrib[templateindex][iClass].Length;i++)
				{
					g_BNCharAttrib[templateindex][iClass].GetString(i, buffer, sizeof(buffer));
					TF2Attrib_SetByName(client, buffer, g_BNCharAttrib[templateindex][iClass].Get(i));
				}
			}

			// Spawn Weapons
			for(int i = 0;i < MAX_ROBOTS_WEAPONS;i++)
			{
				g_BNWeaponClass[templateindex][iClass].GetString(i, buffer, sizeof(buffer));
				if(strlen(buffer) > 3) // check if a weapon exists
				{
					iWeapon = SpawnWeapon(client, buffer, g_BNWeaponIndex[templateindex][iClass][i], 1, 6, IsWeaponWearable(buffer));
					if(g_BNWeapAttrib[templateindex][iClass][i].Length > 0) // Does this weapon have custom attributes?
					{
						for(int y = 0;y < g_BNWeapAttrib[templateindex][iClass][i].Length;y++)
						{
							g_BNWeapAttrib[templateindex][iClass][i].GetString(y, buffer, sizeof(buffer));
							TF2Attrib_SetByName(iWeapon, buffer, g_BNWeapAttribValue[templateindex][iClass][i].Get(y));
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
			// Set Health
			int iHealth = (g_BGHealth[templateindex][iClass] - GetClassBaseHealth(TFClass));
			if(iHealth <= 0)
			{
				iHealth = GetClassBaseHealth(TFClass);
				LogError("Error: Robot \"%s\" with negative health!", g_BGTemplateName[templateindex][iClass]);
			}
			TF2Attrib_SetByName(client, "hidden maxhealth non buffed", view_as<float>(iHealth));
			
			// Set Player Attributes
			if(g_BGCharAttrib[templateindex][iClass].Length > 0)
			{
				for(int i = 0;i < g_BGCharAttrib[templateindex][iClass].Length;i++)
				{
					g_BGCharAttrib[templateindex][iClass].GetString(i, buffer, sizeof(buffer));
					TF2Attrib_SetByName(client, buffer, g_BGCharAttrib[templateindex][iClass].Get(i));
				}
			}

			// Spawn Weapons
			for(int i = 0;i < MAX_ROBOTS_WEAPONS;i++)
			{
				g_BGWeaponClass[templateindex][iClass].GetString(i, buffer, sizeof(buffer));
				if(strlen(buffer) > 3) // check if a weapon exists
				{
					iWeapon = SpawnWeapon(client, buffer, g_BGWeaponIndex[templateindex][iClass][i], 1, 6, IsWeaponWearable(buffer));
					if(g_BGWeapAttrib[templateindex][iClass][i].Length > 0) // Does this weapon have custom attributes?
					{
						for(int y = 0;y < g_BGWeapAttrib[templateindex][iClass][i].Length;y++)
						{
							g_BGWeapAttrib[templateindex][iClass][i].GetString(y, buffer, sizeof(buffer));
							TF2Attrib_SetByName(iWeapon, buffer, g_BGWeapAttribValue[templateindex][iClass][i].Get(y));
						}
					}
				}
			}
		}
	}
}

// Returns the robot name
char RT_GetTemplateName(TFClassType TFClass, int templateindex, int type = 0)
{
	char buffer[255];
	int iClass = view_as<int>(TFClass);
	
	if(templateindex < 0)
	{
		strcopy(buffer, sizeof(buffer), "Your Own Loadout");
		return buffer;
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
	}
	
	return buffer;
}

// Returns the robot attributes
int RT_GetAttributesBits(TFClassType TFClass, int templateindex, int type = 0)
{
	int iBits = 0;
	int iClass = view_as<int>(TFClass);
	
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
	int iClass = view_as<int>(TFClass);
	
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
				iRobotType = g_BGType[templateindex][iClass];
			}			
		}
	}
	
	return iRobotType;
}

void GiveNormalInventory(int client ,int botvariant)
{
	if( IsFakeClient(client) )
		return;

	TFClassType TFClass = TF2_GetPlayerClass(client);
	int iWeapon;
	
	switch( TFClass )
	{
		case TFClass_Scout:
		{
			switch( botvariant )
			{
				case 0: // standard scout
				{
					SpawnWeapon( client, "tf_weapon_scattergun", 13, 1, 6, false ); // client, classname, item index, level, quality, Is Wearable?
					return;					
				}
				case 1: // bat scout
				{
					SpawnWeapon( client, "tf_weapon_bat", 0, 1, 6, false );
					return;					
				}
				case 2: // bonk scout
				{
					SpawnWeapon( client, "tf_weapon_lunchbox_drink", 46, 1, 6, false);
					SpawnWeapon( client, "tf_weapon_bat", 0, 1, 6, false );
					return;					
				}
				case 3: // Minor League Scout
				{
					SpawnWeapon( client, "tf_weapon_bat_wood", 44, 1, 6, false );
					return;					
				}
				case 4: // Hyper League Scout
				{
					iWeapon = SpawnWeapon( client, "tf_weapon_bat_wood", 44, 1, 6, false );
					TF2Attrib_SetByName(iWeapon, "effect bar recharge rate increased", 0.25);
					return;					
				}
				case 5: // Force-A-Nature Scout
				{
					iWeapon = SpawnWeapon( client, "tf_weapon_scattergun", 45, 1, 6, false );
					TF2Attrib_SetByName(iWeapon, "faster reload rate", 1.6);
					TF2Attrib_SetByName(iWeapon, "scattergun knockback mult", 1.5);
					TF2Attrib_SetByName(iWeapon, "damage bonus", 0.65);
					return;					
				}
				case 6: // Shortstop Scout
				{
					iWeapon = SpawnWeapon( client, "tf_weapon_handgun_scout_primary", 220, 1, 6, false );
					TF2Attrib_SetByName(iWeapon, "head scale", 0.7);
					TF2Attrib_SetByName(iWeapon, "move speed bonus", 1.25);
					TF2Attrib_SetByName(iWeapon, "hidden maxhealth non buffed", 525.0);
					return;					
				}
			}
		}
		case TFClass_Soldier:
		{
			switch( botvariant )
			{
				case 0: // standard soldier
				{
					SpawnWeapon( client, "tf_weapon_rocketlauncher", 18, 1, 6, false );
					SpawnWeapon( client, "tf_weapon_shovel", 6, 1, 6, false );
					return;					
				}
				case 1: // direct hit soldier
				{
					SpawnWeapon( client, "tf_weapon_rocketlauncher_directhit", 127, 1, 6, false );
					SpawnWeapon( client, "tf_weapon_shovel", 6, 1, 6, false );
					return;						
				}
				case 2: // extended buff soldier
				{
					SpawnWeapon( client, "tf_weapon_rocketlauncher", 18, 1, 6, false );
					iWeapon = SpawnWeapon( client, "tf_weapon_buff_item", 129, 1, 6, false );
					TF2Attrib_SetByName(iWeapon, "increase buff duration", 9.0);
					return;						
				}
				case 3: // extended battalions soldier
				{
					SpawnWeapon( client, "tf_weapon_rocketlauncher", 18, 1, 6, false );
					iWeapon = SpawnWeapon( client, "tf_weapon_buff_item", 226, 1, 6, false );
					TF2Attrib_SetByName(iWeapon, "increase buff duration", 9.0);
					return;						
				}
				case 4: // extended concheror soldier
				{
					SpawnWeapon( client, "tf_weapon_rocketlauncher", 18, 1, 6, false );
					iWeapon = SpawnWeapon( client, "tf_weapon_buff_item", 354, 1, 6, false );
					TF2Attrib_SetByName(iWeapon, "increase buff duration", 9.0);
					return;						
				}
				case 5: // blast soldier
				{
					iWeapon = SpawnWeapon( client, "tf_weapon_rocketlauncher", 414, 1, 6, false );
					TF2Attrib_SetByName(iWeapon, "damage causes airblast", 1.0);
					TF2Attrib_SetByName(iWeapon, "damage bonus", 0.45);
					TF2Attrib_SetByName(iWeapon, "fire rate bonus", 0.001);
					TF2Attrib_SetByName(iWeapon, "clip size upgrade atomic", -2.0);
					TF2Attrib_SetByName(iWeapon, "faster reload rate", 1.5);
					TF2Attrib_SetByName(iWeapon, "Blast radius decreased", 1.2);
					TF2Attrib_SetByName(iWeapon, "projectile spread angle penalty", 2.0);
					SpawnWeapon( client, "tf_weapon_shovel", 6, 1, 6, false );
					return;						
				}
				case 6: // black box soldier
				{
					iWeapon = SpawnWeapon( client, "tf_weapon_rocketlauncher", 228, 1, 6, false );
					TF2Attrib_SetByName(iWeapon, "heal on hit for rapidfire", 60.0);
					TF2Attrib_SetByName(iWeapon, "damage bonus", 0.33);
					TF2Attrib_SetByName(iWeapon, "fire rate bonus", 0.001);
					TF2Attrib_SetByName(iWeapon, "clip size upgrade atomic", 0.0);
					TF2Attrib_SetByName(iWeapon, "faster reload rate", 0.9);
					TF2Attrib_SetByName(iWeapon, "blast radius increased", 1.25);
					TF2Attrib_SetByName(iWeapon, "projectile spread angle penalty", 2.0);
					SpawnWeapon( client, "tf_weapon_shovel", 6, 1, 6, false );
					return;						
				}
			}
		}
		case TFClass_Pyro:
		{
			switch( botvariant )
			{
				case 0: // standard pyro
				{
					SpawnWeapon( client, "tf_weapon_flamethrower", 21, 1, 6, false ); // client, classname, item index, level, quality, Is Wearable?
					SpawnWeapon( client, "tf_weapon_fireaxe", 2, 1, 6, false ); // Fire Axe
					return;					
				}
				case 1: // flare pyro
				{
					SpawnWeapon( client, "tf_weapon_flaregun", 39, 1, 6, false );
					SpawnWeapon( client, "tf_weapon_fireaxe", 2, 1, 6, false ); // Fire Axe
					return;					
				}
				case 2: // Pyro Pusher
				{
					iWeapon = SpawnWeapon( client, "tf_weapon_flaregun", 740, 1, 6, false );
					TF2Attrib_SetByName(iWeapon, "fire rate bonus", 0.75);
					TF2Attrib_SetByName(iWeapon, "faster reload rate", 1.25);
					TF2Attrib_SetByName(iWeapon, "Projectile speed increased", 0.35);
					SpawnWeapon( client, "tf_weapon_fireaxe", 2, 1, 6, false ); // Fire Axe
					return;					
				}
				case 3: // Fast Scorch Shot
				{
					iWeapon = SpawnWeapon( client, "tf_weapon_flaregun", 740, 1, 6, false );
					TF2Attrib_SetByName(iWeapon, "fire rate bonus", 0.75);
					TF2Attrib_SetByName(iWeapon, "faster reload rate", 1.0);
					TF2Attrib_SetByName(iWeapon, "Projectile speed increased", 1.30);
					SpawnWeapon( client, "tf_weapon_fireaxe", 2, 1, 6, false ); // Fire Axe
					return;					
				}
			}			
		}
		case TFClass_DemoMan:
		{
			switch( botvariant )
			{
				case 0: // standard demo
				{
					SpawnWeapon( client, "tf_weapon_grenadelauncher", 19, 1, 6, false );
					return;			
				}
				case 1: // burst fire demo
				{
					iWeapon = SpawnWeapon( client, "tf_weapon_grenadelauncher", 19, 1, 6, false );
					TF2Attrib_SetByName(iWeapon, "faster reload rate", 1.75);
					TF2Attrib_SetByName(iWeapon, "fire rate bonus", 0.05);
					TF2Attrib_SetByName(iWeapon, "clip size penalty", 0.5);
					TF2Attrib_SetByName(iWeapon, "projectile spread angle penalty", 3.0);
					return;					
				}
				case 2: // Demoknight
				{
					SpawnWeapon( client, "tf_wearable_demoshield", 131, 1, 6, true ); // set true for wearable weapons.
					iWeapon = SpawnWeapon( client, "tf_weapon_sword", 132, 1, 6, false );
					TF2Attrib_SetByName(iWeapon, "critboost on kill", 3.0);
					return;			
				}
				case 3: // Demo Samurai
				{
					SpawnWeapon( client, "tf_wearable_demoshield", 406, 1, 6, true ); // set true for wearable weapons.
					iWeapon = SpawnWeapon( client, "tf_weapon_katana", 357, 1, 6, false );
					TF2Attrib_SetByName(iWeapon, "increased jump height", 2.3);
					TF2Attrib_SetByName(iWeapon, "damage bonus", 1.5);
					TF2Attrib_SetByName(iWeapon, "hidden maxhealth non buffed", 475.0);
					return;			
				}
			}
		}
		case TFClass_Heavy:
		{
			switch( botvariant )
			{
				case 0: // standard heavy
				{
					SpawnWeapon( client, "tf_weapon_minigun", 15, 1, 6, false );
					return;
				}
				case 1: // Heavyweight Champ
				{
					SpawnWeapon( client, "tf_weapon_fists", 43, 1, 6, false );
					return;					
				}
				case 2: // Heater Heavy
				{
					SpawnWeapon( client, "tf_weapon_minigun", 811, 1, 6, false );
					SpawnWeapon( client, "tf_weapon_fists", 5, 1, 6, false );
					return;
				}
				case 3: // Shotgun Heavy
				{
					iWeapon = SpawnWeapon( client, "tf_weapon_shotgun_hwg", 11, 1, 6, false );
					TF2Attrib_SetByName(iWeapon, "faster reload rate", 0.1);
					TF2Attrib_SetByName(iWeapon, "fire rate bonus", 2.5);
					TF2Attrib_SetByName(iWeapon, "bullets per shot bonus", 3.0);
					TF2Attrib_SetByName(iWeapon, "damage bonus", 0.33);
					SpawnWeapon( client, "tf_weapon_fists", 5, 1, 6, false );
					return;
				}
				case 4: // Steel Gauntlet Pusher
				{
					TF2Attrib_SetByName(client, "hidden maxhealth non buffed", 600.0);
					iWeapon = SpawnWeapon( client, "tf_weapon_fists", 331, 1, 6, false );
					TF2Attrib_SetByName(iWeapon, "damage causes airblast", 1.0);
					TF2Attrib_SetByName(iWeapon, "damage bonus", 1.50);
					return;
				}
				case 5: // Stun Heavy
				{
					TF2Attrib_SetByName(client, "hidden maxhealth non buffed", 80.0);
					iWeapon = SpawnWeapon( client, "tf_weapon_minigun", 15, 1, 6, false );
					TF2Attrib_SetByName(iWeapon, "damage causes airblast", 1.0);
					TF2Attrib_SetByName(iWeapon, "damage penalty", 0.15);
					TF2Attrib_SetByName(iWeapon, "fire rate penalty", 1.4);
					TF2Attrib_SetByName(iWeapon, "mod stun waist high airborne", 1.0);
					TF2Attrib_SetByName(iWeapon, "minigun spinup time increased", 1.8);
					return;
				}
			}			
		}
		case TFClass_Engineer:
		{
			switch( botvariant )
			{
				case 0: // standard engineer (275 HP)
				{
					SpawnWeapon( client, "tf_weapon_shotgun_primary", 9, 1, 6, false );
					SpawnWeapon( client, "tf_weapon_wrench", 7, 1, 6, false );
					iWeapon = SpawnWeapon( client, "tf_weapon_pda_engineer_build", 25, 1, 6, false );
					TF2Attrib_SetByName(iWeapon, "hidden maxhealth non buffed", 150.0);
					TF2Attrib_SetByName(iWeapon, "cannot pick up buildings", 1.0);
					SpawnWeapon( client, "tf_weapon_pda_engineer_destroy", 26, 1, 6, false );
					return;
				}
				case 1: // standard engineer (500 HP)
				{
					SpawnWeapon( client, "tf_weapon_shotgun_primary", 9, 1, 6, false );
					SpawnWeapon( client, "tf_weapon_wrench", 7, 1, 6, false );
					iWeapon = SpawnWeapon( client, "tf_weapon_pda_engineer_build", 25, 1, 6, false );
					TF2Attrib_SetByName(iWeapon, "hidden maxhealth non buffed", 375.0);
					TF2Attrib_SetByName(iWeapon, "cannot pick up buildings", 1.0);
					SpawnWeapon( client, "tf_weapon_pda_engineer_destroy", 26, 1, 6, false );
					return;				
				}
				case 2: // battle engineer (275 HP)
				{
					SpawnWeapon( client, "tf_weapon_shotgun_primary", 9, 1, 6, false );
					SpawnWeapon( client, "tf_weapon_wrench", 7, 1, 6, false );
					iWeapon = SpawnWeapon( client, "tf_weapon_pda_engineer_build", 25, 1, 6, false );
					TF2Attrib_SetByName(iWeapon, "hidden maxhealth non buffed", 150.0);
					TF2Attrib_SetByName(iWeapon, "cannot pick up buildings", 1.0);
					SpawnWeapon( client, "tf_weapon_pda_engineer_destroy", 26, 1, 6, false );
					return;
				}
				case 3: // battle engineer (275 HP)
				{
					SpawnWeapon( client, "tf_weapon_shotgun_primary", 9, 1, 6, false );
					SpawnWeapon( client, "tf_weapon_wrench", 7, 1, 6, false );
					iWeapon = SpawnWeapon( client, "tf_weapon_pda_engineer_build", 25, 1, 6, false );
					TF2Attrib_SetByName(iWeapon, "hidden maxhealth non buffed", 150.0);
					TF2Attrib_SetByName(iWeapon, "cannot pick up buildings", 1.0);
					SpawnWeapon( client, "tf_weapon_pda_engineer_destroy", 26, 1, 6, false );
					return;
				}
			}		
		}
		case TFClass_Medic:
		{
			switch( botvariant )
			{
				case 0: // uber medic
				{
					SpawnWeapon( client, "tf_weapon_syringegun_medic", 17, 1, 6, false );
					SpawnWeapon( client, "tf_weapon_medigun", 29, 1, 6, false );
					SpawnWeapon( client, "tf_weapon_bonesaw", 8, 1, 6, false );
					return;
				}
				case 1: // Kritzkrieg medic
				{
					SpawnWeapon( client, "tf_weapon_syringegun_medic", 17, 1, 6, false );
					SpawnWeapon( client, "tf_weapon_medigun", 35, 1, 6, false );
					SpawnWeapon( client, "tf_weapon_bonesaw", 8, 1, 6, false );
					return;				
				}
				case 2: // Quick-fix Mega Heal Medic
				{
					SpawnWeapon( client, "tf_weapon_syringegun_medic", 17, 1, 6, false );
					iWeapon = SpawnWeapon( client, "tf_weapon_medigun", 411, 1, 6, false );
					TF2Attrib_SetByName(iWeapon, "heal rate bonus", 10.0);
					SpawnWeapon( client, "tf_weapon_bonesaw", 8, 1, 6, false );
					return;				
				}
				case 3: // Shield Medic
				{
					SpawnWeapon( client, "tf_weapon_syringegun_medic", 17, 1, 6, false );
					iWeapon = SpawnWeapon( client, "tf_weapon_medigun", 411, 1, 6, false );
					TF2Attrib_SetByName(iWeapon, "generate rage on heal", 2.0);
					TF2Attrib_SetByName(iWeapon, "increase buff duration", 1.2);
					SpawnWeapon( client, "tf_weapon_bonesaw", 8, 1, 6, false );
					return;				
				}
			}	
		}
		case TFClass_Sniper:
		{
			switch( botvariant )
			{
				case 0: // standard sniper
				{
					SpawnWeapon( client, "tf_weapon_sniperrifle", 14, 1, 6, false );
					SpawnWeapon( client, "tf_weapon_club", 3, 1, 6, false );
					if(GetRandomInt(0,10) > 3)
						SpawnWeapon( client, "tf_wearable_razorback", 57, 1, 6, true );
					return;
				}
				case 1: // bowman
				{
					SpawnWeapon( client, "tf_weapon_compound_bow", 56, 1, 6, false );
					SpawnWeapon( client, "tf_weapon_club", 3, 1, 6, false );
					if(GetRandomInt(0,10) > 5)
						SpawnWeapon( client, "tf_wearable_razorback", 57, 1, 6, true );
					return;			
				}
				case 2: // Sydney Sniper
				{
					SpawnWeapon( client, "tf_weapon_sniperrifle", 230, 1, 6, false ); // The Sydney Sleeper
					SpawnWeapon( client, "tf_weapon_club", 3, 1, 6, false );
					if(GetRandomInt(0,10) > 1)
						SpawnWeapon( client, "tf_wearable_razorback", 57, 1, 6, true );
					return;
				}
			}
		}
		case TFClass_Spy:
		{
			switch( botvariant )
			{
				case 0: // standard spy
				{
					SpawnWeapon( client, "tf_weapon_revolver", 24, 1, 6, false );
					SpawnWeapon( client, "tf_weapon_builder", 735, 1, 6, false );
					SpawnWeapon( client, "tf_weapon_knife", 4, 1, 6, false );
					SpawnWeapon( client, "tf_weapon_pda_spy", 27, 1, 6, false );
					SpawnWeapon( client, "tf_weapon_invis", 30, 1, 6, false );
					return;
				}
				case 1: // dead ringer spy
				{
					SpawnWeapon( client, "tf_weapon_revolver", 24, 1, 6, false );
					SpawnWeapon( client, "tf_weapon_builder", 735, 1, 6, false );
					SpawnWeapon( client, "tf_weapon_knife", 4, 1, 6, false );
					SpawnWeapon( client, "tf_weapon_pda_spy", 27, 1, 6, false );
					SpawnWeapon( client, "tf_weapon_invis", 59, 1, 6, false );
					return;			
				}
				case 2: // gentle spy
				{
					SpawnWeapon( client, "tf_weapon_revolver", 61, 1, 6, false );
					iWeapon = SpawnWeapon( client, "tf_weapon_builder", 735, 1, 6, false );
					TF2Attrib_SetByName(iWeapon, "kill eater score type", 24.0);
					TF2Attrib_SetByName(iWeapon, "sapper damage penalty", 0.0);
					TF2Attrib_SetByName(iWeapon, "sapper degenerates buildings", 0.9);
					iWeapon = SpawnWeapon( client, "tf_weapon_knife", 727, 1, 6, false );
					TF2Attrib_SetByName(iWeapon, "hidden maxhealth non buffed", 375.0);
					SpawnWeapon( client, "tf_weapon_pda_spy", 27, 1, 6, false );
					SpawnWeapon( client, "tf_weapon_invis", 59, 1, 6, false );
					return;			
				}
				case 3: // ninja spy
				{
					SpawnWeapon( client, "tf_weapon_revolver", 24, 1, 6, false );
					SpawnWeapon( client, "tf_weapon_builder", 735, 1, 6, false );
					iWeapon = SpawnWeapon( client, "tf_weapon_knife", 356, 1, 6, false );
					TF2Attrib_SetByName(iWeapon, "move speed bonus", 1.30);
					TF2Attrib_SetByName(iWeapon, "health regen", 4.0);
					SpawnWeapon( client, "tf_weapon_pda_spy", 27, 1, 6, false );
					iWeapon = SpawnWeapon( client, "tf_weapon_invis", 59, 1, 6, false );
					TF2Attrib_SetByName(iWeapon, "SET BONUS: quiet unstealth", 1.0);
					TF2Attrib_SetByName(iWeapon, "mult cloak meter regen rate", 24.0);
					TF2Attrib_SetByName(iWeapon, "cloak consume rate decreased", 0.01);
					TF2Attrib_RemoveByName(iWeapon, "cloak_consume_on_feign_death_activate"); // test
					return;			
				}
			}
		}
	}
}

// giant inventory
void GiveGiantInventory(int client ,int botvariant)
{
	if( IsFakeClient(client) )
		return;

	TFClassType TFClass = TF2_GetPlayerClass(client);
	int iWeapon;
	
	switch( TFClass )
	{
		case TFClass_Scout:
		{
			switch( botvariant )
			{
				case 0: // giant scout
				{
					iWeapon = SpawnWeapon( client, "tf_weapon_scattergun", 13, 1, 6, false ); // client, classname, item index, level, quality, Is Wearable?
					TF2Attrib_SetByName(iWeapon, "hidden maxhealth non buffed", 1475.0);
					TF2Attrib_SetByName(iWeapon, "damage force reduction", 0.7);
					TF2Attrib_SetByName(iWeapon, "airblast vulnerability multiplier", 0.7);
					TF2Attrib_SetByName(iWeapon, "override footstep sound set", 5.0);
					return;
				}
				case 1: // super scout
				{
					iWeapon = SpawnWeapon( client, "tf_weapon_bat_fish", 221, 1, 6, false );
					TF2Attrib_SetByName(iWeapon, "hidden maxhealth non buffed", 1075.0);
					TF2Attrib_SetByName(iWeapon, "move speed bonus", 2.0);
					TF2Attrib_SetByName(iWeapon, "damage force reduction", 0.7);
					TF2Attrib_SetByName(iWeapon, "airblast vulnerability multiplier", 0.7);
					TF2Attrib_SetByName(iWeapon, "override footstep sound set", 5.0);
					return;				
				}
			}	
		}
		case TFClass_Soldier:
		{
			switch( botvariant )
			{
				case 0: // giant soldier
				{
					iWeapon = SpawnWeapon( client, "tf_weapon_rocketlauncher", 18, 1, 6, false );
					TF2Attrib_SetByName(iWeapon, "hidden maxhealth non buffed", 3600.0);
					TF2Attrib_SetByName(iWeapon, "move speed bonus", 0.5);
					TF2Attrib_SetByName(iWeapon, "damage force reduction", 0.4);
					TF2Attrib_SetByName(iWeapon, "airblast vulnerability multiplier", 0.4);
					TF2Attrib_SetByName(iWeapon, "override footstep sound set", 3.0);
					return;
				}
				case 1: // Giant Charged Soldier
				{
					iWeapon = SpawnWeapon( client, "tf_weapon_rocketlauncher", 513, 1, 6, false );
					TF2Attrib_SetByName(iWeapon, "hidden maxhealth non buffed", 3600.0);
					TF2Attrib_SetByName(iWeapon, "move speed bonus", 0.5);
					TF2Attrib_SetByName(iWeapon, "damage force reduction", 0.4);
					TF2Attrib_SetByName(iWeapon, "airblast vulnerability multiplier", 0.4);
					TF2Attrib_SetByName(iWeapon, "override footstep sound set", 3.0);
					TF2Attrib_SetByName(iWeapon, "faster reload rate", 0.2);
					TF2Attrib_SetByName(iWeapon, "fire rate bonus", 2.0);
					TF2Attrib_SetByName(iWeapon, "Projectile speed increased", 0.5);
					return;			
				}
				case 2: // Giant Rapid Fire Soldier
				{
					iWeapon = SpawnWeapon( client, "tf_weapon_rocketlauncher", 18, 1, 6, false );
					TF2Attrib_SetByName(client, "hidden maxhealth non buffed", 3600.0);
					TF2Attrib_SetByName(client, "move speed bonus", 0.5);
					TF2Attrib_SetByName(client, "damage force reduction", 0.4);
					TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.4);
					TF2Attrib_SetByName(client, "override footstep sound set", 3.0);
					TF2Attrib_SetByName(iWeapon, "faster reload rate", -0.8);
					TF2Attrib_SetByName(iWeapon, "fire rate bonus", 0.5);
					TF2Attrib_SetByName(iWeapon, "Projectile speed increased", 0.65);
					return;
				}
				case 3: // Giant Burst Fire Soldier
				{
					iWeapon = SpawnWeapon( client, "tf_weapon_rocketlauncher", 18, 1, 6, false );
					TF2Attrib_SetByName(client, "hidden maxhealth non buffed", 3600.0);
					TF2Attrib_SetByName(client, "move speed bonus", 0.5);
					TF2Attrib_SetByName(client, "damage force reduction", 0.4);
					TF2Attrib_SetByName(client, "airblast vulnerability multiplier", 0.4);
					TF2Attrib_SetByName(client, "override footstep sound set", 3.0);
					TF2Attrib_SetByName(iWeapon, "faster reload rate", 0.6);
					TF2Attrib_SetByName(iWeapon, "fire rate bonus", 0.1);
					TF2Attrib_SetByName(iWeapon, "Projectile speed increased", 0.65);
					TF2Attrib_SetByName(iWeapon, "clip size upgrade atomic", 5.0);
					return;
				}
			}	
		}
		case TFClass_Pyro:
		{
			switch( botvariant )
			{
				case 0: // giant pyro
				{
					iWeapon = SpawnWeapon( client, "tf_weapon_flamethrower", 21, 1, 6, false );
					TF2Attrib_SetByName(iWeapon, "hidden maxhealth non buffed", 2825.0);
					TF2Attrib_SetByName(iWeapon, "move speed bonus", 0.5);
					TF2Attrib_SetByName(iWeapon, "damage force reduction", 0.6);
					TF2Attrib_SetByName(iWeapon, "airblast vulnerability multiplier", 0.6);
					TF2Attrib_SetByName(iWeapon, "override footstep sound set", 6.0);
					return;
				}
				case 1: // Giant Airblast Pyro
				{
					iWeapon = SpawnWeapon( client, "tf_weapon_flamethrower", 215, 1, 6, false );
					TF2Attrib_SetByName(iWeapon, "hidden maxhealth non buffed", 2825.0);
					TF2Attrib_SetByName(iWeapon, "move speed bonus", 0.5);
					TF2Attrib_SetByName(iWeapon, "damage force reduction", 0.6);
					TF2Attrib_SetByName(iWeapon, "airblast vulnerability multiplier", 0.6);
					TF2Attrib_SetByName(iWeapon, "override footstep sound set", 6.0);
					TF2Attrib_SetByName(iWeapon, "damage bonus", 0.05);
					TF2Attrib_SetByName(iWeapon, "airblast pushback scale", 5.0);
					return;			
				}
			}			
		}
		case TFClass_DemoMan:
		{
			switch( botvariant )
			{
				case 0: // giant rapid fire demoman
				{
					iWeapon = SpawnWeapon( client, "tf_weapon_grenadelauncher", 19, 1, 6, false );
					TF2Attrib_SetByName(iWeapon, "hidden maxhealth non buffed", 3125.0);
					TF2Attrib_SetByName(iWeapon, "move speed bonus", 0.5);
					TF2Attrib_SetByName(iWeapon, "damage force reduction", 0.5);
					TF2Attrib_SetByName(iWeapon, "airblast vulnerability multiplier", 0.5);
					TF2Attrib_SetByName(iWeapon, "override footstep sound set", 4.0);
					TF2Attrib_SetByName(iWeapon, "faster reload rate", -0.4);
					TF2Attrib_SetByName(iWeapon, "fire rate bonus", 0.75);
					return;
				}
				case 1: // giant rapid fire demoman
				{
					iWeapon = SpawnWeapon( client, "tf_weapon_grenadelauncher", 19, 1, 6, false );
					TF2Attrib_SetByName(iWeapon, "hidden maxhealth non buffed", 2825.0);
					TF2Attrib_SetByName(iWeapon, "move speed bonus", 0.5);
					TF2Attrib_SetByName(iWeapon, "damage force reduction", 0.5);
					TF2Attrib_SetByName(iWeapon, "airblast vulnerability multiplier", 0.5);
					TF2Attrib_SetByName(iWeapon, "override footstep sound set", 4.0);
					TF2Attrib_SetByName(iWeapon, "fire rate bonus", 0.5);
					return;			
				}
			}			
		}
		case TFClass_Heavy:
		{
			switch( botvariant )
			{
				case 0: // giant heavy
				{
					iWeapon = SpawnWeapon( client, "tf_weapon_minigun", 15, 1, 6, false );
					TF2Attrib_SetByName(iWeapon, "hidden maxhealth non buffed", 4700.0);
					TF2Attrib_SetByName(iWeapon, "move speed bonus", 0.5);
					TF2Attrib_SetByName(iWeapon, "damage force reduction", 0.3);
					TF2Attrib_SetByName(iWeapon, "airblast vulnerability multiplier", 0.3);
					TF2Attrib_SetByName(iWeapon, "override footstep sound set", 2.0);
					TF2Attrib_SetByName(iWeapon, "damage bonus", 1.5);
					return;
				}
				case 1: // Giant Deflector Heavy
				{
					iWeapon = SpawnWeapon( client, "tf_weapon_minigun", 850, 1, 6, false );
					TF2Attrib_SetByName(iWeapon, "hidden maxhealth non buffed", 4700.0);
					TF2Attrib_SetByName(iWeapon, "move speed bonus", 0.5);
					TF2Attrib_SetByName(iWeapon, "damage force reduction", 0.3);
					TF2Attrib_SetByName(iWeapon, "airblast vulnerability multiplier", 0.3);
					TF2Attrib_SetByName(iWeapon, "override footstep sound set", 2.0);
					TF2Attrib_SetByName(iWeapon, "damage bonus", 1.5);
					TF2Attrib_SetByName(iWeapon, "attack projectiles", 1.0);
					return;			
				}
			}		
		}
/* 		case TFClass_Engineer:
		{
			switch( botvariant )
			{
				case -1: // own giant engineer
				{

				}
			}		
		} */
		case TFClass_Medic:
		{
			switch( botvariant )
			{
				case 0: // giant medic
				{
					SpawnWeapon( client, "tf_weapon_syringegun_medic", 17, 1, 6, false );
					iWeapon = SpawnWeapon( client, "tf_weapon_medigun", 411, 1, 6, false );
					TF2Attrib_SetByName(iWeapon, "hidden maxhealth non buffed", 4350.0);
					TF2Attrib_SetByName(iWeapon, "move speed bonus", 0.5);
					TF2Attrib_SetByName(iWeapon, "damage force reduction", 0.6);
					TF2Attrib_SetByName(iWeapon, "airblast vulnerability multiplier", 0.6);
					TF2Attrib_SetByName(iWeapon, "heal rate bonus", 200.0);
					return;
				}
				case 1: // giant Kritzkrieg medic
				{
					SpawnWeapon( client, "tf_weapon_syringegun_medic", 17, 1, 6, false );
					iWeapon = SpawnWeapon( client, "tf_weapon_medigun", 35, 1, 6, false );
					TF2Attrib_SetByName(iWeapon, "hidden maxhealth non buffed", 4350.0);
					TF2Attrib_SetByName(iWeapon, "move speed bonus", 0.5);
					TF2Attrib_SetByName(iWeapon, "damage force reduction", 0.6);
					TF2Attrib_SetByName(iWeapon, "airblast vulnerability multiplier", 0.6);
					TF2Attrib_SetByName(iWeapon, "ubercharge rate bonus", 2.0);
					TF2Attrib_SetByName(iWeapon, "uber duration bonus", 9.0);
					return;			
				}
			}		
		}
/* 		case TFClass_Sniper:
		{
			switch( botvariant )
			{
				case 0: // own giant sniper
				{

				}
			}
		}
		case TFClass_Spy:
		{
			switch( botvariant )
			{
				case 0: // own giant spy
				{

				}
			}
		} */
	}
}

// returns the variant name
char GetNormalVariantName(TFClassType TFClass, int botvariant)
{
	char strBotName[128]
	
	switch( TFClass )
	{
		case TFClass_Scout:
		{
			switch( botvariant )
			{
				case -1: strcopy( strBotName, 128, "Your own Scout" );
				case 0: strcopy( strBotName, 128, "Standard Scout" );
				case 1: strcopy( strBotName, 128, "Bat Scout" );
				case 2: strcopy( strBotName, 128, "Bonk Scout" );
				case 3: strcopy( strBotName, 128, "Minor League Scout" );
				case 4: strcopy( strBotName, 128, "Hyper League Scout" );
				case 5: strcopy( strBotName, 128, "Force-A-Nature Scout" );
				case 6: strcopy( strBotName, 128, "Shortstop Scout" );
				default: strcopy( strBotName, 128, "Undefined" );
			}
		}
		case TFClass_Soldier:
		{
			switch( botvariant )
			{
				case -1: strcopy( strBotName, 128, "Your own Soldier" );
				case 0: strcopy( strBotName, 128, "Standard Soldier" );
				case 1: strcopy( strBotName, 128, "Direct Hit Soldier" );
				case 2: strcopy( strBotName, 128, "Extended Buff Soldier" );
				case 3: strcopy( strBotName, 128, "Extended Battalions Soldier" );
				case 4: strcopy( strBotName, 128, "Extended Concheror Soldier" );
				case 5: strcopy( strBotName, 128, "Blast Soldier" );
				case 6: strcopy( strBotName, 128, "Black Box Soldier" );
				default: strcopy( strBotName, 128, "Undefined" );
			}			
		}
		case TFClass_Pyro:
		{
			switch( botvariant )
			{
				case -1: strcopy( strBotName, 128, "Your own Pyro" );
				case 0: strcopy( strBotName, 128, "Standard Pyro" );
				case 1: strcopy( strBotName, 128, "Flare Pyro" );
				case 2: strcopy( strBotName, 128, "Pyro Pusher" );
				case 3: strcopy( strBotName, 128, "Fast Scorch Shot" );
				default: strcopy( strBotName, 128, "Undefined" );
			}		
		}
		case TFClass_DemoMan:
		{
			switch( botvariant )
			{
				case -1: strcopy( strBotName, 128, "Your own Demoman" );
				case 0: strcopy( strBotName, 128, "Standard Demoman" );
				case 1: strcopy( strBotName, 128, "Burst Fire Demoman" );
				case 2: strcopy( strBotName, 128, "Demoknight" );
				case 3: strcopy( strBotName, 128, "Demo Samurai" );
				default: strcopy( strBotName, 128, "Undefined" );
			}		
		}
		case TFClass_Heavy:
		{
			switch( botvariant )
			{
				case -1: strcopy( strBotName, 128, "Your own Heavy" );
				case 0: strcopy( strBotName, 128, "Standard Heavy" );
				case 1: strcopy( strBotName, 128, "Heavyweight Champ" );
				case 2: strcopy( strBotName, 128, "Heater Heavy" );
				case 3: strcopy( strBotName, 128, "Shotgun Heavy" );
				case 4: strcopy( strBotName, 128, "Steel Gauntlet Pusher" );
				case 5: strcopy( strBotName, 128, "Stun Heavy" );
				default: strcopy( strBotName, 128, "Undefined" );
			}		
		}
		case TFClass_Engineer:
		{
			switch( botvariant )
			{
				case -1: strcopy( strBotName, 128, "Your own Engineer" );
				case 0: strcopy( strBotName, 128, "Standard Engineer" );
				case 1: strcopy( strBotName, 128, "Standard Engineer" );
				case 2: strcopy( strBotName, 128, "Battle Engineer" );
				case 3: strcopy( strBotName, 128, "Battle Engineer" );
				default: strcopy( strBotName, 128, "Undefined" );
			}			
		}
		case TFClass_Medic:
		{
			switch( botvariant )
			{
				case -1: strcopy( strBotName, 128, "Your own Medic" );
				case 0: strcopy( strBotName, 128, "Uber Medic" );
				case 1: strcopy( strBotName, 128, "Kritzkrieg Medic" );
				case 2: strcopy( strBotName, 128, "Mega Heal Medic" );
				case 3: strcopy( strBotName, 128, "Shield Medic" );
				default: strcopy( strBotName, 128, "Undefined" );
			}			
		}
		case TFClass_Sniper:
		{
			switch( botvariant )
			{
				case -1: strcopy( strBotName, 128, "Your own Sniper" );
				case 0: strcopy( strBotName, 128, "Standard Sniper" );
				case 1: strcopy( strBotName, 128, "Bowman" );
				case 2: strcopy( strBotName, 128, "Sydney Sniper" );
				default: strcopy( strBotName, 128, "Undefined" );
			}
		}
		case TFClass_Spy:
		{
			switch( botvariant )
			{
				case -1: strcopy( strBotName, 128, "Your own Spy" );
				case 0: strcopy( strBotName, 128, "Standard Spy" );
				case 1: strcopy( strBotName, 128, "Dead Ringer Spy" );
				case 2: strcopy( strBotName, 128, "Gentle Spy" );
				case 3: strcopy( strBotName, 128, "Ninja Spy" );
				default: strcopy( strBotName, 128, "Undefined" );
			}
		}
	}
	return strBotName;
}

char GetGiantVariantName(TFClassType TFClass, int botvariant)
{
	char strBotName[128]
	
	switch( TFClass )
	{
		case TFClass_Scout:
		{
			switch( botvariant )
			{
				case -1: strcopy( strBotName, 128, "Your own Giant Scout" );
				case 0: strcopy( strBotName, 128, "Giant Scout" );
				case 1: strcopy( strBotName, 128, "Super Scout" );
				default: strcopy( strBotName, 128, "Undefined" );
			}
		}
		case TFClass_Soldier:
		{
			switch( botvariant )
			{
				case -1: strcopy( strBotName, 128, "Your own Giant Soldier" );
				case 0: strcopy( strBotName, 128, "Giant Soldier" );
				case 1: strcopy( strBotName, 128, "Giant Charged Soldier" );
				case 2: strcopy( strBotName, 128, "Giant Rapid Fire Soldier" );
				case 3: strcopy( strBotName, 128, "Giant Burst Fire Soldier" );
				default: strcopy( strBotName, 128, "Undefined" );
			}			
		}
		case TFClass_Pyro:
		{
			switch( botvariant )
			{
				case -1: strcopy( strBotName, 128, "Your own Giant Pyro" );
				case 0: strcopy( strBotName, 128, "Giant Pyro" );
				case 1: strcopy( strBotName, 128, "Giant Airblast Pyro" );
				default: strcopy( strBotName, 128, "Undefined" );
			}		
		}
		case TFClass_DemoMan:
		{
			switch( botvariant )
			{
				case -1: strcopy( strBotName, 128, "Your own Giant Demoman" );
				case 0: strcopy( strBotName, 128, "Giant Rapid Fire Demoman" );
				case 1: strcopy( strBotName, 128, "Giant Rapid Fire Demoman" );
				default: strcopy( strBotName, 128, "Undefined" );
			}		
		}
		case TFClass_Heavy:
		{
			switch( botvariant )
			{
				case -1: strcopy( strBotName, 128, "Your own Giant Heavy" );
				case 0: strcopy( strBotName, 128, "Giant Heavy" );
				case 1: strcopy( strBotName, 128, "Giant Deflector Heavy" );
				default: strcopy( strBotName, 128, "Undefined" );
			}		
		}
		case TFClass_Engineer:
		{
			switch( botvariant )
			{
				case -1: strcopy( strBotName, 128, "Your own Giant Engineer" );
				case 0: strcopy( strBotName, 128, "Standard Engineer" );
				case 1: strcopy( strBotName, 128, "Batsaber Scout" );
				default: strcopy( strBotName, 128, "Undefined" );
			}			
		}
		case TFClass_Medic:
		{
			switch( botvariant )
			{
				case -1: strcopy( strBotName, 128, "Your own Giant Medic" );
				case 0: strcopy( strBotName, 128, "Giant Medic" );
				case 1: strcopy( strBotName, 128, "Giant Kritzkrieg Medic" );
				default: strcopy( strBotName, 128, "Undefined" );
			}			
		}
		case TFClass_Sniper:
		{
			switch( botvariant )
			{
				case -1: strcopy( strBotName, 128, "Your own Giant Sniper" );
				case 0: strcopy( strBotName, 128, "Standard Sniper" );
				default: strcopy( strBotName, 128, "Undefined" );
			}
		}
		case TFClass_Spy:
		{
			switch( botvariant )
			{
				case -1: strcopy( strBotName, 128, "Your own Giant Spy" );
				case 0: strcopy( strBotName, 128, "Standard Spy" );
				default: strcopy( strBotName, 128, "Undefined" );
			}
		}
	}
	
	return strBotName;
}

// add attributes to own variants
void SetOwnAttributes(int client , bool bGiant)
{
	if( IsFakeClient(client) )
		return;

	TFClassType TFClass = TF2_GetPlayerClass(client);
	int iWeapon;
	
	if( bGiant )
	{
		switch( TFClass )
		{
			case TFClass_Scout:
			{
				iWeapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
				TF2Attrib_SetByName(iWeapon, "hidden maxhealth non buffed", 1475.0);
				TF2Attrib_SetByName(iWeapon, "damage force reduction", 0.7);
				TF2Attrib_SetByName(iWeapon, "airblast vulnerability multiplier", 0.7);
				TF2Attrib_SetByName(iWeapon, "override footstep sound set", 5.0);
				return;
			}
			case TFClass_Soldier:
			{
				iWeapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
				TF2Attrib_SetByName(iWeapon, "hidden maxhealth non buffed", 3600.0);
				TF2Attrib_SetByName(iWeapon, "move speed bonus", 0.5);
				TF2Attrib_SetByName(iWeapon, "damage force reduction", 0.4);
				TF2Attrib_SetByName(iWeapon, "airblast vulnerability multiplier", 0.4);
				TF2Attrib_SetByName(iWeapon, "override footstep sound set", 3.0);
				return;
			}
			case TFClass_Pyro:
			{
				iWeapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
				TF2Attrib_SetByName(iWeapon, "hidden maxhealth non buffed", 2825.0);
				TF2Attrib_SetByName(iWeapon, "move speed bonus", 0.5);
				TF2Attrib_SetByName(iWeapon, "damage force reduction", 0.6);
				TF2Attrib_SetByName(iWeapon, "airblast vulnerability multiplier", 0.6);
				TF2Attrib_SetByName(iWeapon, "override footstep sound set", 6.0);
				return;
			}
			case TFClass_DemoMan:
			{
				iWeapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
				TF2Attrib_SetByName(iWeapon, "hidden maxhealth non buffed", 3125.0);
				TF2Attrib_SetByName(iWeapon, "move speed bonus", 0.5);
				TF2Attrib_SetByName(iWeapon, "damage force reduction", 0.5);
				TF2Attrib_SetByName(iWeapon, "airblast vulnerability multiplier", 0.5);
				TF2Attrib_SetByName(iWeapon, "override footstep sound set", 4.0);
				return;
			}
			case TFClass_Heavy:
			{
				iWeapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
				TF2Attrib_SetByName(iWeapon, "hidden maxhealth non buffed", 4700.0);
				TF2Attrib_SetByName(iWeapon, "move speed bonus", 0.5);
				TF2Attrib_SetByName(iWeapon, "damage force reduction", 0.3);
				TF2Attrib_SetByName(iWeapon, "airblast vulnerability multiplier", 0.3);
				TF2Attrib_SetByName(iWeapon, "override footstep sound set", 2.0);
				return;
			}
			case TFClass_Engineer:
			{
				iWeapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
				TF2Attrib_SetByName(iWeapon, "hidden maxhealth non buffed", 1775.0);
				TF2Attrib_SetByName(iWeapon, "move speed bonus", 0.5);
				TF2Attrib_SetByName(iWeapon, "damage force reduction", 0.4);
				TF2Attrib_SetByName(iWeapon, "airblast vulnerability multiplier", 0.4);
				TF2Attrib_SetByName(iWeapon, "override footstep sound set", 4.0);
				TF2Attrib_SetByName(iWeapon, "cannot pick up buildings", 1.0);
				return;
			}
			case TFClass_Medic:
			{
				iWeapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
				TF2Attrib_SetByName(iWeapon, "hidden maxhealth non buffed", 4350.0);
				TF2Attrib_SetByName(iWeapon, "move speed bonus", 0.5);
				TF2Attrib_SetByName(iWeapon, "damage force reduction", 0.6);
				TF2Attrib_SetByName(iWeapon, "airblast vulnerability multiplier", 0.6);
				return;
			}
			case TFClass_Sniper:
			{
				iWeapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
				TF2Attrib_SetByName(iWeapon, "hidden maxhealth non buffed", 1275.0);
				TF2Attrib_SetByName(iWeapon, "move speed bonus", 0.5);
				TF2Attrib_SetByName(iWeapon, "damage force reduction", 0.4);
				TF2Attrib_SetByName(iWeapon, "airblast vulnerability multiplier", 0.4);
				TF2Attrib_SetByName(iWeapon, "override footstep sound set", 4.0);
				return;
			}
			case TFClass_Spy:
			{
				iWeapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
				TF2Attrib_SetByName(iWeapon, "hidden maxhealth non buffed", 1175.0);
				TF2Attrib_SetByName(iWeapon, "move speed bonus", 0.5);
				TF2Attrib_SetByName(iWeapon, "damage force reduction", 0.4);
				TF2Attrib_SetByName(iWeapon, "airblast vulnerability multiplier", 0.4);
				TF2Attrib_SetByName(iWeapon, "override footstep sound set", 4.0);
				return;
			}
		}
	}
	else
	{
		switch( TFClass )
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
				iWeapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
				TF2Attrib_SetByName(iWeapon, "hidden maxhealth non buffed", 375.0);
				TF2Attrib_SetByName(iWeapon, "cannot pick up buildings", 1.0);
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
				TF2Attrib_SetByName(iWeapon, "mult cloak meter regen rate", 4.0); // own spy doesn't have inf cloak
			}
		}
	}
}

void GiveBusterInventory(int client)
{
	if( IsFakeClient(client) )
		return;

	int iWeapon = -1;
	iWeapon = SpawnWeapon( client, "tf_weapon_stickbomb", 307, 1, 6, false );
	TF2Attrib_SetByName(iWeapon, "hidden maxhealth non buffed", 2325.0);
	TF2Attrib_SetByName(iWeapon, "move speed bonus", 1.34);
	TF2Attrib_SetByName(iWeapon, "damage force reduction", 0.5);
	TF2Attrib_SetByName(iWeapon, "airblast vulnerability multiplier", 0.5);
	TF2Attrib_SetByName(iWeapon, "override footstep sound set", 7.0);
	TF2Attrib_SetByName(iWeapon, "cannot be backstabbed", 1.0);
}

// ==== ROBOT TEMPLATE CONFIG FILES ====
void RT_InitArrays()
{
	for(int i = 0;i < MAX_ROBOTS_TEMPLATE;i++)
	{
		for(int y = 1;y < CONST_ROBOT_CLASSES;y++)
		{
			g_BNWeaponClass[i][y] = new ArrayList(ByteCountToCells(MAXLEN_CONFIG_STRING));
			g_BNCharAttrib[i][y] = new ArrayList(ByteCountToCells(MAXLEN_CONFIG_STRING));
			g_BNCharAttribValue[i][y] = new ArrayList();
			g_BGWeaponClass[i][y] = new ArrayList(ByteCountToCells(MAXLEN_CONFIG_STRING));
			g_BGCharAttrib[i][y] = new ArrayList(ByteCountToCells(MAXLEN_CONFIG_STRING));
			g_BGCharAttribValue[i][y] = new ArrayList();
			for(int x = 0;x < MAX_ROBOTS_WEAPONS;x++)
			{
				g_BNWeapAttrib[i][y][x] = new ArrayList(ByteCountToCells(MAXLEN_CONFIG_STRING));
				g_BNWeapAttribValue[i][y][x] = new ArrayList();
				g_BGWeapAttrib[i][y][x] = new ArrayList(ByteCountToCells(MAXLEN_CONFIG_STRING));
				g_BGWeapAttribValue[i][y][x] = new ArrayList();
			}
		}
	}
}

void RT_ClearArrays()
{
	for(int i = 0;i < MAX_ROBOTS_TEMPLATE;i++)
	{
		for(int y = 1;y < CONST_ROBOT_CLASSES;y++)
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
		for(int y = 1;y < CONST_ROBOT_CLASSES;y++)
		{
			g_nBotTemplate[i].numtemplates[y] = 0;
		}
	}
}

// Parse data after reading the config files.
void RT_PostLoad()
{
	char strBits[12][MAXLEN_CONFIG_STRING];
	char strValidAttribs[8][MAXLEN_CONFIG_STRING] = {"alwayscrits", "fullcharge", "infinitecloak", "autodisguise", "alwaysminicrits", "teleporttohint", "nobomb", "noteleexit"};
	int AttribValue[8] = {1,2,4,8,16,32,64,128};
	int iNum, iBits;

	for(int i = 0;i < MAX_ROBOTS_TEMPLATE;i++)
	{
		for(int y = 1;y < CONST_ROBOT_CLASSES;y++)
		{
			if(strlen(g_BNRobotAttribs[i][y]) > 0)
			{
				iBits = 0;
				iNum = ExplodeString(g_BNRobotAttribs[i][y], ",", strBits, sizeof(strBits), sizeof(strBits[]));
				for(int x = 0;x < iNum;x++)
				{
					for(int z = 0;z < sizeof(strValidAttribs);z++)
					{
						if(StrEqual(strBits[x], strValidAttribs[z], false))
						{
							iBits += AttribValue[z];
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
		for(int y = 1;y < CONST_ROBOT_CLASSES;y++)
		{
			if(strlen(g_BGRobotAttribs[i][y]) > 0)
			{
				iBits = 0;
				iNum = ExplodeString(g_BGRobotAttribs[i][y], ",", strBits, sizeof(strBits), sizeof(strBits[]));
				for(int x = 0;x < iNum;x++)
				{
					for(int z = 0;z < sizeof(strValidAttribs);z++)
					{
						if(StrEqual(strBits[x], strValidAttribs[z], false))
						{
							iBits += AttribValue[z];
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
	BuildPath(Path_SM, g_strConfigFile, sizeof(g_strConfigFile), "configs/bwrr/robots_normal.cfg");
	
	if(!FileExists(g_strConfigFile))
	{
		SetFailState("Failed to load config file %s", g_strConfigFile);
	}
	
	
	KeyValues kv = new KeyValues("RobotTemplate");
	kv.ImportFromFile(g_strConfigFile);
	int iCounter = 0;
	char strClassKey[10][] = {"unknownclass" ,"scout", "sniper", "soldier", "demoman", "medic", "heavy", "pyro", "spy", "engineer"}; // must be the same as TFClassType enum
	
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
		for(int j = 1;j < sizeof(strClassKey);j++)
		{
			kv.GetSectionName(buffer, sizeof(buffer));
			if(kv.JumpToKey(strClassKey[j]))
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
						
						if(kv.JumpToKey("playerattributes"))
						{
							kv.GetSectionName(buffer, sizeof(buffer));
							if(kv.GotoFirstSubKey(false))
							{
								do
								{ // Store Player Attributes
									kv.GetSectionName(buffer, sizeof(buffer)); // Get Attribute Name
									g_BNCharAttrib[iCounter][j].PushString(buffer); // Attribute Name
									g_BNCharAttribValue[iCounter][j].Push(kv.GetFloat("")); // Attribute Value
								} while(kv.GotoNextKey(false))
								kv.GoBack();
							}
							kv.GoBack();
						}
						
						char strWeaponsKey[MAX_ROBOTS_WEAPONS][] = {"primaryweapon", "secondaryweapon", "meleeweapon", "pda1weapon", "pda2weapon", "pda3weapon"};
						
						for(int i = 0;i < sizeof(strWeaponsKey);i++) // Read Weapons
						{
							if(kv.JumpToKey(strWeaponsKey[i]))
							{
								kv.GetString("classname", buffer, sizeof(buffer), "");
								g_BNWeaponClass[iCounter][j].SetString(i, buffer); // Store Weapon Classname
								g_BNWeaponIndex[iCounter][j][i] = kv.GetNum("index"); // Store Weapon Definition Index
								
								if(kv.GotoFirstSubKey())
								{
									if(kv.GotoFirstSubKey(false)) // Read Weapon's Attributes
									{
										do
										{
											kv.GetSectionName(buffer, sizeof(buffer));
											g_BNWeapAttrib[iCounter][j][i].PushString(buffer); // Store Attribute Name
											g_BNWeapAttribValue[iCounter][j][i].Push(kv.GetFloat("")); // Store Attribute Value
										} while(kv.GotoNextKey(false))
										kv.GoBack();
									}
									kv.GoBack();
								}
								kv.GoBack();
							}			
						}
						iCounter++;
					} while(kv.GotoNextKey())
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
	BuildPath(Path_SM, g_strConfigFile, sizeof(g_strConfigFile), "configs/bwrr/robots_giant.cfg");
	
	if(!FileExists(g_strConfigFile))
	{
		SetFailState("Failed to load config file %s", g_strConfigFile);
	}
	
	
	KeyValues kv = new KeyValues("RobotTemplate");
	kv.ImportFromFile(g_strConfigFile);
	int iCounter = 0;
	char strClassKey[10][] = {"unknownclass" ,"scout", "sniper", "soldier", "demoman", "medic", "heavy", "pyro", "spy", "engineer"}; // must be the same as TFClassType enum
	
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
		for(int j = 1;j < sizeof(strClassKey);j++)
		{
			kv.GetSectionName(buffer, sizeof(buffer));
			if(kv.JumpToKey(strClassKey[j]))
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
						g_BGType[iCounter][j] = kv.GetNum("type", 0);
						
						if(kv.JumpToKey("playerattributes"))
						{
							kv.GetSectionName(buffer, sizeof(buffer));
							if(kv.GotoFirstSubKey(false))
							{
								do
								{ // Store Player Attributes
									kv.GetSectionName(buffer, sizeof(buffer)); // Get Attribute Name
									g_BGCharAttrib[iCounter][j].PushString(buffer); // Attribute Name
									g_BGCharAttribValue[iCounter][j].Push(kv.GetFloat("")); // Attribute Value
								} while(kv.GotoNextKey(false))
								kv.GoBack();
							}
							kv.GoBack();
						}
						
						char strWeaponsKey[MAX_ROBOTS_WEAPONS][] = {"primaryweapon", "secondaryweapon", "meleeweapon", "pda1weapon", "pda2weapon", "pda3weapon"};
						
						for(int i = 0;i < sizeof(strWeaponsKey);i++) // Read Weapons
						{
							if(kv.JumpToKey(strWeaponsKey[i]))
							{
								kv.GetString("classname", buffer, sizeof(buffer), "");
								g_BGWeaponClass[iCounter][j].SetString(i, buffer); // Store Weapon Classname
								g_BGWeaponIndex[iCounter][j][i] = kv.GetNum("index"); // Store Weapon Definition Index
								
								if(kv.GotoFirstSubKey())
								{
									if(kv.GotoFirstSubKey(false)) // Read Weapon's Attributes
									{
										do
										{
											kv.GetSectionName(buffer, sizeof(buffer));
											g_BGWeapAttrib[iCounter][j][i].PushString(buffer); // Store Attribute Name
											g_BGWeapAttribValue[iCounter][j][i].Push(kv.GetFloat("")); // Store Attribute Value
										} while(kv.GotoNextKey(false))
										kv.GoBack();
									}
									kv.GoBack();
								}
								kv.GoBack();
							}			
						}
						iCounter++;
					} while(kv.GotoNextKey())
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
	if(bGiant)
	{
		switch( Class )
		{
			case TFClass_Scout: return g_nBotTemplate[TemplateType_Giant].numtemplates[view_as<int>(TFClass_Scout)];
			case TFClass_Sniper: return g_nBotTemplate[TemplateType_Giant].numtemplates[view_as<int>(TFClass_Sniper)];
			case TFClass_Soldier: return g_nBotTemplate[TemplateType_Giant].numtemplates[view_as<int>(TFClass_Soldier)];
			case TFClass_DemoMan: return g_nBotTemplate[TemplateType_Giant].numtemplates[view_as<int>(TFClass_DemoMan)];
			case TFClass_Heavy: return g_nBotTemplate[TemplateType_Giant].numtemplates[view_as<int>(TFClass_Heavy)];
			case TFClass_Pyro: return g_nBotTemplate[TemplateType_Giant].numtemplates[view_as<int>(TFClass_Pyro)];
			case TFClass_Engineer: return g_nBotTemplate[TemplateType_Giant].numtemplates[view_as<int>(TFClass_Engineer)];
			case TFClass_Medic: return g_nBotTemplate[TemplateType_Giant].numtemplates[view_as<int>(TFClass_Medic)];
			case TFClass_Spy: return g_nBotTemplate[TemplateType_Giant].numtemplates[view_as<int>(TFClass_Spy)];
		}
	}
	else
	{
		switch( Class )
		{
			case TFClass_Scout: return g_nBotTemplate[TemplateType_Normal].numtemplates[view_as<int>(TFClass_Scout)];
			case TFClass_Sniper: return g_nBotTemplate[TemplateType_Normal].numtemplates[view_as<int>(TFClass_Sniper)];
			case TFClass_Soldier: return g_nBotTemplate[TemplateType_Normal].numtemplates[view_as<int>(TFClass_Soldier)];
			case TFClass_DemoMan: return g_nBotTemplate[TemplateType_Normal].numtemplates[view_as<int>(TFClass_DemoMan)];
			case TFClass_Heavy: return g_nBotTemplate[TemplateType_Normal].numtemplates[view_as<int>(TFClass_Heavy)];
			case TFClass_Pyro: return g_nBotTemplate[TemplateType_Normal].numtemplates[view_as<int>(TFClass_Pyro)];
			case TFClass_Engineer: return g_nBotTemplate[TemplateType_Normal].numtemplates[view_as<int>(TFClass_Engineer)];
			case TFClass_Medic: return g_nBotTemplate[TemplateType_Normal].numtemplates[view_as<int>(TFClass_Medic)];
			case TFClass_Spy: return g_nBotTemplate[TemplateType_Normal].numtemplates[view_as<int>(TFClass_Spy)];
		}		
	}
	
	return 0;
}