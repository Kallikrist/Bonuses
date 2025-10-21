import 'package:flutter_test/flutter_test.dart';
import 'package:bonuses/models/subscription_tier.dart';

void main() {
  group('Subscription Tier Management Tests', () {
    group('Default Tiers', () {
      test('All default tiers are available', () {
        final tiers = SubscriptionTier.defaultTiers;
        
        expect(tiers.length, 4);
        expect(tiers.any((t) => t.id == 'tier_free'), true);
        expect(tiers.any((t) => t.id == 'tier_starter'), true);
        expect(tiers.any((t) => t.id == 'tier_professional'), true);
        expect(tiers.any((t) => t.id == 'tier_enterprise'), true);
      });

      test('Free tier has correct configuration', () {
        final tier = SubscriptionTier.free;
        
        expect(tier.id, 'tier_free');
        expect(tier.name, 'Free Trial');
        expect(tier.monthlyPrice, 0);
        expect(tier.yearlyPrice, 0);
        expect(tier.maxEmployees, 5);
        expect(tier.maxWorkplaces, 1);
        expect(tier.maxBonuses, 10);
        expect(tier.features.length, greaterThan(0));
        expect(tier.isActive, true);
      });

      test('Starter tier has correct configuration', () {
        final tier = SubscriptionTier.starter;
        
        expect(tier.id, 'tier_starter');
        expect(tier.name, 'Starter');
        expect(tier.monthlyPrice, 29);
        expect(tier.yearlyPrice, 290);
        expect(tier.maxEmployees, 10);
        expect(tier.maxWorkplaces, 2);
        expect(tier.maxBonuses, 50);
        expect(tier.features.length, greaterThan(0));
      });

      test('Professional tier has correct configuration', () {
        final tier = SubscriptionTier.professional;
        
        expect(tier.id, 'tier_professional');
        expect(tier.name, 'Professional');
        expect(tier.monthlyPrice, 99);
        expect(tier.yearlyPrice, 990);
        expect(tier.maxEmployees, 50);
        expect(tier.maxWorkplaces, 10);
        expect(tier.maxBonuses, -1); // Unlimited
        expect(tier.features.length, greaterThan(0));
      });

      test('Enterprise tier has correct configuration', () {
        final tier = SubscriptionTier.enterprise;
        
        expect(tier.id, 'tier_enterprise');
        expect(tier.name, 'Enterprise');
        expect(tier.monthlyPrice, 299);
        expect(tier.yearlyPrice, 2990);
        expect(tier.maxEmployees, -1); // Unlimited
        expect(tier.maxWorkplaces, -1); // Unlimited
        expect(tier.maxBonuses, -1); // Unlimited
        expect(tier.features.length, greaterThan(0));
      });
    });

    group('Tier Pricing', () {
      test('Pricing increases with tier level', () {
        final tiers = SubscriptionTier.defaultTiers;
        
        expect(SubscriptionTier.free.monthlyPrice < SubscriptionTier.starter.monthlyPrice, true);
        expect(SubscriptionTier.starter.monthlyPrice < SubscriptionTier.professional.monthlyPrice, true);
        expect(SubscriptionTier.professional.monthlyPrice < SubscriptionTier.enterprise.monthlyPrice, true);
      });

      test('Yearly pricing offers discount', () {
        final starter = SubscriptionTier.starter;
        final pro = SubscriptionTier.professional;
        final enterprise = SubscriptionTier.enterprise;
        
        expect(starter.yearlyPrice!, lessThan(starter.monthlyPrice * 12));
        expect(pro.yearlyPrice!, lessThan(pro.monthlyPrice * 12));
        expect(enterprise.yearlyPrice!, lessThan(enterprise.monthlyPrice * 12));
      });

      test('Discount percentage is consistent', () {
        final starter = SubscriptionTier.starter;
        final pro = SubscriptionTier.professional;
        
        // Calculate discount percentage for both tiers
        final starterDiscount = ((starter.monthlyPrice * 12 - starter.yearlyPrice!) / (starter.monthlyPrice * 12)) * 100;
        final proDiscount = ((pro.monthlyPrice * 12 - pro.yearlyPrice!) / (pro.monthlyPrice * 12)) * 100;
        
        // Both should have approximately same discount
        expect((starterDiscount - proDiscount).abs(), lessThan(1.0));
      });
    });

    group('Tier Limits', () {
      test('Free tier has most restrictive limits', () {
        final free = SubscriptionTier.free;
        final starter = SubscriptionTier.starter;
        
        expect(free.maxEmployees < starter.maxEmployees, true);
        expect(free.maxWorkplaces < starter.maxWorkplaces, true);
        expect(free.maxBonuses < starter.maxBonuses, true);
      });

      test('Limits increase with tier level', () {
        final free = SubscriptionTier.free;
        final starter = SubscriptionTier.starter;
        final pro = SubscriptionTier.professional;
        
        expect(free.maxEmployees < starter.maxEmployees, true);
        expect(starter.maxEmployees < pro.maxEmployees || pro.maxEmployees == -1, true);
      });

      test('Unlimited is represented as -1', () {
        final pro = SubscriptionTier.professional;
        final enterprise = SubscriptionTier.enterprise;
        
        expect(pro.maxBonuses, -1); // Pro has unlimited bonuses
        expect(enterprise.maxEmployees, -1); // Enterprise has unlimited employees
        expect(enterprise.maxWorkplaces, -1); // Enterprise has unlimited workplaces
        expect(enterprise.maxBonuses, -1); // Enterprise has unlimited bonuses
      });
    });

    group('Tier Features', () {
      test('All tiers have features defined', () {
        for (final tier in SubscriptionTier.defaultTiers) {
          expect(tier.features, isNotEmpty);
        }
      });

      test('Higher tiers have more features', () {
        final free = SubscriptionTier.free;
        final enterprise = SubscriptionTier.enterprise;
        
        expect(enterprise.features.length > free.features.length, true);
      });

      test('Enterprise tier includes advanced features', () {
        final enterprise = SubscriptionTier.enterprise;
        
        final featureList = enterprise.features.map((f) => f.toLowerCase()).toList();
        expect(featureList.any((f) => f.contains('unlimited')), true);
        expect(featureList.any((f) => f.contains('api') || f.contains('integration')), true);
      });
    });

    group('Tier Serialization', () {
      test('Tier can be converted to JSON and back', () {
        final tier = SubscriptionTier.professional;
        
        final json = tier.toJson();
        final deserialized = SubscriptionTier.fromJson(json);
        
        expect(deserialized.id, tier.id);
        expect(deserialized.name, tier.name);
        expect(deserialized.description, tier.description);
        expect(deserialized.monthlyPrice, tier.monthlyPrice);
        expect(deserialized.yearlyPrice, tier.yearlyPrice);
        expect(deserialized.maxEmployees, tier.maxEmployees);
        expect(deserialized.maxWorkplaces, tier.maxWorkplaces);
        expect(deserialized.maxBonuses, tier.maxBonuses);
        expect(deserialized.features.length, tier.features.length);
        expect(deserialized.isActive, tier.isActive);
      });

      test('Tier with null yearlyPrice serializes correctly', () {
        final tier = const SubscriptionTier(
          id: 'tier_custom',
          name: 'Custom',
          description: 'Custom tier',
          monthlyPrice: 50,
          yearlyPrice: null,
          maxEmployees: 20,
          maxWorkplaces: 5,
          maxBonuses: 100,
          features: ['Feature 1', 'Feature 2'],
        );
        
        final json = tier.toJson();
        final deserialized = SubscriptionTier.fromJson(json);
        
        expect(deserialized.yearlyPrice, isNull);
        expect(deserialized.monthlyPrice, 50);
      });
    });

    group('Tier Copy With', () {
      test('Can modify tier properties', () {
        final original = SubscriptionTier.starter;
        
        final modified = original.copyWith(
          monthlyPrice: 39,
          yearlyPrice: 390,
          maxEmployees: 15,
        );
        
        expect(modified.monthlyPrice, 39);
        expect(modified.yearlyPrice, 390);
        expect(modified.maxEmployees, 15);
        expect(modified.id, original.id); // Unchanged
        expect(modified.name, original.name); // Unchanged
      });

      test('Can deactivate a tier', () {
        final active = SubscriptionTier.professional;
        
        final inactive = active.copyWith(isActive: false);
        
        expect(active.isActive, true);
        expect(inactive.isActive, false);
        expect(inactive.id, active.id); // All other properties unchanged
      });
    });

    group('Tier Comparison', () {
      test('Can identify tier by price', () {
        final tiers = SubscriptionTier.defaultTiers;
        
        final freeTier = tiers.firstWhere((t) => t.monthlyPrice == 0);
        final starterTier = tiers.firstWhere((t) => t.monthlyPrice == 29);
        
        expect(freeTier.id, 'tier_free');
        expect(starterTier.id, 'tier_starter');
      });

      test('Can sort tiers by price', () {
        final tiers = List.from(SubscriptionTier.defaultTiers);
        tiers.sort((a, b) => a.monthlyPrice.compareTo(b.monthlyPrice));
        
        expect(tiers.first.id, 'tier_free');
        expect(tiers.last.id, 'tier_enterprise');
      });
    });

    group('Tier Validation', () {
      test('All tier IDs are unique', () {
        final tiers = SubscriptionTier.defaultTiers;
        final ids = tiers.map((t) => t.id).toList();
        final uniqueIds = ids.toSet();
        
        expect(ids.length, uniqueIds.length);
      });

      test('All tier names are unique', () {
        final tiers = SubscriptionTier.defaultTiers;
        final names = tiers.map((t) => t.name).toList();
        final uniqueNames = names.toSet();
        
        expect(names.length, uniqueNames.length);
      });

      test('All tiers have positive or unlimited limits', () {
        for (final tier in SubscriptionTier.defaultTiers) {
          expect(tier.maxEmployees >= -1, true);
          expect(tier.maxWorkplaces >= -1, true);
          expect(tier.maxBonuses >= -1, true);
        }
      });

      test('All tiers have non-negative prices', () {
        for (final tier in SubscriptionTier.defaultTiers) {
          expect(tier.monthlyPrice >= 0, true);
          if (tier.yearlyPrice != null) {
            expect(tier.yearlyPrice! >= 0, true);
          }
        }
      });
    });

    group('Feature Lists', () {
      test('Each tier has at least one feature', () {
        for (final tier in SubscriptionTier.defaultTiers) {
          expect(tier.features.length, greaterThan(0));
        }
      });

      test('Features are descriptive strings', () {
        final starter = SubscriptionTier.starter;
        
        for (final feature in starter.features) {
          expect(feature.length, greaterThan(0));
          expect(feature.trim(), isNotEmpty);
        }
      });
    });
  });
}

