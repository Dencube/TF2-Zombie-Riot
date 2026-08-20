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

static char g_MeleeHitSounds[][] = 
{
	"weapons/samurai/tf_katana_slice_01.wav",
	"weapons/samurai/tf_katana_slice_02.wav",
	"weapons/samurai/tf_katana_slice_03.wav",
};

static const char g_MeleeAttackSounds[][] =
{
	"weapons/samurai/tf_katana_01.wav",
	"weapons/samurai/tf_katana_02.wav",
	"weapons/samurai/tf_katana_03.wav",
	"weapons/samurai/tf_katana_04.wav",
	"weapons/samurai/tf_katana_05.wav",
	"weapons/samurai/tf_katana_06.wav",
};

#define CHIMERA_MELEE_SIZE 50
#define CHIMERA_MELEE_SIZE_F 50.0

void OshimunoDemoknightOnMapStart()
{
	PrecacheSoundArray(g_DeathSounds);
	PrecacheSoundArray(g_HurtSounds);
	PrecacheSoundArray(g_IdleAlertedSounds);
	PrecacheSoundArray(g_MeleeHitSounds);
	PrecacheSoundArray(g_MeleeAttackSounds);
	NPCData data;
	strcopy(data.Name, sizeof(data.Name), "Oshimuno Demoknight");
	strcopy(data.Plugin, sizeof(data.Plugin), "npc_oshimuno_demoknight");
	strcopy(data.Icon, sizeof(data.Icon), "victoria_basebreaker");
	data.IconCustom = true;
	data.Flags = 0;
	data.Category = Type_Oshimuno;
	data.Func = ClotSummon;
	NPC_Add(data);
}

static any ClotSummon(int client, float vecPos[3], float vecAng[3], int team)
{
	return OshimunoDemoknight(vecPos, vecAng, team);
}

methodmap OshimunoDemoknight < CClotBody
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
	property float m_flSuperSlash
	{
		public get()							{ return fl_AbilityOrAttack[this.index][7]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][7] = TempValueForProperty; }
	}
	property float m_flSuperSlashInAbility
	{
		public get()							{ return fl_AbilityOrAttack[this.index][8]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][8] = TempValueForProperty; }
	}
	property float m_flSuperSlashInAbilityDo
	{
		public get()							{ return fl_AbilityOrAttack[this.index][9]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][9] = TempValueForProperty; }
	}
	
	public OshimunoDemoknight(float vecPos[3], float vecAng[3], int ally)
	{
		OshimunoDemoknight npc = view_as<OshimunoDemoknight>(CClotBody(vecPos, vecAng, "models/player/demo.mdl", "1.0", "1000", ally));

		i_NpcWeight[npc.index] = 1;
		npc.SetActivity("ACT_MP_RUN_MELEE");
		KillFeed_SetKillIcon(npc.index, "demokatana");
		
		npc.m_iBleedType = BLEEDTYPE_NORMAL;
		npc.m_iStepNoiseType = STEPSOUND_NORMAL;
		npc.m_iNpcStepVariation = STEPTYPE_NORMAL;
		

		func_NPCDeath[npc.index] = ClotDeath;
		func_NPCOnTakeDamage[npc.index] = Generic_OnTakeDamage;
		func_NPCThink[npc.index] = ClotThink;
		
		npc.m_flSpeed = 300.0;
		npc.m_iOverlordComboAttack = 1;

		npc.m_iWearable1 = npc.EquipItem("head", "models/workshop_partner/weapons/c_models/c_shogun_katana/c_shogun_katana.mdl");

		npc.m_iWearable2 = npc.EquipItem("head", "models/workshop/player/items/all_class/hwn2022_onimann/hwn2022_onimann_demo.mdl");
		SetEntProp(npc.m_iWearable2, Prop_Send, "m_nSkin", 1);

		npc.m_iWearable3 = npc.EquipItem("head", "models/workshop/player/items/demo/dec24_commanding_style1/dec24_commanding_style1.mdl");
		SetEntProp(npc.m_iWearable3, Prop_Send, "m_nSkin", 1);

		SetEntProp(npc.index, Prop_Send, "m_nSkin", 1);
		SetVariantInt(12);
		AcceptEntityInput(npc.index, "SetBodyGroup");

		npc.StartPathing();
		return npc;
	}
}

static void ClotThink(int iNPC)
{
	OshimunoDemoknight npc = view_as<OshimunoDemoknight>(iNPC);

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
	if(OshimunoDemoknightDashSlash(iNPC))
		return;

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
		OshimunoDemoknightSelfDefense(npc, distance, vecTarget, gameTime);
		OshimunoDemoknightSpeed(npc, distance, gameTime);
	}

	npc.PlayIdleSound();
}

void OshimunoDemoknightSelfDefense(OshimunoDemoknight npc, float distance, float vecTarget[3], float gameTime)
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
void OshimunoDemoknightSpeed(OshimunoDemoknight npc, float distance, float gameTime)
{
	if(npc.m_iOverlordComboAttack == 1)
	{
		if(distance < (NORMAL_ENEMY_MELEE_RANGE_FLOAT_SQUARED) * 16.0)
		{
			npc.AddGesture("ACT_MP_ATTACK_STAND_MELEE",_,_,_, 0.85);
			npc.m_iOverlordComboAttack = 0;
			npc.m_flNextMeleeAttack = gameTime + 2.0;
			npc.m_flDoingAnimation = gameTime + 1.0;
		}
	} /*
	if(npc.m_flDoingAnimation > gameTime)
	{
		npc.StopPathing();
	}
	if(npc.m_flDoingAnimation < gameTime)
	{
		npc.StartPathing();
	}
	*/
}
bool OshimunoDemoknightDashSlash(int iNPC)
{
	OshimunoDemoknight npc = view_as<OshimunoDemoknight>(iNPC);
	if(npc.m_flSuperSlashInAbility)
	{
		if(npc.m_flSuperSlashInAbility > GetGameTime(npc.index))
		{
			npc.m_iTarget = GetClosestTarget(npc.index);
			int EnemyTarget = npc.m_iTarget;
			if (IsValidEnemy(npc.index, EnemyTarget))
			{
				npc.AddGesture("ACT_MP_ATTACK_STAND_MELEE");//He will SMACK you
				float vecTarget[3];
				b_TryToAvoidTraverse[npc.index] = false;
				PredictSubjectPosition(npc, EnemyTarget,_,_, vecTarget);
				vecTarget = GetBehindTarget(EnemyTarget, 60.0 ,vecTarget);
				b_TryToAvoidTraverse[npc.index] = true;

				int red = 255;
				int green = 255;
				int blue = 255;
				int Alpha = 255;

				int colorLayer4[4];
				float diameter = float(CHIMERA_MELEE_SIZE * 4);
				SetColorRGBA(colorLayer4, red, green, blue, Alpha);
				//we set colours of the differnet laser effects to give it more of an effect
				int colorLayer1[4];
				SetColorRGBA(colorLayer1, colorLayer4[0] * 5 + 765 / 8, colorLayer4[1] * 5 + 765 / 8, colorLayer4[2] * 5 + 765 / 8, Alpha);
				int glowColor[4];
				float VectorStart[3]; GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", VectorStart);
				f3_NpcSavePos[npc.index] = vecTarget;
				npc.FaceTowards(vecTarget, 20000.0);
				float damage = 40.0;
				npc.m_flSuperSlashInAbility = GetGameTime(npc.index) + 0.5;

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
							OffsetFromMiddle = {0.0, CHIMERA_MELEE_SIZE_F,CHIMERA_MELEE_SIZE_F};
						}
						case 1:
						{
							OffsetFromMiddle = {0.0, -CHIMERA_MELEE_SIZE_F,-CHIMERA_MELEE_SIZE_F};
						}
						case 2:
						{
							OffsetFromMiddle = {0.0, CHIMERA_MELEE_SIZE_F,-CHIMERA_MELEE_SIZE_F};
						}
						case 3:
						{
							OffsetFromMiddle = {0.0, -CHIMERA_MELEE_SIZE_F,CHIMERA_MELEE_SIZE_F};
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
	npc.m_flSuperSlash = GetGameTime(npc.index) + 20.0;
	npc.StopPathing();
	npc.m_bisWalking = false;
	return true;
	
}
static void ClotDeath(int entity)
{
	OshimunoDemoknight npc = view_as<OshimunoDemoknight>(entity);

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