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

#define FARMER_LINE_WIDTH 180.0
#define FARMER_LINE_LENGTH 900.0
#define FARMER_LINE_GAP 125.0
#define FARMER_LINE_START 30.0
#define FARMER_LINE_TIME 1.2
#define FARMER_LINE_SWING_LEAD 0.75
#define FARMER_LINE_SWING_DELAY 0.1953
#define FARMER_LINE_IMPACT_DELAY (-0.04)
#define FARMER_LINE_FADE_TIME 0.15
#define FARMER_LINE_SPREAD 75.0
#define FARMER_LINE_FADE_STEP 0.045
#define FARMER_LINE_DAMAGE 30.0
#define FARMER_LINE_SWINGS 5

static int g_FarmerLineLaser = -1;
static const char g_FarmerLineWindUpSound[] = "misc/halloween/strongman_fast_swing_01.wav";
static const char g_FarmerLineImpactSound[] = "misc/halloween/strongman_fast_impact_01.wav";

void OshimunoFarmerOnMapStart()
{
	PrecacheSoundArray(g_DeathSounds);
	PrecacheSoundArray(g_HurtSounds);
	PrecacheSoundArray(g_IdleAlertedSounds);
	PrecacheSoundArray(g_MeleeHitSounds);
	PrecacheSoundArray(g_MeleeAttackSounds);
	g_FarmerLineLaser = PrecacheModel("sprites/laserbeam.vmt");
	PrecacheSound(g_FarmerLineWindUpSound);
	PrecacheSound(g_FarmerLineImpactSound);
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
	property float m_flLineAoeDetonate
	{
		public get()							{ return fl_AbilityOrAttack[this.index][1]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][1] = TempValueForProperty; }
	}
	property float m_flLineAoeYaw
	{
		public get()							{ return fl_AbilityOrAttack[this.index][2]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][2] = TempValueForProperty; }
	}
	property float m_flMeleeSwingCount
	{
		public get()							{ return fl_AbilityOrAttack[this.index][3]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][3] = TempValueForProperty; }
	}
	property float m_flLineAoeFade
	{
		public get()							{ return fl_AbilityOrAttack[this.index][4]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][4] = TempValueForProperty; }
	}
	property float m_flLineAoeFadeDraw
	{
		public get()							{ return fl_AbilityOrAttack[this.index][5]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][5] = TempValueForProperty; }
	}
	property float m_flTransformIn
	{
		public get()							{ return fl_NextChargeSpecialAttack[this.index]; }
		public set(float TempValueForProperty) 	{ fl_NextChargeSpecialAttack[this.index] = TempValueForProperty; }
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
		OshimunoFarmer npc = view_as<OshimunoFarmer>(CClotBody(vecPos, vecAng, "models/player/engineer.mdl", "1.3", "50000", ally, false, true, true,true));
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
		for(int client_check=1; client_check<=MaxClients; client_check++)
		{
			if(IsClientInGame(client_check) && !IsFakeClient(client_check))
			{
				LookAtTarget(client_check, npc.index);
				SetGlobalTransTarget(client_check);
				ShowGameText(client_check, "item_armor", 1, "%s", "Sakurawa arrives");
			}
		}

		npc.Anger = false;
		npc.m_flNextChargeSpecialAttack = gameTime + 25.0;
		npc.m_flTreeCooldown = gameTime + INITIAL_TREE_SPAWN_COOLDOWN;
		npc.m_flLineAoeDetonate = 0.0;
		npc.m_flLineAoeYaw = 0.0;
		npc.m_flMeleeSwingCount = 0.0;
		npc.m_flLineAoeFade = 0.0;
		npc.m_flLineAoeFadeDraw = 0.0;
		npc.m_flTransformIn = 0.0;
		npc.g_TimesSummoned = 0;

		func_NPCDeath[npc.index] = ClotDeath;
		func_NPCOnTakeDamage[npc.index] = OshimunoFarmerOnTakeDamage;
		func_NPCThink[npc.index] = ClotThink;
		
		npc.m_flSpeed = 345.0;
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
		SetEntProp(npc.m_iWearable3, Prop_Send, "m_nSkin", 1);
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

static void NPCTalkMessage(int entity, const char[] message)
{
	PrintNPCMessageWithPrefixes(entity, "crimson", message);
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

	if(LastMann)
	{
		if(!npc.m_fbGunout)
		{
			npc.m_fbGunout = true;
			NPCTalkMessage(npc.index, "Last Noob Left.");
		}
	}

	if(npc.m_blPlayHurtAnimation)
	{
		npc.AddGesture("ACT_MP_GESTURE_FLINCH_CHEST", false);
		npc.PlayHurtSound();
		npc.m_blPlayHurtAnimation = false;
	}
	
	if(npc.m_flNextThinkTime > gameTime)
		return;
	
	npc.m_flNextThinkTime = gameTime + 0.1;

	if(npc.m_flLineAoeDetonate)
	{
		if(npc.m_flLineAoeDetonate > gameTime)
		{
			OshimunoFarmerLineAoeDraw(npc, gameTime);
		}
		else
		{
			OshimunoFarmerLineAoeDetonate(npc);
			npc.m_flLineAoeDetonate = 0.0;
			npc.m_flLineAoeFade = gameTime + FARMER_LINE_FADE_TIME;
			npc.m_flLineAoeFadeDraw = gameTime + FARMER_LINE_FADE_STEP;
			int color[4];
			color[0] = 255;
			color[1] = 0;
			color[2] = 0;
			color[3] = 255;
			OshimunoFarmerLineAoeDrawRects(npc, 0.0, color, 0.1);
			RequestFrame(FarmerLineFadeFrame, EntIndexToEntRef(npc.index));
			npc.StartPathing();
			npc.m_bisWalking = true;
		}
		return;
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
	if(OshimunoFarmerTransform(npc))
		return;
	if(npc.m_flTreeCooldown < gameTime)// spawn trees every 25s
	{
		int treehealth = ReturnEntityMaxHealth(npc.index) / 10;
		float pos[3]; GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", pos);
		float ang[3]; GetEntPropVector(npc.index, Prop_Data, "m_angRotation", ang);
		int entity = NPC_CreateByName("npc_oshimuno_tree", -1, pos, ang, GetTeam(npc.index));
		if(entity > MaxClients)
		{
			/*ConnectWithBeam(npc.index, entity, 245, 180, 255, 1.0, 1.0, 0.0, LASERBEAM);*/
			view_as<CClotBody>(entity).m_iWearable9=ConnectWithBeam(npc.index, entity, 245, 180, 255, 1.0, 1.0, 0.0, LASERBEAM);
			if(GetTeam(npc.index) != TFTeam_Red)
				NpcAddedToZombiesLeftCurrently(entity, true);
			SetEntProp(entity, Prop_Data, "m_iHealth", treehealth);
			SetEntProp(entity, Prop_Data, "m_iMaxHealth", treehealth);
		}
		npc.m_flTreeCooldown = gameTime + TREE_SPAWN_COOLDOWN;
	}
	if(GetTreeCount(npc.index) <= 5)// increase stats for every tree alive
	{
		switch(GetTreeCount(npc.index))
		{
			case 1:
			{
				fl_TotalArmor[npc.index] = 0.825;
			}
			case 2:
			{
				fl_TotalArmor[npc.index] = 0.70;
			}
			case 3:
			{
				fl_TotalArmor[npc.index] = 0.65;
				npc.m_flSpeed = 350.0;
			}
			case 4:
			{
				fl_TotalArmor[npc.index] = 0.50;
				npc.m_flSpeed = 360.0;
			}
			case 5:
			{
				fl_TotalArmor[npc.index] = 0.45;
				npc.m_flSpeed = 375.0;
			}
		}
	}
	else if (GetTreeCount(npc.index) >= 6) // beyond 5 trees he gets max buffs
	{
		fl_TotalArmor[npc.index] = 0.33;
		npc.m_flSpeed = 400.0;
	}
	if(!BlockLoseSay && RaidModeTime < GetGameTime()) // time out
	{
		
		RaidModeTime = FAR_FUTURE;
		RaidModeScaling *= 1.5;
		/*TreeCount = TreeCount + 20;*/
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
					float damage = 15.0;
					npc.PlayMeleeHitSound();
					SDKHooks_TakeDamage(target, npc.index, npc.index, damage * RaidModeScaling, DMG_CLUB);
					bool Knocked = false;
					if(IsValidClient(target))
					{
						if(IsInvuln(target))
						{
							Knocked = true;
							Custom_Knockback(npc.index, target, 700.0, true);
							if(!NpcStats_IsEnemySilenced(npc.index))
							{
								TF2_AddCondition(target, TFCond_LostFooting, 0.5);
								TF2_AddCondition(target, TFCond_AirCurrent, 0.5);
							}
						}
						else
						{
							if(!NpcStats_IsEnemySilenced(npc.index))
							{
								TF2_AddCondition(target, TFCond_LostFooting, 0.5);
								TF2_AddCondition(target, TFCond_AirCurrent, 0.5);
							}
						}
					}
					if(!Knocked)
						Custom_Knockback(npc.index, target, 330.0, true); 
				}
			}
			delete swingTrace;
		}
	}
	if(distance < (NORMAL_ENEMY_MELEE_RANGE_FLOAT_SQUARED) * 1.5 && npc.m_flNextMeleeAttack < gameTime)
	{
		int target = Can_I_See_Enemy(npc.index, npc.m_iTarget);
		if(IsValidEnemy(npc.index, target, false, true))
		{
			npc.m_iTarget = target;

			npc.AddGesture("ACT_MP_ATTACK_STAND_MELEE",_,_,_, 0.85);
			npc.PlayMeleeSound();
			
			npc.m_flAttackHappens = gameTime + 0.25;
			npc.m_flNextMeleeAttack = gameTime + 1.0;

			npc.m_flMeleeSwingCount += 1.0;
			if(npc.m_flMeleeSwingCount >= float(FARMER_LINE_SWINGS))
			{
				npc.m_flMeleeSwingCount = 0.0;
				OshimunoFarmerLineAoeStart(npc, gameTime);
			}
		}
	}
}

static void OshimunoFarmerLineAoeStart(OshimunoFarmer npc, float gameTime)
{
	npc.m_flAttackHappens = 0.0;
	npc.m_flLineAoeDetonate = gameTime + FARMER_LINE_TIME;
	CreateTimer(FARMER_LINE_TIME - FARMER_LINE_SWING_LEAD + FARMER_LINE_SWING_DELAY, Timer_FarmerLineSwing, EntIndexToEntRef(npc.index), TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(FARMER_LINE_TIME + FARMER_LINE_IMPACT_DELAY, Timer_FarmerLineImpact, EntIndexToEntRef(npc.index), TIMER_FLAG_NO_MAPCHANGE);

	float pos[3]; GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", pos);
	float ang[3]; GetEntPropVector(npc.index, Prop_Data, "m_angRotation", ang);
	float yawRad = ang[1] * FLOAT_PI / 180.0;
	pos[0] += Cosine(yawRad) * FARMER_LINE_START;
	pos[1] += Sine(yawRad) * FARMER_LINE_START;
	f3_NpcSavePos[npc.index] = pos;
	npc.m_flLineAoeYaw = ang[1];

	npc.StopPathing();
	npc.m_bisWalking = false;
	OshimunoFarmerLineAoeDraw(npc, gameTime);
}

static Action Timer_FarmerLineSwing(Handle timer, any ref)
{
	int entity = EntRefToEntIndex(ref);
	if(entity <= MaxClients || !IsValidEntity(entity))
		return Plugin_Handled;

	OshimunoFarmer npc = view_as<OshimunoFarmer>(entity);
	if(!npc.m_flLineAoeDetonate)
		return Plugin_Handled;

	npc.AddGesture("ACT_MP_ATTACK_STAND_MELEE",_,_,_, 0.85);
	EmitSoundToAll(g_FarmerLineWindUpSound, npc.index, SNDCHAN_STATIC, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME);
	return Plugin_Handled;
}

static Action Timer_FarmerLineImpact(Handle timer, any ref)
{
	int entity = EntRefToEntIndex(ref);
	if(entity <= MaxClients || !IsValidEntity(entity))
		return Plugin_Handled;

	EmitSoundToAll(g_FarmerLineImpactSound, entity, SNDCHAN_STATIC, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME);
	return Plugin_Handled;
}

static void OshimunoFarmerLineAoeDraw(OshimunoFarmer npc, float gameTime)
{
	float remaining = npc.m_flLineAoeDetonate - gameTime;
	if(remaining < 0.0)
		remaining = 0.0;

	int color[4];
	color[0] = 255;
	color[1] = RoundToNearest(255.0 * (remaining / FARMER_LINE_TIME));
	color[2] = 0;
	color[3] = 255;

	OshimunoFarmerLineAoeDrawRects(npc, 0.0, color, 0.15);
}

static void OshimunoFarmerLineAoeDrawRects(OshimunoFarmer npc, float expand, const int color[4], float life)
{
	float yawRad = npc.m_flLineAoeYaw * FLOAT_PI / 180.0;
	float fwdX = Cosine(yawRad);
	float fwdY = Sine(yawRad);
	float leftX = -fwdY;
	float leftY = fwdX;

	float anchor[3];
	anchor = f3_NpcSavePos[npc.index];
	anchor[2] += 4.0;
	anchor[0] -= fwdX * expand;
	anchor[1] -= fwdY * expand;

	float length = FARMER_LINE_LENGTH + (expand * 2.0);
	float halfWidth = (FARMER_LINE_WIDTH * 0.5) + expand;
	for(int line = -1; line <= 1; line++)
	{
		float off = float(line) * (FARMER_LINE_GAP + FARMER_LINE_WIDTH);
		float c1[3], c2[3], c3[3], c4[3];
		c1[0] = anchor[0] + (leftX * (off + halfWidth));
		c1[1] = anchor[1] + (leftY * (off + halfWidth));
		c1[2] = anchor[2];
		c2[0] = anchor[0] + (leftX * (off - halfWidth));
		c2[1] = anchor[1] + (leftY * (off - halfWidth));
		c2[2] = anchor[2];
		c3[0] = c1[0] + (fwdX * length);
		c3[1] = c1[1] + (fwdY * length);
		c3[2] = anchor[2];
		c4[0] = c2[0] + (fwdX * length);
		c4[1] = c2[1] + (fwdY * length);
		c4[2] = anchor[2];

		TE_SetupBeamPoints(c1, c2, g_FarmerLineLaser, -1, 0, 0, life, 4.0, 4.0, 0, 0.0, color, 0);
		TE_SendToAll();
		TE_SetupBeamPoints(c1, c3, g_FarmerLineLaser, -1, 0, 0, life, 4.0, 4.0, 0, 0.0, color, 0);
		TE_SendToAll();
		TE_SetupBeamPoints(c2, c4, g_FarmerLineLaser, -1, 0, 0, life, 4.0, 4.0, 0, 0.0, color, 0);
		TE_SendToAll();
		TE_SetupBeamPoints(c3, c4, g_FarmerLineLaser, -1, 0, 0, life, 4.0, 4.0, 0, 0.0, color, 0);
		TE_SendToAll();
	}
}

static void FarmerLineFadeFrame(any ref)
{
	int entity = EntRefToEntIndex(ref);
	if(entity <= MaxClients || !IsValidEntity(entity))
		return;

	OshimunoFarmer npc = view_as<OshimunoFarmer>(entity);
	float gameTime = GetGameTime(npc.index);
	if(!npc.m_flLineAoeFade)
		return;

	if(npc.m_flLineAoeFade <= gameTime)
	{
		npc.m_flLineAoeFade = 0.0;
		return;
	}

	if(gameTime >= npc.m_flLineAoeFadeDraw)
	{
		npc.m_flLineAoeFadeDraw = gameTime + FARMER_LINE_FADE_STEP;

		float frac = 1.0 - ((npc.m_flLineAoeFade - gameTime) / FARMER_LINE_FADE_TIME);
		if(frac < 0.0)
			frac = 0.0;

		int color[4];
		color[0] = 255;
		color[1] = 0;
		color[2] = 0;
		color[3] = RoundToNearest(255.0 * (1.0 - frac));

		OshimunoFarmerLineAoeDrawRects(npc, FARMER_LINE_SPREAD * frac, color, 0.1);
	}
	RequestFrame(FarmerLineFadeFrame, ref);
}

static void OshimunoFarmerLineAoeDetonate(OshimunoFarmer npc)
{
	float yawRad = npc.m_flLineAoeYaw * FLOAT_PI / 180.0;
	float fwdX = Cosine(yawRad);
	float fwdY = Sine(yawRad);
	float leftX = -fwdY;
	float leftY = fwdX;

	float anchor[3];
	anchor = f3_NpcSavePos[npc.index];

	float halfWidth = (FARMER_LINE_WIDTH * 0.5) + 24.0;
	float off = FARMER_LINE_GAP + FARMER_LINE_WIDTH;
	for(int client = 1; client <= MaxClients; client++)
	{
		if(!IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) != TFTeam_Red)
			continue;

		float pos[3];
		GetClientAbsOrigin(client, pos);
		float dx = pos[0] - anchor[0];
		float dy = pos[1] - anchor[1];
		float dz = pos[2] - anchor[2];
		if(dz > 120.0 || dz < -120.0)
			continue;

		float fwdDist = (dx * fwdX) + (dy * fwdY);
		if(fwdDist < -24.0 || fwdDist > (FARMER_LINE_LENGTH + 24.0))
			continue;

		float leftDist = (dx * leftX) + (dy * leftY);
		if(FloatAbs(leftDist) > halfWidth && FloatAbs(leftDist - off) > halfWidth && FloatAbs(leftDist + off) > halfWidth)
			continue;

		float at[3];
		WorldSpaceCenter(client, at);
		EmitSoundToAll(g_MeleeAttackSounds[GetRandomInt(0, sizeof(g_MeleeAttackSounds) - 1)], client, SNDCHAN_AUTO, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME);
		SDKHooks_TakeDamage(client, npc.index, npc.index, FARMER_LINE_DAMAGE * RaidModeScaling, DMG_CLUB, -1, _, at);
		float VecMe[3]; WorldSpaceCenter(npc.index, VecMe);
		float VecEnemy[3]; WorldSpaceCenter(client, VecEnemy);

		float AngleVec[3];
		MakeVectorFromPoints(VecMe, VecEnemy, AngleVec);
		GetVectorAngles(AngleVec, AngleVec);
		AngleVec[0] = -90.0;
		Custom_Knockback(npc.index, client, 900.0, true, true, true, .OverrideLookAng = AngleVec);
		ApplyStatusEffect(npc.index, client, "Ragdolled", 1.5);	
		FreezeNpcInTime(client, 1.5);
	}
}

static Action OshimunoFarmerOnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{	
	if(!b_thisNpcIsARaid[victim])
		return Plugin_Changed;
		
	OshimunoFarmer npc = view_as<OshimunoFarmer>(victim);
	if((ReturnEntityMaxHealth(npc.index)/3) >= GetEntProp(npc.index, Prop_Data, "m_iHealth") && !npc.Anger) //enrage below 33% hp
	{
		npc.Anger = true;
		npc.m_flTransformIn = GetGameTime() + 2.5;
		npc.m_flTreeCooldown = npc.m_flTreeCooldown + 2.5;
	}
	if(npc.g_TimesSummoned < 99)
	{
		int nextLoss = ReturnEntityMaxHealth(npc.index) * (99 - npc.g_TimesSummoned) / 100;
		if(GetEntProp(npc.index, Prop_Data, "m_iHealth") < nextLoss)
		{
			npc.g_TimesSummoned++;
			npc.m_flTreeCooldown -= 0.7;
		}
	}

	return Plugin_Changed;
}
bool OshimunoFarmerTransform(OshimunoFarmer npc)
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
		npc.SetActivity("ACT_MP_RUN_MELEE");
		npc.m_flTransformIn = 0.0;
		return false;
	}
	if(npc.m_flTransformIn < GetGameTime() + 0.5)
	{
		if(npc.m_iChanged_WalkCycle != 10)
		{
			RaidModeScaling *= 1.05;
			/*fl_Extra_Speed[npc.index] *= 1.05;*/
			for(int i=0 ; i < 6 ; i++) //summon 6 trees
			{
				int treehealth = ReturnEntityMaxHealth(npc.index) / 10;
				float pos[3]; GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", pos);
				float ang[3]; GetEntPropVector(npc.index, Prop_Data, "m_angRotation", ang);
				int entity = NPC_CreateByName("npc_oshimuno_tree", -1, pos, ang, GetTeam(npc.index));

				if(entity > MaxClients)
				{
					ConnectWithBeam(npc.index, entity, 245, 180, 255, 1.0, 1.0, 0.0, LASERBEAM);
					if(GetTeam(npc.index) != TFTeam_Red)
						NpcAddedToZombiesLeftCurrently(entity, true);
					SetEntProp(entity, Prop_Data, "m_iHealth", treehealth);
					SetEntProp(entity, Prop_Data, "m_iMaxHealth", treehealth);
				}
			}
			npc.m_iChanged_WalkCycle = 10;
		}
		return true;
	}
	if(npc.m_iChanged_WalkCycle != 9)
	{
		npc.m_bisWalking = false;
		npc.m_iChanged_WalkCycle = 9;
		npc.StopPathing();
		b_NpcIsInvulnerable[npc.index] = true; //Special huds for invul targets
		b_CannotBeHeadshot[npc.index] = true;
		b_CannotBeBackstabbed[npc.index] = true;
		ApplyStatusEffect(npc.index, npc.index, "Clear Head", 3.0);	
		ApplyStatusEffect(npc.index, npc.index, "Solid Stance", 3.0);	
		ApplyStatusEffect(npc.index, npc.index, "Fluid Movement", 3.0);	
		npc.AddActivityViaSequence("taunt_unleashed_rage_engineer");
		npc.SetPlaybackRate(1.2);
		npc.SetCycle(0.1);
		npc.m_flAttackHappens = 0.0;
	}	
	return true;
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
