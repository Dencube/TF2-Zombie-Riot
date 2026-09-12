#pragma semicolon 1
#pragma newdecls required

static const char g_DeathSounds[][] =
{
	"vo/soldier_paincrticialdeath01.mp3",
	"vo/soldier_paincrticialdeath02.mp3",
	"vo/soldier_paincrticialdeath03.mp3"
};

static const char g_HurtSounds[][] =
{
	"vo/soldier_painsharp01.mp3",
	"vo/soldier_painsharp02.mp3",
	"vo/soldier_painsharp03.mp3",
	"vo/soldier_painsharp04.mp3",
	"vo/soldier_painsharp05.mp3",
	"vo/soldier_painsharp06.mp3",
	"vo/soldier_painsharp07.mp3",
	"vo/soldier_painsharp08.mp3"
};

static const char g_IdleAlertedSounds[][] = 
{
	"vo/taunts/soldier_taunts19.mp3",
	"vo/taunts/soldier_taunts20.mp3",
	"vo/taunts/soldier_taunts21.mp3",
	"vo/taunts/soldier_taunts18.mp3"
};

static const char g_RangedAttackSounds[][] = 
{
	"weapons/rocket_shoot.wav",
};

/*ArrayList TargetsAlreadyHit[MAXENTITIES];*/
static int HitsLeft[MAXENTITIES]={0, ...};
void OshimunoRicochetOnMapStart()
{
	PrecacheSoundArray(g_DeathSounds);
	PrecacheSoundArray(g_HurtSounds);
	PrecacheSoundArray(g_IdleAlertedSounds);
	PrecacheSoundArray(g_RangedAttackSounds);
	NPCData data;
	strcopy(data.Name, sizeof(data.Name), "Tarakeno Ricochet");
	strcopy(data.Plugin, sizeof(data.Plugin), "npc_oshimuno_ricochet");
	strcopy(data.Icon, sizeof(data.Icon), "victoria_basebreaker");
	data.IconCustom = true;
	data.Flags = 0;
	data.Category = Type_Oshimuno;
	data.Func = ClotSummon;
	NPC_Add(data);
}

static any ClotSummon(int client, float vecPos[3], float vecAng[3], int team)
{
	return OshimunoRicochet(vecPos, vecAng, team);
}

methodmap OshimunoRicochet < CClotBody
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
	
	public OshimunoRicochet(float vecPos[3], float vecAng[3], int ally)
	{
		OshimunoRicochet npc = view_as<OshimunoRicochet>(CClotBody(vecPos, vecAng, "models/player/soldier.mdl", "1.0", "1000", ally));
		
		i_NpcWeight[npc.index] = 1;
		npc.SetActivity("ACT_MP_RUN_PRIMARY");
		KillFeed_SetKillIcon(npc.index, "tf_projectile_rocket");
		
		npc.m_iBleedType = BLEEDTYPE_NORMAL;
		npc.m_iStepNoiseType = STEPSOUND_NORMAL;
		npc.m_iNpcStepVariation = STEPTYPE_NORMAL;
		

		func_NPCDeath[npc.index] = ClotDeath;
		func_NPCOnTakeDamage[npc.index] = Generic_OnTakeDamage;
		func_NPCThink[npc.index] = ClotThink;
		
		npc.m_flSpeed = 300.0;

		npc.m_iWearable1 = npc.EquipItem("head", "models/weapons/c_models/c_rocketlauncher/c_rocketlauncher.mdl");

		npc.m_iWearable2 = npc.EquipItem("head", "models/workshop/player/items/soldier/hw2013_shaolin_sash/hw2013_shaolin_sash.mdl");
		SetEntProp(npc.m_iWearable2, Prop_Send, "m_nSkin", 1);

		npc.m_iWearable3 = npc.EquipItem("head", "models/workshop/player/items/all_class/xms2013_jacket/xms2013_jacket_soldier.mdl");
		SetEntProp(npc.m_iWearable3, Prop_Send, "m_nSkin", 1);

		npc.m_iWearable4 = npc.EquipItem("head", "models/workshop/player/items/all_class/hwn2022_onimann/hwn2022_onimann_soldier.mdl");
		SetEntProp(npc.m_iWearable4, Prop_Send, "m_nSkin", 1);

		SetEntProp(npc.index, Prop_Send, "m_nSkin", 1);
		SetVariantInt(2);
		AcceptEntityInput(npc.index, "SetBodyGroup");

		npc.StartPathing();
		return npc;
	}
}

static void ClotThink(int iNPC)
{
	OshimunoRicochet npc = view_as<OshimunoRicochet>(iNPC);

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
		SetGoalVectorIndex = OshimunoRicochetSelfDefense(npc, distance, vecTarget, gameTime, npc.m_iTarget); 

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

int OshimunoRicochetSelfDefense(OshimunoRicochet npc, float distance, float vecTarget[3], float gameTime, int target)
{
	if(distance < (NORMAL_ENEMY_MELEE_RANGE_FLOAT_SQUARED) * 11.0 && npc.m_flNextRangedAttack < gameTime)
	{
		if(IsValidEnemy(npc.index, target, false, true))
		{
			npc.m_iTarget = target;
				
			npc.FaceTowards(vecTarget, 20000.0);
			npc.AddGesture("ACT_MP_ATTACK_STAND_PRIMARY");
			npc.PlayRangedSound();
			
			int projectile;
			float damage = 50.0;
			float ProjectileSpeed = 750.0;
			projectile = npc.FireParticleRocket(vecTarget, damage, ProjectileSpeed, 150.0, "flaregun_energyfield_blue", true);

			SDKUnhook(projectile, SDKHook_StartTouch, Rocket_Particle_StartTouch);
			int particle = EntRefToEntIndex(i_WandParticle[projectile]);
			CreateTimer(10.0, Timer_RemoveEntity, EntIndexToEntRef(projectile), TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(10.0, Timer_RemoveEntity, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
			
			HitsLeft[projectile] = 5;
			WandProjectile_ApplyFunctionToEntity(projectile, OshimunoRicochet_Particle_StartTouch);
			float ang[3];
			GetEntPropVector(projectile, Prop_Data, "m_angRotation", ang);
			Initiate_HomingProjectile(projectile, npc.index, 180.0, 180.0, true, true, ang);
			TriggerTimerHoming(projectile);
			npc.m_flNextRangedAttack = gameTime + 1.4;
		}
	}
	if(distance > (NORMAL_ENEMY_MELEE_RANGE_FLOAT_SQUARED * 10.0))
	{
		//target is too far, try to close in
		return 0;
	}
	else if(distance < (NORMAL_ENEMY_MELEE_RANGE_FLOAT_SQUARED * 5.0))
	{
		if(Can_I_See_Enemy_Only(npc.index, target))
		{
			//target is too close, try to keep distance
			return 1;
		}
	}
	return 0;
}

public void OshimunoRicochet_Particle_StartTouch(int entity, int target) //TODO: this code is ass doesn't work properly || wo suggested making an array to prevent hitting the same target
{
	if(target > 0 && target < MAXENTITIES && !IsIn_HitDetectionCooldown(entity, target, RicochetEnemy))	//did we hit something???
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
			
		float ProjectileLoc[3];
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", ProjectileLoc);

		float damage = 100.0;
		CPrintToChatAll("DEBUG: HIT");
		SDKHooks_TakeDamage(target, owner, inflictor, damage, DMG_BULLET|DMG_PREVENT_PHYSICS_FORCE, -1);	//acts like a kinetic rocket
		Set_HitDetectionCooldown(entity, target, FAR_FUTURE, RicochetEnemy);

		if(HitsLeft[entity] > 0)
		{
			HitsLeft[entity]--;
			//we can still hit new targets, cycle through the closest enemy!
			int NewTarget = GetClosestTarget(entity,true, 1000.0,true,false,-1, _,true,_,_,true, _,
			view_as<Function>(Ricochet_ValidTargetCheck));
			if(!IsValidEntity(NewTarget))
			{
				CPrintToChatAll("DEBUG: ERROR NO TARGET");
				int particle = EntRefToEntIndex(i_WandParticle[entity]);
				if(IsValidEntity(particle))
				{
					RemoveEntity(particle);
				}
				RemoveEntity(entity);
			}
			else
			{
				CPrintToChatAll("DEBUG: FOUND NEW TARGET");
				float ang[3];
				Initiate_HomingProjectile(entity, owner, 180.0, 180.0, true, true, ang, NewTarget);
				TriggerTimerHoming(entity);
			}
		}
		else
		{
			int particle = EntRefToEntIndex(i_WandParticle[entity]);
			if(IsValidEntity(particle))
			{
				RemoveEntity(particle);
			}
			RemoveEntity(entity);
		}
	}
	else
	{
		int particle = EntRefToEntIndex(i_WandParticle[entity]);
		//we uhh, missed?
		if(IsValidEntity(particle))
		{
			RemoveEntity(particle);
		}
		RemoveEntity(entity);
	}
}

bool Ricochet_ValidTargetCheck(int projectile, int target)
{
	if(IsIn_HitDetectionCooldown(projectile, target, RicochetEnemy))
	{
		return false;
		//we have already hit this target, skip.
	}
	return true;
}

static void ClotDeath(int entity) 
{
	OshimunoRicochet npc = view_as<OshimunoRicochet>(entity);

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