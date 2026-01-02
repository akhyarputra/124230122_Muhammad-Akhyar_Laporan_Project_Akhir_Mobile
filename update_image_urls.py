import json
import os

# Mapping lengkap dari nama file lokal ke URL publik
image_urls = {
    'padi-sawah.jpg': 'https://images.unsplash.com/photo-1530836369250-ef72a3f5cda8?w=600&q=80',
    'bambu.jpg': 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=600&q=80',
    'lotus-seroja.jpg': 'https://images.unsplash.com/photo-1567881997560-d45c8ed4f16a?w=600&q=80',
    'teh-camellia.jpg': 'https://images.unsplash.com/photo-1597318371403-d83e5ef07511?w=600&q=80',
    'pohon-bodhi.jpg': 'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=600&q=80',
    'sakura.jpg': 'https://images.unsplash.com/photo-1522383489734-116ce907aae0?w=600&q=80',
    'mawar.jpg': 'https://images.unsplash.com/photo-1562974957-5733c4c65ba4?w=600&q=80',
    'tulip.jpg': 'https://images.unsplash.com/photo-1560707303-4e980ce876ad?w=600&q=80',
    'orchid.jpg': 'https://images.unsplash.com/photo-1520763185298-1b434c919eba?w=600&q=80',
    'hydrangea.jpg': 'https://images.unsplash.com/photo-1490750967868-88aa4486c946?w=600&q=80',
    'bunga-matahari.jpg': 'https://images.unsplash.com/photo-1597848212624-753a6d2c3fb9?w=600&q=80',
    'dahlia.jpg': 'https://images.unsplash.com/photo-1560707303-4e980ce876ad?w=600&q=80',
    'iris.jpg': 'https://images.unsplash.com/photo-1490749967868-88aa4486c946?w=600&q=80',
    'lavender.jpg': 'https://images.unsplash.com/photo-1596050380589-49b5a4cb55ba?w=600&q=80',
    'lily.jpg': 'https://images.unsplash.com/photo-1567881997560-d45c8ed4f16a?w=600&q=80',
    'daffodil.jpg': 'https://images.unsplash.com/photo-1547518166-6b3f3e344c55?w=600&q=80',
    'carnation.jpg': 'https://images.unsplash.com/photo-1580336579312-94651dfd596d?w=600&q=80',
    'camellia.jpg': 'https://images.unsplash.com/photo-1597318371403-d83e5ef07511?w=600&q=80',
    'chrysanthemum.jpg': 'https://images.unsplash.com/photo-1567881997560-d45c8ed4f16a?w=600&q=80',
    'cosmos.jpg': 'https://images.unsplash.com/photo-1548050628-1edffa9f0fa2?w=600&q=80',
    'fern.jpg': 'https://images.unsplash.com/photo-1520763185298-1b434c919eba?w=600&q=80',
}

# Generic fallback by kategori
kategori_urls = {
    'Bunga': 'https://images.unsplash.com/photo-1520763185298-1b434c919eba?w=600&q=80',
    'Sayuran': 'https://images.unsplash.com/photo-1464454709131-ffd692591ee5?w=600&q=80',
    'Buah': 'https://images.unsplash.com/photo-1488459716781-6918f33402b7?w=600&q=80',
    'Padi-padian': 'https://images.unsplash.com/photo-1530836369250-ef72a3f5cda8?w=600&q=80',
    'Rempah': 'https://images.unsplash.com/photo-1586985289688-cacf913bb591?w=600&q=80',
    'Obat': 'https://images.unsplash.com/photo-1557821552-17105176677c?w=600&q=80',
    'Hias': 'https://images.unsplash.com/photo-1546182990-dffeafbe841d?w=600&q=80',
}

def update_json_file(filename):
    filepath = os.path.join('assets/data', filename)
    
    with open(filepath, 'r', encoding='utf-8') as f:
        plants = json.load(f)
    
    for plant in plants:
        # Skip jika sudah ada gambar_url
        if 'gambar_url' in plant:
            continue
        
        # Coba match dari gambar lokal
        gambar_lokal = plant.get('gambar', '').split('/')[-1]
        if gambar_lokal in image_urls:
            plant['gambar_url'] = image_urls[gambar_lokal]
        else:
            # Gunakan fallback berdasarkan kategori
            kategori = plant.get('kategori', 'Hias')
            plant['gambar_url'] = kategori_urls.get(kategori, 'https://images.unsplash.com/photo-1520763185298-1b434c919eba?w=600&q=80')
    
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(plants, f, ensure_ascii=False, indent=2)
    
    print(f'✓ {filename} updated - {len(plants)} plants')

# Update semua file
files = [
    'tanaman_asia.json',
    'tanaman_afrika.json', 
    'tanaman_amerika.json',
    'tanaman_australia.json',
    'tanaman_eropa.json'
]

for file in files:
    try:
        update_json_file(file)
    except Exception as e:
        print(f'✗ Error in {file}: {e}')

print('\nDone! All JSON files updated with gambar_url')
