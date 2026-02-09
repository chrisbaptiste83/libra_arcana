puts "Seeding Libra Arcana..."

# Admin User
admin = User.find_or_create_by!(email: "admin@libraarcana.com") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
  u.first_name = "Arcana"
  u.last_name = "Admin"
  u.admin = true
end
puts "  Admin user created: #{admin.email}"

# Categories
categories_data = [
  { name: "Astrology", icon: "star", description: "Explore the celestial patterns that shape destiny. From natal charts to planetary transits, unlock the wisdom written in the stars." },
  { name: "Tarot", icon: "layers", description: "Master the ancient art of cartomancy. Learn to read the Major and Minor Arcana and divine the threads of fate." },
  { name: "Alchemy", icon: "flask", description: "Discover the sacred science of transformation. From the philosopher's stone to spiritual transmutation." },
  { name: "Divination", icon: "eye", description: "Peer beyond the veil of time. Scrying, runes, I Ching, and other methods of prophecy await." },
  { name: "Herbalism", icon: "leaf", description: "Harness the magical properties of plants. Potions, tinctures, and botanical spellwork for the modern practitioner." },
  { name: "Ancient Wisdom", icon: "book-open", description: "Timeless teachings from mystery schools and secret societies. Hermetic principles, Kabbalah, and sacred geometry." },
  { name: "Numerology", icon: "hash", description: "Decode the hidden language of numbers. Life paths, destiny numbers, and the mathematics of the divine." },
  { name: "Crystal Healing", icon: "gem", description: "Unlock the vibrational power of stones and minerals. Crystal grids, chakra healing, and gem elixirs." }
]

categories = {}
categories_data.each do |data|
  cat = Category.find_or_create_by!(name: data[:name]) do |c|
    c.description = data[:description]
    c.icon = data[:icon]
  end
  categories[data[:name]] = cat
end
puts "  #{categories.size} categories created"

# Ebooks
ebooks_data = [
  # Astrology (3)
  { title: "The Celestial Codex: A Complete Guide to Natal Astrology", author: "Selene Blackwood", price: 14.99, page_count: 342, isbn: "978-0-00-000001-0", publication_year: 2024, featured: true, category: "Astrology",
    description: "An encyclopedic guide to understanding your natal chart. Selene Blackwood draws on decades of astrological practice to reveal the profound influence of planetary placements, aspects, and houses on your life journey. From Sun signs to the outer planets, every celestial body is explored with clarity and depth." },
  { title: "Mercury Retrograde Survival Manual", author: "Orion Thorne", price: 9.99, page_count: 178, isbn: "978-0-00-000002-7", publication_year: 2025, featured: false, category: "Astrology",
    description: "Navigate the chaos of Mercury retrograde with confidence. This practical guide offers rituals, timing strategies, and protective measures for communication, travel, and technology during astrology's most feared transit." },
  { title: "Houses of the Zodiac: Architecture of the Soul", author: "Selene Blackwood", price: 16.99, page_count: 410, isbn: "978-0-00-000003-4", publication_year: 2023, featured: true, category: "Astrology",
    description: "A deep exploration of the twelve astrological houses and how they shape every dimension of human experience—from identity and values to career and spirituality. Includes detailed interpretations for every planet in every house." },

  # Tarot (3)
  { title: "Shadows & Light: The Complete Tarot Reader's Handbook", author: "Morgana Vale", price: 17.99, page_count: 456, isbn: "978-0-00-000004-1", publication_year: 2024, featured: true, category: "Tarot",
    description: "The definitive guide to tarot reading. Morgana Vale takes you from absolute beginner to confident reader, covering all 78 cards, reversals, spreads, and the art of intuitive interpretation. Beautifully illustrated with symbolic analysis for each card." },
  { title: "The Dark Mirror Tarot: Shadow Work Through the Cards", author: "Raven Ashworth", price: 13.99, page_count: 280, isbn: "978-0-00-000005-8", publication_year: 2025, featured: false, category: "Tarot",
    description: "Use the tarot as a tool for psychological shadow work. Raven Ashworth guides you through confronting your hidden self, integrating rejected aspects of the psyche, and emerging with greater wholeness and self-awareness." },
  { title: "Arcana of the Ancients: Tarot's Hidden History", author: "Elias Crane", price: 12.99, page_count: 312, isbn: "978-0-00-000006-5", publication_year: 2023, featured: false, category: "Tarot",
    description: "Trace the tarot's mysterious origins from ancient Egypt through the Renaissance to the modern era. A fascinating historical journey that reveals the esoteric traditions woven into every card." },

  # Alchemy (2)
  { title: "The Emerald Tablet Decoded", author: "Thaddeus Wolfe", price: 15.99, page_count: 298, isbn: "978-0-00-000007-2", publication_year: 2024, featured: true, category: "Alchemy",
    description: "Unravel the cryptic teachings of Hermes Trismegistus. This groundbreaking work deciphers the Emerald Tablet line by line, connecting its ancient wisdom to modern chemistry, psychology, and spiritual practice." },
  { title: "Gold of the Philosophers: Inner Alchemy for the Modern Seeker", author: "Isolde Marchetti", price: 11.99, page_count: 224, isbn: "978-0-00-000008-9", publication_year: 2025, featured: false, category: "Alchemy",
    description: "Transform your inner lead into spiritual gold. A practical guide to the alchemical stages of nigredo, albedo, citrinitas, and rubedo as they apply to personal growth and self-realization." },

  # Divination (3)
  { title: "The Seer's Compendium: Methods of Divination Across Cultures", author: "Cassandra Moon", price: 18.99, page_count: 520, isbn: "978-0-00-000009-6", publication_year: 2024, featured: true, category: "Divination",
    description: "A comprehensive survey of divinatory practices from every corner of the globe. From African bone casting to Norse rune reading, Chinese I Ching to Celtic ogham, this volume is the most complete guide to the world's prophetic traditions." },
  { title: "Scrying: Gazing Into the Abyss", author: "Nyx Holloway", price: 10.99, page_count: 192, isbn: "978-0-00-000010-2", publication_year: 2023, featured: false, category: "Divination",
    description: "Master the ancient art of scrying with mirrors, crystal balls, water, and fire. Detailed instructions for inducing the trance state necessary for clear visions, plus interpretation techniques." },
  { title: "Runes of the Elder Futhark", author: "Bjorn Stormcaller", price: 13.99, page_count: 268, isbn: "978-0-00-000011-9", publication_year: 2025, featured: false, category: "Divination",
    description: "A thorough guide to the 24 runes of the Elder Futhark. Learn their meanings, magical applications, and divination methods, rooted in authentic Norse tradition and modern esoteric practice." },

  # Herbalism (2)
  { title: "The Witch's Apothecary: Magical Herbalism for the Modern Practitioner", author: "Hazel Greenwillow", price: 15.99, page_count: 388, isbn: "978-0-00-000012-6", publication_year: 2024, featured: true, category: "Herbalism",
    description: "Over 150 herbs profiled with their magical correspondences, medicinal properties, and ritual applications. Includes recipes for incenses, oils, tinctures, and teas, plus a complete guide to growing a magical garden." },
  { title: "Poisonous Path: The Dark Flora of Witchcraft", author: "Nightshade Quinn", price: 14.99, page_count: 256, isbn: "978-0-00-000013-3", publication_year: 2025, featured: false, category: "Herbalism",
    description: "Explore the dangerous but fascinating world of baneful herbs. From belladonna to hemlock, understand the historical, mythological, and magical significance of the plants that dwell in shadow." },

  # Ancient Wisdom (3)
  { title: "The Kybalion Illuminated", author: "Three Initiates Society", price: 11.99, page_count: 210, isbn: "978-0-00-000014-0", publication_year: 2023, featured: true, category: "Ancient Wisdom",
    description: "A modern commentary on the seven Hermetic principles. Each law—Mentalism, Correspondence, Vibration, Polarity, Rhythm, Cause & Effect, and Gender—is explored with contemporary examples and practical exercises." },
  { title: "Sacred Geometry: The Architecture of the Universe", author: "Pythia Solis", price: 19.99, page_count: 480, isbn: "978-0-00-000015-7", publication_year: 2024, featured: false, category: "Ancient Wisdom",
    description: "Discover the mathematical patterns underlying all of creation. From the Flower of Life to the Golden Ratio, explore how sacred geometry reveals the hidden order of nature, art, and consciousness." },
  { title: "Whispers of the Kabbalah", author: "Solomon Ashkenazi", price: 16.99, page_count: 365, isbn: "978-0-00-000016-4", publication_year: 2025, featured: false, category: "Ancient Wisdom",
    description: "An accessible introduction to the mystical tradition of Kabbalah. Navigate the Tree of Life, understand the Sephiroth, and discover the hidden dimensions of Hebrew letters and divine names." },

  # Numerology (2)
  { title: "Numbers of Destiny: A Complete Guide to Numerology", author: "Ada Fibonacci", price: 12.99, page_count: 290, isbn: "978-0-00-000017-1", publication_year: 2024, featured: false, category: "Numerology",
    description: "Calculate and interpret your Life Path, Expression, Soul Urge, and Personality numbers. Understand the vibrational essence of each number from 1 to 9, plus the mystical Master Numbers 11, 22, and 33." },
  { title: "The Midnight Equation: Numerology and the Occult", author: "Lazarus Vex", price: 13.99, page_count: 244, isbn: "978-0-00-000018-8", publication_year: 2025, featured: false, category: "Numerology",
    description: "Explore the darker side of numerical magic. Gematria, magic squares, sigil creation through number, and the numerological secrets embedded in ancient grimoires and sacred texts." },

  # Crystal Healing (2)
  { title: "Grimoire of Gems: The Crystal Witch's Bible", author: "Petra Luminara", price: 16.99, page_count: 402, isbn: "978-0-00-000019-5", publication_year: 2024, featured: false, category: "Crystal Healing",
    description: "Over 200 crystals and gemstones catalogued with their metaphysical properties, chakra associations, and magical uses. Includes crystal grid layouts, elixir recipes, and ritual applications for every occasion." },
  { title: "Stones of Power: Crystal Magic for Transformation", author: "Ember Quartzfield", price: 11.99, page_count: 198, isbn: "978-0-00-000020-1", publication_year: 2025, featured: false, category: "Crystal Healing",
    description: "A practical, hands-on guide to working with crystals for personal transformation. Learn to program stones, build crystal grids, create gem elixirs, and use crystals in meditation and energy healing." },
]

ebooks_data.each do |data|
  category = categories[data.delete(:category)]
  Ebook.find_or_create_by!(title: data[:title]) do |e|
    e.assign_attributes(data.merge(category: category))
  end
end
puts "  #{Ebook.count} ebooks created (#{Ebook.featured.count} featured)"

puts "Seeding complete!"
