#include <Arduino.h>
#include <Wire.h>
#include <SensirionI2cSen66.h>
#include <Adafruit_NeoPixel.h>
#include <ArduinoBLE.h>

// Pin Definitions
#define LED_PIN 23 // RGB LED pin
#define NUM_PIXELS 1
#define SDA_PIN 6
#define SCL_PIN 7

// BLE Service and Characteristics
BLEService airQualityService("12345678-1234-5678-1234-56789abcdef0");
BLECharacteristic pm25Characteristic("12345678-1234-5678-1234-56789abcdef1", BLERead | BLENotify, sizeof(float));

BLEService ledService("19B10010-E8F2-537E-4F6C-D104768A1214");
BLEByteCharacteristic ledCharacteristic("19B10011-E8F2-537E-4F6C-D104768A1214", BLERead | BLEWrite);

SensirionI2cSen66 sensor;
Adafruit_NeoPixel pixels(NUM_PIXELS, LED_PIN, NEO_GRB + NEO_KHZ800);

unsigned long lastUpdate = 0;
const int UPDATE_INTERVAL = 500; // 500ms for faster BLE updates

void setLedColor(float pm2_5) {
    pixels.clear();
    if (pm2_5 <= 12.0) {
        pixels.setPixelColor(0, pixels.Color(0, 255, 0)); // Green (Good)
    } else if (pm2_5 > 12.0 && pm2_5 <= 35.0) {
        pixels.setPixelColor(0, pixels.Color(255, 165, 0)); // Yellow (Moderate)
    } else {
        pixels.setPixelColor(0, pixels.Color(255, 0, 0)); // Red (Unhealthy)
    }
    pixels.show();
}

// Blink white LED on startup
void blinkWhiteStartup() {
    for (int i = 0; i < 3; i++) {
        pixels.setPixelColor(0, pixels.Color(255, 255, 255)); // White
        pixels.show();
        delay(200);
        pixels.clear();
        pixels.show();
        delay(200);
    }
}

void setup() {
    Serial.begin(115200);
    Wire.begin(SDA_PIN, SCL_PIN);
    sensor.begin(Wire, SEN66_I2C_ADDR_6B);

    pixels.begin();
    pixels.show();
    blinkWhiteStartup();

    if (sensor.deviceReset() != 0) {
        Serial.println("Sensor Reset Failed");
        return;
    }
    delay(1200);
    if (sensor.startContinuousMeasurement() != 0) {
        Serial.println("Failed to start continuous measurement");
        return;
    }

    // Initialize BLE
    if (!BLE.begin()) {
        Serial.println("Failed to initialize BLE!");
        while (1);
    }

    BLE.setLocalName("ESP32-AirQuality");
    BLE.setDeviceName("Air Quality Sensor");
    BLE.advertise();
    delay(100);
    
    BLE.setAdvertisedService(airQualityService);
    airQualityService.addCharacteristic(pm25Characteristic);
    BLE.addService(airQualityService);

    BLE.setAdvertisedService(ledService);
    ledService.addCharacteristic(ledCharacteristic);
    BLE.addService(ledService);

    ledCharacteristic.writeValue(0);

    BLE.advertise();
    Serial.println("BLE Active - Waiting for connections...");
}

void loop() {
    BLE.poll();

    // Update every UPDATE_INTERVAL ms
    if (millis() - lastUpdate >= UPDATE_INTERVAL) {
        lastUpdate = millis();

        float pm1_0, pm2_5, pm4_0, pm10_0;
        float humidity, temperature, vocIndex, noxIndex, co2;

        if (sensor.readMeasuredValues(pm1_0, pm2_5, pm4_0, pm10_0, humidity, temperature, vocIndex, noxIndex, co2) != 0) {
            Serial.println("Failed to read sensor values");
            return;
        }

        Serial.print("PM2.5: ");
        Serial.println(pm2_5);
        setLedColor(pm2_5);

        // Update BLE characteristic with PM2.5 value
        pm25Characteristic.writeValue((uint8_t*)&pm2_5, sizeof(pm2_5));

        // Check if app sends LED toggle command
        uint8_t ledState = ledCharacteristic.value();
        if (ledState == 1) {
            pixels.setPixelColor(0, pixels.Color(0, 0, 255)); // Blue (LED ON)
        } else {
            pixels.clear(); // LED OFF
        }
        pixels.show();
    }
}