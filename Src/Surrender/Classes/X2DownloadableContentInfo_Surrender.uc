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
/// Called after the Templates have been created (but before they are validated) while this DLC / Mod is installed.
/// </summary>
static event OnPostTemplatesCreated()
{
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
		}
	}

}