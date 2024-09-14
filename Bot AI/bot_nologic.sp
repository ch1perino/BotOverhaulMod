#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

int NoCommand = 0;
int MapHasLogic = 0;

public Plugin myinfo=
{
	name= "No Logic Bots",
	author= "Showin",
	description= "Makes TFBOTS have deathmatch logic when they have no logic at all.",
	version= "1",
}

public void OnMapStart()
{
	MapCheck();
}

void MapCheck()
{
	char currentMap[PLATFORM_MAX_PATH];
	GetCurrentMap(currentMap, sizeof(currentMap));
	
	if ( StrContains( currentMap, "arena_" , false) != -1 || StrContains( currentMap, "cp_" , false) != -1 || StrContains( currentMap, "ctf_" , false) != -1 || StrContains( currentMap, "koth_" , false) != -1 || StrContains( currentMap, "mvm_" , false) != -1 || StrContains( currentMap, "pass_" , false) != -1 || StrContains( currentMap, "pd_" , false) != -1 || StrContains( currentMap, "plr_" , false) != -1 || StrContains( currentMap, "pl_" , false) != -1 || StrContains( currentMap, "rd_" , false) != -1 || StrContains( currentMap, "sd_" , false) != -1 || StrContains( currentMap, "tc_" , false) != -1 || StrContains( currentMap, "tr_" , false) != -1)
	{
		MapHasLogic = 1;
	}
	
	if(NoCommand == 0 && MapHasLogic == 0)
	{
		Commands();
	}
}

stock void Commands()
{
	ServerCommand("wait 350; mp_stalemate_enable 1; mp_timelimit 9999999; mp_restartgame_immediate 1");
	NoCommand = 1;
	CreateTimer(15.0, WaitTimer,_, TIMER_FLAG_NO_MAPCHANGE); 
}

public Action WaitTimer(Handle timer)
{
	NoCommand = 0;
	return Plugin_Continue;
}


