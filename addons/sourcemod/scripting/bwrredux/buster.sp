// sentry buster

char g_TBusterName[MAXLEN_CONFIG_STRING];
int g_TBusterHealth;
int g_TBusterAttribBits;
float g_TBusterScale;
ArrayList g_TBusterCharAttrib;
ArrayList g_TBusterCharAttribValue;

void Buster_InitArrays()
{
	g_TBusterCharAttrib = new ArrayList(ByteCountToCells(MAXLEN_CONFIG_STRING));
	g_TBusterCharAttribValue = new ArrayList();
}

void Buster_ClearArrays()
{
	g_TBusterCharAttrib.Clear();
	g_TBusterCharAttribValue.Clear();
}

void Buster_GetName(char[] name, int size)
{
	strcopy(name, size, g_TBusterName);
}

float Buster_GetScale()
{
	return g_TBusterScale;
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
	
	char buffer[128];
	TF2Attrib_RemoveAll(client);
	// Set Player Attributes
	if(g_TBusterCharAttrib.Length > 0)
	{
		for(int i = 0;i < g_TBusterCharAttrib.Length;i++)
		{
			g_TBusterCharAttrib.GetString(i, buffer, sizeof(buffer));
			TF2Attrib_SetByName(client, buffer, g_TBusterCharAttribValue.Get(i));
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
	kv.GetString("name", g_TBusterName, sizeof(g_TBusterName), "Sentry Buster");
	g_TBusterHealth = kv.GetNum("health", 2500);
	g_TBusterScale = kv.GetFloat("scale", 1.75);
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
	g_TBusterAttribBits = iBits;
	
	if(kv.JumpToKey("playerattributes"))
	{
		kv.GetSectionName(buffer, sizeof(buffer));
		if(kv.GotoFirstSubKey(false))
		{
			do
			{ // Store Player Attributes
				kv.GetSectionName(buffer, sizeof(buffer)); // Get Attribute Name
				g_TBusterCharAttrib.PushString(buffer); // Attribute Name
				g_TBusterCharAttribValue.Push(kv.GetFloat("")); // Attribute Value
			} while(kv.GotoNextKey(false));
			kv.GoBack();
		}
		kv.GoBack();
	}
	
	delete kv;
	return true;
}