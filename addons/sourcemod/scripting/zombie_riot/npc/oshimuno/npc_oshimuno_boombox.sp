#pragma semicolon 1
#pragma newdecls required

static const char g_ExplosionSounds[] = "weapons/explode1.wav";

#define BOOMBOX_RANGE 245.0
#define BOOMBOX_RANGE_TRACE 275.0 //trace is larger than the explosion so it feels more intuitive
#define KNOCKBACK_COOLDOWN 1.5
void OshimunoBoomboxOnMapStart() // USE `npc_oshimuno_break_boombox` TO KILL THIS NPC AT THE VERY END OF A WAVE
{
	PrecacheModel("models/buildables/dispenser_light.mdl");
	PrecacheSound(g_ExplosionSounds);
	NPCData data;
	strcopy(data.Name, sizeof(data.Name), "Shibuya Boombox");
	strcopy(data.Plugin, sizeof(data.Plugin), "npc_oshimuno_boombox");
	strcopy(data.Icon, sizeof(data.Icon), "victoria_basebreaker");
	data.IconCustom = true;
	data.Flags = 0;
	data.Category = Type_Outlaws;
	data.Func = ClotSummon;
	NPC_Add(data);
}

static any ClotSummon(int client, float vecPos[3], float vecAng[3], int team)
{
	return OshimunoBoombox(vecPos, vecAng, team);
}

methodmap OshimunoBoombox < CClotBody
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
	public OshimunoBoombox(float vecPos[3], float vecAng[3], int ally)
	{	
		OshimunoBoombox npc = view_as<OshimunoBoombox>(CClotBody(vecPos, vecAng, "models/buildables/dispenser_lvl3_light.mdl", "1.35", "1000", ally));
		SetEntProp(npc.index, Prop_Send, "m_nSkin", 1);
		
		// OshimunoBoombox npc = view_as<OshimunoBoombox>(CClotBody(vecPos, {-7.63202, 345.066, -44.5095}, "models/player/items/scout/boombox.mdl", "6.0", "15000", ally));
		// boombox model use if the offset can be somehow fixed

		float gameTime = GetGameTime(npc.index);
		i_NpcWeight[npc.index] = 2;
		npc.SetActivity("ACT_MP_RUN_MELEE");
		KillFeed_SetKillIcon(npc.index, "megaton");

		npc.m_iBleedType = BLEEDTYPE_METAL;
		npc.m_iStepNoiseType = STEPSOUND_NORMAL;
		npc.m_iNpcStepVariation = STEPTYPE_NORMAL;
		

		func_NPCDeath[npc.index] = ClotDeath;
		func_NPCOnTakeDamage[npc.index] = BoomboxOnTakeDamage;
		func_NPCThink[npc.index] = ClotThink;
		
		npc.m_flSpeed = 0.0;
		SetMoraleDoAlmina(npc.index, 100.0);
		npc.m_flNextMeleeAttack = gameTime + 4.0;
		b_NoHealthbar[npc.index] = 1;
		npc.m_bDissapearOnDeath = true;
		npc.m_bStaticNPC = true;
   		AddNpcToAliveList(npc.index, 1);
		/*b_ThisEntityIgnoredByOtherNpcsAggro[npc.index] = true;*/ // this makes djs unable to grab the boombox || TODO: make it so only rebels ignore the boombox
		npc.StopPathing();
		return npc;
	}
}

static void ClotThink(int iNPC)
{
	OshimunoBoombox npc = view_as<OshimunoBoombox>(iNPC);

	float gameTime = GetGameTime(npc.index);
	if(npc.m_flNextDelayTime > gameTime)
		return;
	
	npc.m_flNextDelayTime = gameTime + DEFAULT_UPDATE_DELAY_FLOAT;
	npc.Update();

	
	if(npc.m_flNextThinkTime > gameTime)
		return;
	
	npc.m_flNextThinkTime = gameTime + 0.1;

	float VecSelfNpc[3]; WorldSpaceCenter(npc.index, VecSelfNpc);
	if(npc.m_flNextMeleeAttack < gameTime)
	{
		npc.m_flNextMeleeAttack = gameTime + 4.0;

		spawnRing_Vectors(VecSelfNpc, BOOMBOX_RANGE, 0.0, 0.0, 15.0, "materials/sprites/laserbeam.vmt", 50, 225, 225, 175, 1, 0.5, 6.0, 0.1, 1, 640.0);
		Explode_Logic_Custom(150.0, -1, npc.index, -1, VecSelfNpc, BOOMBOX_RANGE, _, 0.75, false, _, false);
		AlminaMoraleGivingDo(npc.index, GetGameTime(npc.index), false, BOOMBOX_RANGE);
		npc.PlayExplosionSound();
	}

	if(IsValidEntity(npc.m_iTargetAlly)) // for removing dj ownership
	{
		if(!IsEntityAlive(npc.m_iTargetAlly))
		{
			npc.m_iTargetAlly = INVALID_ENT_REFERENCE;
		}
	}
	
	float VecSelfNpcabs[3]; GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", VecSelfNpcabs);
	spawnRing_Vectors(VecSelfNpcabs, BOOMBOX_RANGE_TRACE * 2.0, 0.0, 0.0, 15.0, "materials/sprites/laserbeam.vmt", 15, 15, 225, 200, 1, /*duration*/ 0.11, 5.0, 2.0, 1);

}

static Action BoomboxOnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{	
	OshimunoBoombox npc = view_as<OshimunoBoombox>(victim);
	float gameTime = GetGameTime(npc.index);
	if(npc.m_flKnockbackCooldown < gameTime)
	{
		if((damagetype & (DMG_CLUB)) &&! (i_HexCustomDamageTypes[victim] & ZR_DAMAGE_DO_NOT_APPLY_BURN_OR_BLEED)) // take knockback from direct melee hits
		{
			Custom_Knockback(attacker, npc.index, 460.0, true, true);
			npc.m_flKnockbackCooldown = gameTime + KNOCKBACK_COOLDOWN;
		}
	}
	damage = 0.0; // THIS MAKES IT SO THE BOOMBOX CANNOT DIE BY NORMAL MEANS || USE `npc_oshimuno_break_boombox` TO KILL THIS NPC AT THE VERY END OF A WAVE
	return Plugin_Changed;
}

static void ClotDeath(int entity)
{
	OshimunoBoombox npc = view_as<OshimunoBoombox>(entity);
	
	if(IsValidEntity(npc.m_iWearable1))
		RemoveEntity(npc.m_iWearable1);
	
}
