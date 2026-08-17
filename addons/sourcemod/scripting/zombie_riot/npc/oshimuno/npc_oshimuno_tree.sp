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

void OshimunoCherryBlossomOnMapStart()
{
	PrecacheSoundArray(g_DeathSounds);
	PrecacheModel("models/props_japan/sakura_tree01.mdl");
	gLaser1 = PrecacheModel("materials/sprites/laser.vmt");
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

int CherryBlossom_ID()
{
	return NPCID;
}

static any ClotSummon(int client, float vecPos[3], float vecAng[3], int team)
{
	return CherryBlossom(vecPos, vecAng, team);
}

methodmap CherryBlossom < CClotBody
{
	property float m_flRecheckIfAlliesDead
	{
		public get()							{ return fl_AbilityOrAttack[this.index][0]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][0] = TempValueForProperty; }
	}
	public CherryBlossom(float vecPos[3], float vecAng[3], int ally)
	{
		CherryBlossom npc = view_as<CherryBlossom>(CClotBody(vecPos, vecAng, "models/props_japan/sakura_tree01.mdl", "1.5", "15000", ally)); //TODO: tree prop doesnt go away if killed
		SetEntityRenderColor(npc.index, 244, 182, 255, 200);
		
		i_NpcWeight[npc.index] = 999; //cant move trees
		Is_a_Medic[npc.index] = true; 
		b_thisNpcIsABoss[npc.index] = true; // no instakills
		i_NpcIsABuilding[npc.index] = true;
		npc.SetActivity("ACT_MP_RUN_MELEE");
		KillFeed_SetKillIcon(npc.index, "pickaxe");
		
		npc.m_iBleedType = BLEEDTYPE_NORMAL;
		npc.m_iStepNoiseType = STEPSOUND_NORMAL;
		npc.m_iNpcStepVariation = STEPTYPE_NORMAL;
		

		func_NPCDeath[npc.index] = ClotDeath;
		func_NPCOnTakeDamage[npc.index] = Generic_OnTakeDamage;
		func_NPCThink[npc.index] = ClotThink;
		
		npc.m_flSpeed = 150.0;
		npc.m_flMeleeArmor = 1.75;
		npc.m_bDissapearOnDeath = true;

		int Decision = TeleportDiversioToRandLocation(npc.index, true, 1500.0, 1000.0, .NeedLOSPlayer = true);
		switch(Decision)
		{
			case 2:
			{
				Decision = TeleportDiversioToRandLocation(npc.index, true, 1500.0, 500.0, .NeedLOSPlayer = true);
				if(Decision == 2)
				{
					Decision = TeleportDiversioToRandLocation(npc.index, true, 1500.0, 250.0, .NeedLOSPlayer = true);
					if(Decision == 2)
					{
						Decision = TeleportDiversioToRandLocation(npc.index, true, 1500.0, 0.0, .NeedLOSPlayer = true);
						if(Decision == 2)
						{
							//damn, cant find any.... guess we'll just not care about LOS.
							Decision = TeleportDiversioToRandLocation(npc.index, true, 1500.0, 0.0);
						}
					}
				}
			}
			case 3:
			{
				//todo code on what to do if random teleport is disabled
			}
		}
		return npc;
	}
}

static void ClotThink(int iNPC)
{
	CherryBlossom npc = view_as<CherryBlossom>(iNPC);

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
			}
		}
	}
	if(npc.Anger) //if trees are the last thing alive get enraged and start chasing
	{
		npc.StartPathing();
	}
	
	if(target > 0)
	{
		float vecTarget[3]; WorldSpaceCenter(target, vecTarget);
		float VecSelfNpc[3]; WorldSpaceCenter(npc.index, VecSelfNpc);
		float distance = GetVectorDistance(vecTarget, VecSelfNpc, true);	
		
		if(distance < npc.GetLeadRadius())
		{
			float vPredictedPos[3]; PredictSubjectPosition(npc, target,_,_, vPredictedPos);
			npc.SetGoalVector(vPredictedPos);
		}
		else 
		{
			npc.SetGoalEntity(target);
		}
		CherryBlossomSelfDefense(npc, distance, vecTarget, gameTime); 
	}
}

void CherryBlossomSelfDefense(CherryBlossom npc, float distance, float vecTarget[3], float gameTime)
{
	if(npc.m_flAttackHappens)
	{
		if(npc.m_flAttackHappens < gameTime)
		{
			npc.m_flAttackHappens = 0.0;
			int enemy[6];
			float pos[3];
			GetEntPropVector(npc.m_iTarget, Prop_Send, "m_vecOrigin", pos);
			pos[2] += 25.0;
			AbyssLeviathanEffect(npc.index, pos);
			for(int i; i < sizeof(enemy); i++)
			{
				if(enemy[i])
				{
					OshimunoTree_AttackInvoke(npc.index, enemy[i]);
				}
			}
		}
	}

	if(distance < 9999999 && npc.m_flNextMeleeAttack < gameTime) //map wide range bcs they attack you with ROOTS
	{
		int target = Can_I_See_Enemy(npc.index, npc.m_iTarget);
		if(IsValidEnemy(npc.index, target, false, true))
		{
			npc.m_iTarget = target;
			
			npc.m_flAttackHappens = gameTime + 0.25;
			npc.m_flNextMeleeAttack = gameTime + 5.0;
		}
	}
}
static void AbyssLeviathanEffect(int entity = -1, float VecPos_target[3] = {0.0,0.0,0.0})
{	
	int r = 244; //light pink
	int g = 182;
	int b = 255;
	int laser;

	laser = ConnectWithBeam(entity, -1, r, g, b, 3.0, 3.0, 2.35, LASERBEAM, _, VecPos_target);

	CreateTimer(1.1, Timer_RemoveEntity, EntIndexToEntRef(laser), TIMER_FLAG_NO_MAPCHANGE);
}

public void OshimunoTree_AttackInvoke(int ref, int enemy)
{
	int entity = EntRefToEntIndex(ref);
	if(IsValidEntity(entity))
	{
		float Time=1.75;
		float Range=150.0;
		if(LastMann)
			Range = 75.0;

		float Dmg=500.0;
		float vecTarget[3];
		WorldSpaceCenter(enemy, vecTarget );
		vecTarget[2] += 1.0;
		
		
		int color[4];
		color[0] = 244;
		color[1] = 182;
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
		
		spawnRing_Vectors(vecTarget, Range * 2.0, 0.0, 0.0, 0.0, "materials/sprites/laserbeam.vmt", 65, 65, 255, 200, 1, Time, 6.0, 0.1, 1, 1.0);
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

static void ClotDeath(int entity)
{
	CherryBlossom npc = view_as<CherryBlossom>(entity);

	float pos[3]; GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", pos);
	float ang[3]; GetEntPropVector(npc.index, Prop_Data, "m_angRotation", ang);
	int spawn_index = NPC_CreateByName("npc_placed_supplies", -1, pos, ang, GetTeam(npc.index));
	if(spawn_index > MaxClients) //TODO: make a unique npc for this instead of reusing one
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