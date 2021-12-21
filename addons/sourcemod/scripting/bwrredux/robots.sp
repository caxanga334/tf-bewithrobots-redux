// Robots Templates

#define MAX_ROBOTS (1<<10)

int g_cbindex = 0; // Current robot index
int g_maxrobots = 0; // Number of robots that was registered

enum struct etemplates
{
    char pluginname[64]; // the plugin that will handle this robot
    TFClassType class; // the robot class
    int cost; // resource cost
    int index; // robot list internal index
    int type; // robot type
    int supply; // available count
    float percent; // wave percentage
    int spawns; // How many times this robot has spawned in the current wave
    float lastspawn; // The last time this robot spawned in the current wave
}
etemplates g_eTemplates[MAX_ROBOTS];

void RegisterRobotTemplate(char[] pluginname, TFClassType class, int cost, int index, int type, int supply, float percent)
{
    if(g_cbindex == MAX_ROBOTS)
    {
        ThrowError("Maximum number of robots reached!");
    }

    if(class == TFClass_Unknown)
    {
        ThrowError("Invalid robot class! Plugin: \"%s\" (%i)", pluginname, index);
    }

    strcopy(g_eTemplates[g_cbindex].pluginname, 64, pluginname);
    g_eTemplates[g_cbindex].class = class;
    g_eTemplates[g_cbindex].cost = cost;
    g_eTemplates[g_cbindex].index = index;
    g_eTemplates[g_cbindex].type = type;
    g_eTemplates[g_cbindex].supply = supply;
    g_eTemplates[g_cbindex].percent = percent;

    g_cbindex++;
    g_maxrobots++;
}

/**
 * Resets spawn and lastspawn values for each template
 */
void Robots_ResetWaveData()
{
    for(int i = 0;i < g_maxrobots;i++)
    {
        g_eTemplates[i].spawns = 0;
        g_eTemplates[i].lastspawn = 0.0;
    }
}