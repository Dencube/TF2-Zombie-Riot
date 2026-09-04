#pragma semicolon 1
#pragma newdecls required

static const char g_DeathSounds[][] =
{
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

static char g_MeleeHitSounds[][] = 
{
	"weapons/boxing_gloves_hit1.wav",
	"weapons/boxing_gloves_hit2.wav",
	"weapons/boxing_gloves_hit3.wav",
	"weapons/boxing_gloves_hit4.wav",
};

static const char g_RangedAttackSounds[][] = 
{
	"weapons/grenade_launcher1.wav",
};
void OshimunoPowdermanOnMapStart()
{
	PrecacheSoundArray(g_DeathSounds);
	PrecacheSoundArray(g_HurtSounds);
	PrecacheSoundArray(g_IdleAlertedSounds);
	PrecacheSoundArray(g_MeleeHitSounds);
	PrecacheSoundArray(g_RangedAttackSounds);
	NPCData data;
	strcopy(data.Name, sizeof(data.Name), "Spirit Powderman");
	strcopy(data.Plugin, sizeof(data.Plugin), "npc_oshimuno_powderman");
	strcopy(data.Icon, sizeof(data.Icon), "demo");
	data.IconCustom = true;
	data.Flags = 0;
	data.Category = Type_Oshimuno;
	data.Func = ClotSummon;
	NPC_Add(data);
}

static any ClotSummon(int client, float vecPos[3], float vecAng[3], int team)
{
	return OshimunoPowderman(vecPos, vecAng, team);
}

methodmap OshimunoPowderman < CClotBody
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
	public void PlayMeleeHitSound()
	{
		EmitSoundToAll(g_MeleeHitSounds[GetRandomInt(0, sizeof(g_MeleeHitSounds) - 1)], this.index, SNDCHAN_AUTO, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, _);	
	}
	public void PlayRangedSound()
	{
		EmitSoundToAll(g_RangedAttackSounds[GetRandomInt(0, sizeof(g_RangedAttackSounds) - 1)], this.index, SNDCHAN_AUTO, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, _);	
	}
	
	public OshimunoPowderman(float vecPos[3], float vecAng[3], int ally)
	{
		OshimunoPowderman npc = view_as<OshimunoPowderman>(CClotBody(vecPos, vecAng, "models/player/demo.mdl", "1.0", "1000", ally));
		float gameTime = GetGameTime(npc.index);
		
		i_NpcWeight[npc.index] = 1;
		npc.SetActivity("ACT_MP_RUN_SECONDARY");
		KillFeed_SetKillIcon(npc.index, "tf_projectile_pipe");
		
		
		npc.m_iBleedType = BLEEDTYPE_NORMAL;
		npc.m_iStepNoiseType = STEPSOUND_NORMAL;
		npc.m_iNpcStepVariation = STEPTYPE_NORMAL;
		

		func_NPCDeath[npc.index] = ClotDeath;
		func_NPCOnTakeDamage[npc.index] = OshimunoPowdermanOnTakeDamage;
		func_NPCThink[npc.index] = ClotThink;
		
		npc.m_flSpeed = 240.0;
		npc.m_iState = 0;  // 0 for walking with grenade launcher || 1 for shooting and standing still
		npc.m_flNextMeleeAttack = gameTime + FAR_FUTURE;

		npc.m_iWearable1 = npc.EquipItem("head", "models/weapons/c_models/c_grenadelauncher/c_grenadelauncher.mdl");

		npc.m_iWearable2 = npc.EquipItem("head", "models/workshop/player/items/all_class/hw2013_stiff_buddy/hw2013_stiff_buddy_scout.mdl");

		npc.m_iWearable3 = npc.EquipItem("head", "models/workshop/player/items/demo/sbox2014_demo_samurai_armour/sbox2014_demo_samurai_armour.mdl");

		npc.m_iWearable4 = npc.EquipItem("head", "models/workshop/player/items/demo/eotl_demopants/eotl_demopants.mdl");
		SetEntProp(npc.m_iWearable4, Prop_Send, "m_nSkin", 1);

		SetEntProp(npc.index, Prop_Send, "m_nSkin", 1);
		SetVariantInt(4);
		AcceptEntityInput(npc.index, "SetBodyGroup");

		npc.StartPathing();
		return npc;
	}
}

static void ClotThink(int iNPC)
{
	OshimunoPowderman npc = view_as<OshimunoPowderman>(iNPC);

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
		OshimunoPowdermanSelfDefense(npc, distance, vecTarget, gameTime); 
	}
	if(npc.m_flDoingAnimation < gameTime && npc.Anger)
	{
		if(IsValidEntity(npc.m_iWearable1))
			RemoveEntity(npc.m_iWearable1);
		npc.m_iWearable1 = npc.EquipItem("head", "models/workshop/weapons/c_models/c_caber/c_caber.mdl");
		KillFeed_SetKillIcon(npc.index, "ullapool_caber_explosion");
		npc.StartPathing();
		npc.m_flSpeed = 400.0;
		npc.m_bisWalking = true;
		npc.SetActivity("ACT_MP_RUN_MELEE");
		fl_TotalArmor[npc.index] = 1.0;
		npc.m_flDoingAnimation = gameTime + FAR_FUTURE; //so this doesnt trigger again
	}

	npc.PlayIdleSound();
}

void OshimunoPowdermanSelfDefense(OshimunoPowderman npc, float distance, float vecTarget[3], float gameTime)
{	
	if(npc.Anger) // suicide charge
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
						float damage = 150.0;
					
						npc.PlayMeleeHitSound();
						SDKHooks_TakeDamage(target, npc.index, npc.index, damage, DMG_CLUB);

						float pos[3]; GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", pos);
						pos[2] += 45;
						StatusEffects_SpiritFireAddStuff(target, 15, 3.0);
						makeexplosion(-1, pos, 0, 0 , 0);
						SmiteNpcToDeath(npc.index);
					}
				}
				delete swingTrace;
			}
		}

		if(distance < (NORMAL_ENEMY_MELEE_RANGE_FLOAT_SQUARED) && npc.m_flNextMeleeAttack < gameTime)
		{
			int target = Can_I_See_Enemy(npc.index, npc.m_iTarget);
			if(IsValidEnemy(npc.index, target, false, true))
			{
				npc.m_iTarget = target;

				npc.AddGesture("ACT_MP_ATTACK_STAND_MELEE",_,_,_, 0.85);
			
				npc.m_flAttackHappens = gameTime + 0.25;
				npc.m_flNextMeleeAttack = gameTime + 0.75;
			}
		}
	}
	else // normal state
	{
		if(distance < (NORMAL_ENEMY_MELEE_RANGE_FLOAT_SQUARED * 20.0) && npc.m_flNextRangedAttack < gameTime)
		{
			float VecAim[3]; WorldSpaceCenter(npc.m_iTarget, VecAim );
			npc.FaceTowards(VecAim, 20000.0);
			int Enemy_I_See = Can_I_See_Enemy(npc.index, npc.m_iTarget);
			if(IsValidEnemy(npc.index, Enemy_I_See))
			{
				npc.m_iTarget = Enemy_I_See;
				npc.PlayRangedSound();
				float RocketDamage = 90.0;
				float RocketSpeed = 450.0;
				float VecStart[3]; WorldSpaceCenter(npc.index, VecStart);
				float vecDest[3];
				vecDest = vecTarget;
				vecDest[0] += GetRandomFloat(-55.0, 55.0);
				vecDest[1] += GetRandomFloat(-55.0, 55.0);
				vecDest[2] += GetRandomFloat(-10.0, 20.0);
				float SpeedReturn[3];

				npc.AddGesture("ACT_MP_ATTACK_STAND_SECONDARY");
				int RocketGet = npc.FireRocket(vecDest, RocketDamage, RocketSpeed, "models/weapons/w_models/w_grenade_grenadelauncher.mdl", 1.2);
				SetEntProp(RocketGet, Prop_Send, "m_nSkin", 1);
				//Reducing gravity, reduces speed, lol.
				SetEntityGravity(RocketGet, 0.7);
				ArcToLocationViaSpeedProjectile(RocketGet, vecDest, SpeedReturn, 2.0, 1.0);
				Better_Gravity_Rocket(RocketGet, 50.0);
				TeleportEntity(RocketGet, NULL_VECTOR, NULL_VECTOR, SpeedReturn);
				npc.m_flNextRangedAttack = gameTime + 1.8;
			}
		}
		if(distance < (NORMAL_ENEMY_MELEE_RANGE_FLOAT_SQUARED * 8.0)) // prevent from walking too close
		{
			if(Can_I_See_Enemy_Only(npc.index, npc.m_iTarget))
			{
				float VecAim[3]; WorldSpaceCenter(npc.m_iTarget, VecAim );
				npc.FaceTowards(VecAim, 20000.0);
				//stand
				if(npc.m_iState != 1)
				{
					npc.m_bisWalking = false;
					npc.m_iState = 1;
					npc.SetActivity("ACT_MP_RUN_SECONDARY");
					npc.m_flSpeed = 0.0;
					npc.StopPathing();
				}
			}
			else
			{
				if(npc.m_iState != 0)
				{
					npc.m_bisWalking = true;
					npc.m_iState = 0;
					npc.SetActivity("ACT_MP_RUN_SECONDARY");
					npc.m_flSpeed = 240.0;
					npc.StartPathing();
				}
			}
		}
		else //enemy is too far away.
		{
			if(npc.m_iState != 0)
			{
				npc.m_bisWalking = true;
				npc.m_iState = 0;
				npc.SetActivity("ACT_MP_RUN_SECONDARY");
				npc.m_flSpeed = 240.0;
				npc.StartPathing();
			}
		}
	}
}
static Action OshimunoPowdermanOnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{	
	OshimunoPowderman npc = view_as<OshimunoPowderman>(victim);
	float gameTime = GetGameTime(npc.index);
	if((ReturnEntityMaxHealth(npc.index)/2) >= GetEntProp(npc.index, Prop_Data, "m_iHealth") && !npc.Anger) //enrage below 50% hp
	{
		npc.Anger = true;
		fl_TotalArmor[npc.index] = 0.33;
		if(IsValidEntity(npc.m_iWearable1))
			RemoveEntity(npc.m_iWearable1);

		npc.StopPathing();
		npc.m_bisWalking = false;
		npc.AddActivityViaSequence("taunt_unleashed_rage_demo");
		EmitSoundToAll("vo/demoman_paincrticialdeath01.mp3", npc.index);
		npc.m_flNextMeleeAttack = gameTime + 1.75;
		npc.m_flNextRangedAttack = gameTime + FAR_FUTURE;
		npc.m_flDoingAnimation = gameTime + 1.5;
		npc.SetPlaybackRate(2.0);
		npc.SetCycle(0.01);
	}

	return Plugin_Changed;
}
static void ClotDeath(int entity) // TODO: maybe prevent this npc from gibbing when doing the suicide charge
{
	OshimunoPowderman npc = view_as<OshimunoPowderman>(entity);
	if(npc.Anger) // explode on death if enraged
	{
		float pos[3]; GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", pos);
		pos[2] += 45;
		makeexplosion(entity, pos, 75, 150, _, true, true, 3.0);
	}

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