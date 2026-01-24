# Guide de Connexion du Téléphone Android

## Méthode 1 : Connexion sans fil avec code d'appairage (Android 11+)

### Sur le téléphone :
1. **Activer le mode développeur** :
   - Allez dans `Paramètres` → `À propos du téléphone`
   - Tapez 7 fois sur `Numéro de build`
   - Le message "Vous êtes maintenant développeur" apparaît

2. **Activer le débogage sans fil** :
   - Allez dans `Paramètres` → `Options pour les développeurs`
   - Activez `Débogage USB`
   - Activez `Débogage sans fil`
   - Tapez sur `Débogage sans fil`
   - Tapez sur `Associer un appareil avec un code d'appairage`
   - **Notez le code à 6 chiffres et l'adresse IP:Port**

### Sur l'ordinateur :
1. **Lancer la commande d'appairage** :
   ```cmd
   adb pair <IP>:<PORT>
   ```
   Exemple : `adb pair 192.168.1.100:37831`

2. **Entrer le code à 6 chiffres** affiché sur le téléphone

3. **Connecter l'appareil** :
   ```cmd
   adb connect <IP>:<PORT>
   ```
   Exemple : `adb connect 192.168.1.100:37831`

4. **Vérifier la connexion** :
   ```cmd
   adb devices
   ```

## Méthode 2 : Connexion USB puis sans fil

### Étape 1 : Connexion USB initiale
1. Connectez votre téléphone via USB
2. Activez le mode développeur (voir Méthode 1, étape 1)
3. Activez `Débogage USB` dans `Options pour les développeurs`
4. Acceptez l'autorisation de débogage USB sur le téléphone

### Étape 2 : Passer en mode sans fil
1. Vérifiez que le téléphone est connecté :
   ```cmd
   adb devices
   ```

2. Redémarrez adb en mode TCP/IP :
   ```cmd
   adb tcpip 5555
   ```

3. Trouvez l'adresse IP du téléphone :
   - Allez dans `Paramètres` → `À propos du téléphone` → `État`
   - Notez l'adresse IP Wi-Fi

4. Déconnectez le câble USB et connectez-vous sans fil :
   ```cmd
   adb connect <IP>:5555
   ```
   Exemple : `adb connect 192.168.1.100:5555`

5. Vérifiez la connexion :
   ```cmd
   adb devices
   ```

## Méthode 3 : Connexion USB simple

1. Connectez votre téléphone via câble USB
2. Activez le mode développeur (voir Méthode 1, étape 1)
3. Activez `Débogage USB` dans `Options pour les développeurs`
4. Acceptez l'autorisation de débogage USB sur le téléphone
5. Vérifiez la connexion :
   ```cmd
   adb devices
   ```

## Lancer l'application Flutter

Une fois le téléphone connecté :

```cmd
# Voir les appareils disponibles
flutter devices

# Lancer l'application sur l'appareil
flutter run

# Ou lancer en mode release (plus performant)
flutter run --release
```

## Dépannage

### Le téléphone n'apparaît pas dans `adb devices`
- Vérifiez que les pilotes USB sont installés
- Essayez un autre câble USB
- Redémarrez adb : `adb kill-server` puis `adb start-server`
- Révoquez les autorisations USB sur le téléphone et réessayez

### Erreur "offline" dans `adb devices`
```cmd
adb kill-server
adb start-server
adb devices
```

### Connexion sans fil ne fonctionne pas
- Vérifiez que le téléphone et l'ordinateur sont sur le même réseau Wi-Fi
- Désactivez temporairement le pare-feu Windows
- Utilisez l'adresse IP exacte affichée sur le téléphone

### Pour Samsung avec Knox
- Désactivez temporairement Knox Security dans les paramètres de sécurité
