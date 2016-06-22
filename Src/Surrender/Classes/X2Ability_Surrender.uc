class X2Ability_Surrender extends X2Ability;

var name SurrenderName;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateSurrender());

	return Templates;
}


static function X2DataTemplate CreateSurrender()
{
	local X2AbilityTemplate Template;
	// IsAlly is all allies, CanSurrender is all allies who aren't mind controlled
	local X2Condition_UnitProperty IsAlly, CanSurrender;
	local array<name> SkipExclusions;
	local X2AbilityCost_ActionPoints ActionPointCost;
	local X2Condition_UnitEffects ExcludeEffects;
	local X2Effect UnconsciousEffect, ExecutedEffect;
	local X2Effect_RemoveEffects RemoveEffects;

	`CREATE_X2ABILITY_TEMPLATE(Template, default.SurrenderName);

	// disable for multiplayer
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer);

	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.PLACE_EVAC_PRIORITY;
	Template.Hostility = eHostility_Defensive;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_voidadept";
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.bAllowedByDefault = true;

	Template.bSkipFireAction = true;

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	// target an arbitrary squad member and all their allies
	Template.AbilityTargetStyle = default.SingleTargetWithSelf;
	Template.AbilityMultiTargetStyle = new class'X2AbilityMultiTarget_AllAllies';
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	// apply the same hit/miss result to everyone
	Template.AbilityToHitCalc = new class'SurrenderAbilityToHitCalc_AllOrNothing';
	
	// shooter conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	// allow anyone to surrender
	SkipExclusions.AddItem(class'X2Ability_CarryUnit'.default.CarryUnitEffectName);
	SkipExclusions.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
	SkipExclusions.AddItem(class'X2StatusEffects'.default.BurningName);

	Template.AddShooterEffectExclusions(SkipExclusions);


	// target conditions, get all soldiers + VIP, even if panicked or in stasis
	CanSurrender = new class'X2Condition_UnitProperty';
	CanSurrender.ExcludeHostileToSource = true;
	CanSurrender.ExcludeFriendlyToSource = false;
	CanSurrender.RequireSquadmates = true; // prevents random civilians counting as targets
	CanSurrender.ExcludeInStasis = false;
	CanSurrender.ExcludePanicked = false; // panicked units can surrender but they need someone else to activate this ability
	CanSurrender.TreatMindControlledSquadmateAsHostile = true; // leave mindcontrolled allies untouched
	CanSurrender.FailOnNonUnits = true;

	// the same except for TreatMindControlledSquadmateAsHostile
	IsAlly = new class'X2Condition_UnitProperty';
	IsAlly.ExcludeHostileToSource = true;
	IsAlly.ExcludeFriendlyToSource = false;
	IsAlly.RequireSquadmates = true;
	IsAlly.ExcludeInStasis = false;
	IsAlly.ExcludePanicked = false;
	IsAlly.FailOnNonUnits = true;
	
	// exclude units that are already unconscious or bleeding out
	ExcludeEffects = new class'X2Condition_UnitEffects';
	ExcludeEffects.AddExcludeEffect(class'X2StatusEffects'.default.UnconsciousName, 'AA_UnitIsUnconscious');
	ExcludeEffects.AddExcludeEffect(class'X2StatusEffects'.default.BleedingOutName, 'AA_UnitIsBleedingOut');

	Template.AbilityTargetConditions.AddItem(IsAlly);
	Template.AbilityTargetConditions.AddItem(ExcludeEffects);

	// if surrender fails, all soldiers are killed
	ExecutedEffect = new class'X2Effect_ExecutedNoBleedout';
	ExecutedEffect.bApplyOnHit = false;
	ExecutedEffect.bApplyOnMiss = true;
	ExecutedEffect.TargetConditions.AddItem(CanSurrender);

	// free mind controlled allies, since they shouldn't count as surrendering
	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2Effect_MindControl'.default.EffectName);
	RemoveEffects.bCleanse = true;
	RemoveEffects.bApplyOnMiss = true;

	Template.AddTargetEffect(RemoveEffects);
	Template.AddMultiTargetEffect(RemoveEffects);


	UnconsciousEffect = class'X2StatusEffects'.static.CreateUnconsciousStatusEffect();
	UnconsciousEffect.TargetConditions.AddItem(CanSurrender);
	UnconsciousEffect.TargetConditions.AddItem(ExcludeEffects);

	Template.AddTargetEffect(UnconsciousEffect);
	Template.AddMultiTargetEffect(UnconsciousEffect);

	Template.AddTargetEffect(ExecutedEffect);
	Template.AddMultiTargetEffect(ExecutedEffect);

	// includes special handling for misses
	Template.BuildNewGameStateFn = Surrender_BuildGameState;
	Template.BuildVisualizationFn = Surrender_BuildVisualization;

	return Template;
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

simulated function Surrender_BuildVisualization(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameStateContext_Ability AbilityContext;
	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());

	// surrender failed, you get to watch your squad die
	// also since the gremlin will still be told to die, it will look less silly if the specialist isn't standing there complete unfazed
	if(AbilityContext.ResultContext.HitResult == eHit_Miss)
	{
		TypicalAbility_BuildVisualization(VisualizeGameState, OutVisualizationTracks);
	}

	// surrender succeeded, don't visualize everyone falling unconscious
}

defaultproperties
{
	SurrenderName = "KnockoutAll"
}