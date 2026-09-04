#pragma semicolon 1 //TODO: add a mafia wrath system on death to all attackers/last attacker
#pragma newdecls required

static const char g_DeathSounds[][] =
{
	"vo/spy_paincrticialdeath01.mp3",
	"vo/spy_paincrticialdeath02.mp3",
	"vo/spy_paincrticialdeath03.mp3",
};

static const char g_HurtSounds[][] =
{
	"vo/spy_painsharp01.mp3",
	"vo/spy_painsharp02.mp3",
	"vo/spy_painsharp03.mp3",
	"vo/spy_painsharp04.mp3",
};

static const char g_IdleAlertedSounds[][] = 
{
	"vo/spy_battlecry01.mp3",
	"vo/spy_battlecry02.mp3",
	"vo/spy_battlecry03.mp3",
	"vo/spy_battlecry04.mp3",
};

static const char g_RangedAttackSounds[][] =
{
	"weapons/ambassador_shoot.wav",
};

void OshimunoExecutorOnMapStart()
{
	PrecacheSoundArray(g_DeathSounds);
	PrecacheSoundArray(g_HurtSounds);
	PrecacheSoundArray(g_IdleAlertedSounds);
	PrecacheSoundArray(g_RangedAttackSounds);
	NPCData data;
	strcopy(data.Name, sizeof(data.Name), "Tarakeno Executor");
	strcopy(data.Plugin, sizeof(data.Plugin), "npc_oshimuno_executor");
	strcopy(data.Icon, sizeof(data.Icon), "spy");
	data.IconCustom = true;
	data.Flags = 0;
	data.Category = Type_Oshimuno;
	data.Func = ClotSummon;
	NPC_Add(data);
}

static any ClotSummon(int client, float vecPos[3], float vecAng[3], int team)
{
	return OshimunoExecutor(vecPos, vecAng, team);
}

methodmap OshimunoExecutor < CClotBody
{
	public void PlayIdleSound()
	{
		if(this.m_flNextIdleSound > GetGameTime(this.index))
			return;
		
		EmitSoundToAll(g_IdleAlertedSounds[GetRandomInt(0, sizeof(g_IdleAlertedSounds) - 1)], this.index, SNDCHAN_VOICE, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME);
		this.m_flNextIdleSound = GetGameTime(this.index) + GetRandomFloat(12.0, 24.0);
	}
	public void PlayHurtSound()
	{
		EmitSoundToAll(g_HurtSounds[GetRandomInt(0, sizeof(g_HurtSounds) - 1)], this.index, SNDCHAN_VOICE, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME);
	}
	public void PlayDeathSound() 
	{
		EmitSoundToAll(g_DeathSounds[GetRandomInt(0, sizeof(g_DeathSounds) - 1)], this.index, SNDCHAN_VOICE, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME);
	}
	public void PlayRangedSound()
	{
		EmitSoundToAll(g_RangedAttackSounds[GetRandomInt(0, sizeof(g_RangedAttackSounds) - 1)], this.index, SNDCHAN_AUTO, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME);
	}
	
	public OshimunoExecutor(float vecPos[3], float vecAng[3], int ally)
	{
		OshimunoExecutor npc = view_as<OshimunoExecutor>(CClotBody(vecPos, vecAng, "models/player/spy.mdl", "1.0", "1000", ally));
		
		i_NpcWeight[npc.index] = 1;
		npc.SetActivity("ACT_MP_RUN_SECONDARY");
		KillFeed_SetKillIcon(npc.index, "samrevolver");
		
		npc.m_iBleedType = BLEEDTYPE_NORMAL;
		npc.m_iStepNoiseType = STEPSOUND_NORMAL;
		npc.m_iNpcStepVariation = STEPTYPE_NORMAL;
		

		func_NPCDeath[npc.index] = ClotDeath;
		func_NPCOnTakeDamage[npc.index] = Generic_OnTakeDamage;
		func_NPCThink[npc.index] = ClotThink;
		
		npc.m_flSpeed = 150.0;
		npc.m_iState = 0; // 0 walking normally || 1 standing still to shoot

		npc.m_iWearable1 = npc.EquipItem("head", "models/workshop/weapons/c_models/c_ttg_sam_gun/c_ttg_sam_gun.mdl");

		npc.m_iWearable2 = npc.EquipItem("head", "models/workshop/player/items/spy/spr18_assassins_attire/spr18_assassins_attire.mdl");
		SetEntProp(npc.m_iWearable2, Prop_Send, "m_nSkin", 1);

		npc.m_iWearable3 = npc.EquipItem("head", "models/workshop/player/items/all_class/hwn2024_spider_sights/hwn2024_spider_sights_spy.mdl");
		SetEntProp(npc.m_iWearable3, Prop_Send, "m_nSkin", 1);

		npc.m_iWearable4 = npc.EquipItem("head", "models/workshop/player/items/all_class/hwn2022_onimann/hwn2022_onimann_spy.mdl");
		SetEntProp(npc.m_iWearable4, Prop_Send, "m_nSkin", 1);

		SetEntProp(npc.index, Prop_Send, "m_nSkin", 1);
		SetVariantInt(2);
		AcceptEntityInput(npc.index, "SetBodyGroup");

		npc.StartPathing();
		TeleportDiversioToRandLocation(npc.index);
		return npc;
	}
}

static void ClotThink(int iNPC)
{
	OshimunoExecutor npc = view_as<OshimunoExecutor>(iNPC);

	float gameTime = GetGameTime(npc.index);
	if(npc.m_flNextDelayTime > gameTime)
		return;
	
	npc.m_flNextDelayTime = gameTime + DEFAULT_UPDATE_DELAY_FLOAT;
	npc.Update();

	if(npc.m_blPlayHurtAnimation)
	{
		npc.AddGesture("ACT_MP_GESTURE_FLINCH_CHEST", false);
		npc.PlayHurtSound();
		npc.m_blPlayHurtAnimation = false;
	}
	
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
		OshimunoExecutorSelfDefense(npc, distance, vecTarget, gameTime); 
	}

	npc.PlayIdleSound();
}

void OshimunoExecutorSelfDefense(OshimunoExecutor npc, float distance, float vecTarget[3], float gameTime)
{	
	int target;
	target = npc.m_iTarget;
	if(!IsValidEnemy(npc.index,target))
	{
		if(npc.m_iState != 0)
		{
			npc.m_bisWalking = true;
			npc.m_iState = 0;
			npc.SetActivity("ACT_MP_RUN_SECONDARY");
			npc.m_flSpeed = 150.0;
			npc.StartPathing();
		}
		return;
	}
	if(distance < (NORMAL_ENEMY_MELEE_RANGE_FLOAT_SQUARED * 3.0))
	{
		int Enemy_I_See = Can_I_See_Enemy(npc.index, npc.m_iTarget);
					
		if(IsValidEnemy(npc.index, Enemy_I_See))
		{
			if(npc.m_iState != 1)
			{
				npc.m_bisWalking = false;
				npc.m_iState = 1;
				npc.SetActivity("ACT_MP_STAND_SECONDARY");
				npc.m_flSpeed = 0.0;
				npc.StopPathing();
			}	
			if(npc.m_flNextRangedAttack < gameTime)
			{
				if(distance < (NORMAL_ENEMY_MELEE_RANGE_FLOAT_SQUARED * 10.0))
				{	
					npc.AddGesture("ACT_MP_ATTACK_STAND_SECONDARY", true);
					npc.PlayRangedSound();
					npc.FaceTowards(vecTarget, 20000.0);
					Handle swingTrace;
					if(npc.DoSwingTrace(swingTrace, target, { 9999.0, 9999.0, 9999.0 }))
					{
						target = TR_GetEntityIndex(swingTrace);	

						float vecHit[3];
						TR_GetEndPosition(vecHit, swingTrace);
						float origin[3], angles[3];
						view_as<CClotBody>(npc.m_iWearable1).GetAttachment("muzzle", origin, angles);
						ShootLaser(npc.m_iWearable1, "bullet_tracer02_blue_crit", origin, vecHit, false );
						float maxhealth = float(SDKCall_GetMaxHealth(target));
						float extradamage = (maxhealth) / 10; //10% of max health as damage

						if(IsValidEnemy(npc.index, target))
						{
							float damage = 25.0 + extradamage;

							SDKHooks_TakeDamage(target, npc.index, npc.index, damage, DMG_TRUEDAMAGE, -1, _, vecHit);
						}
					}
					delete swingTrace;
					npc.m_flNextRangedAttack = gameTime + 1.6;
				}
			}
		}
		else
		{
			if(npc.m_iState != 0)
			{
				npc.m_bisWalking = true;
				npc.m_iState = 0;
				npc.SetActivity("ACT_MP_RUN_SECONDARY");
				npc.m_flSpeed = 150.0;
				npc.StartPathing();
			}
		}
	}
	else
	{
		if(npc.m_iState != 0)
		{
			npc.m_bisWalking = true;
			npc.m_iState = 0;
			npc.SetActivity("ACT_MP_RUN_SECONDARY");
			npc.m_flSpeed = 150.0;
			npc.StartPathing();
		}
	}
}
static void ClotDeath(int entity) 
{
	OshimunoExecutor npc = view_as<OshimunoExecutor>(entity);

	if(!npc.m_bGib)
		npc.PlayDeathSound();
	
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