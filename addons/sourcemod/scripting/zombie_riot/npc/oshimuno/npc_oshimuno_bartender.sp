#pragma semicolon 1
#pragma newdecls required

static const char g_DeathSounds[][] =
{
	"vo/sniper_paincrticialdeath01.mp3",
	"vo/sniper_paincrticialdeath02.mp3",
	"vo/sniper_paincrticialdeath03.mp3",
};

static const char g_HurtSounds[][] =
{
	"vo/sniper_painsharp01.mp3",
	"vo/sniper_painsharp02.mp3",
	"vo/sniper_painsharp03.mp3",
	"vo/sniper_painsharp04.mp3",
};

static const char g_IdleAlertedSounds[][] = 
{
	"vo/sniper_battlecry01.mp3",
	"vo/sniper_battlecry02.mp3",
	"vo/sniper_battlecry03.mp3",
	"vo/sniper_battlecry04.mp3",
};

static const char g_MeleeAttackSounds[][] =
{
	"vo/sniper_jaratetoss02.mp3",
	"vo/sniper_jaratetoss03.mp3",
};

void OshimunoBartenderOnMapStart()
{
	PrecacheSoundArray(g_DeathSounds);
	PrecacheSoundArray(g_HurtSounds);
	PrecacheSoundArray(g_IdleAlertedSounds);
	PrecacheSoundArray(g_MeleeAttackSounds);
	NPCData data;
	strcopy(data.Name, sizeof(data.Name), "Shibuya Bartender");
	strcopy(data.Plugin, sizeof(data.Plugin), "npc_oshimuno_bartender");
	strcopy(data.Icon, sizeof(data.Icon), "sniper");
	data.IconCustom = true;
	data.Flags = 0;
	data.Category = Type_Oshimuno;
	data.Func = ClotSummon;
	NPC_Add(data);
}

static any ClotSummon(int client, float vecPos[3], float vecAng[3], int team)
{
	return OshimunoBartender(vecPos, vecAng, team);
}

methodmap OshimunoBartender < CClotBody
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
	
	public OshimunoBartender(float vecPos[3], float vecAng[3], int ally)
	{
		OshimunoBartender npc = view_as<OshimunoBartender>(CClotBody(vecPos, vecAng, "models/player/sniper.mdl", "1.0", "1000", ally));
		
		i_NpcWeight[npc.index] = 1;
		npc.SetActivity("ACT_MP_RUN_SECONDARY");
		KillFeed_SetKillIcon(npc.index, "skullbat");
		
		npc.m_iBleedType = BLEEDTYPE_NORMAL;
		npc.m_iStepNoiseType = STEPSOUND_NORMAL;
		npc.m_iNpcStepVariation = STEPTYPE_NORMAL;
		

		func_NPCDeath[npc.index] = ClotDeath;
		func_NPCOnTakeDamage[npc.index] = Generic_OnTakeDamage;
		func_NPCThink[npc.index] = ClotThink;
		
		npc.m_flSpeed = 300.0;

		npc.m_iWearable1 = npc.EquipItem("head", "models/workshop/weapons/c_models/c_madmilk/c_madmilk.mdl"); //TODO: replace with alch potion later if possible

		npc.m_iWearable2 = npc.EquipItem("head", "models/workshop/player/items/all_class/hwn2023_lunatic_fedora_neon/hwn2023_lunatic_fedora_neon_sniper.mdl");
		SetEntProp(npc.m_iWearable2, Prop_Send, "m_nSkin", 1);

		npc.m_iWearable3 = npc.EquipItem("head", "models/player/items/all_class/tuxxy_sniper.mdl");
		

		npc.m_iWearable4 = npc.EquipItem("head", "models/workshop_partner/player/items/all_class/sd_shirt/sd_shirt_sniper.mdl");
		SetEntProp(npc.m_iWearable4, Prop_Send, "m_nSkin", 1);

		SetEntProp(npc.index, Prop_Send, "m_nSkin", 1);

		npc.StartPathing();
		return npc;
	}
}

static void ClotThink(int iNPC)
{
	OshimunoBartender npc = view_as<OshimunoBartender>(iNPC);

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
		OshimunoBartenderSelfDefense(npc, distance, vecTarget, gameTime); 
	}

	npc.PlayIdleSound();
}

static int OshimunoBartenderSelfDefense(OshimunoBartender npc, float distance, float vecTarget[3], float gameTime) 
{
	//Direct mode
	if(gameTime > npc.m_flNextMeleeAttack)
	{
		if(distance < (NORMAL_ENEMY_MELEE_RANGE_FLOAT_SQUARED * 20.0))
		{
			float VecAim[3]; WorldSpaceCenter(npc.m_iTarget, VecAim );
			npc.FaceTowards(VecAim, 20000.0);
			int Enemy_I_See = Can_I_See_Enemy(npc.index, npc.m_iTarget);
			if(IsValidEnemy(npc.index, Enemy_I_See))
			{
				npc.m_iTarget = Enemy_I_See;
				npc.PlayMeleeSound();
				float RocketDamage = 250.0;
				float RocketSpeed = 900.0;
				float VecStart[3]; WorldSpaceCenter(npc.index, VecStart );
				float vecDest[3];
				vecDest = vecTarget;
				vecDest[0] += GetRandomFloat(-200.0, 200.0);
				vecDest[1] += GetRandomFloat(-200.0, 200.0);
				vecDest[2] += GetRandomFloat(-200.0, 200.0);
				if(npc.m_iChanged_WalkCycle == 1)
				{
					float SpeedReturn[3];
					npc.AddGesture("ACT_MP_ATTACK_STAND_ITEM1");

					int RocketGet = npc.FireRocket(vecDest, RocketDamage, RocketSpeed, "models/workshop/weapons/c_models/c_madmilk/c_madmilk.mdl", 1.2);
					//Reducing gravity, reduces speed, lol.
					SetEntityGravity(RocketGet, 1.0); 	
					//I dont care if its not too accurate, ig they suck with the weapon idk lol, lore.
					ArcToLocationViaSpeedProjectile(RocketGet, vecDest, SpeedReturn, 1.75, 1.0);
					Better_Gravity_Rocket(RocketGet, 55.0);
					TeleportEntity(RocketGet, NULL_VECTOR, NULL_VECTOR, SpeedReturn);

					//This will return vecTarget as the speed we need.
				}
				else
				{
					npc.AddGesture("ACT_MP_ATTACK_STAND_ITEM1");
					//They do a direct attack, slow down the rocket and make it deal less damage.
					RocketDamage *= 0.5;
					RocketSpeed *= 0.5;
					npc.FireRocket(vecTarget, RocketDamage, RocketSpeed, "models/workshop/weapons/c_models/c_madmilk/c_madmilk.mdl", 1.2);
				}
				
				if(NpcStats_VestanCallToArms(npc.index))
				{
					npc.m_flNextMeleeAttack = gameTime + 1.0;
				}
				else
				{
					npc.m_flNextMeleeAttack = gameTime + 1.75;
				}
				
				//Launch something to target, unsure if rocket or something else.
				//idea:launch fake rocket with noclip or whatever that passes through all
				//then whereever the orginal goal was, land there.
				//it should be a mortar.
			}
		}
	}
	if(npc.m_flNextMeleeAttack > gameTime)
	{
		return 1;
	}

	//No can shooty.
	//Enemy is close enough.
	if(distance < (NORMAL_ENEMY_MELEE_RANGE_FLOAT_SQUARED * 9.0))
	{
		if(Can_I_See_Enemy_Only(npc.index, npc.m_iTarget))
		{
			float VecAim[3]; WorldSpaceCenter(npc.m_iTarget, VecAim );
			npc.FaceTowards(VecAim, 20000.0);
			//stand
			return 1;
		}
		//cant see enemy somewhy.
		return 0;
	}
	else //enemy is too far away.
	{
		return 0;
	}
}
static void ClotDeath(int entity) 
{
	OshimunoBartender npc = view_as<OshimunoBartender>(entity);

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