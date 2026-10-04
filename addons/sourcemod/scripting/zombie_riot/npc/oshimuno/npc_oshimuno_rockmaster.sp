#pragma semicolon 1
#pragma newdecls required

static const char g_DeathSounds[][] =
{
	"vo/demoman_paincrticialdeath01.mp3",
	"vo/demoman_paincrticialdeath02.mp3",
	"vo/demoman_paincrticialdeath03.mp3",
	"vo/demoman_paincrticialdeath04.mp3",
	"vo/demoman_paincrticialdeath05.mp3"
};

static const char g_HurtSounds[][] =
{
	"vo/demoman_painsharp01.mp3",
	"vo/demoman_painsharp02.mp3",
	"vo/demoman_painsharp03.mp3",
	"vo/demoman_painsharp04.mp3",
	"vo/demoman_painsharp05.mp3",
	"vo/demoman_painsharp06.mp3",
	"vo/demoman_painsharp07.mp3"
};

static const char g_IdleAlertedSounds[][] = 
{
	"vo/demoman_battlecry01.mp3",
	"vo/demoman_battlecry02.mp3",
	"vo/demoman_battlecry03.mp3",
	"vo/demoman_battlecry04.mp3",
};

static const char g_RangedAttackSounds[][] = 
{
	"weapons/cleaver_throw.wav",
};

static const char g_RangedHitSounds[][] = 
{
	"mvm/melee_impacts/bottle_hit_robo01.wav",
	"mvm/melee_impacts/bottle_hit_robo02.wav",
	"mvm/melee_impacts/bottle_hit_robo03.wav"
};

void OshimunoRockMasterOnMapStart()
{
	PrecacheSoundArray(g_DeathSounds);
	PrecacheSoundArray(g_HurtSounds);
	PrecacheSoundArray(g_IdleAlertedSounds);
	PrecacheSoundArray(g_RangedAttackSounds);
	PrecacheSoundArray(g_RangedHitSounds);
	PrecacheModel("models/props_coalmines/boulder2.mdl");
	PrecacheModel("models/props_coalmines/boulder3.mdl");
	PrecacheModel("models/props_coalmines/boulder4.mdl");
	NPCData data;
	strcopy(data.Name, sizeof(data.Name), "Rock Master");
	strcopy(data.Plugin, sizeof(data.Plugin), "npc_oshimuno_rockmaster");
	strcopy(data.Icon, sizeof(data.Icon), "victoria_basebreaker");
	data.IconCustom = true;
	data.Flags = 0;
	data.Category = Type_Oshimuno;
	data.Func = ClotSummon;
	NPC_Add(data);
}

static any ClotSummon(int client, float vecPos[3], float vecAng[3], int team)
{
	return OshimunoRockMaster(vecPos, vecAng, team);
}

methodmap OshimunoRockMaster < CClotBody
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
	
	public OshimunoRockMaster(float vecPos[3], float vecAng[3], int ally)
	{
		OshimunoRockMaster npc = view_as<OshimunoRockMaster>(CClotBody(vecPos, vecAng, "models/player/demo.mdl", "1.2", "3000", ally));
		
		i_NpcWeight[npc.index] = 1;
		npc.SetActivity("ACT_MP_RUN_MELEE");
		KillFeed_SetKillIcon(npc.index, "skullbat");
		
		npc.m_iBleedType = BLEEDTYPE_NORMAL;
		npc.m_iStepNoiseType = STEPSOUND_NORMAL;
		npc.m_iNpcStepVariation = STEPTYPE_NORMAL;
		

		func_NPCDeath[npc.index] = ClotDeath;
		func_NPCOnTakeDamage[npc.index] = Generic_OnTakeDamage;
		func_NPCThink[npc.index] = ClotThink;
		
		npc.m_flSpeed = 270.0;

		npc.m_iWearable1 = npc.EquipItem("head", "models/workshop/player/items/all_class/fall2013_hong_kong_cone/fall2013_hong_kong_cone_demo.mdl");

		npc.m_iWearable2 = npc.EquipItem("head", "models/player/items/demo/demo_parrot.mdl");

		npc.m_iWearable3 = npc.EquipItem("head", "models/workshop/player/items/demo/sbox2014_demo_samurai_armour/sbox2014_demo_samurai_armour.mdl");
		SetEntProp(npc.m_iWearable3, Prop_Send, "m_nSkin", 1);

		SetEntProp(npc.index, Prop_Send, "m_nSkin", 1);
		SetVariantInt(4);
		AcceptEntityInput(npc.index, "SetBodyGroup");

		npc.StartPathing();
		return npc;
	}
}

static void ClotThink(int iNPC)
{
	OshimunoRockMaster npc = view_as<OshimunoRockMaster>(iNPC);

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

	if(npc.m_bAllowBackWalking)
	{
		if(IsValidEnemy(npc.index, npc.m_iTarget))
		{
			float WorldSpaceVec[3]; WorldSpaceCenter(npc.m_iTarget, WorldSpaceVec);
			npc.FaceTowards(WorldSpaceVec, 150.0);
		}
	}
	
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
		int SetGoalVectorIndex = 0;
		SetGoalVectorIndex = OshimunoRockMasterSelfDefense(npc, distance, gameTime, npc.m_iTarget); 

		switch(SetGoalVectorIndex)
		{
			case 0:
			{
				npc.m_bAllowBackWalking = false;
				//Get the normal prediction code.
				if(distance < npc.GetLeadRadius()) 
				{
					float vPredictedPos[3];
					PredictSubjectPosition(npc, npc.m_iTarget,_,_, vPredictedPos);
					npc.SetGoalVector(vPredictedPos);
				}
				else 
				{
					npc.SetGoalEntity(npc.m_iTarget);
				}
			}
			case 1:
			{
				npc.m_bAllowBackWalking = true;
				float vBackoffPos[3];
				BackoffFromOwnPositionAndAwayFromEnemy(npc, npc.m_iTarget,_,vBackoffPos);
				npc.SetGoalVector(vBackoffPos, true); //update more often, we need it
			}
		}
	}
	else
	{
		npc.m_flGetClosestTargetTime = 0.0;
		npc.m_iTarget = GetClosestTarget(npc.index);
	}

	npc.PlayIdleSound();
}

int OshimunoRockMasterSelfDefense(OshimunoRockMaster npc, float distance, float gameTime, int target)
{
	if(distance < (NORMAL_ENEMY_MELEE_RANGE_FLOAT_SQUARED) * 16.0 && npc.m_flNextRangedAttack < gameTime)
	{
		if(IsValidEnemy(npc.index, target, false, true))
		{
			npc.m_iTarget = target;
			
			float vPredictedPos[3];
			PredictSubjectPositionForProjectiles(npc, target, 900.0, _,vPredictedPos);
			npc.FaceTowards(vPredictedPos, 20000.0);
			npc.AddGesture("ACT_MP_THROW");
			npc.PlayRangedSound();
			
			int projectile;
			switch(GetRandomInt(0,2))
			{
				case 0:
				{
					projectile = npc.FireArrow(vPredictedPos, 120.0, 900.0, "models/props_coalmines/boulder2.mdl", 0.4);
				}
				case 1:
				{
					projectile = npc.FireArrow(vPredictedPos, 120.0, 900.0, "models/props_coalmines/boulder3.mdl", 0.4);
				}
				case 2:
				{
					projectile = npc.FireArrow(vPredictedPos, 120.0, 900.0, "models/props_coalmines/boulder4.mdl", 0.4);
				}
			}
			int trail = Trail_Attach(projectile, ARROW_TRAIL, 80, 0.16, 15.0, 6.0, 1);
			i_WandParticle[projectile] = EntIndexToEntRef(trail);
			CreateTimer(5.0, Timer_RemoveEntity, EntIndexToEntRef(trail), TIMER_FLAG_NO_MAPCHANGE);
			SetParent(projectile, trail);
			WandProjectile_ApplyFunctionToEntity(projectile, OshimunoRockMasterParticle_StartTouch);	
			
			npc.m_flNextRangedAttack = gameTime + 2.5;
		}
	}
	if(distance > (NORMAL_ENEMY_MELEE_RANGE_FLOAT_SQUARED * 12.0))
	{
		//target is too far, try to close in
		return 0;
	}
	else if(distance < (NORMAL_ENEMY_MELEE_RANGE_FLOAT_SQUARED * 8.0))
	{
		if(Can_I_See_Enemy_Only(npc.index, target))
		{
			//target is too close, try to keep distance
			return 1;
		}
	}
	return 0;
}

public void OshimunoRockMasterParticle_StartTouch(int entity, int target)
{
	if(target > 0 && target < MAXENTITIES)	//did we hit something???
	{
		int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		if(!IsValidEntity(owner))
		{
			owner = 0;
		}
		
		int inflictor = h_ArrowInflictorRef[entity];
		if(inflictor != -1)
			inflictor = EntRefToEntIndex(h_ArrowInflictorRef[entity]);

		if(inflictor == -1)
			inflictor = owner;

		EmitSoundToAll(g_RangedHitSounds[GetRandomInt(0, sizeof(g_RangedHitSounds) - 1)], entity, _, 80, _, 0.8, 100);

		float VecMe[3]; WorldSpaceCenter(owner, VecMe);
		float VecEnemy[3]; WorldSpaceCenter(target, VecEnemy);
		float AngleVec[3];
		MakeVectorFromPoints(VecMe, VecEnemy, AngleVec);
		GetVectorAngles(AngleVec, AngleVec);
		AngleVec[0] = -30.0;
		Custom_Knockback(owner, target, 600.0, true, true, true, .OverrideLookAng = AngleVec);
		ApplyStatusEffect(owner, target, "Ragdolled", 0.8);	
		FreezeNpcInTime(target, 0.8);
	}
	RemoveEntity(entity);
}
static void ClotDeath(int entity) 
{
	OshimunoRockMaster npc = view_as<OshimunoRockMaster>(entity);

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