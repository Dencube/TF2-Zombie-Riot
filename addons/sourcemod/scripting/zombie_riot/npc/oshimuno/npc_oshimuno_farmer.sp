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

#define INITIAL_TREE_SPAWN_COOLDOWN 10.0
#define TREE_SPAWN_COOLDOWN 25.0

void OshimunoFarmerOnMapStart()
{
	PrecacheSoundArray(g_DeathSounds);
	PrecacheSoundArray(g_HurtSounds);
	PrecacheSoundArray(g_IdleAlertedSounds);
	PrecacheSoundArray(g_MeleeHitSounds);
	PrecacheSoundArray(g_MeleeAttackSounds);
	NPCData data;
	strcopy(data.Name, sizeof(data.Name), "Sakurawa");
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
	property float m_flTreeCooldown
	{
		public get()							{ return fl_AbilityOrAttack[this.index][0]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][0] = TempValueForProperty; }
	}
	property float m_flSuperSlash
	{
		public get()							{ return fl_AbilityOrAttack[this.index][1]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][1] = TempValueForProperty; }
	}
	property float m_flSuperSlashInAbility
	{
		public get()							{ return fl_AbilityOrAttack[this.index][2]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][2] = TempValueForProperty; }
	}
	property float m_flSuperSlashInAbilityDo
	{
		public get()							{ return fl_AbilityOrAttack[this.index][3]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][3] = TempValueForProperty; }
	}
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
		OshimunoFarmer npc = view_as<OshimunoFarmer>(CClotBody(vecPos, vecAng, "models/player/engineer.mdl", "1.1", "50000", ally, false, false, true,true));
		float gameTime = GetGameTime(npc.index);
		
		i_NpcWeight[npc.index] = 3;
		npc.SetActivity("ACT_MP_RUN_MELEE");
		KillFeed_SetKillIcon(npc.index, "back_scratcher");
		
		npc.m_iBleedType = BLEEDTYPE_NORMAL;
		npc.m_iStepNoiseType = STEPSOUND_NORMAL;
		npc.m_iNpcStepVariation = STEPTYPE_NORMAL;

		RaidModeTime = gameTime + 180.0;
		RaidBossActive = EntIndexToEntRef(npc.index);
		RaidAllowsBuildings = false;
		RaidAllowLastman = true;
		b_thisNpcIsARaid[npc.index] = true;
		b_ThisNpcIsImmuneToNuke[npc.index] = true;
		npc.Anger = false;
		npc.m_flNextChargeSpecialAttack = gameTime + 25.0;
		npc.m_flSuperSlash = gameTime + 15.0;
		npc.m_flTreeCooldown = gameTime + INITIAL_TREE_SPAWN_COOLDOWN;

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
		SetEntProp(npc.m_iWearable5, Prop_Send, "m_nSkin", 1);
		npc.m_iWearable6 = npc.EquipItem("head", "models/workshop/player/items/all_class/sum24_botler_2000_style1/sum24_botler_2000_style1_engineer.mdl");
		SetEntProp(npc.m_iWearable6, Prop_Send, "m_nSkin", 1);

		SetEntProp(npc.index, Prop_Send, "m_nSkin", 1);
		SetVariantInt(1);
		AcceptEntityInput(npc.index, "SetBodyGroup");

		npc.StartPathing();
		return npc;
	}
}

static int GetTreeCount(int entity)
{
	int TreeCount;
	int a, entity1;
	// Count trees
	while((entity1 = FindEntityByNPC(a)) != -1)
	{
		if(IsValidEntity(entity1) && i_NpcInternalId[entity1] == OshimunoTree_ID() && GetTeam(entity) == GetTeam(entity1))
		{
			TreeCount++;
		}
	}
	return TreeCount;
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
		OshimunoFarmerSelfDefense(npc, distance, vecTarget, gameTime); 
	}
	if(npc.m_flTreeCooldown < gameTime)// spawn trees every 25s
	{
		float pos[3]; GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", pos);
		float ang[3]; GetEntPropVector(npc.index, Prop_Data, "m_angRotation", ang);
		int entity = NPC_CreateByName("npc_oshimuno_tree", -1, pos, ang, GetTeam(npc.index));
		if(entity > MaxClients)
		{
			ConnectWithBeam(npc.index, entity, 245, 180, 255, 3.0, 3.0, 1.35, LASERBEAM);	
			if(GetTeam(npc.index) != TFTeam_Red)
			NpcAddedToZombiesLeftCurrently(entity, true);
		}
		npc.m_flTreeCooldown = gameTime + TREE_SPAWN_COOLDOWN;
	}
	if(GetTreeCount(npc.index) <= 5)// increase stats for every tree alive
	{
	switch(GetTreeCount(npc.index))
		{
			case 1:
			{
				fl_TotalArmor[npc.index] = 0.90;
			}
			case 2:
			{
				fl_TotalArmor[npc.index] = 0.825;
			}
			case 3:
			{
				fl_TotalArmor[npc.index] = 0.75;
				npc.m_flSpeed = 305.0;
			}
			case 4:
			{
				fl_TotalArmor[npc.index] = 0.60;
				npc.m_flSpeed = 310.0;
			}
			case 5:
			{
				fl_TotalArmor[npc.index] = 0.45;
				npc.m_flSpeed = 315.0;
			}
		}
	}
	else if (GetTreeCount(npc.index) >= 6) // beyond 5 trees he gets max buffs
	{
		fl_TotalArmor[npc.index] = 0.33;
		npc.m_flSpeed = 330.0;
	}
	npc.PlayIdleSound();
}

void OshimunoFarmerSelfDefense(OshimunoFarmer npc, float distance, float vecTarget[3], float gameTime)
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
			npc.m_flNextMeleeAttack = gameTime + 0.75;
		}
	}
}

static Action FarmerOnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{	
	if(!b_thisNpcIsARaid[victim])
		return Plugin_Changed;
		
	OshimunoFarmer npc = view_as<OshimunoFarmer>(victim);
	if((ReturnEntityMaxHealth(npc.index)/3) >= GetEntProp(npc.index, Prop_Data, "m_iHealth") && !npc.Anger) //enrage below 33% hp
	{
		npc.Anger = true;
		for(int i=0 ; i < 6 ; i++) //summon 6 trees
		{
			float pos[3]; GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", pos);
			float ang[3]; GetEntPropVector(npc.index, Prop_Data, "m_angRotation", ang);
			int entity = NPC_CreateByName("npc_oshimuno_tree", -1, pos, ang, GetTeam(npc.index));

			if(entity > MaxClients)
			{
				ConnectWithBeam(npc.index, entity, 245, 180, 255, 3.0, 3.0, 1.35, LASERBEAM);
				if(GetTeam(npc.index) != TFTeam_Red)
				NpcAddedToZombiesLeftCurrently(entity, true);
			}
		}
	}

	return Plugin_Changed;
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
/*
#define FARMER_MELEE_SIZE 75
#define FARMER_MELEE_SIZE_F 50.0

bool Farmer_SuperHit(int iNPC)
{
	OshimunoFarmer npc = view_as<OshimunoFarmer>(iNPC);
	if(npc.m_flSuperSlashInAbility)
	{
		if(npc.m_flSuperSlashInAbility > GetGameTime(npc.index))
		{
			npc.m_iTarget = GetClosestTarget(npc.index);
			int EnemyTarget = npc.m_iTarget;
			if(IsValidEnemy(npc.index, EnemyTarget))
			{
				npc.AddGesture("ACT_MP_ATTACK_STAND_MELEE");//He will SMACK you
				float vecTarget[3];
				b_TryToAvoidTraverse[npc.index] = false;
				PredictSubjectPosition(npc, EnemyTarget,_,_, vecTarget);
				vecTarget = GetBehindTarget(EnemyTarget, 60.0 ,vecTarget);
				b_TryToAvoidTraverse[npc.index] = true;

				int red = 244;
				int green = 182;
				int blue = 255;
				int Alpha = 255;

				int colorLayer4[4];
				float diameter = float(FARMER_MELEE_SIZE * 4);
				SetColorRGBA(colorLayer4, red, green, blue, Alpha);
				//we set colours of the differnet laser effects to give it more of an effect
				int colorLayer1[4];
				SetColorRGBA(colorLayer1, colorLayer4[0] * 5 + 765 / 8, colorLayer4[1] * 5 + 765 / 8, colorLayer4[2] * 5 + 765 / 8, Alpha);
				int glowColor[4];
				float VectorStart[3]; GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", VectorStart);
				f3_NpcSavePos[npc.index] = vecTarget;
				npc.FaceTowards(vecTarget, 20000.0);
				float damage = 40.0;
				damage *= RaidModeScaling;

				float vecForward[3], Angles[3];
				GetVectorAnglesTwoPoints(VectorStart, vecTarget, Angles);
				GetAngleVectors(Angles, vecForward, NULL_VECTOR, NULL_VECTOR);				
				DataPack pack = new DataPack();
				pack.WriteCell(EntIndexToEntRef(npc.index));
				pack.WriteFloat(VectorStart[0]);
				pack.WriteFloat(VectorStart[1]);
				pack.WriteFloat(VectorStart[2]);
				pack.WriteFloat(vecTarget[0]);
				pack.WriteFloat(vecTarget[1]);
				pack.WriteFloat(vecTarget[2]);
				pack.WriteFloat(damage);
				pack.WriteCell(0);
				// 66.6 assumes normal tickrate.
				int i_FrameCount = RoundToNearest(0.5 * 66.6);
				RequestFrames(BobInitiatePunch_DamagePart, i_FrameCount, pack);
				for(int BeamCube = 0; BeamCube < 4 ; BeamCube++)
				{
					float OffsetFromMiddle[3];
					switch(BeamCube)
					{
						case 0:
						{
							OffsetFromMiddle = {0.0, FARMER_MELEE_SIZE_F,FARMER_MELEE_SIZE_F};
						}
						case 1:
						{
							OffsetFromMiddle = {0.0, -FARMER_MELEE_SIZE_F,-FARMER_MELEE_SIZE_F};
						}
						case 2:
						{
							OffsetFromMiddle = {0.0, FARMER_MELEE_SIZE_F,-FARMER_MELEE_SIZE_F};
						}
						case 3:
						{
							OffsetFromMiddle = {0.0, -FARMER_MELEE_SIZE_F,FARMER_MELEE_SIZE_F};
						}
					}
					float AnglesEdit[3];
					AnglesEdit[0] = Angles[0];
					AnglesEdit[1] = Angles[1];
					AnglesEdit[2] = Angles[2];

					float VectorStartEdit[3];
					VectorStartEdit[0] = VectorStart[0];
					VectorStartEdit[1] = VectorStart[1];
					VectorStartEdit[2] = VectorStart[2];
					float VectorStartEdit2[3];
					VectorStartEdit2[0] = f3_NpcSavePos[npc.index][0];
					VectorStartEdit2[1] = f3_NpcSavePos[npc.index][1];
					VectorStartEdit2[2] = f3_NpcSavePos[npc.index][2];

					GetBeamDrawStartPoint_Stock(npc.index, VectorStartEdit,OffsetFromMiddle, AnglesEdit);
					GetBeamDrawStartPoint_Stock(npc.index, VectorStartEdit2,OffsetFromMiddle, AnglesEdit);

					SetColorRGBA(glowColor, red, green, blue, Alpha);
					TE_SetupBeamPoints(VectorStartEdit, VectorStartEdit2, Shared_BEAM_Laser, 0, 0, 0, 0.5, ClampBeamWidth(diameter * 0.1), ClampBeamWidth(diameter * 0.1), 0, 0.0, glowColor, 0);
					TE_SendToAll(0.0);
				}
			}

		}
		else
		{
			npc.m_flSuperSlashInAbilityDo = 0.0;
			npc.m_flSuperSlashInAbility = 0.0;
			if(IsValidEntity(npc.m_iWearable8))
				RemoveEntity(npc.m_iWearable8);
			npc.StartPathing();
			npc.m_bisWalking = true;
		}
		return true;
	}
	if(npc.m_flSuperSlash > GetGameTime(npc.index))
		return false;

	npc.AddGesture("ACT_MP_ATTACK_STAND_MELEE");//He will SMACK you
	npc.m_iWearable8 = Trail_Attach(npc.index, ARROW_TRAIL, 255, 1.0, 60.0, 3.0, 5);
	SetEntityRenderColor(npc.m_iWearable8, 0, 0, 0, 255);
	npc.m_flSuperSlashInAbility = GetGameTime(npc.index) + 4.0;
	npc.m_flSuperSlashInAbilityDo = 0.0;
	npc.m_flSuperSlash = GetGameTime(npc.index) + 20.0;
	npc.StopPathing();
	npc.m_bisWalking = false;
	return true;
	
}
*/