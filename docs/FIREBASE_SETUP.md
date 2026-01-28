# 🔥 Firebase қосу нұсқаулығы

## 📋 Қадамдар

### 1-қадам: Тәуелділіктерді орнату
Терминалда мына команданы орындаңыз:
```bash
flutter pub get
```

---

### 2-қадам: Firebase Console баптау

1. [Firebase Console](https://console.firebase.google.com/) сайтына өтіңіз
2. **recipe-app-5b4e7** жобасын ашыңыз

#### Authentication қосу:
1. Сол жақ панельде **Authentication** таңдаңыз
2. **Get started** басыңыз
3. **Email/Password** әдісін қосыңыз

#### Firestore Database құру:
1. **Firestore Database** таңдаңыз
2. **Create database** басыңыз
3. **Start in test mode** таңдаңыз (тек әзірлеме үшін!)
4. Аймақ таңдаңыз: `europe-west1` немесе `asia-south1`
5. **Enable** басыңыз

#### Storage құру:
1. **Storage** таңдаңыз
2. **Get started** басыңыз
3. **Start in test mode** таңдаңыз
4. Сол аймақты таңдаңыз

---

### 3-қадам: Жобаны тазалау және іске қосу
```bash
flutter clean
flutter pub get
flutter run
```

---

## 📊 Firestore коллекциялар құрылымы

### `users` коллекциясы
```
users/
  └── {userId}/
      ├── username: "Пайдаланушы аты"
      ├── email: "email@example.com"
      ├── role: "user" | "admin"
      ├── avatarUrl: null | "https://..."
      ├── createdAt: Timestamp
      └── isBlocked: false
```

### `recipes` коллекциясы
```
recipes/
  └── {recipeId}/
      ├── userId: "authorUserId"
      ├── title: "Бешбармак"
      ├── description: "Қазақтың ұлттық тағамы"
      ├── cookingTime: 120 (минуттар)
      ├── difficulty: "easy" | "medium" | "hard"
      ├── categoryId: 1
      ├── imageUrl: "https://..."
      ├── servings: 4
      ├── isVegetarian: false
      ├── isDietary: false
      ├── rating: 4.5
      ├── ratingCount: 10
      ├── createdAt: Timestamp
      ├── updatedAt: Timestamp
      ├── ingredients: [
      │     {
      │       ingredientId: 1,
      │       name: "Ет",
      │       quantity: 1,
      │       unit: "кг",
      │       notes: null
      │     }
      │   ]
      └── steps: [
            {
              stepNumber: 1,
              description: "Етті қазанға салып...",
              imageUrl: null,
              duration: 30
            }
          ]
```

### `users/{userId}/favorites` субколлекциясы
```
users/{userId}/favorites/
  └── {recipeId}/
      ├── recipeId: "recipeDocId"
      └── addedAt: Timestamp
```

### `users/{userId}/collections` субколлекциясы
```
users/{userId}/collections/
  └── {collectionId}/
      ├── name: "Мерекелік тағамдар"
      ├── description: "Тойға арналған рецепттер"
      ├── recipeIds: ["recipeId1", "recipeId2"]
      └── createdAt: Timestamp
```

### `users/{userId}/shopping_list` субколлекциясы
```
users/{userId}/shopping_list/
  └── {itemId}/
      ├── ingredientName: "Ет"
      ├── quantity: "1"
      ├── unit: "кг"
      ├── isPurchased: false
      ├── recipeId: "recipeId" (опционал)
      ├── recipeName: "Бешбармак" (опционал)
      └── addedAt: Timestamp
```

### `categories` коллекциясы (опционал)
```
categories/
  └── {categoryId}/
      ├── name: "Breakfast"
      ├── nameKk: "Таңғы ас"
      ├── icon: "breakfast"
      ├── color: "#FF6B35"
      └── order: 1
```

---

## 🔒 Firestore Security Rules (Қауіпсіздік ережелері)

Firebase Console → Firestore Database → Rules ашып, мына кодты қойыңыз:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
      
      // Favorites subcollection
      match /favorites/{docId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      // Collections subcollection
      match /collections/{docId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      // Shopping list subcollection
      match /shopping_list/{docId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // Recipes collection
    match /recipes/{recipeId} {
      allow read: if true; // Everyone can read recipes
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
        (resource.data.userId == request.auth.uid || 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
      
      // Ratings subcollection
      match /ratings/{userId} {
        allow read: if true;
        allow write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // Categories collection
    match /categories/{categoryId} {
      allow read: if true;
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

---

## 🖼️ Storage Security Rules

Firebase Console → Storage → Rules ашып, мына кодты қойыңыз:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // Recipe images
    match /recipes/{recipeId}/{fileName} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // User avatars
    match /users/{userId}/{fileName} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## ✅ Тексеру

Барлығы дұрыс орнатылғанын тексеру:

1. Қосымшаны іске қосыңыз: `flutter run`
2. Тіркелу экранында жаңа пайдаланушы жасаңыз
3. Firebase Console → Authentication тексеріңіз - пайдаланушы пайда болуы керек
4. Firebase Console → Firestore тексеріңіз - `users` коллекциясында мәліметтер пайда болуы керек

---

## 🐛 Жиі кездесетін қателер

### "The supplied auth credential is incorrect"
- Email/Password authentication қосылғанын тексеріңіз

### "PERMISSION_DENIED"
- Firestore Security Rules дұрыс орнатылғанын тексеріңіз
- Тестілеу режимін қолданыңыз

### "No Firebase App"
- `flutter clean` және қайта `flutter run` орындаңыз
