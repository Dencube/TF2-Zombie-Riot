#pragma semicolon 1
#pragma newdecls required

static const char g_ExplosionSounds[] = "weapons/explode1.wav";

static int g_RedPoint;
static int g_Laser;

#define REARMING_DURATION 30.0
#define CANNON_WINDUP 5.0
#define CANNON_EXPLOSION_RANGE 800.0

void OshimunoCannonOnMapStart() // USE `npc_oshimuno_break_boombox` TO KILL THIS NPC AT THE VERY END OF A WAVE
{
	PrecacheSound(g_ExplosionSounds);
	PrecacheModel(ALMINA_BEACON);
	PrecacheModel(LASERBEAM);
	g_Laser = PrecacheModel(LASERBEAM);
	g_RedPoint = PrecacheModel("sprites/redglow1.vmt");
	NPCData data;
	strcopy(data.Name, sizeof(data.Name), "Saigai Cannon");
	strcopy(data.Plugin, sizeof(data.Plugin), "npc_oshimuno_cannon");
	strcopy(data.Icon, sizeof(data.Icon), "victoria_basebreaker");
	data.IconCustom = true;
	data.Flags = 0;
	data.Category = Type_Oshimuno;
	data.Func = ClotSummon;
	NPC_Add(data);
}

static any ClotSummon(int client, float vecPos[3], float vecAng[3], int team, const char[] data)
{
	return OshimunoCannon(vecPos, vecAng, team, data);
}

methodmap OshimunoCannon < CClotBody
{
	public void PlayExplosionSound() 
	{
		EmitSoundToAll(g_ExplosionSounds, this.index, SNDCHAN_VOICE, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, GetRandomInt(80,125));
	}
	property float m_flKnockbackCooldown
	{
		public get()							{ return fl_AbilityOrAttack[this.index][0]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][0] = TempValueForProperty; }
	}
	property float m_flFiringWindup
	{
		public get()							{ return fl_AbilityOrAttack[this.index][1]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][1] = TempValueForProperty; }
	}
	property float m_flRearmingDuration
	{
		public get()							{ return fl_AbilityOrAttack[this.index][2]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][2] = TempValueForProperty; }
	}
	property int m_iWaveCounter
	{
		public get()							{ return i_State[this.index]; }
		public set(int TempValueForProperty) 	{ i_State[this.index] = TempValueForProperty; }
	}
	property int m_iShellsLeft
	{
		public get()							{ return i_AttacksTillMegahit[this.index]; }
		public set(int TempValueForProperty) 	{ i_AttacksTillMegahit[this.index] = TempValueForProperty; }
	}
	public OshimunoCannon(float vecPos[3], float vecAng[3], int ally, const char[] data)
	{	
		OshimunoCannon npc = view_as<OshimunoCannon>(CClotBody(vecPos, vecAng, ALMINA_BEACON, "0.4", "120000", ally));
		SetEntProp(npc.index, Prop_Send, "m_nSkin", 1);

		float gameTime = GetGameTime(npc.index);
		i_NpcWeight[npc.index] = 999;
		npc.SetActivity("ACT_MP_RUN_MELEE");
		KillFeed_SetKillIcon(npc.index, "megaton");

		npc.m_iBleedType = BLEEDTYPE_METAL;
		npc.m_iStepNoiseType = STEPSOUND_NORMAL;
		npc.m_iNpcStepVariation = STEPTYPE_NORMAL;
		

		func_NPCDeath[npc.index] = ClotDeath;
		func_NPCOnTakeDamage[npc.index] = CannonOnTakeDamage;
		func_NPCThink[npc.index] = ClotThink;
		
		npc.m_flSpeed = 0.0;
		npc.m_iWaveCounter = -1;
		npc.Anger = true;
		npc.m_flNextMeleeAttack = gameTime + 4.0;
		//b_NoHealthbar[npc.index] = 1;
		npc.m_bDissapearOnDeath = true;
		npc.m_bStaticNPC = true;
		
   		AddNpcToAliveList(npc.index, 1);
		b_NpcUnableToDie[npc.index] = true;
		b_NpcIsTeamkiller[npc.index] = true;
		b_ThisEntityIgnoredByOtherNpcsAggro[npc.index] = true;
		b_ThisEntityIgnoredBeingCarried[npc.index] = true;
		f_CheckIfStuckPlayerDelay[npc.index] = FAR_FUTURE;
		ApplyStatusEffect(npc.index, npc.index, "Intangible", 999999.0);
		SetEntityRenderColor(npc.index, 255, 255, 255, 255);
		if(StrContains(data, "spawn_notif") != -1)
		{
			if(ally != TFTeam_Red)
			{
				if(LastSpawnDiversio < GetGameTime())
				{
					EmitSoundToAll("weapons/sniper_railgun_world_reload.wav", _, _, _, _, 1.0);	
					EmitSoundToAll("weapons/sniper_railgun_world_reload.wav", _, _, _, _, 1.0);	
					for(int client_check=1; client_check<=MaxClients; client_check++)
					{
						if(IsClientInGame(client_check) && !IsFakeClient(client_check))
						{
							SetGlobalTransTarget(client_check);
							ShowGameText(client_check, "voice_player", 1, "%t", "A cannon has been setup!");
						}
					}
				}
				LastSpawnDiversio = GetGameTime() + 10.0;
			}
		}
		npc.StopPathing();
		return npc;
	}
}

static void ClotThink(int iNPC)
{
	OshimunoCannon npc = view_as<OshimunoCannon>(iNPC);

	float gameTime = GetGameTime(npc.index);
	if(npc.m_flNextDelayTime > gameTime)
		return;
	
	npc.m_flNextDelayTime = gameTime + DEFAULT_UPDATE_DELAY_FLOAT;
	npc.Update();

	
	if(npc.m_flNextThinkTime > gameTime)
		return;
	
	npc.m_flNextThinkTime = gameTime + 0.1;
	
	if(npc.m_flFiringWindup)
	{
		if(npc.m_flFiringWindup > gameTime)
		{
			if(npc.m_iTarget > 0) // update if target is alive. if they somehow die before it fires save their last position
			{
				float vecTarget[3]; WorldSpaceCenter(npc.m_iTarget, vecTarget);
				f3_NpcSavePos[npc.index] = vecTarget;
			}
			float position[3], Temp_Pos[3], Temp_Pos2[3];
			float VecSelfNpc[3]; WorldSpaceCenter(npc.index, VecSelfNpc);
			float TimeLeft = npc.m_flFiringWindup - gameTime;
			//CPrintToChatAll("TIMELEFT:%f ", TimeLeft);
			int RGBColor[3]={255, 200, 80};
			position[0] = f3_NpcSavePos[npc.index][0];
			position[1] = f3_NpcSavePos[npc.index][1];
			position[2] = f3_NpcSavePos[npc.index][2] + 3000.0;
			Temp_Pos[0] = position[0];
			Temp_Pos[1] = position[1];
			Temp_Pos[2] = position[2] - 3000.0;
			VecSelfNpc[2] += 150.0; // laser comes from the cannon not the bottom
			Temp_Pos2[0] = VecSelfNpc[0];
			Temp_Pos2[1] = VecSelfNpc[1];
			Temp_Pos2[2] = VecSelfNpc[2] + 2850.0;
			spawnRing_Vectors(Temp_Pos, CANNON_EXPLOSION_RANGE/CANNON_WINDUP*TimeLeft, 0.0, 0.0, 0.0, LASERBEAM, 255, 255, 255, 150, 1, 0.1, 3.0, 0.1, 3);
			spawnRing_Vectors(Temp_Pos, CANNON_EXPLOSION_RANGE, 0.0, 0.0, 0.0, LASERBEAM, RGBColor[0], RGBColor[1], RGBColor[2], 150, 1, 0.1, 3.0, 0.1, 3);
			TE_SetupBeamPoints(Temp_Pos, position, g_Laser, -1, 0, 0, 0.1, 0.0, 25.0, 0, 0.0, {145, 47, 47, 150}, 3); // laser above target
			TE_SendToAll();
			TE_SetupGlowSprite(Temp_Pos, g_RedPoint, 0.1, 1.0, 255); // pointer on the target
			TE_SendToAll();
			TE_SetupBeamPoints(VecSelfNpc, Temp_Pos2, g_Laser, -1, 0, 0, 0.1, 0.0, 25.0, 0, 0.0, {145, 47, 47, 150}, 3); // laser from the cannon
			TE_SendToAll();
			SetEntityRenderColor(npc.index, 255, RoundToNearest(TimeLeft*50.0), RoundToNearest(TimeLeft*50.0), 255);
		}
		if(npc.m_flFiringWindup < gameTime + 1.0 && !npc.Anger)
		{
			float VecSelfNpc[3]; WorldSpaceCenter(npc.index, VecSelfNpc);
			EmitSoundToAll("weapons/drg_wrench_teleport.wav", 0, SNDCHAN_AUTO, 90, SND_NOFLAGS, 0.8, SNDPITCH_NORMAL, -1, VecSelfNpc);
			npc.Anger = true;
		}
		if(npc.m_flFiringWindup < gameTime && npc.m_flNextMeleeAttack < gameTime)
		{
			if(npc.m_iOverlordComboAttack >= 3)
			{
				SetEntityRenderColor(npc.index, 255, 255, 255, 255);
				if(npc.m_iShellsLeft == 0) // last shot fired
					SetEntityRenderColor(npc.index, 0, 0, 0, 255);
				npc.m_iOverlordComboAttack = 0;
				npc.m_iTarget = -1;
				npc.m_flFiringWindup = 0.0;
				npc.Anger = false;
				return;
			}
			float position2[3];
			position2[0] = f3_NpcSavePos[npc.index][0] + GetRandomFloat(-450.0, 450.0);
			position2[1] = f3_NpcSavePos[npc.index][1] + GetRandomFloat(-450.0, 450.0);
			position2[2] = f3_NpcSavePos[npc.index][2];
			Explode_Logic_Custom(30000.0, -1, npc.index, -1, f3_NpcSavePos[npc.index], CANNON_EXPLOSION_RANGE, 1.0, 0.8, false, 40, _, _, _, CannonPreExplosion);
			ParticleEffectAt(position2, "hightower_explosion", 2.0);
			if(npc.m_iOverlordComboAttack == 0) // only play once
			{
				CreateEarthquake(f3_NpcSavePos[npc.index], 1.2, 2300.0, 24.0, 255.0);
				EmitSoundToAll("items/cart_explode.wav", 0, SNDCHAN_AUTO, 90, SND_NOFLAGS, 0.8, SNDPITCH_NORMAL, -1, f3_NpcSavePos[npc.index]);
			}
			npc.m_flNextMeleeAttack = gameTime + 0.12;
			npc.m_iOverlordComboAttack++;
		}
	}
	if(npc.m_flRearmingDuration)
	{
		if(npc.m_flRearmingDuration < gameTime)
		{
			b_NpcIsInvulnerable[npc.index] = false;
			npc.m_flRearmingDuration = 0.0;
		}
	}
	if(Waves_GetRoundScale() != npc.m_iWaveCounter)
	{
		npc.m_iWaveCounter = Waves_GetRoundScale();
		/* not sure if the round reset should completely reset the cannon
		b_NpcIsInvulnerable[npc.index] = false;
		SetEntityRenderColor(npc.index, 255, 255, 255, 255);
		npc.m_iOverlordComboAttack = 0;
		npc.m_iTarget = -1;
		npc.Anger = false;
		*/
		switch(npc.m_iWaveCounter)
		{
			case 36:
			{
				npc.m_iShellsLeft = 2;
			}
			case 37:
			{
				npc.m_iShellsLeft = 2;
			}
			case 38:
			{
				npc.m_iShellsLeft = 3;
			}
			case 39:
			{
				npc.m_iShellsLeft = 3;
			}
			case 40:
			{
				npc.m_iShellsLeft = 3;
			}
			default: // for beyond w40
			{
				npc.m_iShellsLeft = 4;
			}
		}
	}
}
static float CannonPreExplosion(int attacker, int victim, float &damage, int weapon)
{
	if(GetTeam(attacker) != GetTeam(victim)) // Don't hit players
	{
		damage = 0.0;
		return 0.0;
	}
	if(b_thisNpcIsABoss[victim] || b_thisNpcIsARaid[victim])
		return 10000.0;	// 10k dmg vs bosses
	
	return damage;
}
static Action CannonOnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{	
	OshimunoCannon npc = view_as<OshimunoCannon>(victim);
	float gameTime = GetGameTime(npc.index);
	if(GetEntProp(npc.index, Prop_Data, "m_iHealth") <= 1)
	{
		b_NpcIsInvulnerable[npc.index] = true;
		float healing = float(ReturnEntityMaxHealth(npc.index));
		HealEntityGlobal(npc.index, npc.index, healing, 1.0, REARMING_DURATION, HEAL_ABSOLUTE);
		NPCStats_RemoveAllDebuffs(npc.index, REARMING_DURATION);
		npc.m_flRearmingDuration = gameTime + REARMING_DURATION;
		if(npc.m_iShellsLeft > 0)
		{
			npc.m_iShellsLeft--;
			int highestHp, targetHp, picked;
			for(int i; i < i_MaxcountNpcTotal; i++)	// FIND THE HIGHEST HP ENEMY ON THE MAP
			{
				int target = EntRefToEntIndexFast(i_ObjectsNpcsTotal[i]); 
				if(IsValidEntity(target))
				{
					if(target != INVALID_ENT_REFERENCE && target != npc.index && GetTeam(target) == GetTeam(npc.index) && IsEntityAlive(target))
					{
						targetHp = GetEntProp(target, Prop_Data, "m_iHealth");
						if(targetHp > highestHp)
						{
							highestHp = targetHp;
							picked = target;
						}
					}
				}
			}
			npc.m_iTarget = picked;
			npc.m_flFiringWindup = gameTime + CANNON_WINDUP;
		}
	}
	return Plugin_Changed;
}

static void ClotDeath(int entity)
{
	OshimunoCannon npc = view_as<OshimunoCannon>(entity);
	
	if(IsValidEntity(npc.m_iWearable1))
		RemoveEntity(npc.m_iWearable1);
	
}
