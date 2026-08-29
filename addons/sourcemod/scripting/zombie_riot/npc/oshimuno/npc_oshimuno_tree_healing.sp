#pragma semicolon 1
#pragma newdecls required



static const char g_DeathSounds[][] = 
{
	")physics/metal/metal_canister_impact_hard1.wav",
	")physics/metal/metal_canister_impact_hard2.wav",
	")physics/metal/metal_canister_impact_hard3.wav",
};

static const char g_HurtSounds[][] = 
{
	")physics/metal/metal_box_impact_bullet1.wav",
	")physics/metal/metal_box_impact_bullet2.wav",
	")physics/metal/metal_box_impact_bullet3.wav",
};

static const char g_GiveArmor[][] = 
{
	"items/smallmedkit1.wav",
};

#define RANGE 330.0

void OshimunoTreeHealingOnMapStart()
{
	PrecacheSoundArray(g_DeathSounds);
	PrecacheSoundArray(g_HurtSounds);
	PrecacheSoundArray(g_GiveArmor);
	PrecacheModel("models/props_japan/sakura_tree01.mdl");
	NPCData data;
	strcopy(data.Name, sizeof(data.Name), "Tree Healing");
	strcopy(data.Plugin, sizeof(data.Plugin), "npc_oshimuno_tree_healing");
	strcopy(data.Icon, sizeof(data.Icon), "");
	data.Flags = -1;
	data.Category = Type_Oshimuno;
	data.Func = ClotSummon;
	NPC_Add(data);
}


static any ClotSummon(int client, float vecPos[3], float vecAng[3], int team)
{
	return  OshimunoTreeHealing(vecPos, vecAng, team);
}
methodmap  OshimunoTreeHealing < CClotBody
{
	property float m_flSuicideTimer
	{
		public get()							{ return fl_AbilityOrAttack[this.index][0]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][0] = TempValueForProperty; }
	}
	public void PlayHurtSound() 
	{
		if(this.m_flNextHurtSound > GetGameTime(this.index))
			return;
			
		this.m_flNextHurtSound = GetGameTime(this.index) + 0.4;
		
		EmitSoundToAll(g_HurtSounds[GetRandomInt(0, sizeof(g_HurtSounds) - 1)], this.index, SNDCHAN_VOICE, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME);
		
	}
	
	public void PlayDeathSound() 
	{
		EmitSoundToAll(g_DeathSounds[GetRandomInt(0, sizeof(g_DeathSounds) - 1)], this.index, SNDCHAN_VOICE, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME);
	}
	public void PlayArmorSound() 
	{
		EmitSoundToAll(g_GiveArmor[GetRandomInt(0, sizeof(g_GiveArmor) - 1)], this.index, SNDCHAN_VOICE, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME - 0.1, 70);
	}

	public OshimunoTreeHealing(float vecPos[3], float vecAng[3], int ally)
	{
		OshimunoTreeHealing npc = view_as<OshimunoTreeHealing>(CClotBody(vecPos, vecAng, "models/props_japan/sakura_tree01.mdl", "0.25", "1000", ally, .NpcTypeLogic = 1));
		SetEntityRenderColor(npc.index, 65, 255, 45, 200); //green tiny baby tree
		
		i_NpcWeight[npc.index] = 999;
		
		npc.m_flNextMeleeAttack = 0.0;
		
		npc.m_flMeleeArmor = 2.5;
		npc.m_flRangedArmor = 1.0;

		npc.m_iBleedType = BLEEDTYPE_METAL;
		npc.m_iStepNoiseType = 0;	
		npc.m_iNpcStepVariation = 0;
		npc.m_bDissapearOnDeath = true;
		
		Is_a_Medic[npc.index] = true;
		i_NpcIsABuilding[npc.index] = true;
		MakeObjectIntangeable(npc.index);
		b_DoNotUnStuck[npc.index] = true;
		b_ThisNpcIsImmuneToNuke[npc.index] = true;
		b_NoKnockbackFromSources[npc.index] = true;
		b_ThisEntityIgnored[npc.index] = true;
		b_NoKillFeed[npc.index] = true;
		b_CantCollidie[npc.index] = true; 
		b_CantCollidieAlly[npc.index] = true; 
		b_ThisEntityIgnoredBeingCarried[npc.index] = true; //cant be targeted AND wont do npc collsiions
		npc.m_bDissapearOnDeath = true;
		b_HideHealth[npc.index] = true;
		b_NoHealthbar[npc.index] = 1;

		//these are default settings! please redefine these when spawning!

		func_NPCDeath[npc.index] = ClotDeath;
		func_NPCOnTakeDamage[npc.index] = Generic_OnTakeDamage;
		func_NPCThink[npc.index] = ClotThink;
		
		//IDLE
		npc.m_iState = 0;
		npc.m_flSpeed = 0.0;

		npc.m_flSuicideTimer = GetGameTime() + 12.0;
		//counts as a static npc, means it wont count towards NPC limit.
		AddNpcToAliveList(npc.index, 1);
		SetEntityRenderMode(npc.index, RENDER_TRANSCOLOR);
		SetEntityRenderColor(npc.index, 255, 255, 255, 150);

		return npc;
	}
}

static void ClotThink(int iNPC)
{
	OshimunoTreeHealing npc = view_as<OshimunoTreeHealing>(iNPC);
	if(npc.m_flNextDelayTime > GetGameTime(npc.index))
	{
		return;
	}
	npc.m_flNextDelayTime = GetGameTime(npc.index) + DEFAULT_UPDATE_DELAY_FLOAT;
	npc.Update();

	if(npc.m_blPlayHurtAnimation)
	{
		npc.m_blPlayHurtAnimation = false;
		npc.PlayHurtSound();
	}
	//We only give a time untill we are killed.
	if(npc.m_flSuicideTimer < GetGameTime())
	{
		SmiteNpcToDeath(npc.index);
		return;
	}
	if(npc.m_flNextThinkTime > GetGameTime(npc.index))
	{
		return;
	}
	if(npc.m_iState == 0)
	{
		npc.m_iState = 1;
		SetEntityRenderMode(npc.index, RENDER_NORMAL);
		SetEntityRenderColor(npc.index, 255, 255, 255, 255);
	}
	npc.m_flNextThinkTime = GetGameTime(npc.index) + 0.3;
	ExpidonsaGroupHeal(npc.index, RANGE, 99, 0.0, 1.0, false, OshimunoTreeHealingGiveBuffs, _, true);
	OshimunoTreeHealingEffect(npc.index);
}

void OshimunoTreeHealingEffect(int entity)
{
	float ProjectileLoc[3];
	OshimunoTreeHealing npc1 = view_as<OshimunoTreeHealing>(entity);
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", ProjectileLoc);
	spawnRing_Vectors(ProjectileLoc, RANGE * 2.25, 0.0, 0.0, 10.0, "materials/sprites/laserbeam.vmt", 65, 255, 45, 75, 1, 0.51, 5.0, 0.1, 3);	
	npc1.PlayArmorSound();
}

void OshimunoTreeHealingGiveBuffs(int entity, int victim, float &healingammount)
{
	float HealBy = 0.05;
	if(GetTeam(entity) != GetTeam(victim))
	{
		ApplyStatusEffect(entity, victim, "Defensive Backup", 1.0);
		if(HasSpecificBuff(victim, "Recently Healed Supplies"))
		{
			HealBy = 0.0;
			ApplyStatusEffect(entity, victim, "Recently Healed Supplies", 0.5);
		}
	}
	else //prevent healing npcs
	{
		HealBy = 0.0;
	}
	if(HealBy <= 0.0)
		return;
	int health = ReturnEntityMaxHealth(victim);
	HealEntityGlobal(entity, victim, float(health) * HealBy, 1.0, 0.5);
	
}

static void ClotDeath(int entity)
{
	OshimunoTreeHealing npc = view_as<OshimunoTreeHealing>(entity);
	npc.PlayDeathSound();	
}