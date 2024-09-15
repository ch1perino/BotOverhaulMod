#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

float flag_pos[3];
float flag_pos2[3];
int CorrectMap = 0;

public Plugin myinfo=
{
	name= "PvP Bots",
	author= "EfeDursun125 / Showin",
	description= "Support For Player Destruction! (Based on MvM Bots Plugin by tRololo312312)",
	version= "1.4",
	url= "http://steamcommunity.com/profiles/76561198039186809"
}

float moveForward(float vel[3],float MaxSpeed)
{
	vel[0] = MaxSpeed;
	return vel;
}

public void OnPluginStart()
{
	HookEvent("teamplay_round_start", RoundStarted);
	HookEvent("arena_round_start", RoundStarted);
}

public void OnMapStart()
{
	MapCheck();
}

void MapCheck()
{
	char currentMap[PLATFORM_MAX_PATH];
	GetCurrentMap(currentMap, sizeof(currentMap));
	
	// Are we playing a player destruction map?
	if ( StrContains( currentMap, "pd_" , false) != -1 || StrContains( currentMap, "arena_" , false) != -1)
	{
		CorrectMap = 1;
		CreateTimer(3.0, MoveTimer,_,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

	}
	else
	{		
		CorrectMap = 0;
		
	}
}

public Action RoundStarted(Handle event , const char[] name , bool dontBroadcast)
{
	if(CorrectMap == 1)
	{
		CreateTimer(0.1, LoadStuff);
		CreateTimer(0.1, LoadStuff2);
	}
}

public Action LoadStuff(Handle timer, any userid)
{
	int teamflags = CreateEntityByName("item_teamflag");
	if(IsValidEntity(teamflags))
	{
		DispatchKeyValue(teamflags, "targetname", "redbotflag");
		DispatchKeyValue(teamflags, "trail_effect", "0");
		DispatchKeyValue(teamflags, "ReturnTime", "1");
		DispatchKeyValue(teamflags, "flag_model", "models/empty.mdl");
		DispatchSpawn(teamflags);
		SetEntProp(teamflags, Prop_Send, "m_iTeamNum", 3);
	}
	CreateTimer(1.0, LoadStuff3);
}

public Action LoadStuff2(Handle timer, any userid)
{
	int teamflags = CreateEntityByName("item_teamflag");
	if(IsValidEntity(teamflags))
	{
		DispatchKeyValue(teamflags, "targetname", "bluebotflag");
		DispatchKeyValue(teamflags, "trail_effect", "0");
		DispatchKeyValue(teamflags, "ReturnTime", "1");
		DispatchKeyValue(teamflags, "flag_model", "models/empty.mdl");
		DispatchSpawn(teamflags);
		SetEntProp(teamflags, Prop_Send, "m_iTeamNum", 2);
	}
	CreateTimer(1.0, LoadStuff3);
}

public Action LoadStuff3(Handle timer)
{
	//Changed to one of the Golden Rules(1.1)
	char name[] = "redbotflag";
	char class[] = "item_teamflag";
	char name2[] = "bluebotflag";
	char class2[] = "item_teamflag";
	int ent = FindEntityByTargetname(name, class);
	int ent2 = FindEntityByTargetname(name2, class2);
	if(ent != -1)
	{
		SDKHook(ent, SDKHook_StartTouch, OnFlagTouch );
		SDKHook(ent, SDKHook_Touch, OnFlagTouch );
	}
	if(ent2 != -1)
	{
		SDKHook(ent2, SDKHook_StartTouch, OnFlagTouch );
		SDKHook(ent2, SDKHook_Touch, OnFlagTouch );
	}
}

public Action OnFlagTouch(int point, int client)
{
	for(client=1;client<=MaxClients;client++)
	{
		if(IsClientInGame(client))
		{
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

//danke Forlix for dis stock :))
stock int FindEntityByTargetname(const char[] targetname, const char[] classname)
{
  char namebuf[32];
  int index = -1;
  namebuf[0] = '\0';
 
  while(strcmp(namebuf, targetname) != 0
    && (index = FindEntityByClassname(index, classname)) != -1)
    GetEntPropString(index, Prop_Data, "m_iName", namebuf, sizeof(namebuf));
 
  return(index);
}

public Action MoveTimer(Handle timer)
{
	for(int client=1;client<=MaxClients;client++)
	{
		if(IsClientInGame(client))
		{
			if(IsPlayerAlive(client))
			{
				int team = GetClientTeam(client);
				char name[] = "redbotflag";
				char class[] = "item_teamflag";
				char name2[] = "bluebotflag";
				char class2[] = "item_teamflag";
				int iEnt = -1;
				int iEnt2 = -1;
				int ent = FindEntityByTargetname(name, class);
				int ent2 = FindEntityByTargetname(name2, class2);
				if(ent != -1)
				{
					if((iEnt = FindEntityByClassname(iEnt, "item_powerup_crit")) != INVALID_ENT_REFERENCE)
					{
						if(IsValidEntity(iEnt))
						{
							float TankLoc[3];
							GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", TankLoc);
							TankLoc[2] += 20.0;
							TeleportEntity(ent, TankLoc, NULL_VECTOR, NULL_VECTOR);
						}
					}
					else if(team == 3)
					{
						GetClientAbsOrigin(client, flag_pos);
						TeleportEntity(ent, flag_pos, NULL_VECTOR, NULL_VECTOR);
					}
				}
				if(ent2 != -1)
				{
					if((iEnt2 = FindEntityByClassname(iEnt2, "item_powerup_crit")) != INVALID_ENT_REFERENCE)
					{
						if(IsValidEntity(iEnt2))
						{
							float TankLoc[3];
							GetEntPropVector(iEnt2, Prop_Send, "m_vecOrigin", TankLoc);
							TankLoc[2] += 20.0;
							TeleportEntity(ent2, TankLoc, NULL_VECTOR, NULL_VECTOR);
						}
					}
					else if(team == 2)
					{
						GetClientAbsOrigin(client, flag_pos2);
						TeleportEntity(ent2, flag_pos2, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
		}
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3])
{
	if(CorrectMap == 1)
	{
		if(IsValidClient(client))
		{
			if(IsFakeClient(client))
			{
				if(IsPlayerAlive(client))
				{
					int CurrentHealth = GetEntProp(client, Prop_Send, "m_iHealth");
					int MaxHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");
					// float camangle[3];
					float clientEyes[3];
					// float targetEyes[3];
					GetClientEyePosition(client, clientEyes);
					
					int iDispenser = -1;
					int iSmallMedkit = -1;
					int iMediumMedkit = -1;
					int iFullMedkit = -1;
					if(CurrentHealth < (MaxHealth / 1.3))
					{
						if((iDispenser = FindEntityByClassname(iDispenser, "obj_dispenser")) != INVALID_ENT_REFERENCE)
						{
							float clientOrigin[3];
							float dispenserOrigin[3];
							GetClientAbsOrigin(client, clientOrigin);
							GetEntPropVector(iDispenser, Prop_Send, "m_vecOrigin", dispenserOrigin);
	
							float dispenserDistance;
							dispenserDistance = GetVectorDistance(clientOrigin, dispenserOrigin);
	
							if(IsPointVisibleTank(clientOrigin, dispenserOrigin) && dispenserDistance > 50.0 && dispenserDistance < 500.0)
							{
								TF2_LookAtBuilding(client, dispenserOrigin, 0.055);
								vel = moveForward(vel,300.0);
							}
						}
						else
						{
							while((iSmallMedkit = FindEntityByClassname(iSmallMedkit, "item_healthkit_small")) != INVALID_ENT_REFERENCE)
							{
								float clientOrigin2[3];
								float smedkitOrigin[3];
								GetClientAbsOrigin(client, clientOrigin2);
								GetEntPropVector(iSmallMedkit, Prop_Send, "m_vecOrigin", smedkitOrigin);
	
								float smedkitDistance;
								smedkitDistance = GetVectorDistance(clientOrigin2, smedkitOrigin);
	
								if(IsPointVisibleTank(clientOrigin2, smedkitOrigin) && smedkitDistance < 500.0)
								{
									TF2_LookAtBuilding(client, smedkitOrigin, 0.055);
									vel = moveForward(vel,300.0);
								}
								else
								{
									while((iMediumMedkit = FindEntityByClassname(iMediumMedkit, "item_healthkit_medium")) != INVALID_ENT_REFERENCE)
									{
										float clientOrigin3[3];
										float mmedkitOrigin[3];
										GetClientAbsOrigin(client, clientOrigin3);
										GetEntPropVector(iMediumMedkit, Prop_Send, "m_vecOrigin", mmedkitOrigin);
	
										float mmedkitDistance;
										mmedkitDistance = GetVectorDistance(clientOrigin3, mmedkitOrigin);
	
										if(IsPointVisibleTank(clientOrigin3, mmedkitOrigin) && mmedkitDistance < 500.0)
										{
												TF2_LookAtBuilding(client, mmedkitOrigin, 0.055);
												vel = moveForward(vel,300.0);
										}
										else
										{
											while((iFullMedkit = FindEntityByClassname(iFullMedkit, "item_healthkit_full")) != INVALID_ENT_REFERENCE)
											{
												float clientOrigin4[3];
												float fmedkitOrigin[3];
												GetClientAbsOrigin(client, clientOrigin4);
												GetEntPropVector(iFullMedkit, Prop_Send, "m_vecOrigin", fmedkitOrigin);
								
												float fmedkitDistance;
												fmedkitDistance = GetVectorDistance(clientOrigin4, fmedkitOrigin);
	
												if(IsPointVisibleTank(clientOrigin4, fmedkitOrigin) && fmedkitDistance < 500.0)
												{
													TF2_LookAtBuilding(client, fmedkitOrigin, 0.055);
													vel = moveForward(vel,300.0);
												}
											}
										}
									}
								}
							}
						}
					}
	
					int iSmallAmmo = -1;
					int iMediumAmmo = -1;
					int iFullAmmo = -1;
					int ammoOffset = FindSendPropInfo("CTFPlayer", "m_iAmmo");
					int size = GetEntData(client, ammoOffset + 4, 4);
					if(size < 13)
					{
						if((iDispenser = FindEntityByClassname(iDispenser, "obj_dispenser")) != INVALID_ENT_REFERENCE)
						{
							float clientOrigin[3];
							float dispenserOrigin[3];
							GetClientAbsOrigin(client, clientOrigin);
							GetEntPropVector(iDispenser, Prop_Send, "m_vecOrigin", dispenserOrigin);
	
							float dispenserDistance;
							dispenserDistance = GetVectorDistance(clientOrigin, dispenserOrigin);
	
							if(IsPointVisibleTank(clientOrigin, dispenserOrigin) && dispenserDistance > 50.0 && dispenserDistance < 500.0)
							{
								TF2_LookAtBuilding(client, dispenserOrigin, 0.055);
								vel = moveForward(vel,300.0);
							}
						}
						else
						{
							while((iSmallAmmo = FindEntityByClassname(iSmallAmmo, " item_ammopack_small")) != INVALID_ENT_REFERENCE)
							{
								float clientOrigin2[3];
								float sammoOrigin[3];
								GetClientAbsOrigin(client, clientOrigin2);
								GetEntPropVector(iSmallAmmo, Prop_Send, "m_vecOrigin", sammoOrigin);
	
								float sammoDistance;
								sammoDistance = GetVectorDistance(clientOrigin2, sammoOrigin);
	
								if(IsPointVisibleTank(clientOrigin2, sammoOrigin) && sammoDistance < 500.0)
								{
									TF2_LookAtBuilding(client, sammoOrigin, 0.055);
									vel = moveForward(vel,300.0);
								}
								else
								{
									while((iMediumAmmo = FindEntityByClassname(iMediumAmmo, "item_ammopack_medium")) != INVALID_ENT_REFERENCE)
									{
										float clientOrigin3[3];
										float mammoOrigin[3];
										GetClientAbsOrigin(client, clientOrigin3);
										GetEntPropVector(iMediumAmmo, Prop_Send, "m_vecOrigin", mammoOrigin);
	
										float mammoDistance;
										mammoDistance = GetVectorDistance(clientOrigin3, mammoOrigin);
	
										if(IsPointVisibleTank(clientOrigin3, mammoOrigin) && mammoDistance < 500.0)
										{
											TF2_LookAtBuilding(client, mammoOrigin, 0.055);
											vel = moveForward(vel,300.0);
										}
										else
										{
											while((iFullAmmo = FindEntityByClassname(iFullAmmo, "item_ammopack_full")) != INVALID_ENT_REFERENCE)
											{
												float clientOrigin4[3];
												float fammoOrigin[3];
												GetClientAbsOrigin(client, clientOrigin4);
												GetEntPropVector(iFullAmmo, Prop_Send, "m_vecOrigin", fammoOrigin);
	
												float fammoDistance;
												fammoDistance = GetVectorDistance(clientOrigin4, fammoOrigin);
	
												if(IsPointVisibleTank(clientOrigin4, fammoOrigin) && fammoDistance < 500.0)
												{
													TF2_LookAtBuilding(client, fammoOrigin, 0.055);
													vel = moveForward(vel,300.0);
												}
											}
										}
									}
								}
							}
						}
					}
	
					// Player Destruction CAPPING!
					int iPDCAP = -1;
					if((iPDCAP = FindEntityByClassname(iPDCAP, "func_capturezone")) != INVALID_ENT_REFERENCE)
					{
						float clientOrigin[3];
						float iPDCAPOrigin[3];
						GetClientAbsOrigin(client, clientOrigin);
						GetEntPropVector(iPDCAP, Prop_Send, "m_vecOrigin", iPDCAPOrigin);
	
						float iPDCAPDistance;
						iPDCAPDistance = GetVectorDistance(clientOrigin, iPDCAPOrigin);
	
						if(IsPointVisibleTank(clientOrigin, iPDCAPOrigin) && iPDCAPDistance > 50.0 && iPDCAPDistance < 700.0)
						{
							TF2_LookAtBuilding(client, iPDCAPOrigin, 0.055);
							vel = moveForward(vel,300.0);
						}
					}
	
					// Player Destruction BOTTLE COLLECTING!
					// Im a dumbass this is the fucking mvm canteens!
					int iPDBOTTLE = -1;
					if((iPDBOTTLE = FindEntityByClassname(iPDBOTTLE, "tf_powerup_bottle")) != INVALID_ENT_REFERENCE)
					{
						float clientOrigin[3];
						float iPDBOTTLEOrigin[3];
						GetClientAbsOrigin(client, clientOrigin);
						GetEntPropVector(iPDBOTTLE, Prop_Send, "m_vecOrigin", iPDBOTTLEOrigin);
	
						float iPDBOTTLEDistance;
						iPDBOTTLEDistance = GetVectorDistance(clientOrigin, iPDBOTTLEOrigin);
	
						if(IsPointVisibleTank(clientOrigin, iPDBOTTLEOrigin) && iPDBOTTLEDistance > 50.0 && iPDBOTTLEDistance < 700.0)
						{
							TF2_LookAtBuilding(client, iPDBOTTLEOrigin, 0.055);
							vel = moveForward(vel,300.0);
						}
					}
				}
			}
		}
	}

	return Plugin_Continue;
}

stock void TF2_LookAtBuilding(int client, float flGoal[3], float flAimSpeed = 0.05) // Smooth Aim From Pelipoika
{
	float flPos[3];
	GetClientEyePosition(client, flPos);

	float flAng[3];
	GetClientEyeAngles(client, flAng);

	float FixBuildingAngle[3];
	FixBuildingAngle[1] += 180.0; // Fix For Aim Building's angle

	// get normalised direction from target to client
	float desired_dir[3];
	MakeVectorFromPoints(flPos, flGoal, desired_dir);
	GetVectorAngles(desired_dir, desired_dir);

	// ease the current direction to the target direction
	flAng[0] += AngleNormalize(desired_dir[0] - flAng[0]) * flAimSpeed;
	flAng[1] += AngleNormalize(desired_dir[1] - flAng[1]) + FixBuildingAngle[1] * flAimSpeed;
	
	TeleportEntity(client, NULL_VECTOR, flAng, NULL_VECTOR);
}

stock float AngleNormalize(float angle)
{
    angle = fmodf(angle, 360.0);
    if (angle > 89) 
    {
        angle -= 360;
    }
    if (angle < -89)
    {
        angle += 360;
    }
    
    return angle;
}

stock float fmodf(float number, float denom)
{
    return number - RoundToFloor(number / denom) * denom;
}

stock void ClampAngle(float fAngles[3])
{
	while(fAngles[0] > 89.0)  fAngles[0]-=360.0;
	while(fAngles[0] < -89.0) fAngles[0]+=360.0;
	while(fAngles[1] > 180.0) fAngles[1]-=360.0;
	while(fAngles[1] <-180.0) fAngles[1]+=360.0;
}

stock bool IsPointVisible(const float start[3], const float end[3])
{
	TR_TraceRayFilter(start, end, MASK_PLAYERSOLID, RayType_EndPoint, TraceEntityFilterStuff);
	return TR_GetFraction() >= 0.9;
}

public bool TraceEntityFilterStuff(int entity, int mask)
{
	return entity > MaxClients;
}

stock bool IsPointVisibleTank(const float start[3], const float end[3])
{
	TR_TraceRayFilter(start, end, MASK_PLAYERSOLID, RayType_EndPoint, TraceEntityFilterStuffTank);
	return TR_GetFraction() >= 0.9;
}

public bool TraceEntityFilterStuffTank(int entity, int mask)
{
	int maxentities = GetMaxEntities();
	return entity > maxentities;
}

stock int GetHealth(int client)
{
	return GetEntProp(client, Prop_Send, "m_iHealth");
}

stock bool IsWeaponSlotActive(int iClient, int iSlot)
{
    return GetPlayerWeaponSlot(iClient, iSlot) == GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
}

bool IsValidClient( int client ) 
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}