import { ClothingRepository } from '../repositories/ClothingRepository';
import { OutfitRepository } from '../repositories/OutfitRepository';
import { WearLogRepository } from '../repositories/WearLogRepository';
import { WishlistRepository } from '../repositories/WishlistRepository';
import { ClothingCategory } from '../../domain/clothing/ClothingCategory';
import { ClothingItem } from '../../domain/clothing/ClothingModels';
import { OutfitTemplate } from '../../domain/outfit/OutfitModels';
import { WearLog } from '../../domain/wearLog/WearLogModels';
import { WishlistItem } from '../../domain/wishlist/WishlistModels';

export interface WardrobeSeedRepositories {
  clothingRepository: ClothingRepository;
  outfitRepository: OutfitRepository;
  wearLogRepository: WearLogRepository;
  wishlistRepository: WishlistRepository;
}

export interface WardrobeSeedData {
  clothing: ClothingItem[];
  outfits: OutfitTemplate[];
  wearLogs: WearLog[];
  wishlist: WishlistItem[];
}

export async function seedClothing(repository: ClothingRepository): Promise<ClothingItem[]> {
  const whiteShirt = await repository.createClothing({
    name: 'White cotton shirt',
    category: ClothingCategory.Top,
    photoUris: ['debug://photos/white-shirt.jpg'],
    note: 'offline seed wardrobe item',
    purchaseInfo: {
      storeName: 'Seed Store',
      price: 199,
      purchaseDate: '2026-06-01'
    }
  });
  const blackPants = await repository.createClothing({
    name: 'Black straight pants',
    category: ClothingCategory.Pants,
    photoUris: ['debug://photos/black-pants.jpg'],
    note: 'offline seed wardrobe item'
  });

  return [whiteShirt, blackPants];
}

export async function seedOutfits(
  repository: OutfitRepository,
  clothing: ClothingItem[]
): Promise<OutfitTemplate[]> {
  const workOutfit = await repository.createOutfit({
    title: 'Office weekday',
    photoUris: ['debug://photos/office-outfit.jpg'],
    clothingItemIds: clothing.map((item: ClothingItem) => item.id),
    note: 'offline seed outfit'
  });

  return [workOutfit];
}

export async function seedWearLogs(
  repository: WearLogRepository,
  outfits: OutfitTemplate[]
): Promise<WearLog[]> {
  if (outfits.length === 0) {
    return [];
  }

  const todayLog = await repository.createWearLog({
    outfitTemplateId: outfits[0].id,
    wornDate: '2026-06-30',
    photoUris: ['debug://photos/today-wear.jpg'],
    placeText: 'Office',
    note: 'offline seed wear log'
  });

  return [todayLog];
}

export async function seedWishlist(repository: WishlistRepository): Promise<WishlistItem[]> {
  const wishlistItem = await repository.createWishlistItem({
    title: 'Teal rain jacket',
    photoUris: ['debug://photos/teal-jacket.jpg'],
    storeName: 'Seed Mall',
    price: 399,
    note: 'offline seed wishlist item'
  });

  return [wishlistItem];
}

export async function seedWardrobeDebugData(repositories: WardrobeSeedRepositories): Promise<WardrobeSeedData> {
  const clothing = await seedClothing(repositories.clothingRepository);
  const outfits = await seedOutfits(repositories.outfitRepository, clothing);
  const wearLogs = await seedWearLogs(repositories.wearLogRepository, outfits);
  const wishlist = await seedWishlist(repositories.wishlistRepository);

  return {
    clothing,
    outfits,
    wearLogs,
    wishlist
  };
}
