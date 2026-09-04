#pragma semicolon 1
#pragma newdecls required //TODO: tree attacks are kinda broken when they're last || also fix their attacks activating when others are still alive

static const char g_DeathSounds[][] =
{
	"vo/heavy_paincrticialdeath01.mp3",
	"vo/heavy_paincrticialdeath02.mp3",
	"vo/heavy_paincrticialdeath03.mp3"
};

static int NPCID;
static char gExplosive1;
static char gLaser1;

static int TCONE_COLOR[3] = { 245, 180, 255 };
static bool g_TreeConeFillOk = false;
static int g_TreeConeLaser = -1;

#define TCONE_FILL_MAT "laststand/fill_cone45_v2.vmt"
#define TCONE_RADIUS 160.0
#define TCONE_MELEE_ARC 90.0			// punch hit radius
#define TCONE_HALFANGLE 60.0	    	// angle based on relative north, 22.5 = a 45 degree cone
#define TCONE_LIFESPAN 0.75	    	// how long the cone lasts before disappearing
#define TCONE_OUTLINE_ALPHA 200
#define TCONE_FILL_ALPHA 90			// 0 disables the pie sheet entirely
#define TCONE_FILL_FWD 0.7071
#define TCONE_FILL_LEFT 0.0
#define TCONE_INTERVAL 2.5
#define TCONE_MELEE_DAMAGE 100.0
#define TCONE_DAMAGE 100.0
#define TCONE_LOG_MODEL "models/props_forest/tree_pine_singlelog.mdl"
#define TCONE_LOG_RISE 200.0
#define TCONE_LOG_TIME 0.75
#define TCONE_LOG_SINK 110.0
#define TCONE_LOG_ALPHA 128

void OshimunoTreeOnMapStart()
{
	PrecacheSoundArray(g_DeathSounds);
	PrecacheModel("models/props_japan/sakura_tree01.mdl");
	gLaser1 = PrecacheModel("materials/sprites/laser.vmt");
	g_TreeConeLaser = PrecacheModel("sprites/laserbeam.vmt");
	PrecacheModel(TCONE_LOG_MODEL);
	char path[PLATFORM_MAX_PATH];
	FormatEx(path, sizeof(path), "materials/%s", TCONE_FILL_MAT);
	g_TreeConeFillOk = FileExists(path, true);
	if(g_TreeConeFillOk)
	{
		AddFileToDownloadsTable(path);
		ReplaceString(path, sizeof(path), ".vmt", ".vtf");
		AddFileToDownloadsTable(path);
		PrecacheModel(TCONE_FILL_MAT);
	}
	NPCData data;
	strcopy(data.Name, sizeof(data.Name), "Cherry Blossom");
	strcopy(data.Plugin, sizeof(data.Plugin), "npc_oshimuno_tree");
	strcopy(data.Icon, sizeof(data.Icon), "victoria_basebreaker");
	data.IconCustom = true;
	data.Flags = 0;
	data.Category = Type_Oshimuno;
	data.Func = ClotSummon;
	NPCID = NPC_Add(data);
}

int OshimunoTree_ID()
{
	return NPCID;
}

static any ClotSummon(int client, float vecPos[3], float vecAng[3], int team)
{
	return OshimunoTree(vecPos, vecAng, team);
}

methodmap OshimunoTree < CClotBody
{
	property float m_flRecheckIfAlliesDead
	{
		public get()							{ return fl_AbilityOrAttack[this.index][0]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][0] = TempValueForProperty; }
	}
	property float m_flNextConeAttack
	{
		public get()							{ return fl_AbilityOrAttack[this.index][1]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][1] = TempValueForProperty; }
	}
	public OshimunoTree(float vecPos[3], float vecAng[3], int ally)
	{
		OshimunoTree npc = view_as<OshimunoTree>(CClotBody(vecPos, vecAng, "models/props_japan/sakura_tree01.mdl", "1.5", "1000", ally));
		SetEntityRenderColor(npc.index, 245, 180, 255);
		
		i_NpcWeight[npc.index] = 999; //cant move trees
		Is_a_Medic[npc.index] = true; 
		b_thisNpcIsABoss[npc.index] = true; // no instakills
		i_NpcIsABuilding[npc.index] = true;
		b_NoHealthbar[npc.index] = 1;
		b_thisNpcHasAnOutline[npc.index] = true;
		KillFeed_SetKillIcon(npc.index, "megaton");
		
		npc.m_iBleedType = BLEEDTYPE_NORMAL;
		npc.m_iStepNoiseType = STEPSOUND_NORMAL;
		npc.m_iNpcStepVariation = STEPTYPE_NORMAL;
		

		func_NPCDeath[npc.index] = ClotDeath;
		func_NPCOnTakeDamage[npc.index] = Generic_OnTakeDamage;
		func_NPCThink[npc.index] = ClotThink;
		
		npc.m_flSpeed = 350.0;
		npc.m_flMeleeArmor = 1.35;
		npc.m_bDissapearOnDeath = true;
		npc.m_flNextConeAttack = 0.0;

		int Decision = TeleportDiversioToRandLocation(npc.index, true, 2000.0, 1000.0, .NeedLOSPlayer = true);
		switch(Decision)
		{
			case 2:
			{
				Decision = TeleportDiversioToRandLocation(npc.index, true, 2000.0, 500.0, .NeedLOSPlayer = true);
				if(Decision == 2)
				{
					Decision = TeleportDiversioToRandLocation(npc.index, true, 2000.0, 250.0, .NeedLOSPlayer = true);
					if(Decision == 2)
					{
						Decision = TeleportDiversioToRandLocation(npc.index, true, 2000.0, 0.0, .NeedLOSPlayer = true);
						if(Decision == 2)
						{
							//damn, cant find any.... guess we'll just not care about LOS.
							Decision = TeleportDiversioToRandLocation(npc.index, true, 2000.0, 0.0);
						}
					}
				}
			}
			case 3:
			{
				//todo code on what to do if random teleport is disabled
			}
		}
		if(ally != TFTeam_Red)
		{
			if(LastSpawnDiversio < GetGameTime())
			{
				EmitSoundToAll("weapons/sniper_railgun_world_reload.wav", _, _, _, _, 1.0);	
				EmitSoundToAll("weapons/sniper_railgun_world_reload.wav", _, _, _, _, 1.0);	
				for(int client_check=1; client_check<=MaxClients; client_check++)
				{
					if(IsClientInGame(client_check) && !IsFakeClient(client_check))
					{
						SetGlobalTransTarget(client_check);
						ShowGameText(client_check, "voice_player", 1, "%t", "The forest grows rapidly");
					}
				}
			}
			LastSpawnDiversio = GetGameTime() + 20.0;
		}
		return npc;
	}
}

static void ClotThink(int iNPC)
{
	OshimunoTree npc = view_as<OshimunoTree>(iNPC);

	float gameTime = GetGameTime(npc.index);
	if(npc.m_flNextDelayTime > gameTime)
		return;
	
	npc.m_flNextDelayTime = gameTime + DEFAULT_UPDATE_DELAY_FLOAT;
	npc.Update();
	
	if(npc.m_flNextThinkTime > gameTime)
		return;
	
	npc.m_flNextThinkTime = gameTime + 0.1;

	int target = npc.m_iTarget;
	if(i_Target[npc.index] != -1 && !IsValidEnemy(npc.index, target))
		i_Target[npc.index] = -1;
	
	if(i_Target[npc.index] == -1 || npc.m_flGetClosestTargetTime < gameTime)
	{
		target = GetClosestTarget(npc.index);
		npc.m_iTarget = target;
		npc.m_flGetClosestTargetTime = gameTime + GetRandomRetargetTime();
	}
	if(!npc.Anger) //if trees are the last thing alive get enraged and start chasing
	{
		if(npc.m_flRecheckIfAlliesDead < GetGameTime())
		{
			if(!IsValidAlly(npc.index, GetClosestAlly(npc.index)))
			{
				npc.Anger = true;
				fl_TotalArmor[npc.index] = 0.66;
				SetEntityRenderColor(npc.index, 255, 0, 0); // red because they're PISSED
			}
		}
	}
	if(npc.Anger) //if trees are the last thing alive get enraged and start chasing
	{
		npc.StartPathing();
		if(target > 0)
		{
			float vecTarget[3]; WorldSpaceCenter(target, vecTarget);
			float VecSelfNpc[3]; WorldSpaceCenter(npc.index, VecSelfNpc);
			float distance = GetVectorDistance(vecTarget, VecSelfNpc, true);

			if(npc.m_flAttackHappens)
			{
				if(npc.m_flAttackHappens < gameTime)
				{
					npc.m_flAttackHappens = 0.0;
					int enemy[6];
					UnderTides npc1 = view_as<UnderTides>(iNPC);
					GetHighDefTargets(npc1, enemy, sizeof(enemy));
					float pos[3];
					GetEntPropVector(npc.m_iTarget, Prop_Send, "m_vecOrigin", pos);
					pos[2] += 25.0;
					OshimunoTreeEffect(npc.index, pos);
					for(int i; i < sizeof(enemy); i++)
					{
						if(enemy[i])
						{
							OshimunoTreeAttackInvoke(npc.index, enemy[i]);
						}
					}
				}
			}	
			if(distance < 9999999 && npc.m_flNextMeleeAttack < gameTime) //map wide range bcs they attack you with ROOTS
			{
				if(IsValidEnemy(npc.index, target, false, true))
				{
					npc.m_flAttackHappens = gameTime + 0.25;
					npc.m_flNextMeleeAttack = gameTime + 5.0;
				}
			}
			if(distance < npc.GetLeadRadius())
			{
				float vPredictedPos[3]; PredictSubjectPosition(npc, target,_,_, vPredictedPos);
				npc.SetGoalVector(vPredictedPos);
			}
			else 
			{
				npc.SetGoalEntity(target);
			}
			OshimunoTreeConeAttack(npc, distance, gameTime);
		}
	}
}
	
	
static void OshimunoTreeEffect(int entity = -1, float VecPos_target[3] = {0.0,0.0,0.0})
{	
	int r = 245; //light pink
	int g = 180;
	int b = 255;
	int laser;

	laser = ConnectWithBeam(entity, -1, r, g, b, 3.0, 3.0, 2.35, LASERBEAM, _, VecPos_target);

	CreateTimer(1.1, Timer_RemoveEntity, EntIndexToEntRef(laser), TIMER_FLAG_NO_MAPCHANGE);
}

public void OshimunoTreeAttackInvoke(int ref, int enemy)
{
	int entity = EntRefToEntIndex(ref);
	if(IsValidEntity(entity))
	{
		float Time=2.0;
		float Range=200.0;
		if(LastMann)
			Range = 100.0;

		float Dmg=250.0;
		float vecTarget[3];
		WorldSpaceCenter(enemy, vecTarget );
		vecTarget[2] += 1.0;
		
		
		int color[4];
		color[0] = 245;
		color[1] = 180;
		color[2] = 255;
		color[3] = 255;
		float UserLoc[3];
		GetAbsOrigin(entity, UserLoc);
		
		UserLoc[2]+=75.0;
		
		int SPRITE_INT_2 = PrecacheModel("materials/sprites/lgtning.vmt", false);
					
		TE_SetupBeamPoints(vecTarget, UserLoc, SPRITE_INT_2, 0, 0, 0, 0.8, 22.0, 10.2, 1, 8.0, color, 0);
		TE_SendToAll();

		EmitSoundToAll("misc/halloween/gotohell.wav", 0, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, vecTarget);
		
		Handle data;
		CreateDataTimer(Time, Smite_Timer_Tree, data, TIMER_FLAG_NO_MAPCHANGE);
		WritePackFloat(data, vecTarget[0]);
		WritePackFloat(data, vecTarget[1]);
		WritePackFloat(data, vecTarget[2]);
		WritePackFloat(data, Range); // Range
		WritePackFloat(data, Dmg); // Damge
		WritePackCell(data, ref);
		
		spawnRing_Vectors(vecTarget, Range * 2.0, 0.0, 0.0, 0.0, "materials/sprites/laserbeam.vmt", 245, 180, 255, 200, 1, Time, 6.0, 0.1, 1, 1.0);
	}
}

public Action Smite_Timer_Tree(Handle Smite_Logic, DataPack data)
{
	ResetPack(data);
		
	float startPosition[3];
	float position[3];
	startPosition[0] = ReadPackFloat(data);
	startPosition[1] = ReadPackFloat(data);
	startPosition[2] = ReadPackFloat(data);
	float Ionrange = ReadPackFloat(data);
	float Iondamage = ReadPackFloat(data);
	int client = EntRefToEntIndex(ReadPackCell(data));
	
	if(!IsValidEntity(client))
	{
		return Plugin_Stop;
	}
				
	Explode_Logic_Custom(Iondamage, client, client, -1, startPosition, Ionrange , _ , _ , true);
	
	TE_SetupExplosion(startPosition, gExplosive1, 10.0, 1, 0, 0, 0);
	TE_SendToAll();
			
	position[0] = startPosition[0];
	position[1] = startPosition[1];
	position[2] += startPosition[2] + 900.0;
	startPosition[2] += -200;
	TE_SetupBeamPoints(startPosition, position, gLaser1, 0, 0, 0, 2.0, 30.0, 30.0, 0, 1.0, {65, 65, 255, 255}, 3);
	TE_SendToAll();
	TE_SetupBeamPoints(startPosition, position, gLaser1, 0, 0, 0, 2.0, 50.0, 50.0, 0, 1.0, {65, 65, 255, 255}, 3);
	TE_SendToAll();
	TE_SetupBeamPoints(startPosition, position, gLaser1, 0, 0, 0, 2.0, 80.0, 80.0, 0, 1.0, {65, 65, 255, 255}, 3);
	TE_SendToAll();
	TE_SetupBeamPoints(startPosition, position, gLaser1, 0, 0, 0, 2.0, 100.0, 100.0, 0, 1.0, {65, 65, 255, 255}, 3);
	TE_SendToAll();
	
	position[2] = startPosition[2] + 50.0;
	EmitSoundToAll("ambient/explosions/explode_9.wav", 0, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, startPosition);
	return Plugin_Continue;
}

void OshimunoTreeConeAttack(OshimunoTree npc, float distance, float gameTime)
{
	if(distance > (NORMAL_ENEMY_MELEE_RANGE_FLOAT_SQUARED) * 1.5 || npc.m_flNextConeAttack > gameTime)
		return;

	int target = Can_I_See_Enemy(npc.index, npc.m_iTarget);
	if(!IsValidEnemy(npc.index, target, false, true))
		return;

	npc.m_iTarget = target;
	npc.m_flNextConeAttack = gameTime + TCONE_INTERVAL;

	float bossPos[3];
	GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", bossPos);

	float yawDeg;
	{
		float at[3];
		WorldSpaceCenter(target, at);
		float dx = at[0] - bossPos[0];
		float dy = at[1] - bossPos[1];
		if((dx * dx) + (dy * dy) >= 1.0)
		{
			yawDeg = ArcTangent2(dy, dx) * 180.0 / FLOAT_PI;
		}
		else
		{
			float ang[3];
			GetEntPropVector(npc.index, Prop_Data, "m_angRotation", ang);
			yawDeg = ang[1];
		}
	}
	float yawRad = yawDeg * FLOAT_PI / 180.0;
	float arcRad = TCONE_MELEE_ARC * FLOAT_PI / 180.0;
	bool hit[MAXPLAYERS + 1];
	for(int client = 1; client <= MaxClients; client++)
	{
		if(!IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) != TFTeam_Red)
			continue;

		float pos[3];
		GetClientAbsOrigin(client, pos);
		float dx = pos[0] - bossPos[0];
		float dy = pos[1] - bossPos[1];
		float dz = pos[2] - bossPos[2];
		if(((dx * dx) + (dy * dy)) > (NORMAL_ENEMY_MELEE_RANGE_FLOAT_SQUARED) || dz > 120.0 || dz < -120.0)
			continue;

		if(TCONE_MELEE_ARC < 180.0)
		{
			float diff = ArcTangent2(dy, dx) - yawRad;
			while(diff > FLOAT_PI) diff -= FLOAT_PI * 2.0;
			while(diff < -FLOAT_PI) diff += FLOAT_PI * 2.0;
			if(FloatAbs(diff) > arcRad)
				continue;
		}
		hit[client] = true;
		float at[3];
		WorldSpaceCenter(client, at);
		SDKHooks_TakeDamage(client, npc.index, npc.index, TCONE_MELEE_DAMAGE, DMG_CLUB, -1, _, at);
		OshimunoTreeSpawnLog(pos);
	}
	OshimunoTreeResolveCone(npc, bossPos, yawDeg, hit);
	OshimunoTreeDrawCone(bossPos, yawDeg);
}

static void OshimunoTreeResolveCone(OshimunoTree npc, const float apex[3], float yawDeg, const bool exclude[MAXPLAYERS + 1])
{
	float yawRad = yawDeg * FLOAT_PI / 180.0;
	float halfAngle = (TCONE_HALFANGLE + 6.0) * FLOAT_PI / 180.0;
	float radiusPad = TCONE_RADIUS + 24.0;

	for(int client = 1; client <= MaxClients; client++)
	{
		if(exclude[client] || !IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) != TFTeam_Red)
			continue;

		float pos[3];
		GetClientAbsOrigin(client, pos);
		float dx = pos[0] - apex[0];
		float dy = pos[1] - apex[1];
		float dz = pos[2] - apex[2];
		if(((dx * dx) + (dy * dy)) > (radiusPad * radiusPad) || dz > 120.0 || dz < -120.0)
			continue;

		float diff = ArcTangent2(dy, dx) - yawRad;
		while(diff > FLOAT_PI) diff -= FLOAT_PI * 2.0;
		while(diff < -FLOAT_PI) diff += FLOAT_PI * 2.0;
		if(FloatAbs(diff) > halfAngle)
			continue;

		float at[3];
		WorldSpaceCenter(client, at);
		SDKHooks_TakeDamage(client, npc.index, npc.index, TCONE_DAMAGE, DMG_CLUB, -1, _, at);
		OshimunoTreeSpawnLog(pos);
	}
}

static void OshimunoTreeDrawCone(const float apex[3], float yawDeg)
{
	int color[4];
	color[0] = TCONE_COLOR[0];
	color[1] = TCONE_COLOR[1];
	color[2] = TCONE_COLOR[2];
	color[3] = TCONE_OUTLINE_ALPHA;

	float from[3];
	from = apex;
	from[2] += 5.0;

	float halfAngle = TCONE_HALFANGLE * FLOAT_PI / 180.0;
	float yawRad = yawDeg * FLOAT_PI / 180.0;
	float prev[3];
	for(int step; step <= 6; step++)
	{
		float ang = yawRad - halfAngle + ((halfAngle * 2.0) * (float(step) / 6.0));
		float at[3];
		at[0] = from[0] + (Cosine(ang) * TCONE_RADIUS);
		at[1] = from[1] + (Sine(ang) * TCONE_RADIUS);
		at[2] = from[2];

		if(step == 0 || step == 6)
		{
			TE_SetupBeamPoints(from, at, g_TreeConeLaser, -1, 0, 0, TCONE_LIFESPAN, 4.0, 4.0, 0, 0.0, color, 0);
			TE_SendToAll();
		}
		if(step)
		{
			TE_SetupBeamPoints(prev, at, g_TreeConeLaser, -1, 0, 0, TCONE_LIFESPAN, 4.0, 4.0, 0, 0.0, color, 0);
			TE_SendToAll();
		}
		prev = at;
	}
	if(TCONE_FILL_ALPHA <= 0 || !g_TreeConeFillOk)
		return;

	int spr = CreateEntityByName("env_sprite_oriented");
	if(spr <= MaxClients || !IsValidEntity(spr))
		return;

	char buffer[48];
	DispatchKeyValue(spr, "model", TCONE_FILL_MAT);
	FormatEx(buffer, sizeof(buffer), "%.3f", (TCONE_RADIUS * 0.5) / 32.0);
	DispatchKeyValue(spr, "scale", buffer);
	DispatchKeyValue(spr, "rendermode", "1");	
	FormatEx(buffer, sizeof(buffer), "%d %d %d", TCONE_COLOR[0], TCONE_COLOR[1], TCONE_COLOR[2]);
	DispatchKeyValue(spr, "rendercolor", buffer);
	IntToString(TCONE_FILL_ALPHA, buffer, sizeof(buffer));
	DispatchKeyValue(spr, "renderamt", buffer);
	DispatchKeyValue(spr, "spawnflags", "1");	
	float ang[3];
	ang[0] = 90.0;
	ang[1] = yawDeg + 45.0;
	FormatEx(buffer, sizeof(buffer), "%.0f %.0f 0", ang[0], ang[1]);
	DispatchKeyValue(spr, "angles", buffer);
	DispatchSpawn(spr);
	float fwdRad = yawDeg * FLOAT_PI / 180.0;
	float leftRad = (yawDeg + 90.0) * FLOAT_PI / 180.0;
	float at[3];
	at[0] = apex[0] + (Cosine(fwdRad) * TCONE_RADIUS * TCONE_FILL_FWD)
		+ (Cosine(leftRad) * TCONE_RADIUS * TCONE_FILL_LEFT);
	at[1] = apex[1] + (Sine(fwdRad) * TCONE_RADIUS * TCONE_FILL_FWD)
		+ (Sine(leftRad) * TCONE_RADIUS * TCONE_FILL_LEFT);
	at[2] = apex[2] + 4.0;
	TeleportEntity(spr, at, ang, NULL_VECTOR);
	SetEdictFlags(spr, (GetEdictFlags(spr) & ~(FL_EDICT_DONTSEND | FL_EDICT_PVSCHECK)) | FL_EDICT_ALWAYS);

	CreateTimer(TCONE_LIFESPAN, Timer_RemoveEntity, EntIndexToEntRef(spr), TIMER_FLAG_NO_MAPCHANGE);
}

static void OshimunoTreeSpawnLog(const float playerPos[3])
{
	float ground[3];
	ground = playerPos;

	float start[3], end[3];
	start = playerPos;
	start[2] += 55.0;
	end = playerPos;
	end[2] -= 800.0;

	Handle tr = TR_TraceRayEx(start, end, MASK_PLAYERSOLID_BRUSHONLY, RayType_EndPoint);
	if(TR_DidHit(tr))
		TR_GetEndPosition(ground, tr);
	delete tr;

	int prop = CreateEntityByName("prop_physics_multiplayer");
	if(prop <= MaxClients || !IsValidEntity(prop))
		return;

	float at[3];
	at = ground;
	at[2] -= TCONE_LOG_SINK;

	float ang[3];
	ang[1] = GetRandomFloat(-180.0, 180.0);

	DispatchKeyValue(prop, "model", TCONE_LOG_MODEL);
	DispatchKeyValue(prop, "physicsmode", "2");
	DispatchKeyValue(prop, "solid", "0");
	DispatchKeyValue(prop, "massScale", "1.0");
	DispatchKeyValue(prop, "spawnflags", "6");
	DispatchKeyValueVector(prop, "origin", at);
	DispatchKeyValueVector(prop, "angles", ang);
	DispatchSpawn(prop);

	float mins[3], maxs[3];
	GetEntPropVector(prop, Prop_Send, "m_vecMins", mins);
	GetEntPropVector(prop, Prop_Send, "m_vecMaxs", maxs);

	float up = maxs[2];
	if((maxs[0] - mins[0]) >= (maxs[1] - mins[1]) && (maxs[0] - mins[0]) > (maxs[2] - mins[2]))
	{
		ang[0] = -90.0;
		up = (maxs[0] > -mins[0]) ? maxs[0] : -mins[0];
	}
	else if((maxs[1] - mins[1]) > (maxs[2] - mins[2]))
	{
		ang[2] = 90.0;
		up = (maxs[1] > -mins[1]) ? maxs[1] : -mins[1];
	}
	else if(-mins[2] > up)
	{
		up = -mins[2];
	}

	if(up > 1.0)
		at[2] = ground[2] - up - 4.0;

	float vel[3];
	vel[2] = (TCONE_LOG_RISE / TCONE_LOG_TIME) + (0.5 * 800.0 * TCONE_LOG_TIME);
	TeleportEntity(prop, at, ang, vel);

	SetEntityRenderMode(prop, RENDER_TRANSCOLOR);
	SetEntityRenderColor(prop, 255, 255, 255, TCONE_LOG_ALPHA);

	SetEntityCollisionGroup(prop, 1);
	SetEntProp(prop, Prop_Send, "m_usSolidFlags", 12);
	SetEntProp(prop, Prop_Data, "m_nSolidType", 6);
	SetEdictFlags(prop, (GetEdictFlags(prop) & ~(FL_EDICT_DONTSEND | FL_EDICT_PVSCHECK)) | FL_EDICT_ALWAYS);

	CreateTimer(TCONE_LOG_TIME, Timer_RemoveEntity, EntIndexToEntRef(prop), TIMER_FLAG_NO_MAPCHANGE);
}

static void ClotDeath(int entity)
{
	OshimunoTree npc = view_as<OshimunoTree>(entity);

	float pos[3]; GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", pos);
	float ang[3]; GetEntPropVector(npc.index, Prop_Data, "m_angRotation", ang);
	int spawn_index = NPC_CreateByName("npc_oshimuno_tree_healing", -1, pos, ang, GetTeam(npc.index));
	if(spawn_index > MaxClients)
	{
		NpcStats_CopyStats(npc.index, spawn_index);
		CClotBody npc1 = view_as<CClotBody>(spawn_index);
		npc1.m_flNextThinkTime = GetGameTime() + 1.0;
		NpcAddedToZombiesLeftCurrently(spawn_index, true);
	}
	if(IsValidEntity(npc.m_iWearable1))
		RemoveEntity(npc.m_iWearable1);
	
	if(IsValidEntity(npc.m_iWearable2))
		RemoveEntity(npc.m_iWearable2);
	
	if(IsValidEntity(npc.m_iWearable3))
		RemoveEntity(npc.m_iWearable3);
	
	if(IsValidEntity(npc.m_iWearable4))
		RemoveEntity(npc.m_iWearable4);
	
	if(IsValidEntity(npc.m_iWearable5))
		RemoveEntity(npc.m_iWearable5);
}