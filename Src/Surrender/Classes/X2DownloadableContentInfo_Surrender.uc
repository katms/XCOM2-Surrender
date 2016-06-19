//---------------------------------------------------------------------------------------
//  FILE:   XComDownloadableContentInfo_Surrender.uc                                    
//           
//	Use the X2DownloadableContentInfo class to specify unique mod behavior when the 
//  player creates a new campaign or loads a saved game.
//  
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2DownloadableContentInfo_Surrender extends X2DownloadableContentInfo;

/// <summary>
/// This method is run if the player loads a saved game that was created prior to this DLC / Mod being installed, and allows the 
/// DLC / Mod to perform custom processing in response. This will only be called once the first time a player loads a save that was
/// create without the content installed. Subsequent saves will record that the content was installed.
/// </summary>
static event OnLoadedSavedGame()
{}

/// <summary>
/// Called when the player starts a new campaign while this DLC / Mod is installed
/// </summary>
static event InstallNewCampaign(XComGameState StartState)
{}

/// <summary>
/// Called after the Templates have been created (but before they are validated) while this DLC / Mod is installed.
/// </summary>
static event OnPostTemplatesCreated()
{
	/*local X2AbilityTemplateManager AbilityMgr;
	local X2AbilityTemplate Template;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	Template = AbilityMgr.FindAbilityTemplate('KnockoutSelf');
	if(none != Template)
	{
		Template.bAllowedByDefault = false;
		Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
		`log("Enabled surrender action");
	}*/

	local X2CharacterTemplateManager CharMgr;
	local X2CharacterTemplate CharTemplate;
	local array<X2DataTemplate> Templates;
	local X2DataTemplate Template;

	CharMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	CharMgr.FindDataTemplateAllDifficulties('Soldier', Templates);

	foreach Templates(Template)
	{
		CharTemplate = X2CharacterTemplate(Template);
		if(none != CharTemplate)
		{
			CharTemplate.Abilities.AddItem(class'X2Ability_Surrender'.default.SurrenderName);
			`log("Patched"@CharTemplate);
		}
	}

}