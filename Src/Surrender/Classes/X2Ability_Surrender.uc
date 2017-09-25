class X2Ability_Surrender extends X2Ability config(Surrender);

var name SurrenderName;
var X2Condition_UnitProperty Squadmate;

var config int StabilizeBaseChance;
var config int StabilizeModifier;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	// Surrender is split into two abilities:
	// Surrender removes mind control and stasis, and invokes the next step
	// BeCaptured causes the squad to be rendered unconsicous or killed, collectively
	Templates.AddItem(CreateSurrender());
	Templates.AddItem(CreateBeCaptured());

	return Templates;
}

// prep for capturing, remove stasis so surrender can hit properly and mind control because it makes sense
static function X2DataTemplate CreateSurrender()
{
	local X2AbilityTemplate Template;
	local X2Condition_Surrender SurrenderCondition;
	local X2Condition_UnitStatCheck UnitStatCheckCondition;
	local array<name> SkipExclusions;
	local X2AbilityCost_ActionPoints ActionPointCost;
	local X2Effect_RemoveEffects RemoveEffects;

	`CREATE_X2ABILITY_TEMPLATE(Template, default.SurrenderName);

	// disable for multiplayer
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer);

	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_ShowIfAvailable;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.PLACE_EVAC_PRIORITY;
	Template.Hostility = eHostility_Defensive;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_voidadept";
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.bAllowedByDefault = true;

	Template.bSkipFireAction = true;
	Template.bLimitTargetIcons = true;

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	// target an arbitrary squad member and all their allies
	Template.AbilityTargetStyle = default.SingleTargetWithSelf;
	Template.AbilityMultiTargetStyle = new class'X2AbilityMultiTarget_AllAllies';
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	Template.AbilityToHitCalc = default.Deadeye;

	// shooter conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	
	SurrenderCondition = new class'X2Condition_Surrender';

	Template.AbilityShooterConditions.AddItem(SurrenderCondition);

	// allow anyone to surrender
	SkipExclusions.AddItem(class'X2Ability_CarryUnit'.default.CarryUnitEffectName);
	SkipExclusions.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
	SkipExclusions.AddItem(class'X2StatusEffects'.default.BurningName);

	Template.AddShooterEffectExclusions(SkipExclusions);
	
	Template.AbilityTargetConditions.AddItem(default.Squadmate);

	// exclude units who are dead and not bleeding out
	UnitStatCheckCondition = new class'X2Condition_UnitStatCheck';
	UnitStatCheckCondition.AddCheckStat(eStat_HP, 0, eCheck_GreaterThan);
	Template.AbilityTargetConditions.AddItem(UnitStatCheckCondition);


	// remove stasis so surrender can hit properly
	// free mind controlled allies, since they shouldn't stick around for capturing/dying
	RemoveEffects = new class'X2Effect_RemoveEffects';
	// todo: remove mind control in the next step?
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2Effect_MindControl'.default.EffectName);
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2Effect_Stasis'.default.EffectName);
	// they won't need it where they're going and it blocks unconsciousness
	//RemoveEffects.EffectNamesToRemove.AddItem('MindShieldImmunity');
	RemoveEffects.bApplyOnMiss = true; // will miss if stasised

	Template.AddTargetEffect(RemoveEffects);
	Template.AddMultiTargetEffect(RemoveEffects);

	Template.AdditionalAbilities.AddItem('BeCaptured');
	Template.PostActivationEvents.AddItem('Surrender');

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	return Template;
}

// handles unconciousness/death
static function X2DataTemplate CreateBeCaptured()
{
	local X2AbilityTemplate Template;
	local X2Effect UnconsciousEffect, ExecutedEffect;
	local X2Effect_RemoveEffects StabilizeEffect;
	local X2Condition_UnitEffects ExcludeEffects, AlreadyDying;
	local X2Condition_UnitStatCheck UnitStatCheckCondition;
	local X2AbilityTrigger_EventListener EventListener;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'BeCaptured');

	// ability/display info
	Template.Hostility = eHostility_Defensive;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.bAllowedByDefault = true;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;

	// hit chance
	Template.AbilityToHitCalc = new class'SurrenderAbilityToHitCalc_AllOrNothing';

	// targeting
	Template.AbilityTargetStyle = default.SingleTargetWithSelf;
	Template.AbilityMultiTargetStyle = new class'X2AbilityMultiTarget_AllAllies';

	// should exclude units that were mind controlled until the previous ability
	Template.AbilityTargetConditions.AddItem(default.Squadmate);


	// exclude units that are already unconscious (will be spared on execution)
	ExcludeEffects = new class'X2Condition_UnitEffects';
	ExcludeEffects.AddExcludeEffect(class'X2StatusEffects'.default.UnconsciousName, 'AA_UnitIsUnconscious');

	Template.AbilityTargetConditions.AddItem(ExcludeEffects);

	// exclude units who are dead and not bleeding out
	UnitStatCheckCondition = new class'X2Condition_UnitStatCheck';
	UnitStatCheckCondition.AddCheckStat(eStat_HP, 0, eCheck_GreaterThan);
	Template.AbilityTargetConditions.AddItem(UnitStatCheckCondition);

	// trigger
	EventListener = new class'X2AbilityTrigger_EventListener';
	EventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventListener.ListenerData.EventID = 'Surrender';
	EventListener.ListenerData.Filter = eFilter_Unit;
	EventListener.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	Template.AbilityTriggers.AddItem(EventListener);

	// effects

	// on success, stabilize bleeding out units so they can be captured
	// normal stabilize adds unconsciousness anyway so this should work out
	StabilizeEffect = new class'X2Effect_RemoveEffects';
	StabilizeEffect.EffectNamesToRemove.AddItem(class'X2StatusEffects'.default.BleedingOutName);
	StabilizeEffect.ApplyChanceFn = ApplyChance_Stabilize;
	Template.AddTargetEffect(StabilizeEffect);
	Template.AddMultiTargetEffect(StabilizeEffect);

	UnconsciousEffect = class'X2StatusEffects'.static.CreateUnconsciousStatusEffect();
	UnconsciousEffect.DamageTypes.Length = 0; // bypass any effects that make units immune to unconsciousness
	Template.AddTargetEffect(UnconsciousEffect);
	Template.AddMultiTargetEffect(UnconsciousEffect);

	ExecutedEffect = new class'X2Effect_ExecutedNoBleedout';
	ExecutedEffect.bApplyOnHit = false;
	ExecutedEffect.bApplyOnMiss = true;

	// this doesn't really matter but
	AlreadyDying = new class'X2Condition_UnitEffects';
	AlreadyDying.AddExcludeEffect(class'X2StatusEffects'.default.BleedingOutName, 'AA_UnitIsBleedingOut');
	Template.AddTargetEffect(ExecutedEffect);
	Template.AddMultiTargetEffect(ExecutedEffect);


	// need special handling for misses
	Template.BuildNewGameStateFn = Surrender_BuildGameState;
	Template.BuildVisualizationFn = Surrender_BuildVisualization;

	return Template;
}

static function name ApplyChance_Stabilize(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState)
{
	local XComGameState_Unit Target;
	local XComGameState_Effect EffectState;
	local int ChanceSuccess, idx;

	Target = XComGameState_Unit(kNewTargetState);
	if(none == Target)
	{
		return 'AA_NotAUnit';
	}

	if(!Target.IsBleedingOut())
	{
		return 'AA_UnitIsImmune';
	}

	ChanceSuccess = default.StabilizeBaseChance;
	EffectState = Target.GetUnitAffectedByEffectState(class'X2StatusEffects'.default.BleedingOutName);

	for(idx = 2; idx <= EffectState.iTurnsRemaining; ++idx)
	{
		ChanceSuccess += default.StabilizeModifier;
	}

	if(`SYNC_RAND_STATIC(100) < ChanceSuccess)
	{
		return 'AA_Success';
	}

	return 'AA_EffectChanceFailed';
}

// the memorial will list soldiers killed by a failed surrender as killed by the surrendering soldier
// which is all well and good except it counts as friendly fire, which is a bit silly
// so this manually sets it to use X2Effect_Executed's label instead
// I feel like it makes slightly more sense to put it here than in visualization
simulated function XComGameState Surrender_BuildGameState(XComGameStateContext Context)
{
	local XComGameState NewGameState;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Unit Unit;

	// add the relevant effects normally, then check if cause of death should be updated

	// the usual handling
	NewGameState = TypicalAbility_BuildGameState(Context);

	// todo: why is FillOutGameState getting warnings
	//		 "Accessed array 'X2Ability_Surrender_0.MultiTargetEffectsOverrides' out of bounds (0/0)"

	AbilityContext = XComGameStateContext_Ability(Context);

	// check if they died
	if(AbilityContext.ResultContext.HitResult == eHit_Miss)
	{
		foreach NewGameState.IterateByClassType(class'XComGameState_Unit', Unit)
		{
			// if this unit was targeted, cause of death needs to be fixed so it doesn't blame it on friendly fire
			if(Unit.IsDead() && (AbilityContext.InputContext.PrimaryTarget.ObjectID == Unit.ObjectID || (INDEX_NONE != AbilityContext.InputContext.MultiTargets.find('ObjectID', Unit.ObjectID))))
			{
				// skip soldiers that evac'd but count as targets for whatever reason
				// it's not like the ability kills them I just don't like the idea of setting their cause of death
				// not sure if soldiers who already died and were evac'd would show up but this should cover that too
				if(Unit.bRemovedFromPlay)
				{
					continue;
				}

				Unit.m_strCauseOfDeath = class'X2Effect_Executed'.default.UnitExecutedFlyover;
			}
		}
	}

	return NewGameState;
}

simulated function Surrender_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateContext_Ability AbilityContext;
	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());

	// surrender failed, you get to watch your squad die
	// also since the gremlin will still be told to die, it will look less silly if the specialist isn't standing there complete unfazed
	if(AbilityContext.ResultContext.HitResult == eHit_Miss)
	{
		TypicalAbility_BuildVisualization(VisualizeGameState);
	}

	// surrender succeeded, don't visualize everyone falling unconscious
}

defaultproperties
{
	SurrenderName = "Surrender"

	Begin Object Class=X2Condition_UnitProperty Name=DefaultSurrenderSquadmate
		ExcludeHostileToSource=true
		ExcludeFriendlyToSource=false
		ExcludeDead=false // needed to target units who are bleeding out. To skip units who really are dead, check HP > 0
		RequireSquadmates=true
		ExcludeInStasis=false
		ExcludePanicked=false
		FailOnNonUnits=true
	End Object
	Squadmate=DefaultSurrenderSquadmate
}