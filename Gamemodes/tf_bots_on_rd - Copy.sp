#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>

float flag_pos[3];
float flag_pos2[3];
float flag_pos3[3];
float flag_pos4[3];

public Plugin myinfo=
{
	name= "Robot Destruction Bots",
	author= "EfeDursun125",
	description= "Allows Bots to play Robot Destruction",
	version= "1.1",
	url= "https://steamcommunity.com/id/EfeDursun91/"
}

Handle AttackTimer;

float moveBackwards(float vel[3],float MaxSpeed)
{
	vel[0] = -MaxSpeed;
	return vel;
}

float moveForward(float vel[3],float MaxSpeed)
{
	vel[0] = MaxSpeed;
	return vel;
}

public void OnPluginStart()
{
	HookEvent("teamplay_round_start", RoundStarted);
}

public void OnMapStart()
{
	char currentMap[PLATFORM_MAX_PATH];
	GetCurrentMap(currentMap, sizeof(currentMap));

	if(StrContains(currentMap, "rd_" , false) != -1)
	{
		CreateTimer(0.1, MoveTimer,_,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(0.1, FindFlag,_,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
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

public Action RoundStarted(Handle event , const char[] name , bool dontBroadcast)
{
	char currentMap[PLATFORM_MAX_PATH];
	GetCurrentMap(currentMap, sizeof(currentMap));

	if(StrContains(currentMap, "rd_" , false) != -1)
	{
		CreateTimer(0.1, LoadStuff);
		CreateTimer(0.1, LoadStuff2);
	}
}

public Action LoadStuff(Handle timer)
{
	char nameblue[] = "bluebotflag";
	char classblue[] = "item_teamflag";
	int ent = FindEntityByTargetname(nameblue, classblue);
	if(ent != -1)
	{
		//Do nothing.
	}
	else
	{
		int teamflags = CreateEntityByName("item_teamflag");
		if(IsValidEntity(teamflags))
		{
			DispatchKeyValue(teamflags, "targetname", "bluebotflag");
			DispatchKeyValue(teamflags, "trail_effect", "0");
			DispatchKeyValue(teamflags, "ReturnTime", "1");
			DispatchKeyValue(teamflags, "flag_model", "models/empty.mdl");
			DispatchSpawn(teamflags);
			SetEntProp(teamflags, Prop_Send, "m_iTeamNum", 3);
		}
	}
}

public Action LoadStuff2(Handle timer)
{
	char namered[] = "redbotflag";
	char classred[] = "item_teamflag";
	int ent = FindEntityByTargetname(namered, classred);
	if(ent != -1)
	{
		//Do nothing.
	}
	else
	{
		int teamflags2 = CreateEntityByName("item_teamflag");
		if(IsValidEntity(teamflags2))
		{
			DispatchKeyValue(teamflags2, "targetname", "redbotflag");
			DispatchKeyValue(teamflags2, "trail_effect", "0");
			DispatchKeyValue(teamflags2, "ReturnTime", "1");
			DispatchKeyValue(teamflags2, "flag_model", "models/empty.mdl");
			DispatchSpawn(teamflags2);
			SetEntProp(teamflags2, Prop_Send, "m_iTeamNum", 2);
		}
	}
}

public Action FindFlag(Handle timer)
{
	int ent = -1;
	while ((ent = FindEntityByClassname(ent, "item_teamflag"))!=INVALID_ENT_REFERENCE)
	{
		SDKHook(ent, SDKHook_StartTouch, OnFlagTouch );
		SDKHook(ent, SDKHook_Touch, OnFlagTouch );
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3])
{
	if(IsValidClient(client))
	{
		if(IsFakeClient(client))
		{
			if(IsPlayerAlive(client))
			{
				char currentMap[PLATFORM_MAX_PATH];
				GetCurrentMap(currentMap, sizeof(currentMap));

				if(StrContains(currentMap, "rd_" , false) != -1)
				{
					TFClassType class3 = TF2_GetPlayerClass(client);
					int CurrentHealth = GetEntProp(client, Prop_Send, "m_iHealth");
					int MaxHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");
					if(CurrentHealth < MaxHealth)
					{
						int healthkit = GetNearestEntity(client, "item_healthkit_*"); 
						
						if(healthkit != -1)
						{
							if(IsValidEntity(healthkit))
							{
								if (GetEntProp(healthkit, Prop_Send, "m_fEffects") != 0)
								{
									return Plugin_Continue;
								}
		
								float clientOrigin[3];
								float healthkitorigin[3];
								GetClientAbsOrigin(client, clientOrigin);
								GetEntPropVector(healthkit, Prop_Send, "m_vecOrigin", healthkitorigin);
								
								clientOrigin[2] += 5.0;
								healthkitorigin[2] += 5.0;
								
								if(IsPointVisible(clientOrigin, healthkitorigin))
								{
									TF2_MoveTo(client, healthkitorigin, vel, angles);
								}
							}
						}
					}
					
					if(class3 == TFClass_Sniper)
					{
						for (int search = 1; search <= MaxClients; search++)
						{
							if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)))
							{
								float clientOrigin[3];
								float searchOrigin[3];
								GetClientAbsOrigin(search, searchOrigin);
								GetClientAbsOrigin(client, clientOrigin);
							
								clientOrigin[2] += 65.0;
								searchOrigin[2] += 65.0;
							
								float chainDistance;
								chainDistance = GetVectorDistance(clientOrigin, searchOrigin);
							
								if(AttackTimer == INVALID_HANDLE)
								{
									AttackTimer = CreateTimer(5.0, ResetAttackTimer);
								}
							
								int PrimID = GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iItemDefinitionIndex");
							
								if(IsPointVisible(clientOrigin, searchOrigin))
								{
									if(IsWeaponSlotActive(client, 2))
									{
										if(GetClientAimTarget(client) > 0)
										{
											buttons |= IN_ATTACK;
										}
										vel = moveForward(vel,300.0);
									}
								
									if(IsWeaponSlotActive(client, 1))
									{
										if(GetClientAimTarget(client) > 0)
										{
											buttons |= IN_ATTACK;
										}
										vel = moveBackwards(vel,300.0);
									}
								
									if(chainDistance < 1000.0 && TF2_IsPlayerInCondition(client, TFCond_Zoomed))
									{
										vel = moveBackwards(vel,300.0);
									}
								
									if(IsWeaponSlotActive(client, 0))
									{
										if(PrimID == 56 || PrimID == 1005 || PrimID == 1092 || PrimID == 1098)
										{
											if(AttackTimer == INVALID_HANDLE)
											{
												buttons &= ~IN_ATTACK;
											}
											else
											{
												if(GetClientAimTarget(client) > 0)
												{
													buttons |= IN_ATTACK;
												}
											}
										}
										else
										{
											if(AttackTimer == INVALID_HANDLE)
											{
												if(TF2_IsPlayerInCondition(client, TFCond_Zoomed))
												{
													buttons |= IN_ATTACK;
												}
												else
												{
													if(GetClientAimTarget(client) > 0)
													{
														buttons |= IN_ATTACK;
													}
													else
													{
														buttons |= IN_ATTACK2;
													}
												}
											}
											else
											{
												if(TF2_IsPlayerInCondition(client, TFCond_Zoomed))
												{
													buttons &= ~IN_ATTACK;
												}
												else
												{
													buttons |= IN_ATTACK2;
												}
											}
										}
									}
								}
								else
								{
									if(IsWeaponSlotActive(client, 0))
									{
										if(PrimID == 56 || PrimID == 1005 || PrimID == 1092)
										{
											buttons |= IN_ATTACK2;
										}
									}
								}
							}
						}
					}
				
					if(class3 == TFClass_Spy && TF2_IsPlayerInCondition(client, TFCond_Disguised) && IsWeaponSlotActive(client, 0))
					{
						if(buttons & IN_ATTACK)
						{
							buttons &= ~IN_ATTACK;
						}
					}
				
					if(class3 == TFClass_Spy && GetHealth(client) > 100.0 && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
					{
						if(buttons & IN_ATTACK2)
						{
							buttons &= ~IN_ATTACK2;
						}
					}
					
					if(class3 == TFClass_Spy && GetHealth(client) < 75.0 && !TF2_IsPlayerInCondition(client, TFCond_Disguised) && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
					{
						buttons |= IN_ATTACK2;
					}
					
					if(class3 == TFClass_Spy && GetHealth(client) < 35.0 && TF2_IsPlayerInCondition(client, TFCond_Disguising) && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
					{
						buttons |= IN_ATTACK2;
					}
					
					if(class3 == TFClass_Spy && !IsWeaponSlotActive(client, 0))
					{
						TF2_RemoveWeaponSlot(client, 0);
					}
					
					if(class3 == TFClass_Spy && IsWeaponSlotActive(client, 2))
					{
						if(GetEntProp(GetPlayerWeaponSlot(client, TFWeaponSlot_Melee), Prop_Send, "m_bReadyToBackstab") && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
						{
							buttons |= IN_ATTACK;
						}
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action MoveTimer(Handle timer)
{
	char namered[] = "redbotflag";
	char classred[] = "item_teamflag";
	char nameblue[] = "bluebotflag";
	char classblue[] = "item_teamflag";
	int redrobot = -1;
	int blurobot = -1;
	if((blurobot = FindEntityByClassname(blurobot, "rd_robot_dispenser")) != INVALID_ENT_REFERENCE && GetTeamNumber(blurobot) == 3)
	{
		GetEntPropVector(blurobot, Prop_Data, "m_vecAbsOrigin", flag_pos);
		int ent = FindEntityByTargetname(nameblue, classblue);
		if(ent != -1)
		{
			TeleportEntity(ent, flag_pos, NULL_VECTOR, NULL_VECTOR);
		}
	}
	else
	{
		for(int client=1;client<=MaxClients;client++)
		{
			if(IsClientInGame(client))
			{
				if(IsPlayerAlive(client))
				{
					int ent = FindEntityByTargetname(nameblue, classblue);
					int team = GetClientTeam(client);
					if(ent != -1)
					{
						if(team == 3)
						{
							int selectedclient;
							do
							{
								selectedclient = GetRandomInt(1, MaxClients);
  							}
							while(!IsClientInGame(selectedclient));
							if(GetClientTeam(selectedclient) == 3)
							{
								GetClientAbsOrigin(selectedclient, flag_pos3);
								flag_pos3[2] += 50.0;
								TeleportEntity(ent, flag_pos3, NULL_VECTOR, NULL_VECTOR);
							}
						}
					}
				}
			}
		}
	}
	if((redrobot = FindEntityByClassname(redrobot, "rd_robot_dispenser")) != INVALID_ENT_REFERENCE && GetTeamNumber(redrobot) == 2)
	{
		GetEntPropVector(redrobot, Prop_Data, "m_vecAbsOrigin", flag_pos2);
		int ent2 = FindEntityByTargetname(namered, classred);
		if(ent2 != -1)
		{
			TeleportEntity(ent2, flag_pos2, NULL_VECTOR, NULL_VECTOR);
		}
	}
	else
	{
		for(int client=1;client<=MaxClients;client++)
		{
			if(IsClientInGame(client))
			{
				if(IsPlayerAlive(client))
				{
					int ent2 = FindEntityByTargetname(namered, classred);
					int team = GetClientTeam(client);
					if(ent2 != -1)
					{
						if(team == 2)
						{
							int selectedclient;
							do
							{
								selectedclient = GetRandomInt(1, MaxClients);
  							}
							while(!IsClientInGame(selectedclient));
							if(GetClientTeam(selectedclient) == 2)
							{
								GetClientAbsOrigin(selectedclient, flag_pos4);
								flag_pos4[2] += 50.0;
								TeleportEntity(ent2, flag_pos4, NULL_VECTOR, NULL_VECTOR);
							}
						}
					}
				}
			}
		}
	}
}

stock int GetTeamNumber(int entity)
{
	return GetEntProp(entity, Prop_Send, "m_iTeamNum");
}

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

public Action ResetAttackTimer(Handle timer)
{
	AttackTimer = INVALID_HANDLE;
}

bool IsValidClient(int client) 
{
	if(!(1 <= client <= MaxClients ) || !IsClientInGame(client)) 
		return false; 
	return true; 
}

stock bool IsWeaponSlotActive(int iClient, int iSlot)
{
    return GetPlayerWeaponSlot(iClient, iSlot) == GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
}

public int GetNearestEntity(int client, char[] classname) // https://forums.alliedmods.net/showthread.php?t=318542
{
    int nearestEntity = -1;
    float clientVecOrigin[3], entityVecOrigin[3];
    
    //Get the distance between the first entity and client
    float distance, nearestDistance = -1.0;
    
    //Find all the entity and compare the distances
    int entity = -1;
    while ((entity = FindEntityByClassname(entity, classname)) != -1)
    {
        GetEntPropVector(entity, Prop_Data, "m_vecOrigin", entityVecOrigin);
        distance = GetVectorDistance(clientVecOrigin, entityVecOrigin);
        
        if (distance < nearestDistance || nearestDistance == -1.0)
        {
            nearestEntity = entity;
            nearestDistance = distance;
        }
    }
    
    return nearestEntity;
}

stock void TF2_MoveTo(int client, float flGoal[3], float fVel[3], float fAng[3]) // Stock By Pelipokia
{
    float flPos[3];
    GetClientAbsOrigin(client, flPos);

    float newmove[3];
    SubtractVectors(flGoal, flPos, newmove);
    
    newmove[1] = -newmove[1];
    
    float sin = Sine(fAng[1] * FLOAT_PI / 180.0);
    float cos = Cosine(fAng[1] * FLOAT_PI / 180.0);                        
    
    fVel[0] = cos * newmove[0] - sin * newmove[1];
    fVel[1] = sin * newmove[0] + cos * newmove[1];
    
    NormalizeVector(fVel, fVel);
    ScaleVector(fVel, 450.0);
}

stock void EyeVectors(int client, float fw[3] = NULL_VECTOR, float right[3] = NULL_VECTOR, float up[3] = NULL_VECTOR)
{
	GetAngleVectors(GetEyeAngles(client), fw, right, up);
}

stock float[] GetAbsOrigin(int client)
{
	if(client <= 0)
		return NULL_VECTOR;

	float v[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", v);
	return v;
}

stock float[] GetEyeAngles(int client)
{
	if(client <= 0)
		return NULL_VECTOR;

	float v[3];
	GetClientEyeAngles(client, v);
	return v;
}

stock bool IsPointVisible(const float start[3], const float end[3])
{
	TR_TraceRayFilter(start, end, MASK_SOLID_BRUSHONLY, RayType_EndPoint, TraceEntityFilterStuff);
	return TR_GetFraction() >= 0.99;
}

stock bool IsPointVisibleTank(const float start[3], const float end[3])
{
	TR_TraceRayFilter(start, end, MASK_SOLID_BRUSHONLY, RayType_EndPoint, TraceEntityFilterStuffTank);
	return TR_GetFraction() >= 0.99;
}

public bool TraceEntityFilterStuff(int entity, int mask)
{
	return entity > MaxClients;
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

public bool Filter(int entity,int mask)
{
	return !(IsValidClient(entity));
}
