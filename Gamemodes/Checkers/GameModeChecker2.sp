#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

public Plugin myinfo = 
{
	name = "Gamemode Checker",
	author = "Showin",
	description = "stuff",
	version = "1.0",
	url = "shrek.com"
}

int MISSION;

public void OnPluginStart()
{
	HookEvent("player_spawn", PlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", PlayerDied, EventHookMode_Post);
	HookEvent("teamplay_round_win", TEAMWIN, EventHookMode_Post);
}

public void OnMapStart()
{
	if (GetConVarInt(FindConVar("sv_bonus_challenge")) == 1)
	{
		if (MISSION != 1)
		{
			MISSION = 1;
		}
	}
	MapCheck();
}

void MapCheck()
{
	char currentMap[PLATFORM_MAX_PATH];
	GetCurrentMap(currentMap, sizeof(currentMap));
	
	if (MISSION == 1)
	{
		ServerCommand("exec MISSION.cfg");
	}
	else
	{
		if ( StrContains( currentMap, "pl_" , false) != -1 )
		{
			ServerCommand("exec Payload.cfg");
		}
		else if ( StrContains( currentMap, "cp_" , false) != -1 )
		{
			ServerCommand("exec ControlPoints.cfg");
		}
		else if ( StrContains( currentMap, "ctf_" , false) != -1 )
		{
			ServerCommand("exec CaptureTheFlag.cfg");
		}
		else if ( StrContains( currentMap, "koth_" , false) != -1 )
		{
			ServerCommand("exec KOTH.cfg");
		}
		else if ( StrContains( currentMap, "mvm_" , false) != -1 )
		{
			ServerCommand("exec MVM.cfg");
		}
		else if ( StrContains( currentMap, "plr_" , false) != -1 )
		{
			ServerCommand("exec PayloadRace.cfg");
		}
		else if ( StrContains( currentMap, "pd_" , false) != -1 )
		{
			ServerCommand("exec PlayerDestruction.cfg");
		}
		else if ( StrContains( currentMap, "rd_" , false) != -1 )
		{
			ServerCommand("exec RobotDestruction.cfg");
		}
		else if ( StrContains( currentMap, "sd_" , false) != -1 )
		{
			ServerCommand("exec SpecialDelivery.cfg");
		}
		else if ( StrContains( currentMap, "arena_" , false) != -1 )
		{
			ServerCommand("exec Arena.cfg");
		}
		else if ( StrContains( currentMap, "koth_lakeside_event" , false) != -1 || StrContains( currentMap, "koth_viaduct_event" , false) != -1)
		{
			ServerCommand("exec HalloweenTruce.cfg");
		}
	}
}

public Action PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (MISSION == 1)
	{
		int playerid = GetClientOfUserId(GetEventInt(event, "userid", 0));
		if (!IsFakeClient(playerid))
		{
			char currentMap[256];
			GetCurrentMap(currentMap, 256);
			ServerCommand("exec missions/%s/mission.cfg", currentMap);
		}
	}
	return Plugin_Continue;
}

public Action PlayerDied(Event event, const char[] name, bool dontBroadcast)
{
	if (MISSION == 1)
	{
		int playerid = GetClientOfUserId(GetEventInt(event, "userid", 0));
		if (!IsFakeClient(playerid))
		{
			if (GetClientTeam(playerid) == 2)
			{
				ServerCommand("wait 66; sv_cheats 1; wait 66; mp_forcewin 3; wait 66; sv_cheats 0");
			}
			else
			{
				ServerCommand("wait 66; sv_cheats 1; wait 66; mp_forcewin 2; wait 66; sv_cheats 0");
			}
		}
	}
	return Plugin_Continue;
}

public Action TEAMWIN(Event event, const char[] name, bool dontBroadcast)
{
	if (MISSION == 1)
	{	
		for(int i=1;i<=MaxClients;i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				if (TF2_IsPlayerInCondition(i, TFCond_CritOnWin))
				{
					CreateTimer(14.0, WinTimer,_, TIMER_FLAG_NO_MAPCHANGE);
					ServerCommand("echo MISSION_COMPLETE");
				}
				else
				{
					CreateTimer(14.0, LoseTimer,_, TIMER_FLAG_NO_MAPCHANGE);
					CreateTimer(7.5, LoseTimerPauling,_, TIMER_FLAG_NO_MAPCHANGE);
					ServerCommand("echo MISSION_FAILED");
				}
			}
		}  
	}
	return Plugin_Continue;
}

public Action WinTimer(Handle timer)
{
	ServerCommand("kickall");
	return Plugin_Continue;
}

public Action LoseTimer(Handle timer)
{
	ServerCommand("wait 66; tf_bot_kick all; wait 66; tf_bot_quota 0; mp_restartgame_immediate 1; snd_restart");
	return Plugin_Continue;
}

public Action LoseTimerPauling(Handle timer)
{
	// This randomly plays a Pauling failure line.
	// I might add one to play automatically for class spawns as well.
	// Maybe class win lines too?
	int rndpauling = GetRandomUInt(0,10);
	switch (rndpauling)
	{
		case 0:
		{
			ServerCommand("wait 66; playgamesound vo/pauling/plng_contract_fail_allclass_02.mp3;");
		}
		case 1:
		{
			ServerCommand("wait 66; playgamesound vo/pauling/plng_contract_fail_allclass_03.mp3;");
		}
		case 3:
		{
			ServerCommand("wait 66; playgamesound vo/pauling/plng_contract_fail_allclass_04.mp3;");
		}
		case 4:
		{
			ServerCommand("wait 66; playgamesound vo/pauling/plng_contract_fail_allclass_05.mp3;");
		}
		case 5:
		{
			ServerCommand("wait 66; playgamesound vo/pauling/plng_contract_fail_allclass_06.mp3;");
		}
		case 6:
		{
			ServerCommand("wait 66; playgamesound vo/pauling/plng_contract_fail_allclass_09.mp3;");
		}
		case 7:
		{
			ServerCommand("wait 66; playgamesound vo/pauling/plng_contract_fail_allclass_10.mp3;");
		}
		case 8:
		{
			ServerCommand("wait 66; playgamesound vo/pauling/plng_contract_fail_allclass_11.mp3;");
		}
		case 9:
		{
			ServerCommand("wait 66; playgamesound vo/pauling/plng_contract_fail_allclass_13.mp3;");
		}
		case 10:
		{
			ServerCommand("wait 66; playgamesound vo/pauling/plng_contract_fail_allclass_14.mp3;");
		}
	}
	return Plugin_Continue;
}

int GetRandomUInt(int min, int max)
{
	return RoundToFloor(GetURandomFloat() * (max - min + 1)) + min;
}

public void OnClientDisconnect(int client) 
{ 
	// ENSURE MISSION MODE IS DISABLED UPON DISCONNECT!
	if (!IsFakeClient(client) && GetConVarInt(FindConVar("sv_bonus_challenge")) == 0)
	{
		MISSION = 0;
		ServerCommand("stripper_cfg_path addons/stripper");
	}
}  