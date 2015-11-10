# Fibonacci Clock

Some months ago Philippe Chrétien opened a Kickstarter with his [Fibonacci Clock][1].
I immediately fell in love with it. It was awesome, mathematical, colorful and
open source. A truly makers project. At 100€ the unit it was too expensive
for me but he gathered almost 128k€. He shipped the last of the 1242 clocks
just a few weeks ago. And I got mine more or less in the same dates, but of
course, I did it myself.

You can check how he did it in his [instructables page][2], or browse this repository
with my designs and code.

## Hardware

### The clock

The hardware has been designed using [OpenSCad][2]. It's basically a box with compartments
inside another box. Originally I planned to use 8-10mm thick wood for the outside
box but finally I've used the same DMF as in the inner box. Inside the box there is
a custom PCB wth an RTC and nine 12mm RGB LEDs with WS2812B drivers.

### The controller

The controller is a custom PCB designed to serve different purposes. On one hand
there is an RTC and a uC (ATMega328P, same as an Arduino UNO). The user interface
are 4 big 12x12mm buttons and, optionally there is an SD card reader (more about
this in a future project).

It can be powered with 5V via a 2.1x5.5mm barrel plug or a screw terminal, there is
an FTDI-compatible header to program it and a 3-wire screw terminal to connect
Neopixel-like strips.

Please check the .sch and .brd files for Eagle in the schema folder.

## Firmware

The project is ready to be build using [PlatformIO][4].
Please refer to their web page for instructions on how to install the builder.
Once installed:

```bash
> cd code
> platformio init -b uno
> platformio run
> platformio run --target upload
```

Library dependencies are automatically managed via PlatformIO Library Manager.

[1]: https://www.kickstarter.com/projects/basbrun/fibonacci-clock-an-open-source-clock-for-nerds-wit
[2]: http://www.instructables.com/id/The-Fibonacci-Clock/
[3]: http://www.openscad.org
[4]: http://www.platformio.org
