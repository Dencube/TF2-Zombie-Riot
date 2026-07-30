#pragma semicolon 1
#pragma newdecls required

static const char g_DeathSounds[][] =
{
	"vo/engineer_paincrticialdeath01.mp3",
	"vo/engineer_paincrticialdeath02.mp3",
	"vo/engineer_paincrticialdeath03.mp3",
};

static const char g_HurtSounds[][] =
{
	"vo/engineer_painsharp01.mp3",
	"vo/engineer_painsharp02.mp3",
	"vo/engineer_painsharp03.mp3",
	"vo/engineer_painsharp04.mp3",
	"vo/engineer_painsharp05.mp3",
	"vo/engineer_painsharp06.mp3",
	"vo/engineer_painsharp07.mp3",
	"vo/engineer_painsharp08.mp3",
};

static const char g_IdleAlertedSounds[][] =
{
	"vo/engineer_meleedare01.mp3",
	"vo/engineer_meleedare02.mp3",
	"vo/engineer_meleedare03.mp3",
};

static const char g_MeleeHitSounds[][] =
{
	"weapons/cbar_hit1.wav",
	"weapons/cbar_hit2.wav"
};

static const char g_MeleeAttackSounds[][] =
{
	"weapons/machete_swing.wav",
};

void OshimunoFarmerOnMapStart()
{
	PrecacheSoundArray(g_DeathSounds);
	PrecacheSoundArray(g_HurtSounds);
	PrecacheSoundArray(g_IdleAlertedSounds);
	PrecacheSoundArray(g_MeleeHitSounds);
	PrecacheSoundArray(g_MeleeAttackSounds);
	NPCData data;
	strcopy(data.Name, sizeof(data.Name), "Oshimuno Farmer");
	strcopy(data.Plugin, sizeof(data.Plugin), "npc_oshimuno_farmer");
	strcopy(data.Icon, sizeof(data.Icon), "victoria_basebreaker");
	data.IconCustom = true;
	data.Flags = MVM_CLASS_FLAG_MINIBOSS|MVM_CLASS_FLAG_ALWAYSCRIT;
	data.Category = Type_Raid;
	data.Func = ClotSummon;
	NPC_Add(data);
}

static any ClotSummon(int client, float vecPos[3], float vecAng[3], int team, const char[] data)
{
	return OshimunoFarmer(vecPos, vecAng, team, data);
}

methodmap OshimunoFarmer < CClotBody
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
	
	public OshimunoFarmer(float vecPos[3], float vecAng[3], int ally, const char[] data)
	{
		OshimunoFarmer npc = view_as<OshimunoFarmer>(CClotBody(vecPos, vecAng, "models/player/engineer.mdl", "1.1", "40000", ally, false, false, true,true));
		
		i_NpcWeight[npc.index] = 3;
		npc.SetActivity("ACT_MP_RUN_MELEE");
		KillFeed_SetKillIcon(npc.index, "back_scratcher");
		
		npc.m_iBleedType = BLEEDTYPE_NORMAL;
		npc.m_iStepNoiseType = STEPSOUND_NORMAL;
		npc.m_iNpcStepVariation = STEPTYPE_NORMAL;

		RaidModeTime = GetGameTime(npc.index) + 180.0;
		RaidBossActive = EntIndexToEntRef(npc.index);
		RaidAllowsBuildings = false;
		RaidAllowLastman = true;
		b_thisNpcIsARaid[npc.index] = true;
		b_ThisNpcIsImmuneToNuke[npc.index] = true;
		npc.Anger = false;
		npc.m_flNextChargeSpecialAttack = GetGameTime(npc.index) + 25.0;

		func_NPCDeath[npc.index] = ClotDeath;
		func_NPCOnTakeDamage[npc.index] = FarmerOnTakeDamage;
		func_NPCThink[npc.index] = ClotThink;
		
		npc.m_flSpeed = 300.0;
		npc.m_flMeleeArmor = 1.25;

		char buffers[3][64];
		ExplodeString(data, ";", buffers, sizeof(buffers), sizeof(buffers[]));
		//the very first and 2nd char are SC for scaling
		if(buffers[0][0] == 's' && buffers[0][1] == 'c')
		{
			//remove SC
			ReplaceString(buffers[0], 64, "sc", "");
			float value = StringToFloat(buffers[0]);
			RaidModeScaling = value;
			if(RaidModeScaling < 35)
			{
				RaidModeScaling *= 0.25;
			}
			else
			{
				RaidModeScaling *= 0.5;
			}
			if(value > 40.0)
			{
				RaidModeScaling *= 0.85;
			}
		}
		else
		{	
			RaidModeScaling = float(Waves_GetRoundScale()+1);
			if(RaidModeScaling < 35)
			{
				RaidModeScaling *= 0.25;
			}
			else
			{
				RaidModeScaling *= 0.5;
			}
			if(Waves_GetRoundScale()+1 > 25)
			{
				RaidModeScaling *= 0.85;
			}
		}
		float amount_of_people = ZRStocks_PlayerScalingDynamic();
		if(amount_of_people > 12.0)
		{
			amount_of_people = 12.0;
		}
		amount_of_people *= 0.12;
		
		if(amount_of_people < 1.0)
		{
			amount_of_people = 1.0;
		}
		RaidModeScaling *= amount_of_people;

		npc.m_iWearable1 = npc.EquipItem("head", "models/workshop/weapons/c_models/c_back_scratcher/c_back_scratcher.mdl");
		npc.m_iWearable2 = npc.EquipItem("head", "models/workshop/player/items/engineer/sum26_standing_offer/sum26_standing_offer.mdl");
		SetEntProp(npc.m_iWearable2, Prop_Send, "m_nSkin", 1);
		npc.m_iWearable3 = npc.EquipItem("head", "models/workshop/player/items/all_class/sum26_beachcombers/sum26_beachcombers_engineer.mdl");
		npc.m_iWearable4 = npc.EquipItem("head", "models/workshop/player/items/engineer/dec18_wise_whiskers/dec18_wise_whiskers.mdl");
		npc.m_iWearable5 = npc.EquipItem("head", "models/workshop/player/items/engineer/all_work_and_no_plaid/all_work_and_no_plaid.mdl");
		npc.m_iWearable6 = npc.EquipItem("head", "models/workshop/player/items/all_class/sum24_botler_2000_style1/sum24_botler_2000_style1_engineer.mdl");
		SetEntProp(npc.m_iWearable6, Prop_Send, "m_nSkin", 1);

		SetEntProp(npc.index, Prop_Send, "m_nSkin", 1);
		SetVariantInt(2);
		AcceptEntityInput(npc.index, "SetBodyGroup");

		npc.StartPathing();
		return npc;
	}
}

static void NPCTalkMessage(int iNPC, const char[] message) // temp remove later
{
	PrintNPCMessageWithPrefixes(iNPC, "lightblue", message);
}

static int GetTreeCount(int entity)
{
	int count;
	int a, entity1;
	// Count trees
	while((entity1 = FindEntityByNPC(a)) != -1)
	{
		if(IsValidEntity(entity1) && i_NpcInternalId[entity1] == CherryBlossom_ID() && GetTeam(entity) == GetTeam(entity1))
		{
			count++;
		}
	}
	return count;
}

static void ClotThink(int iNPC)
{
	OshimunoFarmer npc = view_as<OshimunoFarmer>(iNPC);

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
	if((npc.Anger)) 
	{
		
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
		OshimunoFarmer_SelfDefense(npc, distance, vecTarget, gameTime); 
	}
	if(GetTreeCount(npc.index) <= 5)// increase stats for every tree alive || TODO: add a way to count the trees currently alive
	{
	switch(GetTreeCount(npc.index))
		{
			case 1:
			{
				NPCTalkMessage(npc.index, "{purple}VOID{default}, GRANT ME STRENGTH!");
			}
			case 2:
			{
				NPCTalkMessage(npc.index, "You think you won? I'M JUST GETTING STARTED.");
			}
			case 3:
			{
				NPCTalkMessage(npc.index, "Remember those cats? {crimson} You're about to get it worse.");
			}
			case 4:
			{
				NPCTalkMessage(npc.index, "{crimson} DEATH TO MY ENEMIES!!!.");
			}
			case 5:
			{
				NPCTalkMessage(npc.index, "{crimson} DIE ALREADY!!!");
			}
		}
	}
	else if (GetTreeCount(npc.index) >= 6) // beyond 5 trees he gets max buffs
	{
		NPCTalkMessage(npc.index, "{crimson} YOU FUCKED UP BIG TIME!!!"); 
	}
	npc.PlayIdleSound();
}

void OshimunoFarmer_SelfDefense(OshimunoFarmer npc, float distance, float vecTarget[3], float gameTime)
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
					npc.PlayMeleeHitSound();
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

			npc.AddGesture("ACT_MP_ATTACK_STAND_MELEE",_,_,_, 0.85);
			npc.PlayMeleeSound();
			
			npc.m_flAttackHappens = gameTime + 1.0;
			npc.m_flNextMeleeAttack = gameTime + 0.75;
		}
	}
}

static Action FarmerOnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{	
	if(!b_thisNpcIsARaid[victim])
		return;
		
	OshimunoFarmer npc = view_as<OshimunoFarmer>(victim);
	if((ReturnEntityMaxHealth(npc.index)/3) >= GetEntProp(npc.index, Prop_Data, "m_iHealth") && !npc.Anger) //enrage below 33% hp
	{
		npc.Anger = true;
		for(int i=0 ; i < 6 ; i++) //summon 6 trees || TODO: add more effects or something so the trees spawning in is more obvious
		{
			float pos[3]; GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", pos);
			float ang[3]; GetEntPropVector(npc.index, Prop_Data, "m_angRotation", ang);
			int entity = NPC_CreateByName("npc_cherry_blossom", -1, pos, ang, GetTeam(npc.index));

			if(entity > MaxClients)
			{
				
				if(GetTeam(npc.index) != TFTeam_Red)
				NpcAddedToZombiesLeftCurrently(entity, true);
				view_as<CClotBody>(entity).m_flSpeed = npc.m_flSpeed;
			}
		}
	}
	return;
}
static void ClotDeath(int entity)
{
	OshimunoFarmer npc = view_as<OshimunoFarmer>(entity);

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
}