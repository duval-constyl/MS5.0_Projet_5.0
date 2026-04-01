# Plan d'Implémentation Matériel IoT (ESP8266 NodeMCU + MQTT)

L'objectif de cette phase est de configurer le microcontrôleur ESP8266 qui lira les capteurs (Ultrasons, RFID, Boutons) et enverra les événements au broker MQTT Mosquitto.

Puisque nous sommes contraints par le nombre limité de broches (GPIO) de l'ESP8266, nous avons réduit la voilure à :
- **1 module RFID "Entrée"** (avant le poste 1)
- **1 module RFID "Poste 1"**
- **1 Capteur Ultrason "Poste 1"**
- **1 Bouton Andon "Poste 1"**
Le Poste 2 sera uniquement visuel sur la tablette, géré par le flux de données Node-RED.

---

## 1. Schéma de Câblage (Pinout ESP8266 NodeMCU V3)

> ⚠️ **ATTENTION VITAL** : Sur les ESP8266 (NodeMCU), la nomenclature des broches est complexe. Ce qui est écrit `D1` sur la carte correspond au `GPIO 5` dans le code Arduino. **Référez-vous strictement aux correspondances ci-dessous.**

### A. Les 2 lecteurs RFID (MFRC522)
Les modules RFID communiquent via le protocole SPI. Ils partagent les mêmes broches de communication, sauf leur broche "SDA" (ou SS - Slave Select).

| Broche RC522 | Connexion ESP8266 (Sérigraphie) | GPIO Arduino | Description |
| :--- | :--- | :--- | :--- |
| **3.3V** | **3V3** | - | Alimentation (Ne JAMAIS brancher en 5V) |
| **GND** | **G** | - | Masse |
| **SCK** | **D5** | GPIO 14 | Horloge SPI (divisée vers les 2) |
| **MISO** | **D6** | GPIO 12 | Retour données (divisé vers les 2) |
| **MOSI** | **D7** | GPIO 13 | Envoi données (divisé vers les 2) |
| **RST** | **D3** | GPIO 0 | Reset (partagé pour les 2) |
| **SDA (SS) Lecteur 1 (Entrée)** | **D8** | GPIO 15 | Ligne unique Lecteur 1 |
| **SDA (SS) Lecteur 2 (Poste 1)** | **D4** | GPIO 2 | Ligne unique Lecteur 2 |

### B. Le Capteur Ultrason (HC-SR04)
Le capteur a besoin de 5V pour bien fonctionner.
* **VCC** -> Broche **VU** (ou Vin / 5V) du NodeMCU
* **GND** -> **G**
* **TRIG** -> Broche **D1** (GPIO 5)
* **ECHO** -> Broche **D2** (GPIO 4)
> *Astuce : L'ECHO renvoie du 5V, l'ESP8266 n'aime que le 3.3V. Il est vivement conseillé de mettre un pont diviseur de tension (résistances 1K et 2K) sur la broche ECHO.*

### C. Le Bouton Poussoir (Andon Poste 1)
Nous utiliserons la broche `RX` (GPIO 3) qui peut servir de GPIO normal si on n'utilise pas le port série entrant.
* **Un côté du bouton** -> Broche **RX**
* **L'autre côté du bouton** -> **G** (GND)

---

## 2. Le Code Arduino (ESP8266)

Pour compiler ce code dans l'Arduino IDE, vous aurez besoin de sélectionner la carte **NodeMCU 1.0 (ESP-12E Module)** et d'installer ces deux bibliothèques (Gestionnaire de Bibliothèques) :
1. `PubSubClient` (par Nick O'Leary) 
2. `MFRC522` (par GithubCommunity)

```cpp
#include <ESP8266WiFi.h>
#include <PubSubClient.h>
#include <SPI.h>
#include <MFRC522.h>

// ==============================
// 1. CONFIGURATION RÉSEAU
// ==============================
const char* ssid = "Duval😎";
const char* password = "656361373";
const char* mqtt_server = "172.20.10.6";
const int mqtt_port = 1883;
const char* mqtt_user = "user"; 
const char* mqtt_pass = "root"; 

WiFiClient espClient;
PubSubClient client(espClient);

// ==============================
// 2. CONFIGURATION RFID (SPI)
// ==============================
#define RST_PIN   0  // Broche D3
#define SS_PIN_1  15 // Broche D8 (Lecteur Poste 1)
#define SS_PIN_2  2  // Broche D4 (Lecteur Poste 2)

const int numReaders = 2;
byte ssPins[] = {SS_PIN_1, SS_PIN_2};
MFRC522 mfrc522[numReaders];

String lastReadTag[numReaders] = {"", ""};
unsigned long lastReadTime[numReaders] = {0, 0};

// ==============================
// 3. CONFIGURATION INFRAROUGE & BOUTON
// ==============================
#define IR_PIN  5   // Broche D1 (Capteur Infrarouge: OUT/DO)
#define BTN_PIN 3   // Broche RX (Bouton Andon Poste 2)

bool lastBtnState = HIGH;

// ==============================
// FONCTIONS UTILES
// ==============================

// Convertit l'UID du badge RFID en String Hexadécimal
String dump_byte_array(byte *buffer, byte bufferSize) {
  String out = "";
  for (byte i = 0; i < bufferSize; i++) {
    out += String(buffer[i] < 0x10 ? "0" : "");
    out += String(buffer[i], HEX);
  }
  out.toUpperCase();
  return out;
}

void setup_wifi() {
  delay(10);
  Serial.println();
  Serial.print("Connexion à ");
  Serial.println(ssid);

  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("");
  Serial.println("WiFi connecté !");
  Serial.print("Adresse IP : ");
  Serial.println(WiFi.localIP());
}

void reconnect() {
  while (!client.connected()) {
    Serial.print("Tentative de connexion MQTT...");
    if (client.connect("ESP8266_Factory_Gate", mqtt_user, mqtt_pass)) {
      Serial.println("Connecté au Broker !");
    } else {
      Serial.print("Échec, rc=");
      Serial.print(client.state());
      Serial.println(" Nouvelle tentative dans 5s");
      delay(5000);
    }
  }
}

// ==============================
// SETUP & LOOP PRINCIPAL
// ==============================

void setup() {
  Serial.begin(115200);
  
  // Configuration des broches
  pinMode(BTN_PIN, INPUT_PULLUP);
  pinMode(IR_PIN, INPUT); // Le signal Infrarouge est en entrée

  setup_wifi();
  client.setServer(mqtt_server, mqtt_port);

  // Initialisation du bus SPI et des lecteurs RFID
  SPI.begin();
  for (uint8_t i = 0; i < numReaders; i++) {
    mfrc522[i].PCD_Init(ssPins[i], RST_PIN);
    Serial.print("Lecteur RFID "); 
    Serial.print(i + 1); 
    Serial.println(" prêt.");
  }
}

void loop() {
  // Gestion de la connexion MQTT
  if (!client.connected()) {
    reconnect();
  }
  client.loop(); 

  // --- PARTIE 1 : SCAN DES LECTEURS RFID ---
  for (uint8_t i = 0; i < numReaders; i++) {
    mfrc522[i].PCD_Init(ssPins[i], RST_PIN); 

    if (mfrc522[i].PICC_IsNewCardPresent() && mfrc522[i].PICC_ReadCardSerial()) {
      String tagID = dump_byte_array(mfrc522[i].uid.uidByte, mfrc522[i].uid.size);
      
      if (tagID != lastReadTag[i] || (millis() - lastReadTime[i] > 3000)) {
        String location = (i == 0) ? "poste1" : "poste2";
        String topic = "usine/" + location + "/chariot_arrive";
        String payload = "{\"tag\": \"" + tagID + "\"}";
        
        client.publish(topic.c_str(), payload.c_str());
        
        lastReadTag[i] = tagID;
        lastReadTime[i] = millis();
        
        Serial.print("Badge détecté au "); Serial.print(location);
        Serial.print(" : "); Serial.println(tagID);
      }
      mfrc522[i].PICC_HaltA(); 
      mfrc522[i].PCD_StopCrypto1();
    }
  }

  // --- PARTIE 2 : BOUTON D'ALERTE (ANDON) ---
  bool currentBtn = digitalRead(BTN_PIN);
  if (currentBtn == LOW && lastBtnState == HIGH) {
    client.publish("usine/poste2/andon", "{\"alerte\": true}");
    Serial.println("Alerte Andon activée au Poste 2 !");
    delay(200); // Anti-rebond logiciel
  }
  lastBtnState = currentBtn;

  // --- PARTIE 3 : DÉTECTION INFRAROUGE (AUTO-VALIDATION) ---
  static unsigned long lastIR = 0;
  static bool chariotPresent = false; // Mémoire d'état

  // On vérifie le capteur Infrarouge très souvent (toutes les 200 ms)
  if (millis() - lastIR > 200) { 
      
      // La MÉTÉO DU CAPTEUR : 
      // La plupart des modules IR s'activent "LOW" (0) quand ils voient un objet
      // S'il s'active avec HIGH chez toi, remplace simplement 'LOW' par 'HIGH'
      bool objectDetected = (digitalRead(IR_PIN) == LOW);
      
      if (objectDetected) { 
         // Si on voit un chariot, mais qu'il n'y était PAS la milliseconde d'avant
         if (!chariotPresent) {
             client.publish("usine/poste1/chariot_depart", "{\"auto_validate\": true}");
             Serial.println(">>> NOUVEAU Chariot détecté (IR) au Poste 2 : Validation Poste 1 envoyée.");
             chariotPresent = true; // On verrouille
         }
      } else { 
         // S'il n'y a plus d'obstacle
         if (chariotPresent) {
             Serial.println("<<< Le chariot a quitté le Poste 2 (IR). Capteur réarmé.");
             chariotPresent = false; // On déverrouille pour le prochain chariot
         }
      }
      lastIR = millis();
  }
}

```
