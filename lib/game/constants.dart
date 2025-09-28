import 'package:hetu_script/errors.dart';
import 'package:hetu_script/binding.dart';

import '../common.dart';

class ConstantsBinding extends HTExternalClass {
  ConstantsBinding() : super('Constants');

  @override
  dynamic memberGet(String id,
      {String? from, bool isRecursive = false, bool ignoreUndefined = false}) {
    switch (id) {
      case 'Constants.races':
        return kRaces;
      case 'Constants.personalities':
        return kPersonalities;
      case 'Constants.attributes':
        return kAttributes;
      case 'Constants.nonBattleAttributes':
        return kNonBattleAttributes;
      case 'Constants.battleAttributes':
        return kBattleAttributes;
      case 'Constants.attributeToGenre':
        return kAttributeToGenre;
      case 'Constants.genreToAttribute':
        return kGenreToAttribute;
      case 'Constants.battleCardKinds':
        return kBattleCardKinds;
      case 'Constants.organizationCategories':
        return kOrganizationCategories;
      case 'Constants.cultivationGenres':
        return kCultivationGenres;
      case 'Constants.cultivationStyles':
        return kCultivationStyles;
      case 'Constants.locationCityKinds':
        return kLocationCityKinds;
      case 'Constants.locationSiteKinds':
        return kLocationSiteKinds;
      case 'Constants.siteKindsBuildable':
        return kSiteKindsBuildable;
      case 'Constants.siteKindsManagable':
        return kSiteKindsManagable;
      case 'Constants.attackTypes':
        return kAttackTypes;
      case 'Constnats.damageTypes':
        return kDamageTypes;
      case 'Constants.ticksPerDay':
        return kTicksPerDay;
      case 'Constants.daysPerMonth':
        return kDaysPerMonth;
      case 'Constants.ticksPerMonth':
        return kTicksPerMonth;
      case 'Constants.daysPerYear':
        return kDaysPerYear;
      case 'Constants.monthsPerYear':
        return kMonthsPerYear;
      case 'Constants.ticksPerYear':
        return kTicksPerYear;
      case 'Constants.baseBuyRate':
        return kBaseBuyRate;
      case 'Constants.baseSellRate':
        return kBaseSellRate;
      case 'Constants.minSellRate':
        return kMinSellRate;
      case 'Constants.minBuyRate':
        return kMinBuyRate;
      case 'Constants.basePriceOfMaterialKind':
        return kMaterialBasePriceByKind;
      case 'Constants.basePriceByCategory':
        return kItemBasePriceByCategory;
      case 'Constants.terrainKindsLand':
        return kTerrainKindsLand;
      case 'Constants.terrainKindsWater':
        return kTerrainKindsWater;
      case 'Constants.terrainKindsMountain':
        return kTerrainKindsMountain;
      case 'Constants.titleToOrganizationRank':
        return kTitleToOrganizationRank;
      case 'Constants.rankToOrganizationTitle':
        return kRankToOrganizationTitle;

      default:
        if (!ignoreUndefined) throw HTError.undefined(id);
    }
  }
}
