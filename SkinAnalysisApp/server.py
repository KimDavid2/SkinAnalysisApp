from flask import Flask, request, jsonify
import tensorflow as tf
from tensorflow.keras.models import load_model
import cv2
import numpy as np
import requests
from bs4 import BeautifulSoup

app = Flask(__name__)

# 모델 로드
model = load_model('skin_analysis_model.h5')

# 피부 상태에 따른 추천 키워드
def get_recommendations(skin_condition):
    recommendations = {
        'Combination skin': ['balancing moisturizer', 'hydrating serum', 'gentle cleanser'],
        'Dry skin': ['hydrating cream', 'moisturizing lotion', 'nourishing oil'],
        'Normal skin': ['daily moisturizer', 'light sunscreen', 'hydrating toner'],
        'Oily skin': ['oil control lotion', 'mattifying primer', 'pore minimizing serum'],
        'Sensitive skin': ['gentle cleanser', 'calming moisturizer', 'fragrance-free serum'],
        'Aging skin': ['anti-aging serum', 'firming cream', 'wrinkle repair lotion']
    }
    return recommendations.get(skin_condition, ['general skincare product'])

# 키워드로 웹에서 제품 검색 및 평가 기준에 따른 정렬
def search_product(keyword):
    url = f"https://www.example.com/search?q={keyword}"
    response = requests.get(url)
    soup = BeautifulSoup(response.text, 'html.parser')
    
    results = []
    for item in soup.select('.product-item'):
        try:
            title = item.select_one('.product-title').get_text()
            link = item.select_one('a')['href']
            image = item.select_one('.product-image img')['src']
            price = item.select_one('.product-price').get_text()
            reviews = int(item.select_one('.review-count').get_text().replace(' reviews', '').replace(',', ''))
            rating = float(item.select_one('.rating').get_text())
            
            # 리뷰 내용 수집 (예: 긍정적 리뷰 수를 세기 위해)
            review_texts = [review.get_text() for review in item.select('.review-text')]
            positive_reviews = sum(1 for text in review_texts if 'good' in text.lower() or 'excellent' in text.lower())
            
            results.append({
                'title': title,
                'link': link,
                'image': image,
                'price': price,
                'reviews': reviews,
                'rating': rating,
                'positive_reviews': positive_reviews
            })
        except Exception as e:
            print(f"Error parsing product item: {e}")

    # 평가 기준에 따라 정렬 (많은 리뷰, 긍정적 리뷰 내용, 높은 평가 점수)
    results.sort(key=lambda x: (x['reviews'], x['positive_reviews'], x['rating']), reverse=True)
    
    return results[:5]  # 상위 5개 제품만 반환

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return jsonify({"error": "No file part"})
    
    file = request.files['file']
    
    if file.filename == '':
        return jsonify({"error": "No selected file"})
    
    if file:
        img_array = np.frombuffer(file.read(), np.uint8)
        img = cv2.imdecode(img_array, cv2.IMREAD_COLOR)
        img = cv2.resize(img, (224, 224))
        img = img / 255.0
        img = np.expand_dims(img, axis=0)
        
        prediction = model.predict(img)
        result = np.argmax(prediction, axis=1)[0]
        
        skin_conditions = ['Combination skin', 'Dry skin', 'Normal skin', 'Oily skin', 'Sensitive skin', 'Aging skin']
        skin_condition = skin_conditions[result]

        keywords = get_recommendations(skin_condition)
        search_results = []
        for keyword in keywords:
            search_results.extend(search_product(keyword))
        
        # 설명 추가
        explanation = "The analysis is based on various factors identified in the image such as color, texture, and patterns."

        return jsonify({"results": skin_condition, "recommendations": search_results, "explanation": explanation})

if __name__ == '__main__':
    app.run(debug=True)
