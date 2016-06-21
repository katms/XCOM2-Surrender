class X2Effect_ExecutedNoBleedout extends X2Effect_Executed; // X2Effect_Executed provides visualization/flyover text

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit TargetUnit;
	local int KillAmount;
	local UnitValue SustainValue;
	
	// don't call super(), the only ancestor that will do anything is Executed, which causes redundant bleedout + killed notices

	// kill unit even if they can bleed out
	TargetUnit = XComGameState_Unit(kNewTargetState);
	KillAmount = TargetUnit.GetCurrentStat(eStat_HP) + TargetUnit.GetCurrentStat(eStat_ShieldHP);

	// eliminate the chance for them to bleed out, since it wouldn't make sense
	// and it causes the game to tally casualties incorrectly sometimes
	// and might not set cause of death correctly
	// having your surrender rejected is pretty disheartening
	TargetUnit.SetCurrentStat(eStat_Will, 0);

	// disable sustain if applicable, psi ops don't survive getting executed either
	if(TargetUnit.HasSoldierAbility('Sustain'))
	{
		// for some reason GetUnitValue doesn't return the expected result so just assume setting it anyway will work
		// I wonder if this edge case will have edge cases

		//if(TargetUnit.GetUnitValue(class'X2Effect_Sustain'.default.SustainUsed, SustainValue))
		//{
		//	if(SustainValue.fValue <= 0)
		//	{
				TargetUnit.SetUnitFloatValue(class'X2Effect_Sustain'.default.SustainUsed, 1, eCleanup_BeginTactical);
		//	}
		//}
	}
	TargetUnit.TakeEffectDamage(self, KillAmount, 0, 0, ApplyEffectParameters, NewGameState);
}