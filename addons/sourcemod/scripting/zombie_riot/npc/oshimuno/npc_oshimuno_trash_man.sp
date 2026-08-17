#pragma semicolon 1 //TODO: add a mafia wrath system on death to all attackers/last attacker
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
	"weapons/rocket_shoot.wav"
};

void OshimunoTrashManOnMapStart()
{
	PrecacheSoundArray(g_DeathSounds);
	PrecacheSoundArray(g_HurtSounds);
	PrecacheSoundArray(g_IdleAlertedSounds);
	PrecacheSoundArray(g_RangedAttackSounds);
	NPCData data;
	strcopy(data.Name, sizeof(data.Name), "Trash Man");
	strcopy(data.Plugin, sizeof(data.Plugin), "npc_oshimuno_trash_man");
	strcopy(data.Icon, sizeof(data.Icon), "victoria_basebreaker");
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
	public void PlayRangedSound()
	{
		EmitSoundToAll(g_RangedAttackSounds[GetRandomInt(0, sizeof(g_RangedAttackSounds) - 1)], this.index, SNDCHAN_VOICE, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME);
	}
	
	public OshimunoTrashMan(float vecPos[3], float vecAng[3], int ally)
	{
		OshimunoTrashMan npc = view_as<OshimunoTrashMan>(CClotBody(vecPos, vecAng, "models/player/soldier.mdl", "1.0", "1000", ally));
		
		i_NpcWeight[npc.index] = 1;
		npc.SetActivity("ACT_MP_RUN_PRIMARY");
		KillFeed_SetKillIcon(npc.index, "bottle");
		
		npc.m_iBleedType = BLEEDTYPE_NORMAL;
		npc.m_iStepNoiseType = STEPSOUND_NORMAL;
		npc.m_iNpcStepVariation = STEPTYPE_NORMAL;
		

		func_NPCDeath[npc.index] = ClotDeath;
		func_NPCOnTakeDamage[npc.index] = Generic_OnTakeDamage;
		func_NPCThink[npc.index] = ClotThink;
		
		npc.m_flSpeed = 300.0;

		npc.m_iWearable1 = npc.EquipItem("head", "models/workshop/weapons/c_models/c_dumpster_device/c_dumpster_device.mdl");

		npc.m_iWearable2 = npc.EquipItem("head", "models/player/items/pyro/shootmanyrobots_pyro.mdl");

		npc.m_iWearable3 = npc.EquipItem("head", "models/workshop/player/items/heavy/sbox2014_trash_man/sbox2014_trash_man.mdl");

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

	if(IsValidEnemy(npc.index, npc.m_iTarget))
	{
		float vecTarget[3]; WorldSpaceCenter(npc.m_iTarget, vecTarget );
		float VecSelfNpc[3]; WorldSpaceCenter(npc.index, VecSelfNpc);
		float flDistanceToTarget = GetVectorDistance(vecTarget, VecSelfNpc, true);
		int ActionDo = OshimunoTrashManSelfDefense(npc,GetGameTime(npc.index), flDistanceToTarget); 
		switch(ActionDo)
		{
			case 0:
			{
				npc.StartPathing();
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
				npc.m_flSpeed = 200.0;
			}
			case 1:
			{
				npc.StopPathing();
				npc.m_flSpeed = 0.0;
			}
		}
	}
	npc.PlayIdleSound();
}

static int OshimunoTrashManSelfDefense(OshimunoTrashMan npc, float distance, float gameTime)
{
	if(gameTime > npc.m_flNextMeleeAttack)
	{
		if(distance < (NORMAL_ENEMY_MELEE_RANGE_FLOAT_SQUARED * 30.0))
		{
			float VecAim[3]; WorldSpaceCenter(npc.m_iTarget, VecAim );
			npc.FaceTowards(VecAim, 20000.0);
			int Enemy_I_See = Can_I_See_Enemy(npc.index, npc.m_iTarget);
			if(IsValidEnemy(npc.index, Enemy_I_See))
			{
				npc.m_iTarget = Enemy_I_See;
				npc.PlayRangedSound();
				float RocketDamage = 35.0;
				float RocketSpeed = 900.0;
				float vecTarget[3]; WorldSpaceCenter(npc.m_iTarget, vecTarget);
				float VecStart[3]; WorldSpaceCenter(npc.index, VecStart );
				float vecDest[3];
				vecDest = vecTarget;
				vecDest[0] += GetRandomFloat(-200.0, 200.0);
				vecDest[1] += GetRandomFloat(-200.0, 200.0);
				vecDest[2] += GetRandomFloat(-200.0, 200.0);
				float SpeedReturn[3];
				npc.AddGesture("ACT_MP_RELOAD_STAND_PRIMARY",_,_,_, 0.37);
				int RocketGet;
				switch(GetRandomInt(0,3)) // choose random projectile
				{
					case 0:
					{
						RocketGet = npc.FireRocket(vecDest, RocketDamage, RocketSpeed, "models/weapons/c_models/c_wrench/c_wrench.mdl", 1.2);
					}
					case 1:
					{
						RocketGet = npc.FireRocket(vecDest, RocketDamage, RocketSpeed, "models/workshop/weapons/c_models/c_caber/c_caber.mdl", 1.2);
					}
					case 2:
					{
						RocketGet = npc.FireRocket(vecDest, RocketDamage, RocketSpeed, "mmodels/workshop_partner/weapons/c_models/c_shogun_kunai/c_shogun_kunai.mdl", 1.2);
					}
					case 3:
					{
						RocketGet = npc.FireRocket(vecDest, RocketDamage, RocketSpeed, "models/weapons/c_models/c_knife/c_knife.mdl", 1.2);
					}
				}
				//Reducing gravity, reduces speed, lol.
				SetEntityGravity(RocketGet, 1.0); 	
				//I dont care if its not too accurate, ig they suck with the weapon idk lol, lore.
				ArcToLocationViaSpeedProjectile(RocketGet, vecDest, SpeedReturn, 1.75, 1.0);
				Better_Gravity_Rocket(RocketGet, 55.0);
				TeleportEntity(RocketGet, NULL_VECTOR, NULL_VECTOR, SpeedReturn);

				//This will return vecTarget as the speed we need.

				// else
				// {
				// 	npc.AddGesture("ACT_VILLAGER_ATTACK",_,_,_,1.5);
				// 	//They do a direct attack, slow down the rocket and make it deal less damage.
				// 	RocketDamage *= 0.5;
				// 	RocketSpeed *= 0.5;
				// 	//	npc.PlayRangedSound();
				// 	npc.FireRocket(vecTarget, RocketDamage, RocketSpeed, "models/workshop/weapons/c_models/c_caber/c_caber.mdl", 1.2);
				// }
				npc.m_flNextMeleeAttack = gameTime + 1.75;
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
}