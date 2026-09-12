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


int OshimunoAntayotoId;
int OshimunoAntayotoIDReturn()
{
	return OshimunoAntayotoId;
}

void OshimunoAntayotoOnMapStart()
{
	PrecacheSoundArray(g_DeathSounds);
	PrecacheSoundArray(g_HurtSounds);
	PrecacheSoundArray(g_IdleAlertedSounds);
	PrecacheSoundArray(g_MeleeHitSounds);
	PrecacheSoundArray(g_MeleeAttackSounds);
	PrecacheSoundCustom("#zombiesurvival/aprilfools/reteptheme_1.mp3");
	NPCData data;
	strcopy(data.Name, sizeof(data.Name), "Antayoto");
	strcopy(data.Plugin, sizeof(data.Plugin), "npc_oshimuno_antayoto");
	strcopy(data.Icon, sizeof(data.Icon), "blackheavysoul");
	data.IconCustom = true;
	data.Flags = MVM_CLASS_FLAG_MINIBOSS|MVM_CLASS_FLAG_ALWAYSCRIT;
	data.Category = Type_Raid;
	data.Func = ClotSummon;
	OshimunoAntayotoId = NPC_Add(data);
}
 
static any ClotSummon(int client, float vecPos[3], float vecAng[3], int team, const char[] data)
{
	return OshimunoAntayoto(vecPos, vecAng, team, data);
}

methodmap OshimunoAntayoto < CClotBody
{
	property float m_flConeWindUp
	{
		public get()							{ return fl_NextChargeSpecialAttack[this.index]; }
		public set(float TempValueForProperty) 	{ fl_NextChargeSpecialAttack[this.index] = TempValueForProperty; }
	}
	property float m_flConeSlashCD
	{
		public get()							{ return fl_AbilityOrAttack[this.index][0]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][0] = TempValueForProperty; }
	}
	property float m_flBombThrowCD
	{
		public get()							{ return fl_AbilityOrAttack[this.index][1]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][1] = TempValueForProperty; }
	}
	property float m_flTeleportAwayCD
	{
		public get()							{ return fl_AbilityOrAttack[this.index][2]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][2] = TempValueForProperty; }
	}
	property int m_iWhatAbilityDo
	{
		public get()							{ return i_MedkitAnnoyance[this.index]; }
		public set(int TempValueForProperty) 	{ i_MedkitAnnoyance[this.index] = TempValueForProperty; }
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
	
	public OshimunoAntayoto(float vecPos[3], float vecAng[3], int ally, const char[] data)
	{
		OshimunoAntayoto npc = view_as<OshimunoAntayoto>(CClotBody(vecPos, vecAng, "models/player/spy.mdl", "1.15", "40000", ally, false, true, true,true)); //giant!
		float gameTime = GetGameTime(npc.index);

		i_NpcWeight[npc.index] = 3;
		KillFeed_SetKillIcon(npc.index, "back_scratcher");
		
		int iActivity = npc.LookupActivity("ACT_MP_RUN_MELEE");
		if(iActivity > 0) npc.StartActivity(iActivity);

		npc.m_iWearable1 = npc.EquipItem("head", "models/workshop_partner/weapons/c_models/c_shogun_kunai/c_shogun_kunai.mdl");
		npc.m_iWearable2 = npc.EquipItem("head", "models/player/items/spy/spy_rose.mdl");
		SetEntProp(npc.m_iWearable2, Prop_Send, "m_nSkin", 1);
		npc.m_iWearable3 = npc.EquipItem("head", "models/workshop/player/items/all_class/fall2013_hong_kong_cone/fall2013_hong_kong_cone_spy.mdl");
		SetEntProp(npc.m_iWearable3, Prop_Send, "m_nSkin", 1);
		npc.m_iWearable4 = npc.EquipItem("head", "models/workshop/player/items/all_class/spr18_robin_walkers/spr18_robin_walkers_spy.mdl");
		SetEntProp(npc.m_iWearable4, Prop_Send, "m_nSkin", 1);
		npc.m_iWearable5 = npc.EquipItem("head", "models/workshop/player/items/spy/sum24_tuxedo_royale_style1/sum24_tuxedo_royale_style1.mdl");
		SetEntProp(npc.m_iWearable5, Prop_Send, "m_nSkin", 1);
		npc.m_iWearable6 = npc.EquipItem("head", "models/workshop/player/items/spy/dec25_aristocravat/dec25_aristocravat.mdl");
		SetEntProp(npc.m_iWearable6, Prop_Send, "m_nSkin", 1);

		SetEntProp(npc.index, Prop_Send, "m_nSkin", 1);
		SetVariantInt(2);
		AcceptEntityInput(npc.index, "SetBodyGroup");
		
		npc.m_flNextMeleeAttack = 0.0;
		
		npc.m_iBleedType = BLEEDTYPE_NORMAL;
		npc.m_iStepNoiseType = STEPSOUND_GIANT;	
		npc.m_iNpcStepVariation = STEPTYPE_NORMAL;
		npc.m_flMeleeArmor = 1.25;	
		
		func_NPCDeath[npc.index] = OshimunoAntayoto_Death;
		func_NPCOnTakeDamage[npc.index] = OshimunoAntayoto_OnTakeDamage;
		func_NPCThink[npc.index] = OshimunoAntayoto_Think;
		func_NPCFuncWin[npc.index] = OshimunoAntayoto_Win;

		RaidModeTime = GetGameTime(npc.index) + 200.0;
		RaidBossActive = EntIndexToEntRef(npc.index);
		RaidAllowsBuildings = false;
		RaidAllowLastman = true;
		
		MusicEnum music;
		strcopy(music.Path, sizeof(music.Path), "#zombiesurvival/aprilfools/reteptheme_1.mp3");
		music.Time = 110;
		music.Volume = 2.0;
		music.Custom = true;
		strcopy(music.Name, sizeof(music.Name), "Retep theme");
		strcopy(music.Artist, sizeof(music.Artist), "terraria peter griffin mod");
		Music_SetRaidMusic(music);

		NPCTalkMessage(npc.index, "You come here and threaten my world!? I will take you down!");
		NPCTalkMessage(npc.index, "These Heavy souls are fake and evil! They do nothing except hurt!");
		NPCTalkMessage(npc.index, "My own world was threatened by them, them and Smith...");

		WaveStart_SubWaveStart(GetGameTime() + 500.0);
		GiveOneRevive();
		RemoveAllDamageAddition();
		npc.StartPathing();
		npc.m_flSpeed = 320.0;

		BlockLoseSay = false;
		
		EmitSoundToAll("npc/zombie_poison/pz_alert1.wav", _, _, _, _, 1.0);	
		EmitSoundToAll("npc/zombie_poison/pz_alert1.wav", _, _, _, _, 1.0);	
		b_thisNpcIsARaid[npc.index] = true;
		b_angered_twice[npc.index] = false;
		for(int client_clear=1; client_clear<=MaxClients; client_clear++)
		{
			fl_AlreadyStrippedMusic[client_clear] = 0.0; //reset to 0
		}
		bool final = StrContains(data, "final_item") != -1;
		
		if(final)
		{
			i_RaidGrantExtra[npc.index] = 6;
		}
		for(int client_check=1; client_check<=MaxClients; client_check++)
		{
			if(IsClientInGame(client_check) && !IsFakeClient(client_check))
			{
				LookAtTarget(client_check, npc.index);
				SetGlobalTransTarget(client_check);
				ShowGameText(client_check, "item_armor", 1, "%t", "Antayoto Arrived");
			}
		}
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
				RaidModeScaling *= 0.25; //abit low, inreacing
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
				RaidModeScaling *= 0.25; //abit low, inreacing
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
			amount_of_people = 1.0;
		
		RaidModeScaling *= amount_of_people; //More then 9 and he raidboss gets some troubles, bufffffffff
		npc.m_flConeSlashCD = gameTime + 5.0;
		/*
		npc.m_flCongaFastDo = GetGameTime() + 20.0;
		npc.m_flJumpAtEnemy = GetGameTime() + 10.0;

		if(StrContains(data, "jump_test") != -1)
		{
			npc.m_flPowAbilityCD = GetGameTime() + 99999.9;
			npc.m_flCongaFastDo = GetGameTime() + 9999.9;
			npc.m_flJumpAtEnemy = GetGameTime() + 2.5;	
		}
		if(StrContains(data, "timeout") != -1)
		{
			RaidModeTime = GetGameTime() + 10.0;
		}
		*/
		return npc;
	}
}

static void NPCTalkMessage(int entity, const char[] message)
{
	PrintNPCMessageWithPrefixes(entity, "black", message);
}

static void OshimunoAntayoto_Think(int iNPC)
{
	OshimunoAntayoto npc = view_as<OshimunoAntayoto>(iNPC);
	float gameTime = GetGameTime(npc.index);
	if(npc.m_flNextDelayTime > GetGameTime(npc.index))
	{
		return;
	}
	if(IsValidEntity(npc.m_iWearable3))
	{
		float flPos[3]; // original
		float flAng[3]; // original
		GetAttachment(npc.index, "head", flPos, flAng);
		flPos[2] -= 10.0;
		Custom_SDKCall_SetLocalOrigin(npc.m_iWearable3, flPos);
		SetEntPropVector(npc.m_iWearable3, Prop_Data, "m_angRotation", flAng);
	}
	npc.m_flNextDelayTime = GetGameTime(npc.index) + DEFAULT_UPDATE_DELAY_FLOAT;
	npc.Update();

	if(LastMann)
	{
		if(!npc.m_fbGunout)
		{
			npc.m_fbGunout = true;
			NPCTalkMessage(npc.index, "Last Noob Left.");
		}
	}
	if(i_RaidGrantExtra[npc.index] == RAIDITEM_INDEX_WIN_COND)
	{
		npc.m_bisWalking = false;
		npc.AddActivityViaSequence("selectionMenu_Idle");
		npc.SetCycle(0.01);
		func_NPCThink[npc.index] = INVALID_FUNCTION;
		
		NPCTalkMessage(npc.index, "GG EZs.");
		return;

	}	
	int target = npc.m_iTarget;
	if(i_Target[npc.index] != -1 && !IsValidEnemy(npc.index, target))
		i_Target[npc.index] = -1;
	
	if(i_Target[npc.index] == -1 || npc.m_flGetClosestTargetTime < GetGameTime(npc.index))
	{
		target = GetClosestTarget(npc.index);
		npc.m_iTarget = target;
		npc.m_flGetClosestTargetTime = GetGameTime(npc.index) + GetRandomRetargetTime();
	}
	if(BlackHeavy_Transform(npc))
		return;
	npc.PlayIdleAlertSound();
	if(Black_Heavy_PowDo(npc, GetGameTime(npc.index)))
	{
		return;
	}
	if(Black_Heavy_CongaVeryFastDo(npc, GetGameTime(npc.index)))
	{
		return;
	}
	if(Black_Heavy_JumpOfDeath(npc, GetGameTime(npc.index)))
	{
		return;
	}
	
	if(!BlockLoseSay && RaidModeTime < GetGameTime())
	{
		MusicEnum music;
		strcopy(music.Path, sizeof(music.Path), "#zombiesurvival/aprilfools/black_heavy_ultra.mp3");
		music.Time = 167;
		music.Volume = 1.1;
		music.Custom = true;
		strcopy(music.Name, sizeof(music.Name), "Ultra Instinct Theme");
		strcopy(music.Artist, sizeof(music.Artist), "Dragon Ball Super");
		Music_SetRaidMusic(music);
		ApplyStatusEffect(npc.index, npc.index, "Perfected Instinct", 999999.9);
		fl_Extra_Speed[npc.index] 	*= 1.25;
		if(!npc.Anger)
		{
			fl_TotalArmor[npc.index] *= 0.5;
			f_AttackSpeedNpcIncrease[npc.index] *= 0.65;
		}
		npc.Anger = true;
		RaidModeTime = FAR_FUTURE;
		f_AttackSpeedNpcIncrease[npc.index] *= 0.85;
		RaidModeScaling *= 1.5;
		b_NpcUnableToDie[npc.index] = false;
		strcopy(c_NpcName[npc.index], sizeof(c_NpcName[]), "Black Heavy Soul");
		if(IsValidEntity(npc.m_iWearable2))
			RemoveEntity(npc.m_iWearable2);
		if(IsValidEntity(npc.m_iWearable7))
			RemoveEntity(npc.m_iWearable7);
		if(IsValidEntity(npc.m_iWearable3))
			RemoveEntity(npc.m_iWearable3);
		if(IsValidEntity(npc.m_iWearable6))
			RemoveEntity(npc.m_iWearable6);
			
		npc.m_iWearable2 = npc.EquipItem("head", "models/workshop/player/items/medic/hwn2023_power_spike/hwn2023_power_spike.mdl",_,_, 1.0);
	}

	
	if(npc.m_blPlayHurtAnimation)
	{
		npc.AddGesture("ACT_MP_GESTURE_FLINCH_CHEST", false);
		npc.m_blPlayHurtAnimation = false;
		npc.PlayHurtSound();
	}

/*
	if(npc.m_flNextThinkTime > GetGameTime(npc.index))
	{
		return;
	}

	npc.m_flNextThinkTime = GetGameTime(npc.index) + 0.1;
*/
	if(!IsValidEntity(RaidBossActive))
	{
		RaidBossActive = EntIndexToEntRef(npc.index);
	}

	if(npc.m_flGetClosestTargetTime < GetGameTime(npc.index))
	{
		npc.m_iTarget = GetClosestTarget(npc.index);
		npc.m_flGetClosestTargetTime = GetGameTime(npc.index) + GetRandomRetargetTime();
	}
	
	if(IsValidEnemy(npc.index, npc.m_iTarget))
	{
		float vecTarget[3]; WorldSpaceCenter(npc.m_iTarget, vecTarget );
		float VecSelfNpc[3]; WorldSpaceCenter(npc.index, VecSelfNpc);
		float flDistanceToTarget = GetVectorDistance(vecTarget, VecSelfNpc, true);
		int SetGoalVectorIndex = 0;
		SetGoalVectorIndex = OshimunoAntayoto_SelfDefense(npc,GetGameTime(npc.index), npc.m_iTarget, flDistanceToTarget); 

		switch(SetGoalVectorIndex)
		{
			case 0:
			{
				npc.m_bAllowBackWalking = false;
				//Get the normal prediction code.
				if(flDistanceToTarget < npc.GetLeadRadius()) 
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

	if(npc.m_flDoingAnimation < GetGameTime(npc.index))
	{
		OshimunoAntayotoAnimationChange(npc);
	}
}

static Action OshimunoAntayoto_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	OshimunoAntayoto npc = view_as<OshimunoAntayoto>(victim);
		
	if(attacker <= 0)
		return Plugin_Continue;

	if(npc.m_flHeadshotCooldown < GetGameTime(npc.index))
	{
		npc.m_flHeadshotCooldown = GetGameTime(npc.index) + DEFAULT_HURTDELAY;
		npc.m_blPlayHurtAnimation = true;
	}
	return Plugin_Changed;
}
public void OshimunoAntayoto_Win(int entity)
{
	i_RaidGrantExtra[entity] = RAIDITEM_INDEX_WIN_COND;
	BlockLoseSay = true;
	NPCTalkMessage(entity, "get owned.");
}

static void OshimunoAntayoto_Death(int entity)
{
	RaidBossActive = INVALID_ENT_REFERENCE;
	if(BlockLoseSay)
		return;

	NPCTalkMessage(entity, "Nvm fuck you i made it all up.");
	NPCTalkMessage(entity, "*dies of death*");
}

void OshimunoAntayotoAnimationChange(OshimunoAntayoto npc)
{
	
	if(npc.m_iChanged_WalkCycle == 0)
	{
		npc.m_iChanged_WalkCycle = -1;
	}

	if(npc.IsOnGround())
	{
		if(npc.m_iChanged_WalkCycle != 3)
		{
			npc.m_flSpeed = 320.0;
			npc.m_bisWalking = true;
			npc.m_iChanged_WalkCycle = 3;
			npc.SetActivity("ACT_MP_RUN_MELEE");
			npc.StartPathing();
		}	
	}
	else
	{
		if(npc.m_iChanged_WalkCycle != 4)
		{
			npc.m_flSpeed = 320.0;
			npc.m_bisWalking = false;
			npc.m_iChanged_WalkCycle = 4;
			npc.SetActivity("ACT_MP_JUMP_FLOAT_MELEE");
			npc.StartPathing();
		}	
	}

}

int OshimunoAntayoto_SelfDefense(OshimunoAntayoto npc, float gameTime, int target, float distance)
{
	if(npc.m_iWhatAbilityDo == 2)
	{	
		return 0;
	}
	if(npc.m_flAttackHappens)
	{
		if(npc.m_flAttackHappens < GetGameTime(npc.index))
		{
			npc.m_flAttackHappens = 0.0;
			
			if(IsValidEnemy(npc.index, target))
			{
				int HowManyEnemeisAoeMelee = 64;
				Handle swingTrace;
				float VecEnemy[3]; WorldSpaceCenter(npc.m_iTarget, VecEnemy);
				npc.FaceTowards(VecEnemy, 15000.0);
				npc.DoSwingTrace(swingTrace, npc.m_iTarget,_,_,_,1,_,HowManyEnemeisAoeMelee);
				delete swingTrace;
				bool PlaySound = false;
				for(int counter = 1; counter <= HowManyEnemeisAoeMelee; counter++)
				{
					if(i_EntitiesHitAoeSwing_NpcSwing[counter] > 0)
					{
						if(IsValidEntity(i_EntitiesHitAoeSwing_NpcSwing[counter]))
						{
							PlaySound = true;
							int targetTrace = i_EntitiesHitAoeSwing_NpcSwing[counter];
							float vecHit[3];
							
							WorldSpaceCenter(targetTrace, vecHit);

							float damage = 12.0;

							SDKHooks_TakeDamage(targetTrace, npc.index, npc.index, damage * RaidModeScaling, DMG_CLUB, -1, _, vecHit);								

							
							bool Knocked = false;
										
							if(IsValidClient(targetTrace))
							{
								if (IsInvuln(targetTrace))
								{
									Knocked = true;
									Custom_Knockback(npc.index, targetTrace, 900.0, true);
									TF2_AddCondition(targetTrace, TFCond_LostFooting, 0.5);
									TF2_AddCondition(targetTrace, TFCond_AirCurrent, 0.5);
								}
							}		
							if(!Knocked)
								Custom_Knockback(npc.index, targetTrace, 250.0, true); 
						} 
					}
				}
				if(PlaySound)
				{
					npc.PlayMeleeHitSound();
				}
			}
		}
	}
	//Melee attack, last prio
	else if(GetGameTime(npc.index) > npc.m_flNextMeleeAttack)
	{
		if(IsValidEnemy(npc.index, target)) 
		{
			if(distance < (GIANT_ENEMY_MELEE_RANGE_FLOAT_SQUARED))
			{
				int Enemy_I_See;
									
				Enemy_I_See = Can_I_See_Enemy(npc.index, target);
						
				if(IsValidEntity(Enemy_I_See) && IsValidEnemy(npc.index, Enemy_I_See))
				{
					target = Enemy_I_See;

					npc.PlayMeleeSound();
					npc.AddGesture("ACT_MP_ATTACK_STAND_MELEE",_,_,_,3.0);
							
					npc.m_flAttackHappens = gameTime + 0.1;
					npc.m_flNextMeleeAttack = gameTime + 0.15;
					npc.m_flDoingAnimation = gameTime + 0.1;
				}
			}
		}
		else
		{
			npc.m_flGetClosestTargetTime = 0.0;
			npc.m_iTarget = GetClosestTarget(npc.index);
		}	
	}
	return 0;
}

/*
bool OshimunoAntayoto_Transform(OshimunoAntayoto npc)
{
	if(!npc.m_flTransformIn)
		return false;

	if(npc.m_flTransformIn < GetGameTime())
	{			
		b_CannotBeHeadshot[npc.index] = false;
		b_CannotBeBackstabbed[npc.index] = false;
		b_NpcIsInvulnerable[npc.index] = false; //Special huds for invul targets
		npc.m_bisWalking = true;
		npc.StartPathing();
		npc.m_flTransformIn = 0.0;
		return false;
	}
	if(npc.m_flTransformIn < GetGameTime() + 1.75)
	{
		if(npc.m_iChanged_WalkCycle != 101)
		{
			npc.m_iSaiyanState = 1;
			HealEntityGlobal(npc.index, npc.index, ReturnEntityMaxHealth(npc.index) / 2.0, _, 4.0, HEAL_ABSOLUTE);
			RaidModeScaling *= 1.05;
			NPCTalkMessage(npc.index, "{crimson}AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA");
			NPCTalkMessage(npc.index, "{crimson}AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA");
			NPCTalkMessage(npc.index, "{crimson}AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA");
			NPCTalkMessage(npc.index, "{crimson}AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA");
			NPCTalkMessage(npc.index, "{crimson}AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA");
			NPCTalkMessage(npc.index, "{crimson}AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA");
			NPCTalkMessage(npc.index, "{crimson}AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA");
			NPCTalkMessage(npc.index, "{crimson}AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA");
			NPCTalkMessage(npc.index, "{crimson}AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA");
			NPCTalkMessage(npc.index, "{crimson}AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA");
			NPCTalkMessage(npc.index, "{crimson}AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA");
			NPCTalkMessage(npc.index, "{crimson}AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA");
			NPCTalkMessage(npc.index, "{crimson}AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA");
			NPCTalkMessage(npc.index, "{crimson}AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA");
			NPCTalkMessage(npc.index, "{crimson}AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA");
			NPCTalkMessage(npc.index, "{crimson}AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA");
			NPCTalkMessage(npc.index, "{crimson}AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA");
			NPCTalkMessage(npc.index, "{crimson}AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA");
			NPCTalkMessage(npc.index, "{crimson}AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA");
			NPCTalkMessage(npc.index, "{crimson}AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA");
			fl_Extra_Speed[npc.index] *= 1.05;
			SetVariantColor(view_as<int>({255, 255, 0, 200}));
			AcceptEntityInput(npc.m_iTeamGlow, "SetGlowColor");
			strcopy(c_NpcName[npc.index], sizeof(c_NpcName[]), "Super Saiyan Black Heavy Soul");
			float pos[3]; GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", pos);
			pos[2] += 10.0;
			TE_Particle("Explosion_ShockWave_01", pos, NULL_VECTOR, NULL_VECTOR, _, _, _, _, _, _, _, _, _, _, 0.0);
			TE_Particle("grenade_smoke_cycle", pos, NULL_VECTOR, NULL_VECTOR, _, _, _, _, _, _, _, _, _, _, 0.0);
			TE_Particle("hammer_bell_ring_shockwave", pos, NULL_VECTOR, NULL_VECTOR, _, _, _, _, _, _, _, _, _, _, 0.0);
			CreateEarthquake(pos, 1.0, 2000.0, 16.0, 255.0);
			spawnRing_Vectors(pos, 0.0, 0.0, 0.0, 0.0, "materials/sprites/combineball_trail_black_1.vmt", 185, 80, 185, 255, 1, 1.0, 80.0, 4.0, 1, 5000.0);
			spawnRing_Vectors(pos, 0.0, 0.0, 0.0, 0.0, "materials/sprites/combineball_trail_black_1.vmt", 185, 80, 185, 255, 1,=2.0, 80.0, 4.0, 1, 5000.0);	
			spawnRing_Vectors(pos, 0.0, 0.0, 0.0, 0.0, "materials/sprites/combineball_trail_black_1.vmt", 185, 80, 185, 255, 1,= 3.0, 80.0, 4.0, 1, 5000.0);	
			if(IsValidEntity(npc.m_iWearable2))
				RemoveEntity(npc.m_iWearable2);
			npc.m_iWearable2 = npc.EquipItem("head", "models/workshop/player/items/medic/hwn2023_power_spike/hwn2023_power_spike.mdl",_,_, 1.5);
			SetEntityRenderColor(npc.m_iWearable2, 255, 255, 0, 255);
			NpcColourCosmetic_ViaPaint(npc.m_iWearable2, 15185211);
			Explode_Logic_Custom(50.0, 0, npc.index, -1, pos ,1000.0, 1.0, _, true, .FunctionToCallOnHit = SsjBlackHeavy_KnockbackDo);
		
			float flPos[3]; // original
			npc.GetAttachment("", flPos, NULL_VECTOR);
			npc.m_iWearable7 = ParticleEffectAt_Parent(flPos, "utaunt_poweraura_yellow_parent", npc.index, "", {0.0,0.0,0.0});
			f_AttackSpeedNpcIncrease[npc.index] *= 0.65;
			fl_TotalArmor[npc.index] *= 0.65;
			npc.SetPlaybackRate(1.35);

			npc.m_iChanged_WalkCycle = 101;
		}
		return true;
	}
	if(npc.m_iChanged_WalkCycle != 100)
	{
		MusicEnum music;
		strcopy(music.Path, sizeof(music.Path), "#zombiesurvival/aprilfools/black_heavy_2.mp3");
		music.Time = 213;
		music.Volume = 1.1;
		music.Custom = true;
		strcopy(music.Name, sizeof(music.Name), "Flow Hero Song of Hope");
		strcopy(music.Artist, sizeof(music.Artist), "Dragon Ball Z: Battle Of Gods ED");
		Music_SetRaidMusic(music);
		for(int client=1; client<=MaxClients; client++)
		{
			if(IsClientInGame(client))
			{
				SetMusicTimer(client, GetTime() + 5);
			}
		}
		npc.m_bisWalking = false;
		npc.m_iChanged_WalkCycle = 100;
		npc.StopPathing();
		b_NpcIsInvulnerable[npc.index] = true; //Special huds for invul targets
		b_CannotBeHeadshot[npc.index] = true;
		b_CannotBeBackstabbed[npc.index] = true;
		ApplyStatusEffect(npc.index, npc.index, "Clear Head", 6.0);	
		ApplyStatusEffect(npc.index, npc.index, "Solid Stance", 6.0);	
		ApplyStatusEffect(npc.index, npc.index, "Fluid Movement", 6.0);	
		npc.AddActivityViaSequence("taunt_mourning_mercs_heavy");
		npc.SetPlaybackRate(0.8);
		npc.SetCycle(0.05);
		npc.m_flAttackHappens = 0.0;
	}	
	return true;
}

void SsjBlackHeavy_KnockbackDo(int entity, int victim, float damage, int weapon)
{
	float VecMe[3]; WorldSpaceCenter(entity, VecMe);
	float VecEnemy[3]; WorldSpaceCenter(victim, VecEnemy);

	float AngleVec[3];
	MakeVectorFromPoints(VecMe, VecEnemy, AngleVec);
	GetVectorAngles(AngleVec, AngleVec);

	AngleVec[0] = -45.0;
	Custom_Knockback(entity, victim, 800.0, true, true, true, .OverrideLookAng = AngleVec);
	if(IsValidClient(victim))
	{
		ApplyStatusEffect(entity, victim, "Ragdolled", 4.0);	
		FreezeNpcInTime(victim, 4.0);
	}
}
*/

//cone stuff
static int CONE_COLOR[3] = { 0, 255, 255 };
static bool g_ConeFillOk = false;
static int g_ConeLaser = -1;

#define CONE_FILL_MAT "laststand/fill_cone.vmt"
#define CONE_RADIUS 500.0
#define CONE_MELEE_ARC 150.0			// punch hit radius
#define CONE_HALFANGLE 30.0	    	// angle based on relative north, 22.5 = a 45 degree cone
#define CONE_LIFESPAN 0.5	    	// how long the cone lasts before disappearing
#define CONE_OUTLINE_ALPHA 200
#define CONE_FILL_ALPHA 90			// 0 disables the pie sheet entirely
#define CONE_ANIM_MIN_RATE 1.0
#define CONE_ANIM_STILL_SPEED 40.0  // HU/S under which the floor applies
#define CONE_FILL_FWD 0.7071
#define CONE_FILL_LEFT 0.0

//walk Cycle offset is 200
bool OshimunoAntayoto_ConeSlash(OshimunoAntayoto npc, float gameTime)
{
	if(npc.m_iWhatAbilityDo != 1 && npc.m_iWhatAbilityDo != 0)
		return false;
	if(npc.m_flDoingAnimation < gameTime)
	{
		if(npc.m_flConeSlashCD < gameTime)
		{
			if(!IsValidEnemy(npc.index, npc.m_iTarget))
				return false;
			if(!Can_I_See_Enemy_Only(npc.index, npc.m_iTarget))
				return false;
			npc.m_flConeSlashCD = gameTime + 25.0;
			npc.m_flDoingAnimation = gameTime + 1.5;
			npc.m_bisWalking = false;
			npc.StopPathing();
			npc.m_iChanged_WalkCycle = 200;
			npc.AddActivityViaSequence("secondrate_sorcery_demo")
			npc.SetPlaybackRate(0.65);
			npc.SetCycle(0.05);
			npc.m_iWhatAbilityDo = 1;
		}
	}
	if(npc.m_iWhatAbilityDo != 1)
		return false;
		
	int CurrentShotAt = npc.m_iChanged_WalkCycle - 200;
	if(CurrentShotAt > 20)
	{
		npc.m_iWhatAbilityDo = 0;
		npc.m_flDoingAnimation = 0.0;
		return false;
	}
	if(npc.m_flDoingAnimation < gameTime)
	{
		npc.SetPlaybackRate(2.5);
		npc.SetCycle(0.38);
		npc.m_iChanged_WalkCycle++;
		if(IsValidEnemy(npc.index, npc.m_iTarget))
		{
			float bossPos[3];
			GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", bossPos);
			GetClientAbsOrigin(target, targetPos);
			float yawDeg;
			{
				float at[3];
				WorldSpaceCenter(target, at);
				float dx = at[0] - bossPos[0];
				float dy = at[1] - bossPos[1];
				if((dx * dx) + (dy * dy) >= 1.0)
				{
					yawDeg = ArcTangent2(dy, dx) * 180.0 / FLOAT_PI;
				}
				else
				{
					float ang[3];
					GetEntPropVector(npc.index, Prop_Data, "m_angRotation", ang);
					yawDeg = ang[1];
				}
			}
			OshimunoAntayotoResolveCone(npc, bossPos, yawDeg);
			OshimunoTricksterDrawCone(bossPos, yawDeg);
		}
		npc.m_flDoingAnimation = gameTime + 0.25;
	}
	return true;
}
static void OshimunoAntayotoResolveCone(OshimunoAntayoto npc, const float apex[3], float yawDeg)
{
	float yawRad = yawDeg * FLOAT_PI / 180.0;
	float halfAngle = (CONE_HALFANGLE + 6.0) * FLOAT_PI / 180.0;
	float radiusPad = CONE_RADIUS + 24.0;

	for(int client = 1; client <= MaxClients; client++)
	{
		if(!IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) != TFTeam_Red)
			continue;

		float pos[3];
		GetClientAbsOrigin(client, pos);
		float dx = pos[0] - apex[0];
		float dy = pos[1] - apex[1];
		float dz = pos[2] - apex[2];
		if(((dx * dx) + (dy * dy)) > (radiusPad * radiusPad) || dz > 120.0 || dz < -120.0)
			continue;

		float diff = ArcTangent2(dy, dx) - yawRad;
		while(diff > FLOAT_PI) diff -= FLOAT_PI * 2.0;
		while(diff < -FLOAT_PI) diff += FLOAT_PI * 2.0;
		if(FloatAbs(diff) > halfAngle)
			continue;

		float at[3];
		WorldSpaceCenter(client, at);

		float damage = 100.0;
		NPC_Ignite(client, npc.index, 8.0, -1, 2.0);
		SDKHooks_TakeDamage(client, npc.index, npc.index, damage, DMG_CLUB);
	}
}

static void OshimunoAntayotoDrawCone(const float apex[3], float yawDeg)
{
	int color[4];
	color[0] = CONE_COLOR[0];
	color[1] = CONE_COLOR[1];
	color[2] = CONE_COLOR[2];
	color[3] = CONE_OUTLINE_ALPHA;

	float from[3];
	from = apex;
	from[2] += 5.0;

	float halfAngle = CONE_HALFANGLE * FLOAT_PI / 180.0;
	float yawRad = yawDeg * FLOAT_PI / 180.0;
	float prev[3];
	for(int step; step <= 6; step++)
	{
		float ang = yawRad - halfAngle + ((halfAngle * 2.0) * (float(step) / 6.0));
		float at[3];
		at[0] = from[0] + (Cosine(ang) * CONE_RADIUS);
		at[1] = from[1] + (Sine(ang) * CONE_RADIUS);
		at[2] = from[2];

		if(step == 0 || step == 6)
		{
			TE_SetupBeamPoints(from, at, g_ConeLaser, -1, 0, 0, CONE_LIFESPAN, 4.0, 4.0, 0, 0.0, color, 0);
			TE_SendToAll();
		}
		if(step)
		{
			TE_SetupBeamPoints(prev, at, g_ConeLaser, -1, 0, 0, CONE_LIFESPAN, 4.0, 4.0, 0, 0.0, color, 0);
			TE_SendToAll();
		}
		prev = at;
	}
	if(CONE_FILL_ALPHA <= 0 || !g_ConeFillOk)
		return;

	int spr = CreateEntityByName("env_sprite_oriented");
	if(spr <= MaxClients || !IsValidEntity(spr))
		return;

	char buffer[48];
	DispatchKeyValue(spr, "model", CONE_FILL_MAT);
	FormatEx(buffer, sizeof(buffer), "%.3f", (CONE_RADIUS * 0.5) / 32.0);
	DispatchKeyValue(spr, "scale", buffer);
	DispatchKeyValue(spr, "rendermode", "1");	
	FormatEx(buffer, sizeof(buffer), "%d %d %d", CONE_COLOR[0], CONE_COLOR[1], CONE_COLOR[2]);
	DispatchKeyValue(spr, "rendercolor", buffer);
	IntToString(CONE_FILL_ALPHA, buffer, sizeof(buffer));
	DispatchKeyValue(spr, "renderamt", buffer);
	DispatchKeyValue(spr, "spawnflags", "1");	
	float ang[3];
	ang[0] = 90.0;
	ang[1] = yawDeg + 45.0;
	FormatEx(buffer, sizeof(buffer), "%.0f %.0f 0", ang[0], ang[1]);
	DispatchKeyValue(spr, "angles", buffer);
	DispatchSpawn(spr);
	float fwdRad = yawDeg * FLOAT_PI / 180.0;
	float leftRad = (yawDeg + 90.0) * FLOAT_PI / 180.0;
	float at[3];
	at[0] = apex[0] + (Cosine(fwdRad) * CONE_RADIUS * CONE_FILL_FWD)
		+ (Cosine(leftRad) * CONE_RADIUS * CONE_FILL_LEFT);
	at[1] = apex[1] + (Sine(fwdRad) * CONE_RADIUS * CONE_FILL_FWD)
		+ (Sine(leftRad) * CONE_RADIUS * CONE_FILL_LEFT);
	at[2] = apex[2] + 4.0;
	TeleportEntity(spr, at, ang, NULL_VECTOR);
	SetEdictFlags(spr, (GetEdictFlags(spr) & ~(FL_EDICT_DONTSEND | FL_EDICT_PVSCHECK)) | FL_EDICT_ALWAYS);

	CreateTimer(CONE_LIFESPAN, Timer_ConeKillFill, EntIndexToEntRef(spr));
}

public Action Timer_ConeKillFill(Handle timer, any ref)
{
	int spr = EntRefToEntIndex(view_as<int>(ref));
	if(spr > MaxClients && IsValidEntity(spr))
		RemoveEntity(spr);
	return Plugin_Stop;
}

//Wwalk Cycle offset is 300
bool OshimunoAntayoto_CongaVeryFastDo(OshimunoAntayoto npc, float gameTime)
{
	if(npc.m_iWhatAbilityDo != 2 && npc.m_iWhatAbilityDo != 0)
		return false;
	if(npc.m_flDoingAnimation < gameTime)
	{
		if(npc.m_flCongaFastDo < gameTime)
		{
			if(!IsValidEnemy(npc.index, npc.m_iTarget))
				return false;
			if(!Can_I_See_Enemy_Only(npc.index, npc.m_iTarget))
				return false;

			npc.m_flSpeed = 720.0;
			npc.m_flCongaFastDo = gameTime + 35.0;
			npc.m_flDoingAnimation = gameTime + 0.25;
			npc.m_bisWalking = false;
			npc.StartPathing();
			npc.m_iChanged_WalkCycle = 300;
			npc.AddActivityViaSequence("taunt_conga");
			npc.SetPlaybackRate(2.5);
			npc.SetCycle(0.05);
			npc.m_iWhatAbilityDo = 2;
			f_NpcAdjustFriction[npc.index] = 0.2;
			ApplyStatusEffect(npc.index, npc.index, "Intangible", 999999.0);
			f_CheckIfStuckPlayerDelay[npc.index] = FAR_FUTURE; //She CANT stuck you, so dont make players not unstuck in cant bve stuck ? what ?
			b_ThisEntityIgnoredBeingCarried[npc.index] = true; //cant be targeted AND wont do npc collsiions
		}
	}
	if(npc.m_iWhatAbilityDo != 2)
		return false;
		
	int CurrentShotAt = npc.m_iChanged_WalkCycle - 300;
	if(CurrentShotAt > 20)
	{
		f_NpcAdjustFriction[npc.index] = 1.0;
		RemoveSpecificBuff(npc.index, "Intangible");
		f_CheckIfStuckPlayerDelay[npc.index] = 1.0; //She CANT stuck you, so dont make players not unstuck in cant bve stuck ? what ?
		b_ThisEntityIgnoredBeingCarried[npc.index] = false; //cant be targeted AND wont do npc collsiions
		npc.m_iWhatAbilityDo = 0;
		npc.m_flDoingAnimation = 0.0;
		return false;
	}
	if(npc.m_flDoingAnimation < gameTime)
	{		
		npc.m_iChanged_WalkCycle++;
		i_ExplosiveProjectileHexArray[npc.index] |= EP_DEALS_CLUB_DAMAGE;
		float radius = 160.0, damage = 20.0 * RaidModeScaling;
		float Loc[3];
		GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", Loc);
		Explode_Logic_Custom(damage, npc.index, npc.index, -1, _, radius, _, _, true);
		spawnRing_Vectors(Loc, 0.1, 0.0, 0.0, 1.0, "materials/sprites/laserbeam.vmt", 255, 200, 200, 255, 1, 0.2, 8.0, 1.5, 1, radius*2.0);
		spawnRing_Vectors(Loc, 0.1, 0.0, 0.0, 25.0, "materials/sprites/laserbeam.vmt", 255, 200, 200, 255, 1, 0.2, 8.0, 1.5, 1, radius*2.0);
		spawnRing_Vectors(Loc, 0.1, 0.0, 0.0, 45.0, "materials/sprites/laserbeam.vmt", 255, 200, 200, 255, 1, 0.2, 8.0, 1.5, 1, radius*2.0);
		spawnRing_Vectors(Loc, 0.1, 0.0, 0.0, 65.0, "materials/sprites/laserbeam.vmt", 255, 200, 200, 255, 1, 0.2, 8.0, 1.5, 1, radius*2.0);

		npc.m_flDoingAnimation = gameTime + 0.25;
	}
	return false;
}


//Wwalk Cycle offset is 400
bool OshimunoAntayoto_JumpOfDeath(OshimunoAntayoto npc, float gameTime)
{
	if(npc.m_iWhatAbilityDo != 3 && npc.m_iWhatAbilityDo != 0)
		return false;
	if(npc.m_flDoingAnimation < gameTime)
	{
		if(npc.m_flJumpAtEnemy < gameTime)
		{
			if(!IsValidEnemy(npc.index, npc.m_iTarget))
				return false;
			if(!Can_I_See_Enemy_Only(npc.index, npc.m_iTarget))
				return false;

			npc.m_flJumpAtEnemy = gameTime + 35.0;
			npc.m_flDoingAnimation = gameTime + 1.0;
			npc.m_bisWalking = false;
			npc.StopPathing();
			npc.AddActivityViaSequence("taunt_table_flip_outro");
			npc.SetPlaybackRate(0.65);
			npc.SetCycle(0.01);
			npc.m_iChanged_WalkCycle = 400;
			npc.m_iWhatAbilityDo = 3;
			EmitSoundToAll("mvm/mvm_cpoint_klaxon.wav", npc.index, SNDCHAN_STATIC, 120, _, 1.0);
			EmitSoundToAll("mvm/mvm_cpoint_klaxon.wav", npc.index, SNDCHAN_STATIC, 120, _, 1.0);
		}
	}
	if(npc.m_iWhatAbilityDo != 3)
		return false;
		
	if(npc.m_iChanged_WalkCycle == 400)
	{
		if(!IsValidEnemy(npc.index, npc.m_iTarget))
			return true;
		float vecTarget[3]; WorldSpaceCenter(npc.m_iTarget, vecTarget );
		npc.FaceTowards(vecTarget, 15000.0);
		if(npc.m_flDoingAnimation < gameTime)
		{
			npc.SetPlaybackRate(0.0);
			npc.m_iChanged_WalkCycle = 401;
			npc.m_flDoingAnimation = gameTime + 4.0;
			npc.m_flGravityMulti = 0.65;
			PluginBot_Jump(npc.index, vecTarget, 4000.0, .timemodify = 4.0);
			npc.PlaySuperJumpSound();
			float flPos[3];
			float flAng[3];
			npc.GetAttachment("effect_hand_R", flPos, flAng);
			npc.m_iWearable5 = ParticleEffectAt_Parent(flPos, "raygun_projectile_red_crit", npc.index, "effect_hand_R", {0.0,0.0,0.0});
			

			npc.GetAttachment("effect_hand_L", flPos, flAng);
			npc.m_iWearable4 = ParticleEffectAt_Parent(flPos, "raygun_projectile_red_crit", npc.index, "effect_hand_L", {0.0,0.0,0.0});

		}
		return true;
	}
	
	if ((npc.IsOnGround() || npc.m_flDoingAnimation < gameTime) && (npc.m_iChanged_WalkCycle == 401))
	{
		float damageDealt = 600.0 * RaidModeScaling;

		npc.AddActivityViaSequence("taunt_yeti_layer");
		npc.SetPlaybackRate(1.0);
		npc.SetCycle(0.75);
		npc.m_iChanged_WalkCycle = 402;
		npc.m_flDoingAnimation = gameTime + 1.5;
		static float flMyPos[3];
		GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", flMyPos);
		flMyPos[2] += 15.0;
		Explode_Logic_Custom(damageDealt, npc.index, npc.index, -1, flMyPos,300.0, 1.0, _, true, 20);
		TE_Particle("asplode_hoodoo", flMyPos, NULL_VECTOR, NULL_VECTOR, _, _, _, _, _, _, _, _, _, _, 0.0);
		EmitSoundToAll(SOUND_WAND_LIGHTNING_ABILITY_PAP_SMITE, 0, SNDCHAN_AUTO, 100, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, flMyPos);
		EmitSoundToAll(SOUND_WAND_LIGHTNING_ABILITY_PAP_SMITE, 0, SNDCHAN_AUTO, 100, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, flMyPos);
		npc.m_flGravityMulti = 1.0;
		if(IsValidEntity(npc.m_iWearable5))
			RemoveEntity(npc.m_iWearable5);
		if(IsValidEntity(npc.m_iWearable4))
			RemoveEntity(npc.m_iWearable4);
	}
	if (npc.m_iChanged_WalkCycle == 402 && npc.m_flDoingAnimation < gameTime)
	{
		npc.m_iChanged_WalkCycle = 0;
		npc.m_iWhatAbilityDo = 0;
	}
	return true;
}