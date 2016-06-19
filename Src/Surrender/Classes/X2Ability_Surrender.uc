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
	local X2Condition_UnitProperty UnitProperty, ShooterProperty;
	local array<name> SkipExclusions;
	local X2AbilityCost_ActionPoints ActionPointCost;
	local X2Condition_UnitEffects ExcludeEffects;

	`CREATE_X2ABILITY_TEMPLATE(Template, default.SurrenderName);

	// disable for multiplayer
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer);

	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.PLACE_EVAC_PRIORITY;
	Template.Hostility = eHostility_Defensive;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_voidadept";
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.bAllowedByDefault = true;

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	// target an arbitrary squad member and all their allies
	Template.AbilityTargetStyle = default.SingleTargetWithSelf;
	// if this doesn't work out as intended re: UnitProperty just use a custom BuildNewGameStateFn
	Template.AbilityMultiTargetStyle = new class'X2AbilityMultiTarget_AllAllies';
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	Template.AbilityToHitCalc = default.DeadEye;

	// shooter conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	// allow anyone to surrender
	SkipExclusions.AddItem(class'X2Ability_CarryUnit'.default.CarryUnitEffectName);
	SkipExclusions.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
	SkipExclusions.AddItem(class'X2StatusEffects'.default.BurningName);

	Template.AddShooterEffectExclusions(SkipExclusions);


	// target conditions, get all soldiers, even if panicked or in stasis
	UnitProperty = new class'X2Condition_UnitProperty';
	UnitProperty.ExcludeHostileToSource = true;
	UnitProperty.ExcludeFriendlyToSource = false;
	UnitProperty.ExcludeInStasis = false;
	UnitProperty.ExcludePanicked = false; // panicked units can surrender but they need someone else to activate this ability
	UnitProperty.TreatMindControlledSquadmateAsHostile = true; // leave mindcontrolled allies untouched
	UnitProperty.FailOnNonUnits = true;

	// exclude units that are already unconscious
	ExcludeEffects = new class'X2Condition_UnitEffects';
	ExcludeEffects.AddExcludeEffect(class'X2StatusEffects'.default.UnconsciousName, 'AA_UnitIsUnconscious');

	Template.AbilityTargetConditions.AddItem(UnitProperty);
	Template.AbilityTargetConditions.AddItem(ExcludeEffects);

	Template.AddTargetEffect(class'X2StatusEffects'.static.CreateUnconsciousStatusEffect());
	Template.AddMultiTargetEffect(class'X2StatusEffects'.static.CreateUnconsciousStatusEffect());

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	// no visualization

	return Template;
}

defaultproperties
{
	SurrenderName = "KnockoutAll"
}