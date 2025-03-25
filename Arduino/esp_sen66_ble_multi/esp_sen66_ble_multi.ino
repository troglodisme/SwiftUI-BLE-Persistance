#include <Arduino.h>
#include <Wire.h>
#include <SensirionI2cSen66.h>
#include <Adafruit_MAX1704X.h>
#include <Adafruit_NeoPixel.h>
#include <ArduinoBLE.h>

// === Pin Definitions ===
#define LED_PIN 23
#define NUM_PIXELS 1
#define SDA_PIN 6
#define SCL_PIN 7

// === Data Structs ===
struct ParticulateData {
  float pm1_0;
  float pm2_5;
  float pm4_0;
  float pm10_0;
};

struct EnvironmentalData {
  float temperature;
  float humidity;
};

struct GasData {
  float vocIndex;
  float noxIndex;
  float co2;
};

// === BLE Services ===
BLEService airQualityService("12345678-1234-5678-1234-56789abcdef0");
BLEService batteryService("180F");
BLEService deviceInfoService("180A");
BLEService ledService("19B10010-E8F2-537E-4F6C-D104768A1214");

// === BLE Characteristics ===
BLECharacteristic particulateChar("12345678-1234-5678-1234-56789abcdea1", BLERead | BLENotify, sizeof(ParticulateData));
BLECharacteristic envChar("12345678-1234-5678-1234-56789abcdea2", BLERead | BLENotify, sizeof(EnvironmentalData));
BLECharacteristic gasChar("12345678-1234-5678-1234-56789abcdea3", BLERead | BLENotify, sizeof(GasData));
BLEUnsignedCharCharacteristic batteryLevelChar("2A19", BLERead | BLENotify);

BLEStringCharacteristic manufacturerChar("2A29", BLERead, 20);
BLEStringCharacteristic firmwareChar("2A26", BLERead, 20);
BLEStringCharacteristic modelChar("2A24", BLERead, 20);

BLEByteCharacteristic ledCharacteristic("19B10011-E8F2-537E-4F6C-D104768A1214", BLERead | BLEWrite);

// === Sensors ===
SensirionI2cSen66 sensor;
Adafruit_MAX17048 maxlipo;
Adafruit_NeoPixel pixels(NUM_PIXELS, LED_PIN, NEO_GRB + NEO_KHZ800);

// === Timing ===
unsigned long lastUpdate = 0;
const int UPDATE_INTERVAL = 1000; // ms

void blinkWhiteStartup() {
  for (int i = 0; i < 3; i++) {
    pixels.setPixelColor(0, pixels.Color(255, 255, 255));
    pixels.show();
    delay(200);
    pixels.clear();
    pixels.show();
    delay(200);
  }
}

void setLedColor(float pm2_5) {
  pixels.clear();
  if (pm2_5 <= 12.0) {
    pixels.setPixelColor(0, pixels.Color(0, 255, 0));
  } else if (pm2_5 <= 35.0) {
    pixels.setPixelColor(0, pixels.Color(255, 165, 0));
  } else {
    pixels.setPixelColor(0, pixels.Color(255, 0, 0));
  }
  pixels.show();
}

void setup() {
  Serial.begin(115200);
  // while (!Serial);

  Wire.begin(SDA_PIN, SCL_PIN);

  // Sensor Init
  sensor.begin(Wire, SEN66_I2C_ADDR_6B);
  sensor.deviceReset();
  delay(1200);
  sensor.startContinuousMeasurement();

  // Fuel Gauge Init
  if (!maxlipo.begin()) {
    Serial.println("MAX17048 not found! Is a battery connected?");
    while (1) delay(2000);
  }

  // LED
  pixels.begin();
  pixels.show();
  blinkWhiteStartup();

  // BLE Init
  if (!BLE.begin()) {
    Serial.println("BLE init failed");
    while (1);
  }

  BLE.setLocalName("AmbientOne");
  BLE.setDeviceName("Ambient One");

  // Descriptors for human-readable names (shows up in nRF Connect)
  // particulateChar.setUserDescriptor("PM1.0–10.0 (ug/m3)");
  // envChar.setUserDescriptor("Temperature & Humidity");
  // gasChar.setUserDescriptor("VOC, NOx, CO2 Indexes");

  // Add Characteristics
  airQualityService.addCharacteristic(particulateChar);
  airQualityService.addCharacteristic(envChar);
  airQualityService.addCharacteristic(gasChar);
  BLE.setAdvertisedService(airQualityService);
  BLE.addService(airQualityService);

  batteryService.addCharacteristic(batteryLevelChar);
  BLE.addService(batteryService);

  deviceInfoService.addCharacteristic(manufacturerChar);
  deviceInfoService.addCharacteristic(firmwareChar);
  deviceInfoService.addCharacteristic(modelChar);
  BLE.addService(deviceInfoService);

  manufacturerChar.writeValue("Ambient Works");
  firmwareChar.writeValue("v1.0");
  modelChar.writeValue("Ambient One");

  ledService.addCharacteristic(ledCharacteristic);
  BLE.addService(ledService);
  ledCharacteristic.writeValue(0);

  BLE.advertise();
  Serial.println("BLE is now advertising...");
}

void loop() {
  BLE.poll();

  if (millis() - lastUpdate >= UPDATE_INTERVAL) {
    lastUpdate = millis();

    // Read from Sensor
    float pm1_0, pm2_5, pm4_0, pm10_0;
    float humidity, temperature, vocIndex, noxIndex, co2;

    if (sensor.readMeasuredValues(pm1_0, pm2_5, pm4_0, pm10_0,
                                   humidity, temperature,
                                   vocIndex, noxIndex, co2) != 0) {
      Serial.println("Sensor read failed");
      return;
    }

    // Send over BLE
    ParticulateData particulate = { pm1_0, pm2_5, pm4_0, pm10_0 };
    EnvironmentalData env = { temperature, humidity };
    GasData gas = { vocIndex, noxIndex, co2 };

    particulateChar.writeValue((uint8_t*)&particulate, sizeof(particulate));
    envChar.writeValue((uint8_t*)&env, sizeof(env));
    gasChar.writeValue((uint8_t*)&gas, sizeof(gas));

    // Battery
    float batteryPercentRaw = maxlipo.cellPercent();
    float batteryPercent = constrain(batteryPercentRaw, 0.0, 100.0);

    if (!isnan(batteryPercent)) {
      batteryLevelChar.writeValue((uint8_t)constrain(batteryPercent, 0, 100));
    }

    // LED Feedback
    setLedColor(pm2_5);

    // LED Control
    uint8_t ledState = ledCharacteristic.value();
    if (ledState == 1) {
      pixels.setPixelColor(0, pixels.Color(0, 0, 255));
    } else {
      pixels.clear();
    }
    pixels.show();

    // Debug
    Serial.printf("PM2.5: %.1f | Temp: %.1f | Hum: %.1f | Batt: %.1f%%\n",
                  pm2_5, temperature, humidity, batteryPercent);
  }
}