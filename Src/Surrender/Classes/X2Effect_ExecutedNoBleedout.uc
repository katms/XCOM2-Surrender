class X2Effect_ExecutedNoBleedout extends X2Effect_Executed; // X2Effect_Executed provides visualization/flyover text

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit TargetUnit;
	local int KillAmount;
	
	// don't call super(), the only ancestor that will do anything is Executed, which causes redundant bleedout + killed notices

	// kill unit even if they can bleed out
	TargetUnit = XComGameState_Unit(kNewTargetState);
	KillAmount = TargetUnit.GetCurrentStat(eStat_HP) + TargetUnit.GetCurrentStat(eStat_ShieldHP);

	// eliminate the chance for them to bleed out, since it wouldn't make sense
	// and it causes the game to tally casualties incorrectly
	// (bleeding out counts as wound even if being lost kills them)
	// having your surrender rejected is pretty disheartening
	TargetUnit.SetCurrentStat(eStat_Will, 0);

	// todo: the memorial wall will attribute deaths to the surrendering soldier,
	//		 which is all well and good I suppose but not if it's labeled friendly fire
	//		 see if we can't change it to "Executed!"
	TargetUnit.TakeEffectDamage(self, KillAmount, 0, 0, ApplyEffectParameters, NewGameState);
}