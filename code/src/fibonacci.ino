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

#include <Wire.h>
#include <RTClib.h>
#include <Adafruit_NeoPixel.h>
#include "debounceEvent.h"

// ===========================================
// Configuration
// ===========================================

//#define DEBUG
#define SERIAL_BAUD 115200
#define DEBOUNCE_DELAY 100
#define UPDATE_CLOCK_INTERVAL 60000
#define UPDATE_MOOD_INTERVAL 100
#define TOTAL_BLOCKS 5
#define TOTAL_PIXELS 9
#define TOTAL_PALETTES 12
#define TOTAL_MODES 3
#define DEFAULT_BRIGHTNESS 255

// modes
#define MODE_OFF 0
#define MODE_CLOCK 1
#define MODE_LAMP 2

// behaviours
#define BEHAVIOUR_NORMAL 0
#define BEHAVIOUR_CHANGE_HOUR 1
#define BEHAVIOUR_CHANGE_MINUTE 2
#define BEHAVIOUR_PAUSE 3

// pin definitions
#define PIN_BUTTON_MODE 5
#define PIN_BUTTON_HOUR 6
#define PIN_BUTTON_MINUTE 7
#define PIN_BUTTON_ACTION 8
#define PIN_LEDSTRIP 4

// ===========================================
// Globals
// ===========================================

byte mode = MODE_CLOCK;
byte behaviour = BEHAVIOUR_NORMAL;
byte palette = 0;
bool changed = false;

// RTC
RTC_DS1307 rtc;

// Pixel strip
Adafruit_NeoPixel pixels = Adafruit_NeoPixel(TOTAL_PIXELS, PIN_LEDSTRIP, NEO_RGB + NEO_KHZ800);

// Buttons
void buttonCallback(uint8_t pin, uint8_t event);
DebounceEvent buttonHour = DebounceEvent(PIN_BUTTON_HOUR, buttonCallback);
DebounceEvent buttonMinute = DebounceEvent(PIN_BUTTON_MINUTE, buttonCallback);
DebounceEvent buttonMode = DebounceEvent(PIN_BUTTON_MODE, buttonCallback);
DebounceEvent buttonFunction = DebounceEvent(PIN_BUTTON_ACTION, buttonCallback);

// blocks are:
// number : 1, 2, 3, 4,  5
// binary : 1, 2, 4, 8, 16
// value  : 1, 1, 2, 3,  5
byte code_00[] = {0};
byte code_01[] = {1, 2};
byte code_02[] = {4, 3};
byte code_03[] = {8, 5, 6};
byte code_04[] = {7, 9, 10};
byte code_05[] = {16, 11, 12};
byte code_06[] = {18, 13, 14, 17};
byte code_07[] = {20, 15, 19};
byte code_08[] = {24, 21, 22};
byte code_09[] = {23, 25, 26};
byte code_10[] = {28, 27};
byte code_11[] = {30, 29};
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
   { pixels.Color(255,255,255), pixels.Color(255,10,10),   pixels.Color(10,255,10),   pixels.Color(10,10,255)   }, // #00 RGB
   { pixels.Color(255,255,255), pixels.Color(255,10,10),   pixels.Color(248,222,0),   pixels.Color(10,10,255)   }, // #01 Mondrian
   { pixels.Color(255,255,255), pixels.Color(80,40,0),     pixels.Color(20,200,20),   pixels.Color(255,100,10)  }, // #02 Basbrun
   { pixels.Color(255,255,255), pixels.Color(245,100,201), pixels.Color(114,247,54),  pixels.Color(113,235,219) }, // #03 80's
   { pixels.Color(255,255,255), pixels.Color(255,123,123), pixels.Color(143,255,112), pixels.Color(120,120,255) }, // #04 Pastel
   { pixels.Color(255,255,255), pixels.Color(212,49,45),   pixels.Color(145,210,49),  pixels.Color(141,95,224)  }, // #05 Modern
   { pixels.Color(255,255,255), pixels.Color(209,62,200),  pixels.Color(69,232,224),  pixels.Color(80,70,202)   }, // #06 Cold
   { pixels.Color(255,255,255), pixels.Color(237,20,20),   pixels.Color(246,243,54),  pixels.Color(255,126,21)  }, // #07 Warm
   { pixels.Color(255,255,255), pixels.Color(70,35,0),     pixels.Color(70,122,10),   pixels.Color(200,182,0)   }, // #08 Earth
   { pixels.Color(255,255,255), pixels.Color(211,34,34),   pixels.Color(80,151,78),   pixels.Color(16,24,149)   }, // #09 Dark
   { pixels.Color(0,0,0),       pixels.Color(255,10,10),   pixels.Color(10,255,10),   pixels.Color(10,10,255)   }, // #10 Black RGB
   { pixels.Color(0,0,0),       pixels.Color(255,10,10),   pixels.Color(248,222,0),   pixels.Color(10,10,255)   }  // #11 Black Mondrian
};

// ===========================================
// Interrupt routines
// ===========================================

// ===========================================
// Methods
// ===========================================

void resetTime() {
   #ifdef DEBUG
   Serial.println(F("Reseting DS1307"));
   #endif
   rtc.adjust(DateTime(F(__DATE__), F(__TIME__)));
}

// Shifts time the specified number of hours, minutes and seconds
void shiftTime(int hours, int minutes, int seconds) {
   DateTime newTime = DateTime(rtc.now().unixtime() + seconds+60*(minutes+60*hours));
   rtc.adjust(newTime);
   changed = true;
}

// Sets seconds to 0 for current hour:minute
void resetSeconds() {
   shiftTime(0, 0, -rtc.now().second());
}

void printDigits(int digits, bool semicolon = false){
   if (semicolon) Serial.print(F(":"));
   if(digits < 10) Serial.print(F("0"));
   Serial.print(digits);
}

void digitalClockDisplay(DateTime now){
   Serial.print(F("Time: "));
   printDigits(now.hour(), false);
   printDigits(now.minute(), true);
   printDigits(now.second(), true);
   Serial.println();
}

byte getRandomCode(int value) {
   byte * possible = codes[value];
   #ifdef DEBUG
   Serial.print(F("# of options: "));
   Serial.println(options[value]);
   #endif
   byte chosen = (behaviour == BEHAVIOUR_NORMAL) ? random(options[value]) : 0;
   #ifdef DEBUG
   Serial.print(F("Chosen option: "));
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
   Serial.print(F("Pixel code: "));
   Serial.println(code);
   #endif
}

void updateClock(bool force = false) {

   // Check previous values for hour and minute and
   // update only if they have changed
   DateTime now = rtc.now();
   static int previous_hour = -1;
   static int previous_minute = -1;
   int current_hour = now.hour();
   int current_minute = now.minute();
   if ((!force) && (current_hour == previous_hour) && (current_minute == previous_minute)) return;
   previous_hour = current_hour;
   previous_minute = current_minute;

   digitalClockDisplay(now);

   // This array will hold 0, 1, 2 and 3 depending
   // on whether each led should be blank (0),
   // lit for hours (1), minutes (2) or both (3).
   byte strip[9] = {0};

   // Load hours into strip array
   if (behaviour != BEHAVIOUR_CHANGE_MINUTE) {
      current_hour = current_hour > 12 ? current_hour - 12 : current_hour;
      #ifdef DEBUG
         Serial.print(F("Hour: "));
         Serial.println(current_hour);
      #endif
      loadCode(getRandomCode(current_hour), strip, 1);
   }

   // Load minutes into strip array
   if (behaviour != BEHAVIOUR_CHANGE_HOUR) {
      current_minute /= 5;
      #ifdef DEBUG
         Serial.print(F("Minutes/5: "));
         Serial.println(current_minute);
      #endif
      loadCode(getRandomCode(current_minute), strip, 2);
   }

   // Now we dump the strip array into the pixels
   #ifdef DEBUG
      Serial.print(F("Strip configuration: "));
   #endif
   pixels.clear();
   pixels.setBrightness(DEFAULT_BRIGHTNESS);
   for(byte i=0; i<pixels.numPixels(); i++) {
      pixels.setPixelColor(i, colors[palette][strip[i]]);
      #ifdef DEBUG
         Serial.print(strip[i]);
         Serial.print(F(" "));
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
         if (behaviour != BEHAVIOUR_PAUSE) {
            updateMood(UPDATE_MOOD_INTERVAL);
         }
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

// There are 4 buttons
// My younger dau loves the click-click of the buttons,
// so I want time changing to be somewhat difficult to
// prevent her changing the time every now and then.
// So, to change hours or minutes one has to press and hold
// HOUR or MINUTE button and click ACTION button to change them.
// If any of HOUR or MINUTE button is pressed, clock
// will only show hours or minutes, not both.
// Releasing those buttons or pressing the MODE button
// switches behaviour back to BEHAVIOUR_NORMAL
// In BEHAVIOUR_NORMAL behaviour ACTION button changes palettes

// MODE button changes mode: clock -> lamp -> off -> clock
// HOUR button sets hour for modification
// MINUTE button sets minutes for modification
// ACTION button changes hour/minutes/palette depending on HOUR and MINUTE buttons
// ACTION button pauses/resumes rainbow cycle when in MODE_MOOD

void buttonCallback(uint8_t pin, uint8_t event) {

   if (event == EVENT_PRESSED) {

      switch (pin) {

         case PIN_BUTTON_MODE:
         mode = (mode + 1) % TOTAL_MODES;
         behaviour = BEHAVIOUR_NORMAL;
         Serial.print(F("Mode: "));
         Serial.println(mode);
         break;

         case PIN_BUTTON_HOUR:
         if (mode == MODE_CLOCK and behaviour == BEHAVIOUR_NORMAL) {
            behaviour = BEHAVIOUR_CHANGE_HOUR;
            changed = false;
            Serial.println(F("Change hour"));
         }
         break;

         case PIN_BUTTON_MINUTE:
         if (mode == MODE_CLOCK and behaviour == BEHAVIOUR_NORMAL) {
            behaviour = BEHAVIOUR_CHANGE_MINUTE;
            changed = false;
            Serial.println(F("Change minute"));
         }
         break;

         case PIN_BUTTON_ACTION:

         if (mode == MODE_CLOCK) {

            switch (behaviour) {

               case BEHAVIOUR_CHANGE_HOUR:
                  shiftTime(1, 0, 0);
                  break;

               case BEHAVIOUR_CHANGE_MINUTE:
                  shiftTime(0, rtc.now().minute() == 59 ? -59 : 1, 0);
                  break;

               default:
                  palette = (palette + 1) % TOTAL_PALETTES;
                  Serial.print(F("Palette: "));
                  Serial.println(palette);

            }

         }

         if (mode == MODE_LAMP) {
            if (behaviour == BEHAVIOUR_PAUSE) {
               behaviour = BEHAVIOUR_NORMAL;
               Serial.println(F("Resume rainbow cycle"));
            } else {
               behaviour = BEHAVIOUR_PAUSE;
               Serial.println(F("Pause rainbow cycle"));
            }

         }


      }

      update(true);

   }

   if (event == EVENT_RELEASED) {
      if (pin != PIN_BUTTON_ACTION and behaviour != BEHAVIOUR_NORMAL and mode == MODE_CLOCK ) {
         behaviour = BEHAVIOUR_NORMAL;
         if (changed) resetSeconds();
         update(true);
      }
   }

}

void setup() {

   Serial.begin(SERIAL_BAUD);

   // Config RTC
   if (!rtc.begin()) {
      Serial.println(F("Couldn't find RTC"));
      while(1);
   }
   if (!rtc.isrunning()) {
      resetTime();
   }

   // Initialise random number generation
   randomSeed(rtc.now().unixtime());

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
