#pragma semicolon 1
#pragma newdecls required

static const char g_DeathSounds[][] =
{
	"vo/heavy_paincrticialdeath01.mp3",
	"vo/heavy_paincrticialdeath02.mp3",
	"vo/heavy_paincrticialdeath03.mp3"
};

static int NPCID;

void CherryBlossomOnMapStart()
{
	PrecacheSoundArray(g_DeathSounds);
	PrecacheModel("models/props_japan/sakura_tree01.mdl");
	NPCData data;
	strcopy(data.Name, sizeof(data.Name), "Cherry Blossom");
	strcopy(data.Plugin, sizeof(data.Plugin), "npc_cherry_blossom");
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
		
		npc.m_iState = 0;
		npc.m_flSpeed = 0.0;
		npc.m_flMeleeArmor = 2.0;

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
		CherryBlossom_SelfDefense(npc, distance, vecTarget, gameTime); 
	}
}

void CherryBlossom_SelfDefense(CherryBlossom npc, float distance, float vecTarget[3], float gameTime)
{
	if(npc.m_flAttackHappens)
	{
		if(npc.m_flAttackHappens < gameTime)
		{
			npc.m_flAttackHappens = 0.0;
			
			Handle swingTrace;
			npc.FaceTowards(vecTarget, 15000.0);
			if(npc.DoSwingTrace(swingTrace, npc.m_iTarget, _, _, _, _))
			{
				int target = TR_GetEntityIndex(swingTrace);
				if(target > 0)
				{
					float damage = 60.0;

					SDKHooks_TakeDamage(target, npc.index, npc.index, damage, DMG_CLUB);
				}
			}
		}
	}

	if(distance < (NORMAL_ENEMY_MELEE_RANGE_FLOAT_SQUARED) && npc.m_flNextMeleeAttack < gameTime)
	{
		int target = Can_I_See_Enemy(npc.index, npc.m_iTarget);
		if(IsValidEnemy(npc.index, target, false, true))
		{
			npc.m_iTarget = target;
			
			npc.m_flAttackHappens = gameTime + 0.25;
			npc.m_flNextMeleeAttack = gameTime + 0.75;
		}
	}
}
static void ClotDeath(int entity)
{
	CherryBlossom npc = view_as<CherryBlossom>(entity);
	
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