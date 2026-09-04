#pragma semicolon 1
#pragma newdecls required

// there has to be a better way to make this npc but im stupid so
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

static const char g_MeleeAttackSounds[][] =
{
	"weapons/pickaxe_swing1.wav",
	"weapons/pickaxe_swing2.wav",
	"weapons/pickaxe_swing3.wav",
};

static const char g_MeleeHitSounds[][] = 
{
	"weapons/cbar_hit1.wav",
	"weapons/cbar_hit2.wav",
};
static const char g_RangedAttackSounds[][] =
{
	"weapons/rocket_shoot.wav"
};

#define MAX_SHELLS_FRENZY 30
#define TRASHMAN_RING_RANGE 245.0
#define TRASHMAN_RING_RANGE_TRACE 275.0 

void OshimunoTrashManOnMapStart()
{
	PrecacheSoundArray(g_DeathSounds);
	PrecacheSoundArray(g_HurtSounds);
	PrecacheSoundArray(g_IdleAlertedSounds);
	PrecacheSoundArray(g_MeleeAttackSounds);
	PrecacheSoundArray(g_MeleeHitSounds);
	PrecacheSoundArray(g_RangedAttackSounds);
	PrecacheSound("weapons/dumpster_rocket_reload.wav");
	PrecacheModel("models/props_2fort/miningcrate002.mdl");
	NPCData data;
	strcopy(data.Name, sizeof(data.Name), "Trash Man");
	strcopy(data.Plugin, sizeof(data.Plugin), "npc_oshimuno_trash_man");
	strcopy(data.Icon, sizeof(data.Icon), "soldier_crit");
	data.IconCustom = true;
	data.Flags = 0;
	data.Category = Type_Oshimuno;
	data.Func = ClotSummon;
	NPC_Add(data);
}

static any ClotSummon(int client, float vecPos[3], float vecAng[3], int team)
{
	return OshimunoTrashMan(vecPos, vecAng, team);
}

methodmap OshimunoTrashMan < CClotBody
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
	public void PlayMeleeSound()
 	{
		EmitSoundToAll(g_MeleeAttackSounds[GetRandomInt(0, sizeof(g_MeleeAttackSounds) - 1)], this.index, SNDCHAN_AUTO, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, _);
	}
	public void PlayMeleeHitSound()
 	{
		EmitSoundToAll(g_MeleeHitSounds[GetRandomInt(0, sizeof(g_MeleeHitSounds) - 1)], this.index, SNDCHAN_AUTO, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, _);
	}
	public void PlayRangedSound()
	{
		EmitSoundToAll(g_RangedAttackSounds[GetRandomInt(0, sizeof(g_RangedAttackSounds) - 1)], this.index, SNDCHAN_VOICE, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME);
	}
	property float m_flArmorToGive
	{
		public get()							{ return fl_AbilityOrAttack[this.index][0]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][0] = TempValueForProperty; }
	}
	public OshimunoTrashMan(float vecPos[3], float vecAng[3], int ally)
	{
		OshimunoTrashMan npc = view_as<OshimunoTrashMan>(CClotBody(vecPos, vecAng, "models/player/soldier.mdl", "1.5", "7500", ally));
		
		i_NpcWeight[npc.index] = 5;
		npc.SetActivity("ACT_MP_RUN_PRIMARY");
		KillFeed_SetKillIcon(npc.index, "tf_projectile_rocket");
		
		npc.m_iBleedType = BLEEDTYPE_NORMAL;
		npc.m_iStepNoiseType = STEPSOUND_NORMAL;
		npc.m_iNpcStepVariation = STEPTYPE_NORMAL;
		

		func_NPCDeath[npc.index] = ClotDeath;
		func_NPCOnTakeDamage[npc.index] = OshimunoTrashManOnTakeDamage;
		func_NPCThink[npc.index] = ClotThink;
		
		npc.m_flSpeed = 240.0;
		npc.m_iState = 0;
		npc.m_flArmorToGive = 25.0;
		b_NpcUnableToDie[npc.index] = true;

		npc.m_iWearable1 = npc.EquipItem("head", "models/workshop/weapons/c_models/c_liberty_launcher/c_liberty_launcher.mdl");

		npc.m_iWearable2 = npc.EquipItem("head", "models/player/items/soldier/hwn_soldier_hat.mdl");
		SetEntProp(npc.m_iWearable2, Prop_Send, "m_nSkin", 1);

		npc.m_iWearable3 = npc.EquipItem("head", "models/player/items/soldier/hwn_soldier_misc2.mdl"); 
		SetEntProp(npc.m_iWearable3, Prop_Send, "m_nSkin", 1);
		
		npc.m_iWearable4 = npc.EquipItem("head", "models/workshop/player/items/soldier/sum24_pathfinder_style2/sum24_pathfinder_style2.mdl");
		SetEntProp(npc.m_iWearable4, Prop_Send, "m_nSkin", 1);

		npc.m_iWearable5 = npc.EquipItem("head", "models/workshop/player/items/soldier/jul13_lt_bites/jul13_lt_bites.mdl");

		npc.m_iWearable6 = npc.EquipItem("head", "models/workshop/player/items/soldier/hwn2022_safety_stripes/hwn2022_safety_stripes.mdl");

		SetEntProp(npc.index, Prop_Send, "m_nSkin", 1);
		SetVariantInt(2);
		AcceptEntityInput(npc.index, "SetBodyGroup");

		npc.StartPathing();
		return npc;
	}
}

static void ClotThink(int iNPC)
{
	OshimunoTrashMan npc = view_as<OshimunoTrashMan>(iNPC);

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
		OshimunoTrashManSelfDefense(npc, distance, vecTarget, gameTime); 
	}
	if(npc.m_flDoingAnimation < gameTime && npc.Anger) // begin frenzy
	{
		if(IsValidEntity(npc.m_iWearable1))
			RemoveEntity(npc.m_iWearable1);
		npc.m_iWearable1 = npc.EquipItem("head", "models/workshop/weapons/c_models/c_dumpster_device/c_dumpster_device.mdl");
		KillFeed_SetKillIcon(npc.index, "megaton");
		npc.StartPathing();
		npc.m_flSpeed = 333.0;
		npc.m_bisWalking = true;
		npc.SetActivity("ACT_MP_RUN_PRIMARY");
		fl_TotalArmor[npc.index] = 0.4;
		npc.m_flNextMeleeAttack = gameTime + 0.3;
		npc.m_flDoingAnimation = gameTime + FAR_FUTURE; //so this doesnt trigger again
	}
	float VecSelfNpcabs[3]; GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", VecSelfNpcabs);
	spawnRing_Vectors(VecSelfNpcabs, TRASHMAN_RING_RANGE_TRACE * 2.0, 0.0, 0.0, 15.0, "materials/sprites/laserbeam.vmt", 15, 15, 225, 200, 1, /*duration*/ 0.11, 5.0, 2.0, 1);
	npc.PlayIdleSound();
}

void OshimunoTrashManSelfDefense(OshimunoTrashMan npc, float distance, float vecTarget[3], float gameTime)
{	
	if(npc.Anger) // frenzy
	{
		int target = Can_I_See_Enemy(npc.index, npc.m_iTarget);
		if(npc.m_iState != 5) //loading frenzy
		{
			if(npc.m_flNextMeleeAttack < gameTime && npc.m_iOverlordComboAttack < MAX_SHELLS_FRENZY)
			{
				if(IsValidEnemy(npc.index, target, false, true))
				{
					npc.m_iTarget = target;
						
					npc.FaceTowards(vecTarget, 20000.0);
					npc.AddGesture("ACT_MP_RELOAD_STAND_PRIMARY", _, _, _, 1.3);
					EmitSoundToAll("weapons/dumpster_rocket_reload.wav", npc.index); //louder the more rockets are loaded
					if(npc.m_iOverlordComboAttack >= 10)
						EmitSoundToAll("weapons/dumpster_rocket_reload.wav", npc.index);
					if(npc.m_iOverlordComboAttack >= 20)
						EmitSoundToAll("weapons/dumpster_rocket_reload.wav", npc.index);
					npc.m_iOverlordComboAttack++;
					npc.m_flNextMeleeAttack = gameTime + 0.5;
				}
			}
			if(npc.m_iOverlordComboAttack == MAX_SHELLS_FRENZY)
			{
				npc.m_iState = 5;
				npc.m_flNextMeleeAttack = gameTime + FAR_FUTURE;
				npc.m_flNextRangedAttack = gameTime + 0.1;
			}
		}
		if(npc.m_iState == 5) // shooting frenzy
		{
			if(distance < (NORMAL_ENEMY_MELEE_RANGE_FLOAT_SQUARED) * 11.0 && npc.m_flNextRangedAttack < gameTime)
			{
				npc.m_iOverlordComboAttack--;
				int rocket = npc.FireRocket(vecTarget, 120.0, 1000.0, "models/props_2fort/miningcrate002.mdl", 0.7, _, 60.0);
				if(rocket != -1)
				{
					CreateTimer(4.0, Timer_RemoveEntity, EntIndexToEntRef(rocket), TIMER_FLAG_NO_MAPCHANGE);
					SetEntProp(rocket, Prop_Send, "m_bCritical", true);
				}
				npc.m_flNextRangedAttack = gameTime + 0.15;
			}
			if(npc.m_iOverlordComboAttack <= 0)
			{
				float pos[3];
				GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", pos);
				ParticleEffectAt(pos, "hightower_explosion", 2.0);
				EmitSoundToAll("items/cart_explode.wav", npc.index);
				Explode_Logic_Custom(200.0, 0, npc.index, -1, pos , TRASHMAN_RING_RANGE, 1.0, _, true, _, false, _, _, InsaneKnockbackDoExplode);
				b_NpcIsTeamkiller[npc.index] = true;
				SmiteNpcToDeath(npc.index);
			}
		}
	}
	else // normal state
	{
		int target = Can_I_See_Enemy(npc.index, npc.m_iTarget);
		if(distance < (NORMAL_ENEMY_MELEE_RANGE_FLOAT_SQUARED) * 11.0 && npc.m_flNextRangedAttack < gameTime)
		{
			if(IsValidEnemy(npc.index, target, false, true))
			{
				npc.m_iTarget = target;
					
				npc.FaceTowards(vecTarget, 20000.0);
				npc.AddGesture("ACT_MP_ATTACK_STAND_PRIMARY");
				npc.PlayRangedSound();
				
				npc.FireRocket(vecTarget, 80.0, 800.0, "models/props_2fort/miningcrate002.mdl", 0.7, _, 60.0);
				ExpidonsaGroupHeal(npc.index, TRASHMAN_RING_RANGE, 5000, 120.0, 1.0, true, OshimunoTrashManGiveArmor);
				npc.m_flNextRangedAttack = gameTime + 1.4;
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
					npc.SetActivity("ACT_MP_STAND_PRIMARY");
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
					npc.SetActivity("ACT_MP_RUN_PRIMARY");
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
				npc.SetActivity("ACT_MP_RUN_PRIMARY");
				npc.m_flSpeed = 240.0;
				npc.StartPathing();
			}
		}
	}
}
static Action OshimunoTrashManOnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{	
	OshimunoTrashMan npc = view_as<OshimunoTrashMan>(victim);
	float gameTime = GetGameTime(npc.index);
	if((ReturnEntityMaxHealth(npc.index)/4) >= GetEntProp(npc.index, Prop_Data, "m_iHealth") && !npc.Anger) //enrage below 25% hp
	{
		npc.Anger = true;
		fl_TotalArmor[npc.index] = 0.1;
		if(IsValidEntity(npc.m_iWearable1))
			RemoveEntity(npc.m_iWearable1);
		npc.m_bisWalking = false;
		npc.m_flSpeed = 0.0;
		npc.StopPathing();
		npc.AddActivityViaSequence("layer_taunt03");
		EmitSoundToAll("vo/soldier_paincrticialdeath01.mp3", npc.index);
		EmitSoundToAll("vo/soldier_paincrticialdeath01.mp3", npc.index);
		EmitSoundToAll("vo/soldier_paincrticialdeath01.mp3", npc.index);
		npc.m_flNextRangedAttack = gameTime + FAR_FUTURE;
		npc.m_flNextMeleeAttack = gameTime + FAR_FUTURE;
		npc.m_flDoingAnimation = gameTime + 1.8;
		npc.SetCycle(0.01);
		npc.SetPlaybackRate(1.6);
	}
	if( 1 >= GetEntProp(npc.index, Prop_Data, "m_iHealth") && npc.Anger && npc.m_iState != 5) //start frenzy shooting early if "killed"
	{
		npc.m_iState = 5;
		npc.m_flNextMeleeAttack = gameTime + FAR_FUTURE;
		npc.m_flNextRangedAttack = gameTime + 0.1;
	}
	return Plugin_Changed;
}

void OshimunoTrashManGiveArmor(int entity, int victim, float &healingammount)
{
	if(i_NpcIsABuilding[victim])
		return;

	OshimunoTrashMan npc1 = view_as<OshimunoTrashMan>(entity);
	GrantEntityArmor(victim, false, 0.05, 0.75, 0, npc1.m_flArmorToGive);
}

static void ClotDeath(int entity) 
{
	OshimunoTrashMan npc = view_as<OshimunoTrashMan>(entity);

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

	if(IsValidEntity(npc.m_iWearable6))
		RemoveEntity(npc.m_iWearable6);

	if(IsValidEntity(npc.m_iWearable7))
		RemoveEntity(npc.m_iWearable7);

	if(IsValidEntity(npc.m_iWearable8))
		RemoveEntity(npc.m_iWearable8);
}