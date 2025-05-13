
const db = require('../config/db');

const adModel = {
  async getAds({ ad_type, province_id, city_id, sort_by }) {
    try {
      let query = db('advertisements')
        .join('provinces', 'advertisements.province_id', 'provinces.province_id')
        .join('cities', 'advertisements.city_id', 'cities.city_id')
        .select(
          'advertisements.*',
          'provinces.name as province_name',
          'cities.name as city_name'
        );

      if (ad_type) query = query.where('advertisements.ad_type', ad_type);
      if (province_id) query = query.where('advertisements.province_id', province_id);
      if (city_id) query = query.where('advertisements.city_id', city_id);

      if (sort_by === 'newest') query = query.orderBy('advertisements.created_at', 'desc');
      if (sort_by === 'oldest') query = query.orderBy('advertisements.created_at', 'asc');
      if (sort_by === 'cheapest') query = query.orderBy('advertisements.price', 'asc');
      if (sort_by === 'most_expensive') query = query.orderBy('advertisements.price', 'desc');

      const ads = await query;

      const adsWithImages = await Promise.all(
        ads.map(async (ad) => {
          const images = await db('ad_images')
            .select('image_url')
            .where('ad_id', ad.ad_id);
          let realEstate = null;
          if (ad.ad_type === 'REAL_ESTATE') {
            realEstate = await db('real_estate_ads')
              .where('ad_id', ad.ad_id)
              .first();
            if (realEstate && realEstate.real_estate_type === 'SALE') {
              realEstate.deposit = null;
              realEstate.monthly_rent = null;
              realEstate.construction_year = realEstate.construction_year || null;
            }
          }
          return { ...ad, images: images.map(img => img.image_url), ...(realEstate && { ...realEstate }) };
        })
      );

      return adsWithImages;
    } catch (error) {
      console.error('Error in getAds:', error);
      throw error;
    }
  },

  async createAd(adData) {
    try {
      const { imageUrls, ...ad } = adData;
      if (ad.ad_type === 'REAL_ESTATE' && ad.real_estate_type === 'SALE') {
        ad.deposit = null;
        ad.monthly_rent = null;
        ad.construction_year = ad.construction_year || null;
      }

      const [adId] = await db('advertisements').insert({
        title: ad.title,
        description: ad.description,
        ad_type: ad.ad_type,
        price: ad.price,
        province_id: ad.province_id,
        city_id: ad.city_id,
        owner_phone_number: ad.owner_phone_number,
        status: 'PENDING',
        created_at: db.fn.now(),
      });

      if (imageUrls && imageUrls.length > 0) {
        const imageInserts = imageUrls.map(url => ({
          ad_id: adId,
          image_url: url,
        }));
        await db('ad_images').insert(imageInserts);
      }

      if (ad.ad_type === 'REAL_ESTATE') {
        await db('real_estate_ads').insert({
          ad_id: adId,
          real_estate_type: ad.real_estate_type,
          area: ad.area,
          rooms: ad.rooms,
          total_price: ad.total_price,
          price_per_meter: ad.price_per_meter,
          has_parking: ad.has_parking,
          has_storage: ad.has_storage,
          has_balcony: ad.has_balcony,
          deposit: ad.deposit,
          monthly_rent: ad.monthly_rent,
          floor: ad.floor,
          construction_year: ad.construction_year || null,
        });
      }

      return { insertId: adId };
    } catch (error) {
      console.error('Error in createAd:', error);
      throw error;
    }
  },
};

module.exports = adModel;
