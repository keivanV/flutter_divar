const db = require('../config/db');

const adImageModel = {
  async createAdImage(adId, imageUrl) {
    const result = await db('ad_images').insert({
      ad_id: adId,
      image_url: imageUrl,
    });
    return result;
  },
};

module.exports = adImageModel;