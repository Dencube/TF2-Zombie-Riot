#pragma semicolon 1
#pragma newdecls required

static const char g_DeathSounds[][] =
{
	"vo/heavy_paincrticialdeath01.mp3",
	"vo/heavy_paincrticialdeath02.mp3",
	"vo/heavy_paincrticialdeath03.mp3"
};

static const char g_HurtSounds[][] =
{
	"vo/heavy_painsharp01.mp3",
	"vo/heavy_painsharp02.mp3",
	"vo/heavy_painsharp03.mp3",
	"vo/heavy_painsharp04.mp3",
	"vo/heavy_painsharp05.mp3",
};

static const char g_IdleAlertedSounds[][] =
{
	"vo/heavy_meleedare13.mp3",
	"vo/heavy_meleedare12.mp3",
	"vo/heavy_meleedare07.mp3",
	"vo/heavy_meleedare06.mp3",
	"vo/heavy_meleedare05.mp3",
};

static const char g_MeleeHitSounds[][] =
{
	"weapons/fist_hit_world1.wav",
	"weapons/fist_hit_world2.wav",
};

static const char g_MeleeAttackSounds[][] =
{
	"weapons/boxing_gloves_swing1.wav",
	"weapons/boxing_gloves_swing2.wav",
	"weapons/boxing_gloves_swing4.wav"
};

static const char g_AngerSounds[][] =
{
	"vo/heavy_battlecry03.mp3"
};

#define VESSEL_RANGE 350.0

void OshimunoVesselOnMapStart()
{
	PrecacheSoundArray(g_DeathSounds);
	PrecacheSoundArray(g_HurtSounds);
	PrecacheSoundArray(g_IdleAlertedSounds);
	PrecacheSoundArray(g_MeleeHitSounds);
	PrecacheSoundArray(g_MeleeAttackSounds);
	PrecacheSoundArray(g_AngerSounds);
	NPCData data;
	strcopy(data.Name, sizeof(data.Name), "Spirit Vessel");
	strcopy(data.Plugin, sizeof(data.Plugin), "npc_oshimuno_vessel");
	strcopy(data.Icon, sizeof(data.Icon), "heavy_steelfist");
	data.IconCustom = true;
	data.Flags = 0;
	data.Category = Type_Dancer;
	data.Func = ClotSummon;
	NPC_Add(data);
}

static any ClotSummon(int client, float vecPos[3], float vecAng[3], int team)
{
	return OshimunoVessel(vecPos, vecAng, team);
}

methodmap OshimunoVessel < CClotBody
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
	public void PlayAngerSound()
	{
		EmitSoundToAll(g_AngerSounds[GetRandomInt(0, sizeof(g_AngerSounds) - 1)], this.index, SNDCHAN_AUTO, BOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME);	
	}
	property float m_flLastDamageTaken
	{
		public get()							{ return fl_AbilityOrAttack[this.index][0]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][0] = TempValueForProperty; }
	}
	public OshimunoVessel(float vecPos[3], float vecAng[3], int ally)
	{
		OshimunoVessel npc = view_as<OshimunoVessel>(CClotBody(vecPos, vecAng, "models/player/heavy.mdl", "1.35", "5000", ally));
		
		float gameTime = GetGameTime(npc.index);
		i_NpcWeight[npc.index] = 3;
		npc.SetActivity("ACT_MP_RUN_MELEE");
		KillFeed_SetKillIcon(npc.index, "fists");
		
		npc.m_iBleedType = BLEEDTYPE_NORMAL;
		npc.m_iStepNoiseType = STEPSOUND_NORMAL;
		npc.m_iNpcStepVariation = STEPTYPE_NORMAL;
		

		func_NPCDeath[npc.index] = ClotDeath;
		func_NPCOnTakeDamage[npc.index] = OshimunoVesselOnTakeDamage;
		func_NPCThink[npc.index] = ClotThink;
		
		npc.m_flSpeed = 160.0;
		npc.m_iOverlordComboAttack = 7;
		npc.m_flLastDamageTaken = gameTime + 8.0;

		npc.m_iWearable1 = npc.EquipItem("head", "models/workshop/player/items/all_class/hw2013_the_haunted_hat/hw2013_the_haunted_hat_heavy.mdl");
		NpcColourCosmetic_ViaPaint(npc.m_iWearable1, 2452877);

		npc.m_iWearable2 = npc.EquipItem("head", "models/workshop/player/items/heavy/sum25_fat_friar/sum25_fat_friar.mdl");
		SetEntProp(npc.m_iWearable2, Prop_Send, "m_nSkin", 1);

		npc.m_iWearable3 = npc.EquipItem("head", "models/workshop/player/items/heavy/sum26_barbeque_style2/sum26_barbeque_style2.mdl");
		SetEntProp(npc.m_iWearable3, Prop_Send, "m_nSkin", 1);

		SetEntProp(npc.index, Prop_Send, "m_nSkin", 1);
		SetVariantInt(2);
		AcceptEntityInput(npc.index, "SetBodyGroup");

		npc.StartPathing();
		return npc;
	}
}

static void ClotThink(int iNPC)
{
	OshimunoVessel npc = view_as<OshimunoVessel>(iNPC);

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

		int maxhealth = ReturnEntityMaxHealth(npc.index);
		int health = GetEntProp(npc.index, Prop_Data, "m_iHealth");
		
		if(health < (maxhealth * npc.m_iOverlordComboAttack / 8))
		{
			npc.m_iOverlordComboAttack--;
			npc.PlayAngerSound();

			float vecMe[3]; WorldSpaceCenter(npc.index, vecMe);
			spawnRing_Vectors(vecMe, VESSEL_RANGE, 0.0, 0.0, 15.0, "materials/sprites/laserbeam.vmt", 50, 225, 225, 175, 1, 0.5, 6.0, 0.1, 1, 720.0);
			Explode_Logic_Custom(150.0, -1, npc.index, -1, vecMe, VESSEL_RANGE, _, 0.75, false, _, false, _, VesselOnExplodePost);
		}
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
		OshimunoVesselSelfDefense(npc, distance, vecTarget, gameTime); 
	}
	if(npc.m_flLastDamageTaken < gameTime)
	{
		float healing = float(ReturnEntityMaxHealth(npc.index) / 50); // heal 2% of max health every time
		HealEntityGlobal(npc.index, npc.index, healing, 1.0, 0.0, HEAL_SELFHEAL);
		npc.m_flLastDamageTaken = gameTime + 0.5;
	}
	npc.PlayIdleSound();
}

void OshimunoVesselSelfDefense(OshimunoVessel npc, float distance, float vecTarget[3], float gameTime)
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
					float damage = 90.0;
				
					npc.PlayMeleeHitSound();
					SDKHooks_TakeDamage(target, npc.index, npc.index, damage, DMG_CLUB);
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
			npc.PlayMeleeSound();

			npc.m_flAttackHappens = gameTime + 0.25;
			npc.m_flNextMeleeAttack = gameTime + 1.5;
		}
	}
}

static Action OshimunoVesselOnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	OshimunoVessel npc = view_as<OshimunoVessel>(victim);
	float gameTime = GetGameTime(npc.index);
	if(attacker <= 0)
		return Plugin_Continue;

	if((i_HexCustomDamageTypes[victim] & ZR_DAMAGE_DO_NOT_APPLY_BURN_OR_BLEED)) // reset from any non-debuff or teuton damage
		return Plugin_Continue;

	if(TeutonType[attacker] != TEUTON_NONE)
		return Plugin_Continue;

	npc.m_flLastDamageTaken = gameTime + 8.0;
	CPrintToChatAll("DEBUG: RESET HEALING");
	return Plugin_Changed;
}

public void VesselOnExplodePost(int attacker, int victim, float damage, int weapon)
{
	StatusEffects_SpiritFireAddStuff(victim, 10, 2.5);
}

static void ClotDeath(int entity)
{
	OshimunoVessel npc = view_as<OshimunoVessel>(entity);

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
	
	if(IsValidEntity(npc.m_iWearable9))
		RemoveEntity(npc.m_iWearable9);
}