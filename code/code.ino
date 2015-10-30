/*

  Fibonacci Clock
  Copyright (C) 2015 by Xose Pérez <xose dot perez at gmail dot com>

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

#include <Time.h>
#include <TimeAlarms.h>
#include <DS1307RTC.h>
#include <Wire.h>
#include <Adafruit_NeoPixel.h>
#include "debounceEvent.h"

// ===========================================
// Configuration
// ===========================================

//#define DEBUG
#define SERIAL_BAUD 9600
#define DEBOUNCE_DELAY 100
#define DEFAULT_DATETIME 1434121829
#define UPDATE_CLOCK_INTERVAL 60000
#define UPDATE_MOOD_INTERVAL 100
#define TOTAL_BLOCKS 5
#define TOTAL_PIXELS 9
#define TOTAL_PALETTES 10
#define TOTAL_MODES 3

// modes
#define MODE_OFF 0
#define MODE_CLOCK 1
#define MODE_LAMP 2

// pin definitions
#define PIN_BUTTON_MODE 5
#define PIN_BUTTON_FUNCTION 6
#define PIN_BUTTON_HOUR 7
#define PIN_BUTTON_MINUTE 8
#define PIN_LEDSTRIP 4

// ===========================================
// Globals
// ===========================================

byte mode = MODE_CLOCK;
byte palette = 0;

// Pixel strip
Adafruit_NeoPixel pixels = Adafruit_NeoPixel(TOTAL_PIXELS, PIN_LEDSTRIP, NEO_RGB + NEO_KHZ800);

// Buttons
void buttonCallback(uint8_t pin, uint8_t event);
DebounceEvent buttonHour = DebounceEvent(PIN_BUTTON_HOUR, buttonCallback);
DebounceEvent buttonMinute = DebounceEvent(PIN_BUTTON_MINUTE, buttonCallback);
DebounceEvent buttonMode = DebounceEvent(PIN_BUTTON_MODE, buttonCallback);
DebounceEvent buttonFunction = DebounceEvent(PIN_BUTTON_FUNCTION, buttonCallback);

// blocks are: 
// number : 1, 2, 3, 4,  5
// binary : 1, 2, 4, 8, 16
// value  : 1, 1, 2, 3,  5
byte code_00[] = {0};
byte code_01[] = {1, 2};
byte code_02[] = {3, 4};
byte code_03[] = {5, 6, 8};
byte code_04[] = {7, 9, 10};
byte code_05[] = {11, 12, 16};
byte code_06[] = {13, 14, 17, 18};
byte code_07[] = {15, 19, 20};
byte code_08[] = {21, 22, 24};
byte code_09[] = {23, 25, 26};
byte code_10[] = {27, 28};
byte code_11[] = {29, 30};
byte code_12[] = {31};
byte* codes[13] = {
  code_00, code_01, code_02, code_03, 
  code_04, code_05, code_06, code_07, 
  code_08, code_09, code_10, code_11, 
  code_12
};
byte options[13] = {1, 2, 2, 3, 3, 3, 4, 3, 3, 3, 2, 2, 1};

// number of leds for each block
byte leds[] = {1, 1, 1, 2, 4};

// Color palettes, for each palette: OFF, ONLY HOUR, ONLY MINUTE, BOTH HOUR AND MINUTE
uint32_t colors[TOTAL_PALETTES][4] = {
  { pixels.Color(255,255,255), pixels.Color(255,10,10),   pixels.Color(10,255,10),   pixels.Color(10,10,255)   }, // #0 RGB
  { pixels.Color(255,255,255), pixels.Color(255,10,10),   pixels.Color(248,222,0),   pixels.Color(10,10,255)   }, // #1 Mondrian
  { pixels.Color(255,255,255), pixels.Color(80,40,0),     pixels.Color(20,200,20),   pixels.Color(255,100,10)  }, // #2 Basbrun
  { pixels.Color(255,255,255), pixels.Color(245,100,201), pixels.Color(114,247,54),  pixels.Color(113,235,219) }, // #3 80's
  { pixels.Color(255,255,255), pixels.Color(255,123,123), pixels.Color(143,255,112), pixels.Color(120,120,255) }, // #4 Pastel
  { pixels.Color(255,255,255), pixels.Color(212,49,45),   pixels.Color(145,210,49),  pixels.Color(141,95,224)  }, // #5 Modern
  { pixels.Color(255,255,255), pixels.Color(209,62,200),  pixels.Color(69,232,224),  pixels.Color(80,70,202)   }, // #6 Cold
  { pixels.Color(255,255,255), pixels.Color(237,20,20),   pixels.Color(246,243,54),  pixels.Color(255,126,21)  }, // #7 Warm
  { pixels.Color(255,255,255), pixels.Color(70,35,0),     pixels.Color(70,122,10),   pixels.Color(200,182,0)   }, // #8 Earth
  { pixels.Color(255,255,255), pixels.Color(211,34,34),   pixels.Color(80,151,78),   pixels.Color(16,24,149)   }  // #9 Dark
}; 

// ===========================================
// Interrupt routines
// ===========================================

// ===========================================
// Methods
// ===========================================

void digitalClockDisplay(){
  int current_hour = hour();
  int current_minute = minute();
  Serial.print("Time: ");
  Serial.print(current_hour);
  Serial.print(":");
  if(current_minute < 10) Serial.print('0');
  Serial.print(current_minute);
  Serial.println(); 
}

byte getRandomCode(int value) {
  byte * possible = codes[value];
  #ifdef DEBUG
    Serial.print("# of options: ");
    Serial.println(options[value]);
  #endif
  byte chosen = random(options[value]);
  #ifdef DEBUG
    Serial.print("Chosen option: ");
    Serial.println(chosen);
  #endif
  return possible[chosen];
}

void loadCode(byte code, byte * strip, byte value) {
  byte bit = 1;
  byte led = 0;
  for (byte i=0; i<sizeof(leds); i++) {
    if ((code & bit) > 0) {
      for(byte j=0; j<leds[i]; j++) {
        strip[led + j] = strip[led + j] + value;
      }
    }
    led += leds[i];
    bit <<= 1;
  }
  #ifdef DEBUG
    Serial.print("Pixel code: ");
    Serial.println(code);
  #endif
}

void updateClock(bool force = false) {

  // RTC sync not working
  if (timeStatus() != timeSet) {
    #ifdef DEBUG
      Serial.println("Wrong timeStatus, configure DS1307");
    #endif
    return;
  }

  // Check previous values for hour and minute and
  // update only if they have changed
  static int previous_hour = -1;
  static int previous_minute = -1;
  int current_hour = hour();
  int current_minute = minute();
  if ((!force) && (current_hour == previous_hour) && (current_minute == previous_minute)) return;
  previous_hour = current_hour;
  previous_minute = current_minute;

  digitalClockDisplay();

  // This array will hold 0, 1, 2 and 3 depending
  // on whether each led should be blank (0),
  // lit for hours (1), minutes (2) or both (3).
  byte strip[9] = {0};
  
  // Load hours into strip array
  current_hour = current_hour > 12 ? current_hour-12 : current_hour;
  #ifdef DEBUG
    Serial.print("Hour: ");
    Serial.println(current_hour);
  #endif
  loadCode(getRandomCode(current_hour), strip, 1);

  // Load minutes into strip array
  current_minute /= 5;
  #ifdef DEBUG
    Serial.print("Minutes/5: ");
    Serial.println(current_minute);
  #endif
  loadCode(getRandomCode(current_minute), strip, 2);

  // Now we dump the strip array into the pixels
  #ifdef DEBUG
    Serial.print("Strip configuration: ");
  #endif
  pixels.clear();
  for(byte i=0; i<pixels.numPixels(); i++) {
    pixels.setPixelColor(i, colors[palette][strip[i]]);
    #ifdef DEBUG
      Serial.print(strip[i]);
      Serial.print(" ");
    #endif
  }
  #ifdef DEBUG
    Serial.println();
  #endif
  pixels.show();

}

// Input a value 0 to 255 to get a color value.
// The colours are a transition r - g - b - back to r.
uint32_t Wheel(byte WheelPos) {
  
  if(WheelPos < 85) {
    return pixels.Color(WheelPos * 3, 255 - WheelPos * 3, 0);
  } else if(WheelPos < 170) {
    WheelPos -= 85;
    return pixels.Color(255 - WheelPos * 3, 0, WheelPos * 3);
  } else {
    WheelPos -= 170;
    return pixels.Color(0, WheelPos * 3, 255 - WheelPos * 3);
  }

}

// Slightly different, this makes the rainbow equally distributed throughout
void updateMood(uint8_t wait) {
  
  static unsigned long count = 0;
  byte led = 0;
  uint32_t color;

  for (byte i=0; i<sizeof(leds); i++) {
    color = Wheel(((i * 256 / sizeof(leds)) + count) & 255);
    for(byte j=0; j<leds[i]; j++) {        
      pixels.setPixelColor(led+j, color);
    }
    led += leds[i];
  }

  pixels.show();
  delay(wait);
  count = (count + 1) % (256*5);

}

void update(bool force = false) {
 
  static byte previous_mode = 0xFF;

  switch (mode) {
    case MODE_CLOCK:
      updateClock(force);
      break;
    case MODE_LAMP:
      updateMood(UPDATE_MOOD_INTERVAL);
      break;
    default:
      if (mode != previous_mode) {
        pixels.clear();
        pixels.show();
      }
      break;
  }

  previous_mode = mode; 

}

void shiftTime(byte hours, byte minutes) {
  int shift = (hours * 60 + minutes) * 60;
  RTC.set(RTC.get() + shift);
  adjustTime(shift);
}

void buttonCallback(uint8_t pin, uint8_t event) {
  if (event == EVENT_PRESSED) {
    switch (pin) {
        case PIN_BUTTON_MODE:
          mode = (mode + 1) % TOTAL_MODES;
          Serial.print("Mode: ");
          Serial.println(mode);
          break;
        case PIN_BUTTON_HOUR:
          if (mode == MODE_CLOCK) {
            shiftTime(1, 0);
          }
          break;
        case PIN_BUTTON_MINUTE:
          if (mode == MODE_CLOCK) {
            shiftTime(minute() == 59 ? -1 : 0, 1);
          }
          break;
        case PIN_BUTTON_FUNCTION:
          palette = (palette + 1) % TOTAL_PALETTES;
          Serial.print("Palette: ");
          Serial.println(palette);
          break;
        default:
          // do nothing
          break;
    }

    update(true);

  }
}

void setup() {

  Serial.begin(SERIAL_BAUD);

  // Initialise random number generation
  randomSeed(analogRead(0));

  // Config RTC provider
  setSyncProvider(RTC.get); 
  if (timeStatus() != timeSet) {
    setTime(DEFAULT_DATETIME);
    RTC.set(DEFAULT_DATETIME);
  }

  // Start display and initialize all to OFF
  pixels.begin();
  pixels.show();

}

void loop() {

  // Debounce buttons
  buttonHour.loop();
  buttonMinute.loop();
  buttonMode.loop();
  buttonFunction.loop();

  // Update display
  update();

}
