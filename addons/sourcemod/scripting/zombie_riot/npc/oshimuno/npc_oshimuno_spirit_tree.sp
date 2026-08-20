#pragma semicolon 1
#pragma newdecls required

static const char g_DeathSounds[][] =
{
	"vo/heavy_paincrticialdeath01.mp3",
	"vo/heavy_paincrticialdeath02.mp3",
	"vo/heavy_paincrticialdeath03.mp3"
};

static char gExplosive1;
static char gLaser1;

#define INITIAL_ORB_SPAWN_COOLDOWN 10.0
#define ORB_SPAWN_COOLDOWN 20.0

void OshimunoSpiritTreeOnMapStart()
{
	PrecacheSoundArray(g_DeathSounds);
	PrecacheModel("models/props_japan/sakura_tree01.mdl");
	gLaser1 = PrecacheModel("materials/sprites/laser.vmt");
	NPCData data;
	strcopy(data.Name, sizeof(data.Name), "Spirit Cherry Blossom");
	strcopy(data.Plugin, sizeof(data.Plugin), "npc_oshimuno_spirit_tree");
	strcopy(data.Icon, sizeof(data.Icon), "victoria_basebreaker");
	data.IconCustom = true;
	data.Flags = 0;
	data.Category = Type_Oshimuno;
	data.Func = ClotSummon;
	NPC_Add(data);
}

static any ClotSummon(int client, float vecPos[3], float vecAng[3], int team)
{
	return OshimunoSpiritTree(vecPos, vecAng, team);
}

methodmap OshimunoSpiritTree < CClotBody
{
	property float m_flRecheckIfAlliesDead
	{
		public get()							{ return fl_AbilityOrAttack[this.index][0]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][0] = TempValueForProperty; }
	}
	property float m_flOrbCooldown
	{
		public get()							{ return fl_AbilityOrAttack[this.index][2]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][2] = TempValueForProperty; }
	}
	public OshimunoSpiritTree(float vecPos[3], float vecAng[3], int ally)
	{
		OshimunoSpiritTree npc = view_as<OshimunoSpiritTree>(CClotBody(vecPos, vecAng, "models/props_japan/sakura_tree01.mdl", "1.5", "1000", ally));
		SetEntityRenderColor(npc.index, 0, 255, 255);
		float gameTime = GetGameTime(npc.index);
		
		i_NpcWeight[npc.index] = 999; //cant move trees
		Is_a_Medic[npc.index] = true; 
		b_thisNpcIsABoss[npc.index] = true; // no instakills
		i_NpcIsABuilding[npc.index] = true;
		KillFeed_SetKillIcon(npc.index, "megaton");
		
		npc.m_iBleedType = BLEEDTYPE_NORMAL;
		npc.m_iStepNoiseType = STEPSOUND_NORMAL;
		npc.m_iNpcStepVariation = STEPTYPE_NORMAL;
		

		func_NPCDeath[npc.index] = ClotDeath;
		func_NPCOnTakeDamage[npc.index] = Generic_OnTakeDamage;
		func_NPCThink[npc.index] = ClotThink;
		
		npc.m_flSpeed = 100.0;
		npc.m_flMeleeArmor = 1.35;
		npc.m_flOrbCooldown = gameTime + INITIAL_ORB_SPAWN_COOLDOWN;
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
	OshimunoSpiritTree npc = view_as<OshimunoSpiritTree>(iNPC);

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
		if(npc.m_flOrbCooldown < gameTime)// spawn orbs every 20s while not enraged
		{
			float pos[3]; GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", pos);
			float ang[3]; GetEntPropVector(npc.index, Prop_Data, "m_angRotation", ang);
			int entity = NPC_CreateByName("npc_oshimuno_spirit_orb", -1, pos, ang, GetTeam(npc.index));
			if(entity > MaxClients)
			{
				
				if(GetTeam(npc.index) != TFTeam_Red)
				NpcAddedToZombiesLeftCurrently(entity, true);
				view_as<CClotBody>(entity).m_flSpeed = npc.m_flSpeed;
			}
			npc.m_flOrbCooldown = gameTime + ORB_SPAWN_COOLDOWN;
		}
		if(npc.m_flRecheckIfAlliesDead < GetGameTime())
		{
			if(!IsValidAlly(npc.index, GetClosestAlly(npc.index)))
			{
				npc.Anger = true;
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
					OshimunoSpiritTreeEffect(npc.index, pos);
					for(int i; i < sizeof(enemy); i++)
					{
						if(enemy[i])
						{
							OshimunoSpiritTreeAttackInvoke(npc.index, enemy[i]);
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
		}
	}
}
	
	
static void OshimunoSpiritTreeEffect(int entity = -1, float VecPos_target[3] = {0.0,0.0,0.0})
{	
	int r = 235; //orange
	int g = 125;
	int b = 0;
	int laser;

	laser = ConnectWithBeam(entity, -1, r, g, b, 3.0, 3.0, 2.35, LASERBEAM, _, VecPos_target);

	CreateTimer(1.1, Timer_RemoveEntity, EntIndexToEntRef(laser), TIMER_FLAG_NO_MAPCHANGE);
}

public void OshimunoSpiritTreeAttackInvoke(int ref, int enemy)
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
		color[0] = 235;
		color[1] = 125;
		color[2] = 0;
		color[3] = 255;
		float UserLoc[3];
		GetAbsOrigin(entity, UserLoc);
		
		UserLoc[2]+=75.0;
		
		int SPRITE_INT_2 = PrecacheModel("materials/sprites/lgtning.vmt", false);
					
		TE_SetupBeamPoints(vecTarget, UserLoc, SPRITE_INT_2, 0, 0, 0, 0.8, 22.0, 10.2, 1, 8.0, color, 0);
		TE_SendToAll();

		EmitSoundToAll("misc/halloween/gotohell.wav", 0, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, vecTarget);
		
		Handle data;
		CreateDataTimer(Time, Smite_Timer_Spirit_Tree, data, TIMER_FLAG_NO_MAPCHANGE);
		WritePackFloat(data, vecTarget[0]);
		WritePackFloat(data, vecTarget[1]);
		WritePackFloat(data, vecTarget[2]);
		WritePackFloat(data, Range); // Range
		WritePackFloat(data, Dmg); // Damge
		WritePackCell(data, ref);
		
		spawnRing_Vectors(vecTarget, Range * 2.0, 0.0, 0.0, 0.0, "materials/sprites/laserbeam.vmt", 235, 125, 0, 200, 1, Time, 6.0, 0.1, 1, 1.0);
	}
}

public Action Smite_Timer_Spirit_Tree(Handle Smite_Logic, DataPack data)
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
	OshimunoSpiritTree npc = view_as<OshimunoSpiritTree>(entity);

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